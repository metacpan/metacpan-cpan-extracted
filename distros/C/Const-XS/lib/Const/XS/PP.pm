package Const::XS;

use 5.006;

use strict;
use warnings;
no warnings 'recursion';

use Scalar::Util qw/reftype/;

our $RECURSION_LIMIT = 10000;

sub _make_readonly {
	my (undef, $recurse) = @_;

	$recurse++;
	if ($recurse > $RECURSION_LIMIT) {
		die "Bailing on making the readonly variable, Looks like you are in deep recursion";
	}

        if (my $type = reftype $_[0] and not &Internals::SvREADONLY($_[0])) {
                if ($type eq 'ARRAY') {
                        _make_readonly($_, $recurse) for @{ $_[0] };
                }
                elsif ($type eq 'HASH') {
                        &Internals::hv_clear_placeholders($_[0]);
                        _make_readonly($_, $recurse) for values %{ $_[0] };
                }

               	&Internals::SvREADONLY($_[0], 1);
        }

        Internals::SvREADONLY($_[0], 1);

        return;
}

sub _make_readwrite {
	my (undef, $recurse) = @_;

	$recurse++;
	if ($recurse > $RECURSION_LIMIT) {
		die "Bailing on making the variable writeable, Looks like you are in deep recursion";
	}

        if (my $type = reftype $_[0]) {        
               	&Internals::SvREADONLY($_[0], 0);
	        if ($type eq 'ARRAY') {
                        _make_readwrite($_, $recurse) for @{ $_[0] };
                }
                elsif ($type eq 'HASH') {
                        &Internals::hv_clear_placeholders($_[0]);
                        _make_readwrite($_, $recurse) for values %{ $_[0] };
                }
        }
        Internals::SvREADONLY($_[0], 0);

        return;
}

sub _is_readonly {
	my (undef, $recurse) = @_;

	$recurse++;
	if ($recurse > $RECURSION_LIMIT) {
		die "Bailing on checking whether the variable is readonly, Looks like you are in deep recursion";
	}

        if (my $type = reftype $_[0]) {
		if ($type eq 'ARRAY') {
                       _is_readonly($_, $recurse) or return 0 for @{ $_[0] };
                }
                elsif ($type eq 'HASH') {
		      _is_readonly($_, $recurse) or return 0 for values %{ $_[0] };
		}
		return &Internals::SvREADONLY($_[0]) ? 1 : 0;
	}

	return Internals::SvREADONLY($_[0]) ? 1 : 0;
}


sub const (\[$@%]@) {
        my (undef, @args) = @_;

	if ( ! scalar @args ) {
		die "No value for readonly variable";
	}

        if ( ref $_[0] eq 'ARRAY') {
                @{ $_[0] } = @args;
        }
        elsif ( ref $_[0] eq 'HASH') {
                die 'Odd number of elements in hash assignment' if @args % 2;
                %{ $_[0] } = @args;
        }
        else {
		my $ref = reftype($args[0]) || "";
		if ($ref eq 'HASH' || $ref eq 'ARRAY') {
			${ $_[0] } = $args[0];
			$_[0] = ${$_[0]};
		} else {
        	        ${ $_[0] } = $args[0];
		}
        }

        _make_readonly($_[0], 0);

        return $_[0];
}

sub make_readonly (\[$@%]@) {
	my $ref= reftype($_[0]) || "";
	if ( $ref eq 'HASH' || $ref eq 'ARRAY' ) {
		_make_readonly($_[0], 0);
	} else {
		_make_readonly(${$_[0]}, 0);
	}
	$_[0];
}

sub make_readonly_ref {
	_make_readonly($_[0], 0);
	return $_[0];
}

sub unmake_readonly (\[$@%]@)  {
	my $ref= reftype($_[0]) || "";
	if ( $ref eq 'HASH' || $ref eq 'ARRAY' ) {
		_make_readwrite($_[0], 0);
	} else {
		_make_readwrite(${$_[0]}, 0);
	}
	$_[0];
}

sub is_readonly (\[$@%]@) {
	my $ref= reftype($_[0]) || "";
	if ( $ref ) {
		return _is_readonly($_[0], 0);
	} else {
		return _is_readonly(${$_[0]}, 0);
	}
}

1;
