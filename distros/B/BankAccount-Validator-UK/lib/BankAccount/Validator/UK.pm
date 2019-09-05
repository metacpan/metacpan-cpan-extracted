package BankAccount::Validator::UK;

$BankAccount::Validator::UK::VERSION   = '0.49';
$BankAccount::Validator::UK::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

BankAccount::Validator::UK - Interface to validate UK bank account.

=head1 VERSION

Version 0.49

=cut

use 5.006;
use Data::Dumper;
use BankAccount::Validator::UK::Rule;

use Moo;
use namespace::autoclean;

has sc         => (is => 'rw');
has an         => (is => 'rw');
has mod        => (is => 'rw');
has attempt    => (is => 'rw');
has last_ex    => (is => 'rw');
has trace      => (is => 'rw');
has debug      => (is => 'ro', default => sub { 0 });
has last_check => (is => 'rw', default => sub { 0 });
has multi_rule => (is => 'ro', default => sub { 0 });
has sort_code  => (is => 'ro', default => sub { BankAccount::Validator::UK::Rule::get_sort_codes() });

=head1 DESCRIPTION

The module uses the algorithm provided by VOCALINK to validate the bank sort code
and account number.  It is  done by modulus  checking  method as specified in the
document which is available on their website L<VOCALINK|https://www.vocalink.com/customer-support/modulus-checking>
It currently supports the document L<v5.80|https://www.vocalink.com/media/3513/vocalink-validating-account-numbers-v580.pdf> drafted 4th Sep 2019.

Institutions covered by this document are below:

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

=head2 NOTE

If the modulus check shows the account number as valid this means that the account
number  is a possible account number for the sorting code but does'nt necessarily
mean that it's an account number  being  used at that sorting code.  Any  account
details found as invalid should be checked with the account holder where possible.

=head1 CONSTRUCTOR

The constructor  simply expects debug flag, which is optional. By the default the
debug flag is off.

    use strict; use warnings;
    use BankAccount::Validator::UK;

    # Debug is turned off.
    my $account1 = BankAccount::Validator::UK->new;

    # Debug is turned on.
    my $account2 = BankAccount::Validator::UK->new(debug => 1);

=head1 METHODS

=head2 is_valid($sort_code, $account_number)

It expects two parameters i.e. the sort code and the account number.The sort code
can be either nn-nn-nn or nnnnnn format. If the account number starts with 0 then
its advisable to pass in as string i.e. '0nnnnnnn'.

    use strict; use warnings;
    use BankAccount::Validator::UK;

    my $account = BankAccount::Validator::UK->new;
    print "[10-79-99][88837491] is valid.\n"
        if $account->is_valid(107999, 88837491);

    print "[18-00-02][00000190] is valid.\n"
        if $account->is_valid('18-00-02', '00000190');

=cut

sub is_valid {
    my ($self, $sc, $an) = @_;

    die("ERROR: Missing bank sort code.\n")      unless defined $sc;
    die("ERROR: Missing bank account number.\n") unless defined $an;

    ($sc, $an) = _prepare($sc, $an);
    die("ERROR: Invalid sort code.\n")      unless (length($sc) == 6);
    die("ERROR: Invalid account number.\n") unless (length($an) == 8);

    my $_sort_code = _init('u', $sc);
    my $_account_number = _init('a', $an);
    my $_rules = _get_rules($sc);

    next if (scalar(@{$_rules}) == 0);

    $self->{sc} = $sc;
    $self->{an} = $an;
    $self->{multi_rule} = (scalar(@{$_rules}) > 1)?(1):(0);
    foreach my $_rule (@{$_rules}) {
        $self->{attempt}++;
        _init('u', '090126', $_sort_code)
            if ($_rule->{ex} == 8);

        if (($_rule->{ex} == 6)
            &&
            ($_account_number->{a} =~ /^[4|5|6|7|8]$/)
            &&
            ($_account_number->{g} == $_account_number->{h})) {

            $self->{last_ex} = $_rule->{ex};
            $self->{last_check} = 1;
            push @{$self->{trace}}, {'ex'  => $_rule->{ex},
                                     'mod' => $_rule->{mod},
                                     'res' => 'VALID'};
            next;
        }

        if (($_rule->{ex} == 7) && ($_account_number->{g} == 9)) {
            _init('u','000000', $_rule);
            _init('a','00', $_rule);
        }
        elsif ($_rule->{ex} == 8) {
            _init('u', '090126', $_sort_code);
        }
        elsif ($_rule->{ex} =~ /^[2|9]$/) {
            if ($_rule->{ex} == 9) {
                _init('u', '309634', $_sort_code);
            }
            elsif ($_account_number->{a} != 0) {
                if ($_account_number->{g} != 9) {
                    _init('u','001253', $_rule);
                    _init('a','6,4,8,7,10,9,3,1', $_rule);
                }
                elsif ($_account_number->{g} == 9) {
                    _init('u','000000', $_rule);
                    _init('a','0,0,8,7,10,9,3,1', $_rule);
                }
            }
        }
        elsif ($_rule->{ex} == 10) {
            my $_ab = sprintf("%s%s", $_account_number->{a}, $_account_number->{b});
            if ((($_ab eq "09") or ($_ab eq "99")) && ($_account_number->{g} == 9)) {
                _init('u', '000000', $_rule);
                _init('a', '00', $_rule);
            }
        }
        elsif ($_rule->{ex} == 3) {
            $self->{last_ex} = 3;
            next if ($_account_number->{c} =~ /^[6|9]$/);
        }
        elsif ($_rule->{ex} == 5) {
            _init('u', $self->{sort_code}->{$sc}, $_sort_code)
                if (exists $self->{sort_code}->{$sc});
        }

        my $_status;
        if ($_rule->{mod} =~ /MOD(\d+)/i) {
            $_status = $self->_standard_check($_sort_code, $_account_number, $_rule);
        }
        elsif ($_rule->{mod} =~ /DBLAL/i) {
            $_status = $self->_double_alternate_check($_sort_code, $_account_number, $_rule);
        }

        if (defined $_status) {
            $self->{last_ex} = $_status->{ex};
            $self->{last_check} = ($_status->{res} eq 'PASS')?(1):(0);;
            push @{$self->{trace}}, $_status;
        }

        my $_result = $self->_check_result();
        return $_result if defined $_result;
    }

    return $self->{last_check}
        if ((defined $self->{last_ex}) && ($self->{last_ex} =~ /^6$/) && ($self->{multi_rule}));

    return;
}

=head2 get_trace()

Returns the trace information about each rule that applied to the given sort code
and account number.

    use strict; use warnings;
    use Data::Dumper;
    use BankAccount::Validator::UK;

    my $account = BankAccount::Validator::UK->new;
    print "[87-14-27][09123496] is valid.\n"
        if $account->is_valid('871427', '09123496');

    print "Trace information:\n" . Dumper($account->get_trace);

=cut

sub get_trace {
    my ($self) = @_;

    return $self->{trace} if scalar(@{$self->{trace}});
}

#
#
# PRIVATE METHODS

sub _standard_check {
    my ($self, $_sort_code, $_account_number, $_rule) = @_;

    my $total = 0;
    $total += 27 if ($_rule->{ex} == 1);

    if ($_rule->{mod} =~ /MOD(\d+)/i) {
        foreach (keys %{$_sort_code}) {
            print "KEY: [$_] SC: [$_sort_code->{$_}] WEIGHTING: [$_rule->{$_}]\n"
                if $self->{debug};
            $total += $_sort_code->{$_} * $_rule->{$_};
        }

        foreach (keys %{$_account_number}) {
            print "KEY: [$_] AN: [$_account_number->{$_}] WEIGHTING: [$_rule->{$_}]\n"
                if $self->{debug};
            $total += $_account_number->{$_} * $_rule->{$_};
        }

        my $remainder = $total % $1;
        if ($_rule->{ex} == 4) {
            my $_gh = sprintf("%d%d", $_account_number->{g}, $_account_number->{h});
            if ($remainder == $_gh) {
                return {'ex'  => $_rule->{ex},
                        'mod' => $_rule->{mod},
                        'rem' => $remainder,
                        'tot' => $total,
                        'res' => 'PASS'};
            }
        }
        elsif (($_rule->{ex} == 5) && ($1 == 11)) {
            if ($remainder == 0) {
                if ($_account_number->{g} == 0) {
                    return {'ex'  => $_rule->{ex},
                            'mod' => $_rule->{mod},
                            'rem' => $remainder,
                            'tot' => $total,
                            'res' => 'PASS'};
                }
                else {
                    return {'ex'  => $_rule->{ex},
                            'mod' => $_rule->{mod},
                            'rem' => $remainder,
                            'tot' => $total,
                            'res' => 'FAIL'};
                }
            }
            elsif ($remainder == 1) {
                return {'ex'  => $_rule->{ex},
                        'mod' => $_rule->{mod},
                        'rem' => $remainder,
                        'tot' => $total,
                        'res' => 'FAIL'};
            }
            else {
                $remainder = 11 - $remainder;
                if ($_account_number->{g} == $remainder) {
                    return {'ex'  => $_rule->{ex},
                            'mod' => $_rule->{mod},
                            'rem' => $remainder,
                            'tot' => $total,
                            'res' => 'PASS'};
                }
                else {
                    return {'ex'  => $_rule->{ex},
                            'mod' => $_rule->{mod},
                            'rem' => $remainder,
                            'tot' => $total,
                            'res' => 'FAIL'};
                }
            }
        }
        elsif ($remainder == 0) {
            return {'ex'  => $_rule->{ex},
                    'mod' => $_rule->{mod},
                    'rem' => $remainder,
                    'tot' => $total,
                    'res' => 'PASS'};
        }
        else {
            if ($_rule->{ex} == 14) {
                if ($_account_number->{h} =~ /^[0|1|9]$/) {
                    my $an = substr($self->{an}, 0, 7);
                    $an = sprintf("%s%s", '0', $an);
                    _init('a', $an, $_account_number);

                    $total = 0;
                    foreach (keys %{$_sort_code}) {
                        print "KEY: [$_] SC: [$_sort_code->{$_}] WEIGHTING: [$_rule->{$_}]\n"
                            if $self->{debug};
                        $total += $_sort_code->{$_} * $_rule->{$_};
                    }

                    foreach (keys %{$_account_number}) {
                        print "KEY: [$_] AN: [$_account_number->{$_}] WEIGHTING: [$_rule->{$_}]\n"
                            if $self->{debug};
                        $total += $_account_number->{$_} * $_rule->{$_};
                    }

                    $remainder = $total % 11;
                    if ($remainder == 0) {
                        return {'ex'  => $_rule->{ex},
                                'mod' => $_rule->{mod},
                                'rem' => $remainder,
                                'tot' => $total,
                                'res' => 'PASS'};
                    }
                    else {
                        return {'ex'  => $_rule->{ex},
                                'mod' => $_rule->{mod},
                                'rem' => $remainder,
                                'tot' => $total,
                                'res' => 'FAIL'};
                    }
                }
                else {
                    return {'ex'  => $_rule->{ex},
                            'mod' => $_rule->{mod},
                            'rem' => $remainder,
                            'tot' => $total,
                            'res' => 'FAIL'};
                }
            }
            else {
                return {'ex'  => $_rule->{ex},
                        'mod' => $_rule->{mod},
                        'rem' => $remainder,
                        'tot' => $total,
                        'res' => 'FAIL'};
            }
        }
    }

    return;
}

sub _double_alternate_check {
    my ($self, $_sort_code, $_account_number, $_rule) = @_;

    my $total = 0;
    $total += 27 if ($_rule->{ex} == 1);

    foreach (keys %{$_sort_code}) {
        $total += _dbal_total($_sort_code->{$_} * $_rule->{$_});
    }

    foreach (keys %{$_account_number}) {
        $total += _dbal_total($_account_number->{$_} * $_rule->{$_});
    }

    my $remainder = $total % 10;
    if ($_rule->{ex} == 1) {
        if ($remainder == 0) {
            return {'ex'  => $_rule->{ex},
                    'mod' => $_rule->{mod},
                    'rem' => $remainder,
                    'tot' => $total,
                    'res' => 'PASS'};
        }
        else {
            return {'ex'  => $_rule->{ex},
                    'mod' => $_rule->{mod},
                    'rem' => $remainder,
                    'tot' => $total,
                    'res' => 'FAIL'};
        }
    }
    elsif ($_rule->{ex} == 5) {
        if ($remainder == 0) {
            if ($_account_number->{h} == 0) {
                return {'ex'  => $_rule->{ex},
                        'mod' => $_rule->{mod},
                        'rem' => $remainder,
                        'tot' => $total,
                        'res' => 'PASS'};
            }
        }
        else {
            $remainder = 10 - $remainder;
            if ($_account_number->{h} == $remainder) {
                return {'ex'  => $_rule->{ex},
                        'mod' => $_rule->{mod},
                        'rem' => $remainder,
                        'tot' => $total,
                        'res' => 'PASS'};
            }
            else {
                return {'ex'  => $_rule->{ex},
                        'mod' => $_rule->{mod},
                        'rem' => $remainder,
                        'tot' => $total,
                        'res' => 'FAIL'};
            }
        }
    }
    elsif ($remainder == 0) {
        return {'ex'  => $_rule->{ex},
                'mod' => $_rule->{mod},
                'rem' => $remainder,
                'tot' => $total,
                'res' => 'PASS'};
    }
    else {
        return {'ex'  => $_rule->{ex},
                'mod' => $_rule->{mod},
                'rem' => $remainder,
                'tot' => $total,
                'res' => 'FAIL'};
    }
}

sub _init {
    my ($index, $data, $init) = @_;

    if ($data =~ /\,/) {
        map { $init->{$index++} = $_; } split /\,/,$data;
    }
    else {
        map { $init->{$index++} = $_; } split //,$data;
    }

    return $init;
}

sub _check_result {
    my ($self) = @_;

    if ($self->{multi_rule}) {
        if (((defined $self->{last_ex})
             && ($self->{last_ex} =~ /^2|10|12$/)
             && ($self->{last_check} == 1))
            ||
            ((defined $self->{last_ex})
             && ($self->{last_ex} =~ /^9|11|13$/)
             && ($self->{last_check} == 1)
             && ($self->{attempt} == 2))) {
            return 1;
        }
        elsif ((defined $self->{last_ex})
               && ($self->{last_ex} =~ /^5|6$/)
               && ($self->{last_check} == 0)) {
            return 0;
        }
        elsif ((defined $self->{last_ex})
               && ($self->{last_ex} == 0)
               && ($self->{last_check} == 1)) {
            return 1;
        }
        elsif ($self->{attempt} == 2) {
            return $self->{last_check};
        }
    }
    else {
        return $self->{last_check};
    }

    return;
}

sub _get_rules {
    my ($sc) = @_;

    return unless (defined($sc) && ($sc =~ /^\d+$/));

    my $rules;
    foreach (@{BankAccount::Validator::UK::Rule::get_rules()}) {
        push @{$rules}, $_ if ($sc >= $_->{start} && $sc <= $_->{end});
    }

    return $rules;
}

sub _dbal_total {
    my ($_total) = @_;

    if ($_total > 9) {
        my ($left, $right) = split //, $_total;
        return ($left + $right);
    }
    else {
        return $_total;
    }
}

sub _prepare {
    my ($sc, $an) = @_;

    $sc =~ s/[\-\s]+//g;
    $an =~ s/\s+//g;

    die("ERROR: Invalid bank sort code [$sc].\n")      unless ($sc =~ /^\d+$/);
    die("ERROR: Invalid bank account number [$an].\n") unless ($an =~ /^\d+$/);

    if (length($an) == 10) {
        if ($an =~ /^(\d+)\-(\d+)/) {
            $an = $2;
        }
        else {
            $an = substr($an, 0, 8);
        }
    }
    elsif (length($an) == 9) {
        my $_a = substr($an, 0, 1);
        $an = substr($an, 1, 8);
        $sc = substr($sc, 0, 5);
        $sc .= $_a;
    }
    elsif (length($an) == 7) {
        $an = '0'.$an;
    }
    elsif (length($an) == 6) {
        $an = '00'.$an;
    }

    return ($sc, $an);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/BankAccount-Validator-UK>

=head1 BUGS

Please  report  any bugs or feature requests to C<bug-bankaccount-validator-uk at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=BankAccount-Validator-UK>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BankAccount::Validator::UK

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
the  terms  of the the Artistic License  (2.0). You may obtain a copy of the full
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

1; # End of BankAccount::Validator::UK
