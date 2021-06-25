package Compress::LZString;

use 5.006002;
use strict;
use warnings;

# old perl supresses malformed utf-8-strict characters like unpaired surrogate
no if $] < 5.014, warnings => qw/utf8/;

$Compress::LZString::VERSION = '1.4401';
 
BEGIN {
  use Exporter( );
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, @EXPORT_FAIL, %EXPORT_TAGS);

  $VERSION     = $Compress::LZString::VERSION;
  @ISA         = qw/Exporter/;
  @EXPORT      = qw/compress_b64   compress_b64_safe
                    decompress_b64 decompress_b64_safe/;
  @EXPORT_OK   = qw/compress   compressToBase64     compressToEncodedURIComponent
                    decompress decompressFromBase64 decompressFromEncodedURIComponent/;
  %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);
}

END { }


my $keyStrBase64  = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
my $keyStrUriSafe = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-$';
my %baseReverseDic;

sub compress_b64        { return compressToBase64(shift); }
sub compress_b64_safe   { return compressToEncodedURIComponent(shift); }
sub decompress_b64      { return decompressFromBase64(shift); }
sub decompress_b64_safe { return decompressFromEncodedURIComponent(shift); }

sub compressToBase64 {
  my $input = shift;
  return unless $input;
  return _rpad(_compress($input, 6, sub { substr $keyStrBase64,shift,1; }));
}

sub compressToEncodedURIComponent {
  my $input = shift;
  return unless $input;
  return _compress($input, 6, sub { substr $keyStrUriSafe,shift,1; });
}

sub compress {
  my $uncompressed = shift;
  return unless $uncompressed;
  return _compress($uncompressed, 16, sub { chr shift; });
}

sub decompressFromBase64 {
  my $compressed = shift;
  return _decompress(length $compressed, 32,
    sub { getBaseValue($keyStrBase64, substr $compressed,shift,1); });
}

sub decompressFromEncodedURIComponent {
  (my $compressed = shift) =~ s/ /+/g;
  return _decompress(length $compressed, 32,
    sub { getBaseValue($keyStrUriSafe, substr $compressed,shift,1); });
}

sub decompress {
  my $compressed = shift;
  return _decompress(length $compressed, 32768, sub { ord substr $compressed,shift,1; });
}

sub _compress {
  my ($uncompressed, $bitsPerChar, $getCharFromInt) = @_;
  return unless $uncompressed;

  my %context_dictionary;
  my %context_dictionaryToCreate;
  my $context_c  = "";
  my $context_wc = "";
  my $context_w  = "";
  my $context_enlargeIn = 2;
  my $context_dictSize  = 3;
  my $context_numBits   = 2;
  my @context_data;
  my $context_data_val      = 0;
  my $context_data_position = 0;

  my $value = 0;

  foreach (split //, $uncompressed)
  {
    eval {
      $context_dictionary{$_} = $context_dictSize++;
      $context_dictionaryToCreate{$_} = 1;
    } unless defined $context_dictionary{$_};

    $context_c  = $_;
    $context_wc = $context_w . $context_c;
    $context_w  = $context_wc, next if defined $context_dictionary{$context_wc};

    if (defined $context_dictionaryToCreate{$context_w})
    {
      if ((ord substr $context_w,0,1) < 256)
      {
        foreach (1..$context_numBits)
        {
          $context_data_val <<= 1;
          if ($context_data_position == $bitsPerChar-1)
          {
            $context_data_position = 0;
            push @context_data, &$getCharFromInt($context_data_val);
            $context_data_val = 0;
          } else { $context_data_position++; }
        }
        $value = ord substr $context_w,0,1;
        foreach (1..8)
        {
          $context_data_val = ($context_data_val<<1) | ($value&1);
          if ($context_data_position == $bitsPerChar-1)
          {
            $context_data_position = 0;
            push @context_data, &$getCharFromInt($context_data_val);
            $context_data_val = 0;
          } else { $context_data_position++; };
          $value >>= 1;
        }
      }
      else
      {
        $value = 1;
        foreach (1..$context_numBits)
        {
          $context_data_val = ($context_data_val<<1) | $value;
          if ($context_data_position == $bitsPerChar-1)
          {
            $context_data_position = 0;
            push @context_data, &$getCharFromInt($context_data_val);
            $context_data_val = 0;
          } else { $context_data_position++; };
          $value = 0;
        }
        $value = ord substr $context_w,0,1;
        foreach (1..16)
        {
          $context_data_val = ($context_data_val<<1) | ($value&1);
          if ($context_data_position == $bitsPerChar-1)
          {
            $context_data_position = 0;
            push @context_data, &$getCharFromInt($context_data_val);
            $context_data_val = 0;
          } else { $context_data_position++; };
          $value >>= 1;
        }
      }
      $context_enlargeIn--;
      if ($context_enlargeIn == 0)
      {
        $context_enlargeIn = 2**$context_numBits;
        $context_numBits++;
      }
      delete $context_dictionaryToCreate{$context_w};
    }
    else
    {
      $value = $context_dictionary{$context_w};
      foreach (1..$context_numBits)
      {
        $context_data_val = ($context_data_val<<1) | ($value&1);
        if ($context_data_position == $bitsPerChar-1)
        {
          $context_data_position = 0;
          push @context_data, &$getCharFromInt($context_data_val);
          $context_data_val = 0;
        } else { $context_data_position++; };
        $value >>= 1;
      }
    }
    $context_enlargeIn--;
    if ($context_enlargeIn == 0)
    {
      $context_enlargeIn = 2**$context_numBits;
      $context_numBits++;
    }
    # add wc to the dictionary
    $context_dictionary{$context_wc} = $context_dictSize++;
    $context_w = $context_c;
  }

  # output the code for w.
  if ($context_w ne "")
  {
    if (defined $context_dictionaryToCreate{$context_w})
    {
      if ((ord substr $context_w,0,1) < 256)
      {
        foreach (1..$context_numBits)
        {
          $context_data_val <<= 1;
          if ($context_data_position == $bitsPerChar-1)
          {
            $context_data_position = 0;
            push @context_data, &$getCharFromInt($context_data_val);
            $context_data_val = 0;
          } else { $context_data_position++; }
        }
        $value = ord substr $context_w,0,1;
        foreach (1..8)
        {
          $context_data_val = ($context_data_val<<1) | ($value&1);
          if ($context_data_position == $bitsPerChar-1)
          {
            $context_data_position = 0;
            push @context_data, &$getCharFromInt($context_data_val);
            $context_data_val = 0;
          } else { $context_data_position++; };
          $value >>= 1;
        }
      }
      else
      {
        $value = 1;
        foreach (1..$context_numBits)
        {
          $context_data_val = ($context_data_val<<1) | $value;
          if ($context_data_position == $bitsPerChar-1)
          {
            $context_data_position = 0;
            push @context_data, &$getCharFromInt($context_data_val);
            $context_data_val = 0;
          } else { $context_data_position++; };
          $value = 0;
        }
        $value = ord substr $context_w,0,1;
        foreach (1..16)
        {
          $context_data_val = ($context_data_val<<1) | ($value&1);
          if ($context_data_position == $bitsPerChar-1)
          {
            $context_data_position = 0;
            push @context_data, &$getCharFromInt($context_data_val);
            $context_data_val = 0;
          } else { $context_data_position++; };
          $value >>= 1;
        }
      }
      $context_enlargeIn--;
      if ($context_enlargeIn == 0)
      {
        $context_enlargeIn = 2**$context_numBits;
        $context_numBits++;
      }
      delete $context_dictionaryToCreate{$context_w};
    }
    else
    {
      $value = $context_dictionary{$context_w};
      foreach (1..$context_numBits)
      {
        $context_data_val = ($context_data_val<<1) | ($value&1);
        if ($context_data_position == $bitsPerChar-1)
        {
          $context_data_position = 0;
          push @context_data, &$getCharFromInt($context_data_val);
          $context_data_val = 0;
        } else { $context_data_position++; };
        $value >>= 1;
      }
    }
    $context_enlargeIn--;
    if ($context_enlargeIn == 0)
    {
      $context_enlargeIn = 2**$context_numBits;
      $context_numBits++;
    }
  }

  # mark the end of the stream
  $value = 2;
  foreach (1..$context_numBits)
  {
    $context_data_val = ($context_data_val<<1) | ($value&1);
    if ($context_data_position == $bitsPerChar-1)
    {
      $context_data_position = 0;
      push @context_data, &$getCharFromInt($context_data_val);
      $context_data_val = 0;
    } else { $context_data_position++; };
    $value >>= 1;
  }

  # flush the last char
  do { $context_data_val <<= 1; } until $context_data_position++ == $bitsPerChar-1;
  push @context_data, &$getCharFromInt($context_data_val);

  return pack "A*"x@context_data, @context_data;
}

sub _decompress {
  my ($length, $resetValue, $getNextValue) = @_;

  my %dictionary;
  my $enlargeIn = 4;
  my $dictSize  = 4;
  my $numBits   = 3;
  my $entry     = "";
  my @result;

  my %data;
  $data{val}        = &$getNextValue(0);
  $data{position}   = $resetValue;
  $data{index}      = 1;
  @dictionary{0..2} = 0..2;

  my ($w, $c) = (0, 0);
  my ($bits, $maxpower, $power) = (0, 2**2, 1);
  do {{
    $bits |= (($data{val}&$data{position})>0 ? 1:0)*$power;
    next if $data{position} >>= 1;
    $data{position} = $resetValue;
    $data{val}      = &$getNextValue($data{index}++);
  }} until ($power<<=1) == $maxpower;

  if ($bits == 0)
  {
    ($bits, $maxpower, $power) = (0, 2**8, 1);
    do {{
      $bits |= (($data{val}&$data{position})>0 ? 1:0)*$power;
      next if $data{position} >>= 1;
      $data{position} = $resetValue;
      $data{val}      = &$getNextValue($data{index}++);
    }} until ($power<<=1) == $maxpower;
    $c = chr $bits;
  }
  elsif ($bits == 1)
  {
    ($bits, $maxpower, $power) = (0, 2**16, 1);
    do {{
      $bits |= (($data{val}&$data{position})>0 ? 1:0)*$power;
      next if $data{position} >>= 1;
      $data{position} = $resetValue;
      $data{val}      = &$getNextValue($data{index}++);
    }} until ($power<<=1) == $maxpower;
    $c = chr $bits;
  }
  elsif ($bits == 2) { return; }

  # print(bits)
  $dictionary{3} = $w=$c;
  push @result, $c;

  do {
    return if $data{index} > $length;

    ($bits, $maxpower, $power) = (0, 2**$numBits, 1);
    do {{
      $bits |= (($data{val}&$data{position})>0 ? 1:0)*$power;
      next if $data{position} >>= 1;
      $data{position} = $resetValue;
      $data{val}      = &$getNextValue($data{index}++);
    }} until ($power<<=1) == $maxpower;

    if (($c=$bits) == 0)
    {
      ($bits, $maxpower, $power) = (0, 2**8, 1);
      do {{
        $bits |= (($data{val}&$data{position})>0 ? 1:0)*$power;
        next if $data{position} >>= 1;
        $data{position} = $resetValue;
        $data{val}      = &$getNextValue($data{index}++);
      }} until ($power<<=1) == $maxpower;
      $c = $dictSize; $enlargeIn--;
      $dictionary{$dictSize++} = chr $bits;
    }
    elsif ($bits == 1)
    {
      ($bits, $maxpower, $power) = (0, 2**16, 1);
      do {{
        $bits |= (($data{val}&$data{position})>0 ? 1:0)*$power;
        next if $data{position} >>= 1;
        $data{position} = $resetValue;
        $data{val}      = &$getNextValue($data{index}++);
      }} until ($power<<=1) == $maxpower;
      $c = $dictSize; $enlargeIn--;
      $dictionary{$dictSize++} = chr $bits;
    }
    elsif ($bits == 2) { return pack "A*"x@result, @result; };

    $enlargeIn = 2**$numBits++ unless $enlargeIn;

    if (defined $dictionary{$c}) { $entry = $dictionary{$c}; }
    else { return unless $c == $dictSize; $entry = $w.substr $w,0,1; }
    push @result, $entry;

    # add w+entry[0] to the dictionary
    $dictionary{$dictSize++} = $w.substr $entry,0,1;
    $w = $entry; $enlargeIn--;

    $enlargeIn = 2**$numBits++ unless $enlargeIn;
  } while 1;
}

sub _rpad {
  my $str = shift;
  my $len = 4*int((length($str)-1)/4)+4;
  return substr $str."===", 0, $len;
}

sub getBaseValue {
  my ($alphabet, $character) = @_;
  eval {
    @{$baseReverseDic{$alphabet}}{split//,$alphabet} = (0..length $alphabet);
  } unless defined $baseReverseDic{$alphabet};

  return $baseReverseDic{$alphabet}{$character};
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Compress::LZString - LZ-based compression library

=head1 SYNOPSIS

  use Compress::LZString;

  my $plain_text = "Hello, world.";
  my $compressed = compress_b64_safe($plain_text);      # BIUwNmD2A0AEDukBOYAmA6IA
  my $decompressed = decompress_b64_safe($compressed);  # Hello, world.

=head1 DESCRIPTION

L<Compress::LZString> is a perl implementation of lz-string, a fast LZ-based
compression library written in javascript. It is designed to fulfill the need
of storing large amounts of data in browser's localStorage, specifically on
mobile devices.

=head1 FUNCTIONS

=head2 compress

  $compressed = compress($plain_text);

Compresses the given text and returns the result set of bytes.

=head2 compress_b64

  $compressed = compress_b64($plain_text);

Returns a human-readable text stream encoded in base64.

=head2 compress_b64_safe

  $compressed = compress_b64_safe($plain_text);

Returns a text stream encoded in base64 with a few characters replaced to make
sure the result B<URI safe>, which is ready to be sent to web servers.

=head2 decompress

=head2 decompress_b64

=head2 decompress_b64_safe

Decompresses the binary/text stream processed by the function C<compress>,
C<compress_b64>, C<compress_b64_safe>, respectively.

=head2 compressToBase64

=head2 compressToEncodedURIComponent

=head2 decompressFromBase64

=head2 decompressFromEncodedURIComponent

Synonyms of C<compress_b64>, C<compress_b64_safe>, C<decompress_b64>,
C<decompress_b64_safe>, respectively. If you'd like to use the exactly same
function names as is in the JS version of lz-string, you can simply import
these functions and play with them.

=head1 VERSION

This is a port of L<lz-string|https://github.com/pieroxy/lz-string> v.1.4.4
javascript code to perl.

=head1 SEE ALSO

L<pieroxy/lz-string|https://pieroxy.net/blog/pages/lz-string/index.html>
(released under the MIT License)

=head1 AUTHOR

Lucia Poppová <popp@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Lucia Poppová

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
# vim:ai ci et sm sw=2 sts=2
