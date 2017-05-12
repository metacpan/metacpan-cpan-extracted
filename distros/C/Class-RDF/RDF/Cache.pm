package Class::RDF::Cache;

use 5.6.1;
use base qw(Class::RDF);
use Cache::Memcached;
use strict;

use constant Statement  => "Class::RDF::Cache::Statement";
use constant Object     => "Class::RDF::Cache::Object";
use constant Node       => "Class::RDF::Cache::Node";

our $MemCache;

sub cache {
    return $MemCache;
}

sub set_cache {
    my $class = shift;
    my $args  = ref($_[0]) ? shift : {@_};
    $MemCache = Cache::Memcached->new($args);
    return $MemCache;
}

sub fill_cache {
    my $class = shift;
    Class::RDF::Cache::Object->search;
}

package Class::RDF::Cache::Node;

use base 'Class::RDF::Node';

=pod

sub cache {
    my ($class, $value, $node) = @_;
    if ($node) {
	Class::RDF::Cache->cache->add( "_node:$value", $node );
        return $node;
    } else {
        return Class::RDF::Cache->cache->get( "_node:$value" );
    }
}

=cut

package Class::RDF::Cache::Statement;

use base 'Class::RDF::Statement';
use constant Node   => "Class::RDF::Cache::Node";
use constant Object => "Class::RDF::Cache::Object";

__PACKAGE__->has_a( subject   => Node );
__PACKAGE__->has_a( predicate => Node );
__PACKAGE__->has_a( object    => Node );
__PACKAGE__->has_a( context   => Node );


package Class::RDF::Cache::Object;

use base 'Class::RDF::Object';
use constant Node      => "Class::RDF::Cache::Node";
use constant Statement => "Class::RDF::Cache::Statement";
use vars '*memcache';
use strict;

*memcache = \&Class::RDF::Cache::cache;

sub new {
    my $class = shift;
    my ($uri, $self);
    
    $uri = $_[0] unless ref $_[0] eq 'HASH';
    $uri = $uri->value if ref $uri;
    if ($uri) {
	$self = $class->memcache->get($uri);
	$self->{cached}++ if $self;
	warn(($self ? "HIT" : "MISS"), " $uri\n");
    }

    unless ($self) {
	$self = $class->SUPER::new(@_);
	bless $self, $class;
	$self->_cache_set unless $self->{stub};
    }

    return $self;
}

sub _cache_set {
    my $self = shift;
    my $uri = $self->uri->value;
    warn "_cache_set( $self, $uri, @_ )\n";
    my $ok = $self->memcache->set($uri, $self);
    warn __PACKAGE__, "->_cache_set failed on $uri" unless $ok;
    $self->_expire_search(@_) if @_;
    return $self;
}

sub _fetch_statements {
    my $self = shift;
    $self->SUPER::_fetch_statements;
    $self->_cache_set(@_);
}

sub set {
    my $self = shift;
    $self->SUPER::set(@_);
    $self->_cache_set(@_);
}

sub add {
    my $self = shift;
    $self->SUPER::add(@_);
    $self->_cache_set(@_);
}

sub remove {
    my $self = shift;
    $self->SUPER::remove(@_);
    $self->_cache_set(@_);
}

sub _search_key {
    my ($class, $predicate, $object) = @_;
    my $key = "_search:$predicate";
    $key .= ":$object" if $object;
    return $key;
}

sub _expire_search {
    my $class = shift;
    my $key = $class->_search_key(@_);
    $class->memcache->delete( $key );
}

sub search {
    my $self = shift;
    my $key = $self->_search_key(@_);   
    my $results = $self->memcache->get($key);
    if ($results) {
	$_->{cached}++ for @$results;
	warn "HIT $key\n";
    } else {
	warn "MISS $key\n";
	$results = [ $self->SUPER::search(@_) ];
	$self->memcache->set($key, $results)
	    or warn __PACKAGE__, " couldn't set $key";
	warn "ok not missing $key anymore";
    }
    return (wantarray ? $results->[0] : @$results);
}

1;
