package App::timecalc;

our $DATE = '2019-05-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(eval_time_expr);

sub eval_time_expr {
    my $str = shift;

    my ($h, $m, $s) = (0, 0, 0);

    $str =~ s{
                 \s* (?<h1>\d\d?):(?<m1>\d\d?)(?: :(?<s1>\d\d?))? \s*-\s* (?<h2>\d\d?):(?<m2>\d\d?)(?: :(?<s2>\d\d?))? \s* |
                 \s* \+(?<hplus>\d\d?):(?<mplus>\d\d?)(?: :(?<splus>\d\d?))? \s* |
                 \s* \-(?<hminus>\d\d?):(?<mminus>\d\d?)(?: :(?<sminus>\d\d?))? \s*
         }{

             if (defined $+{h1}) {
                 my ($h1, $m1, $s1, $h2, $m2, $s2) = ($+{h1}, $+{m1}, $+{s1} // 0, $+{h2}, $+{m2}, $+{s2} // 0);
                 if ($h1 > 24) { die "Hour cannot exceed 24: $h1" }
                 if ($h2 > 24) { die "Hour cannot exceed 24: $h2" }
                 if ($h2 < $h1 || $h2 <= $h1 && $m2 <= $m1) { $h2 += 24 }
                 $h += ($h2-$h1);
                 $m += ($m2-$m1);
                 $s += ($s2-$s1);
             } elsif (defined $+{hplus}) {
                 $h += $+{hplus};
                 $m += $+{mplus};
                 $s += $+{splus} // 0;
             } elsif (defined $+{hminus}) {
                 $h -= $+{hminus};
                 $m -= $+{mminus};
                 $s -= $+{sminus} // 0;
             }

             "";
         }egsx;

    die "Unexpected string near '$str'" if length $str;

    while ($s < 0) {
        $m--;
        $s += 60;
    }
    while ($s >= 60) {
        $m++;
        $s -= 60;
    }
    while ($m < 0) {
        $h--;
        $m += 60;
    }
    while ($m >= 60) {
        $h++;
        $m -= 60;
    }

    sprintf "+%02d:%02d:%02d", $h, $m, $s;
}

1;
# ABSTRACT: Time calculator

__END__

=pod

=encoding UTF-8

=head1 NAME

App::timecalc - Time calculator

=head1 VERSION

This document describes version 0.003 of App::timecalc (from Perl distribution App-timecalc), released on 2019-05-25.

=head1 SYNOPSIS

See included script L<timecalc>.

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 eval_time_expr

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-timecalc>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-timecalc>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-timecalc>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<datecalc> from L<App::datecalc>. datecalc might be modified to include
L<timecalc>'s features.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
