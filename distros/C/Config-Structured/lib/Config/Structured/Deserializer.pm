package Config::Structured::Deserializer;
$Config::Structured::Deserializer::VERSION = '2.000';
# ABSTRACT: Deserializes perl structures, JSON or YML data, from strings or files

use strict;
use warnings;

use File::Basename;
use IO::All;
use Readonly;

use JSON qw(decode_json);
use YAML::XS;

use Syntax::Keyword::Try;

use experimental qw(signatures);

Readonly::Hash my %FILE_TYPES => (
  yml  => 'yaml',
  yaml => 'yaml',
  json => 'json',
);
Readonly::Scalar my $DEFAULT_DECODER => q{perl};

sub decoders() {
  return (
    yaml => sub {
      Load(shift());
    },
    json => sub {
      decode_json(shift());
    },
    perl => sub {
      eval(shift());
    },
  );
}

sub is_filename($str) {
  return 0 if ($str =~ /\n/);
  return (-f $str);
}

sub decode ($class, $v) {
  return $v if (ref($v) eq 'HASH');

  my %decoders = decoders();
  my $hint     = $DEFAULT_DECODER;
  if (is_filename($v)) {
    my ($fn, $dirs, $suffix) = fileparse($v, keys(%FILE_TYPES));
    $hint = $FILE_TYPES{$suffix} if (defined($suffix));
    $v    = io->file($v)->slurp;
  }
  do {
    my $n       = $hint // (keys(%decoders))[0];
    my $decoder = delete($decoders{$n});
    try {
      my $structure = $decoder->($v);
      return $decoder->($v) if (ref($structure) eq 'HASH');
    } catch {
      # ignore any errors and try the next decoder, or die out at the bottom
    };
  } while (($hint) = keys(%decoders));
  die("Config::Structured was unable to decode input");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Structured::Deserializer - Deserializes perl structures, JSON or YML data, from strings or files

=head1 VERSION

version 2.000

=head1 AUTHOR

Mark Tyrrell <mtyrrell@concertpharma.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Concert Pharmaceuticals, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
