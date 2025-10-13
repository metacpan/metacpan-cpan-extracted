package CLI::Simple::Utils;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use JSON qw(decode_json);
use List::Util qw(none);

use parent qw(Exporter);

our @EXPORT_OK = qw( slurp slurp_json dump_json normalize_options dmp choose);

our $VERSION = '1.0.8';

########################################################################
sub choose (&) { return $_[0]->(); }  ## no critic
########################################################################

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

__END__

=pod

=head1 NAAME

 CLI::Simple::Utils

=head1 SYNOPSIS

 CLI::Simple::Utils qw(choose);

=head1 DESCRIPTION

Utilities that might be useful when writing command line scripts.

=head1 METHODS AND SUBROUTINES

=head2 choose

An anonymous subroutine disguising as a block level internal
subroutine (of sorts). Use when a ternary or a cascading if/else block
just seems wrong.

 choose {
   return "foo"
     if $bar;

   return "bar"
     if $foo;
 };

=head2 dmp

 dmp this => $this, that => $that;

Shortcut for:

 print {*STDERR} Dumper([this => $this, that => $that]);
 
=head2 slurp_json

 slurp_json($file)

Returns a Perl object from a presumably JSON encoded file.

=head2 slurp

 slurp(file)

Return the entire contents of a file.

=head1 AUTHOR

Rob Lauer - <bigfoot@cpan.org>

=head1 SEE ALSO
 
=cut
