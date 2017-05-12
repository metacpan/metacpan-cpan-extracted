package Data::Printer::Filter::ClassicRegex;
use warnings;
use strict;

use Data::Printer::Filter;

our $VERSION = 0.01;


# borrowed almost verbatim from Gisle Aas' Data::Dump
filter 'Regexp' => sub {
  my ($item, $p) = @_;
  my $v = "$item";
  my $mod = "";
  if ($v =~ /^\(\?\^?([msix-]*):([\x00-\xFF]*)\)\z/) {
    $mod = $1;
    $v = $2;
    $mod =~ s/-.*//;
  }

  my $sep = '/';
  my $sep_count = ($v =~ tr/\///);
  if ($sep_count) {
    # see if we can find a better one
    for ('|', ',', ':', '#') {
      my $c = eval "\$v =~ tr/\Q$_\E//"; ## no critic
      if ($c < $sep_count) {
        $sep = $_;
        $sep_count = $c;
        last if $sep_count == 0;
      }
    }
  }
  $v =~ s/\Q$sep\E/\\$sep/g;
  return "qr$sep$v$sep$mod";
};


42;
__END__

=head1 NAME

Data::Printer::Filter::ClassicRegex - print regexes the classic qr// way


=head1 SYNOPSIS

    use Data::Printer filters => {
        -external => [ 'ClassicRegex' ],
    };


=head1 DESCRIPTION

L<Data::Printer> shows regular expressions in a fancy way:

   foo.*bar  (modifiers: i)

This module provides a filter that will display them the classic, Perlish way:

   qr/foo.*bar/i

Enjoy!

=head1 SEE ALSO

L<Data::Printer>

L<Data::Printer::Filter::URI>

L<Data::Dump>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-data-printer-filter-classicregex@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Breno G. de Oliveira  C<< <garu@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Breno G. de Oliveira C<< <garu@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
