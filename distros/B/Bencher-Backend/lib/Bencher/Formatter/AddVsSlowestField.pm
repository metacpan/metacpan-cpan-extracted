package Bencher::Formatter::AddVsSlowestField;

our $DATE = '2019-12-02'; # DATE
our $VERSION = '1.046'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any::IfLOG '$log';

use parent qw(Bencher::Formatter);

use Role::Tiny::With;
with 'Bencher::Role::FieldMunger';
with 'Bencher::Role::ResultMunger';

sub munge_result {
    my ($self, $envres) = @_;

    my $slowest_time;
    for my $rit (@{ $envres->[2] }) {
        $slowest_time = $rit->{time}
            if !defined($slowest_time) || $slowest_time < $rit->{time};
    }

    return unless defined $slowest_time;

    $self->add_field(
        $envres,
        'vs_slowest',
        {after=>'time', align=>'number'},
        sub {
            for my $rit (@{$envres->[2]}) {
                $rit->{vs_slowest} = $slowest_time / $rit->{time};
            }
        }
    );
}

1;
# ABSTRACT: Add vs_slowest field

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Formatter::AddVsSlowestField - Add vs_slowest field

=head1 VERSION

This document describes version 1.046 of Bencher::Formatter::AddVsSlowestField (from Perl distribution Bencher-Backend), released on 2019-12-02.

=head1 DESCRIPTION

This formatter adds a C<vs_slowest> field (after C<time>) to give relative
numbers between the items. The slowest item will have a 1 value, the faster
items will have numbers larger than 1. For example, 2 means that the item is
twice faster than the slowest.

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

This software is copyright (c) 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
