package Class::PObject::Template;

# Template.pm,v 1.24 2005/02/20 18:05:00 sherzodr Exp

use strict;
#use diagnostics;
use Log::Agent;
use Carp;
use vars ('$VERSION');
use overload (
    '""'    => sub { $_[0]->id },
    fallback=> 1
);

$VERSION = '1.93';

sub new {
    my $class = shift;
    $class    = ref($class) || $class;

    logtrc 2, "%s->new()", $class;

    croak "Odd number of arguments passed to new(). May result in corrupted data" if @_ % 2;

    my $props = $class->__props();
    my $self = {
        columns     => { @_ },   # <-- holds key/value pairs
        _is_new     => 1
    };

    bless($self, $class);

    # It's possible that new() was not given all the column/values. So we
    # detect the ones missing, and assign them 'undef'
    for my $colname ( @{$props->{columns}} ) {
        unless ( defined $self->{columns}->{$colname} ) {
            $self->{columns}->{$colname} = undef
        }
    }

    $self->pobject_init;
    return $self
}


#
# Extra init. code should be defined in parent
#
sub pobject_init {	}

sub set_datasource {
	$_[0]->__props()->{"datasource"} = $_[1] if defined( $_[1] );
}

sub set_driver {
    $_[0]->__props()->{'driver'} = $_[1] if defined( $_[1] );
}

sub set {
    my $self = shift;
    my ($colname, $colvalue) = @_;

	croak "set(): called as class method" unless ref( $self );
	croak "set(): missing arguments" unless @_ == 2;

    my $props = $self->__props();
    my ($typeclass, $args) = $props->{tmap}->{$colname} =~ m/^([a-zA-Z0-9_:]+)(?:\(([^\)]+)\))?$/;
    logtrc 3, "col: %s, type: %s, args: %s", $colname, $typeclass, $args;
    if ( ref $colvalue eq $typeclass ) {
        $self->{columns}->{$colname} = $colvalue;
    } else {
        $self->{columns}->{$colname} = $typeclass->new(id=>$colvalue);
    }
}





sub get {
    my ($self, $colname) = @_;

	croak "get(): called as class method" unless ref( $self ); 
	croak "get(): missing arguments" unless defined $colname;
    
    my $colvalue = $self->{columns}->{$colname};

    # If the value is undef, we should return it as is, not to surprise anyone.
    # If we keep going, the user will end up with an object,
    # which may not appear as empty
	return unless defined( $colvalue );
    
    # If we already have this value in our cache, let's return it
	return $colvalue if ref( $colvalue );

    # If we come this far, this value is being inquired for the first time.  So we should load() it.
	# To do this, we first need to identify its column type, to know how to inflate it.
    my $props				= $self->__props();
    my ($typeclass, $args)  = $props->{tmap}->{ $colname } =~ m/^([a-zA-Z0-9_:]+)(?:\(([^\)]+)\))?$/;
    
	croak "set(): couldn't detect type of column '$colname'" unless $typeclass;    

    # We should cache the loaded object in the column
    return $self->{columns}->{$colname} = $typeclass->load($colvalue);
}



sub save {
    my $self  = shift;
    my $class = ref($self) || $self;

	croak "save(): called as class method" unless ref $self;
    logtrc 2, "%s->save(%s)", $class, join ", ", @_;

    my $props		= $self->__props();
    my $driver_obj	= $self->__driver();

    my %columns = ();
    while ( my ($k, $v) = each %{ $self->{columns} } ) {
		# We should realize that column values are of Class::PObject::Type class, 
		# so their values should be stringified before being passed to drivers' save() method.
        $v = $v->id while ref $v;
        $columns{$k} = $v
    }

    # We call the driver's save() method, with the name of the class, all the props passed to pobject(), 
	# and column values to be stored
    my $rv = $driver_obj->save($class, $props, \%columns);
    unless ( defined $rv ) {
        $self->errstr($driver_obj->errstr);
        logerr $self->errstr;
        return undef
    }
    $self->id($rv);
    return $rv
}







sub fetch {
    my $class = shift;
	croak "fetch(): called as object method" if ref( $class );

	my ($terms, $args) = @_;
    $terms ||= {};
    $args  ||= {};

	logtrc 2, "%s->fetch()", $class;

    my $props  = $class->__props();
    my $driver = $class->__driver();

    while ( my ($k, $v) = each %$terms ) {
        $v = $v->id while ref $v;
        $terms->{$k} = $v
    }
    my $ids = $driver->load_ids($class, $props, $terms, $args);

    require Class::PObject::Iterator;
    return Class::PObject::Iterator->new($class, $ids);
}








sub load {
    my $class = shift;
	croak "load(): called as object method" if ref($class);
    my ($terms, $args) = @_;
    
	#
	# Initializing class attributes. This only makes difference if the class
	# if making use of pobject_init()
	#
	$class->new();

    logtrc 2, "%s->load()", $class;

    $terms = {} unless defined $terms;
    $args  = {} unless defined $args;

    # If we're called in void context, why bother?
	return undef unless defined(wantarray);

	unless ( wantarray ) {
		$args->{"limit"} = 1;
		$args->{"sort"}  ||= 'id';
	}

    my $props       = $class->__props();
    my $driver_obj  = $class->__driver();
    my $ids         = [];       # we first initialize an empty ID list

    # now, if we had a single argument, and that argument was not a HASH,
    # we assume we received an ID
    if ( defined($terms) && (ref $terms ne 'HASH') ) {
        $ids        = [ $terms ]
    } else {
        while ( my ($k, $v) = each %$terms ) {
            if ( $props->{tmap}->{$k} =~ m/^(MD5|ENCRYPT)$/ ) {
                carp "cannot select by '$1' type columns (Yet!)"
            }
			#
            # Following trick will enable load(\%terms) syntax to work
            # by passing objects.
			#
            $terms->{$k} = $terms->{$k}->id while ref $terms->{$k};
        }
        $ids = $driver_obj->load_ids($class, $props, $terms, $args) or return
    }
    return () unless scalar(@$ids);
    # if called in array context, we return an array of objects:
    if (  wantarray() ) {
        my @data_set = ();
        for my $id ( @$ids ) {
            my $row = $driver_obj->load($class, $props, $id) or next;
            my $o = $class->new( %$row );
            $o->{_is_new} = 0;
            push @data_set, $o
        }
        return @data_set
    }
    # if we come this far, we're being called in scalar context
    my $row = $driver_obj->load($class, $props, $ids->[0]) or return;
    my $o = $class->new( %$row );
    $o->{_is_new} = 0;
    return $o
}



sub remove {
    my $self    = shift;
	croak "remove(): called as class method" unless ref($self);

    logtrc 2, "%s->remove()", ref $self;
    
    my $props       = $self->__props();
    my $driver_obj  = $self->__driver();

    # if 'id' field is missing, most likely it's because this particular object
    # hasn't been saved into disk yet
	croak "remove(): object id is missing. Cannot remove" unless defined $self->id;

    my $rv = $driver_obj->remove( ref($self), $props, $self->id);
    unless ( defined $rv ) {
        $self->errstr($driver_obj->errstr);
        return undef
    }
    return $rv
}







sub remove_all {
	my $class = shift;
	my ($terms) = @_;

	croak "remove_all(): called as object method" if ref($class);
    logtrc 2, "%s->remove_all()", $class;

    $terms          ||= {};
    my $props       = $class->__props();
    my $driver_obj  = $class->__driver();

    while ( my ($k, $v) = each %$terms ) {
        $v = $v->id while ref $v;
        $terms->{$k} = $v
    }

    my $rv = $driver_obj->remove_all($class, $props, $terms);
    unless ( defined $rv ) {
        $class->errstr($driver_obj->errstr());
        return undef
    }
    return 1
}




sub drop_datasource {
    my $class = shift;
	croak "drop_datasource(): called as object method" if ref( $class );
    logtrc 2, "%s->drop_datasource", $class;

    my $props		= $class->__props();
    my $driver_obj	= $class->__driver();

    my $rv = $driver_obj->drop_datasource($class, $props);
    unless ( defined $rv ) {
        $class->errstr( $driver_obj->errstr );
        return undef
    }
    return 1
}






sub count {
    my ($class, $terms) = @_;
    croak "count(): called as object method" if ref ($class);
    logtrc 2, "%s->count()", $class;

    $terms         ||= {};
    my $props      = $class->__props();
    my $driver_obj = $class->__driver();

    while ( my ($k, $v) = each %$terms ) {
        $v = $v->id while ref $v;
        $terms->{$k} = $v
    }
    return $driver_obj->count($class, $props, $terms)
}



sub errstr {
    my $self  = shift;
    my $class = ref($self) || $self;

    no strict 'refs';
    if ( defined $_[0] ) {
        ${ "$class\::errstr" } = $_[0]
    }
    return ${ "$class\::errstr" }
}










sub columns {
    my $self = shift;
    my $class = ref($self) || $self;

    logtrc 2, "%s->columns()", $class;

    my %columns = ();
    while ( my ($k, $v) = each %{$self->{columns}} ) {
        $v = $v->id while ref $v;
        $columns{$k} = $v;
    }

    return \%columns
}







sub dump {
    my ($self, $indent) = @_;

    require Data::Dumper;
    my $d = Data::Dumper->new([$self], [ref $self]);
    $d->Indent($indent||2);
    $d->Deepcopy(1);
    return $d->Dump()
}





sub __props {
    my $class = shift;

	#
	# Can be called either as class or object method
	#

    no strict 'refs';
    return ${ (ref($class) || $class) . '::props' }
}



sub __driver {
    my $class  = shift;

	
	#
	# Can be called either as class or object method
	#

    my $props	= $class->__props();
    my $pm		= "Class::PObject::Driver::" . $props->{driver};

    # closure for getting and setting driver object
    my $get_set_driver = sub {
        no strict 'refs';
        if ( defined $_[0] ) {
            ${ "$pm\::__O" } = $_[0]
        }
        return ${ "$pm\::__O" }
    };

    my $driver_obj = $get_set_driver->();
	return $driver_obj if defined $driver_obj;

	#
    # If we got this far, it's the first time the driver is
    # required.
	#
    eval "require $pm";
    if ( $@ ) {
        logcroak $@
    }
    $driver_obj = $pm->new();
    unless ( defined $driver_obj ) {
        $class->errstr($pm->errstr);
        return undef
    }
    $get_set_driver->($driver_obj);
    return $driver_obj
}



package VARCHAR;
use vars ('@ISA');
require Class::PObject::Type::VARCHAR;
@ISA = ("Class::PObject::Type::VARCHAR");


package CHAR;
use vars ('@ISA');
require Class::PObject::Type::CHAR;
@ISA = ("Class::PObject::Type::CHAR");


package INTEGER;
use vars ('@ISA');
require Class::PObject::Type::INTEGER;
@ISA = ("Class::PObject::Type::INTEGER");


package TEXT;
use vars ('@ISA');
require Class::PObject::Type::TEXT;
@ISA = ("Class::PObject::Type::TEXT");


package ENCRYPT;
use vars ('@ISA');
require Class::PObject::Type::ENCRYPT;
@ISA = ("Class::PObject::Type::ENCRYPT");


package MD5;
use vars ('@ISA');
require Class::PObject::Type::MD5;
@ISA = ("Class::PObject::Type::MD5");


1;

__END__;

=pod

=head1 NAME

Class::PObject::Template - Class template for all the pobjects

=head1 DESCRIPTION

Class::PObject::Template defines the structure of all the classes created
through C<pobject()> construct.

All created pobjects are dynamically set to inherit from Class::PObject::Template.

=head1 NOTES

It would be nice if we had an option of setting an alternative template class
for pobjects individually.

=head1 AUTHOR and COPYRIGHT

For author and copyright information refer to L<Class::PObject|Class::PObject/>.

=cut
