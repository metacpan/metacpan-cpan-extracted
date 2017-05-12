use 5.006;
use strict;
use warnings;

package CPAN::Distribution::ReleaseHistory::ReleaseIterator;

our $VERSION = '0.002005';

# ABSTRACT: A container to iterate a collection of releases for a single distribution

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has );
use CPAN::DistnameInfo;
use CPAN::Distribution::ReleaseHistory::Release;







has 'scroller' => ( is => 'ro', required => 1 );









sub next_release {
  my ($self) = @_;
  my $scroll_result = $self->scroller->next;
  return if not $scroll_result;

  my $data_hash = $scroll_result->{'_source'} || $scroll_result->{'fields'};
  return if not $data_hash;

  my $path = $data_hash->{download_url};
  $path =~ s{\A.*/authors/id/}{}msx;
  my $distinfo = CPAN::DistnameInfo->new($path);
  my $distname =
    defined($distinfo) && defined( $distinfo->dist )
    ? $distinfo->dist
    : $data_hash->{name};
  return CPAN::Distribution::ReleaseHistory::Release->new(
    distname  => $distname,
    path      => $path,
    timestamp => $data_hash->{stat}->{mtime},
    size      => $data_hash->{stat}->{size},
  );
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Distribution::ReleaseHistory::ReleaseIterator - A container to iterate a collection of releases for a single distribution

=head1 VERSION

version 0.002005

=head1 METHODS

=head2 C<next_release>

Returns a L<< C<CPAN::Distribution::ReleaseHistory::Release>|CPAN::Distribution::ReleaseHistory::Release >>

  my $item = $release_iterator->next_release();

=head1 ATTRIBUTES

=head2 C<scroller>

A C<Search::Elasticsearch::Scroll>  instance that dispatches results.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
