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

  my $file_list = $self->get_file_list;

  die "ERROR: usage: cmb resolve-vars [--vars-file var-file] [--file-list file-list | source-file]\n"
    if !$source && !$file_list;

  die "ERROR: source-file and --file-list are mutually exclusive\n"
    if $source && $file_list;

  if ($file_list) {
    die "ERROR: $file_list not found or not readable\n"
      if !-f $file_list || !-r $file_list;

    foreach my $file ( split /\n/xsm, slurp($file_list) ) {
      next if !$file || $file =~ /^[#]/xsm;

      die "ERROR: $file not found or not readable\n"
        if !-f $file || !-r $file;

      my $output = $file;
      $output =~ s/[.]in\z/.rendered/xsm;

      die "ERROR: cannot determine rendered output for $file\n"
        if $output eq $file;

      open my $fh, '>', $output
        or die "ERROR: cannot write $output: $ERRNO\n";

      print {$fh} $self->_resolve_source($file);

      close $fh
        or die "ERROR: cannot close $output: $ERRNO\n";
    }

    return $SUCCESS;
  }

  die "ERROR: $source not found or not readable\n"
    if !-f $source || !-r $source;

  print {*STDOUT} $self->_resolve_source($source);

  return $SUCCESS;
}

########################################################################
sub _resolve_source {
########################################################################
  my ( $self, $source ) = @_;

  local %ENV = %ENV;

  my $vars_file = $self->get_vars_file;

  die "ERROR: $vars_file is not found or unreadable!\n"
    if $vars_file && ( !-f $vars_file || !-r $vars_file );

  $vars_file //= "$source.vars";

  if ( -f $vars_file && -r $vars_file ) {

    foreach my $kv ( split /\n/xsm, slurp($vars_file) ) {
      next if !$kv || $kv =~ /^[#]/xsm;
      my ( $k, $v ) = split /[=]/xsm, $kv, 2;
      $ENV{$k} = $v;
    }
  }

  return $self->_resolve_vars( slurp($source) );
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
