package Data::Coloured;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Visualize random ASCII data streams
$Data::Coloured::VERSION = '0.003';
use strict;
use warnings;
use Exporter 'import';
use Term::ANSIColor qw( colored );

our @EXPORT_OK = qw( pc c );
our @EXPORT = qw( coloured poloured );

our %control = (qw(
    0 NUL
    1 SOH
    2 STX
    3 ETX
    4 EOT
    5 ENQ
    6 ACK
    7 BEL
    8 BS
    9 TAB
   10 LF
   11 VT
   12 FF
   13 CR
   14 SO
   15 SI 
   16 DLE
   17 DC1
   18 DC2
   19 DC3
   20 DC4
   21 NAK
   22 SYN
   23 ETB
   24 CAN
   25 EM
   26 SUB
   27 ESC
   28 FS
   29 GS
   30 RS
   31 US
  127 DEL
));

our %colours = (qw(
  control bright_red
  print   bright_yellow
  binary  bright_cyan
));

our @control_delimiter = qw( [ ] );
our @binary_delimiter = qw( < > );

sub poloured {
  print coloured(@_);
}
sub pc { poloured(@_) }

sub coloured {
  my $data = join('',@_);
  my @chars = split(//,$_[0]);
  my $output = "";
  for my $char (@chars) {
    my $chr = ord($char);
    if (defined $control{$chr}) {
      $output .= colored($control_delimiter[0].$control{$chr}.$control_delimiter[1],$colours{control});
    } elsif ($char =~ /[ -~]/) {
      $output .= colored($char,$colours{print});
    } else {
      $output .= colored($binary_delimiter[0].unpack('H*',$char).$binary_delimiter[1], $colours{binary});
    }
  }
  return $output;
}
sub c { coloured(@_) }

1;

__END__

=pod

=head1 NAME

Data::Coloured - Visualize random ASCII data streams

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use DDC;

  my $coloured = coloured($data);
  my $coloured = c($data);
  poloured($data); # print coloured
  pc($data);       # same

  use Data::Coloured; # no auto export of pc and c

=head1 DESCRIPTION

This module is made for visualizing in coloured and printable form random bytes
of a data stream or any other source. It was specifically made for debugging
TCP and UART connections, to also see the control characters.

This module does the following with the data for return or print:

=over

=item Control characters

The ASCII control characters are described on L<Wikipedia|http://en.wikipedia.org/wiki/ASCII#ASCII_control_code_chart>.
Those get replaced with their name listed in "Abbreviation" on the Wikipedia
page, surrounded by square brackets (exception is here B<HT> which is shown as
B<TAB>). The ANSI colour is B<bright_red>

=item Printable characters

The prinatable characters (from space to ~) are just taken as is, and put in
the colour B<bright_yellow>.

=item Binary characters / extended ASCII

All non printable characters, so those above 127, are converted into their hex
value and surrounded by angle brackets.

=back

=head1 SUPPORT

IRC

  Join #vonbienenstock on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-data-coloured
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-data-coloured/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
