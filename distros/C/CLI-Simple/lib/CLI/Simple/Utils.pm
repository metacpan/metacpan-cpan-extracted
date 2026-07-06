package CLI::Simple::Utils;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use JSON qw(decode_json);
use List::Util qw(none);

use parent qw(Exporter);

our @EXPORT_OK = qw(
  choose
  dmp
  dump_json
  normalize_options
  slurp
  slurp_json
  toPascalCase
  toCamelCase
  to_snake_case
);

our $VERSION = '2.0.10';

sub toPascalCase { goto &_toCamelCase; }
sub ToCamelCase  { goto &_toCamelCase; }
sub toCamelCase  { return _toCamelCase( $_[0], $_[1], 1 ); }
########################################################################
sub _toCamelCase {
########################################################################
  my ( $snake_case, $want_hash, $lc_first ) = @_;

  $snake_case = ref $snake_case ? $snake_case : [$snake_case];

  $want_hash //= wantarray ? 0 : 1;

  my @CamelCase = map {
    ( $want_hash ? $_ : (), join q{}, map {ucfirst} split /[_-]/xsm )
  } @{$snake_case};

  return $want_hash ? {@CamelCase} : @CamelCase
    if !$lc_first;

  return map {lcfirst} @CamelCase
    if !$want_hash;

  my %camelCase = @CamelCase;

  %camelCase = map { $_ => lcfirst $camelCase{$_} } keys %camelCase;

  return \%camelCase;
}

########################################################################
sub to_snake_case {
########################################################################
  my ($str) = @_;

  return q{}
    if !defined $str;

  # 1. Handle acronym boundaries (e.g., HTMLParser -> HTML_Parser)
  #    We look for a sequence of UpperCase followed by (UpperCase + LowerCase)
  $str =~ s/([[:upper:]]+)([[:upper:]][[:lower:]])/$1_$2/xsmg;

  # 2. Handle normal Camel/Pascal boundaries (e.g., UserID -> User_ID)
  #    We look for (LowerCase/Digit) followed by (UpperCase)
  $str =~ s/([[:lower:]\d])([[:upper:]])/$1_$2/xsmg;

  # 3. Lowercase everything
  return lc $str;
}

########################################################################
sub choose(&) { ## no critic
########################################################################
  my @result = shift->();

  return wantarray ? @result : $result[0];
}

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

=head1 NAME

 CLI::Simple::Utils - Useful utility functions for CLI::Simple-based applications

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

=head1 LICENSE AND COPYRIGHT

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See
L<https://dev.perl.org/licenses/> for more information.

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=head1 SEE ALSO

L<CLI::Simple>

=cut
