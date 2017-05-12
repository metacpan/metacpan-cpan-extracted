package Data::XML::Variant::Build;

use warnings;
use strict;
use HTML::Entities ();
use aliased 'Data::XML::Variant::Output';

# cache for all tag methods added
my %METHOD_CACHE;

=head1 NAME

Data::XML::Variant::Build - Data::XML::Variant "build" class.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Do not use this class directly.  L<Data::XML::Variant> will return an instance of
this class and autogenerate the requested tag methods.

=head1 EXPORT

None.

=head1 METHODS

=cut

##############################################################################

=head2 New

  my $build = Data::XML::Variant::Build->New;

Returns a new L<Data::XML::Variant::Build> object.  Takes no arguments.

=cut

sub New { bless {}, shift }

##############################################################################

=head2 Add

 $xml->Add($tag);
 $xml->Add($tag, $method);

This method will create three tag methods for you for the start tag, end tag, 
and just "tag".  For example:

 $xml->Add('foo');
 print $xml->start_foo;      # <foo>
 print $xml->foo('message'); # <foo>message</foo>
 print $xml->end_foo;        # </foo>

The base name of the methods defaults to to tag name, but a second argument
will allow you to specify a different method base name name if the tag name is
not a legal method name.

For example:

 $xml->Add('foo');
 $xml->Add('florp:bar', 'bar');
 print $xml->start_bar([ id => 3 ]), #attributes to 'bar'
       $xml->foo('message'),
       $xml->end_bar;

 # or
 print $xml->bar( [ id => 3 ], $xml->foo('message') ); # same thing

That should output:

 <florp:bar id="3"><foo>message</foo></florp:bar>

Method names must be legal for Perl and B<must> begin with a lower-case 
letter.  The latter restriction ensures no collision with the pre-existing
methods in this class, all of which begin with an upper-case letter.

This method will croak if the method already exists in this class or if you
attempt to override a method in C<UNIVERSAL>.

Any arguments passed to the C<end_$tag> method will cause that method to
croak.

B<Note>:  because this method adds new methods directly into this namespace,
all instances of this object will have access to the same methods.  See the
C<Remove> and C<Methods> methods to see how to manage them.  This may change
in the future.

See L<ATTRIBUTES> for information about how attributes are handled.

=cut

sub Add {
    my ( $self, $tag, $method_name ) = @_;
    $method_name ||= $tag;
    if ( UNIVERSAL->can($method_name) ) {
        $self->_croak('Cannot override UNIVERSAL methods');
    }
    unless ( $method_name =~ /^[[:lower:]]/ ) {
        $self->_croak(
            "Added methods must begin with a lower-case letter ($method_name)");
    }
    if ( $self->can($method_name) ) {
        $self->_croak("Method ($method_name) already added");
    }

    no strict 'refs';
    my ( $start, $method, $end ) = $self->_tag_methods($method_name);
    $METHOD_CACHE{$method} = 1;
    *$start = sub {
        my ( $self, $attributes ) = @_;
        if ( $attributes && !$self->_has_attributes($attributes) ) {
            $self->_croak(
                "Argument to start_$method must be an array ref or hash ref");
        }
        my $result = "<$tag";
        if ($attributes) {
            $result .= $self->_attributes($attributes);
        }
        $result .= ">";
        return Output->new($result);
    };

    *$method = sub {
        my ( $self, @data ) = @_;
        my $result;
        $result =
          $self->_has_attributes( $data[0] )
          ? $self->$start( shift @data )
          : $self->$start;
        unless (@data) {
            my $closing = $self->Closing;
            $result =~ s{>$}{$closing>};
            return Output->new($result);
        }

        foreach my $data (@data) {
            $result .=
              Output eq ref $data ? $data->output : $self->_encode($data);
        }
        $result .= $self->$end;
        return Output->new($result);
    };

    *$end = sub {
        my $self = shift;
        if (@_) {
            $self->_croak("end_$method does not take any arguments");
        }
        my $result = "</$tag>";
        return Output->new($result);
    };
}

=head2 Encode

  $xml->Encode($sub_ref);

Don't like how the XML is encoded?  Supply a subref which handles the encoding
for you.  The first argument to the subref will be the
C<Data::XML::Variant::Build> object and the second argument will be the string
to be encoded.  For example, to eliminate all encoding:

 $xml->Encode(sub {
    my ($self, $string) = @_;
    return $string;
 });

By default, data is encoded with C<HTML::Entities::encode_entities> with
no arguments other than the data string.

=cut

sub Encode {
    my ( $self, $sub ) = shift;
    unless ( 'CODE' eq ref $sub ) {
        $self->_croak("Argument to Encode() must be a subroutine reference.");
    }
    *_encode = $sub;
}

sub _encode {
    my $self = shift;
    HTML::Entities::encode_entities(shift);
}

sub _croak {
    my ( $self, @error ) = @_;
    require Carp;
    Carp::croak(@error);
}

##############################################################################

=head2 Closing

  my $closing = $xml->Closing;
  $xml->Closing(' /');

This getter/setter determines how self-closing tags terminate.  Generally there
should not be a space prior to the trailing slash:

 print $xml->foo; # <foo/>

Some XML/HTML parsers do not like this and require a space before the trailing
slash.  Use this method to provide this (or any other closing).

 $xml->Closing(' /');
 print $xml->foo; # <foo />

=cut

sub Closing {
    my $self = shift;
    return $self->{closing} || '/' unless @_;
    $self->{closing} = shift;
    return $self;
}

##############################################################################

=head2 Quote

  my $quote = $xml->Quote;
  $xml->Quote("'"); # use single quotes

Getter/setter for attribute quote character

=cut

sub Quote {
    my $self = shift;
    return $self->{quote} || '"' unless @_;
    $self->{quote} = shift;
    return $self;
}

##############################################################################

=head2 Methods

  my @methods = $xml->Methods;

Returns a list of I<tag> methods which have been added.

=cut

sub Methods {
    my $self = shift;

    return map { $self->_tag_methods($_) }
      sort keys %METHOD_CACHE;
}

##############################################################################

=head2 Remove

  $xml->Remove('foo'); # remove the foo tag methods
  $xml->Remove;        # remove all tag methods

This method allows you to remove undesired methods from C<Data::XML::Build>
namespace.  Specifying a tag name will remove the corresponding start, end,
and tag methods.  Calling without arguments will remove all methods.

Warns if the tag name is not found.

Return true on success.

=cut

sub Remove {
    my ( $self, $tag ) = @_;
    my @remove;
    if ( defined $tag ) {
        unless (exists $METHOD_CACHE{$tag}) {
            require Carp;
            Carp::carp("Tried to remove unknown tag ($tag)");
            return;
        }
        @remove = $tag;
    }
    else {
        @remove = keys %METHOD_CACHE;
    }
    foreach my $remove (@remove) {
        foreach my $method ($self->_tag_methods($remove)) {
            no strict 'refs';

            # we need to wipe out the entire glob because "undef &$method"
            # will result in a weird "Not a CODE reference" error if the
            # method is later called because the other glob slots will still
            # exist.  This is arguably a bug in Perl.
            undef *$method; 
            delete $METHOD_CACHE{$method};
        }
    }
    return 1;
}

##############################################################################

=head2 Cdata

  my $Cdata = $xml->Cdata($string);

Returns a CDATA section for XML.  Does not escape data.

=cut

sub Cdata {
    my ( $self, $data ) = @_;

    # need to deal with the END marker
    return Output->new( '<![CDATA[' . $data . ']]>' );
}

##############################################################################

=head2 Raw

  print $xml->some_tag($xml->Raw($string));

This method allows you to insert I<raw>, unescaped data into your output.

Use with caution.

=cut

sub Raw {
    my ( $self, $string ) = @_;
    return Output->new($string);
}

##############################################################################

=head2 Decl

  print $xml->Decl;
  # <?xml version="1.0"?>
  print $xml->Decl([version => '1.0', encoding => "utf-8", standalone => "yes");

This method returns an XML declaration with a version of '1.0'.  If you desire
additional attributes, you may specify an attribute list.  C<version> must be
explicitly specified if you have attributes.

=cut

sub Decl {
    my ( $self, $attributes ) = @_;
    if ( defined $attributes && !$self->_has_attributes($attributes) ) {
        $self->_croak('You must supply valid attributes to Decl()');
    }
    $attributes ||= [ version => '1.0' ];
    return Output->new( '<?xml' . $self->_attributes($attributes) . '?>' );
}

##############################################################################

=head2 PI

  $xml->PI( 
    'xml-stylesheet', 
    [ type => 'text/xsl', href => 'http://www.example.com' ] 
  );
  # <?xml-stylesheet type="text/xsl" href="http://www.example.com"?>

Returns a process instruction.

=cut

sub PI {
    my ( $self, $pi, $attributes ) = @_;
    if ( defined $attributes && !$self->_has_attributes($attributes) ) {
        $self->_croak('You must supply valid attributes to Decl()');
    }
    return Output->new( "<?$pi" . $self->_attributes($attributes) . '?>' );
}

##############################################################################

=head2 Comment

  $xml->Comment('this is a > comment');
  # <!-- this is a &gt; comment -->

Returns an XML comment.  Comment is padded with one space before and after the
C<$comment> string.

=cut

sub Comment {
    my ($self, $comment) = @_;
    return Output->new('<!-- '.$self->_encode($comment).' -->');
}

sub _has_attributes {
    my ( $self, $data ) = @_;
    return unless defined $data && ref $data;

    # we're reaching into UNIVERSAL because they data may be a string,
    # a normal reference or a blessed reference
    return !UNIVERSAL::isa( $data, Output )
      && ( UNIVERSAL::isa( $data, 'ARRAY' )
        || UNIVERSAL::isa( $data, 'HASH' )
        || UNIVERSAL::isa( $data, 'SCALAR' ) );
}

sub _attributes {
    my ( $self, $attrs ) = @_;
    return '' unless $attrs;
    if ( ref $attrs && UNIVERSAL::isa( $attrs, 'SCALAR' ) ) {
        return ' ' . $$attrs;
    }
    my @attributes = UNIVERSAL::isa( $attrs, 'HASH' ) ? %$attrs : @$attrs;
    return '' unless @attributes;
    my $result = '';
    my $quote  = $self->Quote;
    for ( my $i = 0 ; $i < @attributes ; $i += 2 ) {
        my ( $attr, $value ) = @attributes[ $i, $i + 1 ];
        $value = $self->_encode($value);
        $result .= qq{ $attr=$quote$value$quote};
    }
    return $result;
}

sub _tag_methods {
    my ( $self, $tag ) = @_;
    return ( "start_$tag", $tag, "end_$tag" );
}

=head1 ATTRIBUTES

Attribute handling is an annoying problem.  Many tools require XML attributes
to appear in a particular order even though this is not required.  We handle
this by allowing you to specify attributes in three different ways.

=over 4

=item Array references

This is the preferred method.  Pass an array reference for attributes and the
attributes will be added in the correct order:

 print $xml->foo( [ id => 2, class => 'none' ] );
 # <foo id="2" class="none"/>

=item Hash references

This is the traditional method.  Pass a hash reference for attributes and the
attributes will be added, but the order is not guaranteed:

 print $xml->foo( { id => 2, class => 'none' } );
 # <foo id="2" class="none"/>
 # <foo class="none" id="2"/>

=item Scalar references

If you are forced to work with an XML variant which has unusual attribute 
requirements, you may pass a scalar reference and the attributes will be
added to the tag exactly as you have passed them (but there will still be
a space after the tag name):

 my $attributes = "id=2 selected";
 print $xml->foo( \$attributes );
 # <foo id=2 selected/>

=back

=head1 NEWLINES

Many people don't like their XML running on the same line.  Because the goal
of this module is to give you fine-grained control over how you need to produce
your XML variant, it will not attempt to second guess where you want newlines.
You will have to insert them yourself.

Here's an example.  Note how the individual method calls are joined on newlines
but method calls inside other method calls have newlines inserted between them.

 my $xml = Data::XML::Variant->new(
     {
         'ns:foo'  => 'foo',
         'bar'     => 'bar',
         'ns2:baz' => 'baz',
     }
 );
 my $xslt_url = 'http://www.example.com/xslt/';
 my $url      = 'http://www.example.com/url/';

 print join "\n" => $xml->Decl, # joining outer elements in \n 
   $xml->PI( 'xml-stylesheet', [ type => 'text/xsl', href => "$xslt_url" ] ),
   $xml->foo(
     [ id => 3, 'xmlns:ns2' => $url ],                      "\n",
     $xml->bar('silly'),                                    "\n",
     $xml->Comment('this is a > comment'),                  "\n",
     $xml->baz( [ 'asdf:some_attr' => 'value' ], 'whee!' ), "\n"
   );
 
That will print the following:

 <?xml version="1.0"?>
 <?xml-stylesheet type="text/xsl" href="$xslt_url"?>
 <ns:foo id="3" xmlns:ns2="$url">
 <bar>silly</bar>
 <!-- this is a &gt; comment -->
 <ns2:baz asdf:some_attr="value">whee!</ns2:baz>
 </ns:foo>

Yes, there are an unbound prefixes in that example.  This was deliberate.

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-xml-variant@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-XML-Variant>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
