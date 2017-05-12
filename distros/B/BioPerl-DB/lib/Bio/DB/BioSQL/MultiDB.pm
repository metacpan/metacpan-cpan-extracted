# $Id$
# Adaptor for Multiple BioSQL databases.
# By Juguang Xiao <juguang@tll.org.sg> 

=head1 NAME

Bio::DB::BioSQL::MultiDB

=head1 SYNOPSIS

  use Bio::DB::BioSQL::MultiDB;

  # create the common biosql db adaptors
  my $swissprot_db;  # Physical databases may be located on different servers
  my $embl_db;       # or accessible by different users.

  # register them by bio-database
  my $multiDB = Bio::DB::BioSQL::MultiDB->new(
      'swissprot' => $swissprot_db,
      'embl' => $embl_db
  );

  # Each time before you want to create a persistent object for
  # Bio::Seq, assign the 'namescape' sub of seq object first, as the
  # biodatabase name.
  my $seq;    # for either store or fetch.
  $seq->namespace('swissprot');

  # OR you need to assign the default namespace for multiDB
  $multiDB->namespace('swissport');

  my $pseq = $multiDB->create_persistent($seq);
  $pseq->store;


  # If you want to fetch a seq, then you have to specify namespace for
  # multiDB first
  $multiDB->namespace('swissport');
  $pseq = $multiDB->get_object_adaptor->find_by_unique_key($seq);

=head1 DESCRIPTION

The scalability issue will arise, when multiple huge bio databases are
loaded in a single database in RDBMS, due to the scalability of the
RDBMS. So one solution to solve it is simply to distribute them into
multiple physical database, while a user expects to manage them by one
logic adaptor.

So here you go, MultiDB aims at such issue to solve. The way to apply
that is pretty simple. You, first, load data from different
biodatabase, such as swissprot or embl, into physical RDBMS databases;
then create a db adaptor for each simple physical biosql db; finally
register these adaptors into MultiDB and use it as that was a normal
dbadaptor.

=head1 CONTACT

Juguang Xiao, juguang@tll.org.sg

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _


=cut

package Bio::DB::BioSQL::MultiDB;

use strict;
use vars qw(@ISA);

use Bio::Root::Root;

@ISA = qw(Bio::Root::Root);


=head2 new

=cut 

sub new{
    my ($class, @args) = @_;
    my %dbs = @args;
    my $self = $class->SUPER::new(@args); 

    foreach (keys %dbs){
        $self->_namespace_dbs($_, $dbs{$_});
    }
    return $self;
}

sub _namespace_dbs{
    my ($self, $key, $value) = @_;
    $self->{_namespace_dbs} = {} unless $self->{_namespace_dbs};
    if (exists $self->{_namespace_dbs}->{$key}){
		return $self->{_namespace_dbs}->{$key};
	}elsif(!defined $value){
#		$self->throw("Cannot find \'$key\' as namespace. It may not regiested");
	}

    return $self->{_namespace_dbs}->{$key} = $value if $value;

}

=head2 create_persistent

This method offers the same interface as Bio::DB::BioSQL::DBAdaptor,
hence the usage is same as well.

NOTE: You need to assign $obj-E<gt>namespace as the biodatabase name,
such as embl, before you invoke this method.

=cut

sub create_persistent{
    my ($self,$obj,@args) = @_;

    # The object instant creation is copy from Bio::DB::BioSQL::DBAdaptor

    # we need to obtain an instance of the class 
    # if it's not already an instance
    if(! ref($obj)) {
        my $class = $obj;
        # load the module first, otherwise new() will fail;
        # this will throw an exception if it fails
        $self->_load_module($class);
        # we wrap this in an eval in order to indicate clearer what failed
        # (if it fails)
        eval {
            $obj = $class->new(@args);
        };
        if($@){
            $self->throw("Failed to instantiate ${obj}: ".$@);
        }
    }

    # The end of coping and here is my code.
    # Try to get namespace
    my $namespace;
    if($obj->isa('Bio::Seq') or $obj->can('namespace')){
        $namespace = $obj->namespace;
    }elsif(defined $self->namespace){
        $namespace = $self->namespace;
    }else{
        $self->throw('The module, '. ref($obj). ', is not supported');
    }

    my $db = $self->_namespace_dbs($namespace);
    return $db->create_persistent($obj);
    
}

sub get_object_adaptor{
    my ($self, $class, $dbc) = @_;
    my ($adp, $adpclass);

    my $namespace;
    if( ref $class){
        if( $class->can('namespace')){
            $namespace = $class->namespace;
        }else{
            $namespace = $self->namespace;
        }
        $class = ref $class;
    }else{
        $namespace = $self->namespace;
    }

    my $db = $self->_namespace_dbs($namespace);
    $adpclass = $db->get_object_adaptor($class, $dbc);

    return $adpclass;
}

sub find_by_unique_key{
    my ($self, $key) = @_;
    
    if($key->can('namespace')){
        if(defined(my $namespace = $key->namespace)){
            my $db = $self->_namespace_dbs($namespace);
            if(defined $db){
                my $adaptor = $db->get_object_adaptor($key);
                return $adaptor->find_by_unique_key($key);
            }
        }
    }

    # namespace is unknown from the key, so search for all registered db(s).
    eval{require Thread;};
    if($@){
#        $self->throw("Failed to load Thread:\n$@");
        
        # The non-thread approach
        my @keys;
        foreach(keys %{$self->{_namespace_dbs}} ){
            my $db = $self->_namespace_dbs($_);
            $key->namespace($_);
            my $adaptor = $db->get_object_adaptor($key);
            my $result = $adaptor->find_by_unique_key($key);
			push @keys, $result if defined $result;
        }
        return @keys;
    }
    
    my @threads;
    foreach(keys %{$self->{_namespace_dbs}} ){
        my $db = $self->_namespace_dbs($_);
        my $adaptor = $db->get_object_adaptor($key);
        my $t = Thread->new(
            sub{
                return shift->find_by_unique_key(shift);
            }, 
            $adaptor, $key);
        push @threads, $t;
    }

    my @keys;
    foreach(@threads){
        my $result = $_->join();
        push @keys, $result if defined $result;
    }

    return @keys;
}

sub _find_by_unique_key{
    my ($adaptor, $key) = @_;
    return $adaptor->find_by_unique_key($key);
}

=head2 Get/Set for default namespace

=cut

sub namespace{
    my ($self, $value) = @_;
    return $self->{'_namespace'} = $value if defined $value;
    return $self->{'_namespace'};
}



