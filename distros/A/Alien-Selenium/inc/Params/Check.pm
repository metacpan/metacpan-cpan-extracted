#line 1 "inc/Params/Check.pm - /Users/kane/sources/p4/other/params-check/lib/Params/Check.pm"
package Params::Check;

use strict;

use Carp qw[carp];
use Locale::Maketext::Simple Style => 'gettext';

BEGIN {
    use Exporter    ();
    use vars        qw[ @ISA $VERSION @EXPORT_OK $VERBOSE $ALLOW_UNKNOWN 
                        $STRICT_TYPE $STRIP_LEADING_DASHES $NO_DUPLICATES
                        $PRESERVE_CASE $ONLY_ALLOW_DEFINED
                    ];

    @ISA        =   qw[ Exporter ];
    @EXPORT_OK  =   qw[check allow last_error];
    
    $VERSION                = 0.08;
    $VERBOSE                = $^W ? 1 : 0;
    $NO_DUPLICATES          = 0;
    $STRIP_LEADING_DASHES   = 0;
    $STRICT_TYPE            = 0;
    $ALLOW_UNKNOWN          = 0;
    $PRESERVE_CASE          = 0;
    $ONLY_ALLOW_DEFINED     = 0;
}


my @known_keys =    qw| required allow default strict_type no_override store
                        defined |;

sub check {
    my $utmpl   = shift;
    my $href    = shift;
    my $verbose = shift || $VERBOSE || 0;
    
    ### reset the error string ###
    _clear_error(); 

    ### check for weird things in the template and warn
    ### also convert template keys to lowercase if required
    my $tmpl = _sanity_check($utmpl);

    ### lowercase all args, and handle both hashes and hashrefs ###
    my $args = {};
    if (ref($href) eq 'HASH') {
        %$args = map { _canon_key($_), $href->{$_} } keys %$href;
    
    } elsif (ref($href) eq 'ARRAY') {
    
        if (@$href == 1 && ref($href->[0]) eq 'HASH') {
            %$args = map { _canon_key($_), $href->[0]->{$_}}
                keys %{ $href->[0] };
    
        } else {
            if ( scalar @$href % 2) {
                _store_error(
                    loc(qq[Uneven number of arguments passed to %1], 
                            _who_was_it()),
                    $verbose
                );     
                return;
            }
            
            my %realargs = @$href;
            %$args = map { _canon_key($_), $realargs{$_} } keys %realargs;
        }
    }

    ### flag to set if something went wrong ###
    my $flag;

    for my $key ( keys %$tmpl ) {

        ### check if the required keys have been entered ###
        my $rv = _hasreq( $key, $tmpl, $args );

        unless( $rv ) {
            _store_error(
                loc("Required option '%1' is not provided for %2 by %3",
                    $key, _who_was_it(), _who_was_it(1)),
                $verbose
            );              
            $flag++;
        }
    }
    return if $flag;

    ### set defaults for all arguments ###
    my $defs = _hashdefs($tmpl);

    ### check if all keys are valid ###
    for my $key ( keys %$args ) {

        unless( _iskey( $key, $tmpl ) ) {
            if( $ALLOW_UNKNOWN ) {
                $defs->{$key} = $args->{$key} if exists $args->{$key};
            } else {
                _store_error(
                    loc("Key '%1' is not a valid key for %2 provided by %3",
                        $key, _who_was_it(), _who_was_it(1)),
                    $verbose
                );      
                next;
            }

        } elsif ( $tmpl->{$key}->{no_override} ) {
            _store_error(
                loc( qq[You are not allowed to override key '%1' for %2 from %3],
                    $key, _who_was_it(), _who_was_it(1)),
                $verbose
            );     
            next;
        } else {

            ### flag to set if the value was of a wrong type ###
            my $wrong;

            my $must_be_defined =   $tmpl->{$key}->{'defined'} || 
                                    $ONLY_ALLOW_DEFINED || 0;
            if( $must_be_defined ) {
                $wrong++ if not defined $args->{$key};
            }

            if( exists $tmpl->{$key}->{allow} ) {
                
                $wrong++ unless allow(  $args->{$key}, 
                                        $tmpl->{$key}->{allow},
                                        $must_be_defined,
                                    );
            }

            if( $STRICT_TYPE || $tmpl->{$key}->{strict_type} ) {
                $wrong++ unless ref $args->{$key} eq 
                                ref $tmpl->{$key}->{default};
            }

            ### somehow it's the wrong type.. warn for this! ###
            if( $wrong ) {
                _store_error(
                    loc(qq[Key '%1' is of invalid type for %2 provided by %3],
                        $key, _who_was_it(), _who_was_it(1)),
                    $verbose
                );     
                ++$flag && next;

            } else {

                ### if we got here, it's apparently an ok value for $key,
                ### so we'll set it in the default to return it in a bit
                
                $defs->{$key} = $args->{$key};
            }
        }
    }

    ### check if we need to store ###
    for my $key ( keys %$defs ) {
        if( my $scalar = $tmpl->{$key}->{store} ) {
            $$scalar = $defs->{$key};
            delete $defs->{$key} if $NO_DUPLICATES;
        }
    }              

    return $flag ? undef : $defs;
}

sub allow {
    my $val                 = shift;
    my $aref                = shift;

    my $wrong;
    if ( ref $aref eq 'Regexp' ) {
        $wrong++ unless defined $val and $val =~ /$aref/;

    } elsif ( ref $aref eq 'ARRAY' ) {
        #$wrong++ unless grep { ref $_ eq 'Regexp'
        #                            ? $val =~ /$_/
        #                            : _safe_eq($val, $_)
        #                     } @$aref;
        $wrong++ unless grep { allow( $val, $_ ) } @$aref;

    } elsif ( ref $aref eq 'CODE' ) {
        $wrong++ unless $aref->( $val );

    ### fall back to a simple 'eq'
    } else {
        $wrong++ unless _safe_eq( $val, $aref );
    }
    return !$wrong;
}    

### Like check_array, but tmpl is an array and arguments can be given
### in a positional way; the tmpl order is the argument order.
sub check_positional {
    my $atmpl   = shift;
    my $aref    = shift;
    my $verbose = shift || $VERBOSE || 0;

    ### reset the error string ###
    _clear_error();

    my %args;
    {
        local $STRIP_LEADING_DASHES = 1;
        my ($tmpl, $pos, $syn) = _atmpl_to_tmpl_pos_syn($atmpl);
        
        if ($#$aref == 1 && ref($aref->[0]) eq 'HASH') {
        
            ### Single hashref argument containing actual args.
            my ($key, $item);
            while (($key, $item) = each %{ $aref->[0] }) {
                $key = _canon_key($key);
                if ($syn->{$key}) {
                    _store_error(
                        loc( qq[Synonym used in call to %1], _who_was_it() ),
                        $verbose
                    );     
                    $key = $syn->{$key};
                }
                $args{$key} = $item;
            }
        
        } elsif (!($#$aref % 2) && ref($aref->[0]) eq 'SCALAR' &&
                     $aref->[0] =~ /^-/) {
            
            ### List of -KEY => value pairs.
            while (my $key = (shift @$aref)) {
                $key = _canon_key($key);
                if ($syn->{$key}) {
                    _store_error(
                        loc( qq[Synonym used in call to %1], _who_was_it() ),
                        $verbose
                    );     
                    $key = $syn->{$key};
                }
                $args{_convert_case($key)} = shift @$aref;
            }
        } else {
            ### Positional arguments, yay!
            while (@$aref) {
                my $item = shift @$aref;
                my $key = shift @$pos;
                if (!$key) {
                    _store_error(
                        loc( qq[Too many positional arguments for %1] ,
                            _who_was_it() ),
                        $verbose,
                    );
                    
                    ### We ran out of positional arguments, no sense in
                    ### continuing on.
                    last;
                }
                $args{$key} = $item;
            }
        }
        return check($tmpl, \%args, $verbose);
    }
}

### Return a hashref of $tmpl keys with required values
sub _listreqs {
    my $tmpl = shift;

    my %hash = map { $_ => 1 } grep { $tmpl->{$_}->{required} } keys %$tmpl;
    return \%hash;
}

### Convert template arrayref (keyword, hashref pairs) into straight ###
### hashref and an (array) mapping of position => keyname ###
sub _atmpl_to_tmpl_and_pos {
    my @atmpl = @{ shift @_ };

    my (%tmpl, @positions, %synonyms);
    while (@atmpl) {
        
        my $key = shift @atmpl;
        my $href = shift @atmpl;
        
        push @positions, $key;
        $tmpl{_convert_case($key)} = $href;
        
        for ( @{ $href->{synonyms} || [] } ) {
            $synonyms{ _convert_case($_) } = $key;
        };
        
        undef $href->{synonyms};
    };
    return (\%tmpl, \@positions, \%synonyms);
}

### Canonicalise key (lowercase, and strip leading dashes if desired) ###
sub _canon_key {
    my $key = _convert_case( +shift );
    $key =~ s/^-// if $STRIP_LEADING_DASHES;
    return $key;
}


### check if the $key is required, and if so, whether it's in $args ###
sub _hasreq {
    my ($key, $tmpl, $args ) = @_;
    my $reqs = _listreqs($tmpl);

    return $reqs->{$key}
            ? exists $args->{$key}
                ? 1
                : undef
            : 1;
}

### Return a hash of $tmpl keys with default values => defaults
### make sure to even include undefined ones, so that 'exists' will dwym
sub _hashdefs {
    my $tmpl = shift;

    my %hash =  map {
                    $_ => defined $tmpl->{$_}->{default}
                                ? $tmpl->{$_}->{default}
                                : undef
                } keys %$tmpl;

    return \%hash;
}

### check if the key exists in $data ###
sub _iskey {
    my ($key, $tmpl) = @_;
    return $tmpl->{$key} ? 1 : undef;
}

sub _who_was_it {
    my $level = shift || 0;

    return (caller(2 + $level))[3] || 'ANON'
}

sub _safe_eq {
    my($a, $b) = @_;

    if ( defined($a) && defined($b) ) {
        return $a eq $b;
    }
    else {
        return defined($a) eq defined($b);
    }
}

sub _sanity_check {
    my $tmpl = shift;
    my $rv = {};
    
    while( my($key,$href) = each %$tmpl ) {
        for my $type ( keys %$href ) {
            unless( grep { $type eq $_ } @known_keys ) {
                _store_error(
                    loc(q|Template type '%1' not supported [at key '%2']|, $type, $key), 1, 1
                );     
            }               
        }
        $rv->{_convert_case($key)} = $href;
    }
    return $rv;
}    

sub _convert_case {
    my $key = shift;
    
    return $PRESERVE_CASE ? $key : lc $key;
}

{   my $ErrorString = '';

    sub _store_error {
        my $err     = shift;
        my $verbose = shift || 0;
        my $offset  = shift || 0;
        my $level   = 1 + $offset;
    
        local $Carp::CarpLevel = $level;
        
        carp $err if $verbose;
        
        $ErrorString .= $err . "\n";
    }
    
    sub _clear_error {
        $ErrorString = '';
    }
    
    sub last_error { $ErrorString }    
}

1;

__END__

#line 731

# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
         
