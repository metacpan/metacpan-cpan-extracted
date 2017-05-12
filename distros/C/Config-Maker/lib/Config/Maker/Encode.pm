package Config::Maker::Encode;

use utf8;
use warnings;
use strict;

use Carp;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(encode decode encmode $utf8);
our @EXPORT_OK = @EXPORT;

sub encode($$;$);
sub decode($$;$);
sub encmode(*$);

our $utf8;

sub _encode_only_system($$;$) {
    my ($enc, $text, $check) = @_;
    unless($enc eq 'system') {
	if($check == 1) {
	    croak "Encoding not available. Can't convert encoding $enc";
	} else {
	    carp "Encoding not available. Can't convert encoding $enc";
	}
    }
    return $text;
}

sub _binmode_only_system(*$) {
    my ($handle, $enc) = @_;
    unless($enc eq 'system') {
	carp "Encoding not available. Can't set encoding to $enc";
    }
}

sub _binmode_encoding(*$) {
    my ($handle, $enc) = @_;
    binmode $handle, ":encoding($enc)";
}

eval {
    require I18N::Langinfo;
    require Encode;
    require Encode::Alias;
    require PerlIO::encoding;
    $::ENCODING = I18N::Langinfo::langinfo(&I18N::Langinfo::CODESET);
    if(!$::ENCODING) {
	$::ENCODING_LOG = "Can't get your locale encoding! Assuming ASCII.";
	Encode::find_encoding($::ENCODING = 'ascii')
	    or die "Can't get ascii codec!";
    } elsif(!Encode::find_encoding($::ENCODING)) {
	$::ENCODING_LOG = "Your locale encoding `$::ENCODING' it's not supported by Encode!";
	Encode::find_encoding($::ENCODING = 'ascii')
	    or die "Can't get ascii codec!";
    }
    Encode::Alias::define_alias('system' => $::ENCODING);
};

if($@) { # Encoding stuff not available!
    undef $::ENCODING;
    *encode = \&_encode_only_system;
    *decode = \&_encode_only_system;
    *encmode = \&_binmode_only_system;
    $utf8 = '';
} else { # Wow! Encoding is available!
    *encode = \&Encode::encode;
    *decode = \&Encode::decode;
    *encmode = \&_binmode_encoding;
    $utf8 = ':utf8';
    binmode STDERR, ':encoding(system)';
}

1;

__END__

=head1 NAME

Config::Maker::Encode - Wrapper for Encode and PerlIO::encoding

=head1 SYNOPSIS

  use Config::Maker::Encode

  $localtext = encode('system', $test);
  $text = decode('system', $localtext);
  encmode FH, 'system';

=head1 DESCRIPTION

This module exports three functions, C<encode>, C<decode> and C<encmode>. The
C<encode> and C<decode> functions work like their counterparts from L<Encode>.
The C<encmode> function is a wrapper around C<binmode> core function, that sets
C<:encoding(I<$encoding>)> layer.

These functions degrade gracefuly to nops, if not all of the recoding
infrastructure is available, as is the case with perl 5.6, printing a warning
if non-default operation was requested (where non-default means different from
C<system>).

Additionaly, a C<system> encoding alias is defined to whatever
C<I18N::Langinfo> reports as a locale encoding (falling back to C<ascii> if
that encoding is not supported by perl).

To fully support recoding, the modules L<Encode>, L<Encode::Alias>,
L<PerlIO::encoding> and L<I18N::Langinfo> must be available. If they are not,
dummy replacements are used as described above. In that case, C<Config::Maker>
will only work when all files are in the same default encoding and non-ascii
characters won't work in identifiers (since the data can't be internaly
translated to unicode).

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

configit(1), perl(1), Config::Maker(3pm), Encode(3pm), Encode::Alias(3pm),
I18N::Langinfo(3pm), PerlIO::encoding(3pm).

=cut
# arch-tag: 350a53f2-ce83-465a-9861-b4542b792033
