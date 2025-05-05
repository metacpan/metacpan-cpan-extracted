package Const::XS;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.07';

use base qw/Import::Export/;

our %EX = (
        const => [qw/all/]
);

require XSLoader;
XSLoader::load("Const::XS", $VERSION);

__END__

1;

=head1 NAME

Const::XS - Facility for creating read-only scalars, arrays, hashes

=head1 VERSION

Version 0.07

=cut

=head1 SYNOPSIS

	use Const::XS qw/all/;

	const my $scalar => 'Hello World';
	const my @array => qw/welcome to paradise/;
	const my %hash => ( one => 1, two => 2, three => 3 );


=head1 EXPORTS

=head2 const

This is the only function of this module. It takes a scalar, array or hash lvalue as the first argument, and a list of one or more values depending on the type of the first argument as the value for the variable. It will set the variable to that value and subsequently make it readonly. Arrays and hashes will be made deeply readonly.

	const my %factory => (
		workers => 5,
		cb => sub { ... }
	);

	$factory{workers}; # 5;
	$factory{cb}->();

	$factory{not_set}; # errors
	exists $factory{not_set}; # false

=head2 BENCHMARK

	use Benchmark qw(:all);
	use Const::Fast;
	use Const::XS;
	use Readonly;

	timethese(5000000, {
		'Readonly' => sub {
			Readonly my $string => "Hello World";
			Readonly my %hash => (
				a => 1,
				b => 2,
				c => 3
			);
			Readonly my @array => (
				qw/1 2 3/
			);
		},
		'Const::Fast' => sub {
			Const::Fast::const my $string => "Hello World";
			Const::Fast::const my %hash => (
				a => 1,
				b => 2,
				c => 3
			);
			Const::Fast::const my @array => (
				qw/1 2 3/
			);
		},
		'XS' => sub {
			Const::XS::const my $string => "Hello World";
			Const::XS::const my %hash => (
				a => 1,
				b => 2,
				c => 3
			);
			Const::XS::const my @array => (
				qw/1 2 3/
			);
		}
	});

...

	Benchmark: timing 5000000 iterations of Const::Fast, Readonly, XS...
	Const::Fast: 18 wallclock secs (19.00 usr +  0.00 sys = 19.00 CPU) @ 263157.89/s (n=5000000)
	  Readonly: 20 wallclock secs (19.77 usr +  0.01 sys = 19.78 CPU) @ 252780.59/s (n=5000000)
		XS:  4 wallclock secs ( 3.31 usr +  0.03 sys =  3.34 CPU) @ 1497005.99/s (n=5000000)


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

1; # End of Const::XS
