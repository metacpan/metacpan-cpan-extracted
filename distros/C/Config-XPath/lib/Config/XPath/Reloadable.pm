#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2006-2010 -- leonerd@leonerd.org.uk

package Config::XPath::Reloadable;

use strict;
use warnings;
use base qw( Config::XPath );

use Carp;

our $VERSION = '0.16';

=head1 NAME

C<Config::XPath::Reloadable> - a subclass of C<Config::XPath> that supports
reloading

=head1 SYNOPSIS

 use Config::XPath::Reloadable;

 my $conf = Config::XPath::Reloadable->new( filename => 'addressbook.xml' );

 $SIG{HUP} = sub { $conf->reload };

 $conf->associate_nodeset( '//user', '@name',
    add => sub {
       my ( $name, $user_conf ) = @_;
       print "New user called $name, whose phone is " .
          $user_conf->get_string( '@phone' ) . "\n";
    },

    keep => sub {
       my ( $name, $user_conf ) = @_;
       print "User $name phone is now " .
          $user_conf->get_string( '@phone' ) . "\n";
    },

    remove => sub {
       my ( $name ) = @_;
       print "User $name has now gone\n";
    },
 );

 # Main body of code here ...

=head1 DESCRIPTION

This subclass of C<Config::XPath> supports reloading the underlying XML file
and updating the containing program's data structures. This is achieved by
taking control of the lifetimes of the program's data structures that use it.

Where a simple C<name=value> config file could be reloaded just by reapplying
string values, a whole range of new problems occur with the richer layout
afforded to XML-based files. New nodes can appear, old nodes can move, change
their data, or disappear. All these changes may involve data structure changes
within the containing program. To cope with these types of events, callbacks
in the form of closures can be registered that are called when various changes
happen to the underlying XML data.

As with the non-reloadable parent class, configuration is generally processed
by forming a tree of objects which somehow maps onto the XML data tree. The
way this is done in this class, is to use the $node parameter passed in to the
C<add> and C<keep> event callbacks. This parameter will hold a child
C<Config::XPath::Reloadable> object with its XPath context pointing at the
corresponding node in the XML data, much like the C<get_sub()> method does.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $conf = Config::XPath::Reloadable->new( %args )

This function returns a new instance of a C<Config::XPath::Reloadable> object,
initially containing the configuration in the named XML file. The file is
closed by the time this method returns, so any changes of the file itself will
not be noticed until the C<reload> method is called.

The C<%args> hash takes the following keys

=over 8

=item filename => $file

The filename of the XML file to read

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   if( !defined $args{filename} ) {
      croak "Expected 'filename' argument";
   }

   my $self = $class->SUPER::new( %args );

   $self->{nodelists} = [];

   $self;
}

=head1 METHODS

All of the simple data access methods of L<Config::XPath> are supported:

 $str = $config->get_string( $path, %args )

 $attrs = $config->get_attrs( $path )

 @values = $config->get_list( $path )

 $map = $config->get_map( $listpath, $keypath, $valuepath )

Because of the dynamically-reloadable nature of objects in this class, the
C<get_sub()> and C<get_sub_list()> methods are no longer allowed. They will
instead throw exceptions. The event callbacks in nodelists and nodesets
should be used instead, to obtain subconfigurations.

=cut

=head2 $conf->reload()

This method requests that the configuration object reloads the configuration
data that constructed it.

If called on the root object, the XML file that was named in the constructor
is reopened and reparsed. The file is re-opened by name, rather than by
rereading the filehandle that was opened in the constructor. (This distinction
is only of significance for systems that allow open files to be renamed). If
called on a child object, the stored XPath data tree is updated from the
parent.

In either case, after the data is reloaded, each nodelist stored by the object
is reevlauated, by requerying the XML nodeset using the stored XPaths, and the
event callbacks being invoked as appropriate.

=cut

sub reload
{
   my $self = shift;
   if( exists $self->{filename} ) {
      $self->_reload_file;
   }

   foreach my $nodelist ( @{ $self->{nodelists} } ) {
      $self->_run_nodelist( $nodelist );
   }
}

# Override - no POD
sub get_sub
{
   croak "Can't generate subconfig of a " . __PACKAGE__;
}

# Override - no POD
sub get_sub_list
{
   croak "Can't generate subconfig list of a " . __PACKAGE__;
}

=head2 $conf->associate_nodelist( $listpath, %events )

This method associates callback closures with events that happen to a given
nodelist in the XML data. When the function is first called, and every time
the C<< $conf->reload() >> method is called, the nodeset given by the XPath
string $listpath is obtained. The C<add> or C<keep> callback is then called as
appropriate on each node, in the order they appear in the current XML data.

Finally, the list of nodes that were present last time which no longer exist
is determined, and the C<remove> callback called for those, in no particular
order.

When this method is called, the C<add> callbacks will be invoked before the
method returns, for any matching items found in the data.

The C<%events> hash should be passed keys for the following events:

=over 8

=item add => CODE

Called when a node is returned in the list that has a name that wasn't present
on the last loading of the file. Called as:

 $add->( $index, $node )

=item keep => CODE

Called when a node is returned in the list that has a name that was present on
the last loading of the file. Note that the contents of this node may or may
not have changed; the containing program would have to requery the config node
to determine if this is the case. Called as:

 $keep->( $index, $node )

=item remove => CODE

Called at the end of the list enumeration, when a node was present last time
but is not present in the latest loading of the file. Called as:

 $remove->( $index )

=back

In each callback, the $index parameter will contain the index of the config
nodewithin the nodelist given by the $listpath, and the $node parameter will
contain a C<Config::XPath::Reloadable> object reference, with the XPath
context at the respective XML data node.

If further recursive nodesets are associated on the inner config node given
to the C<add> or C<keep> callbacks, then the C<keep> callback should invoke
the C<reload> method on the node, to ensure full recursive reloading of the
content.

=cut

sub associate_nodelist
{
   my $self = shift;
   my ( $listpath, %events ) = @_;

   my %nodelistitem = (
      listpath => $listpath,
   );

   foreach (qw( add keep remove )) {
      $nodelistitem{$_} = $events{$_} if exists $events{$_};
   }

   push @{ $self->{nodelists} }, \%nodelistitem;

   $self->_run_nodelist( \%nodelistitem );
}

=head2 $conf->associate_nodeset( $listpath, $namepath, %events )

This method is similar in operation to C<associate_nodelist>, except that
each node in the set is identified by some value, rather than just its
index within the list. The value given by $namepath is obtained by using the
get_string() method (so it must be a plain text node, attribute value, or any
other XPath query that gives a string value). This name is then used to
determine whether the node has been added, or kept since the last time.

The C<%events> hash should be passed keys for the following events:

=over 8

=item add => CODE

Called when a node is returned in the list that has a name that wasn't present
on the last loading of the file. Called as:

 $add->( $name, $node )

=item keep => CODE

Called when a node is returned in the list that has a name that was present on
the last loading of the file. Note that the contents of this node may or may
not have changed; the containing program would have to requery the config node
to determine if this is the case. Called as:

 $keep->( $name, $node )

=item remove => CODE

Called at the end of the list enumeration, when a node was present last time
but is not present in the latest loading of the file. Called as:

 $remove->( $name )

=back

In each callback, the $name parameter will contain the string value returned by
the $namepath path on each node, and the $node parameter will contain a
C<Config::XPath::Reloadable> object reference, with the XPath context at the
respective XML data node.

=cut

sub associate_nodeset
{
   my $self = shift;
   my ( $listpath, $namepath, %events ) = @_;

   my %nodelistitem = (
      listpath => $listpath,
      namepath => $namepath,
   );

   foreach (qw( add keep remove )) {
      $nodelistitem{$_} = $events{$_} if exists $events{$_};
   }

   push @{ $self->{nodelists} }, \%nodelistitem;

   $self->_run_nodelist( \%nodelistitem );
}

sub _run_nodelist
{
   my $self = shift;
   my ( $nodelist ) = @_;

   my $class = ref( $self );

   my %lastitems;
   %lastitems = %{ $nodelist->{items} } if defined $nodelist->{items};

   my %newitems;

   my $listpath = $nodelist->{listpath};
   my $namepath = $nodelist->{namepath};

   my @nodes = $self->get_config_nodes( $listpath );

   foreach my $index ( 0 .. $#nodes ) {
      my $n = $nodes[$index];

      my $name = defined $namepath ? $self->get_string( $namepath, context => $n ) : $index;

      my $item;

      if( exists $lastitems{$name} ) {
         $item = delete $lastitems{$name};

         $item->{xp} = $self->{xp};
         $item->{context} = $n;

         $nodelist->{keep}->( $name, $item ) if defined $nodelist->{keep};
      }
      else {
         $item = $class->newContext( $self, $n );

         $nodelist->{add}->( $name, $item ) if defined $nodelist->{add};
      }

      $newitems{$name} = $item;
   }

   foreach my $name ( keys %lastitems ) {
      $nodelist->{remove}->( $name ) if defined $nodelist->{remove};
   }

   $nodelist->{items} = \%newitems;
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 SEE ALSO

=over 4

=item *

C<XML::XPath> - Perl XML module that implements XPath queries

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
