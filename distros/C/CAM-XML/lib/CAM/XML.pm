package CAM::XML;

use 5.006;
use strict;
use warnings;
use CAM::XML::Text;
use English qw(-no_match_vars);
use Carp;

our $VERSION = '1.14';

=for stopwords XHTML XPath pre-formatted attr1 attr2

=head1 NAME 

CAM::XML - Encapsulation of a simple XML data structure

=head1 LICENSE

Copyright 2006 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SYNOPSIS

  my $pollTag = CAM::XML->new('poll');
  
  foreach my $q (@questions) {
    my $questionTag = CAM::XML->new('question');
    
    $questionTag->add(-text => $q->{text});
    my $choicesTag = CAM::XML->new('choices');
    
    foreach my $c (@{$q->{choices}}) {
      my $choiceTag = CAM::XML->new('choice');
      $choiceTag->setAttributes('value', $c->{value});
      $choiceTag->add(-text => $c->{text});
      $choicesTag->add($choiceTag);
    }
    $questionTag->add($choicesTag);
    $pollTag->add($questionTag);
  }
  print CAM::XML->header();
  print $pollTag->toString();

=head1 DESCRIPTION

This module reads and writes XML into a simple object model.  It is
optimized for ease of creating code that interacts with XML.

This module is not as powerful or as standards-compliant as say
XML::LibXML, XML::SAX, XML::DOM, etc, but it's darn easy to use.  I
recommend it to people who want to just read/write a quick but valid
XML file and don't want to bother with the bigger modules.

In our experience, this module is actually easier to use than
XML::Simple because the latter makes some assumptions about XML
structure that prevents it from handling all XML files well.  YMMV.

However, one exception to the simplicity claimed above is our
implementation of a subset of XPath.  That's not very simple.  Sorry.

=head1 CLASS METHODS

=over

=item $pkg->parse($xmlstring)

=item $pkg->parse(-string => $xmlstring)

=item $pkg->parse(-filename => $xmlfilename)

=item $pkg->parse(-filehandle => $xmlfilehandle)

Parse an incoming stream of XML into a CAM::XML hierarchy.  This
method just hands the first argument off to XML::Parser, so it can
accept any style of argument that XML::Parser can.  Note that XML::Parser
says the filehandle style should pass an IO::Handle object.  This can
be called as a class method or an instance method.

Additional meaningful flags:

  -cleanwhitespace => 1

Traverse the document and remove non-significant whitespace, as per
removeWhitespace().

  -xmlopts => HASHREF

Any options in this hash are passed directly to XML::Parser.

NOTE: this method does NOT work well on subclasses.  I tried, but
failed to fix it up.  The problems is that CAM::XML::XMLTree has to be
able to instantiate one of this class, but there's no really good way
to communicate with it yet.

=cut

sub parse
{
   my $pkg_or_self = shift;
   my $mode;
   if ($_[0] =~ m/\A-/xms)    # If no mode was specified, imply one
   {
      $mode = shift;
   }
   else
   {
      $mode = '-string';
   }
   my $xml   = shift;
   my %flags = (@_);

   local $SIG{__DIE__};
   local $SIG{__WARN__};
   require CAM::XML::XMLTree;
   require XML::Parser;
   my $pkg = ref $pkg_or_self;
   if (!$pkg)
   {
      $pkg = $pkg_or_self;
   }
   my $p = XML::Parser->new(Style => $pkg.'::XMLTree',
                            $flags{-xmlopts} ? %{$flags{xmlopts}} : ());
   my $self;
   if ($mode eq '-filename')
   {
      if (open my $fh, '<', $xml)
      {
         local $INPUT_RECORD_SEPARATOR = undef;
         eval {
            $self = $p->parse(<$fh>);
         };
         close $fh;
      }
   }
   else
   {
      eval {
         $self = $p->parse($xml);
      };
   }
   if ($self && $flags{-cleanwhitespace})
   {
      $self->removeWhitespace();
   }
   return $self;
}

=item $pkg->new($tagname)

=item $pkg->new($tagname, attr1 => $value1, attr2 => $value2, ...)

Create a new XML tag.  Optionally, you can set tag attributes at the
same time.

=cut

sub new
{
   my $pkg  = shift;
   my $name = shift;

   if (!$name)
   {
      croak 'No XML tag name specified';
   }

   my $self = bless {
      name       => $name,
      attributes => {},
      children   => [],
   }, $pkg;

   return $self->setAttributes(@_);
}

=item $pkg->header()

=item $self->header()

Return a string containing the following message, suffixed by a newline:

  <?xml version="1.0" encoding="UTF-8" standalone="no" ?>

=cut

sub header
{
   return qq[<?xml version="1.0" encoding="UTF-8" standalone="no" ?>\n];
}

=back

=head1 INSTANCE METHODS

=over

=item $self->getName()

Returns the name of the node.

=cut

sub getName
{
   my $self = shift;
   return $self->{name};
}

=item $self->setAttributes(attr1 => $value1, attr2 => $value2, ...)

Set the value of one or more XML attributes.  If any keys are
duplicated, only the last one set is recorded.

=cut

sub setAttributes
{
   my $self = shift;

   while (@_ > 0)
   {
      my $key   = shift;
      my $value = shift;
      if (!defined $key || $key eq q{})
      {
         croak 'Invalid key specified';
      }
      $self->{attributes}->{$key} = $value;
   }
   return $self;
}

=item $self->deleteAttribute($key)

Remove the specified attribute if it exists.

=cut

sub deleteAttribute
{
   my $self = shift;
   my $key = shift;

   delete $self->{attributes}->{$key};
   return $self;
}

=item $self->getAttributeNames()

Returns a list of the names of all the attributes of this node.  The
names are returned in arbitrary order.

=cut

sub getAttributeNames
{
   my $self = shift;

   return keys %{ $self->{attributes} };
}

=item $self->getAttributes()

Returns a hash of all attributes.

=cut

sub getAttributes
{
   my $self = shift;

   return %{ $self->{attributes} };
}

=item $self->getAttribute($key)

Returns the value of the named attribute, or undef if it does not exist.

=cut

sub getAttribute
{
   my $self = shift;
   my $key  = shift;

   return $key ? $self->{attributes}->{$key} : undef;
}

=item $self->getChildren()

Returns an array of XML nodes and text objects contained by this node.

=cut

sub getChildren
{
   my $self = shift;
   return @{ $self->{children} };
}

=item $self->getChild($index)

Returns a child of this node.  The argument is a zero-based index.
Returns undef if the index is not valid.

=cut

sub getChild
{
   my $self  = shift;
   my $index = shift;

   return if (!defined $index || $index !~ m/\A\d+\z/xms);
   return $self->{children}->[$index];
}

=item $self->getChildNodes()

Returns an array of XML nodes contained by this node (that is, unlike
getChildren(), text nodes are ignored).

=cut

sub getChildNodes
{
   my $self = shift;

   return grep { $_->isa(__PACKAGE__) } @{ $self->{children} };
}

=item $self->getChildNode($index)

Returns a CAM::XML child of this node (that is, unlike getChild(),
text nodes are ignored.  The argument is a zero-based index.  Returns
undef if the index is not valid.

=cut

sub getChildNode
{
   my $self  = shift;
   my $index = shift;

   return if (!defined $index || $index !~ m/\A\d+\z/xms);
   my @kids = grep { $_->isa(__PACKAGE__) } @{ $self->{children} };
   return $kids[$index];
}

=item $self->setChildren($node1, $node2, ...)

Removes all the children from this node and replaces them with the
supplied values.  All of the values MUST be CAM::XML or CAM::XML::Text
objects, or this method will abort and return false before any changes
are made.

=cut

sub setChildren
{
   my $self = shift;

   my @good = grep { defined $_ && ref $_ && 
                     ($_->isa(__PACKAGE__) || $_->isa('CAM::XML::Text')) } @_;
   if (@good != @_)
   {
      croak 'Attempted to add bogus XML node';
   }

   @{ $self->{children} } = @good;
   return $self;
}

=item $self->add(CAM::XML instance)

=item $self->add(-text => $text)

=item $self->add(-cdata => $text)

=item $self->add(-xml => $rawxml)

=item $self->add(<multiple elements of the above types>)

Add content within the current tag.  Order of addition may be
significant.  This content can be any one of 1) subsidiary XML tags
(CAM::XML), 2) literal text content (C<-text> or C<-cdata>), or 3)
pre-formatted XML content (C<-xml>).

In C<-text> and C<-cdata> content, any reserved characters will be
automatically escaped.  Those two modes differ only in their XML
representation: C<-cdata> is more human-readable if there are a lot of
"&", "<" and ">" characters in your text, where C<-text> is usually more
compact for short strings.  These strings are not escaped until
output.

Content in C<-xml> mode is parsed in as CAM::XML objects.  If it is not
valid XML, a warning will be emitted and the add will fail.

=cut

sub add
{
   my $self = shift;

   while (@_ > 0)
   {
      my $add = shift;

      # Test different kinds of input
        !$add                                   ? croak 'Undefined object'
      : ref $add && $add->isa(__PACKAGE__)      ? push @{ $self->{children} }, $add
      : ref $add && $add->isa('CAM::XML::Text') ? push @{ $self->{children} }, $add
      : ref $add                                ? croak 'Invalid object type to add to a CAM::XML node'
      : $add =~ m/\A-(text|cdata)\z/xms         ? $self->_add_text($1, shift)
      : $add eq '-xml'                          ? $self->_add_xml(shift)
      : croak "Unknown flag '$add'.  Expected '-text' or '-cdata' or '-xml'";
   }

   return $self;
}

sub _add_text
{
   my $self = shift;
   my $type = shift;
   my $text = shift;

   if (!defined $text)
   {
      $text = q{};
   }
   
   # If the previous element was the same kind of text item
   # then merge them.  Otherwise append this text item.
   
   if (@{ $self->{children} } > 0 &&
       $self->{children}->[-1]->isa('CAM::XML::Text') &&
       $self->{children}->[-1]->{type} eq $type)
   {
      $self->{children}->[-1]->{text} .= $text;
   }
   else
   {
      push @{ $self->{children} }, CAM::XML::Text->new($type => $text);
   }
   return;
}

sub _add_xml
{
   my $self = shift;
   my $xml  = shift;

   my $parsed = $self->parse($xml);
   if ($parsed)
   {
      $self->add($parsed);
   }
   else
   {
      croak 'Tried to add invalid XML content';
   }
   return;
}

=item $self->removeWhitespace()

Clean out all non-significant whitespace.  Whitespace is deemed
non-significant if it is bracketed by tags.  This might not be true in
some data formats (e.g. HTML) so don't use this function carelessly.

=cut

sub removeWhitespace
{
   my $self = shift;

   my @delete_indices  = ();
   my $lasttag = -1;
   foreach my $i (0 .. $#{ $self->{children} })
   {
      my $child = $self->{children}->[$i];
      if ($child->isa(__PACKAGE__))
      {
         if (defined $lasttag)
         {
            push @delete_indices, ($lasttag + 1) .. ($i - 1);
         }
         $child->removeWhitespace();
         $lasttag = $i;
      }
      elsif ($child->{text} =~ m/\S/xms) # CAM::XML::Text instance
      {
         $lasttag = undef;
      }
   }
   if (defined $lasttag)
   {
      push @delete_indices, ($lasttag + 1) .. $#{ $self->{children} };
   }
   while (@delete_indices > 0)
   {
      my $node_index = pop @delete_indices;
      splice @{ $self->{children} }, $node_index, 1;
   }
   return $self;
}

=item $self->getInnerText()

For the given node, descend through all of its children and
concatenate all the text values that are found.  If none, this method
returns an empty string (not undef).

=cut

sub getInnerText
{
   my $self = shift;

   my $text  = q{};
   my @stack = ([@{ $self->{children} }]);
   while (@stack > 0)
   {
      my $list  = $stack[-1];
      my $child = shift @{$list};
      if ($child)
      {
         if ($child->isa(__PACKAGE__))
         {
            push @stack, [@{ $child->{children} }];
         }
         else # CAM::XML::Text
         {
            $text .= $child->{text};
         }
      }
      else
      {
         pop @stack;
      }
   }
   return $text;
}

=item $self->getNodes(-tag => $tagname)

=item $self->getNodes(-attr => $attrname, -value => $attrvalue)

=item $self->getNodes(-path => $path)

Return an array of CAM::XML objects representing nodes that match the
requested properties.

A path is a syntactic path into the XML doc something like an XPath

  '/' divides nodes
  '//' means any number of nodes
  '/[n]' means the nth child of a node (1-based)
  '<tag>[n]' means the nth instance of this node
  '/[-n]' means the nth child of a node, counting backward
  '/[last()]' means the last child of a node (same as [-1])
  '/[@attr="value"]' means a node with this attribute value
  '/text()' means all of the text data inside a node
            (note this returns just one node, not all the nodes)

For example, C</html/body//table/tr[1]/td/a[@target="_blank"]>
searches an XHTML body for all tables, and returns all anchor nodes in
the first row which pop new windows.

Please note that while this syntax resembles XPath, it is FAR from a
complete (or even correct) implementation.  It's useful for basic
delving into an XML document, however.

=cut

sub getNodes
{
   my $self     = shift;
   my %criteria = (@_);

   if ($criteria{-path})
   {
      # This is a very different beast.  Handle it separately.
      return $self->_get_path_nodes($criteria{-path}, [$self]);
   }

   my @list  = ();
   my @stack = ([$self]);
   while (@stack > 0)
   {
      my $list = $stack[-1];
      my $obj  = shift @{$list};
      if ($obj)
      {
         if ($obj->isa(__PACKAGE__))
         {
            push @stack, [@{ $obj->{children} }];
            if (($criteria{-tag} && $criteria{-tag} eq $obj->{name}) ||
                ($criteria{-attr} && exists $obj->{attributes}->{$criteria{-attr}} &&
                 $obj->{attributes}->{$criteria{-attr}} eq $criteria{-value}))
            {
               push @list, $obj;
            }
         }
      }
      else
      {
         pop @stack;
      }
   }
   return @list;
}

# Internal use only

sub _get_path_nodes
{
   my $self = shift;
   my $path = shift;
   my $kids = shift || $self->{children};

   my @list = !$path                                   ? $self
            : $path =~ m,\A /?text\(\)          \z,xms ? $self->_get_path_nodes_text()
            : $path =~ m,\A /?\[(\d+)\](.*)     \z,xms ? $self->_get_path_nodes_easyindex($kids, $1, $2)
            : $path =~ m,\A /?\[([^\]]+)\](.*)  \z,xms ? $self->_get_path_nodes_index($kids, $1, $2)
            : $path =~ m,\A //+                 \z,xms ? $self->_get_path_nodes_all($kids, $path)
            : $path =~ m,   (/?)(/?)([^/]+)(.*) \z,xms ? $self->_get_path_nodes_match($kids, $path, $1, $2, $3, $4)
            : croak "path not understood: '$path'";

   return @list;
}


sub _get_path_nodes_text
{
   my $self = shift;

   return CAM::XML::Text->new(text => $self->getInnerText());
}

sub _get_path_nodes_easyindex
{
   my $self = shift;
   my $kids = shift;
   my $num  = shift;
   my $rest = shift;
   
   # this is a special case of _get_path_nodes_index
   # it's higher performance since we can go straight to the
   # index instead of looping

   my $match = $kids->[$num - 1];
   return $match ? $match->_get_path_nodes($rest) : ();
}

sub _get_path_nodes_index
{
   my $self  = shift;
   my $kids  = shift;
   my $limit = shift;
   my $rest  = shift;

   my $index = 0;
   my @list;
   foreach my $node (@{$kids})
   {
      ++$index;    # one-based
      if ($self->_match($node, undef, $limit, $index, scalar @{$kids}))
      {
         push @list, $node->_get_path_nodes($rest);
      }
   }
   return @list;
}

sub _get_path_nodes_all
{
   my $self = shift;
   my $kids = shift;
   my $path = shift;

   my @list;
   foreach my $node (@{$kids})
   {
      if ($node->isa(__PACKAGE__))
      {
         push @list, $node, $node->_get_path_nodes($path);
      }
   }
   return @list;
}

sub _get_path_nodes_match
{
   my $self  = shift;
   my $kids  = shift;
   my $path = shift;
   my $base  = shift;
   my $any   = shift;
   my $match = shift;
   my $rest  = shift;

   my @list;
   my $limit = undef;
   if ($match =~ s,\[([^\]]+)\]\z,,xms)
   {
      $limit = $1;
      if (!$limit)
      {
         croak "bad index in path (indices are one-based): '$path'";
      }
   }
   if ($match && $limit)
   {
      # This is a special case that arose from a bug in _match()
      # TODO: move the @group and $index logic into _match()
      my @group;
      my $index = 0;
      my $max   = 0;
      foreach my $node (@{$kids})
      {
         ++$index;    # one-based
         if ($self->_match($node, $match, undef, $index, scalar @{$kids}))
         {
            push @group, 1;
            $max++;
         }
         else
         {
            push @group, 0;
         }
      }
      $index = 0;
      foreach my $i (0 .. $#{$kids})
      {
         my $node = $kids->[$i];
         if ($group[$i])
         {
            ++$index;    # one-based
            if ($self->_match($node, undef, $limit, $index, $max))
            {
               push @list, $node->_get_path_nodes($rest);
            }
         }
         if ($any)
         {
            push @list, $node->_get_path_nodes($path);
         }
      }
   }
   elsif ($match || $limit)
   {
      my $index = 0;
      foreach my $node (@{$kids})
      {
         ++$index;    # one-based
         if ($self->_match($node, $match, $limit, $index, scalar @{$kids}))
         {
            push @list, $node->_get_path_nodes($rest);
         }
         if ($any)
         {
            push @list, $node->_get_path_nodes($path);
         }
      }
   }
   else
   {
      die 'Internal error: neither match nor limit were true';
   }
   return @list;
}

sub _match
{
   my $self  = shift;
   my $node  = shift;
   my $tag   = shift;
   my $limit = shift;
   my $index = shift;    # one-based
   my $max   = shift;

   if ($tag && $limit)
   {
      die 'Internal error: _match() is broken for simultaneous tag and index matches';
      # currently, the $tag && $limit case is handled externally.
      # TODO: handle this better
   }

   my $is_element = $node->isa(__PACKAGE__);
   if ($tag)
   {
      return if (!$is_element);
      return if ($node->{name} ne $tag);
   }
   if ($limit)
   {
      # massaging
      if ($limit eq 'last()')
      {
         $limit = -1;
      }

      if ($limit =~ m/\A\-\d+/xms)
      {
         return if ($max + $limit + 1 != $index);
      }
      elsif ($limit =~ m/\A\d+/xms)
      {
         return if ($limit != $index);
      }
      elsif ($limit =~ m/\A\@(\w+)=\"([^\"]*)\"\z/xms ||
             $limit =~ m/\A\@(\w+)=\'([^\']*)\'\z/xms)
      {
         return if (!$is_element);
         my $attr = $1;
         my $val  = $2;
         my $cmp  = $node->{attributes}->{$attr};
         return if (!defined $cmp || $val ne $cmp);
      }
      else
      {
         croak "path predicate not understood: '$limit'";
      }
   }
   return $self;
}

=item $self->toString([OPTIONS])

Serializes the tag and all subsidiary tags into an XML string.  This
is called recursively on any subsidiary CAM::XML objects.  Note that
the XML header is not prepended to this output.

The following optional arguments apply:

  -formatted => boolean
        If true, the XML is indented nicely.  Otherwise, no whitespace
        is inserted between tags.
  -textformat => boolean
        Only relevent if -formatted is true.  If false, this prevents
        the formatting of pure text values.
  -level => number
        Indents this tag by the number of levels indicated.  This implies
        -formatted => 1
  -indent => number
        The number of spaces to indent per level if the output is
        formatted.  By default, this is 2 (i.e. two spaces).

Example: -formatted => 0

   <foo><bar>Baz</bar></foo>

Example: -formatted => 1

   <foo>
     <bar>
       Baz
     </bar>
   </foo>

Example: C<-formatted =E<gt> 1, textformat =E<gt> 0>

   <foo>
     <bar>Baz</bar>
   </foo>

Example: C<-formatted =E<gt> 1, textformat =E<gt> 0, -indent =E<gt> 4>

   <foo>
       <bar>Baz</bar>
   </foo>

=cut

sub toString
{
   my $self = shift;
   my %args = (@_);

   if ($args{'-formatted'} && !exists $args{'-level'})
   {
      $args{'-level'} = 0;
      if (!exists $args{'-textformat'})
      {
         $args{'-textformat'} = 1;
      }
   }
   if (!defined $args{'-indent'} || $args{'-indent'} =~ m/\D/xms)
   {
      $args{'-indent'} = 2;
   }

   return join q{}, $self->_to_string(%args);
}

sub _to_string
{
   my $self = shift;
   my %args = (@_);

   my $level  = $args{'-level'};
   my $indent = defined $level ? q{ } x $args{'-indent'} : q{};
   my $begin  = defined $level ? $indent x $level        : q{};
   my $end    = defined $level ? "\n"                    : q{};

   # open tag
   my @ret = ( $begin, '<', $self->_XML_escape($self->{name}) );

   # attributes
   foreach my $key (sort keys %{ $self->{attributes} })
   {
      push @ret, (
         q{ }, $self->_XML_escape($key), q{=},
         q{"}, $self->_XML_escape($self->{attributes}->{$key}), q{"},
      );
   }

   # Empty tag?
   if (@{ $self->{children} } == 0)
   {
      push @ret, '/>', $end;
   }

   # Body is pure text?
   elsif ($args{'-formatted'} && !$args{'-textformat'}
          && 0 == scalar grep {$_->isa(__PACKAGE__)} @{$self->{children}})
   {
      push @ret, '>';
      push @ret, map { $_->toString() } @{ $self->{children} };
      push @ret, '</', $self->{name}, '>', $end;
   }

   # Body has elements
   else
   {
      push @ret, '>', $end;
      foreach my $child (@{ $self->{children} })
      {
         if ($child->isa(__PACKAGE__))
         {
            push @ret, $child->_to_string(
               %args, -level => defined $level ? $level+1 : undef,
            );
         }
         else
         {
            push @ret, $begin, $indent, $child->toString(), $end;
         }
      }
      push @ret, $begin, '</', $self->{name}, '>', $end;
   }

   return @ret;
}

# Private function
sub _XML_escape
{
   my $pkg_or_self = shift;
   my $text        = shift;

   if (!defined $text)
   {
      $text = q{};
   }
   $text =~ s/&/&amp;/gxms;
   $text =~ s/</&lt;/gxms;
   $text =~ s/>/&gt;/gxms;
   $text =~ s/\"/&quot;/gxms;
   return $text;
}

# Private function
sub _CDATA_escape
{
   my $pkg_or_self = shift;
   my $text        = shift;

   # Escape illegal "]]>" strings by ending and restarting the CDATA section
   $text =~ s/ ]]> /]]>]]&gt;<![CDATA[/gxms;

   return "<![CDATA[$text]]>";
}

1;
__END__

=back

=head1 ENCODING

It is assumed that all text will be UTF-8.  This includes any tag
names, attribute keys and values, text content, and raw XML content
that are added to the data structure.

=head1 CODING

This module has just over 97% code coverage in its regression tests,
as reported by Devel::Cover via C<perl Build testcover>.  The
remaining few percent is mostly error conditions and a few conditional
defaults on internal methods.

This module passes most of the Perl Best Practices guidelines, as
enforced by Perl::Critic v0.14.  A notable exceptions is the
legacy use of C<camelCase> subroutine names.

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary Developer: Chris Dolan

=cut
