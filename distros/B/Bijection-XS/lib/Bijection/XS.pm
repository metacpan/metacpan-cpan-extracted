package Bijection::XS;

use 5.006;
use strict;
use warnings;

use base qw/Import::Export/;

our %EX = (biject => [qw/all main/], inverse => [qw/all main/], bijection_set => [qw/all set/], offset_set => [qw/all set/]);

BEGIN {
	our $VERSION = '0.05';
	require XSLoader;
	XSLoader::load("Bijection::XS", $VERSION);
	bijection_set(qw/b c d f g h j k l m n p q r s t v w x y z B C D F G H J K L M N P Q R S T V W X Y Z 0 1 2 3 4 5 6 7 8 9/);
}

1;

__END__


=head1 NAME

Bijection::XS - Bijection of an integer faster

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

Perhaps a little code snippet.

        use Bijection::XS qw/biject inverse/;

        my $int = 1;
        my $string = biject($int);
        inverse($string) == $int;

        ....

        use Bijection::XS qw/all/;

        my $offset = 100000000;
        bijection_set($offset, qw/b c d f g h j k l m n p q r s t v w x y z B C D F G H J K L M N P Q R S T V W X Y Z 0 1 2 3 4 5 6 7 8 9/);

        my $int = 2;
        my $string = biject($int);
        inverse($string) == $int;

=cut

=head1 EXPORT

=head2 biject

Takes an integer and returns a bijected string.

=cut

=head2 inverse

Takes an bijected string and returns an integer.

=cut

=head2 bijection_set

Set the bijective pair "set", this function expects a list of alphanumeric characters.

The following is set by default:

	bijection_set(qw/b c d f g h j k l m n p q r s t v w x y z B C D F G H J K L M N P Q R S T V W X Y Z 0 1 2 3 4 5 6 7 8 9/);

=cut

=head2 offset_set

Offset the bijection by setting an integer value here. This value is used to sum during bijection and substract during inversion.

=cut

=head1 BENCHMARK

	use Benchmark qw(:all);
	use lib '.';
	use Bijection;
	use Bijection::XS;

	timethese(10000000, {
		'Bijection' => sub {
			my $int = 10000;
			Bijection::inverse(Bijection::biject($int));
		},
		'XS' => sub {
			my $int = 10000;
			Bijection::XS::inverse(Bijection::XS::biject($int));
		}
	});


	Benchmark: timing 10000000 iterations of Bijection, XS...
	 Bijection:  8 wallclock secs ( 8.74 usr +  0.05 sys =  8.79 CPU) @ 1137656.43/s (n=10000000)
		XS:  2 wallclock secs ( 2.48 usr +  0.01 sys =  2.49 CPU) @ 4016064.26/s (n=10000000)

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bijection-xs at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bijection-XS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bijection::XS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Bijection-XS>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Bijection-XS>

=item * Search CPAN

L<https://metacpan.org/release/Bijection-XS>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Bijection::XS
