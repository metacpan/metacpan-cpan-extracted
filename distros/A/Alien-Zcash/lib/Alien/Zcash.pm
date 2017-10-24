package Alien::Zcash;

use strict;
use warnings;
use base qw( Alien::Base );

=head1 NAME

Alien::Zcash - Easily install Zcash cryptocoin full node

=head1 DESCRIPTION

This allows you to tell your favorite CPAN installer to install Zcash, via
your local CPAN mirror. This allows Perl applications to specify that they
depend on an external dependency, Zash, in a standard way, the Alien::*
namespace. Most likely you will not use this module directly, you just want
to do

    cpan Alien::Zcash

to install with the normal CPAN.pm client or:

    cpanm Alien::Zcash

to use the newer, more featureful cpanminus client.

=head1 AUTHOR

Duke Leto <duke@leto.net>

=head1 SUPPORT THIS WORK

Send your ZEC donations to

zcZLVdeNHvbw58ch56RWi92ws8hweLHyxhoT6jniFKd8kkBPXPR5E46YXzAqXhrfagtwRojAtumg4M3kmrHfZPU6m63Rj5z

to support this CPAN module. Thanks!

=head1 COPYRIGHT

Copyright (c) 2017 by Duke Leto <duke@leto.net>.  All rights reserved.

=head1 LICENSE AGREEMENT

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, Fuck Yeah!

=cut

"ZEC";
