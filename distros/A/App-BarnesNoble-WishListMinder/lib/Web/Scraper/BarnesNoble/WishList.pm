#---------------------------------------------------------------------
package Web::Scraper::BarnesNoble::WishList;
#
# Copyright 2014 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 20 Jun 2014
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Create a Web::Scraper object for a Barnes & Noble wishlist
#---------------------------------------------------------------------

our $VERSION = '0.004'; # VERSION
# This file is part of App-BarnesNoble-WishListMinder 0.004 (December 20, 2014)

use 5.010;
use strict;
use warnings;

use Web::Scraper;

#=====================================================================


sub bn_scraper
{
  scraper {
    process 'div.wishListItem', 'books[]' => scraper {
      process qw(//input[@name="ItemEan"] ean @value),
      process qw(//h5[1]/a[1] title  TEXT),
      process qw(//h5[1]/em[1]/a[1] author TEXT),
      process qw(div.wishListDateAdded date_added TEXT),
      process qw(//span[@class=~"listPriceValue"] list_price TEXT),
      process qw(//span[@class=~"onlinePriceValue"] price TEXT),
      process qw(//div[@class=~"onlineDiscount"] discount TEXT),
      process '//div[@class=~"eBooksPriority"]/select/option[@selected]',
              qw(priority @value),
    };
    result 'books';
  };
} # end bn_scraper

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

Web::Scraper::BarnesNoble::WishList - Create a Web::Scraper object for a Barnes & Noble wishlist

=head1 VERSION

This document describes version 0.004 of
Web::Scraper::BarnesNoble::WishList, released December 20, 2014
as part of App-BarnesNoble-WishListMinder version 0.004.

=head1 SYNOPSIS

  use Web::Scraper::BarnesNoble::WishList;
  my $scraper = Web::Scraper::BarnesNoble::WishList::bn_scraper();

=head1 DESCRIPTION

This module creates a L<Web::Scraper> object for scraping a Barnes &
Noble wishlist.  Currently, it's part of L<App::BarnesNoble::WishListMinder>.
If there's interest, I'll split it out into its own distribution and
add documentation.

=head1 SUBROUTINES

=head2 bn_scraper

  $scraper = Web::Scraper::BarnesNoble::WishList::bn_scraper();

Construct a L<Web::Scraper> for a wishlist.

=head1 CONFIGURATION AND ENVIRONMENT

Web::Scraper::BarnesNoble::WishList requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-App-BarnesNoble-WishListMinder AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=App-BarnesNoble-WishListMinder >>.

You can follow or contribute to App-BarnesNoble-WishListMinder's development at
L<< https://github.com/madsen/App-BarnesNoble-WishListMinder >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
