package Apache::GuessCharset;

use strict;
our $VERSION = 0.03;
our $DEBUG   = 0;

use Apache::Constants;
use Apache::File;
use Encode::Guess;
use I18N::Charset;

# generated from http://www.iana.org/assignments/character-sets
# '/Name: (\S*)/ and $name = $1; /Alias: (\S*).*preferred MIME/ and print qq("$name" => "$1",)'
our %Prefered_MIME = (
    "ANSI_X3.4-1968" => "US-ASCII",
    "ISO_8859-1:1987" => "ISO-8859-1",
    "ISO_8859-2:1987" => "ISO-8859-2",
    "ISO_8859-3:1988" => "ISO-8859-3",
    "ISO_8859-4:1988" => "ISO-8859-4",
    "ISO_8859-6:1987" => "ISO-8859-6",
    "ISO_8859-6-E" => "ISO-8859-6-E",
    "ISO_8859-6-I" => "ISO-8859-6-I",
    "ISO_8859-7:1987" => "ISO-8859-7",
    "ISO_8859-8:1988" => "ISO-8859-8",
    "ISO_8859-8-E" => "ISO-8859-8-E",
    "ISO_8859-8-I" => "ISO-8859-8-I",
    "ISO_8859-5:1988" => "ISO-8859-5",
    "ISO_8859-9:1989" => "ISO-8859-9",
    "Extended_UNIX_Code_Packed_Format_for_Japanese" => "EUC-JP",
);

sub handler {
    my $r = shift;
    return DECLINED if
	! $r->is_main                  or
	$r->content_type !~ m@^text/@  or
	$r->content_type =~ /charset=/ or
	! -e $r->finfo                 or
	-d _                           or
	!(my $chunk = read_chunk($r));

    my @suspects = $r->dir_config->get('GuessCharsetSuspects');
    my $enc  = guess_encoding($chunk, @suspects);
    unless (ref $enc) {
	warn "Couldn't guess encoding: $enc" if $DEBUG;
	return DECLINED;
    }

    my $iana    = iana_charset_name($enc->name);
    my $charset = lc($Prefered_MIME{$iana} || $iana); # lowercased
    warn "Guessed: $charset" if $DEBUG;
    $r->content_type($r->content_type . "; charset=$charset");
    return OK;
}

sub read_chunk {
    my $r  = shift;
    my $fh = Apache::File->new($r->filename) or return;
    my $buffer_size = $r->dir_config('GuessCharsetBufferSize') || 512;
    read $fh, my($chunk), $buffer_size;
    return $chunk;
}

1;
__END__

=head1 NAME

Apache::GuessCharset - adds HTTP charset by guessing file's encoding

=head1 SYNOPSIS

  SetHandler perl-script
  PerlFixupHandler +Apache::GuessCharset

  # how many bytes to read for guessing (default 512)
  PerlSetVar GuessCharsetBufferSize 1024

  # list of encoding suspects
  PerlSetVar GuessCharsetSuspects euc-jp
  PerlAddVar GuessCharsetSuspects shiftjis
  PerlAddVar GuessCharsetSuspects 7bit-jis

=head1 DESCRIPTION

Apache::GuessCharset is an Apache fix-up handler which adds HTTP
charset attribute by automaticaly guessing text files' encodings via
Encode::Guess.

=head1 CONFIGURATION

This module uses following configuration variables.

=over 4

=item GuessCharsetSuspects

a list of encodings for C<Encode::Guess> to check. See
L<Encode::Guess> for details.

=item GuessCharsetBufferSize

specifies how many bytes for this module to read from source file, to
properly guess encodings. default is 512.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Encode::Guess>, L<Apache::File>

=cut
