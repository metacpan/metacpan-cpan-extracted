package Class::XML::Parser;

use strict;
use warnings;

use XML::Parser;
use Carp qw( croak );

our $VERSION = '0.901';

my $_parse_instance = undef;

sub new {
    my ( $class, %args ) = @_;

    my $pclass;
    if ( $args{ validate } ) {
        $pclass = 'XML::Checker::Parser';
        eval "use $pclass";
    } else {
        $pclass = 'XML::Parser';
    }

    my $parser = $pclass->new(
        %args,
        Style   => "Stream",
        Pkg     => "Class::XML::Parser::Internal",
    ) or croak "Couldn't create $pclass parser object";

    my $self = bless {
        parser      => $parser,
        error       => undef,
        stack       => Class::XML::Parser::Stack->new,
        object_stack=> Class::XML::Parser::Stack->new,
        root_class  => $args{ root_class } || [ caller ]->[ 0 ],
        prune       => $args{ prune } || 0,
        strip       => $args{ strip } || 0,
        map_uri     => $args{ map_uri },
        validate    => $args{ validate } || 0,
    }, $class;

    return $self
}

sub last_error { shift->{ error } }

sub parse {
    my ( $self, $xml ) = @_;

    $_parse_instance = $self;

    my $parsed = undef;

    eval {
        local $XML::Checker::FAIL = sub {
            my ( $code, @params ) = @_;

            die XML::Checker::error_string( @_ ) if $code < 200;
        };

        if ( $self->__validate and $self->__map_uri ) {
            XML::Checker::Parser::map_uri( %{ $self->__map_uri } );
        }

            
        $parsed = $self->__parser->parse( $xml );
    };
    if ( $@ ) {
        $self->__set_error( $@ );
        return;
    }

    undef $_parse_instance;

    return $self->{ object };
}

sub __parser        { $_[ 0 ]->{ parser } }
sub __validate      { $_[ 0 ]->{ validate } }
sub __map_uri       { $_[ 0 ]->{ map_uri } }
sub __stack         { $_[ 0 ]->{ stack } }
sub __object_stack  { $_[ 0 ]->{ object_stack } }
sub __root_class    { $_[ 0 ]->{ root_class } }
sub __prune         { $_[ 0 ]->{ prune } }
sub __strip         { $_[ 0 ]->{ strip } }
sub __object        { $_[ 0 ]->{ object } = $_[ 1 ] }
sub __parse_instance{ $_parse_instance }
sub __set_error     { $_[ 0 ]->{ error } = $_[ 1 ] }

package Class::XML::Parser::Internal;

use constant ELEM => 0;
use constant OBJ => 1;

my $instance = undef;

sub StartDocument {
    $instance = Class::XML::Parser->__parse_instance;
}

sub EndDocument {
    $instance = undef;
}

sub StartTag {
    my ( undef, $elem ) = @_;

    my %attributes = %_;

    my $stack = $instance->__stack;
    my $obj_stack = $instance->__object_stack;

    my $item;
    if ( $obj_stack->is_empty ) {
        # set first element to be new instance of root class object
        $stack->push( $elem );

        my $class = $instance->__root_class;

        my $ctor = $class->can( '__xml_parse_constructor' ) && $class->__xml_parse_constructor;
        $ctor = 'new' if not defined $ctor;

        $item = $class->$ctor;
        $obj_stack->push( [ $elem, $item ] );

        $instance->__object( $item );
    } else {
        $item = $obj_stack->peek->[ OBJ ];

        my $as_objects = $item->can( '__xml_parse_objects' ) && $item->__xml_parse_objects;

        my $alias = $elem;
        if ( $item->can( '__xml_parse_aliases' ) ) {
            my $aliases = $item->__xml_parse_aliases;

            $alias = $aliases->{ $elem }
              if UNIVERSAL::isa( $aliases, 'HASH' ) and exists $aliases->{ $elem };
        }

        my $class = $as_objects->{ $elem } if $as_objects;
        if ( $class ) {
            my $ctor = $class->can( '__xml_parse_constructor' ) && $class->__xml_parse_constructor;
            $ctor = 'new' if not defined $ctor;

            my $new_item = $class->$ctor;

            $item->$alias( $new_item );
            $item = $new_item;
            $obj_stack->push( [ $elem, $item ] );
        }
        $stack->push( $elem );
    }

    # set attributes
    while ( my ( $k, $v ) = each %attributes ) {
        $item->$k( $v );
    }
}

sub EndTag {
    my ( undef, $elem ) = @_;

    $instance->__object_stack->pop
      if $elem eq $instance->__object_stack->peek->[ ELEM ];

    $instance->__stack->pop;
}

sub Text {
    my $obj = $instance->__object_stack->peek->[ OBJ ];
    my $elem = $instance->__stack->peek;

    if ( $instance->__strip ) {
        s/^\s+//;
        s/\s+$//;
    }

    return
      if /^\s*$/ and $instance->__prune;

    return
      if $elem eq $instance->__object_stack->peek->[ ELEM ] and not $_;

    my $alias = $elem;
    if ( $obj->can( '__xml_parse_aliases' ) ) {
        my $aliases = $obj->__xml_parse_aliases;

        $alias = $aliases->{ $elem }
          if UNIVERSAL::isa( $aliases, 'HASH' ) and exists $aliases->{ $elem };
    }

    $obj->$alias( $_ );
}

sub PI { }

package Class::XML::Parser::Stack;

sub new {
    return bless [], shift;
}

sub is_empty    { return scalar @{ $_[ 0 ] } ? 0 : 1 }
sub push        { push @{ $_[ 0 ] }, $_[ 1 ] }
sub pop         { pop @{ $_[ 0 ] } }
sub peek        { $_[ 0 ]->[-1] };

1;

__END__

=head1 NAME

Class::XML::Parser - Parses (and optionally validates against a DTD) an XML
message into a user-defined class structure.

=head1 SYNOPSIS

 # parse result base class, just defines an autoloader

 package ParseResult::Base;

 sub new { bless {}, shift(); }
 sub AUTOLOAD {
     my ( $self, $val ) = @_;

     my $meth = $AUTOLOAD;
     $meth =~ s/.*:://;

     return if $meth eq 'DESTROY';

     if ( defined $val ) {
         $self->{ $meth } = $val;
     }

     $self->{ $meth };
 }

 # define classes that xml gets parsed into
 package ParseResult;

 use base qw( ParseResult::Base );

 # optionally define sub-classes that specific elements will be parsed into.
 # If this method doesn't exist, then all sub-elements and attributes thereof
 # will be parsed into this class
 sub __xml_parse_objects {
     {
         blah   => 'ParseResult::Blah',
     }
 }

 # optionally, have a class use a constructor other than 'new'.  Useful
 # for Class::Singleton objects
 sub __xml_parse_constructor {
     'new'
 }

 # optionally, have elements aliased to a method other than the XML
 # element name
 sub __xml_parse_aliases {
    {
        elem1   => 'bar',
    }
 }

 package ParseResult::Blah;

 use base qw( ParseResult::Base );

 package main;
 
 use Class::XML::Parser;
 
 my $xml = <<EOXML;
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE parser PUBLIC "-//Example//DTD Parse Example//EN"
                                 "http://example.com/parse.dtd">
 <parser>
   <elem1>
     <qwerty>uiop</qwerty>
     <blah>
       <wibble a="20">wobble</wibble>
     </blah>
   </elem1>
 </parser>
 EOXML

 my $parser = Class::XML::Parser->new(
     root_class      => 'ParseResult',   # top-level class to parse results into
     prune           => 1,
     validate        => 1,               # DTD validation should be done
     map_uri         => {
         # maps from XML SYSID or PUBID to URLs to replace.  Use to avoid
         # having to do a HTTP retrieval of the DTD, instead finding it on
         # the local filesystem
         'http://example.com/parse.dtd' => 'file:/tmp/parse.dtd',
     },
 );

 my $top = $parser->parse( $xml )
   or die $parser->last_error;

 print Dumper $top;

 # assuming the DTD exists, this will return a structure of:
 #$VAR1 = bless( {
 #    'blah' => bless( {
 #        'wibble' => 'wobble',      # sub-element of <blah>
 #        'a' => '20'                # attributes are also handled
 #    }, 'ParseResult::Blah' ),      # created as new object, as blah
 #                                   # defined in higher-level
 #                                   # __xml_parse_objects
 #    'qwerty' => 'uiop'             # sub-element of root
 #}, 'ParseResult' );                # top object is blessed into
 #                                   # 'root_class'

=head1 DESCRIPTION

This module allows for XML to be parsed into an user-defined object
hierarchy.  Additionally, the XML will be validated against it's DTD, if
such is defined within the XML body, and L<XML::Checker::Parser> is
available.

A note as to how the parsing is done.  When the ->parse method is called,
the each element name is checked against the current class' (root_class
by default) __xml_parse_objects result.  If an entry exists for this element
in the __xml_parse_objects hash, a new instance of the destination class
is created.  All further elements and attributes will be called as mutators
on that object, until the closing tag for the element is found, at which time
the previous object would be restored, and all further elements will default
to calling accessors on that object.  If nested elements are found, but no
__xml_parse_objects definition exists for them, any data elements and
attributes will be folded with the current object (container-only elements
are *not* added).  

=head1 constructor

 my $parser = Class::XML::Parser->new(
    root_class  => 'DataClass',
    validate    => 1,
    map_uri     => { 'http://example.com/data.dtd' => 'file:/tmp/data.dtd' },
    prune       => 1,
    parser      => 'XML::Parser',
 );

The following describes the parameters for the constructor:

=over 4

=item root_class

The root class that the parse results will be blessed into.  If not defined,
this will be the calling class.

=item validate

Whether DTD validation should be performed.  Internally, if this is set to
a true value, XML::Checker::Parser is used for parsing.  If not set, the
parsing class will be XML::Parser.

=item map_uri

This is only meaningful when 'validate' is true.  This allows replacements
URLs to be defined for DTD SYSIDs and PUBIDs.  This should be given as a
hash-ref.  If the given URL is a 'file:' type, the filename must be fully-
qualified.  See L<XML::Checker::Parser> for more details.

=item prune

If true, all parsed data values will not be assigned if they're found to
be empty of all but whitespace.

=item strip

If true, all data values will be stripped of leading/trailing whitespace.

=item *

Any other items will be passed to the internal XML parser class used,
either XML::Checker::Parser, if L<validiate> is specified, or XML::Parser.

Possibly the most useful other item would be a Namespaces paramater, which
will cause namespaces within the XML to be ignored when parsing.  See
L<XML::Parser::Expat> for more details.

=back

=head1 Object Methods

=over 4

=item parse( $xml )

Attempts to parse (and validate if specified) the given XML into an object
hierarchy.  Upon an error, this will return undef, and L<last_error> will
be set.  NOTE:  This method is NOT thread-safe.

=item last_error()

Returns the last parsing or validation error for this object, or undef on
no previous error.

=back

=head1 Data Object Methods

=over 4

=item __xml_parse_objects

This method, if defined for any parser classes, will define which XML
elements will be deserialized as new objects.  

This method should return a hash-ref, of the form { xml-tag => package_name },
where an XML element of <xml-tag> is found, a new instance of <package_name>
is created, and all attributes and sub-element will then be parsed into
that class.

=item __xml_parse_constructor

If defined, the value returned by this method will be used as the
constructor method for objects that parse into this class, instead of
the typical 'new' method.

=item __xml_parse_aliases

If defined, this method should return a hash-ref, which maps XML elements to
alternate method, rather than using a method of the same name as the element.

=back

=head1 CAVEATS

IMPORTANT: No checks are done to determine if the element/attribute
deserialization would cause a previous definition to be overwritten.  Where
there is a possibility of this, and it is not the desired behaviour, this
can be overcome by creating a mutator for that element in the package that
it will be parsed into, to push it onto an array, or hash, as appropriate.
See t/05_hierarchy_custom_mutator.t for an example of this.

Due to a limitation of XML::Parser Stream handling, elements that are
completely empty (no content or attributes) will NOT be assigned to.  This
could possibly be overcome, but I didn't need this, so didn't bother. :)

If namespaces exist in the parsed XML, there are 2 options for handling.  The
first is to pass a Namespaces => 1 to the Class::XML::Parser constructor, and
ensure that the xmlns attribute is defined (see t/11_namespaces.t for an
example of this).  The alternative would be to make liberal use of
__xml_parse_aliases in all parse result classes.

=head1 SEE ALSO

L<XML::Parser>

L<XML::Checker::Parser> (used for DTD validation internally)

=head1 AUTHOR

makk384@gmail.com

=end
