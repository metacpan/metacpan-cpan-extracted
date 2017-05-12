package Class::XML;

$VERSION = "0.06";

use strict;
use warnings;
use vars qw/$VERSION/;
use Carp;
use XML::XPath;
use XML::XPath::XMLParser;
use base qw/
  XML::XPath::Node::Element
  Class::Accessor
  Class::Data::Inheritable
  /;

use XML::XPath::Node ':node_keys';

use overload '""' => \&XML::XPath::XMLParser::as_string;

sub DEBUG { 0; };
#sub DEBUG { 1; };

sub _classdata_hashref {
  my ($package, $name) = @_;
  $package->mk_classdata($name);
  $package->$name({});
}

__PACKAGE__->_classdata_hashref('__group_types');

sub _add_hash_plural {
  my ($package, $meth) = @_;
  no strict 'refs';
  *{"${package}::${meth}s"} =
    sub {
      my ($package, %hash) = @_;
      while (my @pair = each %hash) {
        $package->$meth(@pair);
      }
    }
}

sub _add_group_type {
  my ($package, $type, $hash) = @_;
  $package->__group_types()->{$type} = $hash;
  $package->_classdata_hashref("__${type}");
  $package->_add_has($type);
}

__PACKAGE__->_add_hash_plural('_add_group_type');

sub has_attributes {
  my ($package) = @_;
  foreach (@_[1..$#_]) {
    $package->has_attribute($_);
  }
}

__PACKAGE__->_add_group_types(
  'attribute' => {
    'get' => 'getAttribute',
    'set' => 'setAttribute',
    'delete' => 'removeAttribute',
    },
  'parent' => {
    'get' => '_get_parent',
    'set' => '_croak_ro',
    'delete' => '_croak_ro',
    },
  'child' => {
    'get' => '_get_child',
    'set' => '_set_child',
    'delete' => '_delete_child',
    },
  'children' => {
    'get' => '_get_children',
    'set' => '_set_children',
    'delete' => '_set_children',
    },
  'relation' => {
    'get' => '_get_relation',
    'set' => '_get_relation',
    'delete' => '_croak_ro',
    },
  );

sub element_name {
  my ($self, $name) = @_;
  if (defined $name) {
    $self->__element_name($name);
  } else {
    return $self->__element_name || $self->_default_element_name;
  }
}

__PACKAGE__->mk_classdata('__element_name');

sub _default_element_name {
  my ($self) = @_;
  my $package = ref $self || $self;
  $package =~ s/.*:://;
  return $package;
}

sub _add_has {
  my ($package, $has) = @_;
  no strict 'refs';
  my $meth = "has_${has}";
  my $classdata = "__${has}";
  *{"${package}::${meth}"} =
    sub {
      my ($package, $name, $class) = @_;
      $package->mk_accessors($name);
      my @attrs = %{$package->$classdata()};
      $package->$classdata({ @attrs, $name, $class });
    };
}

sub _get_parent {
  my ($self, $key, $class) = @_;
  my $node = $self->getParentNode;
  return cast($class, $node);
}

sub _get_child {
  my ($self, $key, $class) = @_;
  my ($child, @rest) = $self->_get_children(@_[1..$#_]);
  $self->_croak("Multiple ${key} children (".(1 + @rest).") found for"
                  ." has_child relation of ".ref($self)) if @rest;
  return $child;
}

sub _set_child {
  my ($self, $key, $class, $new) = @_;
  $self->_croak("New $key is not an XPath node")
    unless (ref $new && $new->isa("XML::XPath::Node"));
  $self->_croak("Incorrect node name ".$new->getName." (expected $key)")
    unless ($new->getName eq $key);
  my $old = $self->_get_child($key, $class);
  if ($old) {
    $self->_replace_child_node($old => $new);
  } else {
    $self->appendChild($new);
  }
}

sub _replace_child_node { # Should be replaceChild in XML::XPath really
  my ($self, $old, $new) = @_;
  $self->insertAfter($new, $old) if $new;
  $self->removeChild($old);
  #my $pos = $old->get_pos;
  #$new->set_pos($pos);
  #${$self}->[node_children]->[$pos] = $new;
  #$old->del_parent_link;
}

sub _get_children {
  my ($self, $key, $class) = @_;
  return map { cast($class, $_); }
          grep { $_->isElementNode && ($_->getName eq $key) }
            $self->getChildNodes;
}

sub _set_children {
  my ($self, $key, $class, @new) = @_;
  my @old = $self->_get_children(@_[1..$#_]);
  my $diff = @new - @old;
  my $least = ($diff >= 0 ? $#old : $#new);
  warn "Diff $diff, least $least, new $#new, old $#old" if DEBUG;
  for (0..$least) {
    $self->_replace_child_node($old[$_] => $new[$_]);
  }
  $least++;
  if ($diff > 0) {
    for ($least .. $#new) {
      $self->appendChild($new[$_]);
    }
  } elsif ($diff < 0) {
    for ($least .. $#old) {
      $self->removeChild($old[$_]);
    }
  }
}

sub _delete_child {
  my ($self, $key) = @_;
  foreach (grep { $_->isElementNode && ($_->getName eq $key) }
             $self->getChildNodes) {
    $self->removeChild($_);
  }
}

sub _get_relation {
  my ($self, $key, $spec, @args) = @_;
  my ($path, $class) = @$spec;
  $path = sprintf($path, @args);
  warn "$path -> $class" if DEBUG;
  return map { cast($class, $_); } ($self->findnodes($path));
}

sub new {
  my ($self, @opts) = @_;
  my %passthru;
  @passthru{qw(xml ioref filename parser)} = undef;
  if (@opts == 2 && exists $passthru{$opts[0]} && ref($opts[1]) ne 'HASH') {
    warn "Calling parse with @opts" if DEBUG;
    return $self->parse(@opts);
  } else {
    warn "Calling create with @opts" if DEBUG;
    return $self->create(@opts);
  }
}

sub create {
  my ($self, @opts) = @_;
  my @name = ($self->element_name);
  my $args;
  unless (@opts) {
    # Empty constructor, keep defaults
  } elsif (!ref $opts[0]) {
    @name = (shift @opts);
    if (!ref $opts[0]) {
      push(@name, shift @opts)
    }
  }
  $args = shift @opts;
  warn "Constructing name @name" if DEBUG;
  my $new = cast( $self, XML::XPath::Node::Element->new( @name ));
  if (ref $args eq 'HASH' || ref $args eq 'ARRAY') {
    my @construct = (ref $args eq 'HASH' ? %$args : @$args);
    while (my ($k, $v) = splice(@construct,0,2)) {
      if ($new->can($k)) {
        $new->$k($v);
      } else {
        $self->_croak("Constructor argument $k ($v) is not valid for "
                       .ref($new));
      }
      last unless @construct;
    }
  } 
  return $new;
}

sub parse {
  my $self = shift;
  my $parser = XML::XPath::XMLParser->new(@_);
  my ($root) = $parser->parse()->findnodes('/child::*');
  warn "Parsed root name ".$root->getName if DEBUG;
  #my $new = { _xpath_node => $root };
  cast( $self, $root );
}

sub _croak_ro {
  my ($self, $key) = @_;
  my $caller = caller;
  $self->_croak("'$caller' cannot alter the value of '${key}' on ".
    "objects of class '".ref($self)."'");
}

sub _croak {
  my ($self, $msg) = @_;
  Carp::croak($msg || $self);
}

sub get {
  my ($self, @keys) = @_;
  warn "Get called: @_" if DEBUG;
  if (@keys == 1) {
    return $self->_do_action("get", @keys);
  } else {
    return map { $self->get($_[0]) } @keys;
  }
}

sub set {
  my ($self, @data) = @_;
  my $action = ((defined $data[1]) ? 'set' : 'delete');
  $self->_do_action($action, @data);
}

sub _do_action {
  my ($self, $type, $key, @args) = @_;
  keys %{$self->__group_types}; # Reset hash iterator
  while (my ($k, $v) = each %{$self->__group_types}) {
    my $group = "__${k}";
    warn "Checking for $key in $group (".join(',',keys %{$self->$group()}).")"
     if DEBUG;
    next unless exists $self->$group()->{$key};
    my $meth = $v->{$type};
    warn "Found $key; calling $meth" if DEBUG;
    unshift(@args, $self->$group()->{$key}) if defined $self->$group()->{$key};
    return $self->$meth($key, @args);
  }
}

sub search_children {
  my ($self) = @_;
  my $xpath = $self->_gen_search_expr('./child::', @_[1..$#_]);
  my @results = $self->findnodes($xpath);
  NODE: foreach my $node (@results) {
    next NODE unless $node->isElementNode;
    my $name = $node->getName;
    my $class;
    GROUP: foreach my $group (qw/child children/) {
      my $meth = "__${group}";
      $class = $self->$meth()->{$name};
      last GROUP if defined $class;
    }
    next NODE unless defined $class;
    cast($class, $node);
  }
  return @results;
}

sub _gen_search_expr {
  my ($self, $axis, $name, $attrs) = @_;
  if (ref $name eq 'HASH') {
    $attrs = $name;
    undef $name;
  }
  $name ||= '*';
  my $xpath = "${axis}${name}";
  ATTRS: {
    if ($attrs) {
      my $count;
      eval { $count = keys %{$attrs}; };
      $self->_croak("Attributes for search_children must be a hashref!") if $@;
      last ATTRS unless $count;
      my @test;
      while (my ($k, $v) = each %{$attrs}) {
        $v =~ s/"/\"/g;
        push(@test, qq!\@${k} = "${v}"!);
      }
      $xpath .= '['.join(' and ', @test).']';
    }
  }
  return $xpath;
}

sub cast {
  my ($to, $obj) = @_;
  warn "Casting $obj (".(ref $obj).") to ".(ref $to || $to) if DEBUG;
  return $obj unless ref $obj;
  return $obj if (eval { $obj->isa(ref $to || $to) });
  unless (ref $to) {
    eval "use ${to};";
    Carp::croak $@ if $@;
  }
  if ($obj->isa('XML::XPath::NodeImpl')) {
    my $dummy = bless(\$obj, 'Class::XML::DummyLayer');
    return bless(\$dummy, ref $to || $to);
  }
  return bless($obj, ref $to || $to);
}

package Class::XML::DummyLayer;

use base qw/XML::XPath::Node::Element/;

sub DESTROY { }; # This should stop things getting GC'ed unexpectedly

=head1 NAME

Class::XML - Simple XML Abstraction

=head1 SYNOPSIS

  package Foo;

  use base qw/Class::XML/;

  __PACKAGE__->has_attributes(qw/length colour/);
  __PACKAGE__->has_child('bar' => Bar);

  package Bar;

  use base qw/Class::XML/;

  __PACKAGE__->has_parent('foo');
  __PACKAGE__->has_attribute('counter');

  # Meanwhile, in another piece of code -

  my $foo = Foo->new( xml =>           # Or filename or ioref or parser
    qq!<foo length="3m" colour="pink"><bar /></foo>! );

  $foo->length;                         # Returns "3m"
  $foo->colour("purple");               # Sets colour to purple

  print $foo;  # Outputs <foo length="3m" colour="purple"><bar /></foo>

  my $new_bar = new Bar;                # Creates empty Bar node

  $new_bar->counter("formica");
  
  $foo->bar($new_bar);                  # Replaces child

  $new_bar->foo->colour;                # Returns "purple"

  $foo->colour(undef);                  # Deletes colour attribute

  print $foo;  # Outputs <foo length="3m"><bar counter="formica" /></foo>

=head1 DESCRIPTION

Class::XML is designed to make it reasonably easy to create, consume or modify
XML from Perl while thinking in terms of Perl objects rather than the available
XML APIs; it was written out of a mixture of frustration that JAXB (for Java)
and XMLSerializer (for .Net) provided programming capabilities that simply
weren't easy to do in Perl with the existing modules, and the sheer pleasure
that I've had using Class::DBI.

The aim is to provide a convenient abstraction layer that allows you to put as
much of your logic as you like into methods on a class tree, then throw some
XML at that tree and get back a tree of objects to work with. It should also be
easy to get started with for anybody familiar with Class::DBI (although I
doubt you could simply switch them due to the impedance mismatch between XML
and relational data) and be pleasant to use from the Template Toolkit.

Finally, all Class::XML objects are also XML::XPath nodes so the full power of
XPath is available to you if Class::XML doesn't provide a shortcut to what
you're trying to do (but if you find it doesn't on a regular basis, contact me
and I'll see if I can fix that ;).

=head1 DETAILS

=head2 Setup

=head3 element_name

  __PACKAGE__->element_name('foo');

Sets/gets the default element name for this class. If you don't set it,
Class::XML defaults to the last component of the package name - so a class
Foo::Bar will by default create 'Bar' elements.

Note that his is *not* necessarily the element name of any given instance - you
can override this in the constructor or by calling the XML::XPath::Node::Element
setName method. But if you're doing that, presumably you know what you're doing
and why ...

=head3 has_attribute(s)

  __PACKAGE__->has_attribute('attr');
  or
  __PACKAGE__->has_attributes(qw/attr1 attr2 attr3/);

Creates accessor method(s) for the named attribute(s). Both can be called as
many times as you want and will add the specified attributes to the list. Note
that setting an attribute to the empty string does *not* delete it - to do that
you need to call

  $obj->attr( undef );

which will delete the attribute entirely from the object. There's nothing to
stop you calling the accessor again later to re-create it though.

=head2 Relationships

=head3 has_parent

  __PACKAGE__->has_parent('foo');

Creates a *read-only* accessor of the specified name that references an
instance's parent node in the XML document. Can be specified more than once if
you expect the class to be used as a child of more than one different element.

=head3 has_child

  __PACKAGE__->has_child('name' => 'Class::Name');

Creates an accessor of the specified name that affects a single child node of
that name; a runtime exception will be thrown if the instance has more than one
child of that name.

When setting you can pass in any object which isa XML::XPath::Node::Element;
Class::XML will re-bless it appropriately before it gives you it back later.

=head3 has_children

  __PACKAGE__->has_children('name' => 'Class::Name');

Functions identically to has_child except the generated accessor returns an
array, and can take one to set all such child nodes at once.

=head3 has_relation

  __PACKAGE__->has_relation('name' => [ '//xpath' => 'Class::Name' ]);

Creates a read-only accessor that returns the nodeset specified by evaluating
the given XPath expression with the object as the context node, and returning
the results as an array of Class::Name objects.

You can also specify an XPath expression with %s, %i etc. in it; the result
will be run through an sprintf on the arguments to the accessor before being
used - for example

  __PACKAGE__->has_relation('find_person' =>
                              [ '//person[@name="%s"]' => 'Person' ]);
  ...
  my @ret = $obj->find_person("Barry"); # Evaluates //person[@name="Barry"]

=head2 Constructors

=head3 new

  my $obj = My::Class->new( stuff ... )

Tries to DWIM as much as possible; figures out whether you're asking it to
parse something or create an object from scratch and passes it to the
appropriate method. This also means that any args to the 'new' methods of
either XML::XPath::XMLParser or XML::XPath::Node::Element will both work
here in almost all cases.

=head3 parse

  my $root = My::Class->parse( xml | filename | ioref | parser => source );

All four possible arguments behave pretty much as you'd expect (with the caveat
that 'parser' needs to be an XML::Parser object since that's what XML::XPath
uses). Returns an object corresponding to the root node of the XML document.

=head3 create

  my $new = My::Class->create( name?, ns?, { opts }? )

Creates a new instance of the appropriate class from scratch; 'name' if given
will override the one stored in element_name, 'ns' is the namespace prefix for
the element and 'opts' if given should be a hashref containing name => value
pairs for the initial attributes and children of the object.

=head2 Searching

=head3 search_children

  my @res = $obj->search_children( name?, { attr => value, ... }? )

Searches the immediate children of the object for nodes of name 'name' (or
any name if not given) with attribute-value pairs matching the supplied hash
reference (or all nodes matching the name test if not given). Any child for
whose name a has_child or has_children relationship has been declared will be
returned as an object of the appropriate class; any other node will be returned
as a vanilla XML::XPath::Node::Element object.

=head2 Utility

=head3 cast

  Class::XML::cast($new_class, $obj);

Loads the class specified by $new_class if necessary and then re-blesses $obj
into it. Designed for internal use but may come in handy :)

=head1 AUTHOR

Matt S Trout <mstrout@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
