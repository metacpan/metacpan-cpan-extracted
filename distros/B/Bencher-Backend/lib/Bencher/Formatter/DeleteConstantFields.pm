package Bencher::Formatter::DeleteConstantFields;

our $DATE = '2020-01-12'; # DATE
our $VERSION = '1.047'; # VERSION

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

    {
        last unless @{$envres->[2]};
        require TableData::Object::aohos;
        my $td = TableData::Object::aohos->new($envres->[2]);
        last unless $td->row_count >= 2;
        my @const_cols = $td->const_col_names;
        for my $k (@const_cols) {
            next unless $k =~ /^(item_.+|arg_.+|perl|modver|participant|p_.+|dataset|ds_.+)$/;
            $self->delete_fields($envres, $k);
        }
    }
}

1;
# ABSTRACT: Delete constant item permutation fields to reduce clutter

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Formatter::DeleteConstantFields - Delete constant item permutation fields to reduce clutter

=head1 VERSION

This document describes version 1.047 of Bencher::Formatter::DeleteConstantFields (from Perl distribution Bencher-Backend), released on 2020-01-12.

=head1 DESCRIPTION

Constant fields are fields that exist in every row and have a single value
across all rows.

Only item permutation fields that are constant are removed. Result fields are
not removed even though they are constant.

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

This software is copyright (c) 2020, 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
