package Bencher::Formatter::ModuleStartup;

our $DATE = '2017-07-13'; # DATE
our $VERSION = '1.040'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any::IfLOG '$log';

use parent qw(Bencher::Formatter);

use Role::Tiny::With;
with 'Bencher::Role::FieldMunger';
with 'Bencher::Role::ResultMunger';

use Bencher::Backend;
use List::Util qw(first);

sub munge_result {
    my ($self, $envres) = @_;

    return unless $envres->[3]{'func.module_startup'};
    return unless @{$envres->[2]};

    $self->add_field(
        $envres,
        'mod_overhead_time',
        {after=>'time', unit_of=>'time', align=>'number'},
        sub {
            for my $rit (@{$envres->[2]}) {
                my $rit_baseline = first {
                    ($_->{participant} // '') eq 'perl -e1 (baseline)' &&
                        ($_->{perl} // '') eq ($rit->{perl} // '')
                    } @{ $envres->[2] };
                next unless $rit_baseline;

                $rit->{mod_overhead_time} =
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
# ABSTRACT: Munge module_startup results

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Formatter::ModuleStartup - Munge module_startup results

=head1 VERSION

This document describes version 1.040 of Bencher::Formatter::ModuleStartup (from Perl distribution Bencher-Backend), released on 2017-07-13.

=head1 DESCRIPTION

Here's what this formatter does:

=over

=item * Remove C<rate> field

=item * Add a field C<mod_overhead_time> after C<time>

=back

=for Pod::Coverage .*

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Backend>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Backend>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Backend>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
