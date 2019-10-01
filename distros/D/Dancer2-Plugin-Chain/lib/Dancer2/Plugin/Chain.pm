package Dancer2::Plugin::Chain;

$Dancer2::Plugin::Chain::VERSION   = '0.11';
$Dancer2::Plugin::Chain::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Dancer2::Plugin::Chain - Dancer2 add-on for route chaining.

=head1 VERSION

Version 0.11

=cut

use 5.006;
use strict; use warnings;
use Data::Dumper;

use Dancer2::Plugin;
use Dancer2::Plugin::Chain::Router;

=head1 DESCRIPTION

A very simple plugin for L<Dancer2> for chaining routes.I needed this for my other
project (in-progress) available on L<github|https://github.com/Manwar/Dancer2-Cookbook>.

=head1 SYNOPSIS

    my $continent       = chain '/continent/:continent' => sub { var 'site'  => param('continent'); };
    my $country         = chain '/country/:country'     => sub { var 'site'  => param('country');   };
    my $event           = chain '/event/:event'         => sub { var 'event' => param('event');     };
    my $continent_event = chain $continent, $event;

    get chain $country, $event, '/schedule' => sub {
        return sprintf("Schedule of %s in %s\n", var('event'), var('site'));
    };

    get chain $continent_event, '/schedule' => sub {
        return sprintf("Schedule of %s in %s\n", var('event'), var('site'));
    };

    get chain $continent, sub { var 'temp' => var('site') },
              $country,   sub { var 'site' => join(', ', var('site'), var('temp')) },
              $event, '/schedule' => sub {
                  return sprintf("Schedule of %s in %s\n", var('event'), var('site'));
              };

=head1 METHODS

=head2 chain(@args)

=cut

register chain => sub {
    my $dsl  = shift;
    my @args = @_;

    my $router = Dancer2::Plugin::Chain::Router->new({ args => \@args });
    return wantarray ? $router->route : $router;
};

register_plugin;

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Dancer2-Plugin-Chain>

=head1 ACKNOWLEDGEMENTS

Inspired by the package L<Dancer::Plugin::Chain> (Yanick Champoux <yanick@babyl.dyndns.org>).

=head1 SEE ALSO

L<Dancer::Plugin::Chain>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer2-plugin-chain at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-Chain>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::Chain

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer2-Plugin-Chain>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer2-Plugin-Chain>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Plugin-Chain>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer2-Plugin-Chain/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2016 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Dancer2::Plugin::Chain
