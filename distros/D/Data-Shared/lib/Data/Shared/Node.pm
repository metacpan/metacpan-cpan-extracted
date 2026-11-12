package Data::Shared::Node;
use strict;
use warnings;
use Carp ();
use Scalar::Util qw(blessed);

our $VERSION = '0.01';

our @CARP_NOT = qw(Data::Shared);

sub new {
    my ($class, $root, $components) = @_;
    return bless { root => $root, components => [ @{ $components || [] } ] }, $class;
}

sub CLONE_SKIP { 1 }
sub root { return $_[0]{root} }
sub components { return [ @{ $_[0]{components} } ] }
sub path { return '/' . join('/', @{ $_[0]{components} }) }

sub _abs {
    my ($self, $rel) = @_;
    return [ @{ $self->{components} } ]
        if !defined $rel || (!ref $rel && ($rel eq '' || $rel eq '/'));
    Carp::croak('Data::Shared: a Data::Shared::Node is an absolute cursor, not a relative path')
        if blessed($rel) && $rel->isa('Data::Shared::Node');
    # Arrayref components are validated there, as $root->node([...]) is.
    return [ @{ $self->{components} }, @{ Data::Shared::_rel_components($rel) } ];
}

sub node {
    my ($self, $rel) = @_;
    return Data::Shared::Node->new($self->{root}, $self->_abs($rel));
}

# An explicit undef is a path computation that came back empty, not this node; omitted or '' is.
sub _rel {
    my ($self, $verb, $argc, $rel) = @_;
    Carp::croak("Data::Shared: node $verb: undef relative path (pass '' for this node)")
        if $argc > 1 && !defined $rel;
    return $self->_abs($rel);
}

# _abs has validated the components, so these skip shareda_*.
sub get    { my ($s, $rel, @a) = @_; return Data::Shared::_dispatch('get',    $s->{root}, $s->_rel('get', scalar @_, $rel), @a) }
sub set    { my ($s, $rel, @a) = @_; return Data::Shared::_dispatch('set',    $s->{root}, $s->_rel('set', scalar @_, $rel), @a) }
sub delete { my ($s, $rel, @a) = @_; return Data::Shared::_dispatch('delete', $s->{root}, $s->_rel('delete', scalar @_, $rel), @a) }
sub exists { my ($s, $rel, @a) = @_; return Data::Shared::_dispatch('exists', $s->{root}, $s->_rel('exists', scalar @_, $rel), @a) }
sub incr   { my ($s, $rel, @a) = @_; return Data::Shared::_dispatch('incr',   $s->{root}, $s->_rel('incr', scalar @_, $rel), @a) }
sub push   { my ($s, $rel, @a) = @_; return Data::Shared::_dispatch_pushpop('push', $s->{root}, $s->_rel('push', scalar @_, $rel), @a) }
sub pop    { my ($s, $rel, @a) = @_; return Data::Shared::_dispatch_pushpop('pop',  $s->{root}, $s->_rel('pop', scalar @_, $rel), @a) }

sub call {
    my ($self, $method, @args) = @_;
    Carp::croak("Data::Shared: node call requires a method name") unless defined $method && length $method;
    return Data::Shared::_dispatch_call($self->{root}, $self->_abs(''), $method, @args);
}

sub call_at {
    my ($self, $rel, $method, @args) = @_;
    return Data::Shared::_dispatch_call($self->{root},
        $self->_rel('call_at', scalar @_, $rel), $method, @args);
}

sub children {
    my ($self, $rel) = @_;
    return $self->{root}->children($self->_abs($rel));
}

sub handle {
    my ($self, $rel) = @_;
    return $self->{root}->handle($self->_abs($rel));
}

1;

__END__

=head1 NAME

Data::Shared::Node - A cursor into a Data::Shared namespace

=head1 SYNOPSIS

    my $alice = $root->node('/users/alice');
    $alice->call('count');
    $alice->get('/event-42');
    my @kids = $root->node('/users')->children;

=head1 DESCRIPTION

Returned by C<< $root->node($path) >> and by C<shared_get> on an
intermediate composite path. Holds a root plus absolute path
components. A path-taking method appends its relative argument -- a
string, an arrayref or a compiled path, omitted for the node itself --
to those components and dispatches it through L<Data::Shared>; C<call>
takes a method name instead, and C<call_at> a relative path and then a
method name.

=head2 root, components, path

Accessors. C<path> is the display form (ambiguous for components
containing C</>; use C<components> programmatically). C<components>
returns a copy.

=head2 get, set, delete, exists, incr, push, pop

Relative-path forms of the generic verbs: the relative path is always
the first argument, so addressing the node itself means passing C<''>
(C<< $node->push('', $value) >>, C<< $node->set('', $value) >>).

=head2 call($method, @args), call_at($rel, $method, @args)

C<call> invokes a native method at the node itself; C<call_at> at a
relative path below it.

=head2 node($rel), children, handle

C<node> returns a deeper cursor, C<children> lists child addresses
at a composite node, and C<handle> returns the native handle when
the node is exactly a leaf (or a composite child leaf).

=cut
