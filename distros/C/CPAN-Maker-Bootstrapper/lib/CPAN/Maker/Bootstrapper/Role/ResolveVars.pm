package CPAN::Maker::Bootstrapper::Role::ResolveVars;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(choose slurp);

use English qw(-no_match_vars);
use Data::Dumper;
use Role::Tiny;

use Readonly;
Readonly::Scalar our $PLACEHOLDER => qr/[@]([A-Z0-9_]+)[@]/xsm;

########################################################################
sub cmd_resolve_vars {
########################################################################
  my ($self) = @_;

  my ($source) = $self->get_args;

  die "ERROR: usage: cmb resolve-var [--vars-file var-file] source-file\n"
    if !$source;

  die "ERROR: $source not found or not readable\n"
    if !-f $source || !-r $source;

  my $vars_file = $self->get_vars_file;

  die "ERROR: %s is not found or unreadable!\n"
    if $vars_file && ( !-f $vars_file || !-r $vars_file );

  $vars_file //= "$source.vars";

  if ( -f $vars_file && -r $vars_file ) {

    foreach my $kv ( split /\n/xsm, slurp($vars_file) ) {
      next if !$kv || $kv =~ /^[#]/xsm;
      my ( $k, $v ) = split /[=]/xsm, $kv, 2;
      $ENV{$k} = $v;
    }
  }

  my $resolved_text = $self->_resolve_vars( slurp($source) );

  print {*STDOUT} $resolved_text;

  return $SUCCESS;
}

########################################################################
sub _resolve_vars {
########################################################################
  my ( $self, $text ) = @_;

  # default strict unless explicitly disabled with --no-strict
  my $strict = $self->get_strict;
  $strict //= $TRUE;

  # Scrub a COPY for the missing-value check only. Placeholders that
  # appear solely in POD or comments are references, not substitutions,
  # so they must not count toward "no value present". Substitution
  # below still runs against the original, untouched $text.
  ( my $code = $text ) =~ s/^=\w+.*?^=cut[^\n]*$//gxsm;  # strip POD blocks
  $code =~ s/[#][^\n]*//gxsm;  # strip comments

  my %in_code = map { $_ => 1 } $code =~ /$PLACEHOLDER/gxsm;

  my @missing = sort grep { !( defined $ENV{$_} && length $ENV{$_} ) }
    keys %in_code;

  if (@missing) {
    my $msg = sprintf "no value present for:\n\t%s\n", join "\n\t", @missing;

    die "ERROR: $msg"
      if $strict;

    warn "WARNING: $msg";
  }

  # Substitute wherever a value exists; anything without a value --
  # including POD/comment references and (in --no-strict) missing code
  # vars -- is left literal rather than blanked out.
  $text =~ s/$PLACEHOLDER/ ( defined $ENV{$1} && length $ENV{$1} ) ? $ENV{$1} : "\@$1\@" /gxsme;

  return $text;
}

1;
