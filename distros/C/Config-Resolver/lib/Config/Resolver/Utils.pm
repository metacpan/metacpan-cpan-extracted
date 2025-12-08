package Config::Resolver::Utils;

use strict;
use warnings;

use English qw(-no_match_vars);
use Scalar::Util qw(reftype);
use Carp 'croak';

our @EXPORT_OK = qw(to_boolean is_hash is_array slurp_file);

our $VERSION = '1.0.10';

use parent qw(Exporter);

########################################################################
sub slurp_file {
########################################################################
  my ($file) = @_;

  local $RS = undef;

  open my $fh, '<', $file
    or croak "ERROR: could not open $file for reading\n$OS_ERROR";

  my $content = <$fh>;

  close $fh;

  return $content;
}

########################################################################
sub choose(&) { return $_[0]->(); }  ## no critic
########################################################################
sub _is { return ref $_[0] && ( reftype( $_[0] ) eq $_[1] || ref $_[0] eq $_[1] ); }
########################################################################
sub is_hash { return _is( @_, 'HASH' ); }
########################################################################
sub is_array { return _is( @_, 'ARRAY' ); }
########################################################################

########################################################################
sub to_boolean {
########################################################################
  my ($val) = @_;

  # undefined may trigger defaults, so return
  return
    if !defined $val;

  $val =~ s/^\s+|\s+$//xsmg;

  $val = lc $val;

  my %booleans = (
    true  => 1,
    false => 0,
    yes   => 1,
    no    => 0,
    on    => 1,
    off   => 0,
    '0'   => 0,
    '1'   => 1,
  );

  croak "ERROR: unknown boolean: $val: valid values [yes,no,true,false,off,on,0,1]\n"
    if !exists $booleans{$val};

  return $booleans{$val};
}

1;

__END__

=pod

=head1 NAME

Config::Resolver::Utils - Shared utilities for Config::Resolver and plugins

=head1 SYNOPSIS

 # In your Config::Resolver::Plugin::MyPlugin.pm
 package Config::Resolver::Plugin::MyPlugin;
 
 use Config::Resolver::Utils qw(to_boolean is_hash);

 if ( is_hash($foo) ) { ... }

 my $bool = to_boolean('yes'); # returns 1

=head1 DESCRIPTION

This module provides a shared, public set of utility functions for use
by C<Config::Resolver> and any module in the
C<Config::Resolver::Plugin::*> namespace.

This ensures that all plugins can share a consistent, robust
method for type-checking and boolean coercion.

=head1 EXPORTABLE SUBROUTINES

None of these are exported by default. You must request them.

=head2 to_boolean( $scalar )

Safely coerces a string into a Perl boolean (1 or 0). [cite: 214, 215]
Returns C<undef> if the input is C<undef>. [cite: 214]

Valid truthy strings: C<true>, C<yes>, C<on>, C<1>
Valid falsy strings: C<false>, C<no>, C<off>, C<0>

Will C<croak> if a defined value is not one of the known strings. [cite: 215]

=head2 is_hash( $scalar )

Returns true if the scalar is a HASH reference. [cite: 212]

=head2 is_array( $scalar )

Returns true if the scalar is an ARRAY reference. [cite: 212]

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=cut
