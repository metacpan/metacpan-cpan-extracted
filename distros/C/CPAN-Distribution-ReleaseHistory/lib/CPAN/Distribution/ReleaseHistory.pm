use 5.006;
use strict;
use warnings;

package CPAN::Distribution::ReleaseHistory;

our $VERSION = '0.002005';

# ABSTRACT: Show the release history of a single distribution

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo 1.000008 qw( has );














has 'distribution' => (
  is       => 'ro',
  required => 1,
);



































has 'sort' => (
  is      => 'ro',
  lazy    => 1,
  builder => sub { 'desc' },
);














has 'scroll_size' => (
  is      => 'ro',
  lazy    => 1,
  builder => sub { 1000 },
);












sub _iterator_from_scroll {
  my ( undef, $scroll ) = @_;
  require CPAN::Distribution::ReleaseHistory::ReleaseIterator;
  return CPAN::Distribution::ReleaseHistory::ReleaseIterator->new( scroller => $scroll );
}

sub release_iterator {
  my ($self) = @_;
  return $self->_iterator_from_scroll( $self->_mk_query_distribution );
}













has 'ua' => (
  is        => 'ro',
  predicate => 'has_ua',
);







has 'es' => (
  is      => 'ro',
  lazy    => 1,
  builder => sub {
    my ($self) = @_;
    my %args = (
      nodes            => 'api.metacpan.org',
      cxn_pool         => 'Static::NoPing',
      send_get_body_as => 'POST',
    );
    if ( $self->has_ua ) {
      $args{handle} = $self->ua;
    }
    require Search::Elasticsearch;
    return Search::Elasticsearch->new(%args);
  },
);

sub _mk_query {
  my ($self) = @_;
  return { term => { distribution => $self->distribution } };
}

sub _mk_body {
  my ($self) = @_;
  my $body = { query => $self->_mk_query };
  if ( $self->sort ) {
    $body->{sort} = { 'stat.mtime' => $self->sort };
  }
  return $body;
}

sub _mk_fields {
  return [qw(name version date status maturity stat download_url )];
}

sub _es_version {
  my ( $self, $wanted_version ) = @_;
  local $@ = undef;
  return eval { $self->es->VERSION($wanted_version); 1 };    ## no critic (RequireCheckingReturnValueOfEval)
}

sub _mk_scroll_args {
  my ($self) = @_;

  my %scrollargs = (
    scroll => '5m',
    index  => 'v0',
    type   => 'release',
    size   => $self->scroll_size,
    body   => $self->_mk_body,
    ( $self->_es_version(5) ? 'stored_fields' : 'fields' ) => $self->_mk_fields,
  );

  if ( not $self->sort ) {
    $scrollargs{'search_type'} = 'scan';
  }
  return \%scrollargs;
}

sub _mk_query_distribution {
  my ($self) = @_;

  my %scrollargs = %{ $self->_mk_scroll_args };

  ( $self->_es_version(5) )
    ? ( require Search::Elasticsearch::Client::5_0::Scroll )
    : ( require Search::Elasticsearch::Scroll );

  return $self->es->scroll_helper(%scrollargs);
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Distribution::ReleaseHistory - Show the release history of a single distribution

=head1 VERSION

version 0.002005

=head1 SYNOPSIS

This is similar in concept to C<CPAN::ReleaseHistory>, except its tailored to use a single distribution name, and uses
C<MetaCPAN> to resolve its information.

  use CPAN::Distribution::ReleaseHistory;

  my $release_history = CPAN::Distribution::ReleaseHistory->new(
    distribution => 'Dist-Zilla',
    # ua          => a HTTP::Tiny instance to use for requests
    # es          => a Search::Elasticsearch instance
    # scroll_size => 1000  : How many results to fetch per HTTP request
    # sort        => 'desc': Direction of sort ( vs 'asc' and undef )
  );

  # Returns a CPAN::Distribution::ReleaseHistory::ReleaseIterator
  my $iterator = $release_history->release_iterator();

  # $release is an instance of CPAN::Distribution::ReleaseHistory::Release
  while ( my $release = $iterator->next_release() ) {
    print $release->distname();                   # Dist-Zilla
    print $release->path();                       # R/RJ/RJBS/Dist-Zilla-1.000.tar.gz
    print scalar gmtime $release->timestamp();    # Timestamp is Unixtime.
    print $release->size();                       # 30470 ( bytes )
    my $distinfo = $release->distinfo();          # CPAN::DistInfo object
  }

=head1 METHODS

=head2 C<release_iterator>

Perform the query and return a new
L<< C<CPAN::Distribution::ReleaseHistory::ReleaseIterator>|CPAN::Distribution::ReleaseHistory::ReleaseIterator >> to walk over
the results.

  my $iterator = $object->release_iterator

=head2 C<has_ua>

Determine if user specified a custom C<UserAgent>

=head1 ATTRIBUTES

=head2 C<distribution>

A string exactly matching a name of a C<CPAN> distribution.

example:

  Dist-Zilla
  MetaCPAN-Client
  Search-Elasticsearch
  WWW-Mechanize-Cached

=head2 C<sort>

The implicit sort direction of the output.

  default: 'desc' # The most recent release is returned first.

Alternative options:

  'asc' # The oldest release is returned first
  undef # Results are unsorted

=head4 C<undef>

Opting for C<undef> for this value will give a slight speed up to the responsiveness of queries.

Though this benefit will only be observed in conjunction with low values of C<scroll_size>

    5 desc average 0.08625 /each   11.594 items/sec
   5 undef average 0.03856 /each   25.937 items/sec

   10 desc average 0.05384 /each   18.573 items/sec
  10 undef average 0.03773 /each   26.507 items/sec

   20 desc average 0.03856 /each   25.934 items/sec
  20 undef average 0.02758 /each   36.252 items/sec

   50 desc average 0.02579 /each   38.777 items/sec
  50 undef average 0.02547 /each   39.267 items/sec

  100 desc average 0.02279 /each   43.873 items/sec
 100 undef average 0.02510 /each   39.846 items/sec

=head2 C<scroll_size>

Volume of results to fetch per request.

  default: 1000

Larger values give slower responses but faster total execution time.

Smaller values give faster responses but slower total execution time. ( Due to paying ping time both ways per request in
addition to other per-request overheads that are constant sized )

=head2 C<ua>

A C<HTTP::Tiny> compatible user agent.

=head2 C<es>

A Search::Elasticsearch instance.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
