package EROOT;
require 5.002;

#
# Eternal Root: an exercise in object persistence.
#   3jun96
#   Dean Roehrich
#
# changes/bugs fixed since 14mar95 version:
#  - removed some 'defined' checks on 'ref's--bonehead bug.
# changes/bugs fixed since 03dec94 version:
#  - podified
#  - updated for changes in 5.001 strictures.
# changes/bugs fixed since 21nov94 version:
#  - Updated manpage.
#  - Moved Persister::Continue to EROOT::Persister::Continue.
#  - Changed some error messages.
#  - new() blesses into $type, is inheritable.
#  - No longer requires root objects to be blessed.
#  - Misc. nit changes.
#  - Now using strictures.
# changes/bugs fixed since 31oct94 version:
#  - Moved to Class::Eroot.  Package is still EROOT.
#  - Using Class::Template.pm (was Class.pm).
# changes/bugs fixed since 20feb94 version:
#  - Changed SLEEP/WAKEUP to suspend/resume.
#  - Added Carp to some places.
#  - Order of keep/resume is now preserved.
#  - Keep is now more careful about taking blessed objects.
#  - Store will no longer make up a class name for an unblessed object.
#  - Convert to proper module.
#  - Bug in WriteStack prevented first object on stack from getting a resume.
#  - Replaced local() with my().
#  - Resume can now bless to a lowercase class name without causing warnings.
#  - Flattened EROOT::private class, it prevented reusability.
#  - Continue now uses dynamic dispatch for Resume.
#  - Updated manpage and examples.
#  - Now using dynamic dispatch everywhere; eases reusability.

=head1 NAME

Eroot - an eternal root to handle persistent objects

=head1 ABSTRACT

The Eternal Root (eroot) is given references to the root objects of any
object hierarchies which must persist between separate invocations of the
application.  When the eroot's destructor is called, the eroot will find all
objects referenced in the object hierarchies and will store them.  All
objects will be restored (if possible) when and if the B<Continue> message
is sent to the eroot.

=head1 SYNOPSIS

	require Class::Eroot;
	my $some_obj;
	my $eroot = new EROOT ( 'Name' => "persist.file",
				  'Key'  => "myAppObjects" );

	if( $eroot->Continue ){
		# No existing objects.  Start from scratch.
		$some_obj = new SomeObj;
		$eroot->Keep( "Some_obj" => $some_obj );
	}
	else{
		$some_obj = $eroot->Root("some_obj");
	}

	$eroot->List;
	$eroot->Keep( "MyObj" => $myobj );
	$eroot->Lose( "Old_Obj" );
	$eroot->Lose( $this_obj );

=head1 DESCRIPTION

When the eroot saves a group of object hierarchies, it stores its B<key>
with them.  The key of any objects being restored must match the key of the
eroot which is trying to restore them.  The B<Continue> method will call
B<die> if the keys do not match.  Continue will return 0 if the objects were
loaded and non-zero if they were not.

The eroot will attempt to send a B<suspend> message to the object prior to
storing the object's state.  The object's class is not required to have a
suspend method defined.

When the eroot restores an object it will bless the object reference in the
object's class (package) and will attempt to send a B<resume> message to the
object.  The object's class is not required to have a resume method defined.

An object should not propagate B<suspend> and B<resume> messages.  The eroot
will send suspend messages to the objects in the order in which they were
stored in the eroot (breadth-first, root-to-leaves).  The eroot will send
resume messages by starting with the classes of the objects at the leaves of
the object hierarchy and moving toward the root of the object hierarchy.

Note that Perl will call the B<destructors> of the persistent objects.  The
programmer should be prepared to deal with this.

It is necessary to B<Keep> an object only once.  The object will remain
persistent until the eroot is told to B<Lose> it.

=head1 INSTANCE VARIABLES

References will be properly hooked up if they are type SCALAR, ARRAY, REF,
or HASH.  The eroot assumes that keys and values (if the value is not a
reference) for the objects' B<instance variables> can be represented as text
within single quotes.  If this is not true for your objects then the object's
B<suspend> method can be used to "wrap" the object for storage, and the
B<resume> method can be used to "unwrap" the object.

Embedded single quotes in the value will be preserved.  This is
currently the only place where single quotes are handled.

=head1 THINGS TO AVOID

	o Storing the eroot.
	o Storing references to tie()'d variables and objects.
	o Storing references to CODE objects.
	o Storing the same object in two different eroots.
	  Unless you think you know what you're doing, of course.
	o Using two eroots to store each other :)
	o Storing named arrays and hashes.  These will be restored as
	  anonymous arrays and hashes.
	o Storing an object while it has an open stream.
	o Storing an object which has an %OVERLOAD somewhere in
	  it's class hierarchy.

Know your object hierarchy.  Be sure that everything in the hierarchy
can handle persistence.

=head1 NOTES

This is not an OODBMS.

=head1 FILES

	Class::Eroot.pm	- Eternal Root class.
	persist.file	- User-defined file where objects are stored.
	Class::Template.pm	- Struct/member template builder.

=cut

@ISA=qw(EROOT::Persister);
use Carp;
use Class::Template;

use strict;
no strict 'refs';

Var: {

	# Stub.  WriteStack will create method EROOT::Continue
	# to override this.
	sub EROOT::Persister::Continue { 1; }
	
	$EROOT::DumpStack = 0;
	$EROOT::WriteStack = 1;

	@EROOT::MEMBERS = (
		'refs'		=> '@',  # objects
		'xrefs'		=> '%',  # indices into refs
		'xnames'	=> '%',  # indices into xrefs
		'id2name'	=> '%',  # indices into xnames
		'fname'		=> '$',
		'key'		=> '$',
		);

	members EROOT { @EROOT::MEMBERS };
}


# Parameters:  Name, Key
sub new {
	my( $type, %args ) = @_;
	my $self = InitMembers();

	$self->fname( $args{'Name'} ) ||
		croak "Need name of file for persistent objects";
	$self->key( $args{'Key'} ) ||
		croak "Need key for persistent objects";
	require $args{'Name'} if( -e $args{'Name'} );
	bless $self, $type;
}


DESTROY {
	my $self = shift;

	$self->Store;
}


sub Keep {
	my $self = shift;
	my( $name, $ref ) = @_;
	my $i = @{$self->refs};
	my $id;

	if( @_ != 2 ){
		croak "usage - EROOT::Keep( self, name, ref )";
		return;
	}
	if( ! ref $ref ){
		carp "Not an object";
	}
	else{
		$self->refs( $i, $ref );
		($id) = "$ref" =~ /\((0x[a-f0-9]+)\)$/o;
		$self->xrefs( $id, $i );
		$self->xnames( $name, $id );
		$self->id2name( $id, $name );
	}
}


sub Lose {
	my( $self, $ref ) = @_;
	my( $id, $i );

	if( ref $ref ){
		($id) = "$ref" =~ /\((0x[a-f0-9]+)\)$/o;
		if( defined $self->xrefs($id) ){
			$i = $self->xrefs($id);
			$self->refs( $i, undef );
			$self->xrefs( $id, undef );
			$self->id2name( $id, undef );
		}
	}
	elsif( defined $self->xnames( $ref ) ){
		$id = $self->xnames( $ref );
		$i = $self->xrefs( $id );
		$self->refs( $i, undef );
		$self->xrefs( $id, undef );
		$self->id2name( $id, undef );
	}
	else{
		carp "Not an object";
	}
}


sub Root {
	my( $self, $name ) = @_;
	my( $id, $i );
	my $root = undef;

	if( defined $self->xnames( $name ) ){
		$id = $self->xnames( $name );
		$i = $self->xrefs( $id );
		$root = $self->refs( $i );
	}
	else{
		carp "No root named $name";
	}
	$root;
}


sub List {
	my $self = shift;
	my @keys = keys %{$self->xrefs};
	my( $id, $i );

	while( @keys ){
		$id = shift @keys;
		$i = $self->xrefs( $id );
		print $self->id2name($id)," is ",$self->refs($i),"\n";
	}
}


#
# Private routines for the EROOT.  These actually do the store/restore
# of the objects.
#

## private
sub Resume {
	# Bless the reference in its own package.
	eval qq{ bless \$_[2], qq{$_[1]} };
	if( $@ ){
		warn "While blessing ref $_[2] in class $_[1]: $@";
	}
	else{
		# Let object resume.
		eval { $_[2]->resume };
	}
}


# Push all objects onto a stack, using breadth-first search.  The root
# object is at the bottom of the stack, the leaf objects are at the top
# of the stack.
#

## private
sub Store {
	my $self = shift;
	my $name = $self->{'fname'};
	my( $n, $obj, @k );
	my @s = ();
	my @objs = @{$self->{'refs'}};
	my $roots = $self->{'xrefs'};
	my $id2name = $self->{'id2name'};
	my $key = $self->{'key'};
	my( $class, $type, $ident );
	my %id = ();

	while( @objs ){
		$obj = shift @objs;
		next if( ! defined $obj );
		$class = "";
		"$obj" =~ /^([^=]+)=/o && do { $class = $1 };
		if( "$obj" =~ /([A-Z]+)\((0x[a-f0-9]+)\)$/o ){
			($type,$ident) = ($1,$2);
			next if( defined $id{$ident} );
			$id{$ident}++;
			push( @s, "end $ident" );

			# Suspend the object.
			eval { $obj->suspend } if( $class ne '' );

			if( $type eq 'ARRAY' ){
				if( @$obj ){
					$self->StoreArray( $obj, $ident, \@s, \@objs );
				}
			}
			elsif( $type eq 'HASH' ){
				if( keys %$obj ){
					$self->StoreHash( $obj, $ident, \@s, \@objs );
				}
			}
			# The following also catches anything
			# you thought was REF (REF is actually SCALAR^2).
			elsif( $type eq 'SCALAR' ){
				$self->StoreScalar( $obj, $ident, \@s, \@objs );
			}
			else{
				die "Don't know how to handle $type $obj";
			}
			if( defined $roots->{$ident} ){
				$n = $id2name->{$ident};
				push( @s, "root $ident $n" );
				$roots->{$ident} = undef;
			}
			push( @s, "object $ident $type $class" );
		}
		else{
			warn "Eroot: Unable to recognize object $obj";
		}
	}
	$self->DumpStack( \@s )			if $EROOT::DumpStack;
	$self->WriteStack( $key, $name, \@s )	if $EROOT::WriteStack;
}


# Turn the stack into perl code.
# This will create a method named Continue in the EROOT class.
# This assumes that keys and values for the "objects" can be safely
# represented as text within single quotes.
#

## private
sub WriteStack {
	my $self = shift;
	my( $key, $name, $s ) = @_;
	my $fh = (caller)[0] . "::$name";
	my $i = @$s;
	my( $type, @v, $v );
	my( $junk, $word, $ident, $stuff );
	my @roots = ();
	my @keep = ();
	my @keepwake = ();
	my @wake = ();
	my %wake = ();
	my( $e1, $e2, $elem, $whack );
	my @delayed = ();

	open( $fh, ">$name" ) || do{
		warn "Eroot: Cannot save objects, unable to write to file $name";
		return;
	};
	print $fh "#KEY:$key\n";
	print $fh "# Persistent objects\n";
	print $fh "sub EROOT::Continue {\n";
	print $fh "  my \$self = shift;\n";
	print $fh "  my \%ref = ();\n";
	print $fh "  die \"These persistent objects (key=$key) do not belong to this application.\\n\"\n";
	print $fh "    if( \$self->{\'key\'} ne \'$key\' );\n";
	while( $i-- > 0 ){
		($junk, $word, $ident, $stuff) =
			split( /^(\w+) ([^\s]+) ?/o, $s->[$i], 2 );
		if( $word eq 'object' ){
			@v = split( ' ', $stuff );
			$e1 = $e2 = $type = $whack = '';
			if( $v[0] eq 'ARRAY' ){
				$e1 = "[";
				$e2 = "]";
				$type = " = []";
			}
			elsif( $v[0] eq 'HASH' ){
				$e1 = "{\'";
				$e2 = "\'}";
				$type = " = {}";
			}
			elsif( $v[0] eq 'SCALAR' ){
				$whack = "\\";
			}
			if( defined $v[1] ){
				push( @wake, "$ident!\$self->Resume( \'$v[1]\', \$ref{\'$ident\'} );" );
				$wake{$ident} = $#wake;
			}
			print $fh "  {\n    my \$x$type;\n";
		}
		elsif( $word eq 'root' ){
			push( @keep, "\$self->Keep( \'$stuff\', \$ref{\'$ident\'} );" );
			if( $wake{$ident} ){
				push( @keepwake, "\$self->Resume( \'$v[1]\', \$ref{\'$ident\'} );" );
				delete $wake{$ident};
			}
		}
		elsif( $word eq 'end' ){
			print $fh "    \$ref{\'$ident\'} = $whack\$x;\n  }\n";
		}
		elsif( $word eq 'ref' ){
			($junk, @v) = split( /^\(([^)]*)\) /o, $stuff, 0 );
			$elem = ($v[0] ne '') ? "->$e1$v[0]$e2" : "";
			push( @delayed, "  \$ref{\'$ident\'}$elem = $whack\$ref{\'$v[1]\'};" );
		}
		elsif( $word eq 'simple' ){
			($junk, @v) = split( /^\(([^)]*)\) /o, $stuff, 0 );
			$v[1] = '' unless defined $v[1];
			$elem = ($v[0] ne '') ? "->$e1$v[0]$e2" : "";
			$v[1] =~ s/\'/\\\'/og; # save embedded single quotes
			print $fh "    \$x$elem = \'$v[1]\';\n";
		}
		else{
			warn "Eroot: Unknown code: $v";
		}
	}
	print $fh join("\n", @delayed),"\n";
	# Everything here is to preserve Keep() and resume() order.
	while( @wake ){
		$_ = shift @wake;
		@_ = split('!');
		next unless defined $wake{$_[0]};
		print $fh "  $_[1]\n";
	}
	print $fh "  ", join("\n  ", reverse @keepwake), "\n";
	print $fh "  ", join("\n  ", reverse @keep), "\n";
	print $fh "  0;\n}\n1;\n";
	close( $fh );
}

## private
sub StoreScalar {
	my $self = shift;
	my( $obj, $ident, $s, $objs ) = @_;
	my $v;

	if( ref $$obj ){
		($v) = "$$obj" =~ /\((0x[a-f0-9]+)\)$/o;
		push( @$s, "ref $ident () $v" );
		push( @$objs, $$obj );
	}
	else{
		push( @$s, "simple $ident () $$obj" );
	}
}

## private
sub StoreHash {
	my $self = shift;
	my( $obj, $ident, $s, $objs ) = @_;
	my( $k, $v, @k );

	@k = keys %$obj;
	while( @k ){
		$k = shift @k;
		if( defined $obj->{$k} ){
			if( ! ref $obj->{$k} ){
				push( @$s, "simple $ident ($k) $obj->{$k}" );
			}
			else{
				($v) = "$obj->{$k}" =~ /\((0x[a-f0-9]+)\)$/o;
				push( @$s, "ref $ident ($k) $v" );
				push( @$objs, $obj->{$k} );
			}
		}

	}
}

## private
sub StoreArray {
	my $self = shift;
	my( $obj, $ident, $s, $objs ) = @_;
	my $k = 0;
	my $v;

	while( $k < @$obj ){
		if( defined $obj->[$k] ){
			if( ! ref $obj->[$k] ){
				push( @$s, "simple $ident ($k) $obj->[$k]" );
			}
			else{
				($v) = "$obj->[$k]" =~ /\((0x[a-f0-9]+)\)$/o;
				push( @$s, "ref $ident ($k) $v" );
				push( @$objs, $obj->[$k] );
			}
		}
		++$k;
	}
	$k;
}

## private
sub DumpStack {
	my $self = shift;
	my $s = shift;
	my $i = @$s;

	while( $i-- > 0 ){
		print "$s->[$i]\n";
	}
}
1;
