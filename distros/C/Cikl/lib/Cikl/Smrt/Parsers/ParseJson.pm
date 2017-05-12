package Cikl::Smrt::Parsers::ParseJson;

use strict;
use warnings;

use JSON::XS;
use Mouse;
use Cikl::Smrt::Parser;
extends 'Cikl::Smrt::Parser';
use namespace::autoclean;

use constant NAME => 'json';
sub name { return NAME; }

has 'fields' => (
  is => 'ro',
  isa => 'Str',
  required => 1
);

has 'fields_map' => (
  is => 'ro',
  isa => 'Str',
  required => 1
);

sub parse {
    my $self = shift;
    my $fh = shift;
    my $broker = shift;

    my @fields      = split(/\s*,\s*/,$self->fields);
    my @fields_map  = split(/\s*,\s*/, $self->fields_map);
    my $cb = sub {
      my $a = shift;
      my $h = {};
      foreach (0 ... $#fields_map){
        my $v = $a->{$fields[$_]};
        if (defined($v)) {
          $h->{$fields_map[$_]} = lc($v);
        }
      }
      $broker->emit($h);
    };

    $self->_parse_json_as_stream($fh, $cb);
    return(undef);
}

# This will parse the JSON as a stream, which uses significantly less memory 
# than reading the entire structure in at once.
# In order to accomplish this, we have to strip off the '[' and ']' that we
# expect to surround the main JSON array in order to get the JSON lib to emit
# individual objects. We must also remove any commas that appear between 
# the objects that are emitted, as the incremental parser expects distinct 
# JSON objects.
#
# We're essentially going from a 'dump' json format:
#     [{...},{...},{...}]
#  to a 'streamed' json format:
#     {...}{...}{...}
#
# The parser should also be able to handle streamed the streamed format, if 
# provided.
#
sub _parse_json_as_stream { 
  my $self = shift;
  my $fh = shift;
  my $cb = shift;

  my $buf;
  my $json = JSON::XS->new();
  my $firstread = 1;
  my $trim_comma_on_read = 0;
  while (read($fh, $buf, 10000)) {
    if ($firstread == 1) {
      # Skip trim off the first '[', indicating the start of an array.
      $buf =~ s/^\s*\[//;
      $firstread = 0;
    }
    if (eof($fh)) {
      # Strip off the trailing ']'
      $buf =~ s/\]\s*$//;
    }
    if ($trim_comma_on_read == 1) {
      $buf =~ s/^\s*,//;
      $trim_comma_on_read = 0;
    }
    $json->incr_parse($buf);
    while (my $data = $json->incr_parse()) {
      $cb->($data);
      if ($json->incr_text =~ s/^\s*\]\s*$//) {
        # We're at the end of an object, and got the closing ']'. so, we'll
        # just let ourselves finish gracefully.
        last;
      }
      $json->incr_text =~ s/^\s*,//;
      # If there's nothing left in the buffer, then iterate to the next read.
      if ($json->incr_text =~ /^\s*$/) {
        $trim_comma_on_read = 1;
        last;
      }
    }
  }

  return undef;
}

__PACKAGE__->meta->make_immutable;

1;
