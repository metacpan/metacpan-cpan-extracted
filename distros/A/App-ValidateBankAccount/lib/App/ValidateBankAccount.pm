package App::ValidateBankAccount;

$App::ValidateBankAccount::VERSION   = '0.10';
$App::ValidateBankAccount::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

App::ValidateBankAccount - App to validate bank account number.

=head1 VERSION

Version 0.10

=cut

use 5.006;
use Data::Dumper;
use BankAccount::Validator::UK;
use App::ValidateBankAccount::Option;
use Moo;
use namespace::autoclean;
use MooX::Options;
with 'App::ValidateBankAccount::Option';

our $DEFAULT_COUNTRY = 'uk';

=head1 DESCRIPTION

It provides command line interface to the distribution L<BankAccount::Validator::UK>.
The distribution installs script C<validate-bank-account> for you to play with.

=head1 SYNOPSIS

You can list all command line options by giving C<-h> flag.

    USAGE: validate-bank-account [-h] [long options...]

        --country=String         Country code. Default is UK.
        --sort_code=String       Sort Code (required).
        --account_number=String  Bank Account Number (required).

        --usage                  show a short help message
        -h                       show a compact help message
        --help                   show a long help message
        --man                    show the manual

=head1 SUPPORTED COUNTRIES

=head2 UNITED KINGDOM

=head3 BANKS

=over 4

=item * Allied Irish

=item * Bank of England

=item * Bank of Ireland

=item * Bank of Scotland

=item * Barclays

=item * Bradford and Bingley Building Society

=item * Charity Bank

=item * Citibank

=item * Clear Bank

=item * Clydesdale

=item * Contis Financial Services

=item * Co-Operative Bank

=item * Coutts

=item * First Trust

=item * Halifax

=item * Hoares Bank

=item * HSBC

=item * Lloyds

=item * Metro Bank

=item * NatWest

=item * Nationwide Building Society

=item * Northern

=item * Orwell Union Ltd.

=item * Royal Bank of Scotland

=item * Santander

=item * Secure Trust

=item * Starling Bank

=item * Tesco Bank

=item * TSB

=item * Ulster Bank

=item * Unity Trust Bank

=item * Virgin Bank

=item * Williams & Glyn

=item * Woolwich

=item * Yorkshire Bank

=back

=head1 METHODS

=head2 run()

This is the only method provided by the package L<App::ValidateBankAccount>.It does
not expect any parameter. Code from the supplied C<validate-bank-account> script.

    use strict; use warnings;
    use App::ValidateBankAccount;

    App::ValidateBankAccount->new_with_options->run;

=cut

sub run {
    my ($self) = @_;

    my $country        = $self->country;
    my $sort_code      = $self->sort_code;
    my $account_number = $self->account_number;

    $country = $DEFAULT_COUNTRY unless defined $country;

    $sort_code =~ s/[\-\s]+//g;
    unless ($sort_code =~ /^\d+$/) {
        print sprintf("Sorry, %s is an invalid sort code.\n", $self->sort_code);
        return;
    }

    $account_number =~ s/\s+//g;
    unless ($account_number =~ /^\d+$/) {
        print sprintf("Sorry, %s is an invalid account number.\n", $self->account_number);
        return;
    }

    if ($country eq $DEFAULT_COUNTRY) {

        my $validator = BankAccount::Validator::UK->new;
        if ($validator->is_valid($sort_code, $account_number)) {
            print sprintf("[%s][%s] is a valid bank account.\n", $self->sort_code, $self->account_number);
        }
        else {
            print sprintf("Sorry, [%s][%s] is an invalid bank account.\n", $self->sort_code, $self->account_number);
        }
    }
    else {
        print sprintf("Sorry, %s is not currently supported.\n", $country);
    }
}

#
#
# PRIVATE METHODS

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

    perldoc App::ValidateBankAccount

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-ValidateBankAccount>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-ValidateBankAccount>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-ValidateBankAccount>

=item * Search CPAN

L<http://search.cpan.org/dist/App-ValidateBankAccount/>

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

1; # End of App::ValidateBankAccount
