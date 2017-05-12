package Config::Merged;

use strict;
use warnings;

require 5.006;

use base qw( Config::Any );


our $VERSION = '0.05';


sub load_files { _merge( shift->SUPER::load_files( @_ ) ) }

sub load_stems { _merge( shift->SUPER::load_stems( @_ ) ) }

sub _merge {
  my ( $mixed ) = @_;

  my ( $config, @configs );

  if( ref $mixed eq 'ARRAY' ) {
    ( $config, @configs ) = map { (%$_)[1] } @$mixed;
  }
  elsif( ref $mixed eq 'HASH' ) {
    ( $config, @configs ) = values %$mixed;
  }
  else {
    die "Config::Any returned something unexpected.  Please contact the author and report this as a bug\n";
  }

  _merge_hash( $config, $_ )
    for @configs;

  return $config;
}

sub _merge_hash {
  my ( $left, $right ) = @_;

  for my $key ( keys %$right ) {
    if( ref $right->{$key} eq 'HASH' && ref $left->{$key} eq 'HASH' ) {
      _merge_hash( $left->{$key}, $right->{$key} );
    }
    else {
      $left->{$key} = $right->{$key};
    }
  }
}


1
__END__

=pod

=head1 NAME

Config::Merged - Load and merge configuration from different file formats, transparently

=head1 SYNOPSIS

  use Config::Merged;

  my $config = Config::Merged->load_files({ files => \@files, ... });

  # or

  my $config = Config::Merged->load_stems({ stems => \@stems, ... });

=head1 DESCRIPTION

Config::Merged is a subclass of L<Config::Any|Config::Any> that
returns a single, merged configuration structure.  This is simply
a re-implementation of L<Catalyst|Catalyst::Runtime>'s C<merge_hashes()>
wrapped around L<Config::Any|Config::Any>.

=head1 METHODS

=head2 load_files( \%args )

Similar to L<Config::Any|Config::Any>'s C<load_files()> method
except that a single, merged hash is returned.

=head2 load_stems( \%args )

Similar to L<Config::Any|Config::Any>'s C<load_stems()> method
except that a single, merged hash is returned.

=head1 BUGS

When using the C<flatten_to_hash> option (as documented in
L<Config::Any|Config::Any>), the order of the configuration
files cannot be guaranteed which may result in improper
precedence during merging.  It is recommended that this option
never be used when using L<Config::Merged|Config::Merged>.

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 SEE ALSO

=over 4

=item L<Config::Any|Config::Any>

=back

=head1 COPYRIGHT

Copyright (c) 2008-2014, jason hord

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
