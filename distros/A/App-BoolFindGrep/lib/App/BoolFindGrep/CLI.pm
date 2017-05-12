package App::BoolFindGrep::CLI;

use common::sense;
use charnames q(:full);
use English qw[-no_match_vars];
use Moo;
use App::BoolFindGrep;

our $VERSION = '0.06'; # VERSION

has args   => ( is => q(rw), default => sub { {}; }, );
has result => ( is => q(rw), default => sub { []; }, );
has files_with_matches => ( is => q(rw) );

sub process {
    my $self = shift;

    my $controller = App::BoolFindGrep->new( $self->args() );
    local $EVAL_ERROR;
    eval { $controller->process(); };
    if ($EVAL_ERROR) {
        if ($EVAL_ERROR =~    #
            m{\A(?<msg>.*?)
              \sat\s
              (?<module>.*?)
              \sline\s
              (?<line>\d+)\.\s*\z
             }msx
            )
        {
            say STDERR sprintf q(%s: %s), $PROGRAM_NAME,
                $LAST_PAREN_MATCH{msg};
        }
        return;
    } ## end if ($EVAL_ERROR)

    if ( defined $self->args->{match_expr} ) {
        my ( %result, $num_max );
        foreach my $file ( sort @{ $controller->greped_files() } ) {
            next unless exists $controller->grep->content_found->{$file};
            foreach my $number (
                keys %{ $controller->grep->content_found->{$file} } )
            {
                if ( !( defined $num_max ) || $number > $num_max ) {
                    $num_max = $number;
                }
                $result{$file}{$number}
                    = $controller->grep->content_found->{$file}{$number};
            }
        }
        foreach my $file ( sort keys %result ) {
            if ( $self->files_with_matches() ) {
                push @{ $self->result() }, $file;
                next;
            }
            foreach my $number ( sort { $a <=> $b } keys %{ $result{$file} } )
            {
                my $string = $result{$file}{$number};
                my $result = sprintf q(%s:%.*d:%s),     #
                    $file, length $num_max, $number, $string;
                push @{ $self->result() }, $result;
            }
        }

    } ## end if ( defined $self->args...)
    else { @{ $self->result() } = @{ $controller->found_files() }; }

    @{ $self->result() } = sort @{ $self->result() };

    return 1;
} ## end sub process

sub args_checker {
    my $self = shift;
    my %arg  = splice @_;

    $self->_args_translator(%arg);

    my %rule = (
        q(are mutually exclusive.) => [
            [ qw[file_expr files_from], ],
            [ qw[line_regexp word_regexp], ],
            [ qw[directory files_from], ],
            [ qw[fixed_strings glob_regexp], ],
        ],
        q(an empty value was given.) =>
            [qw[file_delim file_expr files_from match_expr directory]],
        q(implies) => [
            { find_type          => [q(file_expr)] },
            { find_ignore_case   => [q(file_expr)] },
            { files_delim        => [q(files_from)] },
            { ignore_case        => [q(match_expr)] },
            { line_regexp        => [q(match_expr)] },
            { word_regexp        => [q(match_expr)] },
            { files_with_matches => [q(match_expr)] },
        ],
    );

    foreach my $msg ( keys %rule ) {
        if ( $msg eq q(are mutually exclusive.) ) {
            return
                unless $self->_mutually_exclusive_checker( $msg,
                $rule{$msg} );
        }
        elsif ( $msg eq q(an empty value was given.) ) {
            return unless $self->_empty_value_checker( $msg, $rule{$msg} );
        }
        elsif ( $msg eq q(implies) ) {
            return unless $self->_implies_checker( $msg, $rule{$msg} );
        }
        else { die; }
    }

    foreach my $parameter ( keys %{ $self->args() } ) {
        my $value = $self->args->{$parameter};
        my $checker = sprintf q(_%s_checker), $parameter;
        if ( $parameter eq q(files_with_matches) ) {
            $self->$parameter( delete $self->args->{$parameter} );
        }
        elsif ( $self->can($checker) ) {
            return unless $self->$checker($value);
        }
    }

    return 1;
} ## end sub args_checker

sub _args_translator {
    my $self = shift;
    my %arg  = splice @_;

    my %array2scalar = (
        file_expr  => 1,
        match_expr => 1,
    );
    while ( my ( $arg, $value ) = each %arg ) {
        my $key = $arg;
        $key =~ tr{-}{_};
        if ( $key eq q(files_delim) ) {
            if ( $value eq q(\0) ) {
                $value = qq(\N{NULL});
            }
        }
        elsif ( exists $array2scalar{$key} ) {
            my $ref = ref $value // q();
            $value = "@$value" if $ref eq q(ARRAY);
        }
        $self->args->{$key} = $value;
    }

    return 1;
} ## end sub _args_translator

sub _mutually_exclusive_checker {
    my $self  = shift;
    my $msg   = shift;
    my $pairs = shift;

    foreach my $keys ( @{$pairs} ) {
        my @key = @{$keys};
        if ( @key == ( grep { exists $self->args->{$_} } @key ) ) {
            $self->_msg( sprintf q('--%s' and '--%s' ) . $msg, @key );
            return;
        }
    }

    return 1;
} ## end sub _mutually_exclusive_checker

sub _empty_value_checker {
    my $self = shift;
    my $msg  = shift;
    my $keys = shift;

    foreach my $key ( @{$keys} ) {
        next unless exists $self->args->{$key};
        my $ref = ref $self->args->{$key} || q();
        my @value;
        if    ( $ref eq q() )      { @value = $self->args->{$key}; }
        elsif ( $ref eq q(ARRAY) ) { @value = @{ $self->args->{$key} }; }
        else                       { die; }

        if ( ( grep { $_ eq q() } @value ) != 0 ) {
            $self->_msg( sprintf q('--%s': ) . $msg, $key );
            return;
        }
    }

    return 1;
} ## end sub _empty_value_checker

sub _implies_checker {
    my $self    = shift;
    my $msg     = shift;
    my $implies = shift;

    foreach my $imply ( @{$implies} ) {
        foreach my $key ( keys %{$imply} ) {
            next unless exists $self->args->{$key};
            foreach my $skey ( @{ $imply->{$key} } ) {
                unless ( exists $self->args->{$skey} ) {
                    $self->_msg( sprintf q('--%s' %s '--%s' option.),
                        $key, $msg, $skey );
                    return;
                }
            }
        }
    }

    return 1;
} ## end sub _implies_checker

sub _files_from_checker {
    my $self  = shift;
    my $value = shift;

    my $parameter = ( split m{::_(\S+)_checker\z}msx, ( caller 0 )[3] )[-1];

    my $msg;
    foreach ($value) {
        if ( !/\A(?:-|stdin)\z/i ) {
            if ( !-e ) {
                $msg = sprintf q('--%s' => nonexistent file '%s'.),
                    $parameter, $value;
            }
            elsif ( !-f ) {
                $msg = sprintf q('--%s' => irregular file '%s'.),
                    $parameter, $value;
            }
            elsif ( !-r ) {
                $msg = sprintf q('--%s' => unreadable file '%s'.),
                    $parameter, $value;
            }
            elsif (-z) {
                $msg = sprintf q('--%s' => empty file '%s'.),
                    $parameter, $value;
            }
        } ## end if ( !/\A(?:-|stdin)\z/i)
    } ## end foreach ($value)

    if ( defined $msg ) { $self->_msg($msg); return; }

    $self->args->{files_delim} = qq(\N{LINE FEED});

    return 1;
} ## end sub _files_from_checker

sub _find_type_checker {
    my $self  = shift;
    my $value = shift;

    my $parameter = ( split m{::_(\S+)_checker\z}msx, ( caller 0 )[3] )[-1];
    my %type = (
        glob    => 1,    #
        literal => 1,    #
        regexp  => 1,    #
    );

    unless ( exists $type{$value} ) {
        $self->_msg( sprintf q('--%s' => argument invalid '%s'.),
            $parameter, $value );
        return;
    }

    return 1;
} ## end sub _find_type_checker

sub _directory_checker {
    my $self   = shift;
    my $values = shift;

    my $parameter = ( split m{::_(\S+)_checker\z}msx, ( caller 0 )[3] )[-1];

    my $msg;
    foreach ( @{$values} ) {
        if ( !-e ) {
            $msg = sprintf q('--%s' => nonexistent directory '%s'.),
                $parameter, $_;
        }
        elsif ( !-d ) {
            $msg = sprintf q('--%s' => non-directory argument '%s'.),
                $parameter, $_;
        }
        elsif ( !-r ) {
            $msg = sprintf q('--%s' => unreadable directory '%s'.),
                $parameter, $_;
        }
        if ( defined $msg ) { $self->_msg($msg); return; }
    } ## end foreach ( @{$values} )

    return 1;
} ## end sub _directory_checker

sub _msg {
    my $self = shift;
    my $msg  = shift;

    say STDERR sprintf q(%s: %s), $PROGRAM_NAME, $msg;
    say STDERR sprintf q(Try '%s --help' for more information.),
        $PROGRAM_NAME;

    return 1;
}

no Moo;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::BoolFindGrep::CLI - Command Line Interface functions.

=head1 VERSION

version 0.06

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 args

Hash reference with command line arguments.

=head2 args_checker

Process, transform and validade arguments.

=head2 files

Array reference with searching results.

=head2 process

Does the work.

=head1 OPTIONS

=head1 ERRORS

=head1 DIAGNOSTICS

=head1 EXAMPLES

=head1 ENVIRONMENT

=head1 FILES

=head1 CAVEATS

=head1 BUGS

=head1 RESTRICTIONS

=head1 NOTES

=head1 AUTHOR

Ronaldo Ferreira de Lima aka jimmy <jimmy at gmail>.

=head1 HISTORY

=head1 SEE ALSO

=cut
