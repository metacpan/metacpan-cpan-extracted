# $Id: /mirror/coderepos/lang/perl/Alien-Iconv/trunk/lib/Alien/Iconv.pm 50848 2008-04-18T23:33:49.283250Z daisuke  $

package Alien::Iconv;
use strict;
use vars qw($VERSION);

$VERSION = '1.12001';

1;

__END__

=head1 NAME

Alien::Iconv - Wrapper For Installing libiconv 1.12

=head1 DESCRIPTION

NOTE: Alpha quality! Testers are welcome, but please be patient and kindly
report any breakage.

Alien::Iconv is a wrapper to install libiconv library. Modules that depend on
libiconv can depend on Alien::Iconv and use the CPAN shell to install it for you.

For Win32 people, sorry, At this moment I have no clue how to install
libiconv on Windows. Please send in patches if you would like that feature

=head1 AUTHORS

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=cut