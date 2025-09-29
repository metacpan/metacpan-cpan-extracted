package CLI::Simple::Utils;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use JSON qw(decode_json);
use List::Util qw(none);

use parent qw(Exporter);

our @EXPORT_OK = qw( slurp slurp_json dump_json normalize_options dmp);

our $VERSION = '1.0.7';

########################################################################
sub dmp {
########################################################################
  my (@args) = @_;

  return Dumper( \@args );
}

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

  open my $fh, '<:raw', $file
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

  return JSON->new->pretty->encode($obj);
}

########################################################################
sub args {
########################################################################
  my ( $args, @valid_keys ) = @_;

  croak 'args(): first argument must be a hashref'
    if ref($args) ne 'HASH';

  my %ok  = map  { $_ => 1 } @valid_keys;
  my @bad = grep { !$ok{$_} } keys %{$args};

  croak sprintf 'bad argument(s): %s', join ', ', @bad
    if @bad;

  # return in the caller-specified order
  return @{$args}{@valid_keys};
}

1;
