package Cache::utLRU;

use strict;
use warnings;

use XSLoader;
our $VERSION = '0.002000';
XSLoader::load(__PACKAGE__, $VERSION);

1;

__END__

=pod

=encoding utf8

=head1 SYNOPSIS

Cache::utLRU - A Perl LRU cache using the uthash library

=head1 VERSION

Version 0.002000

=head1 DESCRIPTION

Quick & dirty implementation of a Perl LRU cache using the uthash library.

=head1 AUTHORS

=over 4

=item * Gonzalo Diethelm C<< gonzus AT cpan DOT org >>

=back

=head1 THANKS

=over 4

=item * Vickenty Fesunov C<< kent AT setattr DOT net >>

=item * The C<uthash> team at L<http://troydhanson.github.com/uthash>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Gonzalo Diethelm.

This is free software, licensed under:

    The MIT (X11) License
