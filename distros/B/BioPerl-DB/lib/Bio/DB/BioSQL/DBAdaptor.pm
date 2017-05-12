# $Id$

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::BioSQL::DBAdapter - Object representing an instance of a 
bioperl database

=head1 SYNOPSIS

    $dbcontext = Bio::DB::SimpleContext->new(
        -user   => 'root',
        -dbname => 'pog',
        -host   => 'caldy',
        -driver => 'mysql',
	);

    $db = Bio::DB::BioSQL::DBAdaptor->new(
        -dbcontext => $dbcontext
    );

    # You can also create db adaptor by calling Bio::DB::BioDB constructor.
    $db = Bio::DB::BioDB->new(
        -database => 'biosql',
        -user   => 'root',
        -dbname => 'pog',
        -host   => 'caldy',
        -driver => 'mysql',
    );

=head1 DESCRIPTION

This object represents a database that is implemented somehow (you
shouldn't care much as long as you can get the object). From the
object you can pull out other adapters, such as the BioSeqAdapter,

=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut

#'
# Let the code begin...


package Bio::DB::BioSQL::DBAdaptor;

use vars qw(@ISA);
use strict;

use Bio::Root::Root;
use Bio::DB::DBAdaptorI;
use Bio::DB::PersistenceAdaptorI;
use Bio::DB::Persistent::PersistentObject;
use DBI;
use FileHandle;

@ISA = qw(Bio::Root::Root Bio::DB::DBAdaptorI);

sub new {
    my($pkg, @args) = @_;

    my $self = $pkg->SUPER::new(@args);

    my ($dbc, $printerror) = 
        $self->_rearrange([qw(DBCONTEXT PRINTERROR)],@args);

    $self->dbcontext($dbc) if $dbc;
    $self->{'_failed_objadp'} = {};
    $self->{'_objadp_cache'} = {};
    $self->{'_objadp_instances'} = {};

    # by default we'll shut up DBI
    $printerror = 0 unless defined($printerror); 

    # we'll disable AutoCommit for the persistence adaptors of this
    # database, and we'll also disable RaiseError
    if($dbc) {
	$dbc->dbi()->conn_params("Bio::DB::PersistenceAdaptorI",
				 { RaiseError => 0, 
                                   AutoCommit => 0,
                                   PrintError => $printerror,
                               });
    }

    return $self; # success - we hope!
}

=head2 get_object_adaptor

 Title   : get_object_adaptor
 Usage   : $objadp = $adaptor->get_object_adaptor("Bio::SeqI");
 Function: Obtain an PersistenceAdaptorI compliant object for the given class
           or object.
 Example :
 Returns : The appropriate object adaptor, a Bio::DB::PersistenceAdaptorI
           implementing object.
 Args    : The class (a string) or object for which the adaptor is to be
           obtained. Optionally, a DBContextI implementing object to initialize
           the adaptor with. 


=cut

sub get_object_adaptor{
    my ($self,$class,$dbc) = @_;
    my ($adp, $adpclass);
    
    # adaptor classes are cached under the class name, not the hash ref
    $class = ref($class) if ref($class);
    # obtain adaptor class (throws an exception upon failure)
    $adpclass = $self->_get_object_adaptor_class($class);
    # need to instantiate if instance from cache not available
    if(exists($self->{'_objadp_instances'}->{$adpclass})) {
	# instance is cached
	$adp = $self->{'_objadp_instances'}->{$adpclass};
    } else {
	# no, not cached
	# get dbcontext as we'll need it for instantiation
	$dbc = $self->dbcontext() unless $dbc;
	# instantiate, and propagate the verbosity level
	$self->debug("instantiating adaptor class $adpclass\n");
	$adp = $adpclass->new(-dbcontext => $dbc,
			      -verbose   => $self->verbose());
	# cache
	$self->set_object_adaptor($class, $adp);
    }
    # return the object
    return $adp;
}

=head2 _get_object_adaptor_class

 Title   : _get_object_adaptor_class
 Usage   : $objadpclass = $adaptor->_get_object_adaptor_class("Bio::SeqI");
 Function: Obtains and loads the PersistenceAdaptorI compliant class for the
           given class or object.
 Example :
 Returns : The appropriate object adaptor class, a Bio::DB::PersistenceAdaptorI
           implementing class, or an instantiation of it, if one has been
           cached.
 Args    : The class (a string) for which the adaptor class is to be obtained. 


=cut

sub _get_object_adaptor_class{
    my ($self,$class) = @_;

    # is it cached directly, as success or failure?
    if(exists($self->{'_objadp_cache'}->{$class})) {
	return $self->{'_objadp_cache'}->{$class};
    } elsif(exists($self->{'_failed_objadp'}->{$class})) {
	$self->throw("failed to load adaptor for class $class");
    }
    # no, not cached.
    #
    # can we load it directly?
    my ($adpclass);
    eval {
	$self->debug("attempting to load adaptor class for $class\n");
	$adpclass = $self->_load_object_adaptor($class);
    };
    #
    # upon failure recursively and depth-first traverse inheritance tree
    #
    my @ancestors = ();
    if(! $adpclass) {
	# we need to bring in this class here in order to have access to @ISA.
	eval {
	    $self->_load_module($class);
	};
	if($@) {
	    $self->throw("weird: got object of class $class, ".
			 "but cannot load class: ".$@);
	}
	my $aryname = "${class}::ISA"; # this is a soft reference
	# hence, allow soft refs
	no strict "refs";
	@ancestors = @$aryname;
	# and disallow again
	use strict "refs";
	# loop; this is depth first traversal
	# note that this may need tuning as to e.g. traverse interfaces first
	foreach my $ancestor (@ancestors) {
	    # did this fail once already?
	    next if $self->{'_failed_objadp'}->{$ancestor};
	    # no, first attempt
	    eval {
		$adpclass = $self->_get_object_adaptor_class($ancestor);
	    };
	    # terminate the loop if success
	    last if $adpclass;
	}
    }
    # success (immediately, or after inheritance tree traversal) ?
    if($adpclass) {
	# cache success right here
	$self->set_object_adaptor($class, $adpclass);
	return $adpclass;
    } # else failure
    # cache failure as well ...
    $self->{'_failed_objadp'}->{$class} = 1;
    # and raise the exception ...
    $self->throw("failed to load adaptor for class $class as well as parents ".
		 join(", ", @ancestors));
}

=head2 set_object_adaptor

 Title   : set_object_adaptor
 Usage   : $adaptor->set_object_adaptor("Bio::SeqI", $bioseqadaptor);
 Function: Sets the PersistenceAdaptorI compliant object and/or class for the
           given class or interface.
 Example :
 Returns : none
 Args    : The class (a string) or object for which the adaptor is to be set.
           The PersistenceAdaptorI compliant class or an instance of it to
           serve as the adaptor.


=cut

sub set_object_adaptor{
    my ($self, $class, $adp) = @_;

    if(ref($adp) && ! $adp->isa('Bio::DB::PersistenceAdaptorI')) {
	$self->throw(ref($adp)." to be used as adaptor for $class does not ".
		     "implement Bio::DB::PersistenceAdaptorI. Bad.");
    }
    $self->{'_objadp_cache'}->{$class} = ref($adp) ? ref($adp) : $adp;
    $self->{'_objadp_instances'}->{ref($adp)} = $adp if ref($adp);
}

=head2 create_persistent

 Title   : create_persistent
 Usage   : $dbadaptor->create_persistent($obj)
 Function: Creates a PersistentObjectI implementing object that adapts the
           given object to the datastore.
 Example :
 Returns : A Bio::DB::PeristentObjectI implementing object
 Args    : An object of a type that can be stored in the datastore adapted
           by this factory. Alternatively, the class name of such an object.
           All remaining arguments will be passed to the constructor of the
           class if the first argument is a class name.


=cut

sub create_persistent{
   my ($self,$obj,@args) = @_;

   # sanity check the object argument
   $self->throw("are you kidding me? make undef persistent??") 
       unless defined($obj);

   # we need to obtain an instance of the class if it's not already an instance
   if(! ref($obj)) {
       my $class = $obj;
       # load the module first, otherwise new() will fail; this will throw
       # an exception if it fails
       $self->_load_module($class);
       # we wrap this in an eval in order to indicate clearer what failed (if
       # it fails)
       eval {
	   $obj = $class->new(@args);
       };
       if($@) {
	   $self->throw("Failed to instantiate ${obj}: ".$@);
       }
   }
   # we also need to obtain an adaptor
   my $adp = $self->get_object_adaptor($obj);
   # ready to create the persistent object
   return $adp->create_persistent($obj);
}


=head2 dbcontext

 Title   : dbcontext
 Usage   : $obj->dbcontext($newval)
 Function: Get/set the DBContextI object representing the physical database.

           If this slot is not set, adaptor objects returned by
           get_adaptor() will not be initialized with a database connection,
           unless a DBContextI is passed to get_adaptor().
 Example : 
 Returns : A DBContextI implementing object
 Args    : on set, the new DBContextI implementing object


=cut

sub dbcontext{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'dbcontext'} = $value;
    }
    return $self->{'dbcontext'};
}

=head2 _load_object_adaptor

 Title   : _load_object_adaptor
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub _load_object_adaptor{
    my ($self,$class,$suffix) = @_;

    # standard suffix is Adaptor
    $suffix = 'Adaptor' unless $suffix;
    # our adaptors are all in Bio::DB::BioSQL
    my $prefix = 'Bio::DB::BioSQL';
    # strip all leading path from the class name
    $class =~ s/.*:://;
    # we'll try w/ and w/o the trailing I (in case of an interface)
    my ($class_noI) = $class =~ /^(.*)I$/;
    # load away ...
    my @mods = ($prefix."::".$class.$suffix);
    push(@mods, $prefix."::".$class_noI.$suffix) if $class_noI;
    my $adp;
    foreach my $mod (@mods) {
	eval {
	    $self->debug("\tattempting to load module $mod\n");
	    $self->_load_module($mod);
	    $adp = $mod;
	};
	last if $adp;
    }
    return $adp if $adp;
    $self->throw("failed to dynamically load any of (".join(",",@mods).")");
}


1;
