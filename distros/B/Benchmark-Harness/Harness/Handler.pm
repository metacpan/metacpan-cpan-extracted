use strict;
package Benchmark::Harness::Handler;
use Benchmark::Harness::Constants;
use XML::Quote;
use overload;

use vars qw($VERSION); $VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

### ###########################################################################
# USAGE: new Benchmark::Harness::Handler(
#                       $parentHarness,
#                       modifiers_from_(...),
#                       package-name,
#                       subroutine-name)
sub new {
    my ($cls, $harness, $modifiers, $pckg, $subName) = @_;
    # If already defined, then we keep the original one
    #  ("the pen once writ . . .")
    return undef if $harness->FindHandler($pckg, $subName);

    my $self = bless [  $#{$harness->{EventList}}+1,
                        $harness,
                        $modifiers,
                        $subName,
                        $pckg,
                        undef,
                        0,
                     ], $cls;

    push @{$harness->{EventList}}, $self;
    return $self;
}

# Attached this event handler to this subroutine in the code
# Modifiers -
#           '0' : do not harness this method (even if asked to later in the parameters)
#           filter, filterStart : harness, but report only each filter-th event, starting
#                                 with the filterStart-th event. filterStart=0|undef reports
#                                 the first event, then each filter-th one thereafter.
sub Attach {
    my ($traceSubr) = @_;
    my ($modifiers, $pckg, $method) = ($traceSubr->[HNDLR_MODIFIERS], $traceSubr->[HNDLR_PACKAGE], $traceSubr->[HNDLR_NAME]);

    return if ( defined $modifiers && ($modifiers eq '0') ); # (0) means do not harness . . .

    # Splitting handler parameters by '|' makes it easier to include them in a qw()
    my ($filter, $filterStart) = (split /\s*\|\s*/, $modifiers) if defined $modifiers;

    $traceSubr->[HNDLR_ORIGMETHOD] = \&{"$pckg\:\:$method"};

    my $newMethod;
    if ( defined $filter ) {

        $filter = $filter || 1;
        $filterStart = $filterStart || 1;
        $traceSubr->[HNDLR_FILTER] = $filter;
        $traceSubr->[HNDLR_FILTERSTART] = $filterStart;

###  ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## NEW METHOD ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
        $newMethod = sub  {
            if ( $traceSubr->[HNDLR_FILTERSTART] ) {
                goto $traceSubr->[HNDLR_ORIGMETHOD] if ( --$traceSubr->[HNDLR_FILTERSTART] );
                $traceSubr->[HNDLR_FILTERSTART] = $traceSubr->[HNDLR_FILTER];
            }
            my @newArgs;
            unless ( $Benchmark::Harness::IS_HARNESS_MODE ) {
                $Benchmark::Harness::IS_HARNESS_MODE += 1;
                @newArgs = $traceSubr->OnSubEntry(@_);
                $traceSubr->harnessPrintReport('E',$traceSubr);
                $Benchmark::Harness::IS_HARNESS_MODE -= 1;
            }
            if (wantarray) {
                my @answer = $traceSubr->[HNDLR_ORIGMETHOD](@_);
                my $newAnswer;
                unless ( $Benchmark::Harness::IS_HARNESS_MODE ) {
                    $Benchmark::Harness::IS_HARNESS_MODE += 1;
                    $newAnswer = $traceSubr->OnSubExit(\@answer);
                    $traceSubr->harnessPrintReport('X',$traceSubr);
                    $Benchmark::Harness::IS_HARNESS_MODE -= 1;
                }
                return @answer;
            } else {
                my $answer;
                my $newAnswer;
                unless ( $Benchmark::Harness::IS_HARNESS_MODE ) {
                    $Benchmark::Harness::IS_HARNESS_MODE += 1;
                    $answer = $traceSubr->[HNDLR_ORIGMETHOD](@_);
                    $newAnswer = scalar $traceSubr->OnSubExit($answer);
                    $traceSubr->harnessPrintReport('X',$traceSubr);
                    $Benchmark::Harness::IS_HARNESS_MODE -= 1;
                }
                return $answer;
            }
        };
###  ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
### ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
    } else {
###  ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## NEW METHOD ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
        $newMethod = sub {
            my @newArgs;
            unless ( $Benchmark::Harness::IS_HARNESS_MODE ) {
                $Benchmark::Harness::IS_HARNESS_MODE += 1;
                @newArgs = $traceSubr->OnSubEntry(@_);
                $traceSubr->harnessPrintReport('E',$traceSubr);
                $Benchmark::Harness::IS_HARNESS_MODE -= 1;
            }
            if (wantarray) {
                my @answer = $traceSubr->[HNDLR_ORIGMETHOD](@_);
                my $newAnswer;
                unless ( $Benchmark::Harness::IS_HARNESS_MODE ) {
                    $Benchmark::Harness::IS_HARNESS_MODE += 1;
                    $newAnswer = $traceSubr->OnSubExit(\@answer);
                    $traceSubr->harnessPrintReport('X',$traceSubr);
                    $Benchmark::Harness::IS_HARNESS_MODE -= 1;
                }
                return @answer;
            } else {
                my $answer = $traceSubr->[HNDLR_ORIGMETHOD](@_);
                my $newAnswer;
                unless ( $Benchmark::Harness::IS_HARNESS_MODE ) {
                    $Benchmark::Harness::IS_HARNESS_MODE += 1;
                    $newAnswer = scalar $traceSubr->OnSubExit($answer);
                    $traceSubr->harnessPrintReport('X',$traceSubr);
                    $Benchmark::Harness::IS_HARNESS_MODE -= 1;
                }
                return $answer;
            }
        };
###  ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
### ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
    }
###  ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
## NEW METHOD ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
    no warnings; # We are redefining a method, so don't warn all that!
    eval "\*$pckg\:\:$method = \$newMethod";
    $traceSubr->[HNDLR_HANDLED] = 1;
}

sub Detach {
    my ($traceSubr) = @_;
    return unless $traceSubr->[HNDLR_HANDLED];
    my ($pckg, $method, $origMethod) = ($traceSubr->[HNDLR_PACKAGE],$traceSubr->[HNDLR_NAME],$traceSubr->[HNDLR_ORIGMETHOD]);
    no warnings; # We are redefining a method, so don't warn all that!
    eval "\*$pckg\:\:$method = \$origMethod";
}

### ###########################################################################
sub reportTraceInfo {
    my $self = shift;
    $self->[HNDLR_REPORT] = [undef,{},undef,undef] unless defined $self->[HNDLR_REPORT];
    my $rpt = $self->[HNDLR_REPORT];

    for ( @_ ) {
        my $typ = ref($_);
        if ( $typ ) {
            if ( $typ eq 'HASH' ) {
                my $hsh = $rpt->[1];
                for my $nam ( keys %$_ ) {
                    $hsh->{$nam} = $_->{$nam};
                }
            }
            elsif ( $typ eq 'ARRAY' ) {
                $rpt->[2] = [] unless defined $rpt->[2];
                push @{$rpt->[2]}, @$_;
            }
            elsif ( $typ eq 'SCALAR' ) {
                $rpt->[3] .= $$_;
            } else {
                $rpt->[3] .= $_;
            }
        } else {
                $rpt->[0] = $_;
        }
    }
    return $self;
}


### ###########################################################################
sub reportValueInfo {
    my $self = shift;

    my $val = ['V',{},undef,undef];
    for ( @_ ) {
        my $typ = ref($_);
        if ( $typ ) {
            if ( $typ eq 'HASH' ) {
                my $hsh = $val->[1];
                for my $nam ( keys %$_ ) {
                    # I figure this is the quickest way to get both
                    # the stringified (if overloaded) and type of
                    # the value in this hash-entry.
                    my $_val = $_->{$nam};
                    my $_ref = ref($_val);
                    if ( $_ref ) {
                        if ( my $stringify = overload::Method($_val,'""') ) {
                            $hsh->{$nam} = $stringify->($_val);
                            $hsh->{_t} = ref($_val);
                                #unless defined $hsh->{_t};
                        } else {
                            $hsh->{$nam} = $_val;
                        }
                    } else {
                        $hsh->{$nam} = $_val;
                    }
                }
            }
            elsif ( $typ eq 'ARRAY' ) {
                $val->[2] = [] unless defined $val->[2];
                push @{$val->[2]}, @$_;
            }
            elsif ( $typ eq 'SCALAR' ) {
                $val->[3] .= $$_;
            }
            else {
                $val->[3] .= "$_"; # will stringify if overloaded 
            }
        } else {
                $val->[0] = $_;
        }
    }

    $self->[HNDLR_REPORT] = [undef,{},[],undef] unless defined $self->[HNDLR_REPORT];
    my $rpt = $self->[HNDLR_REPORT];
    push @{$rpt->[2]}, $val;
    return $val;
}

### ###########################################################################
### harnessPrintReport ( mode, event-handler, [ report-element ] )
sub harnessPrintReport {
    my $self = shift;
    return unless ref($self);
    my $harness = $self->[HNDLR_HARNESS];

    my $mode = shift;
    my $trace = shift;
    my $rpt = shift || $self->[HNDLR_REPORT];

    return unless $rpt;

    my $fh = $harness->{_outFH};
    return unless $fh;

    print $fh '<'.(defined($rpt->[0])?$rpt->[0]:'T');
    print $fh " _i='$trace->[HNDLR_ID]' _m='$mode'" if $mode;
    my $closeTag = '/>';

    my $hsh = $rpt->[1];
    map { print $fh " $_='".xml_quote($hsh->{$_})."'" if defined $hsh->{$_} } keys %$hsh;

    if ( defined $rpt->[2] ) {
        print $fh '>'; $closeTag = '</'.(defined($rpt->[0])?$rpt->[0]:'T').'>';
        for ( @{$rpt->[2]} ) {
            $self->harnessPrintReport(undef, undef, $_);
        }
    }

    if ( defined $rpt->[3] ) {
        print $fh '>'; $closeTag = '</'.(defined($rpt->[0])?$rpt->[0]:'T').'>';
        print $fh $rpt->[3];
    }

    print $fh $closeTag;
    $self->[HNDLR_REPORT] = undef;
}

### ###########################################################################
# USAGE: Invoked by attach()'d subroutine: see above.
# This is, presumably, overridden by the sub-harness.
sub OnSubEntry {
    my $self = shift;
    return @_;
}

### ###########################################################################
# USAGE: Invoked by attach()'d subroutine: see above.
# This is, presumably, overridden by the sub-harness.
sub OnSubExit {
    my $self = shift;
    return @_;
}


### ###########################################################################
# USAGE: Harness::Variables(list of any variable(s));
sub Variables {
  my $self = ref($_[0])?shift:$Benchmark::Harness::Harness;
  return unless ref($self);
  return unless $self->{_outFH};
}


### ###########################################################################
# USAGE: Harness::Arguments(@_);
sub ArgumentsXXX {
  my $self = shift;
  return $self unless ref($self);
  return $self unless $self->{_outFH};

  $self->_PrintT('-Arguments', caller(1));

  my $i = 1;
  for ( @_ ) {
    my $obj = ref($_)?$_:\$_;
    my ($nm, $sz) = (ref($_), Devel::Size::total_size($_));
    $nm = $i unless $nm; $i += 1;
    $self->print("<V n='$nm' s='$sz'/>");
  }
  $self->_PrintT_();
  return $self;
}

### ###########################################################################
# USAGE: Harness::NamedObject($name, $self); - where $self is a blessed reference.
sub NamedObjects {
  my $self = shift;
  return $self unless ref($self);

    my %objects = @_;
    for ( keys %objects ) {
        $self->reportValueInfo(
                    {   'n' => $_,
                        'v' => $objects{$_},
                    }
                );
    }
    return $self;
}

### ###########################################################################
# USAGE: Harness::Object($obj); - where $obj is an object reference.
sub Object {
  my $self = shift;
  return $self unless ref($self);
  my $pckg = $_[0];

  my $pckgName = "$pckg";
  $pckgName =~ s{=?(ARRAY|HASH|SCALAR).*$}{};
  my $pckgType = $1;
  $self->_PrintT("-$pckgType $pckgName", caller(1));
  $self->OnObject(@_);

  $self->_PrintT_();
  return $self;
}

### ###########################################################################
# USAGE: Benchmark::MemoryUsage::MethodReturn( $pckg )
#     Print useful information about the given object ($pckg)
sub OnObject {
  my $self = shift;
  my $obj = shift;

  my $objName = "$obj";
  $objName =~ s{=?([A-Z]+).*$}{};#s{=?(ARRAY|HASH|SCALAR|CODE).*$}{};
  my $objType = $1 || '';

  if ( $objType eq 'HASH' ) {
    my $i = 0;
    for ( keys %$obj ) {
      my $obj = ref($_)?$_:\$_;
      my ($nm) = ($_);
      $nm = $i unless $nm; $i += 1;
      $self->print("<V n='$nm'/>");
    }
  } elsif ( $objType eq 'ARRAY' ) {
        my $i = 0;
        for ( @$obj ) {
        my ($nm) = ($i);
        $i += 1;
        $self->print("<V n='$nm'/>");
        last if ( ++$i == 20 );
        if ( scalar(@$objType) > 20 ) {
            $self->print("<G n='".scalar(@_)."'/>");
        };
    }
  } elsif ( $objType eq 'SCALAR' ) {
      $self->print("<V>$$obj</V>");
  } else {
      $self->print("<V t='$objType'>$obj</V>");
  }
  return $self;
}

### ###########################################################################
# USAGE: Harness::NamedVariables('name1' => $variable1 [, 'name1' => $variable2 ])
sub NamedVariables {
  my $self = ref($_[0])?shift:$Benchmark::Harness::Harness;
  return $self unless ref($self);

  $self->_PrintT(undef, caller(1));

  my $i = 1;
  while ( @_ ) {
    my ($nm, $sz) = (shift, Devel::Size::total_size(shift));
    $nm = $i unless $nm; $i += 1;
    $self->print("<V n='$nm' s='$sz'/>");
  }
  $self->_PrintT_();
  return $self;
}

1;