use strict;
use warnings;

package B::Compiling;
our $AUTHORITY = 'cpan:FLORA';
# ABSTRACT: Expose PL_compiling to perl
$B::Compiling::VERSION = '0.06';
use B;
use XSLoader;

XSLoader::load(
    __PACKAGE__,
    exists $B::Compiling::{VERSION} ? ${ $B::Compiling::{VERSION} } : (),
);

use Sub::Exporter -setup => {
    exports => ['PL_compiling'],
    groups  => { default => ['PL_compiling'] },
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

B::Compiling - Expose PL_compiling to perl

=head1 SYNOPSIS

    use B::Compiling;

    BEGIN {
        warn "currently compiling ", PL_compiling->file;
    }

=head1 DESCRIPTION

This module exposes the perl interpreter's PL_compiling variable to perl.

=head1 FUNCTIONS

=head2 PL_compiling

This function returns a C<B::COP> object representing PL_compiling. It's
exported by default. See L<B> for documentation on how to use the returned
C<B::COP>.

=head1 SEE ALSO

L<B>

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
