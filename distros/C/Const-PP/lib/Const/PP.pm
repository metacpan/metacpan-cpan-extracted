package Const::PP;

use 5.006;
use strict;
use warnings;
no warnings 'recursion';

our $VERSION = '0.02';

use Scalar::Util qw/reftype/;

use base qw/Import::Export/;

our %EX = (
        const => [qw/all/],
	make_readonly => [qw/all/],
	make_readonly_ref => [qw/all/],
	unmake_readonly => [qw/all/],
	is_readonly => [qw/all/],
);

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
			return &Internals::SvREADONLY($_[0]) ? 1 : 0;
		}
                elsif ($type eq 'HASH') {
		      	_is_readonly($_, $recurse) or return 0 for values %{ $_[0] };
			return &Internals::SvREADONLY($_[0]) ? 1 : 0;
		}
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
	if ($ref eq 'HASH' || $ref eq 'ARRAY' ) {
		return _is_readonly($_[0], 0);
	} else {
		return _is_readonly(${$_[0]}, 0);
	}
}

1;

__END__

=head1 NAME

Const::PP - Facility for creating read-only scalars, arrays, hashes

=head1 VERSION

Version 0.02

=cut

	package MyApp::Constants;

	use Const::PP qw/const/;

	use base 'Import::Export';

	our %EX = (
		'$SCALAR' => [qw/all/],
		'@ARRAY' => [qw/all/],
		'%HASH' => [qw/all/],
	);

	const our $SCALAR => 'Hello World';
	const our @ARRAY => qw/welcome to paradise/;
	const our %HASH => ( one => 1, two => [ ... ], three => { ... }, four => sub { } );

	1;

...

	package MyApp::Controller::Logic;

	use MyApp::Constants qw/$SCALAR @ARRAY %HASH/;

	...

	1;

=head1 DESCRIPTION

The Const::PP module facilitates the creation of read-only variables in Perl. This module serves as a sister implementation to L<Const::XS>, providing full backward compatibility and is implemented entirely in "pure perl".

For further documentation see L<Const::XS>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-const-pp at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Const-PP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Const::PP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Const-PP>

=item * Search CPAN

L<https://metacpan.org/release/Const-PP>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

