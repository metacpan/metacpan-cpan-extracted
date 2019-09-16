package App::ValidateBankAccount::Option;

$App::ValidateBankAccount::Option::VERSION   = '0.09';
$App::ValidateBankAccount::Option::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

App::ValidateBankAccount::Option - Option as Moo Role for App::ValidateBankAccount.

=head1 VERSION

Version 0.09

=cut

use 5.006;
use Data::Dumper;

use Moo::Role;
use namespace::autoclean;
use Types::Standard -all;
use MooX::Options;

option country        => (is => 'ro', order => 1, isa => Str, format => 's', required => 0, doc => 'Country code. Default is UK.');
option sort_code      => (is => 'ro', order => 2, isa => Str, format => 's', required => 1, doc => 'Sort Code (required).');
option account_number => (is => 'ro', order => 3, isa => Str, format => 's', required => 1, doc => 'Bank Account Number (required).');

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/App-ValidateBankAccount>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-validatebankaccount at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ValidateBankAccount>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::ValidateBankAccount::Option

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-ValidateBankAccount>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-ValidateBankAccount>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-ValidateBankAccount>

=item * Search MetaCPAN

L<https://metacpan.org/pod/App::ValidateBankAccount>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2019 Mohammad S Anwar.

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

1; # End of App::ValidateBankAccount::Option
