package Catmandu::Store::FedoraCommons;

use Catmandu::Sane;
use Catmandu::FedoraCommons;
use Moo;

with 'Catmandu::Store';

has baseurl  => (is => 'ro' , required => 1);
has username => (is => 'ro' , default => sub { '' } );
has password => (is => 'ro' , default => sub { '' } );
has model    => (is => 'ro' , default => sub { 'Catmandu::Store::FedoraCommons::DC' } );

has fedora => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_fedora',
);
has _repository_description => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_repository_description'
);
has _default_namespace => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_default_namespace'
);
has _pid_delimiter => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_pid_delimiter'
);

sub _build_fedora {
    my $self = $_[0];

    Catmandu::FedoraCommons->new($self->baseurl, $self->username, $self->password);
}
#namespace corresponds to name of bag
#don't use "data", but use the internal default namespace of fedora
around default_bag => sub {
    my($orig,$self) = @_;
    $self->_default_namespace();
};

sub _build_repository_description {
    $_[0]->fedora->describeRepository()->parse_content();
}
sub _build_default_namespace {
    my $self = $_[0];
    my $desc = $self->_repository_description();
    $desc->{repositoryPID}->{'PID-namespaceIdentifier'};
}
sub _build_pid_delimiter {
    my $self = $_[0];
    my $desc = $self->_repository_description();
    $desc->{repositoryPID}->{'PID-delimiter'};
}

package Catmandu::Store::FedoraCommons::Bag;

use Catmandu::Sane;
use Catmandu::Store::FedoraCommons::FOXML;
use Moo;
use Catmandu::Util qw(:is);


has _namespace_prefix => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_namespace_prefix'
);
has _namespace_prefix_re => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    builder => '_build_namespace_prefix_re'
);
sub _build_namespace_prefix {
    my $self = $_[0];
    my $name = $self->name();
    my $pid_delimiter = $self->store->_pid_delimiter();
    "${name}${pid_delimiter}";
}
sub _build_namespace_prefix_re {
    my $self = $_[0];
    my $p = $self->_namespace_prefix();
    qr/$p/;
}
sub _id_valid {
    my ($self,$id) = @_;
    return ( index( $id, $self->_namespace_prefix() ) == 0 ) ? 1 : 0;
}

#add namespace to generated ID if it does not start with the namespace prefix
before add => sub {
    my ($self, $data) = @_;
    unless( $self->_id_valid( $data->{_id} ) ) {
        $data->{_id} = $self->_namespace_prefix().$data->{_id};
    }
};
#make it impossible to find 'islandora:1' in bag 'archive.ugent.be'
around 'get' => sub {
    my($orig,$self,$id) = @_;

    return undef unless $self->_id_valid( $id );

    $orig->($self,$id);
};
#make it impossible to delete 'islandora:1' when using bag 'archive.ugent.be'
around 'delete' => sub {
    my($orig,$self,$id) = @_;

    return undef unless $self->_id_valid( $id );

    $orig->($self,$id);
};

sub _get_model {
    my ($self, $obj) = @_;
    my $pid    = $obj->{pid};
    my $fedora = $self->store->fedora;
    my $model  = $self->store->model;
    
    eval "use $model";
    my $x   = $model->new(fedora => $fedora);
    my $res = $x->get($pid);
    
    return $res;
}

sub _update_model {
    my ($self, $obj) = @_;
    my $fedora = $self->store->fedora;
    my $model  = $self->store->model;

    eval "use $model";
    my $x   = $model->new(fedora => $fedora);
    my $res = $x->update($obj);

    return $res;
}

sub _ingest_model {
    my ($self, $data) = @_;
    
    my $serializer = Catmandu::Store::FedoraCommons::FOXML->new;
    
    my ($valid,$reason) = $serializer->valid($data);
    
    unless ($valid) {
        warn "data is not valid";
        return undef;
    }
    
    my $xml = $serializer->serialize($data);
 
    my %args = (
        pid => $data->{_id} ,
        xml => $xml ,
        format => 'info:fedora/fedora-system:FOXML-1.1'
    );
    
    my $result = $self->store->fedora->ingest(%args);
    
    return undef unless $result->is_ok;
    
    $data->{_id} = $result->parse_content->{pid};
    
    return $self->_update_model($data);
}

sub generator {
    my ($self) = @_;
    my $fedora = $self->store->fedora;
    
    sub {
        state $hits;
        state $row;
        state $ns_prefix = $self->_namespace_prefix;
        
        if( ! defined $hits) {
            my $res = $fedora->findObjects( query => "pid~${ns_prefix}*" );
            unless ($res->is_ok) {
                warn $res->error;
                return undef;
            }
            $row  = 0;
            $hits = $res->parse_content;
        }
        if ($row + 1 == @{ $hits->{results} } && defined $hits->{token}) {
            my $result = $hits->{results}->[ $row ];
            
            my $res = $fedora->findObjects(sessionToken => $hits->{token});
            
            unless ($res->is_ok) {
                warn $res->error;
                return undef;
            }
            
            $row  = 0;
            $hits = $res->parse_content;
            
            return $self->_get_model($result);
        }  
        else {
            my $result = $hits->{results}->[ $row++ ];
            return $self->_get_model($result);
        }
    };
}

sub add {
    my ($self,$data) = @_;    
    
    if ( defined $self->get($data->{_id}) ) {
        my $ok = $self->_update_model($data);

        die "failed to update" unless $ok;
    }
    else {
        my $ok = $self->_ingest_model($data);
        
        die "failed to ingest" unless $ok;
    }
         
    return $data;
}

sub get {
    my ($self, $id) = @_;
    return $self->_get_model({ pid => $id });
}

sub delete {
    my ($self, $id) = @_;
    
    return undef unless defined $id;
    
    my $fedora = $self->store->fedora;
    
    $fedora->purgeObject(pid => $id)->is_ok;
}

sub delete_all {
    my ($self) = @_;
    
    my $count = 0;
    $self->each(sub {
        my $obj = $_[0];
        my $pid = $obj->{_id};
        
        my $ret = $self->delete($pid);
        
        $count += 1 if $ret;
    });
    
    $count;
}

with 'Catmandu::Bag';

1;

=head1 NAME

Catmandu::Store::FedoraCommons - A Catmandu::Store plugin for the Fedora Commons repository

=head1 SYNOPSIS

 use Catmandu::Store::FedoraCommons;

 my $store = Catmandu::Store::FedoraCommons->new(
         baseurl  => 'http://localhost:8080/fedora',
         username => 'fedoraAdmin',
         password => 'fedoraAdmin',
         model    => 'Catmandu::Store::FedoraCommons::DC' # default
 );

 # We use the DC model, lets store some DC
 my $obj1 = $store->bag->add({ 
                    title => ['The Master and Margarita'] , 
                    creator => ['Bulgakov, Mikhail'] }
            );

 printf "obj1 stored as %s\n" , $obj1->{_id};

 # Force an id in the store
 my $obj2 = $store->bag->add({ _id => 'demo:120812' , title => ['The Master and Margarita']  });

 my $obj3 = $store->bag->get('demo:120812');

 $store->bag->delete('demo:120812');

 $store->bag->delete_all;

 # All bags are iterators
 $store->bag->each(sub {  
     my $obj = $_[0];
     my $pid = $obj->{_id};
     my $ds  = $store->fedora->listDatastreams(pid => $pid)->parse_content;
 });
 
 $store->bag->take(10)->each(sub { ... });
 
=head1 DESCRIPTION

A Catmandu::Store::FedoraCommons is a Perl package that can store data into
FedoraCommons backed databases. The database as a whole is called a 'store'.
Databases also have compartments (e.g. tables) called Catmandu::Bag-s.
In Fedora we have namespaces. A bag corresponds to a namespace.
The default bag corresponds to the default namespace in Fedora.

By default Catmandu::Store::FedoraCommons works with a Dublin Core data model.
You can use the add,get and delete methods of the store to retrieve and insert Perl HASH-es that
mimic Dublin Core records. Optionally other models can be provided by creating
a model package that implements a 'get' and 'update' method.

=head1 METHODS

=head2 new(baseurl => $fedora_baseurl , username => $username , password => $password , model => $model )

Create a new Catmandu::Store::FedoraCommons store at $fedora_baseurl. Optionally provide a name of
a $model to serialize your Perl hashes into a Fedora Commons model.

=head2 bag('$namespace')

Create or retrieve a bag. Returns a Catmandu::Bag.
Use this for storing or retrieving records from a
fedora namespace.

=head2 fedora

Returns a low level Catmandu::FedoraCommons reference.

=head1 SEE ALSO

L<Catmandu::Bag>, L<Catmandu::Searchable>, L<Catmandu::FedoraCommons>

=head1 AUTHOR

=over

=item * Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=back

=cut
