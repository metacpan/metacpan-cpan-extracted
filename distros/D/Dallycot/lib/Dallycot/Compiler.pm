package Dallycot::Compiler;
our $AUTHORITY = 'cpan:JSMITH';

use Moose;

use RDF::Trine;
use RDF::Query;
use Data::UUID;
use Carp qw(croak);
use Storable qw(dclone);
use Dallycot::Model;
use Dallycot::Registry;
use Dallycot::Resolver;

has root => (
  is => 'rw'
);

has model => (
  isa => 'Dallycot::Model',
  is => 'ro',
  default => sub {
    Dallycot::Model -> new
  },
  handles => [qw/
    as_turtle
    as_ntriples
    as_tsv
    as_xml
    as_dot
  /]
);

has _prefixes => (
  isa => 'RDF::Trine::NamespaceMap',
  is => 'ro',
  default => sub {
    RDF::Trine::NamespaceMap->new({
      'loc' => 'http://www.dallycot.net/ns/loc/1.0#',
      'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
      'xsd' => 'http://www.w3.org/2001/XMLSchema#',
    })
  }
);

has prefixes => (
  isa => 'RDF::Trine::NamespaceMap',
  is => 'ro',
  default => sub {
    RDF::Trine::NamespaceMap->new
  },
  lazy => 1,
  predicate => 'has_prefixes'
);

has parent => (
  isa => __PACKAGE__,
  is => 'ro',
  predicate => 'has_parent',
  required => 0
);

has symbols => (
  isa => 'HashRef',
  is => 'ro',
  default => sub { +{} }
);

has namespace_search_path => (
  isa => 'ArrayRef',
  is => 'ro',
  default => sub { [] }
);

sub child_model {
  my($self, %info) = @_;

  return $self -> new(
    parent => $self,
    _prefixes => $self -> _prefixes,
    model => $self -> model,
    prefixes => dclone($self -> prefixes),
    namespace_search_path => [ @{$self -> namespace_search_path} ],
    %info
  );
}

sub add_search_path {
  my($self, @paths) = @_;

  my $cv = AnyEvent -> condvar;

  Dallycot::Registry->instance->register_used_namespaces(@paths)->done(sub {
    push @{$self -> namespace_search_path}, @paths;
    $cv -> send();
  }, sub {
    $cv -> croak(@_);
  });
  $cv -> recv;
}

sub add_symbol {
  my($self, $symbol, $uri) = @_;

  if($self->symbols->{$symbol}) {
    croak "$symbol may only be defined once in a scope\n";
  }

  $self -> symbols -> {$symbol} = $uri;
}

sub fetch_symbol {
  my($self, $symbol) = @_;

  return unless defined $symbol;
  if($self->symbols->{$symbol}) {
    return $self->symbols->{$symbol};
  }

  if($self -> has_parent) {
    my $val = $self->parent->fetch_symbol($symbol);
    return $val if $val;
  }

  # now look through search path
  my $registry = Dallycot::Registry->instance;
  if($registry->has_assignment( $self -> namespace_search_path, $symbol )) {
    my $uri = $registry->get_assignment_uri( $self -> namespace_search_path, $symbol);
    return RDF::Trine::Node::Resource->new($uri) if $uri;
  }
}

sub add_namespace_mapping {
  my($self, $ns, $href) = @_;

  $self -> prefixes -> add_mapping($ns, $href);
}

sub compile {
  my($self, @exprs) = @_;

  my $expr;

  if(@exprs > 1) {
    $expr = Dallycot::AST::Sequence->new(@exprs);
  }
  else {
    $expr = $exprs[0];
  }

  my $root = $expr->to_rdf($self);
  $self->root($root);
  return $root;
}


sub uri {
  my($self, $prefixed) = @_;

  if($self -> has_prefixes) {
    my $uri = $self -> prefixes -> uri($prefixed);
    return $uri if defined $uri;
  }

  if($self -> has_parent) {
    return $self -> parent -> uri($prefixed);
  }

  return $prefixed;
}

sub meta_uri {
  my($self, $prefixed) = @_;

  return $self -> _prefixes -> uri($prefixed);
}

sub add_type {
  my($self, $node, $type) = @_;

  $self -> model -> add_statement(
    RDF::Trine::Statement -> new(
      $node,
      $self -> _prefixes -> rdf->type,
      $self -> _prefixes -> uri($type)
    )
  );
}

sub add_expression {
  my($self, $node, $expr) = @_;

  return unless defined $expr;

  $expr = $expr -> to_rdf($self) unless $expr -> isa('RDF::Trine::Node');

  $self -> model -> add_statement(
    RDF::Trine::Statement -> new(
      $node,
      $self -> _prefixes -> uri('loc:expression'),
      $expr
    )
  );
}

sub add_connection {
  my($self, $node, $prop, $object) = @_;

  return unless defined $object;

  if($node -> is_literal) {
    # mint a node that points to the literal
    my $bnode = $self -> bnode;
    $self -> add_connection($bnode, 'rdf:value', $node);
    $node = $bnode;
  }

  $self->model -> add_statement(
    RDF::Trine::Statement->new(
      $node,
      $self -> _prefixes -> uri($prop),
      $object
    )
  );

  return $node;
}

sub add_label {
  my($self, $node, $label) = @_;

  return unless defined $label;

  $self->model -> add_statement(
    RDF::Trine::Statement -> new(
      $node,
      $self -> _prefixes -> uri('rdfs:label'),
      RDF::Trine::Node::Literal->new($label, '')
    )
  );
}

sub add_option {
  my($self, $node, $label, $expr) = @_;

  return unless defined $label && defined $expr;

  my $opt_bnode = $self -> bnode;
  $self->model->add_statement(
    RDF::Trine::Statement -> new(
      $node,
      $self->_prefixes->uri('loc:option'),
      $opt_bnode
    )
  );
  $self -> add_type($opt_bnode, 'loc:Option');
  $self -> add_label($opt_bnode, $label);
  $self -> add_expression($opt_bnode, $expr);
}

sub add_list {
  my($self, $node, $prop, @items) = @_;
  my $list_node = $self -> model -> add_list(@items);
  $self -> model -> add_statement(
    RDF::Trine::Statement->new(
      $node,
      $self -> _prefixes -> uri($prop),
      $list_node
    )
  );
}

sub add_first {
  my($self, $node, $expr) = @_;

  return unless defined $expr;

  $self -> model -> add_statement(
    RDF::Trine::Statement -> new(
      $node,
      $self -> _prefixes -> uri('loc:first'),
      $expr -> to_rdf($self)
    )
  );
}

sub add_last {
  my($self, $node, $expr) = @_;

  return unless defined $expr;

  $self -> model -> add_statement(
    RDF::Trine::Statement -> new(
      $node,
      $self -> _prefixes -> uri('loc:last'),
      $expr -> to_rdf($self)
    )
  );
}

sub apply {
  my($self, $expression, $bindings, $options) = @_;

  my $bnode = $self->bnode();

  $self -> add_type($bnode, 'loc:Application');

  # $self -> add_expression($bnode, $expression);
  $expression = $expression -> to_rdf($self) unless $expression -> isa('RDF::Trine::Node');
  $self -> model -> add_statement(
    RDF::Trine::Statement->new(
      $bnode,
      $self -> _prefixes -> uri('loc:algorithm'),
      $expression
    )
  );

  $self -> add_list($bnode, 'loc:target',
    map { $_ -> isa('RDF::Trine::Node') ? $_ : $_ -> to_rdf($self) } @$bindings
  ) if $bindings && @$bindings;

  foreach my $opt (keys %{$options||{}}) {
    $self -> add_option($bnode, $opt, $options->{$opt});
  }

  return $bnode;
}

sub integer {
  my($self, $int) = @_;

  return RDF::Trine::Node::Literal->new($int, '', $self->_prefixes->uri('xsd:integer'));
}

sub string {
  my($self, $value, $lang) = @_;

  if($lang) {
    return RDF::Trine::Node::Literal->new($value, $lang);
  }
  else {
    return RDF::Trine::Node::Literal->new($value, '', $self->_prefixes->uri('xsd:string'));
  }
}

sub list {
  my($self, @items) = @_;

  my $bnode = $self -> model -> add_list(@items);

  return $bnode;
}

sub list_with_promise {
  my($self, @items) = @_;

  my $promise = pop @items;

  my $node = $self -> model -> add_list(@items);

  # now to traverse the list to the end and replace the tail with the promise
  my $root = $node;
  my @next;

  while(@next = $self -> model -> objects($root, $self -> meta_uri('rdf:rest'), undef, type => 'node')) {
    last if $next[0] eq $self -> meta_uri('rdf:nil');
    $root = $next[0];
  }
  return $node;
}

my $uuid_generator = Data::UUID -> new;

sub bnode {
  my($self) = @_;

  return RDF::Trine::Node::Blank -> new($uuid_generator->to_string($uuid_generator->create));
}

__PACKAGE__ -> meta -> make_immutable;

1;
