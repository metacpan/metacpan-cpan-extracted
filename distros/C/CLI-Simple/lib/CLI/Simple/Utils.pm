package CLI::Simple::Utils;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English  qw(-no_match_chars);
use JSON::PP qw(decode_json);

use parent qw(Exporter);

our @EXPORT_OK = qw( slurp slurp_json dump_json normalize_options);

our $VERSION = '0.0.2';

########################################################################
sub slurp_json {
########################################################################
  my ($file) = @_;

  my $json = eval { return decode_json( slurp($file) ) };

  croak "ERROR: could not decode JSON string:\n$EVAL_ERROR\n"
    if !$json || $EVAL_ERROR;

  return $json;
}

########################################################################
sub slurp {
########################################################################
  my ($file) = @_;

  local $RS = undef;

  open my $fh, '<', $file
    or croak "ERROR: could not open $file\n";

  my $content = <$fh>;

  close $fh
    or carp "ERROR: could not close $file\n";

  return $content;
}

########################################################################
sub normalize_options {
########################################################################
  my ($options) = @_;

  foreach my $k ( keys %{$options} ) {
    next if $k !~ /\-/xsm;
    my $val = delete $options->{$k};

    $k =~ s/\-/_/gxsm;

    $options->{$k} = $val;
  }

  return %{$options};
}

########################################################################
sub dump_json {
########################################################################
  my ($obj) = @_;

  return JSON::PP->new->pretty->encode($obj);
}

1;
