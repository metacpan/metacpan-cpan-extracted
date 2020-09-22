package Bencher::Formatter::DeleteNotesFieldIfEmpty;

our $DATE = '2020-09-21'; # DATE
our $VERSION = '1.052'; # VERSION

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

    for my $row (@{$envres->[2]}) {
        return if $row->{notes};
    }

    $self->delete_fields(
        $envres,
        'notes'
    );
}

1;
# ABSTRACT: Delete notes field if there are no notes

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Formatter::DeleteNotesFieldIfEmpty - Delete notes field if there are no notes

=head1 VERSION

This document describes version 1.052 of Bencher::Formatter::DeleteNotesFieldIfEmpty (from Perl distribution Bencher-Backend), released on 2020-09-21.

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
