package Acme::Sub::Parms;

use strict;
use warnings;
use Filter::Util::Call;

BEGIN {
    $Acme::Sub::Parms::VERSION  = '1.03';
    %Acme::Sub::Parms::args     = ();
    %Acme::Sub::Parms::raw_args = ();
    $Acme::Sub::Parms::line_counter   = 0;
}

sub _NORMALIZE    ()   { return ':normalize';    };
sub _NO_VALIDATION  () { return ':no_validation';  };
sub _DUMP           () { return ':dump_to_stdout'; };
sub _DEBUG          () { 0; };

sub _legal_option {
    return {
        _NORMALIZE()     => 1,
        _NO_VALIDATION() => 1,
        _DUMP()          => 1,
    }->{$_[0]};
}

####

sub import {
    my $class = shift;
    my $options = {
           _NORMALIZE()      => 0,
           _NO_VALIDATION()  => 0,
           _DUMP()           => 0,
           };
    foreach my $item (@_) {
        if (not _legal_option($item)) {
            my $package = __PACKAGE__;
            require Carp;
            Carp::croak("'$item' not a valid option for 'use $package'\n");
        }
        $options->{$item} = 1;
    }
    $Acme::Sub::Parms::line_counter = 0;
    my $ref   = {'options' => $options, 'bind_block' => 0 };
    filter_add(bless $ref); # imported from Filter::Util::Call
}

####

sub _parse_bind_spec {
    my ($self, $raw_spec) = @_;

    my $spec = $raw_spec;

    my $spec_tokens = {
        'is_defined' => 0,
        'required'   => 1,
        'optional'   => 0,
    };
    while ($spec ne '') {
        if ($spec =~ s/^required(\s*,\s*|$)//) { # 'required' flag
            $spec_tokens->{'required'} = 1;
            $spec_tokens->{'optional'} = 0;

        } elsif ($spec =~ s/^optional(\s*,\s*|$)//) { # 'optional' flag
            $spec_tokens->{'required'} = 0;
            $spec_tokens->{'optional'} = 1;

        } elsif ($spec =~ s/^is_defined(\s*,\s*|$)//) { # 'is_defined' flag
            $spec_tokens->{'is_defined'} = 1;

        } elsif ($spec =~ s/^(can|isa|type|callback|default)\s*=\s*//) { # 'something="somevalue"'
            my $spec_key = $1;

            # Simple unquoted text with no embedded ws
            if ($spec =~ s/^([^\s"',]+)(\s*,\s*|$)//) {
                $spec_tokens->{$spec_key} = $1;

            # Single quoted text with no embedded quotes
            } elsif ($spec =~ s/^'([^'\/]+)'\s*,\s*//) {
                $spec_tokens->{$spec_key} = "'$1'";

            # Double quoted text with no embedded quotes or escapes
            } elsif ($spec =~ s/^"([^"\/]+)"\s*,\s*//) {
                $spec_tokens->{$spec_key} = '"' . $1 . '"';

            # It is a tricky case with quoted characters. One character at a time it is.
            } elsif ($spec =~ s/^(['"])//) {
                my $quote = $1;
                my $upend_spec  = reverse $spec;
                my $block_done  = 0;
                my $escape_next = 0;
                my $token       = $quote;
                until ($block_done || ($upend_spec eq '')) {
                    my $ch = chop $upend_spec;
                    if ($escape_next) {
                        $token      .= $ch;
                        $escape_next = 0;

                    } elsif (($ch eq "\\") && (not $escape_next)) {
                        $token      .= $ch;
                        $escape_next = 1;

                    } elsif ($ch eq $quote) {
                        $block_done = 1;

                    } else {
                        $token .= $ch;
                    }
                }
                if ($escape_next) {
                    die("Syntax error in BindParms spec: $raw_spec\n");
                }
                $spec = reverse $upend_spec;
                $spec_tokens->{$spec_key} = $token . $quote;

            } else {
                die("Syntax error in BindParms spec: $raw_spec\n");
            }
        } else {
            die("Syntax error in BindParms spec: $raw_spec\n");
        }
    }
    return $spec_tokens;
}

###############################################################################
# bind_spec is intentionally a a non-POD documented'public' method. It can be overridden in a sub-class
# to provide alternative features.
# 
# It takes two parameters: 
#
#  $raw_spec             - this is the content of the [....] block (not including the '[' and ']' block delimitters)
#  $field_name           - the hash key for the field being processed
# 
# As each line of the BindParms block is processed the two parameters for each line are passed to the bind_spec
# method for evaluation. bind_spec should return a string containing any Perl code generated as a result of
# the bind specification.
#
# Good style dictates that the returned output should be *ONE* line (it could be a very *long* line)
# so that line numbering in the source file is preserved for any error messages.
#
sub bind_spec {
    my $self = shift;
    my ($raw_spec, $field_name) = @_;

    my $options        = $self->{'options'};
    my $no_validation  = $options->{_NO_VALIDATION()};

    my $spec_tokens = $self->_parse_bind_spec($raw_spec);

    my $has_side_effects = 0;
    my $output = '';

    my @spec_tokens_list = keys %$spec_tokens;
    if ((0 == @spec_tokens_list) || ((1 == @spec_tokens_list) && ($spec_tokens->{'optional'}))) {
        return;
    }

    ######################
    # default="some value"
    if (defined $spec_tokens->{'default'}) {
        if ($spec_tokens->{'optional'}) {
            $output .= "unless (exists (\$Acme::Sub::Parms::args\{'$field_name'\})) \{ \$Acme::Sub::Parms::args\{'$field_name'\} = " . $spec_tokens->{'default'} . ";\} ";
        } else { # required
            $output .= "unless (defined (\$Acme::Sub::Parms::args\{'$field_name'\})) \{ \$Acme::Sub::Parms::args\{'$field_name'\} = " . $spec_tokens->{'default'} . ";\} ";
        }
        $has_side_effects = 1;
    }

    ######################
    # callback="some_subroutine"
    if ($spec_tokens->{'callback'}) {
        $output .= "\{ my (\$callback_is_valid, \$callback_error) = "
                    . $spec_tokens->{'callback'}
                    . "(\'$field_name\', \$Acme::Sub::Parms::args\{\'$field_name\'\}, \\\%Acme::Sub::Parms::args);"
                    . "unless (\$callback_is_valid) { require Carp; Carp::croak(\"$field_name error: \$callback_error\"); }} ";
        $has_side_effects = 1;
    }

    ######################
    # required 
    if ((! $no_validation) && $spec_tokens->{'required'}) {
        $output .= "unless (exists (\$Acme::Sub::Parms::args\{\'$field_name\'\})) { require Carp; Carp::croak(\"Missing required parameter \'$field_name\'\"); } ";
    }

    ######################
    # is_defined 
    if ($spec_tokens->{'is_defined'}) {
        $output .= "if (exists (\$Acme::Sub::Parms::args\{\'$field_name\'\}) and (! defined (\$Acme::Sub::Parms::args\{\'$field_name\'\}))) { require Carp; Carp::croak(\"parameter \'$field_name\' cannot be undef\"); } ";
    }

    my $type_requirements = $spec_tokens->{'type'};
    my $isa_requirements  = $spec_tokens->{'isa'};
    my $can_requirements  = $spec_tokens->{'can'};

    if (defined ($type_requirements ) || defined($isa_requirements) || defined($can_requirements)) {
        $output .=  "if (exists (\$Acme::Sub::Parms::args\{\'$field_name\'\})) \{";

        #####################
        # type="SomeRefType" or type="SomeRefType, SomeOtherRefType, ..."
        if (defined $type_requirements) {
            $type_requirements =~ s/^['"]//;
            $type_requirements =~ s/['"]$//;
            my @type_classes = split(/[,\s]+/, $type_requirements);
            $output .= "unless (";
            my @type_tests = ();
            foreach my $class_name (@type_classes) {
                push (@type_tests, "ref(\$Acme::Sub::Parms::args\{'$field_name'\}) eq '$class_name')");
            }
            $output .= join(' || ',@type_tests) . " \{ require Carp; Carp::croak(\'parameter \\\'$field_name\\\' must be a " . join(' or ',@type_classes) . "\'); \}";
        }

        #####################
        # isa="SomeRefType" or isa="SomeRefType, SomeOtherRefType, ..."
        if (defined $isa_requirements) {
            $isa_requirements =~ s/^['"]//;
            $isa_requirements =~ s/['"]$//;
            my @isa_classes = split(/[,\s]+/, $isa_requirements);
            $output .= "unless (";
            my @isa_tests = ();
            foreach my $class_name (@isa_classes) {
                push (@isa_tests, "\$Acme::Sub::Parms::args\{'$field_name'\}->isa('$class_name')");
            }
            $output .= join(' || ',@isa_tests) . ") \{ require Carp; Carp::croak(\'parameter \\\'$field_name\\\' must be a " . join(' or ',@isa_classes) . " instance or subclass\'); \}";
        }

        #####################
        # can="somemethod" or can="somemethod, someothermethod, ..."
        if (defined $can_requirements) {
            $can_requirements =~ s/^['"]//;
            $can_requirements =~ s/['"]$//;
            my @can_methods = split(/[,\s]+/, $can_requirements);
            $output .= "unless ("; 
            my @can_tests = ();
            foreach my $method_name (@can_methods) {
                push (@can_tests, "\$Acme::Sub::Parms::args\{'$field_name'\}->can('$method_name')");
            }
            $output .= join(' && ',@can_tests) . ") \{ require Carp; Carp::croak(\'parameter \\\'$field_name\\\' must be an object with a " . join(' and a ',@can_methods) . " method\'); \}";
        }

        $output .= "\}";
    }

    return ($has_side_effects,$output);
}

####

sub filter {
    my $self = shift;

    my $options        = $self->{'options'};
    my $dump_to_stdout = $options->{_DUMP()};
    my $normalize      = $options->{_NORMALIZE()};
    my $no_validation  = $options->{_NO_VALIDATION()};
    my $bind_block     = $self->{'bind_block'};

    my $status;

    if ($status = filter_read() > 0) { # imported from Filter::Util::Call
    	$Acme::Sub::Parms::line_counter++;
        
        if (_DEBUG) {
            print STDERR "input line $Acme::Sub::Parms::line_counter: $_";	
        }
   
        #############################################
        # If we are in a bind block, handle it
        if ($bind_block) {
            my $bind_entries = $self->{'bind_entries'};
            my $simple_bind  = $self->{'simple_bind'};

            ##############################
            # Last line of the bind block? Generate the working code.
            if (m/^\s*\)(\s*$|\s*#.*$)/) {
            	
            	my $block_trailing_comment = $2;
            	$block_trailing_comment = defined($block_trailing_comment) ? $block_trailing_comment : '';
            	$block_trailing_comment =~ s/[\r\n]+$//s;
                my $side_effects = 0;
                my $args = 'local %Acme::Sub::Parms::args; '; # needed?
                if ($normalize) {
                    $args .= '{ local $_; local %Acme::Sub::Parms::raw_args = @_; %Acme::Sub::Parms::args = map { lc($_) => $Acme::Sub::Parms::raw_args{$_} } keys %Acme::Sub::Parms::raw_args; }' . "\n";
                } else {
                    $args .= '%Acme::Sub::Parms::args = @_;' . "\n";
                }
                # If we have validation or defaults, handle them
                my $padding_lines = 0;
                if (! $simple_bind) { 
                    my @parm_declarations = ();
                    foreach my $entry (@$bind_entries) {
                        my $variable_decl    = $entry->{'variable'};
                        my $field_name       = $entry->{'field'};
                        my $spec             = $entry->{'spec'};
                        my $trailing_comment = $entry->{'trailing_comment'};
                        if ( (! defined($spec)) || ($spec eq '')) {
                            # push(@parm_declarations, $trailing_comment);
                            next;
                        }
                        # The hard case. We have validation requirements.
                        my ($has_side_effects, $bind_spec_output) = $self->bind_spec($spec, $field_name);
                        $side_effects += $has_side_effects;
                        push (@parm_declarations, "$bind_spec_output$trailing_comment");
                    }
                    $args .=  join("\n",@parm_declarations,'');
                }

                # Generate the actual parameter data binding
                my @var_declarations      = ();
                my @hard_var_declarations = ();
                my @field_declarations    = ();
                my @fields_list           = ();
                foreach my $entry (@$bind_entries) {
                	my $spec       = $entry->{'spec'};
                	next if ((not defined $spec) || ($spec eq ''));
                    my $raw_var    = $entry->{'variable'};
                    my $field_name = $entry->{'field'};
                    
                    push (@fields_list, "'$field_name'");
                    my ($variable_name) = $raw_var =~ m/^my\s+(\S+)$/;
                    if (defined $variable_name) { # simple 'my $variable :' entries are special-cased for performance
                        push (@var_declarations,   $variable_name);
                        push (@field_declarations, "'$field_name'");

                    } else { # Otherwise make a seperate entry for this binding
                        push (@hard_var_declarations, "$raw_var = \$Acme::Sub::Parms::args\{$field_name\};");
                    }
                }
                my $hard_args = join(' ',@hard_var_declarations);
                my $arg_line  = '';
                if (0 < @var_declarations) {
                 
                    if ($simple_bind && (! $normalize) && $no_validation && (0 == $side_effects) && (0 == @hard_var_declarations)) {
                       $args = "\n    my (" . join(",", @var_declarations) . ') = @{{@_}}{' . join(',',@field_declarations) . '}; ';

                    } else {
    
                        $arg_line  = 'my (' . join(",", @var_declarations) . ') = @Acme::Sub::Parms::args{' . join(',',@field_declarations) . '}; ';
                    }
                }
                my $unknown_parms_check = '';
                unless ($no_validation) {
                    $unknown_parms_check = 'delete @Acme::Sub::Parms::args{' . join(',',@fields_list) . '}; if (0 <  @Acme::Sub::Parms::args) { require Carp; Carp::croak(\'Unexpected parameters passed: \' . join(\', \',@Acme::Sub::Parms::args)); } ';

                }
                $self->{'bind_block'} = 0;
                my $original_block_length = $Acme::Sub::Parms::line_counter - $self->{'line_block_start'};
                my $new_block = $args . join(' ',$arg_line, $hard_args, $unknown_parms_check) . "$block_trailing_comment\n";
                $new_block =~ s/\n+/\n/gs;
                my $new_block_lines = $new_block =~ m/\n/gs;
                
                my $additional_lines = $original_block_length - $new_block_lines;
                #warn("Need $additional_lines extra lines\n---\n$new_block---\n");
                if ($additional_lines > 0) {
                    $_ = $new_block . ("\n" x $additional_lines);	
                } else {
                    $_ = $new_block;	
                }

            ########################
            # Bind block parameter line
            } elsif (my($bind_var, $bind_field,$trailing_comment) = m/^\s*(\S.*?)\s+:\s+([^'"\s\[]+.*?)\s*(;\s*|;\s*#.*)$/) {
            	$trailing_comment = defined($trailing_comment) ? $trailing_comment : '';
            	$trailing_comment =~ s/[\r\n]+$//s;
            	$trailing_comment =~ s/^;//;
                my $bind_entry = { 'variable' => $bind_var, 'field' => $bind_field, trailing_comment => $trailing_comment };
                push (@$bind_entries, $bind_entry);
                if ($bind_var !~ m/^my \$\S+$/) {
                    $self->{'simple_bind'} = 0;
                }
                if ($bind_field =~ m/^(\S+)\s*\[(.*)\]$/) { # Complex spec
                    $bind_entry->{'field'} = $1;
                    $bind_entry->{'spec'}  = $2;
                    unless ($no_validation && ($bind_field !~ m/[\s\[,](default|callback)\s*=\s*/)) {
                        $self->{'simple_bind'} = 0;
                    }
                } elsif ($bind_field =~ m/^\w+$/) { # my $thing : something;
                	$bind_entry->{'spec'}  = 'required';
                	unless ($no_validation) {
                		$self->{'simple_bind'} = 0;	
                    }
                } else {
                	die("Failed to parse BindParms block line $Acme::Sub::Parms::line_counter: $_");
                }
                undef $trailing_comment;
                undef $bind_var;
                undef $bind_field;
                $_ = '';

            ############################
            # Blank and comment only lines
            } elsif (m/^(\s*|\s*#.*)$/) {
            	my $trailing_comment = $1;
            	$trailing_comment = defined ($trailing_comment) ? $trailing_comment : '';
            	$trailing_comment =~ s/[\r\n]+$//s;
            	
                my $bind_entry = { spec => '', trailing_comment => $trailing_comment};
                push (@$bind_entries, $bind_entry);
                $_ = '';
                
            } else {
                die("Failed to parse BindParms block line $Acme::Sub::Parms::line_counter: $_");
            }

        } else { # Start of a bind block
            if (m/^\s*BindParms\s+:\s+\((\s*#.*$|\s*$)/) {
                $self->{'simple_bind'}  = 1;
                $self->{'bind_entries'} = [];
                $self->{'bind_block'}   = 1;
                $self->{'line_block_start'} = $Acme::Sub::Parms::line_counter;
                my $block_head_comment = $2;
                $block_head_comment = defined ($block_head_comment) ? $block_head_comment : '';
                $block_head_comment =~ s/[\r\n]+$//s;
                $_ = $block_head_comment;

#######
#            ################################
#            # Invokation : $self;
#            } elsif (my ($ihead,$ivar,$itail) = m/^(\s*)Invokation\s+:\s+(\S+.*?)\s*;(.*)$/) {
#                $_ = $ihead . " my $ivar = shift @_;$itail\n";
#
#            ################################
#            # ParmsHash : %args;
#            } elsif (my ($fhead,$func_hash_ident,$ftail) = m/^(\s*)ParmsHash\s+:\s+(\S+.*?)\s*;(.*)$/) {
#                if ($normalize) {
#                    $_ = "${fhead}my $func_hash_ident; { local \%Acme::Sub::Parms::raw_args = \@\_; $func_hash_ident = map \{ lc(\$\_\) \=\> \$Acme::Sub::Parms::raw_args\{\$\_\} \} keys \%Acme::Sub::Parms::raw_args; } $ftail\n";
#                } else {
#                    $_ = "${fhead}my $func_hash_ident = \@\_;$ftail\n";
#                }
#
#            ################################
#            # MethodParms : $self, %args;
#            } elsif (my ($mhead,$method_invokation,$method_hash_ident,$mtail) = m/^(\s*)MethodParms\s+:\s+(\S+.*?)\s*,\s*(\S+.*?)\s*;(.*)$/) {
#                if ($normalize) {
#                    $_ = "${mhead}my $method_invokation = shift; my $method_hash_ident; { local \$_; local \%Acme::Sub::Parms::raw_args = \@\_; $method_hash_ident = map \{ lc(\$\_\) \=\> \$Acme::Sub::Parms::raw_args\{\$\_\} \} keys \%Acme::Sub::Parms::raw_args; } $mtail\n";
#                } else {
#                    $_ = "${mhead}my $method_invokation = shift; my $method_hash_ident = \@\_; $mtail\n";
#                }
#######
            }
        }
    }
    if (_DEBUG) {
    	print STDERR "output as: $_";	
    }
    if ($dump_to_stdout) { print $_; }

    return $status;
}

####

1;

