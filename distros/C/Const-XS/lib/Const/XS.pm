package Const::XS;

use 5.006;

use strict;
use warnings;

our $VERSION = '1.01';

require XSLoader;
XSLoader::load("Const::XS", $VERSION);

use base qw/Import::Export/;

our %EX = (
        const => [qw/all/],
	make_readonly => [qw/all/],
	make_readonly_ref => [qw/all/],
	unmake_readonly => [qw/all/],
	is_readonly => [qw/all/],
);

1;

__END__

=head1 NAME

Const::XS - Facility for creating read-only scalars, arrays, hashes

=head1 VERSION

Version 1.01

=cut

=head1 SYNOPSIS


	package MyApp::Constants;

	use Const::XS qw/const/;

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

The Const::XS module facilitates the creation of high-performance read-only variables in Perl. It's implemented in XS/C and delivers a 4x+ performance improvement compared to L<Const::PP>, a pure Perl version of this module that maintains full backward compatibility.

=head1 EXPORTS

=head2 const

This is the one of five functions of this module. It takes a scalar, array or hash lvalue as the first argument, and a list of one or more values depending on the type of the first argument as the value for the variable. It will set the variable to that value and subsequently make it readonly. Arrays and hashes will be made deeply readonly.

	const my %factory => (
		workers => 5,
		cb => sub { ... }
	);

	$factory{workers}; # 5;
	$factory{cb}->();

	$factory{not_set}; # errors
	exists $factory{not_set}; # false

=head2 make_readonly

The second function exported by this module is make_readonly. It will take a perl variable and deeply make it readonly.

	my $string = "abc";
	make_readonly($string);
	$string = 'def'; # errors

	my %hash = ( a => 1, b => 2, c => 3 );
	make_readonly(%hash);
	$hash{d}; # errors
	%hash = ( new => 1 ); # errors

=head2 make_readonly_ref

The third function exported by this module is make_readonly_ref. It will take a perl struct and deeply make it readonly. Please note that if you call make_readonly_ref the struct will be deeply made readonly however it is 'copied' into the variable and that does not get set as readonly. Take the following example.

	my $ref = make_readonly_ref({a => 1, b => 2, c => 3 }; # we copy into $ref
	$ref->{d}; # errors
	$ref = { new => 1 };  # is okay

=head2 unmake_readonly

The fourth function exported by this module is unmake_readonly. It will take a perl variable that has been through make_readonly/make_readonly_ref and deeply make it writeable again.

	my $string = "abc";
	make_readonly($string);
	$string = 'def'; # errors
	unmake_readonly($string);
	$string = 'def'; # is okay

=head2 is_readonly

The fifth function exported by this module is is_readonly. It can be used to validate if a variable is readonly.

	my %hash = ( one => "abc" );
	is_readonly(%hash); # 0;
	make_readonly(%hash);
	is_readonly(%hash); # 1;

=head2 BENCHMARK

	use Benchmark qw(:all);
	use Const::Fast;
	use Const::XS;
	use Const::PP;
	use Readonly;

	my $r = timethese(5000000, {
		'Readonly' => sub {
			Readonly::Scalar my $string => "Hello World";
			Readonly::Hash my %hash => (
				a => $string,
				b => $string,
				c => $string
			);
			Readonly::Array my @array => (
				qw/1 2 3/, $string, \%hash
			);
			die unless $string eq "Hello World";
			die unless $hash{a} eq "Hello World";
			die unless $array[3] eq "Hello World";
		},
		'Const::Fast' => sub {
			Const::Fast::const my $string => "Hello World";
			Const::Fast::const my %hash => (
				a => $string,
				b => $string,
				c => $string
			);
			Const::Fast::const my @array => (
				qw/1 2 3/, $string, \%hash
			);
			die unless $string eq "Hello World";
			die unless $hash{a} eq "Hello World";
			die unless $array[3] eq "Hello World";
		},
		'Const::PP' => sub {
			Const::XS::PP::const my $string => "Hello World";
			Const::XS::PP::const my %hash => (
				a => $string,
				b => $string,
				c => $string
			);
			Const::XS::PP::const my @array => (
				qw/1 2 3/, $string, \%hash
			);
			die unless $string eq "Hello World";
			die unless $hash{a} eq "Hello World";
			die unless $array[3] eq "Hello World";
		},
		'XS' => sub {
			Const::XS::const my $string => "Hello World";
			Const::XS::const my %hash => (
				a => $string,
				b => $string,
				c => $string
			);
			Const::XS::const my @array => (
				qw/1 2 3/, $string, \%hash
			);
			die unless $string eq "Hello World";
			die unless $hash{a} eq "Hello World";
			die unless $array[3] eq "Hello World";
		}
	});

	cmpthese $r;

...

	Const::Fast: 22.5694 wallclock secs (22.53 usr +  0.01 sys = 22.54 CPU) @ 221827.86/s (n=5000000)
	 Const::PP: 19.7015 wallclock secs (19.66 usr +  0.01 sys = 19.67 CPU) @ 254194.20/s (n=5000000)
	  Readonly: 34.829 wallclock secs (34.78 usr +  0.01 sys = 34.79 CPU) @ 143719.46/s (n=5000000)
		XS: 3.92774 wallclock secs ( 3.89 usr +  0.03 sys =  3.92 CPU) @ 1275510.20/s (n=5000000)
			 Rate    Readonly Const::Fast   Const::PP          XS
	Readonly     143719/s          --        -35%        -43%        -89%
	Const::Fast  221828/s         54%          --        -13%        -83%
	Const::PP    254194/s         77%         15%          --        -80%
	XS          1275510/s        787%        475%        402%          --


=head2 SEE ALSO

L<Const::PP>

L<Const::Fast>

L<Readonly>

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-const-xs at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Const-XS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Const::XS

You can also look for information at:

=over 2

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Const-XS>

=item * Search CPAN

L<https://metacpan.org/release/Const-XS>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

