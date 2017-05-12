package DBIx::Objects;

use strict;
use warnings qw(all);
use vars qw($VERSION);

BEGIN {
    $VERSION=0.04;
}

###

package DBIx::Object;

use strict;
use warnings qw(all);

# Back-end methods
sub _blank {    # Default back-end for constructor
                # ARGS: $self, [$namespace,] @arglist
                # $namespace - Scalar (string) - Namespace of managing package for variables
                # @arglist   - Array (string) - List of variables to be registered as methods
    my $self=shift;
    my $package=
          (UNIVERSAL::isa($_[0],__PACKAGE__) && # Looks like a descendant
          shift) || caller; # Shift or autodetect namespace to register
    warn "Package $package not listed in registry"
        unless defined($self->{_REGISTRY}{$package});
    while (@_) {
        local $_=uc(shift);
        $self->{$_}=undef;
        $self->{_REGISTRY}{_DATA}{$_}{source}=$package;
        $self->{_REGISTRY}{_DATA}{$_}{access}=1; # default to rw
	$self->{_REGISTRY}{_DATA}{$_}{type}="basic";
    }
}

sub _register { # Default back-end for package registration
                # Call immediately after being bless()ed
    my $self=shift;
    my $package=caller;
    $self->{_REGISTRY}{$package}{prep}=0 unless (defined($self->{_REGISTRY}{$package}));
    return defined($self->{_REGISTRY}{$package});
}

sub _unregister{# Default back-end for package de-registration
                # If you wish to partially destruct an object, make sure to call this
                # from each namespace being removed from the object
    my $self=shift;
    my $package=caller;
    $self->_taint($package);
    undef $self->{_REGISTRY}{$package};
    return (!(defined($self->{_REGISTRY}{$package})));
}

sub _primary {  # Sets/detects whether a namespace contains the primary key
                # Used internally to assure that the primary key's namespace is always
                # in sync with the rest of the object
    my $self=shift;
    my $package=(UNIVERSAL::isa($_[0],__PACKAGE__) && shift) || caller;
    if ($_[0]) {$self->{_REGISTRY}{_PRIMARY}=$package;$self->_taint;}
    return ($self->{_REGISTRY}{_PRIMARY} || 0);
}

sub _readonly { # Sets/detects whether a data mehod is tagged read-only
                # Used by AUTOLOAD to detect read-only method calls
    my $self=shift;
    my $package=(UNIVERSAL::isa($_[0],__PACKAGE__) && shift) || caller;
    my $var=uc(shift);
    if (@_) {local $_=shift;$self->{_REGISTRY}{_DATA}{$var}{access}=(!($_)?1:0) if (/[01]/);} #Set to "0" to catch in this check next time
    return (!($self->{_REGISTRY}{_DATA}{$var}{access}) ||
            $self->{_REGISTRY}{_DATA}{$var}{source} eq $self->_primary);
}

sub _validate { # Marks a namespace as tied to the back-end database
                # Intended to be called on first refresh - Paired with _taint
    my $self=shift;
    my $package=shift || caller;
    (my @vars=$self->_vars($package)) || return $self;
    foreach my $var (@vars) {
	if ($self->_isobject($var)) { # Reset embedded object information (only if needed)
	    unless ($self->{var} && ($self->{_REGISTRY}{_DATA}{$var}{data} eq $self->{$var})) {
		$self->{_REGISTRY}{_DATA}{$var}{data}=$self->{$var};
		$self->{_REGISTRY}{_DATA}{$var}{prep}=0;
		$self->{$var}=undef;
	    }
	}
    }
    $self->{_REGISTRY}{$package}{prep}=1;
    $self->{_REGISTRY}{ref($self)}{prep}=1;
    $self->_clean($package);
}

sub _taint {    # Marks a namespace as untied from the back-end database
                # Intended to be called on destruction only
    my $self=shift;
    my $package=shift || caller;
    $self->_dirty($package);
    (my @vars=$self->_vars($package)) || return $self;
    foreach my $var (@vars) {
	if ($self->_isobject($var)) { # Reset embedded object information (only if needed)
	    $self->{_REGISTRY}{_DATA}{$var}{prep}=0;
	    $self->{$var}=undef;
	}
    }
    $self->{_REGISTRY}{$package}{prep}=0;
}

sub _clean {    # Marks a namespace as in-sync with the back-end database
                # Intended to be called on all calls to add(), refresh() and update()
    my $self=shift;
    my $package=shift || caller;
    $self->{_REGISTRY}{$package}{dirty}=0;
}

sub _dirty {    # Marks a namespace as out-of-sync with the back-end databse
                # Intended to be called upon a write-access call to a class-method
    my $self=shift;
    my $package=shift || caller;
    $self->{_REGISTRY}{$package}{dirty}=1;
}

sub _vars {     # Returns a list of variables registered to a specific namespace
                # Used internally by default _refresh() and update() methods
    my $self=shift;
    my $package=shift || caller;
    my @vars = ();
    my @keys = keys(%{$self->{_REGISTRY}{_DATA}});
    foreach my $var(@keys) {
        push @vars,$var if ($self->{_REGISTRY}{_DATA}{$var}{source} eq $package);
    }
    return @vars;
}

sub _refresh {  # Default back-end for refresh
                # Inherited classes should implement a custom _refresh()
                # Alternatively, the default _refresh may be used if a valid DBI connection
                # is set using $__PACKAGE__::dbh and the table is set to $__PACKAGE__::table
    my $self=shift;
    my $package=(UNIVERSAL::isa($_[0],__PACKAGE__) && shift) || ref($self);
    my @vars=$self->_vars($package) || return $self;
    my $sth;
    {
        no strict 'vars';
        eval "\$sth=\$dbh->prepare_cached('SELECT \@vars FROM \$table WHERE (ID=?)');";
    }
    $sth->execute(@_) or return $self->blank;
    if ($sth->rows!=1) {
	$self->blank;
    } else {
	my $res=$sth->fetchrow_hashref;
	foreach my $var (@vars) {
	    $self->{$var}=$res->{$var};
	}
        $self->_validate;
    }
    $sth->finish;
    return $self;
}

sub AUTOLOAD {  # Default method call handler
                # Current support:
                #    * Read/Write registered methods from internal hash
    my $param;
    my $package;
    {
        no strict 'vars';
        $AUTOLOAD=~s/(.*):://;
	$package=$1;
        $param=$AUTOLOAD;
    }
    if (UNIVERSAL::isa($_[0],__PACKAGE__)) { # Method call of a sub-class
        my $self=shift;
        if ($self->{_REGISTRY}{_DATA}{uc($param)}) { # Acceptable function call
            my $source=$self->{_REGISTRY}{_DATA}{uc($param)}{source};
            if (!($self->valid($source))) {
                $self->refresh($source);
            }
	    # SET access
            if ((@_) && !($self->_readonly($source,$param))) { # Update rewriteable request
		if ($self->_isbasic($param)) {
		    $self->{uc($param)}=@_;
		    $self->_taint;
		} elsif ($self->_isobject($param)) { # Object SET
		    unless ($self->_isobjarray($param)) { # No SET allowed on arrays
			my ($temp,$pid)=@_;
			if (ref($temp) eq $self->{_REGISTRY}{_DATA}{uc($param)}{class}) {
			    # TODO: see if temp->isa($self->{_REGISTRY}{_DATA}{uc($param)}{class})
			    $pid=$temp->id; #Retrieve ID from internal object
			} else {
			    $pid=$temp; #Assume ID is specified if not compatible object
			}
			$self->{_REGISTRY}{_DATA}{uc($param)}{data}=$pid;
			$self->_taint;
		    }
		}
            } # GET access
	    if ($self->_isobject($param)) { # Prepare object
		return (wantarray?undef:0) unless $self->_o_prep($param);
	    }
	    if ($self->_isobjarray($param)) { # Object array returns special values
		    return (wantarray?@{$self->{uc($param)}}:$self->{_REGISTRY}{_DATA}{uc($param)}{prep});
	    } else {
		return $self->{uc($param)};
	    }
        }
    }
}

sub new {       # Default constructor
                # Do not overload this unless you're SURE you know what you're doing
    my $self={ };
    my $proto=shift;
    my $class=ref($proto) || $proto;
    bless $self,$class;
    eval "foreach \$_ (\@".$class."::ISA) {eval \$_.\"::blank(\\\$self);\";}";
    $self->_register;
    $self->blank(@_);
    if (@_) {
        eval ($self->_primary."::_refresh(\$self,'".$self->_primary."',@_);") if ($self->_primary);
	$self->_refresh(@_);
    }
    return $self;
}

sub clean {     # Returns true if namepace is in-sync with back-end database
                # Be sure to check for valid()ity BEFORE using this
    my $self=shift;
    my $package=shift || caller;
    return !($self->{_REGISTRY}{$package}{dirty});
}

sub valid {     # Returns true if namespace is tied and in-sync with back-end database
    my $self=shift;
    my $package=shift || ref($self);
    if ($self->_primary)
    {return ($self->{_REGISTRY}{$self->_primary}{prep} &&
             $self->clean($self->_primary) &&
             $self->{_REGISTRY}{$package}{prep} &&
             $self->clean($package))}
    else {return $self->{_REGISTRY}{$package}{prep} &&
                 $self->clean($package)};
}

sub blank {     # Default (abstract) blank method - used by the default constructor
                # This should be overridden by any inherited class that's meant to be useful
                # A typical blank() method should look like:
                #    sub blank {
                #        my $self=shift;
                #        $self->_register;
                #        $self->_blank("FOO", "BAR", ... , "LAST");
                #    }
    $_[0]->_register;
}

sub refresh {   # Default front-end for refresh
    my $self=shift;
    my $package=shift || ref($self);
    $self->_taint($package);
    eval $package."::_refresh(\$self,".$self->id.");";
    return $self->valid;
}

sub id  {      # Default id method - must be explicitly so that it can be overloaded
	       # when needed for refresh, but not be dependant on the object being valid
    my $self=shift;
    # Set access
    if ((@_) && !($self->_readonly("id"))) { # Update rewriteable request
	$self->{ID}=@_;
        $self->_taint;
    }
    return $self->{ID};
}

sub _isbasic { # Returns true if access method marked as basic (default)
    my $self=shift;
    my $var=uc(shift);
    return ($self->{_REGISTRY}{_DATA}{$var}{type} eq "basic");
}

sub _isobject { # Returns true if access method marked as embedded object
    my $self=shift;
    my $var=uc(shift);
    return ($self->{_REGISTRY}{_DATA}{$var}{type} eq "object");
}

sub _isobjarray {
    my $self=shift;
    my $var=uc(shift);
    return ($self->_isobject($var) && $self->{_REGISTRY}{_DATA}{$var}{array});
}

sub _object { # Marks an access member as an object (call in blank)
    my $self=shift;
    my $var=uc(shift);
    my $package=(UNIVERSAL::isa($_[0],__PACKAGE__) && shift) || ref($self);
    $self->{_REGISTRY}{_DATA}{$var}{prep}=0;
    $self->{_REGISTRY}{_DATA}{$var}{class}=$package;
    $self->{_REGISTRY}{_DATA}{$var}{data}=$self->{$var} || undef;
    $self->{_REGISTRY}{_DATA}{$var}{array}=0;
    $self->{_REGISTRY}{_DATA}{$var}{type}="object";
    $self->{$var}=undef;
}

sub _objarray { # Marks an access member as an array of objects (call in blank)
    my $self=shift;
    my $var=uc(shift);
    my $package=(UNIVERSAL::isa($_[0],__PACKAGE__) && shift) || ref($self);
    $self->_object($var,$package);
    $self->_readonly($var,1);
    $self->{_REGISTRY}{_DATA}{$var}{array}=1;
}

# This (objarray) won't be fully implemented until I can figure out how the heck
# to set the data source as an array - it probably has to be dealt with by
# end-module's refresh ($self->{$var}=@arrayofdata;) [UPDATE VALIDATE TO DEAL WITH THIS]...

sub _o_prep {
    my $self=shift;
    my $var=uc(shift);
    my $class=$self->{_REGISTRY}{_DATA}{$var}{class};
    my $source=$self->{_REGISTRY}{_DATA}{$var}{source};
    return 0 unless $self->valid($source);
    return $self->{_REGISTRY}{_DATA}{$var}{prep} if
	$self->{_REGISTRY}{_DATA}{$var}{prep};
    if ($self->_isobjarray($var)) {
	for (my $i=0;$i<=$#{$self->{_REGISTRY}{_DATA}{$var}{data}};$i++) {
	    $self->{$var}[$i]=$class->new($self->{_REGISTRY}{_DATA}{$var}{data}[$i]);
	}
	$self->{_REGISTRY}{_DATA}{$var}{prep}=$#{$self->{_REGISTRY}{_DATA}{$var}{data}}+1;
    } else {
	$self->{_REGISTRY}{_DATA}{$var}{prep}=(($self->{$var}=$class->new($self->{_REGISTRY}{_DATA}{$var}{data}))?1:0);
    }
    return $self->{_REGISTRY}{_DATA}{$var}{prep};
}

# TODO: Update updates recursively (into embedded objects)
#        UpdateNR updates non-0recursively (data ghets lost)

# DOCUMENT: _validate also initializes objects by setting internal DATA value and clearing external value


package DBIx::Object::DBI; #Shortcut functions for DBI-based backend

our @ISA=qw(DBIx::Object);

sub blank {
    $_[0]->_register;
}

sub _dbidbh {		# Sets/returns the DBI connection to use
    my $self=shift;
    my $package=(UNIVERSAL::isa($_[0],__PACKAGE__) && shift) || caller;
    if($_[0]) {$self->{_REGISTRY}{$package}{DBI}{dbh}=$_[0];}
    return $self->{_REGISTRY}{$package}{DBI}{dbh};
}

sub _dbirefresh {	# Sets/returns the SQL statement to run on refresh calls
    my $self=shift;
    my $package=(UNIVERSAL::isa($_[0],__PACKAGE__) && shift) || caller;
    if($_[0]) {$self->{_REGISTRY}{$package}{DBI}{refresh}=$_[0];}
    return $self->{_REGISTRY}{$package}{DBI}{refresh};
}

sub _refresh {   # Default back-end for DBI refresh
                 # Inherited classes may implement a custom _refresh()
    my $self=shift;
    my $package=(UNIVERSAL::isa($_[0],__PACKAGE__) && shift) || ref($self);
    my $sth=$self->{_REGISTRY}{$package}{DBI}{dbh}->prepare_cached($self->{_REGISTRY}{$package}{DBI}{refresh});
        $sth->execute(@_) or return $self->blank;
    if ($sth->rows!=1) {
	$self->blank;
    } else {
	my $res=$sth->fetchrow_hashref;
        foreach my $key (keys %{$res}) {
            $self->{uc($key)}=$res->{$key};
        }
        $self->_validate($package);
    }
    $sth->finish;
    return $self;
}

1;

__END__

=head1 NAME

DBIx::Objects - Perl extension to ease creation of database-bound objects

=head1 SYNOPSIS

This module is intended to provide an object-oriented framework for
accessing data sources.  The source of the data is completely abstract,
allowing for complete flexibility for the data back-end.  This module is
NOT intended to provide a persistance layer - please use another module
(like TANGRAMS) if you require object persistance.

I'm really not sure how to go about documenting this library, so let me
start by explaining the history of why it was written

=head1 BACKGROUND

I developed this module when I began to notice that most of my web-applications
followed a very similar format - there was a data back end and web methods
which could interoperate with them.  When I started to need helper applications
to work with the web-apps, I started porting all of my applications to use 2
layers.  The lower layer was an object framework which contained the Perl
code needed to work with the database.  This way, I could be sure that all of
the helper applications, and of course the web application, all used the same
access methods to get to the database to eleminate the possibility that something
was getting f#$%ed up in the database by a faulty query somewhere in the big mess of code.
(The upper layer was the "business logic" layer, which was the web or helper
application.)

Then, I noticed that all of these database access objects were very similar:
they all had access methods for each member of the class, which represented
a single field in the database and had select/insert/update/delete routines.

I'd also developed a "dynamic object" at this point, where I'd have a huge
variable-length field in the database which conatained many fields.  This
way I could change the object without worrying about compatibility in the
back end database if I added/changed/removed fields.  (We'll get back to
this later.)

Beyond that, there were different ways of embedding objects (for example,
a person object might have a phone number object embedded in it as part
of an address-book application).  (We'll get back to this later, too).

So there were different ways of logically grouping different sets of data,
but the objects all shared a unified way of accessing the data.  Thus was
DBIx::Objects born - it provided a framework which would reallly guarantee
that the objects would really function in a logically similar way - similar
to the way that most GUI applications work in logically similar ways (they
all have that File menu with Open , Save, Exit... The Help menu with Help
topics, an optional upgrade, etc).  So I guess you could call this library
an API for developing database bound objects.

For more information, see http://www.beamartyr.net/YAPC/

=head1 BASIC OBJECTS API

The most basic type of object that can be used with this library simply
get tied directly to fields in the database.

=item blank($self, @args)

This is your constructor.  Anything that is important for you to add to the
object's new() method should be done here.  DO NOT DECLARE YOUR OWN new()
FUNCTION!  This function gets a bless()ed $self passed as the first parameter,
followed by the argument list to the new() call.  The constructor is expected
to call the internal _blank() function described below, and should call _primary(),
if applicable.

In addition to being called by the constructor, this function is also called every
time an empty (blank) instance of the object is needed.

A sample structure for the blank() method is included for reference:

sub blank {
    my $self=shift;
    $self->_register;
    $self->_blank("FOO", "BAR", ... , "LAST");
    $self->_primary(1); # Optional - Marks as containing primary key
}

=item _refresh($self, [$package], $id)

This is called internally by refresh() and should contain code to sync the data
structure with the back end database.  Note that the $package variable is optional,
but should be checked for (META: Remove code that makes this necessary). The
subroutine should either refresh the data from the database and call _validate() or,
if no suitable data is found, should call blank() [NOT _blank()]. In either case,
it should return $self.  A sample structure for the _refresh() method is included here
for reference:

sub _refresh {
    my $self=shift; # Shift $self
    my $package=(UNIVERSAL::isa($_[0],__PACKAGE__) && shift) || ref($self); # Detect $package
    my $sth=$dbh->prepare_cached('SELECT FIRSTNAME, LASTNAME FROM PEOPLE WHERE (ID=?)'); # Set SQL
    $sth->execute(@_) or return $self->blank; # Run SQL or return blank() object
    if ($sth->rows!=1) { # A good SQL statement should always return EXACTLY one row
	$self->blank; # Bad SQL - return blank()
    } else { # Good SQL
	my $res=$sth->fetchrow_hashref; # Fetch results
        $self->{FIRSTNAME}=$res->{FIRSTNAME}; # Each element from the result set
	$self->{LASTNAME}=$res->{LASTNAME}; # gets passed to exactly one hash element
        $self->_validate; # And call _validate() to mark it as clean and in-sync with the DB
    }
    $sth->finish; # Finished with SQL
    return $self; # ...and return $self
}

=head1 ADVANCED OBJECTS API

Beyond storing simple values, you can also magically construct objects using
the primary key of the target objects.  Using the above example,
we spoke of a phone book catalog, which has a person object and a phone number object.
Would it be nice, if instead of writing:

my $phone_number=Phone_Number->new($person->phone_number);
print "Number is ".$phone_number->thenumber;

... you could simply write ...

print "Number is ".$person->phone_number->thenumber;

The advanced objects API lets you do just that, with almost no extra work on your behalf.

=item _object($var, [$package])

This should be called in the blank() constructor.  It is used to mark access
method $var as an embedded object of type $package.  If $package is not passed
as an argument, it will default to the current package (eg, Your::Object).  To
use the feature, simply store the data you want passed to the object's constructor
the same way you'd store any other data for a normal access method, and when
you _validate the object, the data will be appropriately stored.  The object will be
constructed on the first call to the access method.

=item _objarray($var, [$package])

This should be called in the blank() constructor.  It is used to mark access method
$var as an embedded array of objects of type $package.  If $package is not passed
as an argument, it will default to the current package (eg, Your::Object).  The
functionality is similar to that of _object except that we are dealing with arrays.
As such, care must be taken to properly initialize the array.  To use it, store an
array (not a reference) in the _refresh function.  When _validate is called on the
object, the array will be stored and objects will be called on subsequent access
via the method call $var.  The method call will return the number of objects in
the array if called in a scalar context, and the array of objects if called in a
list context.  The objects will be constructed upon access.

Note that this functionality is still under construction.

=head1 DBIx::Object::DBI

This object provides some shortucts for DBIx::Objects which use DBI as the backend
datasource.

=item _dbidbh

Gets/sets the DBI connection to use in the object.  Use is as follows:

$dbh=new DBI($DSN);
...
(in blank() )
$self->_dbidbh($dbh);

=item _dbirefresh

Gets/sets the SQL statement to use in refresh() calls.  Paramaters can be used, and
will be set by the parameters actually passed to refresh()  Remember that internally,
DBIx::Objects assumes that it should receive valid data by calling

$self->refresh($self->id);

If that won't work for you, consider overloading the id() call, or implementing your
own refresh() routine

=head1 INTERNAL FUNCTIONS

=item _blank(@vars)

This should be called by the blank() constructor.  The arguments should be all of the
access methods provided by this class.  It should *not* include inherited access
methods, as they will automatically be discovered by AUTOLOAD.  This will register
all of the access methods in the registry under the module's namespace, so that
AUTOLOAD can auto-load the module to refresh or update the database for it.

=item _validate()

This method should be called from the _refresh function.  It tells the object that
its data has been updated and to remark itself as having fresh unchanged data.

=head1 AUTHOR AND COPYRIGHT

Copyright (c) 2003, 2004 Issac Goldstand E<lt>margol@beamartyr.netE<gt> - All rights reserved.

This library is free software. It can be redistributed and/or modified
under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Class::DBI>.

=cut
