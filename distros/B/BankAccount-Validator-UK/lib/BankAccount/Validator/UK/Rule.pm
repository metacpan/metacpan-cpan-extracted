package BankAccount::Validator::UK::Rule;

$BankAccount::Validator::UK::Rule::VERSION   = '0.42';
$BankAccount::Validator::UK::Rule::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

BankAccount::Validator::UK::Rule - Rules for validating UK bank account.

=head1 VERSION

Version 0.42

=cut

use 5.006;
use strict; use warnings;
use autodie;
use File::ShareDir ':ALL';

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>

=head1 METHODS

=head2 get_sort_codes()

It is used by the module L<BankAccount::Validator::UK> internally. It returns the
substituting  sort  code  if found, as provided by VOCALINK in the document dated
13th June'2005. The document is called scsubtab.txt.

=cut

sub get_sort_codes {

    my $sort_codes = {};
    my $file_name  = dist_file('BankAccount-Validator-UK', 'scsubtab.txt');

    open(my $SOURCE, "<", $file_name);
    while (my $row = <$SOURCE>) {
        chomp $row;
        my ($left, $right) = split /\s/, $row, 2;
        $left  =~ s/^\s+//g;
        $left  =~ s/\s+$//g;
        $right =~ s/^\s+//g;
        $right =~ s/\s+$//g;

        if (($left =~ /^\d+$/) && ($right =~ /^\d+$/)) {
            $sort_codes->{$left} = $right;
        }
    }
    close($SOURCE);

    return $sort_codes;
}

=head2 get_rules()

It is used by the module L<BankAccount::Validator::UK> internally.It returns every
possible rules cover by the document, as provided by VOCALINK dated 31st July 2018
and is called valacdos.txt.

=cut

sub get_rules {

    my $rules;
    foreach (@{_raw_data()}) {
        my @values   = split ' ';
        my $value_of = {};
        my $index    = 0;
        foreach my $k (qw(start end mod u v w x y z a b c d e f g h)) {
            $values[$index] =~ s/^\s+//g;
            $values[$index] =~ s/\s+$//g;
            if ($index == 2) {
                $value_of->{$k} = $values[$index];
            }
            else {
                $value_of->{$k} = $values[$index] + 0;
            }
            $index++;
        }

        if (!$values[$index]) {
            $value_of->{'ex'} = 0;
        }
        else {
            $value_of->{'ex'} = $values[$index] + 0;
        }

        push @$rules, $value_of;
    }

    return $rules;
}

sub _raw_data {

    my $raw_data  = [];
    my $file_name = dist_file('BankAccount-Validator-UK', 'valacdos.txt');

    open(my $SOURCE, "<", $file_name);
    while (my $row = <$SOURCE>) {
        chomp $row;
        push @$raw_data, $row;
    }
    close($SOURCE);

    return $raw_data;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/BankAccount-Validator-UK>

=head1 BUGS

Please  report any bugs or feature requests to C<bug-bankaccount-validator-uk  at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=BankAccount-Validator-UK>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BankAccount::Validator::UK::Rule

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=BankAccount-Validator-UK>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/BankAccount-Validator-UK>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/BankAccount-Validator-UK>

=item * Search CPAN

L<http://search.cpan.org/dist/BankAccount-Validator-UK/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2012 - 2017 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic  License (2.0). You may obtain a copy of the full
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

1; # End of BankAccount::Validator::UK::Rule
