package Data::Sah::Format::perl::boolstr;

our $DATE = '2016-06-17'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp;

our $styles = {
    yes_no     => ['yes', 'no'],
    Y_N        => ['Y', 'N'],
    true_false => ['true', 'false'],
    T_F        => ['T', 'F'],
    '1_0'      => ['1', '0'],
    on_off     => ['on', 'off'],
};

sub format {
    my %args = @_;

    my $dt    = $args{data_term};
    my $fargs = $args{args} // {};

    my ($true_str, $false_str);
    if (defined $fargs->{true_str}) {
        die "BUG: both true_str and false_str must be defined"
            unless defined $fargs->{false_str};
        $true_str  = $fargs->{true_str};
        $false_str = $fargs->{false_str};
    } elsif (defined $fargs->{false_str}) {
        die "BUG: both true_str and false_str must be defined";
    } else {
        my $style = $fargs->{style} // 'yes_no';
        $styles->{$style} or die "BUG: Unknown style '$style'";
        $true_str  = $styles->{$style}[0];
        $false_str = $styles->{$style}[1];
    }

    my $res = {};

    $res->{expr} = join(
        "",
        "!defined($dt) ? $dt : $dt ? ".dmp($true_str)." : ".dmp($false_str),
    );

    $res;
}

1;
# ABSTRACT: Format boolean as yes/no, etc

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Format::perl::boolstr - Format boolean as yes/no, etc

=head1 VERSION

This document describes version 0.002 of Data::Sah::Format::perl::boolstr (from Perl distribution Data-Sah-Format-perl-boolstr), released on 2016-06-17.

=head1 DESCRIPTION

By default will format all values that are regarded as true by Perl with "yes",
and all false values as "no". Undef will be left undef. The true string and
false string can be set using the formatter arguments C<true_str> and
C<false_str>, or you can choose from a set of predefined styles.

=for Pod::Coverage ^(format)$

=head1 FORMATTER ARGUMENTS

=head2 true_str => str

=head2 false_str => str

=head2 style => str (default: yes_no)

Can be: yes_no, Y_N, true_false, T_F, 1_0, on_off.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Format-perl-boolstr>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Format-perl-boolstr>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Format-perl-boolstr>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
