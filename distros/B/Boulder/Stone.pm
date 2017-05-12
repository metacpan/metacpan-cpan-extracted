# ----------------- Stone ---------------
# This is basic unit of the boulder stream, and defines a
# multi-valued hash array type of structure.

package Stone;
use strict;
use vars qw($VERSION $AUTOLOAD $Fetchlast);
use overload  '""' => 'toString',
	      'fallback' =>' TRUE';

$VERSION = '1.15';
require 5.004;

=head1 NAME

Stone - In-memory storage for hierarchical tag/value data structures

=head1 SYNOPSIS

 use Stone;
 my $stone = Stone->new( Jim => { First_name => 'James',
				  Last_name  => 'Hill',
				  Age        => 34,
				  Address    => {
					 Street => ['The Manse',
						    '19 Chestnut Ln'],
					 City  => 'Garden City',
					 State => 'NY',
					 Zip   => 11291 }
				},
			  Sally => { First_name => 'Sarah',
				     Last_name  => 'James',
				     Age        => 30,
				     Address    => {
					 Street => 'Hickory Street',
					 City  => 'Katonah',
					 State => 'NY',
					 Zip  => 10578 }
				}
			 );

 @tags    = $stone->tags;          # yields ('James','Sally');
 $address = $stone->Jim->Address;  # gets the address subtree
 @street  = $address->Street;      # yeilds ('The Manse','19 Chestnut Ln')

 $address = $stone->get('Jim')->get('Address'); # same as $stone->Jim->Address
 $address = $stone->get('Jim.Address'); # another way to express same thing

 # first Street tag in Jim's address
 $address = $stone->get('Jim.Address.Street[0]'); 
 # second Street tag in Jim's address
 $address = $stone->get('Jim.Address.Street[1]'); 
 # last Street tag in Jim's address
 $address = $stone->get('Jim.Address.Street[#]'); 

 # insert a tag/value pair
 $stone->insert(Martha => { First_name => 'Martha', Last_name => 'Steward'} );

 # find the first Address
 $stone->search('Address'); 

 # change an existing subtree
 $martha = $stone->Martha;
 $martha->replace(Last_name => 'Stewart');  # replace a value

 # iterate over the tree with a cursor
 $cursor = $stone->cursor;
 while (my ($key,$value) = $cursor->each) {
   print "$value: Go Bluejays!\n" if $key eq 'State' and $value eq 'Katonah';
 }

 # various format conversions
 print $stone->asTable;
 print $stone->asString;
 print $stone->asHTML;
 print $stone->asXML('Person');

=head1 DESCRIPTION

A L<Stone> consists of a series of tag/value pairs.  Any given tag may
be single-valued or multivalued.  A value can be another Stone,
allowing nested components.  A big Stone can be made up of a lot of
little stones (pebbles?).  You can obtain a Stone from a
L<Boulder::Stream> or L<Boulder::Store> persistent database.
Alternatively you can build your own Stones bit by bit.

Stones can be exported into string, XML and HTML representations.  In
addition, they are flattened into a linearized representation when
reading from or writing to a L<Boulder::Stream> or one of its
descendents.

L<Stone> was designed for subclassing.  You should be able to create
subclasses which create or require particular tags and data formats.
Currently only L<Stone::GB_Sequence> subclasses L<Stone>.

=head1 CONSTRUCTORS

Stones are either created by calling the new() method, or by reading
them from a L<Boulder::Stream> or persistent database.

=head2 $stone = Stone->new()

This is the main constructor for the Stone class.  It can be called
without any parameters, in which case it creates an empty Stone object
(no tags or values), or it may passed an associative array in order to
initialize it with a set of tags.  A tag's value may be a scalar, an
anonymous array reference (constructed using [] brackets), or a hash
references (constructed using {} brackets).  In the first case, the
tag will be single-valued.  In the second, the tag will be
multivalued. In the third case, a subsidiary Stone will be generated
automatically and placed into the tree at the specified location.

Examples:

	$myStone = new Stone;
	$myStone = new Stone(Name=>'Fred',Age=>30);
	$myStone = new Stone(Name=>'Fred',
                             Friend=>['Jill','John','Jerry']);
	$myStone = new Stone(Name=>'Fred',
                             Friend=>['Jill',
				      'John',
			              'Gerald'
				      ],
			     Attributes => { Hair => 'blonde',
			                     Eyes => 'blue' }
                             );

In the last example, a Stone with the following structure is created:

 Name        Fred
 Friend      Jill
 Friend      John
 Friend      Gerald
 Attributes  Eyes    blue
             Hair    blonde

Note that the value corresponding to the tag "Attributes" is itself a
Stone with two tags, "Eyes" and "Hair".

The XML representation (which could be created with asXML()) looks like this:

 <?xml version="1.0" standalone="yes"?>
 <Stone>
    <Attributes>
       <Eyes>blue</Eyes>
       <Hair>blonde</Hair>
    </Attributes>
    <Friend>Jill</Friend>
    <Friend>John</Friend>
    <Friend>Gerald</Friend>
    <Name>Fred</Name>
 </Stone>

More information on Stone initialization is given in the description
of the insert() method.

=head1 OBJECT METHODS

Once a Stone object is created or retrieved, you can manipulate it
with the following methods.

=head2 $stone->insert(%hash)

=head2 $stone->insert(\%hash)

This is the main method for adding tags to a Stone.  This method
expects an associative array as an argument or a reference to one.
The contents of the associative array will be inserted into the Stone.
If a particular tag is already present in the Stone, the tag's current
value will be appended to the list of values for that tag.  Several
types of values are legal:

=over 4

=item * A B<scalar> value

The value will be inserted into the C<Stone>.

	$stone->insert(name=>Fred,
	               age=>30,
	               sex=>M);
	$stone->dump;
	
	name[0]=Fred
	age[0]=30
	sex[0]=M

=item * An B<ARRAY> reference

A multi-valued tag will be created:

	$stone->insert(name=>Fred,
		       children=>[Tom,Mary,Angelique]);
	$stone->dump;
	
	name[0]=Fred
	children[0]=Tom
	children[1]=Mary
	children[2]=Angelique

=item * A B<HASH> reference

A subsidiary C<Stone> object will be created and inserted into the 
object as a nested structure.

	$stone->insert(name=>Fred,
                       wife=>{name=>Agnes,age=>40});
	$stone->dump;

	name[0]=Fred
	wife[0].name[0]=Agnes
	wife[0].age[0]=40

=item * A C<Stone> object or subclass

The C<Stone> object will be inserted into the object as a nested
structure.

	$wife = new Stone(name=>agnes,
                          age=>40);
	$husband = new Stone;
	$husband->insert(name=>fred,
                         wife=>$wife);
	$husband->dump;
	
	name[0]=fred
	wife[0].name[0]=agnes
	wife[0].age[0]=40

=back

=head2 $stone->replace(%hash)

=head2 $stone->replace(\%hash)

The B<replace()> method behaves exactly like C<insert()> with the
exception that if the indicated key already exists in the B<Stone>,
its value will be replaced.  Use B<replace()> when you want to enforce
a single-valued tag/value relationship.

=head2 $stone->insert_list($key,@list)
=head2 $stone->insert_hash($key,%hash)
=head2 $stone->replace_list($key,@list)
=head2 $stone->replace_hash($key,%hash)

These are primitives used by the C<insert()> and C<replace()> methods.
Override them if you need to modify the default behavior.

=head2 $stone->delete($tag)

This removes the indicated tag from the Stone.

=head2 @values = $stone->get($tag [,$index])

This returns the value at the indicated tag and optional index.  What
you get depends on whether it is called in a scalar or list context.
In a list context, you will receive all the values for that tag.  You
may receive a list of scalar values or (for a nested record) or a list
of Stone objects. If called in a scalar context, you will either
receive the first or the last member of the list of values assigned to
the tag.  Which one you receive depends on the value of the package
variable C<$Stone::Fetchlast>.  If undefined, you will receive the
first member of the list. If nonzero, you will receive the last
member.

You may provide an optional index in order to force get() to return a
particular member of the list.  Provide a 0 to return the first member
of the list, or '#' to obtain the last member.

If the tag contains a period (.), get() will call index() on your
behalf (see below).

If the tag begins with an uppercase letter, then you can use the
autogenerated method to access it:

  $stone->Tag_name([$index])

This is exactly equivalent to:

  $stone->get('Teg_name' [,$index])

=head2 @values = $stone->search($tag)

Searches for the first occurrence of the tag, traversing the tree in a
breadth-first manner, and returns it.  This allows you to retrieve the 
value of a tag in a deeply nested structure without worrying about all 
the intermediate nodes.  For example:

 $myStone = new Stone(Name=>'Fred',
	 	      Friend=>['Jill',
			       'John',
			       'Gerald'
			      ],
		      Attributes => { Hair => 'blonde',
				      Eyes => 'blue' }
		    );

   $hair_colour = $stone->search('Hair');

The disadvantage of this is that if there is a tag named "Hair" higher
in the hierarchy, this tag will be retrieved rather than the lower
one.  In an array context this method returns the complete list of
values from the matching tag.  In a scalar context, it returns either
the first or the last value of multivalued tags depending as usual on
the value of C<$Stone::Fetchlast>.

C<$Stone::Fetchlast> is also consulted during the depth-first
traversal.  If C<$Fetchlast> is set to a true value, multivalued
intermediate tags will be searched from the last to the first rather
than the first to the last.

The Stone object has an AUTOLOAD method that invokes get() when you
call a method that is not predefined.  This allows a very convenient
type of shortcut:

  $name        = $stone->Name;
  @friends     = $stone->Friend;
  $eye_color   = $stone->Attributes->Eyes

In the first example, we retrieve the value of the top-level tag Name.
In the second example, we retrieve the value of the Friend tag..  In
the third example, we retrieve the attributes stone first, then the
Eyes value.

NOTE: By convention, methods are only autogenerated for tags that
begin with capital letters.  This is necessary to avoid conflict with
hard-coded methods, all of which are lower case.

=head2 @values = $stone->index($indexstr)

You can access the contents of even deeply-nested B<Stone> objects
with the C<index> method.  You provide a B<tag path>, and receive 
a value or list of values back.

Tag paths look like this:

	tag1[index1].tag2[index2].tag3[index3]

Numbers in square brackets indicate which member of a multivalued tag
you're interested in getting.  You can leave the square brackets out
in order to return just the first or the last tag of that name, in a scalar
context (depending on the setting of B<$Stone::Fetchlast>).  In an
array context, leaving the square brackets out will return B<all>
multivalued members for each tag along the path.

You will get a scalar value in a scalar context and an array value in
an array context following the same rules as B<get()>.  You can
provide an index of '#' in order to get the last member of a list or 
a [?] to obtain a randomly chosen member of the list (this uses the rand() call,
so be sure to call srand() at the beginning of your program in order
to get different sequences of pseudorandom numbers.  If
there is no tag by that name, you will receive undef or an empty list.
If the tag points to a subrecord, you will receive a B<Stone> object.

Examples:

	# Here's what the data structure looks like.
	$s->insert(person=>{name=>Fred,
			    age=>30,
			    pets=>[Fido,Rex,Lassie],
			    children=>[Tom,Mary]},
		   person=>{name=>Harry,
			    age=>23,
			    pets=>[Rover,Spot]});

	# Return all of Fred's children
	@children = $s->index('person[0].children');

	# Return Harry's last pet
	$pet = $s->index('person[1].pets[#]');

	# Return first person's first child
	$child = $s->index('person.children');

	# Return children of all person's
	@children = $s->index('person.children');

	# Return last person's last pet
	$Stone::Fetchlast++;
	$pet = $s->index('person.pets');

	# Return any pet from any person
	$pet = $s->index('person[?].pet[?]');

I<Note> that B<index()> may return a B<Stone> object if the tag path
points to a subrecord.

=head2 $array = $stone->at($tag)

This returns an ARRAY REFERENCE for the tag.  It is useful to prevent
automatic dereferencing.  Use with care.  It is equivalent to:

	$stone->{'tag'}

at() will always return an array reference.  Single-valued tags will
return a reference to an array of size 1.

=head2 @tags = $stone->tags()

Return all the tags in the Stone.  You can then use this list with
get() to retrieve values or recursively traverse the stone.

=head2 $string = $stone->asTable()

Return the data structure as a tab-delimited table suitable for
printing.

=head2 $string = $stone->asXML([$tagname])

Return the data structure in XML format.  The entire data structure
will be placed inside a top-level tag called <Stone>.  If you wish to
change this top-level tag, pass it as an argument to asXML().

An example follows:

 print $stone->asXML('Address_list');
 # yields:
 <?xml version="1.0" standalone="yes"?>

 <Address_list>
    <Sally>
       <Address>
          <Zip>10578</Zip>
          <City>Katonah</City>
          <Street>Hickory Street</Street>
          <State>NY</State>
       </Address>
       <Last_name>Smith</Last_name>
       <Age>30</Age>
       <First_name>Sarah</First_name>
    </Sally>
    <Jim>
       <Address>
          <Zip>11291</Zip>
          <City>Garden City</City>
          <Street>The Manse</Street>
          <Street>19 Chestnut Ln</Street>
          <State>NY</State>
       </Address>
       <Last_name>Hill</Last_name>
       <Age>34</Age>
       <First_name>James</First_name>
    </Jim>
 </Address_list>

=head2 $hash = $stone->attributes([$att_name, [$att_value]]])

attributes() returns the "attributes" of a tag.  Attributes are a
series of unique tag/value pairs which are associated with a tag, but
are not contained within it.  Attributes can only be expressed in the
XML representation of a Stone:

   <Sally id="sally_tate" version="2.0">
     <Address type="postal">
          <Zip>10578</Zip>
          <City>Katonah</City>
          <Street>Hickory Street</Street>
          <State>NY</State>
       </Address>
   </Sally>

Called with no arguments, attributes() returns the current attributes
as a hash ref:

    my $att = $stone->Address->attributes;
    my $type = $att->{type};

Called with a single argument, attributes() returns the value of the
named attribute, or undef if not defined:

    my $type = $stone->Address->attributes('type');

Called with two arguments, attributes() sets the named attribute:

    my $type = $stone->Address->attributes(type => 'Rural Free Delivery');

You may also change all attributes in one fell swoop by passing a hash
reference as the single argument:

    $stone->attributes({id=>'Sally Mae',version=>'2.1'});

=head2 $string = $stone->toString()

toString() returns a simple version of the Stone that shows just the
topmost tags and the number of each type of tag.  For example:

  print $stone->Jim->Address;
      #yields => Zip(1),City(1),Street(2),State(1)

This method is used internally for string interpolation.  If you try
to print or otherwise manipulate a Stone object as a string, you will
obtain this type of string as a result.

=head2 $string = $stone->asHTML([\&callback])

Return the data structure as a nicely-formatted HTML 3.2 table,
suitable for display in a Web browser.  You may pass this method a
callback routine which will be called for every tag/value pair in the
object.  It will be passed a two-item list containing the current tag
and value.  It can make any modifications it likes and return the
modified tag and value as a return result.  You can use this to modify
tags or values on the fly, for example to turn them into HTML links.

For example, this code fragment will turn all tags named "Sequence"
blue:

  my $callback = sub {
        my ($tag,$value) = @_;
	return ($tag,$value) unless $tag eq 'Sequence';
	return ( qq(<FONT COLOR="blue">$tag</FONT>),$value );
  }
  print $stone->asHTML($callback);

=head2 Stone::dump()

This is a debugging tool.  It iterates through the B<Stone> object and
prints out all the tags and values.

Example:

	$s->dump;
	
	person[0].children[0]=Tom
	person[0].children[1]=Mary
	person[0].name[0]=Fred
	person[0].pets[0]=Fido
	person[0].pets[1]=Rex
	person[0].pets[2]=Lassie
	person[0].age[0]=30
	person[1].name[0]=Harry
	person[1].pets[0]=Rover
	person[1].pets[1]=Spot
	person[1].age[0]=23

=head2 $cursor = $stone->cursor()

Retrieves an iterator over the object.  You can call this several
times in order to return independent iterators. The following brief
example is described in more detail in L<Stone::Cursor>.

 my $curs = $stone->cursor;
 while (my($tag,$value) = $curs->next_pair) {
   print "$tag => $value\n";
 }
 # yields:
   Sally[0].Address[0].Zip[0] => 10578
   Sally[0].Address[0].City[0] => Katonah
   Sally[0].Address[0].Street[0] => Hickory Street
   Sally[0].Address[0].State[0] => NY
   Sally[0].Last_name[0] => James
   Sally[0].Age[0] => 30
   Sally[0].First_name[0] => Sarah
   Jim[0].Address[0].Zip[0] => 11291
   Jim[0].Address[0].City[0] => Garden City
   Jim[0].Address[0].Street[0] => The Manse
   Jim[0].Address[0].Street[1] => 19 Chestnut Ln
   Jim[0].Address[0].State[0] => NY
   Jim[0].Last_name[0] => Hill
   Jim[0].Age[0] => 34
   Jim[0].First_name[0] => James

=head1 AUTHOR

Lincoln D. Stein <lstein@cshl.org>.

=head1 COPYRIGHT

Copyright 1997-1999, Cold Spring Harbor Laboratory, Cold Spring Harbor
NY.  This module can be used and distributed on the same terms as Perl
itself.

=head1 SEE ALSO

L<Boulder::Blast>, L<Boulder::Genbank>, L<Boulder::Medline>, L<Boulder::Unigene>,
L<Boulder::Omim>, L<Boulder::SwissProt>

=cut

use Stone::Cursor;
use Carp;
use constant DEFAULT_WIDTH=>25;  # column width for pretty-printing

# This global controls whether you will get the first or the
# last member of a multi-valued attribute when you invoke
# get() in a scalar context.
$Stone::Fetchlast=0;	

sub AUTOLOAD {
  my($pack,$func_name) = $AUTOLOAD=~/(.+)::([^:]+)$/;
  my $self = shift;
  croak "Can't locate object method \"$func_name\" via package \"$pack\". ",
  "Tag names must begin with a capital letter in order to be called this way"
    unless $func_name =~ /^[A-Z]/;
  return $self->get($func_name,@_);
}

# Create a new Stone object, filling it with the
# provided tag/value pairs, if any
sub new {
    my($pack,%initial_values) = @_;
    my($self) = bless {},$pack;
    $self->insert(%initial_values) if %initial_values;
    return $self;
}

# Insert the key->value pairs into the Stone object,
# appending to any similarly-named keys that were there before.
sub insert {
    my($self,@arg) = @_;

    my %hash;
    if (ref $arg[0] and ref $arg[0] eq 'HASH') {
      %hash = %{$arg[0]};
    } else {
      %hash = @arg;
    }

    foreach (keys %hash) {
	$self->insert_list($_,$hash{$_});
    }
}

# Add the key->value pairs to the Stone object,
# replacing any similarly-named keys that were there before.
sub replace {
    my($self,@arg) = @_;

    my %hash;
    if (ref $arg[0] and ref $arg[0] eq 'HASH') {
      %hash = %{$arg[0]};
    } else {
      %hash = @arg;
    }
    
    foreach (keys %hash) {
	$self->replace_list($_,$hash{$_});
    }
}

# Fetch the value at the specified key.  In an array
# context, this will return the  entire array.  In a scalar
# context, this will return either the first or the last member
# of the array, depending on the value of the global Fetchlast.
# You can specify an optional index to index into the resultant
# array.
# Codes:
#    digit (12)        returns the 12th item
#    hash sign (#)     returns the last item
#    question mark (?) returns a random item
#    zero (0)          returns the first item
sub get {
    my($self,$key,$index) = @_;
    return $self->index($key) if $key=~/[.\[\]]/;

    $index = '' unless defined $index;
    return $self->get_last($key) if $index eq '#' || $index == -1 ;
    if ($index eq '?') {
	my $size = scalar(@{$self->{$key}});
	return $self->{$key}->[rand($size)];
    }
    return $self->{$key}->[$index] if $index ne '';

    if (wantarray) {
      return @{$self->{$key}} if $self->{$key};
      return my(@empty);
    }
    return $self->get_first($key) unless $Fetchlast;
    return $self->get_last($key);
}

# Returns 1 if the key exists.
sub exists {
    my($self,$key,$index) = @_;
    return 1 if defined($self->{$key}) && !$index;
    return 1 if defined($self->{$key}->[$index]);
    return undef;
}

# return an array reference at indicated tag.
# Equivalent to $stone->{'tag'}
sub at {
    my $self = shift;
    return $self->{$_[0]};
}
				# 
# Delete the indicated key entirely.
sub delete {
    my($self,$key) = @_;
    delete $self->{$key};
    $self->_fix_cursors;
}

# Return all the tags in the stone.
sub tags {
  my $self = shift;
  return grep (!/^\./,keys %{$self});
}

# Return attributes as a hash reference
# (only used by asXML)
sub attributes {
  my $self = shift;
  my ($tag,$value) = @_;
  if (defined $tag) {
    return $self->{'.att'} = $tag if ref $tag eq 'HASH';
    return $self->{'.att'}{$tag} = $value if defined $value;
    return $self->{'.att'}{$tag};
  } 
  return $self->{'.att'} ||= {};
}


# Fetch an Iterator on the Stone.
sub cursor {
    my $self = shift;
    return new Stone::Cursor($self);
}

# Convert a stone into a straight hash
sub to_hash {
    my ($self) = shift;
    my ($key,%result);
    foreach $key (keys %$self) {
	next if substr($key,0,1) eq '.';
	my ($value,@values);
	foreach $value (@{$self->{$key}}) {
	    push(@values,ref($value) ? { $value->to_hash() } : $value);
	}
	$result{$key} = @values > 1 ? [@values] : $values[0];
    }
    return %result;
}

# Search for a particular tag and return it using a breadth-first search
sub search {
  my ($self,$tag) = @_;
  return $self->get($tag) if $self->{$tag};
  foreach ($self->tags()) {
    my @objects = $self->get($_);
    @objects = reverse(@objects) if $Fetchlast;
    foreach my $obj (@objects) {
      next unless ref($obj) and $obj->isa('Stone');
      my @result = $obj->search($tag);
      return wantarray ? @result : ($Fetchlast ? $result[$#result] : $result[0]);
    }
  }
  return wantarray ? () : undef;
}

# Extended indexing, using a compound index that
# looks like:
# key1[index].key2[index].key3[index]
# If indices are left out, then you can get
# multiple values out:
# 1. In a scalar context, you'll get the first or last
#      value from each position.
# 2. In an array context, you'll get all the values!
sub index {
    my($self,$index) = @_;
    return &_index($self,split(/\./,$index));
}

sub _index {
    my($self,@indices) = @_;
    my(@value,$key,$position,$i);
    my(@results);
    $i = shift @indices;

    if (($key,$position) = $i=~/(.+)\[([\d\#\?]+)\]/) { # has a position
	@value = $self->get($key,$position); # always a scalar
    } elsif (wantarray) {
	@value = $self->get($i);
    } else {
	@value = scalar($self->get($i));
    }
    
    foreach (@value) {
	if (@indices) {
	    push @results,&_index($_,@indices) if $_->isa('Stone') && !exists($_->{'.name'});
	} else{
	    push @results,$_;
	}
    }
    return wantarray ? @results : $results[0];
}

# Return the data structure as a nicely-formatted tab-delimited table
sub asTable {
  my $self = shift;
  my $string = '';
  $self->_asTable(\$string,0,0);
  return $string;
}

# Return the data structure as a nice string representation (problematic)
sub asString {
  my $self = shift;
  my $MAXWIDTH = shift || DEFAULT_WIDTH;
  my $tabs = $self->asTable;
  return '' unless $tabs;
  my(@lines) = split("\n",$tabs);
  my($result,@max);
  foreach (@lines) {
    my(@fields) = split("\t");
    for (my $i=0;$i<@fields;$i++) {
      $max[$i] = length($fields[$i]) if
	!defined($max[$i]) or $max[$i] < length($fields[$i]);
    }
  }
  foreach (@max) { $_ = $MAXWIDTH if $_ > $MAXWIDTH; } # crunch long lines
  my $format1 = join(' ',map { "^"."<"x $max[$_] } (0..$#max)) . "\n";
  my $format2 =   ' ' . join('  ',map { "^"."<"x ($max[$_]-1) } (0..$#max)) . "~~\n";
  $^A = '';
  foreach (@lines) {
    my @data = split("\t");
    push(@data,('')x(@max-@data));
    formline ($format1,@data);
    formline ($format2,@data);
  }
  return ($result = $^A,$^A='')[0];
}

# Return the data structure as an HTML table
sub asHTML {
  my $self = shift;
  my $modify = shift;
  $modify ||= \&_default_modify_html;
  my $string = "<TABLE BORDER>\n";
  $self->_asHTML(\$string,$modify,0,0);
  $string .= "</TR>\n</TABLE>";
  return $string;
}

# Return data structure using XML syntax
# Top-level tag is <Stone> unless otherwise specified
sub asXML {
  my $self = shift;
  my $top = shift || "Stone";
  my $modify = shift || \&_default_modify_xml;
  my $att;
  if (exists($self->{'.att'})) {
    my $a = $self->attributes;
    foreach (keys %$a) {
      $att .= qq( $_="$a->{$_}");
    }
  }
  my $string = "<${top}${att}>\n";
  $self->_asXML(\$string,$modify,0,1);
  $string .="</$top>\n";
  return $string;
}

# This is the method used for string interpolation
sub toString {
  my $self = shift;
  return $self->{'.name'} if exists $self->{'.name'};
  my @tags = map {  my @v = $self->get($_);
		    my $cnt = scalar @v;
		    "$_($cnt)" 
		  }  $self->tags;
  return '<empty>' unless @tags;
  return join ',',@tags;
}


sub _asTable {
  my $self = shift;
  my ($string,$position,$level) = @_;
  my $pos = $position;
  foreach my $tag ($self->tags) {
    my @values = $self->get($tag);
    foreach my $value (@values) {
      $$string .= "\t" x ($level-$pos) . "$tag\t";
      $pos = $level+1;
      if (exists $value->{'.name'}) {
	$$string .= "\t" x ($level-$pos+1) . "$value\n";
	$pos=0;
      } else {
	$pos = $value->_asTable($string,$pos,$level+1);
      }
    }
  }
  return $pos;
}

sub _asXML {
  my $self = shift;
  my ($string,$modify,$pos,$level) = @_;
  foreach my $tag ($self->tags) {
    my @values     = $self->get($tag);
    foreach my $value (@values) {
      my($title,$contents) = $modify ? $modify->($tag,$value) : ($tag,$value);
      my $att;

      if (exists $value->{'.att'}) {
	my $a = $value->{'.att'};
	foreach (keys %$a) {
	  $att .= qq( $_="$a->{$_}");
	}
      }

      $$string .= '   ' x ($level-$pos) . "<${title}${att}>";
      $pos = $level+1;

      if (exists $value->{'.name'}) {
	$$string .= '   ' x ($level-$pos+1) . "$contents</$title>\n";
	$pos=0;
      } else {
	$$string .= "\n" . '   ' x ($level+1);
	$pos = $value->_asXML($string,$modify,$pos,$level+1);
	$$string .= '   ' x ($level-$pos) . "</$title>\n";
      } 
    }
  }
  return $pos;
}

sub _asHTML {
  my $self = shift;
  my ($string,$modify,$position,$level) = @_;
  my $pos = $position;
  foreach my $tag ($self->tags) {
    my @values = $self->get($tag);
    foreach my $value (@values) {
      my($title,$contents) = $modify->($tag,$value);
      $$string .= "<TR ALIGN=LEFT VALIGN=TOP>" unless $position;
      $$string .= "<TD></TD>" x ($level-$pos) . "<TD ALIGN=LEFT VALIGN=TOP>$title</TD>";
      $pos = $level+1;
      if (exists $value->{'.name'}) {
	$$string .= "<TD></TD>" x ($level-$pos+1) . "<TD ALIGN=LEFT VALIGN=TOP>$contents</TD></TR>\n";
	$pos=0;
      } else {
	$pos = $value->_asHTML($string,$modify,$pos,$level+1);
      }
    }
  }

  return $pos;
}

sub _default_modify_html {
  my ($tag,$value) = @_;
  return ("<B>$tag</B>",$value);
}

sub _default_modify_xml {
  my ($tag,$value) = @_;
  $value =~ s/&/&amp;/g;
  $value =~ s/>/&gt;/g;
  $value =~ s/</&lt;/g;
  ($tag,$value);
}

# Dump the entire data structure, for debugging purposes
sub dump {
    my($self) = shift;
    my $i = $self->cursor;
    my ($key,$value);
    while (($key,$value)=$i->each) {
	print "$key=$value\n";
    }
    # this has to be done explicitly here or it won't happen.
    $i->DESTROY;		
}

# return the name of the Stone
sub name { 
  $_[0]->{'.name'} = $_[1] if defined $_[1];
  return $_[0]->{'.name'} 
}


# --------- LOW LEVEL DATA INSERTION ROUTINES ---------
# Append a set of values to the key.
# One or more values may be other Stones.
# You can pass the same value multiple times
# to enter multiple values, or alternatively
# pass an anonymous array.
sub insert_list {
    my($self,$key,@values) = @_;

    foreach (@values) {
	my $ref = ref($_);

	if (!$ref) {  # Inserting a scalar
	  my $s = new Stone;
	  $s->{'.name'} = $_;
	  push(@{$self->{$key}},$s);
	  next;
	}

	if ($ref=~/Stone/) {	# A simple insertion
	    push(@{$self->{$key}},$_);
	    next;
	}

	if ($ref eq 'ARRAY') {	# A multivalued insertion
	    $self->insert_list($key,@{$_}); # Recursive insertion
	    next;
	}
	
	if ($ref eq 'HASH') {	# Insert a record, potentially recursively
	    $self->insert_hash($key,%{$_});
	    next;
	}

	warn "Attempting to insert a $ref into a Stone. Be alert.\n";
	push(@{$self->{$key}},$_);

    }
    $self->_fix_cursors;
}

# Put the values into the key, replacing
# whatever was there before.
sub replace_list {
    my($self,$key,@values) = @_;
    $self->{$key}=[];		# clear it out
    $self->insert_list($key,@values); # append the values
}

# Similar to put_record, but doesn't overwrite the
# previous value of the key.
sub insert_hash {
    my($self,$key,%values) = @_;
    my($newrecord) = $self->new_record($key);
    foreach (keys %values) {
	$newrecord->insert_list($_,$values{$_});
    }
}

# Put a new associative array at the indicated key,
# replacing whatever was there before.  Multiple values
# can be represented with an anonymous ARRAY reference.
sub replace_hash {
    my($self,$key,%values) = @_;
    $self->{$key}=[];		# clear it out
    $self->insert_hash($key,%values);
}

#------------------- PRIVATE SUBROUTINES-----------
# Create a new record at indicated key
# and return it.
sub new_record {
    my($self,$key) = @_;
    my $stone = new Stone();
    push(@{$self->{$key}},$stone);
    return $stone;
}

sub get_first {
    my($self,$key) = @_;
    return $self->{$key}->[0];
}

sub get_last {
    my($self,$key) = @_;
    return $self->{$key}->[$#{$self->{$key}}];
}

# This is a private subroutine used for registering
# and unregistering cursors
sub _register_cursor {
    my($self,$cursor,$register) = @_;
    if ($register) {
	$self->{'.cursors'}->{$cursor}=$cursor;
    } else {
	delete $self->{'.cursors'}->{$cursor};
	delete $self->{'.cursors'} unless %{$self->{'.cursors'}};
    }
}

# This is a private subroutine used to alert cursors that
# our contents have changed.
sub _fix_cursors {
    my($self) = @_;
    return unless $self->{'.cursors'};
    my($cursor); 
    foreach $cursor (values %{$self->{'.cursors'}}) {
	$cursor->reset;
    }
}

# This is a private subroutine.  It indexes
# all the way into the structure.
#sub _index {
#    my($self,@indices) = @_;
#    my $stone = $self;
#    my($key,$index,@h);
#    while (($key,$index) = splice(@indices,0,2)) {
#	unless (defined($index)) {
#	    return scalar($stone->get($key)) unless wantarray;
#	    return @h = $stone->get($key) if wantarray;
#	} else {
#	    $stone= ($index eq "\#") ? $stone->get_last($key):
#		     $stone->get($key,$index);
#	    last unless ref($stone)=~/Stone/;
#	}
#    }
#    return $stone;
#}

sub DESTROY {
    my $self = shift;
    undef %{$self->{'.cursor'}};  # not really necessary ?
}


1;
