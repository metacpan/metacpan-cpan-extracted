# $Id$
#
use strict;
use warnings;
no warnings qw(uninitialized);
use utf8;

package Data::HashArray;
require 5.008;

use Carp qw(carp cluck);
use Data::Dumper;
use Scalar::Util qw(reftype);

use vars qw($VERSION);
$VERSION = '1.03';

our $AUTOLOAD;

# Hash deref. gives access to the first element
# For debugging purpose only
#carp "\033\[0;35m[NOTICE] Overloaded '\"\"' called (".
#  __PACKAGE__.")\033\[0m";
use overload (
    '%{}'      => sub { $_[0]->_hash_access; },
    '""'       => sub { "". $_[0]->_hash_access; },
    'fallback' => 1,
);

# --------------------------------------------------------------------
# Constructor
# --------------------------------------------------------------------

sub new {
    my ($proto, @array) = @_;
    my $class = ref($proto) || $proto;

    bless \@array, $class;
}


# Return the first element (which is normally a hash ref) of the list
sub _hash_access () {
    my ($self) = @_;

    my $item = eval { $self->[0]; };
    if ($@) {
        cluck "$@";
    }

    #carp "Hash-access => DONE\n";
    return $item;
}

#-------------------------------------------------------
# hash(field1, field2, field3, ...)
#
# Return a hash keyed on field1. If there is no field2, this will be 
# a hash of HashArrays. If field2 exists, this will be a hash of hashes of
# HashArrays. And so on...
# 
# Note that field1; field2, ... may be CODE references, too. In that case, the sub gets called
# at least once for each item in the array. The item is passed as an argument to the sub.
# 
# Breadth-first recursive.
#-------------------------------------------------------
sub hash {
	my $self	= shift;
	my $class	= ref($self);	
	return undef unless (@_);	
	my $field	= shift;
	return undef unless defined($field);
		
	my $h = {};
	
	# Hash the array on '$field';
	foreach my $item (@$self) {
		my $key;
		
		if (ref($field) eq 'CODE') {
			# Field is a CODE refernce. Call it, with 'item' passed as an argument
			$key = &$field($item);
		} elsif (UNIVERSAL::can($item, $field)) {
			# Field has an accessor. Call it  (the resukt should stringify to a hash key).
			$key = $item->$field();
		} else {
			# Field should otherwise stringify to a hash key
			$key = $item->{$field};
		}
		
		# If the keyed item doesn't yet exist, create a new NodeArray and assign it.
		unless ( exists($h->{$key}) ) {
			$h->{$key} = $class->new();
		}
		
		# Push the item on the keyed NodeArray.
		my $array= $h->{$key};		
		push @$array, $item;
	}

	# If we don't have any more fields, just return the hash.
	return $h unless (@_);

	# Otherwise, further hash each item in the hash on the remaining fields.
	foreach my $key (keys %$h) {
		my $array = $h->{$key};
		$h->{$key} = $array->hash(@_);
	}
	return $h;	
}


#-------------------------------------------------------
# By default, all method calls are delegated to the first element.
#-------------------------------------------------------
sub AUTOLOAD {
    my $self = shift;
    my $func = $AUTOLOAD;
    $func    =~ s/.*:://;

    if ($func =~ /^[0-9]+$/o) {
        return eval { $self->[$func]; };
    }

    return undef if $func eq 'DESTROY';
    if (reftype($self) && reftype($self) eq 'ARRAY') {
        $self->_hash_access->$func(@_);
    } else {
        cluck "*** \$self->$func";
    }
}


1;


__END__


=head1 NAME

B<Data::HashArray> - An array class of hashes that has magical properties via overloading and AUTOLOAD. 

=head1 ISA

This class does not descend from any other class. 

=head1 SYNOPSIS

  my $a = Data::HashArray->new(
					  {code=>'FR', name=>'France', size=>'medium'},
					  {code=>'TR', name=>'Turkey', size=>'medium'},
					  {code=>'US', name=>'United States', size=>'large'}
					  );

  print $a->[2]->{name};    # Prints 'United States'. No surprise.
  print $a->[0]->{name};    # Prints 'France'. No surprise.
  print $a->{name};	        # Prints 'France'. OVERLOADED hash access.

  my $h = $a->hash('code');  		# One level hash (returns a hash of a HashArray of hashes)
  my $h = $a->hash('size', 'code');	# Two level hash (returns a hash of a hash of a HashArray  of hashes)

  my $h = $a->hash('size')						# One level hash on 'size'.  
  my $h = $a->hash(sub { shift->{'size'}; })	# Same as above, but with a CODE reference
  

=head1 DESCRIPTION

Normally, B<Data::HashArray> is an array of hashes or hash-based objects. This class has some magical properties
that make it easier to deal with multiplicity. 

First, there exist two B<overload>s. One for hash access and the other for stringification. Both will act on the first 
element of the array. In other words, performing a hash access on an object of this class will be equivalent to 
performing a hash access on the first element of the array. 

Second, the AUTOLOAD method will delegate any method unkown to this class to the first item in the array as well. For this to 
work, at least the first item of the array better be an object on which one could call such a method. 

Both of these magical properties make it easier to deal with unpredictable multiplicity. You can both treat the object as an array 
or as hash (the first one in the array). This way, if your code deosn't know that an element can occur multiple times (in other words, if the
code treats the element as singular), the same code should still largely work when the singualr element is replaced by a B<Data::HashArray> object. 

The other practical feature of this class is the capabality to place the objects (or hashes) in the array into a hash keyed on the value of a given field or fields 
(see the L</hash()> method for further details).

=head1 OVERLOADS

Two overloads are performed so that a B<Data::HashArray> object looks like a simple hash or a singular object if treated like one.

=head4 hash access

If an object of this class is accessed as if it were a reference to a hash with the usual C<$object-E<gt>{$key}> syntax, it will I<behave> just like 
a genuine hash. The access will be made on the first item of the array (as this is an array class) assuming this item is a hash or hash-based object. 

=head4 stringification

If an object of this class is accessed as if it were a string, then the stringification of the first item of the array will be returned. 


=head1 METHODS

=head2 CONSTRUCTORS
 
=head4 new() 

  my $array = Data::HashArray->new();		# An empty array
  my $array = Data::HashArray->new(@items);	# An array with initial items in it.

B<CONSTRUCTOR>.

The new() constructor method instantiates a new B<Data::HashArray> object. 
This method is inheritable.
  
Any items that are passed in the parameter list will form the initial items of the array. 


=head2 OTHER METHODS

=head4 hash()

  my $h = $array->hash($field);		# Single hash level with one key field
  my $h = $array->hash(@fields);	# Multiple hash levels with several key fields
  
  my $h = $array->hash('size')						# Concrete example. Hash on 'size'.  
  my $h = $array->hash(sub { shift->{'size'}; })	# Same as above, but with a CODE reference
  
B<OBJECT METHOD>.

Remember that the items of a B<Data::HashArray> object are supposed to be hashes or at least
hash-based objects. 

When called with a single argument, the B<hash()> method will create a hash of the items of the array 
keyed on the value of the argument 'field'. 

An example is best. Assume that we have a B<Data::HashArray> object that looks like the following :

  my $array = bless ([
                      {code=>'FR', name=>'France', size=>'medium'},
                      {code=>'TR', name=>'Turkey', size=>'medium'},
                      {code=>'US', name=>'United States', size=>'large'}
                     ], 'Data::HashArray');

Now, if we make a call to B<hash()> as follows:

  my $hash = $array->hash('code');
 
Then the resulting hash will look like the following:
  
  $hash = {
           FR=> bless ([{code=>'FR', name=>'France', size=>'medium'], 'Data::HashArray'),
           TR=> bless ([{code=>'TR', name=>'Turkey', size=>'medium'], 'Data::HashArray'),
           US=> bless ([{code=>'US', name=>'United States', size=>'large'}, 'Data::HashArray')
  };
  
When, multiple fields are passes, then multiple levels of hashes will be created each keyed on the
field of the corresponding level. 

If, for example, we had done the following call on the above array:
  my $hash = $array->hash('size', 'code'};
  
We would then get the following hash:

  $hash = {
  	large =>  {
                US=> bless ([{code=>'US', name=>'United States', size=>'large'}, 'Data::HashArray')
                },
   	medium => {
                 FR=> bless ([{code=>'FR', name=>'France', size=>'medium'}], 'Data::HashArray'),
                 TR=> bless ([{code=>'TR', name=>'Turkey', size=>'medium'}], 'Data::HashArrayy')
                 }
   };

Note that the last level of the hierarachy is always a HashArray of hashes. This is done to accomodate the case
where more then one item can have the same key.

Note that the arguments to this method could also be CODE references. In that case, the CODE is executed for each item
in the array, passing the item reference as the first argument to the CODE refernce. The code BLOCK should return the expected
key value for the item. 

For example, the following are equivalent:

  my $h = $array->hash('size')						# Concrete example. Hash on 'size'.  
  my $h = $array->hash(sub { shift->{'size'}; })	# Same as above, but with a CODE reference passed as an argument.
	

.

=head1 BUGS & CAVEATS

There no known bugs at this time, but this doesn't mean there are aren't any. 
Use it at your own risk.

Note that there may be other bugs or limitations that the author is not aware of.

=head1 AUTHOR

Ayhan Ulusoy <dev@ulusoy.name>


=head1 COPYRIGHT

  Copyright (C) 2006-2008 Ayhan Ulusoy. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 DISCLAIMER

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, 
THERE IS NO WARRANTY FOR THE SOFTWARE, 
TO THE EXTENT PERMITTED BY APPLICABLE LAW. 
EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE 
THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, 
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, 
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. 
THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. 
SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING 
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE 
AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, 
SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE 
(INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY 
YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), 
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.



=cut
