package CPAN::Changes::Subclass::Cwalitee;

our $DATE = '2019-07-03'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(CPAN::Changes);

sub add_release {
    my $self = shift;

    for my $release ( @_ ) {
        my $new = Scalar::Util::blessed $release ? $release
            : CPAN::Changes::Release->new( %$release );
        $self->{ releases }->{ $new->version } = $new;

        # we also push to an array
        $self->{ _releases_array } //= [];
        push @{ $self->{_releases_array} }, $new;
    }
}

1;
# ABSTRACT: CPAN::Changes subclass for CPAN::Changes::Cwalitee

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Changes::Subclass::Cwalitee - CPAN::Changes subclass for CPAN::Changes::Cwalitee

=head1 VERSION

This document describes version 0.001 of CPAN::Changes::Subclass::Cwalitee (from Perl distribution CPAN-Changes-Cwalitee), released on 2019-07-03.

=head1 SYNOPSIS

Use as you would L<CPAN::Changes>.

=head1 DESCRIPTION

This subclass currently does the following:

=over

=item * In add_release, also store the releases in the order received

We want to know the original order of releases in the file.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CPAN-Changes-Cwalitee>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CPAN-Changes-Cwalitee>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Changes-Cwalitee>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
