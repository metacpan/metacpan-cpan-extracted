package Bencher::Formatter::Sort;

use 5.010001;
use strict;
use warnings;
#use Log::Any::IfLOG '$log';

use parent qw(Bencher::Formatter);

use Role::Tiny::With;
with 'Bencher::Role::ResultMunger';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-08'; # DATE
our $DIST = 'Bencher-Backend'; # DIST
our $VERSION = '1.061'; # VERSION

sub munge_result {
    my ($self, $envres) = @_;

    $self->{by} //= ['-time'];

    # sort by default from slowest to fastest
    $envres->[2] = [sort {
        for my $by0 (@{ $self->{by} }) {
            my ($desc, $by) = $by0 =~ /^(-?)(.+)/;
            return 0 unless defined($a->{$by}) && defined($b->{$by});
            my $numeric = $by =~ /time|errors|samples/ ? 1:0; # XXX ad-hoc
            my $res = ($desc ? -1:1) * ($numeric ?
                                            $a->{$by} <=> $b->{$by} :
                                            $a->{$by} cmp $b->{$by});
            return $res if $res;
        }
        0;
    } @{$envres->[2]}];
}

1;
# ABSTRACT: Sort rows

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Formatter::Sort - Sort rows

=head1 VERSION

This document describes version 1.061 of Bencher::Formatter::Sort (from Perl distribution Bencher-Backend), released on 2022-02-08.

=head1 DESCRIPTION

By default, sort from slowest (largest C<time> value) to fastest (smallest
C<time> value).

=for Pod::Coverage .*

=head1 OPTIONS

=head2 by => array of str (default: ["-time"])

Customize sort orders. One or more field names (field name can be prefixed with
C<-> (dash) to mean descending order).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Backend>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Backend>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Backend>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
