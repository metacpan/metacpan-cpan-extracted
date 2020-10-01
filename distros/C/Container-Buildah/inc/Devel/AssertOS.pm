package #
Devel::AssertOS;

use Devel::CheckOS;

use strict;
use warnings;

our $VERSION = '1.21';

=head1 NAME

Devel::AssertOS - require that we are running on a particular OS

=head1 DESCRIPTION

Devel::AssertOS is a utility module for Devel::CheckOS and
Devel::AssertOS::*.  It is nothing but a magic C<import()> that lets you
do this:

    use Devel::AssertOS qw(Linux FreeBSD Cygwin);

which will die unless the platform the code is running on is Linux, FreeBSD
or Cygwin.

To assert that the OS is B<not> a specific platform, prepend the platform name
with a minus sign. For example, to run on anything but Amiga, do:

    use Devel::AssertOS qw(-Amiga);


=cut

sub import {
    shift;
    die("Devel::AssertOS needs at least one parameter\n") unless(@_);

    my @oses = @_;

    my ( @must, @must_not );

    for my $os ( @oses ) {
        if ( $os =~ s/^-// ) {
            push @must_not, $os;
        }
        else {
            push @must, $os;
        }
    }

    Devel::CheckOS::die_if_os_is(@must_not) if @must_not;
    Devel::CheckOS::die_if_os_isnt(@must)   if @must;
}

=head1 BUGS and FEEDBACK

I welcome feedback about my code, including constructive criticism.
Bug reports should be made using L<https://github.com/DrHyde/perl-modules-Devel-CheckOS/issues>.

You will need to include in your bug report the exact value of $^O, what
the OS is called (eg Windows Vista 64 bit Ultimate Home Edition), and,
if relevant, what "OS family" it should be in and who wrote it.

If you are feeling particularly generous you can encourage me in my
open source endeavours by buying me something from my wishlist:
  L<http://www.cantrell.org.uk/david/wishlist/>

=head1 SEE ALSO

$^O in L<perlvar>

L<perlport>

L<Devel::CheckOS>

L<Devel::AssertOS::Extending>

The use-devel-assertos script

L<Module::Install::AssertOS>

=head1 AUTHOR

David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

Thanks to David Golden for suggesting that I add this utility module.

=head1 COPYRIGHT and LICENCE

Copyright 2007 David Cantrell

This software is free-as-in-speech software, and may be used, distributed, and modified under the terms of either the GNU General Public Licence version 2 or the Artistic Licence. It's up to you which one you use. The full text of the licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

$^O;
