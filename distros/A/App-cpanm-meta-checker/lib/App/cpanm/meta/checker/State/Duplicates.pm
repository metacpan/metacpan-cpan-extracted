use 5.006;    # our
use strict;
use warnings;

package App::cpanm::meta::checker::State::Duplicates;

our $VERSION = '0.001002';

# ABSTRACT: Data tracking for duplicate distribution meta-data

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has );
use App::cpanm::meta::checker::State::Duplicates::Dist;





has 'dists' => (
  is      => ro  =>,
  lazy    => 1,
  builder => sub { {} },
);







sub seen_dist_version {
  my ( $self, $dist, $version ) = @_;
  if ( not exists $self->dists->{$dist} ) {
    $self->dists->{$dist} = App::cpanm::meta::checker::State::Duplicates::Dist->new();
  }
  return $self->dists->{$dist}->seen_version($version);
}









sub has_duplicates {
  my ( $self, $dist ) = @_;
  return unless exists $self->dists->{$dist};
  return $self->dists->{$dist}->has_duplicates;
}










sub reported_duplicates {
  my ( $self, $dist, $set_reported ) = @_;
  return unless exists $self->dists->{$dist};
  return $self->dists->{$dist}->reported($set_reported) if @_ > 2;
  return $self->dists->{$dist}->reported();
}









sub duplicate_versions {
  my ( $self, $dist ) = @_;
  return unless exists $self->dists->{$dist};
  return $self->dists->{$dist}->duplicate_versions;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cpanm::meta::checker::State::Duplicates - Data tracking for duplicate distribution meta-data

=head1 VERSION

version 0.001002

=head1 METHODS

=head2 C<seen_dist_version>

  ->seen_dist_version( 'Dist-Name', '5.000' );

=head2 C<has_duplicates>

  if ( $o->has_duplicates( 'Dist-Name' ) ) {
    ...
  }

=head2 C<reported_duplicates>

  if ( not $o->reported_duplicates('Dist-Name') ) {
    /* report dups  */
    $o->reported_duplicates('Dist-Name', 1);
  }

=head2 C<duplicate_versions>

  for my $v ( $o->duplicate_versions('Dist-Name') ) {

  }

=head1 ATTRIBUTES

=head2 C<dists>

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
