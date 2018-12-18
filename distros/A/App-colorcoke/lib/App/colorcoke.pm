package App::colorcoke; 

use strict;

our $VERSION = '0.422';

1;


=pod

=head1 NAME

colorcoke - modify the extended, non-ANSI terminal colorset

=head1 DESCRIPTION

B<colorcoke> shows off some cool things you can do with the L<Term::ExtendedColor>
family of modules.

colorcoke lets one modify the extended colorset (88-16 or 256-16 colors,
respectively) for a running terminal session. The change takes effect
immediately - no need to restart the terminal.

Shades and tints can be generated for an arbitary number of ranges.

The ANSI colors can be left untouched, be included in a shade or set
separately. One can also exclude everything but the ANSI colors.
The ANSI colors is untouched by default.

The grey scale ramp (extended color index 232-255) is left untouched by
default. To include them, set the end point to 255.

Additional colors can be left untouched by specifying their index with the
C<--no flag>. This can also be configured in the configuration file.

The base color to use is specified with the -c flag, and the stepping
is controlled with the -r, -g and -b flag - red, green and blue channel.

Red, green and blue amount is specified with C<-rr>, C<-rg> and C<-rb> when the
randomizing option is used.

=head1 OPTIONS

  -c,   --color       the base color
  -r,   --red         red channel stepping
  -g,   --green       green channel stepping
  -b,   --blue        blue channel stepping
  -s,   --start       first color index to operate on (default: 17)
  -e,   --end         last  color index to operate on (default: 231)
  -a,   --ansi        modify the ANSI color range only
  -1,   --single      set a single color (HEX, index)
        --random      randomize the colors
  -rr,  --rand-red    control amount of red
  -rg,  --rand-green  control amount of green
  -rb,  --rand-blue   control amount of blue
  -n,   --no          do not modify color index n

  -h,   --help        show the help and exit
  -v,   --version     show version info and exit
  -m,   --man         show the manpage and exit

=head1 AUTHOR

  Magnus Woldrich
  CPAN ID: WOLDRICH
  m@japh.se
  http://japh.se

=head1 SEE ALSO

L<Term::ExtendedColor>, L<Term::ExtendedColor::Xresources>, L<Term::ExtendedColor::TTY>

=head1 COPYRIGHT

Copyright 2010, 2011, 2018 Magnus Woldrich <m@japh.se>. This program is free
software; you may redistribute it and/or modify it under the same terms as
Perl itself.

=cut
