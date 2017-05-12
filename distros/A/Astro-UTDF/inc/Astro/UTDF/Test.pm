package Astro::UTDF::Test;

use strict;
use warnings;

use base qw{ Exporter };

use Carp;
use Test::More 0.88;

my @export = qw{
    decode
    fails
    hexify
    returns
    round_trip
};

our @EXPORT = ( @export, @Test::More::EXPORT );	## no critic (ProhibitAutomaticExportation)
our @EXPORT_OK = ( @export, @Test::More::EXPORT_OK );

sub decode {
    splice @_, 1, 0, 'decode';
    goto &returns;
}

sub fails {	## no critic (RequireArgUnpacking)
    my ( $obj, @args ) = @_;
##  my $opt = ref $args[0] eq 'HASH' ? shift @args : {};
    ref $args[0] eq 'HASH' and shift @args;	# $opt is unused
    my $method = shift @args;
    my $name = pop @args;
    my $want = pop @args;
    ref $want or $want = qr<@{[ quotemeta $want ]}>;
    local $@;
    eval { $obj->$method( @args ); 1 }
	and do {
	@_ = ( "$name did not throw an exception" );
	goto &fail;
    };
    @_ = ( $@, $want, $name );
    goto &like;
}

sub hexify {
    splice @_, 1, 0, { unpack => 'H*' };
    goto &returns;
}

sub returns {	## no critic (RequireArgUnpacking)
    my ( $obj, @args ) = @_;
    my $opt = ref $args[0] eq 'HASH' ? shift @args : {};
    my $method = shift @args;
    my $name = pop @args;
    my $want = pop @args;
    my $got;
    eval { $got = $obj->$method( @args ); 1 }
	or do {
	@_ = ( "$name threw $@" );
	goto &fail;
    };
    $opt->{unpack}
	and $got = unpack $opt->{unpack}, $got;
    $opt->{sprintf}
	and $got = sprintf $opt->{sprintf}, $got;
    @_ = ( $got, $want, $name );
    goto &is;
}

sub round_trip {	## no critic (RequireArgUnpacking)
    my ( $attr, $value, $opt ) = @_;
    $opt ||= {};
    my $name = $opt->{name} || "Round-trip $attr( $value )";
    my $utdf = eval {
	my $obj = Astro::UTDF->new( $attr => $value );
	return Astro::UTDF->new( raw_record => $obj->raw_record() );
    } or do {
	@_ = ( "$name threw $@" );
	goto &fail;
    };
    @_ = ( $utdf, $opt, $attr, $value, $name );
    goto &returns;
}

1;

__END__

=head1 NAME

Astro::UTDF::Test - Testing routines for Astro::UTDF

=head1 SYNOPSIS

 use lib qw{ inc };
 use Astro::UTDF::Test;
 plan( 'no_plan' );
 require_ok( 'Astro::UTDF' );
 round_trip( router => 'ZZ' );
 my $utdf = Astro::UTDF->new();
 returns( $utdf, router => '  ', 'Default router is blank' );
 fails( $utdf, range => 42, 'range() may not',
     'range() is not a mutator' );

=head1 DETAILS

This package extends L<Test::More|Test::More> by adding convenient (to
the author) wrappers for its tests. All L<Test::More|Test::More>
subroutines are also exported, and available to the user.

Each subroutine exported by this package represents one test, unless
otherwise noted. The calling sequence is generally an invocant, a method
name, some arguments, the expected result, and the test name.

Most of the exported subroutines are wrappers for L<returns()|/returns>.

=head1 SUBROUTINES

This package exports the following subroutines:

=head2 decode

 decode( $utdf, frequency_band => 'S-band',
     'Decode frequency_band()' );

This convenience routine simply splices C<'decode'> into the argument
list as the name of the method, and then chains to L</returns>. Passing
an option hash after the invocant is not supported.

=head2 fails

 fails( $utdf, range => 42, 'may not be used as a mutator',
     'range() is not a mutator' );

This test succeeds if the tested method throws the expected exception,
and fails otherwise. The arguments are an invocant, a method name, any
arguments to the method, a match string or regular expression, and a
test name. If a match string is passed, it is made into a regular
expression by running the results through C<quotemeta()> and then
wrapping them in C<qr{}>.

=head2 hexify

This convenience routine simply splices C<< { unpack => 'H*' } >> into
the argument list after the invocant, and then chains to L</returns>.
Passing an option hash after the invocant is not supported.

=head2 returns

 returns( $utdf, router => 'AA', 'Router is AA' );

The arguments are an invocant, a method name, any arguments to the
method, the expected value, and the name of the test. In the example
there are no arguments. The method is called on the invocant, and a
L<Test::More::is()|Test::More/is> test performed on the result. If the
method throws an exception, the test fails.

An options hash can be given as the second argument (i.e. after the
invocant but before the method name). This hash can contain the
following keys:

=over

=item sprintf => template

This option causes the result of the method to be formatted with
sprintf() using the given template. The formatted value is compared to
the expected value.

=item unpack => template

This option causes the result of the method to be unpacked using the
given template. The unpacked value is compared to the expected value.

=back

=head2 round_trip

 round_trip( router => 'ZZ' );

This method creates an C<Astro::UTDF> object, calls the given mutator
with the given value, then calls raw_record() on the new object. The
raw record thus obtained is used to generate a second object. A test of
the value returned by the original method called on the new object is
constructed, and chained to C</returns>. A test name is generated which
describes the attribute and its value.

Just to be inconsistent, the optional hash for C</returns> can be passed
as the third argument. You can use this hash to override the generated
name by passing the desired name as the value of the C<name> key:

 round_trip( router => 'ZZ', { name => 'Bogus router' } );

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2012-2016 Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
