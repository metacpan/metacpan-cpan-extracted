package Acme::ALEXEY::Utils;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Exporter ('import');
our @EXPORT = qw(sum);
=head1 NAME

Acme::ALEXEY::Utils - The great new Acme::ALEXEY::Utils!

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Acme::ALEXEY::Utils;

    my $foo = Acme::ALEXEY::Utils->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 sum 

=cut

sub sum {
  my $sum;
  $sum += $_ for @_;
  $sum;
}

=head1 AUTHOR

Alexey Morar , C<< <alexeymorar0 at gmail.com > >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-alexey-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-ALEXEY-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::ALEXEY::Utils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-ALEXEY-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-ALEXEY-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-ALEXEY-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-ALEXEY-Utils/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Alexey Morar .

This program is released under the following license: artistic_2


=cut

1; # End of Acme::ALEXEY::Utils
