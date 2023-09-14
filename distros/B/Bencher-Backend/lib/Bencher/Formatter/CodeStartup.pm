package Bencher::Formatter::CodeStartup;

use 5.010001;
use strict;
use warnings;

use parent qw(Bencher::Formatter);

use Role::Tiny::With;
with 'Bencher::Role::FieldMunger';
with 'Bencher::Role::ResultMunger';

use Bencher::Backend;
use List::Util qw(first);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-08'; # DATE
our $DIST = 'Bencher-Backend'; # DIST
our $VERSION = '1.063'; # VERSION

sub munge_result {
    my ($self, $envres) = @_;

    return unless $envres->[3]{'func.code_startup'};
    return unless @{$envres->[2]};

    $self->add_field(
        $envres,
        'code_overhead_time',
        {after=>'time', unit_of=>'time', align=>'number'},
        sub {
            for my $rit (@{$envres->[2]}) {
                my $rit_baseline = first {
                    ($_->{participant} // '') eq 'perl -e1 (baseline)' &&
                        ($_->{perl} // '') eq ($rit->{perl} // '')
                    } @{ $envres->[2] };
                next unless $rit_baseline;

                $rit->{code_overhead_time} =
                    $rit->{time} - $rit_baseline->{time};
            }
        },
    );

    $self->delete_fields(
        $envres,
        'dataset',
        'rate',
    );
}

1;
# ABSTRACT: Munge code_startup results

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Formatter::CodeStartup - Munge code_startup results

=head1 VERSION

This document describes version 1.063 of Bencher::Formatter::CodeStartup (from Perl distribution Bencher-Backend), released on 2023-07-08.

=head1 DESCRIPTION

Here's what this formatter does:

=over

=item * Remove C<rate> field

=item * Add a field C<code_overhead_time> after C<time>

=back

=for Pod::Coverage .*

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Backend>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
