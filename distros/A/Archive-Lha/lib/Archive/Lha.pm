package Archive::Lha;

use strict;
use warnings;

our $VERSION = '0.22';

require XSLoader;
XSLoader::load('Archive::Lha', $VERSION);

1;

__END__

=encoding UTF-8

=head1 NAME

Archive::Lha - read and extract .LZH/.LHA archives

=head1 SYNOPSIS

  use Archive::Lha::Header;
  use Archive::Lha::Stream::File;
  use Archive::Lha::Decode;

  my $stream = Archive::Lha::Stream::File->new(file => 'archive.lzh');
  while (defined(my $level = $stream->search_header)) {
    my $header = Archive::Lha::Header->new(
      level  => $level,
      stream => $stream,
    );

    # filename decoded from archive charset (auto-detected from OS field)
    print $header->pathname, "\n";

    # or override charset explicitly
    print $header->pathname('cp932', 'utf-8'), "\n";

    $stream->seek($header->data_top);
    my $decoded = '';
    my $decoder = Archive::Lha::Decode->new(
      header => $header,
      read   => sub { $stream->read(@_) },
      write  => sub { $decoded .= join '', @_ },
    );
    my $crc = $decoder->decode;
    die "crc mismatch for " . $header->pathname if $crc != $header->crc16;

    $stream->seek($header->next_header);
  }

=head1 DESCRIPTION

Archive::Lha reads and extracts LZH/LHA archives, the format historically
used by the Amiga LhA archiver and MS-DOS LHA, and still common in Japan
and in Amiga software archives.

The module supports header levels 0, 1 and 2, and decompression methods
lh0 (stored), lh5, lh6 and lh7. The decompression code is implemented in
XS/C, based on LHa for UNIX.

=head2 Filename encoding

LHA archives store filenames as raw bytes. The encoding depends on the
platform that created the archive. C<Archive::Lha::Header::pathname()>
auto-detects the encoding from the OS field in the header:

  Amiga (A)       -> ISO-8859-15
  MS-DOS/Win (M/w)-> CP1252
  Unix (U)        -> UTF-8
  Human68K (H)    -> CP932 (Sharp X68000, Japanese)
  unknown/level-0 -> Encode::Guess (latin1/latin2/cp932/euc-jp)

The result is always returned as UTF-8. Pass explicit C<($from, $to)>
arguments to C<pathname()> to override:

  $header->pathname('cp932', 'utf-8');
  $header->pathname('iso-8859-1', 'utf-8');

=head1 KNOWN LIMITATIONS

=over 4

=item *

Decompression is slower than native tools. Some of the critical code is in
XS/C, but large archives may still take longer than tools like lhasa or
LHa for UNIX.

=item *

Creating or modifying archives is not supported — read and extract only.

=item *

Header level 3 is not supported (it is rarely found in practice).

=back

=head1 COMMAND LINE TOOLS

This distribution includes two command line tools:

=over 4

=item L<plha>

Lists and extracts archives using Amiga LhA-compatible output formats
(C<l>, C<v>, C<vv>, C<x>, C<t> commands). Supports C<-fc>/C<-tc> for
charset override.

=item L<plhasa>

A symlink to C<plha> that activates a lhasa-compatible interface when
invoked as C<plhasa>.

=back

=head1 ACKNOWLEDGMENTS

The XS/C decompression code is based on LHa for UNIX version
1.14i-ac20050924p1, with modifications for thread-safety and XS
integration. Those parts are copyrighted by Nobutaka Watazaki (1993-1995),
Tsugio Okamoto (1996-2000?), and Koji Arai (2002-). Kudos also to the
broader LHa family authors: Masaru Oki, Yoichi Tagawa, Haruhiko Okumura,
Haruyasu Yoshizaki, Kazuhiko Miki and others.

=head1 SEE ALSO

=over 4

=item L<https://github.com/jca02266/lha> (LHa for UNIX)

=item L<https://github.com/fragglet/lhasa> (lhasa, read-only LHA tool)

=item L<http://lha.sourceforge.jp/> (LHa for UNIX project site, now offline)
— archived at L<https://web.archive.org/web/*/http://lha.sourceforge.jp/>

=item L<http://lha.sourceforge.jp/history.html> (history of LHa for UNIX, now offline)
— archived at L<https://web.archive.org/web/*/http://lha.sourceforge.jp/history.html>

=item L<http://homepage1.nifty.com/dangan/en/Content/Program/Java/jLHA/Notes/Notes.html>
(LHa header format details, may be offline)
— archived at L<https://web.archive.org/web/*/http://homepage1.nifty.com/dangan/en/Content/Program/Java/jLHA/Notes/Notes.html>

=item L<http://oku.edu.mie-u.ac.jp/~okumura/compression/oldstory.html>
(older history of LHa/LHarc, may be offline)
— archived at L<https://web.archive.org/web/*/http://oku.edu.mie-u.ac.jp/~okumura/compression/oldstory.html>

=back

=head1 AUTHORS

Kenichi Ishigaki E<lt>ishigaki@cpan.orgE<gt> (original author).

Nicolas Mendoza E<lt>mendoza@pvv.ntnu.noE<gt> (Amiga support, charset
handling, CLI tools, bug fixes).

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki, unless otherwise noted.

Copyright (C) 2025-2026 by Nicolas Mendoza, for additional modifications.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
