package Bat::Interpreter;

use utf8;

use 5.014;
use Moo;
use Types::Standard qw(ConsumerOf);
use App::BatParser 0.011;
use Carp;
use Data::Dumper;
use Bat::Interpreter::Delegate::FileStore::LocalFileSystem;
use Bat::Interpreter::Delegate::Executor::PartialDryRunner;
use Bat::Interpreter::Delegate::LineLogger::Silent;
use File::Glob;
use namespace::autoclean;

our $VERSION = '0.025';    # VERSION

# ABSTRACT: Pure perl interpreter for a small subset of bat/cmd files

has 'batfilestore' => (
    is      => 'rw',
    isa     => ConsumerOf ['Bat::Interpreter::Role::FileStore'],
    default => sub {
        Bat::Interpreter::Delegate::FileStore::LocalFileSystem->new;
    }
);

has 'executor' => (
    is      => 'rw',
    isa     => ConsumerOf ['Bat::Interpreter::Role::Executor'],
    default => sub {
        Bat::Interpreter::Delegate::Executor::PartialDryRunner->new;
    }
);

has 'linelogger' => (
    is      => 'rw',
    isa     => ConsumerOf ['Bat::Interpreter::Role::LineLogger'],
    default => sub {
        Bat::Interpreter::Delegate::LineLogger::Silent->new;
    }
);

sub run {
    my $self         = shift();
    my $filename     = shift();
    my $external_env = shift() // \%ENV;

    my $parser = App::BatParser->new;

    my $ensure_last_line_has_carriage_return = "\r\n";
    if ( $^O eq 'MSWin32' ) {
        $ensure_last_line_has_carriage_return = "\n";
    }

    my $parse_tree =
      $parser->parse( $self->batfilestore->get_contents($filename) . $ensure_last_line_has_carriage_return );
    if ($parse_tree) {
        my $lines = $parse_tree->{'File'}{'Lines'};

        my %environment = %$external_env;

        # Index file based on labels
        #Only for perl >= 5.020
        #my %line_from_label = List::AllUtils::pairmap { $b->{'Label'}{'Identifier'} => $a }
        #%{$lines}[ List::AllUtils::indexes { exists $_->{'Label'} } @$lines ];
        my %line_from_label;
        for ( my $i = 0; $i < scalar @$lines; $i++ ) {
            my $line = $lines->[$i];
            if ( exists $line->{'Label'} ) {
                $line_from_label{ $line->{'Label'}{'Identifier'} } = $i;
            }
        }
        $line_from_label{'EOF'} = scalar @$lines;
        $line_from_label{'eof'} = scalar @$lines;
        my $context = { 'ENV'          => \%environment,
                        'IP'           => 0,
                        'LABEL_INDEX'  => \%line_from_label,
                        'current_line' => '',
                        'STACK'        => [],
                        'filename'     => $filename
        };

        # Execute lines in a nonlinear fashion
        for ( my $instruction_pointer = 0; $instruction_pointer < scalar @$lines; ) {
            my $current_instruction = $lines->[$instruction_pointer];
            $context->{'IP'} = $instruction_pointer;
            my $old_ip = $instruction_pointer;
            $self->_handle_instruction( $current_instruction, $context );
            $instruction_pointer = $context->{'IP'};
            if ( $old_ip == $instruction_pointer ) {
                $instruction_pointer++;
            }
            $self->_log_line_from_context($context);
        }
        return $context->{'STDOUT'};
    } else {
        die "An error ocurred parsing the file";
    }
}

sub _handle_instruction {
    my $self                = shift();
    my $current_instruction = shift();
    my $context             = shift();

    my ($type) = keys %$current_instruction;

    if ( $type eq 'Comment' ) {
        $context->{'current_line'} = ":: " . $current_instruction->{'Comment'}{'Text'};
    }

    if ( $type eq 'Label' ) {
        $context->{'current_line'} = ":" . $current_instruction->{'Label'}{'Identifier'};
    }

    if ( $type eq 'Statement' ) {
        my $statement = $current_instruction->{'Statement'};
        $self->_handle_statement( $statement, $context );
    }

}

sub _handle_statement {
    my $self      = shift();
    my $statement = shift();
    my $context   = shift();

    my ($type) = keys %$statement;

    if ( $type eq 'Command' ) {
        my $command = $statement->{'Command'};
        $self->_handle_command( $command, $context );
    }

}

sub _handle_command {
    my $self    = shift();
    my $command = shift();
    my $context = shift();

    if ( defined $command && $command ne '' ) {
        my ($type) = keys %$command;

        if ( $type eq 'SimpleCommand' ) {
            my $command_line = $command->{'SimpleCommand'};
            $command_line = $self->_variable_substitution( $command_line, $context );

            # Path adjustment
            $command_line = $self->_adjust_path($command_line);

            $context->{'current_line'} .= $command_line;

            if ( $command_line =~ /^exit\s+\/b/i ) {
                my $stack_frame = pop @{ $context->{'STACK'} };
                if ( defined $stack_frame ) {
                    $context->{'IP'} = $stack_frame->{'IP'} + 1;
                }
            } else {
                $self->_execute_command( $command_line, $context );
            }
        }
        if ( $type eq 'SpecialCommand' ) {
            my $special_command_line = $command->{'SpecialCommand'};
            $self->_handle_special_command( $special_command_line, $context );
        }
    } else {

        # Empty command
        $context->{'current_line'} .= '';
    }

}

sub _handle_special_command {
    my $self                 = shift();
    my $special_command_line = shift();
    my $context              = shift();

    my ($type) = keys %$special_command_line;

    if ( $type eq 'If' ) {
        $context->{'current_line'} .= 'IF ';
        my $condition;
        my $statement;
        if ( exists $special_command_line->{$type}->{'NegatedCondition'} ) {
            $context->{'current_line'} .= 'NOT ';
            $condition = $special_command_line->{$type}->{'NegatedCondition'}->{'Condition'};
            $statement = $special_command_line->{$type}->{'Statement'};
            if ( not $self->_handle_condition( $condition, $context ) ) {
                $self->_handle_statement( $statement, $context );
            }
        } else {
            ( $condition, $statement ) = @{ $special_command_line->{'If'} }{ 'Condition', 'Statement' };
            if ( $self->_handle_condition( $condition, $context ) ) {
                $self->_handle_statement( $statement, $context );
            }
        }

    }

    if ( $type eq 'Goto' ) {
        my $label = $special_command_line->{'Goto'}{'Identifier'};
        $context->{'current_line'} .= 'GOTO ' . $label;
        $self->_goto_label( $label, $context, 0 );
    }

    if ( $type eq 'Call' ) {
        my $token = $special_command_line->{'Call'}{'Token'};
        $token = $self->_variable_substitution( $token, $context );
        $token = $self->_adjust_path($token);
        $context->{'current_line'} .= 'CALL ' . $token;
        if ( $token =~ /^:/ ) {
            $self->_goto_label( $token, $context, 1 );
        } else {
            ( my $first_word ) = $token =~ /\A([^\s]+)/;
            if ( $first_word =~ /(\.[^.]+)$/ ) {
                ( my $extension ) = $first_word =~ /(\.[^.]+)$/;
                if ( $extension eq '.exe' ) {
                    $self->_execute_command( $token, $context );
                } elsif ( $extension eq '.bat' || $extension eq '.cmd' ) {
                    $self->_log_line_from_context($context);
                    my $stdout = $self->run( $token, $context->{ENV} );
                    if ( !defined $context->{STDOUT} ) {
                        $context->{STDOUT} = [];
                    }
                    if ( defined $stdout ) {
                        push @{ $context->{STDOUT} }, @$stdout;
                    }
                }
            }
        }
    }

    if ( $type eq 'Set' ) {
        my ( $variable, $value ) = @{ $special_command_line->{'Set'} }{ 'Variable', 'Value' };
        $value = $self->_variable_substitution( $value, $context );
        $value = $self->_adjust_path($value);
        $context->{'current_line'} .= 'SET ' . $variable . '=' . $value;
        $context->{ENV}{$variable} = $value;
    }

    if ( $type eq 'For' ) {
        $context->{'current_line'} .= 'FOR ';
        my $token = $special_command_line->{'For'}{'Token'};

        # Handle only simple cases
        if ( $token =~ /\s*?\/F\s*?"delims="\s*%%(?<variable_bucle>[A-Z0-9]+?)\s*?in\s*?\('(?<comando>.+)'\)/i ) {
            my $comando        = $+{'comando'};
            my $parameter_name = $+{'variable_bucle'};
            $comando = $self->_variable_substitution( $comando, $context );
            $comando = $self->_adjust_path($comando);
            $comando =~ s/%%/%/g;

            $context->{'current_line'} .= '/F "delims="' . $parameter_name . ' in ' . "'$comando' ";
            my $salida = $self->_for_command_evaluation($comando);

            my $statement = $special_command_line->{'For'}{'Statement'};

            $context->{'PARAMETERS'}{$parameter_name} = $salida;

            $self->_handle_statement( $statement, $context );
            delete $context->{'PARAMETERS'}{$parameter_name};
        } elsif ( $token =~ /\s*?%%(?<variable_bucle>[A-Z0-9]+?)\s*?in\s*?(\([\d]+(?:,[^,\s]+)+\))/i ) {
            my $statement      = $special_command_line->{'For'}{'Statement'};
            my $parameter_name = $+{'variable_bucle'};
            my $value_list     = $2;
            $value_list =~ s/(\(|\))//g;
            my @values = split( /,/, $value_list );
            $context->{'current_line'} .= $token . ' do ';
            for my $value (@values) {
                $context->{'PARAMETERS'}->{$parameter_name} = $value;
                $context->{'current_line'} .= "\n\t";
                $self->_handle_statement( $statement, $context );
                delete $context->{'PARAMETERS'}{$parameter_name};
            }

        } else {
            Carp::confess('FOR functionality not implemented!');
        }
    }

    if ( $type eq 'Echo' ) {
        $context->{'current_line'} .= 'ECHO ';
        my $echo = $special_command_line->{'Echo'};
        if ( exists $echo->{'EchoModifier'} ) {
            $context->{'current_line'} .= $echo->{'EchoModifier'};
        } else {
            my $message = $echo->{'Message'};
            $message = $self->_variable_substitution( $message, $context );
            $context->{'current_line'} .= $message;
        }
    }
}

sub _handle_condition {
    my $self      = shift();
    my $condition = shift();
    my $context   = shift();

    my ($type) = keys %$condition;
    if ( $type eq 'Comparison' ) {
        my ( $left_operand, $operator, $right_operand ) =
          @{ $condition->{'Comparison'} }{qw(LeftOperand Operator RightOperand)};

        $left_operand  = $self->_variable_substitution( $left_operand,  $context );
        $right_operand = $self->_variable_substitution( $right_operand, $context );

        $context->{'current_line'} .= $left_operand . ' ' . $operator . ' ' . $right_operand . ' ';

        my $uppercase_operator = uc($operator);
        if ( $operator eq '==' || $uppercase_operator eq 'EQU' ) {
            my $a = $left_operand  =~ s/\s*(.*)\s*/$1/r;
            my $b = $right_operand =~ s/\s*(.*)\s*/$1/r;
            return $a eq $b;
        } elsif ( $uppercase_operator eq 'NEQ' ) {
            return $left_operand != $right_operand;
        } elsif ( $uppercase_operator eq 'LSS' ) {
            return $left_operand < $right_operand;
        } elsif ( $uppercase_operator eq 'LEQ' ) {
            return $left_operand <= $right_operand;
        } elsif ( $uppercase_operator eq 'GTR' ) {
            return $left_operand > $right_operand;
        } elsif ( $uppercase_operator eq 'GEQ' ) {
            return $left_operand >= $right_operand;

        } else {
            die "Operator: $operator not implemented";
        }
    } elsif ( $type eq 'Exists' ) {
        my $path = ${ $condition->{'Exists'} }{'Path'};
        $path = $self->_variable_substitution( $path, $context );
        $path = $self->_adjust_path($path);
        $context->{'current_line'} .= 'EXIST ' . $path;

        # Glob expansion
        my @paths       = File::Glob::bsd_glob($path);
        my $file_exists = 1;
        if (@paths) {
            for my $expanded_path (@paths) {
                $file_exists = $file_exists && -e $expanded_path;
            }
            return $file_exists;
        } else {
            return 0;    # If bsd_glob returns and empty array there is no such file
        }
    } else {
        die "Condition type $type not implemented";
    }
    return 0;
}

sub _variable_substitution {
    my $self    = shift();
    my $string  = shift();
    my $context = shift();

    if ( !defined $context ) {
        Carp::cluck "Please provide a context for variable substitution";
    }

    my $parameters = $context->{'PARAMETERS'};
    if ( defined $parameters && scalar keys %$parameters > 0 ) {

        my $handle_parameter_sustitution = sub {
            my $parameter_name = shift();
            if ( exists $parameters->{$parameter_name} ) {
                return $parameters->{$parameter_name};
            } else {
                Carp::cluck "Parameter not defined: $parameter_name";
                return '';
            }
        };
        $string =~ s/%%([A-Za-z])/$handle_parameter_sustitution->($1)/eg;
    }

    my $handle_variable_manipulations = sub {
        my $variable_name = shift();
        my $manipulation  = shift();

        if ( defined $variable_name && $variable_name ne '' ) {

            my $result = $context->{'ENV'}{$1};
            if ( defined $result ) {
                if ( defined $manipulation && $manipulation ne '' ) {
                    $manipulation =~ s/^://;
                    if ( $manipulation =~ /^~(?<from>\d+),(?<length>\d+)$/ ) {
                        $result = substr( $result, $+{'from'}, $+{'length'} );
                    } elsif ( $manipulation =~ /^~(?<from_end>-\d+),(?<length>\d+)$/ ) {
                        $result = substr( $result, $+{'from_end'}, $+{'length'} );
                    } elsif ( $manipulation =~ /^\~(\-\d)+$/ ) {
                        $result = substr( $result, $1 );
                    } else {
                        Carp::cluck
                          "Variable manipulation not understood: $manipulation over variable: $variable_name. Returning unchanged variable: $result";
                        return $result;
                    }
                }
                return $result;
            } else {
                Carp::cluck("Variable: $variable_name not defined");
            }
            return '';
        } else {
            return '%%';
        }
    };

    $string =~ s/%([\w\#\$\'\(\)\*\+\,\-\.\?\@\[\]\`\{\}\~]*?)(:.+?)?%/$handle_variable_manipulations->($1, $2)/eg;

    $string =~ s/%%/%/g;

    return $string;
}

sub _adjust_path {
    my $self = shift();
    my $path = shift();
    if ( !( $^O =~ 'Win' ) ) {
        $path =~ s/\\/\//g;
    }
    return $path;
}

sub _execute_command {
    my $self = shift();
    $self->executor->execute_command(@_);
}

sub _goto_label {
    my $self    = shift();
    my $label   = shift();
    my $context = shift();
    my $call    = shift();
    $label =~ s/^://;
    $label =~ s/ //g;
    if ( $context->{'LABEL_INDEX'}{$label} ) {
        if ( $label =~ /eof/i ) {
            my $stack_frame = pop @{ $context->{'STACK'} };
            if ( defined $stack_frame ) {
                $context->{'IP'} = $stack_frame->{'IP'} + 1;
            } else {
                $context->{'IP'} = $context->{'LABEL_INDEX'}{$label};
            }
        } else {
            if ($call) {
                push @{ $context->{'STACK'} }, { IP => $context->{'IP'} };
            }
            $context->{'IP'} = $context->{'LABEL_INDEX'}{$label};
        }
    } else {
        die "Label: $label not indexed. Index contains: " . Dumper( $context->{'LABEL_INDEX'} );
    }
}

sub _for_command_evaluation {
    my $self    = shift();
    my $comando = shift();
    return $self->executor->execute_for_command($comando);
}

sub _log_line_from_context {
    my $self    = shift();
    my $context = shift();
    my $line    = $context->{'current_line'};
    if ( defined $line && $line ne '' ) {
        $self->linelogger->log_line( $context->{'current_line'} );
    }
    $context->{'current_line'} = '';
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bat::Interpreter - Pure perl interpreter for a small subset of bat/cmd files

=head1 VERSION

version 0.025

=head1 SYNOPSIS

 #!/usr/bin/env perl -w
 
 use 5.014;
 use Bat::Interpreter;
 
 my $interpreter = Bat::Interpreter->new;
 
 $interpreter->run('basic.cmd');
 
 say join("\n", @{$interpreter->executor->commands_executed});

=head1 DESCRIPTION

Pure perl interpreter for a small subset of bat/cmd files.

=for markdown [![Build status](https://ci.appveyor.com/api/projects/status/xi8e6fjjxwfp77th/branch/master?svg=true)](https://ci.appveyor.com/project/pablrod/p5-bat-interpreter/branch/master)

=head1 METHODS

=head2 run

Run the interpreter

=head1 BUGS

Please report any bugs or feature requests via github: L<https://github.com/pablrod/p5-Bat-Interpreter/issues>

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=head1 CONTRIBUTORS

=for stopwords andres.mari eva.dominguez Eva juanradiego Nicolas De los Santos pablo.rodriguez ricardo.gomez Toby Inkster

=over 4

=item *

andres.mari <andres.mari@meteologica.com>

=item *

eva.dominguez <eva.dominguez@meteologica.com>

=item *

Eva <meloncego@gmail.com>

=item *

juanradiego <kilaweo@gmail.com>

=item *

Nicolas De los Santos <ndls05@gmail.com>

=item *

pablo.rodriguez <pablo.rodriguez@meteologica.com>

=item *

ricardo.gomez <ricardogomezescalante@gmail.com>

=item *

Toby Inkster <tobyink@cpan.org>

=back

=cut
