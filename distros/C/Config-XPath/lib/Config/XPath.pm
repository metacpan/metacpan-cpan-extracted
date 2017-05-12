#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2005-2010 -- leonerd@leonerd.org.uk

package Config::XPath;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
   get_service_config

   get_config_string
   get_config_attrs
   get_config_list
   get_config_map

   get_sub_config
   get_sub_config_list

   read_default_config
);

our $VERSION = '0.16';

use XML::XPath;

use Carp;

use Scalar::Util qw( weaken );

=head1 NAME

C<Config::XPath> - retrieve configuration data from XML files by using XPath

=head1 SYNOPSIS

 use Config::XPath;

 my $conf = Config::XPath->new( filename => 'addressbook.xml' );

 ## Basic data retrieval

 my $bob_phone = $conf->get_string( '//user[@name="bob"]/@phone' );

 my %jim_details = $conf->get_attrs( '//user[@name="jim"]' );

 my @everyone_with_fax = $conf->get_list( '//user[@fax]' );
 print " $_ has a fax\n" for @everyone_with_fax;

 my $phone_map = $conf->get_map( '//user', '@name', '@phone' );
 print " $_ has a phone: $phone_map->{$_}\n" for sort keys %$phone_map;

 ## Subconfigurations

 my $james_config = $conf->get_sub( '//user[@name="james"]' );
 my $james_phone = $james_config->get_string( '@phone' );

 foreach my $user_config ( $conf->get_sub_list( '//user[@email]' ) ) {
    my $town = $user_config->get_string( 'address/town' );
    print "Someone in $town has an email account\n";
 }

=head1 DESCRIPTION

This module provides easy access to configuration data stored in an XML file.
Configuration is retrieved using XPath keys; various methods exist to
convert the result to a variety of convenient forms.

If the methods are called as static functions (as opposed to as object
methods) then they access data stored in the default configuration file
(details given below).

=cut

=head2 Subconfigurations

By default, the XPath context is at the root node of the XML document. If some
other context is required, then a subconfiguration object can be used. This is
a child C<Config::XPath> object, built from an XPath query on the parent.
Whatever node the query matches becomes the context for the new object. The
methods C<get_sub()> and C<get_sub_list()> perform this task; the former
returning a single child, and the latter returning a list of all matches.

=cut

=head1 CONSTRUCTOR

=head2 $conf = Config::XPath->new( %args )

This function returns a new instance of a C<Config::XPath> object, containing
the configuration in the named XML file. If the given file does not exist, or
an error occured while reading it, an exception is thrown.

The C<%args> hash requires one the following keys to provide the XML source:

=over 8

=item filename => $file

The filename of the XML file to read

=item xml => $xml

A string containing XML data

=item ioref => IO

An IO handle reference

=back

Also may be provided:

=over 8

=item parser => $parser

An C<XML::Parser> object

=back

If a parser is not provided, one will be constructed internally.

=cut

sub new
{
   my $class = shift;

   my %args;

   # Cope with now-deprecated constructor form
   if( @_ == 1 ) {
      carp 'Use of '.__PACKAGE__.'->new( $file ) is deprecated; use ->new( filename => $file ) instead';
      %args = ( filename => $_[0] );
   }
   else {
      %args = @_;
   }

   my $self = bless { 
   }, $class;

   my $parser = $self->{parser} = delete $args{parser};
   
   if( defined $args{filename} ) {
      $self->{filename} = $args{filename};
      $self->_reload_file;
   }
   elsif( defined $args{xml} ) {
      my $xp = XML::XPath->new(
         xml => $args{xml},
         defined $parser ? ( parser => $parser ) : (),
      );
      croak "Cannot parse string" unless $xp;
      $self->{xp} = $xp;
   }
   elsif( defined $args{ioref} ) {
      my $xp = XML::XPath->new( 
         ioref => $args{ioref},
         defined $parser ? ( parser => $parser ) : (),
      );
      croak "Cannot parse XML from ioref" unless $xp;
      $self->{xp} = $xp;
   }
   else {
      croak "Expected 'filename', 'xml', 'parser' or 'ioref' argument";
   }

   return $self;
}

# Internal-only constructor
sub newContext
{
   my $class = shift;
   my ( $parent, $context ) = @_;

   my $self = {
      parent   => $parent,
      context  => $context
   };

   weaken( $self->{parent} );

   return bless $self, $class;
}

sub find
{
   my $self = shift;
   my ( $path, %args ) = @_;

   my $toplevel = $self;
   $toplevel = $toplevel->{parent} while !exists $toplevel->{xp};

   my $xp = $toplevel->{xp};

   my $context = $args{context} || $self->{context};

   if ( defined $context ) {
      return $xp->find( $path, $context );
   }
   else {
      return $xp->find( $path );
   }
}

sub get_config_nodes
{
   my $self = shift;
   my ( $path ) = @_;

   my $nodeset = $self->find( $path );

   unless( $nodeset->isa( "XML::XPath::NodeSet" ) ) {
      croak "Expected result to be a nodeset at '$path'";
   }

   return $nodeset->get_nodelist;
}

sub get_config_node
{
   my $self = shift;
   my ( $path ) = @_;

   my @nodes = $self->get_config_nodes( $path );

   if ( scalar @nodes == 0 ) {
      croak "No config found at '$path'";
   }

   if ( scalar @nodes > 1 ) {
      croak "Found more than one node at '$path'";
   }

   return shift @nodes;
}

sub get_node_attrs($)
# Get a hash of the attributes, putting the node name in "+"
{
   my ( $node ) = @_;

   my %attrs = ( '+' => $node->getName() );

   foreach my $attr ( $node->getAttributes() ) {
      $attrs{$attr->getName} = $attr->getValue;
   }

   return \%attrs;
}

sub convert_string
{
   my $self = shift;
   my ( $nodeset, $path, %args ) = @_;

   if( !$nodeset->isa( "XML::XPath::NodeSet" ) ) {
      return $nodeset->string_value();
   }

   my @nodes = $nodeset->get_nodelist;
   if ( scalar @nodes == 0 ) {
      return $args{default} if exists $args{default};

      croak "No config found at '$path'";
   }

   if ( scalar @nodes > 1 ) {
      croak "Found more than one node at '$path'";
   }

   my $node = $nodes[0];

   if ( $node->isa( "XML::XPath::Node::Element" ) ) {
      my @children = $node->getChildNodes();

      if( !@children ) {
         # No child nodes - treat this as an empty string
         return "";
      }
      elsif ( scalar @children == 1 ) {
         my $child = shift @children;

         if ( ! $child->isa( "XML::XPath::Node::Text" ) ) {
            croak "Result is not a plain text value at '$path'";
         }

         return $child->string_value();
      }
      else {
         croak "Found more than one child node at '$path'";
      }
   }
   elsif( $node->isa( "XML::XPath::Node::Text" ) ) {
      return $node->getValue();
   }
   elsif( $node->isa( "XML::XPath::Node::Attribute" ) ) {
      return $node->getValue();
   }
   else {
      my $t = ref( $node );
      croak "Cannot return string representation of node type $t at '$path'";
   }
}

=head1 METHODS

=cut

=head2 $result = $config->get( $paths, %args )

This method retrieves the result of one of more XPath expressions from the XML
file. Each expression should give either a text-valued element with no
sub-elements, an attribute, or an XPath function that returns a string,
integer or boolean value.

The C<$paths> argument should contain a data tree of ARRAY and HASH
references, whose leaves will be the XPath expressions used. The C<$result>
will be returned in a similar tree structure, with the leaves containing the
value each expression yielded against the XML config. The C<%args> may contain
a C<default> key, which should give default values for these results, also in
a similar tree structure.

If no suitable node was found matching an XPath expression and no
corresponding C<default> value is found, then an exception is thrown. If more
than one node is returned, or the returned node is not either a plain-text
content containing no child nodes, or an attribute, then an exception is
thrown.

=over 8

=item $paths

A tree data structure containing ARRAY and HASH references, and XPath
expressions stored in plain scalars.

=item %args

A hash that may contain extra options to control the operation. Supports the
following keys:

=over 4

=item C<default>

Contains a tree in the same structure as the C<$paths>, whose leaf values
should be returned instead of the value yielded by the XPath expression, in
the case that no nodes match it.

=back

=back

=cut

sub get
{
   my $self = shift;
   my ( $paths, %args ) = @_;

   my $context = $args{context};

   if( !ref $paths ) {
      return $self->get_string( $paths, %args );
   }
   elsif( ref $paths eq "ARRAY" ) {
      my $default = delete $args{default};

      my @ret;

      foreach my $index ( 0 .. $#$paths ) {
         $ret[$index] = $self->get( $paths->[$index], %args,
            exists $default->[$index] ? (default => $default->[$index]) : ()
         );
      }

      return \@ret;
   }
   elsif( ref $paths eq "HASH" ) {
      my $default = delete $args{default};

      my %ret;

      foreach my $key ( keys %$paths ) {
         $ret{$key} = $self->get( $paths->{$key}, %args,
            exists $default->{$key} ? (default => $default->{$key}) : ()
         );
      }

      return \%ret;
   }
   else {
      croak "Expected a plain string or ARRAY or HASH reference as path, got " . ( ref $paths ) . " reference instead";
   }
}

=head2 $str = $config->get_string( $path, %args )

This function is a smaller version of the C<get> method, which only works on a
single string path.

=over 8

=item $path

The XPath to the required configuration node

=item %args

A hash that may contain extra options to control the operation. Supports the
following keys:

=over 4

=item C<default>

If no XML node is found matching the path, return this value rather than
throwing an exception.

=back

=back

=cut

sub get_string
{
   my $self = shift;
   my ( $path, %args ) = @_;

   my $nodeset = $self->find( $path, context => $args{context} );

   return $self->convert_string( $nodeset, $path, %args );
}

=head2 $attrs = $config->get_attrs( $path )

This method retrieves the attributes of a single element in the XML file. The
attributes are returned in a hash, along with the name of the element itself,
which is returned in a special key named C<'+'>. This name is not valid for an
XML attribute, so this key will never clash with an actual value from the XML
file.

If no suitable node was found matching the XPath query, then an exception is
thrown.  If more than one node matched, or the returned node is not an
element, then an exception is thrown.

=over 8

=item C<I<$path>>

The XPath to the required configuration node

=back

=cut

sub get_attrs
{
   my $self = shift;
   my ( $path ) = @_;

   my $node = $self->get_config_node( $path );

   unless( $node->isa( "XML::XPath::Node::Element" ) ) {
      croak "Node is not an element at '$path'";
   }

   return get_node_attrs( $node );
}

=head2 @results = $config->get_list( $listpath; $valuepaths, %args )

This method obtains a list of nodes matching the C<$listpath> expression. For
each node in the list, it obtains the result of the C<$valuepaths> with the
XPath context at each node, and returns them all in a list. The C<$valuepaths>
argument can be a single string expression, or an ARRAY or HASH tree, as for
the C<get()> method.

If the C<$valuepaths> argument is not supplied, the type of each node
determines the value that will be returned. Element nodes return a
hashref, identical to that which C<get_attrs()> returns. Other nodes will
return their XPath string value.

=over 8

=item $listpath

The XPath expression to generate the list of nodes.

=item $valuepaths

Optional. If present, the XPath expression or tree of expressions to generate
the results.

=item %args

A hash that may contain extra options to control the operation. Supports the
following keys:

=over 4

=item C<default>

Contains a tree in the same structure as the C<$valuepaths>, whose leaf values
should be returned instead of the value yielded by the XPath expression, in
the case that no nodes match it.

=back

=back

=cut

sub get_list
{
   my $self = shift;
   my ( $listpath, $valuepaths, %args ) = @_;

   my @nodes = $self->get_config_nodes( $listpath );

   my @ret;

   foreach my $node ( @nodes ) {
      my $val;

      if ( defined $valuepaths ) {
         $val = $self->get( $valuepaths, context => $node, %args );
      }

      elsif ( $node->isa( "XML::XPath::Node::Element" ) ) {
         $val = get_node_attrs( $node );
      }
      elsif ( $node->isa( "XML::XPath::Node::Text" ) or $node->isa( "XML::XPath::Node::Attribute" ) ) {
         $val = $self->convert_string( $node, $listpath );
      }
      else {
         my $t = ref( $node );
         croak "Cannot return string representation of node type $t at '$listpath'";
      }

      push @ret, $val;
   }

   return @ret;
}

=head2 $map = $config->get_map( $listpath, $keypath, $valuepaths, %args )

This method obtains a map, returned as a hash, containing one entry for each
node returned by the C<$listpath> search, where the key and value are given by
the C<$keypath> and C<$valuepaths> within each node. It is not an error for no
nodes to match the C<$listpath>.

The result of the C<$listpath> query must be a nodeset. The result of the
C<$keypath> is used as the hash key for each node, and must be convertable
to a string, by the same rules as the C<get_string()> method. The value for
each node in the hash will be obtained using the C<$valuepaths>, which can be
a plain string, or an ARRAY or HASH tree, as for the C<get()> method.

The keys obtained by the C<$keypath> should be unique. In the case of
duplicates, the last value from the nodeset is used.

=over 8

=item $listpath

The XPath to generate the nodeset

=item $keypath

The XPath within each node to generate the key

=item $valuepaths

The XPath expression or tree of expressions within each node to generate the
value.

=item %args

A hash that may contain extra options to control the operation. Supports the
following keys:

=over 4

=item C<default>

Contains a tree in the same structure as the C<$valuepaths>, whose leaf values
should be returned instead of the value yielded by the XPath expression, in
the case that no nodes match it.

=back

=back

=cut

sub get_map
{
   my $self = shift;
   my ( $listpath, $keypath, $valuepaths, %args ) = @_;

   my @nodes = $self->get_config_nodes( $listpath );

   my %ret;

   foreach my $node ( @nodes ) {
      my $keynode = $self->find( $keypath, context => $node );
      my $key = $self->convert_string( $keynode, $keypath );

      my $value = $self->get( $valuepaths, context => $node, %args );

      $ret{$key} = $value;
   }

   return \%ret;
}

=head2 $subconfig = $config->get_sub( $path )

This method constructs a new C<Config::XPath> object whose context is at the
single node selected by the XPath query. The newly constructed child object is
then returned.

If no suitable node was found matching the XPath query, then an exception of
is thrown. If more than one node matched, then an exception is thrown.

=over 8

=item $path

The XPath to the required configuration node

=back

=cut

sub get_sub
{
   my $self = shift;
   my $class = ref( $self );
   my ( $path ) = @_;

   my $node = $self->get_config_node( $path );

   return $class->newContext( $self, $node );
}

=head2 @subconfigs = $config->get_sub_list( $path )

This method constructs a list of new C<Config::XPath> objects whose context is
at each node selected by the XPath query. The array of newly constructed
objects is then returned. Unlike other methods, it is not an error for no
nodes to match.

=over 8

=item $path

The XPath for the required configuration

=back

=cut

sub get_sub_list
{
   my $self = shift;
   my $class = ref( $self );
   my ( $path ) = @_;

   my @nodes = $self->get_config_nodes( $path );

   my @ret;

   foreach my $node ( @nodes ) {
      push @ret, $class->newContext( $self, $node );
   }

   return @ret;
}

# Private methods
sub _reload_file
{
   my $self = shift;

   # Recurse down to the toplevel object
   return $self->{parent}->reload() if exists $self->{parent};

   my $file = $self->{filename};
   my $parser = $self->{parser};

   my $xp = XML::XPath->new(
      filename => $file,
      defined $parser ? ( parser => $parser ) : (),
   );

   croak "Cannot read config file $file" unless $xp;

   # If we threw an exception, this line never gets run, so the old {xp} is
   # preserved. If not, then we know that $xp at least contains valid XML data
   # so we store it, replacing the old value.

   $self->{xp} = $xp;
}

=head1 DEFAULT CONFIG FILE

In the case of calling as static functions, the default configuration is
accessed. When the module is loaded no default configuration exists, but one
can be loaded by calling the C<read_default_config()> function. This makes
programs simpler to write in cases where only one configuration file is used
by the program.

=cut

my $default_config;

=head2 read_default_config( $file )

This function reads the default configuration file, from the location given.
If the file is not found, or an error occurs while reading it, then an
exception is thrown.

The default configuration is cached, so multiple calls to this function will
not result in multiple reads of the file; subsequent requests will be silently
ignored, even if a different filename is given.

=over 8

=item $file

The filename of the default configuration to load

=back

=cut

sub read_default_config
{
   my ( $file ) = @_;

   last if defined $default_config;
   
   $default_config = Config::XPath->new( filename => $file );
}

=head1 FUNCTIONS

Each of the following functions is equivalent to a similar method called on 
the default configuration, as loaded by C<read_default_config()>.

=cut

=head2 $str = get_config_string( $path, %args )

Equivalent to the C<get_string()> method

=cut

sub get_config_string
{
   my $self;
   if( ref( $_[0] ) && $_[0]->isa( __PACKAGE__ ) ) {
      carp "Using static function 'get_config_string' as a method is deprecated";
      $self = shift;
   }
   else {
      croak "No default config loaded for '$_[0]'" unless defined $default_config;
      $self = $default_config;
   }

   $self->get_string( @_ );
}

=head2 $attrs = get_config_attrs( $path )

Equivalent to the C<get_attrs()> method

=cut

sub get_config_attrs
{
   my $self;
   if( ref( $_[0] ) && $_[0]->isa( __PACKAGE__ ) ) {
      carp "Using static function 'get_config_attrs' as a method is deprecated";
      $self = shift;
   }
   else {
      croak "No default config loaded for '$_[0]'" unless defined $default_config;
      $self = $default_config;
   }

   $self->get_attrs( @_ );
}

=head2 @values = get_config_list( $path )

Equivalent to the C<get_list()> method

=cut

sub get_config_list
{
   my $self;
   if( ref( $_[0] ) && $_[0]->isa( __PACKAGE__ ) ) {
      carp "Using static function 'get_config_list' as a method is deprecated";
      $self = shift;
   }
   else {
      croak "No default config loaded for '$_[0]'" unless defined $default_config;
      $self = $default_config;
   }

   $self->get_list( @_ );
}

=head2 $map = get_config_map( $listpath, $keypath, $valuepath )

Equivalent to the C<get_map()> method

=cut

sub get_config_map
{
   my $self;
   if( ref( $_[0] ) && $_[0]->isa( __PACKAGE__ ) ) {
      carp "Using static function 'get_config_map' as a method is deprecated";
      $self = shift;
   }
   else {
      croak "No default config loaded for '$_[0]'" unless defined $default_config;
      $self = $default_config;
   }

   $self->get_map( @_ );
}

=head2 $map = get_sub_config( $path )

Equivalent to the C<get_sub()> method

=cut

sub get_sub_config
{
   my $self;
   if( ref( $_[0] ) && $_[0]->isa( __PACKAGE__ ) ) {
      carp "Using static function 'get_sub_config' as a method is deprecated";
      $self = shift;
   }
   else {
      croak "No default config loaded for '$_[0]'" unless defined $default_config;
      $self = $default_config;
   }

   $self->get_sub( @_ );
}

=head2 $map = get_sub_config_list( $path )

Equivalent to the C<get_sub_list()> method

=cut

sub get_sub_config_list
{
   my $self;
   if( ref( $_[0] ) && $_[0]->isa( __PACKAGE__ ) ) {
      carp "Using static function 'get_sub_config_list' as a method is deprecated";
      $self = shift;
   }
   else {
      croak "No default config loaded for '$_[0]'" unless defined $default_config;
      $self = $default_config;
   }

   $self->get_sub_list( @_ );
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 SEE ALSO

=over 4

=item *

L<XML::XPath> - Perl XML module that implements XPath queries

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
