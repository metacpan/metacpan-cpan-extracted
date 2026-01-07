package Business::Tax::US::Form_1040::Worksheets;
use 5.14.0;
use warnings;
use Carp;
#use Data::Dump qw(dd pp);

BEGIN {
    use Exporter ();
    use List::Util qw( min );
    our ($VERSION, @ISA, @EXPORT_OK);
    $VERSION     = '0.07';
    @ISA         = qw(Exporter);
    @EXPORT_OK   = qw(
        social_security_benefits
        social_security_worksheet_data
        pp_ssbw
        qualified_dividends_capital_gains_tax
        pp_qdcgtw
        decimal_lines
    );
}

=head1 NAME

Business::Tax::US::Form_1040::Worksheets - IRS Form 1040 worksheets calculations

=head1 SYNOPSIS

    use Business::Tax::US::Form_1040::Worksheets qw(
        social_security_benefits
        social_security_worksheet_data
        qualified_dividends_capital_gains_tax
        pp_qdcgtw
        decimal_lines
    );

    $benefits = social_security_benefits( $inputs );

    $worksheet_data = social_security_worksheet_data( $inputs );

    $lines = qualified_dividends_capital_gains_tax( $inputs );

    pp_qdcgtw($lines);

=head1 DESCRIPTION

This library exports, on demand only, functions which implement calculations
used in various worksheets found in U.S. IRS Form 1040 instructions.

B<Acronyms:>

=over 4

=item *

B<SSBW:> I<Social Security Benefits Worksheet>, I<e.g.,> as found on page 32
of IRS Form 1040 Instructions for filing year 2024.

=item *

B<QDCGTW:> I<Qualified Dividends and Capital Gain Tax Worksheet>, I<e.g.,> as
found on page 36 of those 2024 Instructions.

=back

The current version of this library supports the SSBW and most of the QDCGTW
for filing years 2022, 2023 and 2024.  Future versions may extend the support of
those worksheets forwards and backwords; may offer more complete support for
the QDCGTW; and may offer support for other worksheets found within the Form
1040 instructions.

B<The accuracy of the calculations in these functions has not been reviewed by
the Internal Revenue Service, any other tax authority, any accountant or any
attorney.  Use at your own risk!>

=head1 SUBROUTINES

=head2 C<social_security_benefits()>

=over 4

=item * Purpose

Calculate taxable social security benefits per the SSBW for the purpose of
entering the amount of such taxable benefits on IRS Form 1040.  (For filing
year 2024, these would be lines 6a and 6b on that form.)

    my $benefits = social_security_benefits( $inputs );

=item * Arguments

Single hash reference with the following keys (values are purely for example):

    $inputs = {
        box5    => 30000.00,    # Sum of box 5 on all Forms SSA-1099 and RRB-1099
        l1z     => 0,           # Form 1040, line 1z
        l2b     => 350.00,
        l3b     => 6000.00,
        l4b     => 0,
        l5b     => 8000.00,
        l7      => 1600.00,
        l8      => 1000.00,
        l2a     => 0,
        s1l11     => 0,         # Schedule 1 (Form 1040), line 11
        s1l12     => 0,
        s1l13     => 0,
        s1l14     => 0,
        s1l15     => 0,
        s1l16     => 0,
        s1l17     => 0,
        s1l18     => 0,
        s1l19     => 0,
        s1l20     => 0,
        s1l23     => 0,
        s1l25     => 0,
        status     => 'single', # Social Security Benefits Worksheet, line 8
        filing_year => 2023,
    };

Appropriate values for elements in C<$inputs>:

=over 4

=item * C<status>:  String holding one of C<married single married_sep>.

=item * C<filing_year>:  Filing year (4-digits).

=item *

All others:  Number holding dollar amount (to 2-decimal maximum).  If value is
C<0>, element may be omitted.

=back

=item * Return Value

Scalar holding taxable social security benefits in dollars and two cents,
I<e.g.,> C<289.73>.

=back

=cut

my %data_2022_ssb = (
    worksheet_line_count    => 18,
    ssa_percentage          => 0.5,
    percentage_a            => 0.85,
    percentage_b            => 0.85,
    percentage_c            => 0.85,
    married_amt_a           => 32000,
    single_amt_a            => 25000,
    married_amt_b           => 12000,
    single_amt_b            =>  9000,
    other_percentage        => 0.5,
);
# inspection of 2023 Soc Sec worksheet indicates no change in
# parameters
my %data_2023_ssb = map { $_ => $data_2022_ssb{$_} } keys %data_2022_ssb;
# inspection of 2024 Soc Sec worksheet indicates no change in
# parameters
my %data_2024_ssb = map { $_ => $data_2023_ssb{$_} } keys %data_2023_ssb;

our %params = (
    ssb => {
        2022 => { %data_2022_ssb },
        2023 => { %data_2023_ssb },
        2024 => { %data_2024_ssb },
    },
    qd => {
        2022 => {
            worksheet_line_count        => 21,
            single_or_married_sep_amt_a => 41675,
            married_amt_a               => 83350,
            head_of_household_amt_a     => 55800,
            single_amt_b                => 459750,
            married_sep_amt_b           => 258600,
            married_amt_b               => 517200,
            head_of_household_amt_b     => 488500,
            percentage_a                => 0.15,
            percentage_b                => 0.20,
        },
        2023 => {
            worksheet_line_count        => 21,
            single_or_married_sep_amt_a => 44625,
            married_amt_a               => 89250,
            head_of_household_amt_a     => 59750,
            single_amt_b                => 492300,
            married_sep_amt_b           => 276900,
            married_amt_b               => 553850,
            head_of_household_amt_b     => 523050,
            percentage_a                => 0.15,
            percentage_b                => 0.20,
        },
        2024 => {
            worksheet_line_count        => 21,
            single_or_married_sep_amt_a => 47025,
            married_amt_a               => 94050,
            head_of_household_amt_a     => 63000,
            single_amt_b                => 518900,
            married_sep_amt_b           => 291850,
            married_amt_b               => 583750,
            head_of_household_amt_b     => 551350,
            percentage_a                => 0.15,
            percentage_b                => 0.20,
        },
    },
);

sub social_security_benefits {
    my ($inputs) = @_;
    my $rv = _social_security_benefits_engine($inputs);
    return $rv->{taxable_benefits};
}

=head2 C<social_security_worksheet_data()>

=over 4

=item * Purpose

Calculate data needed for the purpose of completing all entries (except
checkboxes) on the Social Security Benefits Worksheet.

    my $worksheet_data = social_security_worksheet_data( $inputs );

=item * Arguments

The same, single hash reference which is supplied to
C<social_security_benefits()> (I<q.v.> above).

=item * Return Value

Reference to an array holding the data to be entered on lines 1-18 of the SSBW.
The indexes to the elements of that array correspond to those line numbers on the SSBW.

=back

=cut

sub social_security_worksheet_data {
    my ($inputs) = @_;
    my $rv = _social_security_benefits_engine($inputs);
    return $rv->{worksheet_data};
}

sub _social_security_benefits_engine {
    my ($inputs) = @_;
    croak "Argument to social_security_benefits() must be hashref"
        unless ref($inputs) eq 'HASH';
    my @numerics = qw(
        box5
        l1z
        l2b
        l3b
        l4b
        l5b
        l7
        l8
        l2a
        s1l11 s1l12 s1l13 s1l14 s1l15
        s1l16 s1l17 s1l18 s1l19 s1l20
        s1l23
        s1l25
    );
    my %permitted = map { $_ => 1 } (@numerics, 'status', 'filing_year');
    for my $k (keys %{$inputs}) {
        croak "Invalid element in hashref passed to social_security_benefits()"
            unless $permitted{$k};
    }
    my %permitted_statuses = map { $_ => 1 } ( qw|
        married single married_sep
    | );
    croak "Invalid value for 'status' element"
        unless (defined $inputs->{status} and $permitted_statuses{$inputs->{status}});
    my $data = {};
    for my $el (@numerics) {
        $data->{$el} = $inputs->{$el} // 0;
    }
    $data->{status} = $inputs->{status};
    my $filing_year = $inputs->{filing_year}; # TODO add test for numeric; required element
    my @lines = (undef, (undef) x $params{ssb}{$filing_year}{worksheet_line_count});
    my $formatted_lines;
    $lines[1] = $data->{box5};
    $lines[2] = $lines[1] * $params{ssb}{$filing_year}{ssa_percentage};
    $lines[3] =
        $data->{l1z} +
        $data->{l2b} +
        $data->{l3b} +
        $data->{l4b} +
        $data->{l5b} +
        $data->{l7} +
        $data->{l8};
    $lines[4] = $data->{l2a};
    $lines[5] = $lines[2] + $lines[3] + $lines[4];
    # sum up some Adjustments to Income (Schedule 1, Part II)
    $lines[6] =
        $data->{s1l11} +
        $data->{s1l12} +
        $data->{s1l13} +
        $data->{s1l14} +
        $data->{s1l15} +
        $data->{s1l16} +
        $data->{s1l17} +
        $data->{s1l18} +
        $data->{s1l19} +
        $data->{s1l20} +
        $data->{s1l23} +
        $data->{s1l25};
    if (! ($lines[6] < $lines[5]) ) {
        $formatted_lines = decimal_lines(\@lines);
        return {
          taxable_benefits => 0,
          worksheet_data => $formatted_lines,
        };
    }
    $lines[7] = $lines[5] - $lines[6];
    if ($data->{status} eq 'married_sep') {
        $lines[16] = $lines[7] * $params{ssb}{$filing_year}{percentage_b};
        $lines[17] = $lines[1] * $params{ssb}{$filing_year}{percentage_c};
        $lines[18] = min($lines[16], $lines[17]);
        $formatted_lines = decimal_lines(\@lines);
        return {
            taxable_benefits => $lines[18],
            worksheet_data => $formatted_lines,
        };
    }
    $lines[8] = $data->{status} eq 'married'
        ? $params{ssb}{$filing_year}{married_amt_a}
        : $params{ssb}{$filing_year}{single_amt_a};
    unless ($lines[8] < $lines[7]) {
        $formatted_lines = decimal_lines(\@lines);
        return {
            taxable_benefits => 0,
            worksheet_data => $formatted_lines,
        };
    }
    $lines[9] = $lines[7] - $lines[8];
    $lines[10] = $data->{status} eq 'married'
        ? $params{ssb}{$filing_year}{married_amt_b}
        : $params{ssb}{$filing_year}{single_amt_b};
    my $diff = $lines[9] - $lines[10];
    $lines[11] = $diff > 0 ? $diff : 0;
    $lines[12] = min($lines[9], $lines[10]);
    $lines[13] = $lines[12] * $params{ssb}{$filing_year}{other_percentage};
    $lines[14] = min($lines[2], $lines[13]);
    my $x = $lines[11] * $params{ssb}{$filing_year}{percentage_a};
    $lines[15] = $x > 0 ? $x : 0;
    $lines[16] = $lines[14] + $lines[15];
    $lines[17] = $lines[1] * $params{ssb}{$filing_year}{percentage_c};
    $lines[18] = min($lines[16], $lines[17]);
    $formatted_lines = decimal_lines(\@lines);
    return {
        taxable_benefits => $lines[18],
        worksheet_data => $formatted_lines,
    };
}

=head2 C<pp_ssbw()>

=over 4

=item * Purpose

Pretty-print ('pp' for short) the results of
C<social_security_worksheet_data()> for easier transcription to printed
worksheet.

    pp_ssbw($results);

=item * Arguments

The array reference which is the return value of
C<social_security_worksheet_data()>.  Required.

=item * Return Value

Implicitly returns true value upon success.

=item * Comment

In a future version of this library, this function may take a second argument
which presumably will be a string holding the path to an output file.  For
now, the function simply prints to C<STDOUT>.

=back

=cut

sub _compose_worksheet_line {
    my ($line_number, $formatting, $text, $result) = @_;
    my $line = sprintf("$formatting" => (
        $line_number,
        $text,
        $line_number,
        $result,
    ) );
    return $line;
}

sub pp_ssbw {
    my ($results) = @_;
    croak "First argument to pp_ssbw() must be array reference"
        unless ref($results) eq 'ARRAY';
    my @output = ();
    my $line_number = 0;
    my $one_wide_format     = "% 2s. %-40s  % 2s. % 12.2f";
    my $two_wide_format     = "% 2s. %-52s        % 2s. % 12.2f";
    my @f = (undef, $one_wide_format, $two_wide_format);

    my $lines = [
        undef,
        { formatting => $f[1], text => "Enter sum of 1099s, box 5" },
        { formatting => $f[2], text => "Line 1 x 50%" },
        { formatting => $f[2], text => "Sum of 1040 lines 1z 2b 3b 4b 5b 7 8" },
        { formatting => $f[2], text => "1040 line 2a" },
        { formatting => $f[2], text => "Line 2 + Line 3 + Line 4" },
        { formatting => $f[2], text => "Schedule 1, sum lines 11-20, 23, 25" },
        { formatting => $f[2], text => "Line 5 - Line 6 (or 0)" },
        { formatting => $f[2], text => "Status (1)" },
        { formatting => $f[2], text => "Line 7 - Line 8 (or 0)" },
        { formatting => $f[2], text => "Status (2)" },
        { formatting => $f[2], text => "Line 9 - Line 10" },
        { formatting => $f[2], text => "Smaller of lines 9 or 10" },
        { formatting => $f[2], text => "Line 12 x 50%" },
        { formatting => $f[2], text => "Smaller of lines 2 or 13" },
        { formatting => $f[2], text => "Line 11 x 85%" },
        { formatting => $f[2], text => "Line 14 + Line 15" },
        { formatting => $f[2], text => "Line 1 x 85%" },
        { formatting => $f[2], text => "Smaller of lines 16 or 17" },
    ];

    for (my $i = 0; $i <= $#{$results} -1 ; $i++) {
        my $j = $i + 1;
        push @output, _compose_worksheet_line(
            $j,
            $lines->[$j]->{formatting},
            $lines->[$j]->{text},
            $results->[$j],
        );
    }

    say $_ for @output;
    return 1;
}

=head2 C<qualified_dividends_capital_gains_tax()>

=over 4

=item * Purpose

B<Partial calculation> of taxes due per the QDCGTW for the purpose of
entering the amount of such taxes due on IRS Form 1040.  (For filing
year 2024, these would be Form 1040 line 16.)

    my $lines = qualified_dividends_capital_gains_tax( $inputs );

=item * Arguments

Reference to a hash with 6 required elements: C<l15 l3a sD status1 status2 filing_year>.

    my $inputs = {
        l15 => 7000.00,                     # Form 1040, line 15
        l3a => 4900.00,                     # Form 1040, line 3a
        sD =>  1600.00,                     # If filing Schedule D, enter smaller
                                            # of Schedule D, line 15 o4 16;
                                            # if not, enter Form 1040, line 7.
        status1 => 'single_or_married_sep', # Permissible values:
                                            #  single_or_married_sep
                                            #  married
                                            #  head_of_household
        status2 => 'single',                # Permissible values:
                                            #  single
                                            #  married_sep
                                            #  married
                                            #  head_of_household
        filing_year => 2023,
    };

=item * Return Value

Reference to an array where the indices of the array correspond to the values
calculated for the following lines in the Qualified Dividends and Capital Gain
Tax Worksheet:

    my $lines = [
        undef,
        7000,       # QDCGT Worksheet, line 1
        4900,
        1600,
        6500,
        500,
        41675,
        7000,
        500,
        6500,
        6500,
        6500,
        0,
        459750,
        7000,
        7000,
        0,
        0,
        0,
        6500,
        0,
        0,       # QDCGT Worksheet, line 21
    ]

=item * Comment

QDCGT Worksheet lines 22 and 24 require looking up values in the Tax Table or
the Tax Computation Worksheet.  To access the data those tables is currently
beyond the scope of this library.  Hence, the return value of this function
provides you with those values you need to fill in lines 1 through 21 on the
Worksheet.  You must then turn to the Tax Table or Tax Computation Worksheet
to make entries in lines 22 through 25 of the Worksheet.  Once you calculate
line 25 of that Worksheet, you will typically enter that on Form 1040 Line 16,
your tax due.

=back

=cut

sub qualified_dividends_capital_gains_tax {
    my $inputs = shift;
    croak "Argument to qualified_dividends_capital_gains_tax() must be hashref"
        unless ref($inputs) eq 'HASH';
    my @numerics = qw(
        l15
        l3a
        sD
    );

    my %permitted_statuses_1 = map { $_ => 1 } ( qw|
        single_or_married_sep
        married
        head_of_household
    | );
    croak "Invalid value for 'status1' element"
        unless (defined $inputs->{status1} and $permitted_statuses_1{$inputs->{status1}});

    my %permitted_statuses_2 = map { $_ => 1 } ( qw|
        single
        married_sep
        married
        head_of_household
    | );
    croak "Invalid value for 'status2' element"
        unless (defined $inputs->{status2} and $permitted_statuses_2{$inputs->{status2}});

    my %permitted = map { $_ => 1 } (@numerics, 'status1', 'status2', 'filing_year');
    for my $k (keys %{$inputs}) {
        croak "Invalid element in hashref passed to qualified_dividends_capital_gains_tax()"
            unless $permitted{$k};
    }

    my $data = {};
    for my $el (@numerics) {
        $inputs->{$el} //= 0;
        $data->{$el} = $inputs->{$el};
    }
    $data->{status1} = $inputs->{status1};
    $data->{status2} = $inputs->{status2};
    my $filing_year = $inputs->{filing_year}; # TODO add test for numeric; required element
    my @lines = (undef, (undef) x $params{qd}{$filing_year}{worksheet_line_count});
    # We will return after line 21 because thereafter we have to look up
    # things in the Tax Table.
    $lines[1] = $inputs->{l15};
    $lines[2] = $inputs->{l3a};
    $lines[3] = $inputs->{sD};
    $lines[4] = $lines[2] + $lines[3];
    my $diff = $lines[1] - $lines[4];
    $lines[5] = $diff > 0 ? $diff : 0;
    $lines[6] = $inputs->{status1} eq 'single_or_married_sep'
        ? $params{qd}{$filing_year}{single_or_married_sep_amt_a}
        : $inputs->{status1} eq 'married'
            ? $params{qd}{$filing_year}{married_amt_a}
            : $params{qd}{$filing_year}{head_of_household_amt_a};
    $lines[7] = min($lines[1], $lines[6]);
    $lines[8] = min($lines[5], $lines[7]);
    $lines[9] = $lines[7] - $lines[8];
    $lines[10] = min($lines[1], $lines[4]);
    $lines[11] = $lines[9];
    $lines[12] = $lines[10] - $lines[11];
    $lines[13] = $inputs->{status2} eq 'single'
        ? $params{qd}{$filing_year}{single_amt_b}
        : $inputs->{status2} eq 'married_sep'
            ? $params{qd}{$filing_year}{married_sep_amt_b}
            : $inputs->{status2} eq 'married'
                ? $params{qd}{$filing_year}{married_amt_b}
                : $params{qd}{$filing_year}{head_of_household_amt_b};
    $lines[14] = min($lines[1], $lines[13]);
    $lines[15] = $lines[5] + $lines[9];
    my $diff1 = $lines[14] - $lines[15];
    $lines[16] = $diff1 > 0 ? $diff1 : 0;
    $lines[17] = min($lines[12], $lines[16]);
    $lines[18] = $lines[17] * $params{qd}{$filing_year}{percentage_a};
    $lines[19] = $lines[9] + $lines[17];
    $lines[20] = $lines[10] - $lines[19];
    $lines[21] = $lines[20] * $params{qd}{$filing_year}{percentage_b};
    # We will need to use 5, 18, 21, 22 and 1
    my @formatted_lines = (
        $lines[0], # undef
        map { sprintf("%.2f" => $lines[$_]) } (1..$#lines),
    );
    return \@formatted_lines;
}

=head2 C<pp_qdcgtw()>

=over 4

=item * Purpose

Pretty-print ('pp' for short) the results of
C<qualified_dividends_capital_gains_tax()> for easier transcription to printed
worksheet.

    pp_qdcgtw($results);

=item * Arguments

The array reference which is the return value of
C<qualified_dividends_capital_gains_tax()>.  Required.

=item * Return Value

Implicitly returns true value upon success.

=item * Comment

In a future version of this library, this function may take a second argument
which presumably will be a string holding the path to an output file.  For
now, the function simply prints to C<STDOUT>.

=back

=cut

sub pp_qdcgtw {
    my ($results) = @_;
    croak "First argument to pp_qdcgtw() must be array reference"
        unless ref($results) eq 'ARRAY';
    my @output = ();
    my $line_number = 0;
    my $one_wide_format     = "% 2s. %-28s  % 2s. % 12.2f";
    my $two_wide_format     = "% 2s. %-40s        % 2s. % 12.2f";
    my $three_wide_format   = "% 2s. %-52s              % 2s. % 12.2f";
    my @f = (undef, $one_wide_format, $two_wide_format, $three_wide_format);

    my $lines = [
        undef,
        { formatting => $f[2], text => "Enter Form 1040, line 15" },
        { formatting => $f[1], text => "Enter Form 1040, line 3a" },
        { formatting => $f[1], text => "Sched. D/Form 1040, line 7" },
        { formatting => $f[1], text => "Line 2 - Line 3" },
        { formatting => $f[2], text => "Line 1 - Line 4" },
        { formatting => $f[2], text => "Filing status amount (1)" },
        { formatting => $f[2], text => "Smaller of lines 1 or 6" },
        { formatting => $f[2], text => "Smaller of lines 5 or 7" },
        { formatting => $f[2], text => "Line 7 - Line 8" },
        { formatting => $f[2], text => "Smaller of lines 1 or 4" },
        { formatting => $f[2], text => "Line 9 amount" },
        { formatting => $f[2], text => "Line 10 - Line 11" },
        { formatting => $f[2], text => "Filing status amount (2)" },
        { formatting => $f[2], text => "Smaller of lines 1 or 13" },
        { formatting => $f[2], text => "Line 5 + Line 9" },
        { formatting => $f[2], text => "Line 14 - Line 15" },
        { formatting => $f[2], text => "Smaller of lines 12 or 16" },
        { formatting => $f[3], text => "Line 17 x 15%" },
        { formatting => $f[2], text => "Line 9 + Line 17" },
        { formatting => $f[2], text => "Line 10 - Line 19" },
        { formatting => $f[3], text => "Line 20 x 20%" },
    ];

    for (my $i = 0; $i <= $#{$results} -1 ; $i++) {
        my $j = $i + 1;
        push @output, _compose_worksheet_line(
            $j,
            $lines->[$j]->{formatting},
            $lines->[$j]->{text},
            $results->[$j],
        );
    }

    say $_ for @output;
    return 1;
}

=head2 C<decimal_lines()>

=over 4

=item * Purpose

This is a helper subroutine used within both this module and the test suite to
ensure that all final monetary data is appropriately reported to two decimal
places.

=item * Arguments

    my $formatted_lines = decimal_lines($lines);

Single array reference holding a list of the values calculated for the various
lines in a worksheet.

=item * Return Value

Single array reference holding a list of values prepared for entry into the
worksheets to two decimal places (except for where the value is zero (C<0>).
Values that are undefined remain so.

=back

=cut

sub decimal_lines {
    my $lines = shift;
    my @formatted_lines = ();
    for my $l (@{$lines}) {
        if (! defined $l or $l eq '0') {
            push @formatted_lines, $l;
        }
        else {
            push @formatted_lines, sprintf("%.2f" => $l);
        }
    }
    return \@formatted_lines;
}

=head1 AUTHOR

    James E Keenan
    CPAN ID: JKEENAN
    jkeenan@cpan.org
    http://thenceforward.net/perl

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

1;
# The preceding line will help the module return a true value

