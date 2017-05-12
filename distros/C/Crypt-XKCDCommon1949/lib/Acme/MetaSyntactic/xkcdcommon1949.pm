package Acme::MetaSyntactic::xkcdcommon1949;
use base qw(Acme::MetaSyntactic::List);

use strict;
use warnings;

use Crypt::XKCDCommon1949;

our $VERSION = '1.000';

__PACKAGE__->init();

# our data isn't actually in __DATA__, but rather we override what
# ->init extracted with this glob routine to alias the data from
# Crypt::XKCDCommon1949 instead
*List = \@Crypt::XKCDCommon1949::words;

1;

__DATA__
__END__

=head1 NAME

Acme::MetaSyntactic::xkcdcommon1949 - xkcd common wordlist for Acme::MetaSyntactic

=head1 SYNOPSIS

  # see Crypt::XKCDCommon1949

=head1 DESCRIPTION

Interface for Acme::MetaSyntactic to the XKCD common 1949 wordlist.

=head1 AUTHOR

Written by Mark Fowler <mark@twoshortplanks.com>

=head1 COPYRIGHT

Copyright Mark Fowler 2013.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

Bugs should be reported via this distribution's
CPAN RT queue.  This can be found at
L<https://rt.cpan.org/Dist/Display.html?Crypt-XKCDCommon1949>

You can also address issues by forking this distribution
on github and sending pull requests.  It can be found at
L<http://github.com/2shortplanks/Crypt-XKCDCommon1949>

=head1 SEE ALSO

L<Crypt::XKCDCommon1949>, L<Acme::MetaSyntactic>