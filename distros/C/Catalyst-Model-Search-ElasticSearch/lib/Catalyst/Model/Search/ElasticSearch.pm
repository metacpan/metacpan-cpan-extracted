package Catalyst::Model::Search::ElasticSearch;
$Catalyst::Model::Search::ElasticSearch::VERSION = '1.142550';
use Moose;
use namespace::autoclean;
use Search::Elasticsearch;
extends 'Catalyst::Model';


# ABSTRACT: A simple Catalyst model to interface with Search::Elasticsearch


has 'nodes' => (
  is      => 'rw',
  lazy    => 1,
  default => "localhost:9200",
);


has 'transport' => (
  is      => 'rw',
  lazy    => 1,
  default => "+Search::Elasticsearch::Transport",
);


has '_additional_opts' => (
  is      => 'rw',
  lazy    => 1,
  isa     => 'HashRef',
  default => sub { {} },
);


has '_es' => (
  is       => 'ro',
  lazy     => 1,
  required => 1,
  builder  => '_build_es',
  handles  => {
    map { $_ => $_ }
      qw(
      search searchqs scrolled_search count index get mget create delete reindex
      bulk bulk_index bulk_create bulk_delete
      )
  },
);

sub _build_es {
  my $self = shift;
  return Search::Elasticsearch->new(
    nodes     => $self->nodes,
    transport => $self->transport,
    %{ $self->_additional_opts },
  );

}

around BUILDARGS => sub {
  my $orig   = shift;
  my $class  = shift;

  my $params = $class->$orig(@_);
  if (defined $params->{servers}) {
    warn("Passing 'servers' is deprecated, use 'nodes' now");
    $params->{nodes} = delete $params->{servers};
  }
  my %additional_opts = %{$params};
  delete $additional_opts{$_} for qw/ nodes transport /;
  $params->{_additional_opts} = \%additional_opts;
  return $params;
};



__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Model::Search::ElasticSearch - A simple Catalyst model to interface with Search::Elasticsearch

=head1 VERSION

version 1.142550

=head1 SYNOPSIS

    package My::App;
    use strict;
    use warnings;

    use Catalyst;

    our $VERSION = '0.01';
    __PACKAGE__->config(
      name            => 'Test::App',
      'Model::Search' => {
        nodes           => 'localhost:9200',
        request_timeout => 30,
        max_requests    => 10_000
      }
    );

    __PACKAGE__->setup;


    package My::App::Model::Search;
    use Moose;
    use namespace::autoclean;
    extends 'Catalyst::Model::Search::ElasticSearch';

    __PACKAGE__->meta->make_immutable;
    1;

    package My::App::Controller::Root;
    use base 'Catalyst::Controller';
    __PACKAGE__->config(namespace => '');

    sub search : Local {
      my ($self, $c) = @_;
      my $params = $c->req->params;
      my $search = $c->model('Search');
      my $results = $search->search(
        index => 'test',
        type  => 'test',
        body  => { query => { term => { schpongle => $params->{'q'} } } }
      );
      $c->stash( results => $results );

    }

=head1 WARNING

This is in very alpha stages.  More testing and production use are coming up, but be warned until then.

=head1 CONFIGURATION PARAMETERS AND ATTRIBUTES

=head2 nodes

A list of nodes to connect to.

=head2 transport

The transport to use to interact with the Elasticsearch API.  See L<Search::Elasticsearch::Transport|Search::Elasticsearch::Transport> for options.

=head2 _additional_opts

Stores other key/value pairs to pass to L<Search::Elasticsearch|Search::Elasticsearch>.

=head2 _es

The L<Search::Elasticsearch|Search::Elasticsearch> object.

=head1 SEE ALSO

=over

=item *

The Catalyst Advent article on integrating Elasticsearch into your app: L<http://www.catalystframework.org/calendar/2010/2>

=item *

L<Search::Elasticsearch|Search::Elasticsearch> - Elasticsearch interface this
model provides access to

=item *

L<http://www.elasticsearch.org/> - Open Source Distributed Real Time Search and Analytics

=back

=head1 AUTHORS

=over 4

=item *

Devin Austin <dhoss@cpan.org>

=item *

Manfred Stock <mstock@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Devin Austin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
