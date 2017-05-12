package Convert::YText;

use strict;
use warnings;
use Carp;

use vars qw/$VERSION @ISA @EXPORT_OK/;
@ISA = 'Exporter';
@EXPORT_OK = qw( encode_ytext decode_ytext validate_ytext);

$VERSION="0.2";

=head1 NAME

Convert::YText - Quotes strings suitably for rfc2822 local part

=head1 VERSION

Version 0.2

=head1 SYNOPSIS

use Convert::YText qw(encode_ytext decode_ytext);

$encoded=encode_ytext($string);
$decoded=decode_ytext($encoded);

($decoded eq $string) || die "this should never happen!";

=head1 DESCRIPTION

Convert::YText converts strings to and from "YText", a format inspired
by xtext defined in RFC1894, the MIME base64 and quoted-printable
types (RFC 1394).  The main goal is encode a UTF8 string into something safe
for use as the local part in an internet email address  (RFC2822).

By default spaces are replaced with "+", "/" with "~", the characters
"A-Za-z0-9_.-" encode as themselves, and everything else is written
"=USTR=" where USTR is the base64 (using "A-Za-z0-9_." as digits)
encoding of the unicode character code.  The encoding is configurable
(see below).

=head1 PROCEDURAL INTERFACE

The module can can export C<encode_ytext> which converts arbitrary
unicode string into a "safe" form, and C<decode_ytext> which recovers
the original text.  C<validate_ytext> is a heuristic which returns 0
for bad input.


=cut


sub encode_ytext{
  my $str=shift;
  my $object = Convert::YText->new();
  return $object->encode($str);
}

sub decode_ytext{
  my $str=shift;
  my $object = Convert::YText->new();
  return $object->decode($str);
}

sub validate_ytext{
  my $str=shift;
  my $object = Convert::YText->new();
  return $object->valid($str);
}

=head1 OBJECT ORIENTED INTERFACE.

For more control, you will need to use the OO interface.

=head2 new

Create a new encoding object.

=head3 Arguments

Arguments are by name (i.e. a hash).

=over

=item DIGIT_STRING ("A-Za-z0-9_.") Must be 64 characters long

=item ESCAPE_CHAR ('=') Must not be in digit string.

=item SPACE_CHAR ('+') Non digit to replace space. Can be the empty string.

=item SLASH_CHAR ( '~') Non digit to replace slash. Can be the empty string.

=item EXTRA_CHARS ('._\-') Other characters to leave unencoded.

=back

=cut

sub new {
  my $class = shift;

  my %params=@_;

  my $self = { ESCAPE_CHAR=>'=',
	       SPACE_CHAR=>'+',
	       SLASH_CHAR=>'~',
	       EXTRA_CHARS=>'-',
	       DIGIT_STRING=>
	       "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_."
	     };

  while (my ($key,$val) = each %params){
    $self->{$key} = $val;
  };

  croak("DIGIT_STRING must have 64 characters got: ".$self->{DIGIT_STRING}) if (length($self->{DIGIT_STRING})!=64);

  # computed values. Setting directly is probably a bad idea.

  $self->{DIGITS}=[split "",$self->{DIGIT_STRING}];
  $self->{NO_ESCAPE}= $self->{DIGIT_STRING}.$self->{EXTRA_CHARS}.( length($self->{SPACE_CHAR}) ? ' ' : '' ) 
    . (length($self->{SLASH_CHAR}) ? '/' : '');

  $self->{ESCRX}=qr{\Q$self->{ESCAPE_CHAR}\E([\Q$self->{DIGIT_STRING}\E]+)\Q$self->{ESCAPE_CHAR}\E};

  $self->{MUST64}=qr{[^\Q$self->{NO_ESCAPE}\E]};

  $self->{VALIDRX}=qr{[\Q$self->{ESCAPE_CHAR}$self->{NO_ESCAPE}\E]+};

  bless ($self, $class);
  return $self;
}


sub encode_num{
  my $self=shift;
  my $num=shift;
  my $str="";

  while ($num>0){
    my $remainder=$num % 64;
    $num=$num >> 6;
    $str = $self->{DIGITS}->[$remainder].$str;
  }
  return $str;
}

sub decode_str{
  my $self=shift;
  my $str=shift;
  my @chars=split "",$str;
  my $num=0;

  while (scalar(@chars)>0){
    my $remainder=index $self->{DIGIT_STRING},$chars[0];
	
    croak("not a digit: ".$chars[0]. " in \"$str\"") if ($remainder <0);

    $num=$num << 6;
    $num+=$remainder;
    shift @chars;
  }
    
  return chr($num);
}

=head2 encode

=head3 Arguments

a string to encode.

=head3 Returns

encoded string

=cut

sub encode{
  my $self=shift;
  my $str=shift;
  
  $str=~ s/($self->{MUST64})/"$self->{ESCAPE_CHAR}".encode_num($self,ord($1))."$self->{ESCAPE_CHAR}"/ge;
  $str=~ s|/|$self->{SLASH_CHAR}|g if (length($self->{SLASH_CHAR}));
  $str=~ s/ /$self->{SPACE_CHAR}/g;
    
    return $str;
};

=head2 decode

=head3 Arguments

a string to decode.

=head3 Returns

encoded string

=cut

sub decode{
  my $self=shift;
  my $str = shift;
   
  $str=~ s/\Q$self->{SPACE_CHAR}\E/ /g if (length($self->{SPACE_CHAR}));
  $str=~ s|\Q$self->{SLASH_CHAR}\E|/|g if (length($self->{SLASH_CHAR}));
  $str=~ s/$self->{ESCRX}/ decode_str($self,$1)/eg;
  return $str;
}

=head2 valid

Simple necessary but not sufficient test for validity.

=cut 

sub valid{
  my $self=shift;
  my $str = shift;
   
  return $str =~ m/$self->{VALIDRX}/;
}

=head1 DISCUSSION

According to RFC 2822, the following non-alphanumerics are OK for the
local part of an address: "!#$%&'*+-/=?^_`{|}~". On the other hand, it
seems common in practice to block addresses having "%!/|`#&?" in the
local part.  The idea is to restrict ourselves to basic ASCII
alphanumerics, plus a small set of printable ASCII, namely "=_+-~.".


The characters '+' and '-' are pretty widely used to attach suffixes
(although usually only one works on a given mail host). It seems ok to
use '+-', since the first marks the beginning of a suffix, and then is
a regular character. The character '.' also seems mostly permissable.


=head1 AUTHOR

David Bremner, E<lt>ddb@cpan.org<gt>

=head1 COPYRIGHT

Copyright (C) 2011 David Bremner.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<MIME::Base64>, L<MIME::Decoder::Base64>, L<MIME::Decoder::QuotedPrint>.

=cut

1;
