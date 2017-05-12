package Cikl::Smrt::Decoders::AutoDecoder;

use strict;
use warnings;
use Cikl::Smrt::DecoderRole;
use File::Type;
use Carp;
use Module::Pluggable search_path => "Cikl::Smrt::Decoders", 
      require => 1, sub_name => '_decoders', on_require_error => \&croak;

use namespace::autoclean;
use Mouse;
with 'Cikl::Smrt::DecoderRole';

has 'decoder_map' => (
  is => 'ro',
  isa => 'HashRef',
  init_arg => undef,
  builder => "_init_decoders"
);

has 'decoder_args' => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { return {} }
);

sub _init_decoders {
  my $self = shift;
  my $ret = {};
  foreach my $decoder (_decoders()) {
    next unless ($decoder->meta->does_role("Cikl::Smrt::AutoDecodableRole"));

    foreach my $mime_type ($decoder->mime_types()) {
      if (defined($ret->{$mime_type})) {
        my $existing = $ret->{$mime_type};
        die("Cannot associate $decoder with $mime_type. Already registered with $existing.");
      }
      $ret->{$mime_type} = $decoder;
    }
  }
  return $ret;
}

sub decode {
    my $self = shift;
    my $fh = shift;
    my $orig_pos = $fh->tell();
    my $buffer;
    $fh->read($buffer, 2048) or die($!);
    $fh->seek($orig_pos, 0) or die($!);

    my $ft = File::Type->new();
    my $type = $ft->mime_type($buffer);
    my $decoder_class = $self->decoder_map->{$type};
    unless($decoder_class) {
      die("Don't know how to decode $type");
    }

    my $decoder = $decoder_class->new(%{$self->decoder_args});
    return $decoder->decode($fh);
}

__PACKAGE__->meta->make_immutable();

1;


