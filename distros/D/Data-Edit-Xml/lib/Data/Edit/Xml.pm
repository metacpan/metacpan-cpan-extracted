#!/usr/bin/perl
#-I/home/phil/z/perl/cpan/DataTableText/lib
#-------------------------------------------------------------------------------
# Edit data held in xml format
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------
# podDocumentation

package Data::Edit::Xml;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Table::Text qw(:all);
use XML::Parser;                                                                # https://metacpan.org/pod/XML::Parser
our $VERSION = 20170719;

#1 Constructor

sub new(;$)                                                                     # New parse - call this method statically as in Data::Edit::Xml::new(file or string) B<or> with no parameters and then use L</input>, L</inputFile>, L</inputString>, L</errorFile>  to provide specific parameters for the parse, then call L</parse> to perform the parse and return the parse tree
 {my ($fileNameOrString) = @_;                                                  # File name or string
  if (@_)
   {my $x = bless {input=>$fileNameOrString};                                   # Create xml editor with a string or file
    $x->parser = $x;                                                            # Parser node
    return $x->parse;                                                           # Parse
   }
  my $x = bless {};                                                             # Create empty xml editor
  $x->parser = $x;                                                              # Parser node
  $x                                                                            # Parser
 }

genLValueScalarMethods(qw(parent));                                             # Parent node of this node or undef if root node, see also L</Traversal> and L</Navigation>. Consider as read only.
genLValueScalarMethods(qw(parser));                                             # Parser details: the root node of a tree is the parse node for that tree. Consider as read only.
genLValueScalarMethods(qw(tag));                                                # Tag name for this node, see also L</Traversal> and L</Navigation>. Consider as read only.
genLValueScalarMethods(qw(input));                                              # Source of the parse if this is the parser node. Use this parameter to specify some input either as a string or as a file name for the parser to convert into a parse tree
genLValueScalarMethods(qw(inputFile));                                          # Source file of the parse if this is the parser node. Use this parameter to explicitly set the file to be parsed.
genLValueScalarMethods(qw(inputString));                                        # Source string of the parse if this is the parser node. Use this parameter to explicitly set the string to be parsed.
genLValueScalarMethods(qw(errorsFile));                                         # Error listing file. Use this parameter to explicitly set the name of the filw that will be used to write an parse errors to, by default this file is named: B<zzzParseErrors/out.data>
genLValueScalarMethods(qw(text));                                               # Text of this node but only if it is a text node, i.e. the tag is cdata() <=> L</isText> is true
genLValueArrayMethods (qw(content));                                            # Content of command: the nodes immediately below this node in the order in which they appeared in the source text, see also L</Contents>
genLValueHashMethods  (qw(attributes));                                         # The attributes of this node, see also: L</Attributes>,  The frequently used attributes: class, id, href, outputclass can be accessed by an lvalue method as in: $node->id = 'c1'
genLValueHashMethods  (qw(conditions));                                         # Conditional strings attached to a node, see L</Conditions>
genLValueHashMethods  (qw(indexes));                                            # Indexes to sub commands by tag in the order in which they appeared in the source text

sub cdata                                                                       # The name of the tag to be used to represent text - this tag must not also be used as a command tag otherwise chaos will occur

 {'CDATA'
 }

sub parse($)                                                                    # Parse input xml
 {my ($p) = @_;                                                                 # Parser created by L</new>
  my $badFile = $p->errorsFile // 'zzzParseErrors/out.data';                    # File to write source xml into if a parsing error occurs
  unlink $badFile if -e $badFile;                                               # Remove existing errors file

  if (my $s = $p->input)                                                        # Source to be parsed is a file or a string
   {if ($s =~ /\n/gs or !-e $s)                                                 # Parse as a string becuase it does not look like a file name
     {$p->inputString = $s;
     }
    else                                                                        # Parse a file
     {$p->inputFile = $s;
      $p->inputString = readFile($s);
     }
   }
  elsif (my $f = $p->inputFile)                                                 # Source to be parsed is a file
   {$p->inputString = readFile($f);
   }
  elsif ($p->inputString) {}                                                    # Source to be parsed is a string
  else                                                                          # Unknown string
   {confess "Supply a string or file to be parsed";
   }

  my $parser = new XML::Parser(Style => 'Tree');                                # Extend Larry Wall's excellent XML parser
  my $d = $p->inputString;                                                      # String to be parsed
  my $x = eval {$parser->parse($d)};                                            # Parse string
  if (!$x)                                                                      # Error in parse
   {my $f = $p->inputFile ? "Source files is:\n".$p->inputFile."\n" : '';       # Source details if a file
    writeFile($badFile, "$d\n$f\n$@\n");                                        # Write a description of the error to the errorsFile
    confess "Xml parse error, see file:\n$badFile\n";                           # Complain helpfully if parse failed
   }
  $p->tree($x);                                                                 # Structure parse results as a tree
  if (my @c = @{$p->content})
   {confess "No xml" if !@c;
    confess "More than one outer-most tag" if @c > 1;
    my $c = $c[0];
    $p->tag        = $c->tag;
    $p->attributes = $c->attributes;
    $p->content    = $c->content;
    $p->parent     = undef;
    $p->indexNode;
   }
  $p                                                                            # Parse details
 }

sub tree($$)                                                                    ## Build a tree representation of the parsed xml which can be easily traversed to look for things
 {my ($parent, $parse) = @_;                                                    # The parent node, the remaining parse
  while(@$parse)
   {my $tag  = shift @$parse;                                                   # Tag for node
    my $node = bless {parser=>$parent->parser};                                 # New node
    if ($tag eq cdata)
     {confess cdata.'tag encountered';                                          # We use this tag for text and so it cannot be used as a user tag in the document
     }
    elsif ($tag eq '0')                                                         # Text
     {my $s = shift @$parse;
      if ($s !~ /\A\s*\Z/)                                                      # Ignore entirely blank strings
       {$s = replaceSpecialChars($s);                                           # Replace < and > in text with xml special characters
        $node->tag = cdata;                                                     # Save text. ASSUMPTION: CDATA is not used as a tag anywhere.
        $node->text = $s;
        push @{$parent->content}, $node;                                        # Save on parents content list
       }
     }
    else                                                                        # Node
     {my $children   = shift @$parse;
      my $attributes = shift @$children;
      $node->tag = $tag;                                                        # Save tag
      $node->attributes = $attributes;                                          # Save attributes
      push @{$parent->content}, $node;                                          # Save on parents content list
      $node->tree($children) if $children;                                      # Add nodes below this node
     }
   }
  $parent->indexNode;                                                           # Index this node
 }

sub newText($$)                                                                 # Create a new text node
 {my (undef, $text) = @_;                                                       # Any reference to this package, content of new text node
  my $node = bless {};                                                          # New node
  $node->parser = $node;                                                        # Root node of this parse
  $node->tag    = cdata;                                                        # Text node
  $node->text   = $text;                                                        # Content of node
  $node                                                                         # Return new non text node
 }

sub newTag($$%)                                                                 # Create a new non text node
 {my (undef, $command, %attributes) = @_;                                       # Any reference to this package, the tag for the node, attributes as a hash
  my $node = bless {};                                                          # New node
  $node->parser = $node;                                                        # Root node of this parse
  $node->tag    = $command;                                                     # Tag for node
  $node->attributes = \%attributes;                                             # Attributes for node
  $node                                                                         # Return new node
 }

sub newTree($%)                                                                 # Create a new tree - this is a static method
 {my ($command, %attributes) = @_;                                              # The name of the root node in the tree, attributes of the root node in the tree as a hash
  &newTag(undef, @_)
 }

sub indexNode($)                                                                ## Index the children of a node so that we can access them by tag and number
 {my ($node) = @_;                                                              # Node to index
  delete $node->{indexes};                                                      # Delete the indexes
  my @contents = $node->contents;                                               # Contents of the node
  return unless @contents;                                                      # No content so no indexes

  if (grep {$_->isText} @contents)                                              # Make parsing easier for the user by concatenating successive text nodes with a blank between them (so that they do not elide) so that there are never two or more successive text nodes under a node and if there is a text node then it is non blank
   {my (@c, @t);                                                                # New content, pending intermediate text
    for(@contents)                                                              # Each node under the current node
     {if ($_->isText)                                                           # Text node
       {push @t, $_ if @t or $_->text !~ m(\A\s*\Z)s;                           # Add the text node if not a leading blank node
       }
      elsif (@t)                                                                # Non text element encountered with pending intermediate text
       {if (@t == 1) {push @c, @t}                                              # Just one text node, add it as it cannot be blank as leading blank nodes are suppressed
        else                                                                    # More than one text node - remove leading and trailing blank text nodes
         {pop @t while @t and $t[-1] =~ m(\A\s*\Z)s;                            # Remove trailing blank text nodes
          if (@t == 1) {push @c, @t}                                            # Single non blank text node - there must be at least one to have gotten this far
          else                                                                  # Leading and trailing non blank text nodes possibly with multiple interior blank text nodes which we allow to persist
           {my $t = shift @t;                                                   # Reuse the first text node
            $t->text .= join ' ', map {$_->text} @t;                            # Concatenate the remaining text nodes with single intervening spaces to stop them eliding - really we should remove multiple spacing nodes but that would be a lot of work: the current method is faster while being safe
            push @c, $t;                                                        # Save resulting text node
           }
         }
        push @c, $_;                                                            # Save current non text node after combined preceding text nodes
        @t = ();                                                                # Empty pending intermediate text list
       }
      else {push @c, $_}                                                        # Non text node encountered without immediately preceding text
     }

    if (!@t) {}                                                                 # No action required if no pending text at the end
    elsif (@t == 1) {push @c, @t}                                               # Just one text node, add it as it cannot be blank as leading blank nodes are suppressed
    else                                                                        # More than one text node - remove leading and trailing blank text nodes
     {pop @t while @t and $t[-1] =~ m(\A\s*\Z)s;                                # Remove trailing blank text nodes
      if (@t == 1) {push @c, @t}                                                # Single non blank text node - there must be at least one to have gotten this far
      else                                                                      # Leading and trailing non blank text nodes possibly with multiple interior blank text nodes which we allow to persist
       {my $t = shift @t;                                                       # Reuse the first text node
        $t->text .= join ' ', map {$_->text} @t;                                # Concatenate the remaining text nodes with single intervening spaces to stop them eliding - really we should remove multiple spacing nodes but that would be a lot of work: the current method is faster while being safe
        push @c, $t;                                                            # Save resulting text element
       }
     }
    @contents = @c;                                                             # The latest content of the node
    $node->content = \@c;                                                       # Node contents with no more than one text element at a time
   }

  if (@contents == 1)                                                           # Empty the current node if it contains just one blank string as its content
   {for my $c(@contents)
     {if ($c->isText and $c->text =~ m(\A\s*\Z)s)
       {$node->content = undef;
        $c->parent = undef;
        return;
       }
     }
   }

  for my $n(@contents)                                                          # Index content
   {push @{$node->indexes->{$n->tag}}, $n;                                      # Indices to sub nodes
    $n->parent = $node;                                                         # Point to parent
    $n->parser = $node->parser;                                                 # Point to parser
   }
 }

sub replaceSpecialChars($)                                                      ## Replace < and > with &lt; and &gt; in a string
 {my ($s) = @_;                                                                 # String
  $s =~ s/\</&lt;/gr =~ s/\>/&gt;/gr;                                           # Larry Wall's parser unfortunately replaces &lt and &gt with their expansions in text and does not seem to provide away to stop this behaviour, so we have to put them back
 }

sub tags($)                                                                     # Count the number of tags in a parse tree
 {my ($node) = @_;                                                              # Parse tree
  my $n = 0;
  $node->by(sub {++$n});                                                        # Count tags including CDATA
  $n                                                                            # Number of tags encountered
 }

#1 Stringification                                                              # Print the parse tree

sub string($)                                                                   # Return a string representing a node of a parse tree and all the nodes below it
 {my ($node) = @_;                                                              # Start node
  return $node->text if $node->isText;                                          # Text node
  my $t = $node->tag;                                                           # Not text so it has a tag
  my $content = $node->content;                                                 # Sub nodes
  return '<'.$t.$node->printAttributes.'/>' if !@$content;                      # No sub nodes

  my $s = '<'.$t.$node->printAttributes.'>';                                    # Has sub nodes
  $s .= $_->string for @$content;                                               # Recurse to get the sub content
  return $s.'</'.$t.'>';
 }

sub contentString($)                                                            # Return a string representing all the nodes below a node of a parse tree
 {my ($node) = @_;                                                              # Start node
  my $s = '';
  $s .= $_->string for $node->contents;                                         # Recurse to get the sub content
  $s
 }

sub prettyString($;$)                                                           # Return a readable string representing a node of a parse tree and all the nodes below it
 {my ($node, $depth) = @_;                                                      # Start node, depth
  $depth //= 0;                                                                 # Start depth if none supplied

  if ($node->isText)                                                            # Text node
   {my $n = $node->next;
    my $s = $n && $n->isText ? '' : "\n";                                       # Add a new line after contiguous blocks of text to offset next node
    return $node->text.$s;
   }

  my $t = $node->tag;                                                           # Not text so it has a tag
  my $content = $node->content;                                                 # Sub nodes
  my $space   = "\t"x($depth//0);
  return $space.'<'.$t.$node->printAttributes.'/>'."\n" if !@$content;          # No sub nodes

  my $s = $space.'<'.$t.$node->printAttributes.'>'.                             # Has sub nodes
    ($node->first->isText ? '' : "\n");                                         # Continue text on the same line, otherwise place nodes on following lines
  $s .= $_->prettyString($depth+2) for @$content;                               # Recurse to get the sub content
  return $s.$space.'</'.$t.'>'."\n";
 }

sub PrettyContentString($)                                                      # Return a readable string representing all the nodes below a node of a parse tree - infrequent use and so capitialised to avoid being presented as an option by Geany
 {my ($node) = @_;                                                              # Start node
  my $s = '';
  $s .= $_->prettyString for $node->contents;                                   # Recurse to get the sub content
  $s
 }

#2 Conditions                                                                   # Print a subset of the the parse tree determined by the conditions attached to it

sub stringWithConditions($@)                                                    # Return a string representing a node of a parse tree and all the nodes below it subject to conditions to select or reject some nodes
 {my ($node, @conditions) = @_;                                                 # Start node, conditions to be regarded as in effect
  return $node->text if $node->isText;                                          # Text node
  my %c = %{$node->conditions};                                                 # Process conditions if any for this node
  return '' if keys %c and @conditions and !grep {$c{$_}} @conditions;          # Return if conditions are in effect and no conditions match
  my $t = $node->tag;                                                           # Not text so it has a tag
  my $content = $node->content;                                                 # Sub nodes

  my $s = ''; $s .= $_->stringWithConditions(@conditions) for @$content;        # Recurse to get the sub content
  return '<'.$t.$node->printAttributes.'/>' if !@$content or $s =~ /\A\s*\Z/;   # No sub nodes or none selected
  '<'.$t.$node->printAttributes.'>'.$s.'</'.$t.'>';                             # Has sub nodes
 }

sub addConditions($@)                                                           # Add conditions to a node and return the node
 {my ($node, @conditions) = @_;                                                 # Node, conditions to add
  $node->conditions->{$_}++ for @conditions;
  $node
 }

sub deleteConditions($@)                                                        # Delete conditions applied to a node and return the node
 {my ($node, @conditions) = @_;                                                 # Node, conditions to add
  delete $node->conditions->{$_} for @conditions;
  $node
 }

sub listConditions($)                                                           # Return a list of conditions applied to a node
 {my ($node) = @_;                                                              # Node
  sort keys %{$node->conditions}
 }

sub printAttributes($)                                                          ## Print the attributes of a node
 {my ($node) = @_;                                                              # Node whose attributes are to be printed
  my $a = $node->attributes;                                                    # Attributes
  defined($$a{$_}) ? undef : delete $$a{$_} for keys %$a;                       # Remove undefined attributes
  return '' unless keys %$a;                                                    # No attributes
  my $s = ' '; $s .= $_.'="'.$a->{$_}.'" ' for sort keys %$a; chop($s);         # Attributes enclosed in "" in alphabetical order
  $s
 }

#1 Attributes                                                                   # Get or set attributes

sub attr($$) :lvalue                                                            # Return the value of an attribute of the current node as an assignable value
 {my ($node, $attribute) = @_;                                                  # Node in parse tree, attribute name
  $node->attributes->{$attribute}
 }

sub attrs($@)                                                                   # Return the values of the specified attributes of the current node
 {my ($node, @attributes) = @_;                                                 # Node in parse tree, attribute names
  my @v;
  my $a = $node->attributes;
  push @v, $a->{$_} for @attributes;
  @v
 }

sub attrCount($)                                                                # Return the number of attributes in the specified node
 {my ($node) = @_;                                                              # Node in parse tree, attribute names
  my $a = $node->attributes;
  $a ? keys %$a : 0
 }

BEGIN
 {for(qw(class href id outputclass))                                            # Return well known attributes as an assignable value
   {eval 'sub '.$_.'($) :lvalue {&attr($_[0], qw('.$_.'))}';
    $@ and confess "Cannot create well known attribute $_\n$@";
   }
 }

sub setAttr($@)                                                                 # Set the value of an attribute in a node and return the node
 {my ($node, %values) = @_;                                                     # Node in parse tree, (attribute name=>new value)*
  $node->attributes->{$_} = $values{$_} for keys %values;
  $node
 }

sub deleteAttr($$;$)                                                            # Delete the attribute, optionally checking its value first and return the node
 {my ($node, $attr, $value) = @_;                                               # Node, attribute name, optional attribute value to check first
  my $a = $node->attributes;                                                    # Attributes hash
  if (@_ == 3)
   {delete $a->{$attr} if defined($a->{$attr}) and $a->{$attr} eq $value;       # Delete user key if it has the right value
   }
  else
   {delete $a->{$attr};                                                         # Delete user key unconditionally
   }
  $node
 }

sub deleteAttrs($@)                                                             # Delete any attributes mentioned in a list without checking their values and return the node
 {my ($node, @attrs) = @_;                                                      # Node, attribute name, optional attribute value to check first
  my $a = $node->attributes;                                                    # Attributes hash
  delete $a->{$_} for @attrs;
  $node
 }

sub renameAttr($$$)                                                             # Change the name of an attribute regardless of whether the new attribute already exists and return the node
 {my ($node, $old, $new) = @_;                                                  # Node, existing attribute name, new attribute name
  my $a = $node->attributes;                                                    # Attributes hash
  if (defined($a->{$old}))                                                      # Check old attribute exists
   {my $value = $a->{$old};                                                     # Existing value
    $a->{$new} = $value;                                                        # Change the attribute name
    delete $a->{$old};
   }
  $node
 }

sub changeAttr($$$)                                                             # Change the name of an attribute unless it has already been set and return the node
 {my ($node, $old, $new) = @_;                                                  # Node, existing attribute name, new attribute name
  exists $node->attributes->{$new} ? $node : $node->renameAttr($old, $new)      # Check old attribute exists
 }

sub renameAttrValue($$$$$)                                                      # Change the name and value of an attribute regardless of whether the new attribute already exists and return the node
 {my ($node, $old, $oldValue, $new, $newValue) = @_;                            # Node, existing attribute name and value, new attribute name and value
  my $a = $node->attributes;                                                    # Attributes hash
  if (defined($a->{$old}) and $a->{$old} eq $oldValue)                          # Check old attribute exists and has the specified value
   {$a->{$new} = $newValue;                                                     # Change the attribute name
    delete $a->{$old};
   }
  $node
 }

sub changeAttrValue($$$$$)                                                      # Change the name and value of an attribute unless it has already been set and return the node
 {my ($node, $old, $oldValue, $new, $newValue) = @_;                            # Node, existing attribute name and value, new attribute name and value
  exists $node->attributes->{$new} ? $node :                                    # Check old attribute exists
    $node->renameAttrValue($old, $oldValue, $new, $newValue)
 }

#1 Traversal                                                                    # Traverse the parse tree

sub by($$;@)                                                                    # Post-order traversal of a parse tree or sub tree and return the specified starting node
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  $_->by($sub, $node, @context) for @n;                                         # Recurse to process sub nodes in deeper context
  &$sub(local $_ = $node, @context);                                            # Process specified node last
  $node
 }

sub byReverse($$;@)                                                             # Reverse post-order traversal of a parse tree or sub tree and return the specified starting node
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  $_->by($sub, $node, @context) for reverse @n;                                 # Recurse to process sub nodes in deeper context
  &$sub(local $_ = $node, @context);                                            # Process specified node last
  $node
 }

sub down($$;@)                                                                  # Pre-order traversal down through a parse tree or sub tree and return the specified starting node
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$sub(local $_ = $node, @context);                                            # Process specified node first
  $_->down($sub, $node, @context) for @n;                                       # Recurse to process sub nodes in deeper context
  $node
 }

sub downReverse($$;@)                                                           # Reverse pre-order traversal down through a parse tree or sub tree and return the specified starting node
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$sub(local $_ = $node, @context);                                            # Process specified node first
  $_->down($sub, $node, @context) for reverse @n;                               # Recurse to process sub nodes in deeper context
  $node
 }

sub through($$$;@)                                                              # Traverse parse tree visiting each node twice and return the specified starting node
 {my ($node, $before, $after, @context) = @_;                                   # Starting node, sub to call when we meet a node, sub to call we leave a node, accumulated context
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$before(local $_ = $node, @context);                                         # Process specified node first with before()
  $_->through($before, $after, $node, @context) for @n;                         # Recurse to process sub nodes in deeper context
  &$after(local $_ = $node, @context);                                          # Process specified node last with after()
  $node
 }

#1 Contents                                                                     # Contents of the specified node

sub contents($)                                                                 # Return all the nodes contained by this node either as an array or as a reference to such an array
 {my ($node) = @_;                                                              # Node
  my $c = $node->content;                                                       # Contents reference
  $c ? @$c : ()                                                                 # Contents as an array
 }

sub contentBeyond($)                                                            # Return all the nodes following this node at the level of this node
 {my ($node) = @_;                                                              # Node
  my $parent = $node->parent;                                                   # Parent
  return () if !$parent;                                                        # The uppermost node has no content beyond it
  my @c = $parent->contents;                                                    # Contents of parent
  while(@c)                                                                     # Test until no more nodes left to test
   {my $c = shift @c;                                                           # Position of current node
    return @c if $c == $node                                                    # Nodes beyond this node if it is the searched for node
   }
  confess "Node not found in parent";                                           # Something wrong with parent/child relationship
 }

sub contentBefore($)                                                            # Return all the nodes preceding this node at the level of this node
 {my ($node) = @_;                                                              # Node
  my $parent = $node->parent;                                                   # Parent
  return () if !$parent;                                                        # The uppermost node has no content beyond it
  my @c = $parent->contents;                                                    # Contents of parent
  while(@c)                                                                     # Test until no more nodes left to test
   {my $c = pop @c;                                                             # Position of current node
    return @c if $c == $node                                                    # Nodes beyond this node if it is the searched for node
   }
  confess "Node not found in parent";                                           # Something wrong with parent/child relationship
 }

sub contentAsTags($)                                                            # Return a string containing the tags of all the nodes contained by this node separated by single spaces
 {my ($node) = @_;                                                              # Node
  join ' ', map {$_->tag} $node->contents
 }

sub contentBeyondAsTags($)                                                      # Return a string containing the tags of all the nodes following this node separated by single spaces
 {my ($node) = @_;                                                              # Node
  join ' ', map {$_->tag} $node->contentBeyond
 }

sub contentBeforeAsTags($)                                                      # # Return a string containing the tags of all the nodes preceding this node separated by single spaces
 {my ($node) = @_;                                                              # Node
  join ' ', map {$_->tag} $node->contentBefore
 }

sub position($)                                                                 # Return the index of a node in its parent's content
 {my ($node) = @_;                                                              # Node
  my @c = $node->parent->contents;                                              # Each node in parent content
  for(keys @c)                                                                  # Test each node
   {return $_ if $c[$_] == $node;                                               # Return index position of node which counts from zero
   }
  undef
 }

sub index($)                                                                    # Return the index of a node in its parent index
 {my ($node) = @_;                                                              # Node
  if (my @c = $node->parent->c($node->tag))                                     # Each node in parent index
   {for(keys @c)                                                                # Test each node
     {return $_ if $c[$_] == $node;                                             # Return index position of node which counts from zero
     }
   }
  undef
 }

sub present($@)                                                                 # Return the count of the number of the specified tag types present immediately under a node
 {my ($node, @names) = @_;                                                      # Node, possible tags immediately under the node
  my %i = %{$node->indexes};                                                    # Index of child nodes
  grep {$i{$_}} @names                                                          # Count of tag types present
 }

sub count($@)                                                                   # Return the count the number of instances of the specified tags under the specified node, either by tag in array context or in total in scalar context
 {my ($node, @names) = @_;                                                      # Node, possible tags immediately under the node
  if (wantarray)                                                                # In array context return the count for each tag specified
   {my @c;                                                                      # Count for the corresponding tag
    my %i = %{$node->indexes};                                                  # Index of child nodes
    for(@names)
     {if (my $i = $i{$_}) {push @c, scalar(@$i)} else {push @c, 0};             # Save corresponding count
     }
    return @c;                                                                  # Return count for each tag specified
   }
  else                                                                          # In scalar context count the total number of instances of the named tags
   {if (@names)
     {my $c = 0;                                                                # Tag count
      my %i = %{$node->indexes};                                                # Index of child nodes
      for(@names)
       {if (my $i = $i{$_}) {$c += scalar(@$i)}
       }
      return $c;
     }
    else                                                                        # In scalar context, with no tags specified, return the number of nodes under the specified node
     {my @c = $node->contents;
      return scalar(@c);                                                        # Count of all tags including CDATA
     }
   }
  confess "This should not happen"
 }

sub isText($)                                                                   # Confirm that this is a text node
 {my ($node) = @_;                                                              # Node to test
  $node->tag eq cdata
 }

#1 Navigation                                                                   # Move around in the parse tree

sub get($@)                                                                     # Return a sub node under the specified node by its position in each index with position zero assumed if no position is supplied
 {my ($node, @position) = @_;                                                   # Node, position specification: (index position?)* where position defaults to zero if not specified
  my $p = $node;                                                                # Current node
  while(@position)                                                              # Position specification
   {my $i = shift @position;                                                    # Index name
    $p or confess "No such node: $i";                                           # There is no node of the named type under this node
    my $q = $p->indexes->{$i};                                                  # Index
    defined $i or confess 'No such index: $i';                                  # Complain if no such index
    if (@position)                                                              # Position within index
     {if ((my $n = $position[0]) =~ /\A\d+\Z/)                                  # Numeric position in index from start
       {shift @position;
        $p = $q->[$n]
       }
      elsif ($n =~ /\A-\d+\Z/)                                                  # Numeric position in index from end
       {shift @position;
        $p = $q->[-$n]
       }
      elsif ($n =~ /\A\*\Z/ and @position == 1)                                 # Final index wanted
       {return @$q;
       }
      else {$p = $q->[0]}                                                       # Step into first sub node by default
     }
    else {$p = $q->[0]}                                                         # Step into first sub node by default on last step
   }
  $p
 }

sub c($$)                                                                       # Return an array of all the nodes with the specified tag below the specified node
 {my ($node, $tag) = @_;                                                        # Node, tag
  my $c = $node->indexes->{$tag};                                               # Index for specified tags
  $c ? @$c : ()                                                                 # Contents as an array
 }

sub first($)                                                                    # Return the first node below this node
 {my ($node) = @_;                                                              # Node
  $node->content->[0]
 }

sub firstChild($@)                                                              # Return the first instance of each of the specified tags under the specified node
 {my ($node, @tags) = @_;                                                       # Node, tags to find the first instance of
  map {$node->indexes->{$_}->[0]} @tags;                                        # Find first tag with the specified name under the specified node or undef if no such
 }

sub firstContextOf($@)                                                          # Return the first node encountered in the specified context in a depth first post-order traversal of the parse tree
 {my ($node, @context) = @_;                                                    # Node, array of tags specifying context
  my $x;                                                                        # Found node if found
  eval                                                                          # Trap the die which signals success
   {$node->by(sub                                                               # Traverse  parse tree in depth first order
     {my ($o) = @_;
      if ($o->at(@context))                                                     # Does this node match the supplied context?
       {$x = $o;                                                                # Success
        die "success!";                                                         # Halt the search
       }
     });
   };
  confess $@ if $@ and  $@ !~ /success!/;                                       # Report any suppressed error messages at this point
  $x                                                                            # Return node found if we are still alive
 }

sub last($)                                                                     # Return the last node below this node
 {my ($node) = @_;                                                              # Node
  $node->content->[-1]
 }

sub lastContextOf($@)                                                           # Return the last node encountered in the specified context in a depth first reverse pre-order traversal of the parse tree
 {my ($node, @context) = @_;                                                    # Node, array of tags specifying context
  my $x;                                                                        # Found node if found
  eval                                                                          # Trap the die which signals success
   {$node->downReverse(sub                                                      # Traverse  parse tree in depth first order
     {my ($o) = @_;
      if ($o->at(@context))                                                     # Does this node match the supplied context?
       {$x = $o;                                                                # Success
        die "success!";                                                         # Halt the search
       }
     });
   };
  confess $@ if $@ and  $@ !~ /success!/;                                       # Report any suppressed error messages at this point
  $x                                                                            # Return node found if we are still alive
 }

sub next($)                                                                     # Return the node next to the specified node
 {my ($node) = @_;                                                              # Node
  return undef if $node->isLast;                                                # No node follows the last node at a level or the top most node
  my @c = $node->parent->contents;                                              # Content array of parent
  while(@c)                                                                     # Test until no more nodes left to test
   {my $c = shift @c;                                                           # Each node
    return shift @c if $c == $node                                              # Next node if this is the specified node
   }
  confess "Node not found in parent";                                           # Something wrong with parent/child relationship
 }

sub prev($)                                                                     # Return the node previous to the specified node
 {my ($node) = @_;                                                              # Node
  return undef if $node->isFirst;                                               # No node precedes the first node at a level or the top most node
  my @c = $node->parent->contents;                                              # Content array of parent
  while(@c)                                                                     # Test until no more nodes left to test
   {my $c = pop @c;                                                             # Each node
    return pop @c if $c == $node                                                # Previous node if this is the specified node
   }
  confess "Node not found in parent";                                           # Something wrong with parent/child relationship
 }

sub upto($@)                                                                    # Return the first ancestral node that matches the specified context
 {my ($node, @tags) = @_;                                                       # Start node, tags identifying context
  for(my $p = $node; $p; $p = $p->parent)                                       # Go up
   {return $p if $p->at(@tags);                                                 # Return node which satisfies the condition
   }
  undef                                                                         # Not found
 }

#1 Position

sub at($@)                                                                      # Confirm that the node has the specified ancestry
 {my ($node, @context) = @_;                                                    # Starting node, ancestry
  for(my $x = shift @_; $x; $x = $x->parent)                                    # Up through parents
   {return 1 unless @_;                                                         # OK if no more required context
    next if shift @_ eq $x->tag;                                                # Carry on if contexts match
    return 0                                                                    # Error if required does not match actual
   }
  !@_                                                                           # Top of the tree is OK as long as there is no more required context
 }

sub context($)                                                                  # Return a string containing the tag of this node and its ancestors separated by single spaces
 {my ($node) = @_;                                                              # Node
  my @a;                                                                        # Ancestors
  for(my $p = $node; $p; $p = $p->parent)
   {push @a, $p->tag;
    @a < 100 or confess "Overly deep tree!";
   }
  join ' ', @a
 }

sub isFirst($)                                                                  # Confirm that this node is the first node under its parent
 {my ($node) = @_;                                                              # Node
  my $parent = $node->parent;                                                   # Parent
  return 1 unless $parent;                                                      # The top most node is always first
  $node == $parent->first                                                       # First under parent
 }

sub isLast($)                                                                   # Confirm that this node is the last node under its parent
 {my ($node) = @_;                                                              # Node
  my $parent = $node->parent;                                                   # Parent
  return 1 unless $parent;                                                      # The top most node is always last
  $node == $parent->last                                                        # Last under parent
 }

sub isOnlyChild($)                                                              # Confirm that this node is the only node under its parent
 {my ($node) = @_;                                                              # Node
  $node->isFirst and $node->isLast
 }

sub isEmpty($)                                                                  # Confirm that this node is empty, that is: this node has no content, not even a blank string of text
 {my ($node) = @_;                                                              # Node
  !$node->first;                                                                # If it has no first descendant it must be empty
 }

sub over($$)                                                                    # Confirm that the string representing the tags at the level below this node match a regular expression
 {my ($node, $re) = @_;                                                         # Node, regular expression
  $node->contentAsTags =~ m/$re/
 }

sub after($$)                                                                   # Confirm that the string representing the tags following this node match a regular expression
 {my ($node, $re) = @_;                                                         # Node, regular expression
  $node->contentBeyondAsTags =~ m/$re/
 }

sub before($$)                                                                  # Confirm that the string representing the tags preceding this node match a regular expression
 {my ($node, $re) = @_;                                                         # Node, regular expression
  $node->contentBeforeAsTags =~ m/$re/
 }

#1 Editing                                                                      # Edit the data in the parse tree

sub change($$@)                                                                 # Change the name of a node in an optional tag context and return the node
 {my ($node, $name, @tags) = @_;                                                # Node, new name, tags defining the context
  return undef if @tags and !$node->at(@tags);
  $node->tag = $name;                                                           # Change name
  if (my $parent = $node->parent) {$parent->indexNode}                          # Reindex parent
  $node
 }

#2 Structure                                                                    # Change the structure of the parse tree

sub wrapWith($$)                                                                # Wrap the original node in a new node forcing the original node down deepening the parse tree; return the new wrapping node
 {my ($old, $tag) = @_;                                                         # Node, tag for new node
  my $new = newTag(undef, $tag);                                                # Create wrapping node
  $new->parser = $old->parser;                                                  # Assign the new node to the old parser
  if (my $par  = $old->parent)                                                  # Parent node exists
   {my $c = $par->content;                                                      # Content array of parent
    my $i = $old->position;                                                     # Position in content array
    splice(@$c, $i, 1, $new);                                                   # Replace node
    $old->parent  =  $new;                                                      # Set parent of original node as wrapping node
    $new->parent  =  $par;                                                      # Set parent of wrapping node
    $new->content = [$old];                                                     # Create content for wrapping node
    $par->indexNode;                                                            # Rebuild indices for parent
   }
  else                                                                          # At  the top - no parent
   {$new->content = [$old];                                                     # Create content for wrapping node
    $old->parent  =  $new;                                                      # Set parent of original node as wrapping node
    $new->parent  = undef;                                                      # Set parent of wrapping node - there is none
   }
  $new->indexNode;                                                              # Create index for wrapping node
  $new                                                                          # Return wrapping node
 }

sub wrapUp($@)                                                                  # Wrap the original node in a sequence of new nodes forcing the original node down deepening the parse tree; return the array of wrapping nodes
 {my ($node, @tags) = @_;                                                       # Node to wrap, tags to wrap the node with - with the uppermost tag rightmost
  map {$node = $node->wrapWith($_)} @tags;                                      # Wrap up
 }

sub wrapDown($@)                                                                # Wrap the content of the original node in a sequence of new nodes forcing the original node up deepening the parse tree; return the array of wrapping nodes
 {my ($node, @tags) = @_;                                                       # Node to wrap, tags to wrap the node with - with the uppermost tag rightmost
  map {$node = $node->wrapContentWith($_)} @tags;                               # Wrap up
 }

sub wrapContentWith($$)                                                         # Wrap the content of a node in a new node, the original content then contains the new node which contains the original node's content; returns the new wrapped node
 {my ($old, $tag) = @_;                                                         # Node, tag for new node
  my $new = newTag(undef, $tag);                                                # Create wrapping node
  $new->parser  = $old->parser;                                                 # Assign the new node to the old parser
  $new->content = $old->content;                                                # Transfer content
  $old->content = [$new];                                                       # Insert new node
  $new->indexNode;                                                              # Create indices for new node
  $old->indexNode;                                                              # Rebuild indices for old mode
  $new                                                                          # Return new node
 }

sub unwrap($)                                                                   # Unwrap a node by inserting its content into its parent at the point containing the node; returns the parent node
 {my ($node) = @_;                                                              # Node to unwrap
  my $parent = $node->parent;                                                   # Parent node
  $parent or confess "Cannot unwrap the outer most node";
  if ($node->isEmpty)                                                           # Empty nodes can just be cut out
   {$node->cut;
   }
  else
   {my $p = $parent->content;                                                   # Content array of parent
    my $n = $node->content;                                                     # Content array of node
    my $i = $node->position;                                                    # Position of node in parent
    splice(@$p, $i, 1, @$n);                                                    # Replace node with its content
    $parent->indexNode;                                                         # Rebuild indices for parent
    $node->parent = undef;                                                      # Remove node from parse tree
   }
  $parent                                                                       # Return the parent node
 }

sub replaceWith($$)                                                             # Replace a node (and all its content) with a new node (and all its content) and return the new node
 {my ($old, $new) = @_;                                                         # Old node, new node
  $new->parent and confess "Please cut out the node before moving it";          # The node must have be cut out first
  $new->parser == $new and $old->parser == $new and                             # Prevent a root node from being inserted into a sub tree
    confess "Recursive replacement attempted";
  if (my $parent = $old->parent)                                                # Parent node of old node
   {my $c = $parent->content;                                                   # Content array of parent
    if (defined(my $i = $old->position))                                        # Position of old node in content array of parent
     {splice(@$c, $i, 1, $new);                                                 # Replace old node with new node
      $old->parent = undef;                                                     # Cut out node
      $parent->indexNode;                                                       # Rebuild indices for parent
     }
   }
  $new                                                                          # Return new node
 }

sub replaceWithText($$)                                                         # Replace a node (and all its content) with a new text node and return the new node
 {my ($old, $text) = @_;                                                        # Old node, text of new node
  my $n = $old->replaceWith($old->newText($text));                                       # Create a new text node, replace the old node and return the result
  $n
 }

sub replaceWithBlank($)                                                         # Replace a node (and all its content) with a new blank text node and return the new node
 {my ($old) = @_;                                                               # Old node, text of new node
  my $n = $old->replaceWithText(' ');                                                   # Create a new text node, replace the old node with a new blank text node and return the result
  $n
 }

#2 Cut and Put                                                                  # Move nodes around in the parse tree

sub cut($)                                                                      # Cut out a node - remove the node from the parse tree and return the node so that it can be put else where
 {my ($node) = @_;                                                              # Node to  cut out
  my $parent = $node->parent;                                                   # Parent node
# confess "Already cut out" unless $parent;                                     # We have to let thing be cut out more than once or supply an isCutOut() method
  return $node unless $parent;                                                  # Uppermost node is already cut out
  my $c = $parent->content;                                                     # Content array of parent
  my $i = $node->position;                                                      # Position in content array
  splice(@$c, $i, 1);                                                           # Remove node
  $parent->indexNode;                                                           # Rebuild indices
  $node->parent = undef;                                                        # No parent after being cut out
  $node                                                                         # Return node
 }

sub putNext($$)                                                                 # Place the new node just after the original node in the content of the parent and return the new node
 {my ($old, $new) = @_;                                                         # Original node, new node
  my $parent = $old->parent;                                                    # Parent node
  $parent or confess "Cannot place a node after the outermost node";            # The originating node must have a parent
  $new->parent and confess "Please cut out the node before moving it";          # The node must have be cut out first
  $new->parser == $new and $old->parser == $new and                             # Prevent a root node from being inserted into a sub tree
    confess "Recursive insertion attempted";
  $new->parser = $old->parser;                                                  # Assign the new node to the old parser
  my $c = $parent->content;                                                     # Content array of parent
  my $i = $old->position;                                                       # Position in content array
  splice(@$c, $i+1, 0, $new);                                                   # Insert new node after original node
  $new->parent = $parent;                                                       # Return node
  $parent->indexNode;                                                           # Rebuild indices for parent
  $new                                                                          # Return the new node
 }

sub putPrev($$)                                                                 # Place the new node just before the original node in the content of the parent and return the new node
 {my ($old, $new) = @_;                                                         # Original node, new node
  my $parent = $old->parent;                                                    # Parent node
  $parent or confess "Cannot place a node after the outermost node";            # The originating node must have a parent
  $new->parent and confess "Please cut out the node before moving it";          # The node must have be cut out first
  $new->parser == $new and $old->parser == $new and                             # Prevent a root node from being inserted into a sub tree
    confess "Recursive insertion attempted";
  $new->parser = $old->parser;                                                  # Assign the new node to the old parser
  my $c = $parent->content;                                                     # Content array of parent
  my $i = $old->position;                                                       # Position in content array
  splice(@$c, $i, 0, $new);                                                     # Insert new node before original node
  $new->parent = $parent;                                                       # Return node
  $parent->indexNode;                                                           # Rebuild indices for parent
  $new                                                                          # Return the new node
 }

sub putFirst($$)                                                                # Place the new node at the front of the content of the original node and return the new node
 {my ($old, $new) = @_;                                                         # Original node, new node
  $new->parent and confess "Please cut out the node before moving it";          # The node must have be cut out first
  $new->parser == $new and $old->parser == $new and                             # Prevent a root node from being inserted into a sub tree
    confess "Recursive insertion attempted";
  $new->parser = $old->parser;                                                  # Assign the new node to the old parser
  unshift @{$old->content}, $new;                                               # Content array of original node
  $old->indexNode;                                                              # Rebuild indices for node
  $new                                                                          # Return the new node
 }

sub putLast($$)                                                                 # Place the new node at the end of the content of the original node and return the new node
 {my ($old, $new) = @_;                                                         # Original node, new node
  $new->parent and confess "Please cut out the node before moving it";          # The node must have be cut out first
  $new->parser == $new and $old->parser == $new and                             # Prevent a root node from being inserted into a sub tree
    confess "Recursive insertion attempted";
  $new->parser = $old->parser;                                                  # Assign the new node to the old parser
  push @{$old->content}, $new;                                                  # Content array of original node
  $old->indexNode;                                                              # Rebuild indices for node
  $new                                                                          # Return the new node
 }

sub putFirstAsText($$)                                                          # Add a new text node first under a parent and return the new text node
 {my ($node, $text) = @_;                                                       # The parent node, the string to be added which might contain unparsed xml as well as text
  $node->putFirst($node->newText($text));                                       # Add new text node
  $node                                                                         # Return parent node
 }

sub putLastAsText($$)                                                           # Add a new text node last under a parent and return the new text node
 {my ($node, $text) = @_;                                                       # The parent node, the string to be added which might contain unparsed xml as well as text
  $node->putLast($node->newText($text));                                        # Add new text node
  $node                                                                         # Return parent node
 }

sub putNextAsText($$)                                                           # Add a new text node following this node and return the new text node
 {my ($node, $text) = @_;                                                       # The parent node, the string to be added which might contain unparsed xml as well as text
  $node->putNext($node->newText($text));                                        # Add new text node
  $node                                                                         # Return parent node
 }

sub putPrevAsText($$)                                                           # Add a new text node following this node and return the new text node
 {my ($node, $text) = @_;                                                       # The parent node, the string to be added which might contain unparsed xml as well as text
  $node->putPrev($node->newText($text));                                        # Add new text node
  $node                                                                         # Return parent node
 }

sub checkParentage($)                                                           ## Check the parent pointers are correct in a parse tree
 {my ($x) = @_;
  $x->by(sub
   {my ($o) = @_;
   for($o->contents)
     {my $p = $_->parent;
      $p == $o or confess "No parent: ". $_->tag;
      $p and $p == $o or confess "Wrong parent: ".$o->tag. ", ". $_->tag;
     }
   });
 }

sub checkParser($)                                                              ## Check that every node has a parser
 {my ($x) = @_;
  $x->by(sub
   {$_->parser or confess "No parser for ". $_->tag;
    $_->parser == $x or confess "Wrong parser for ". $_->tag;
   })
 }

# Tests and documentation

sub test{eval join('', <Data::Edit::Xml::DATA>) or die $@} test unless caller;  ## Test

#extractDocumentation() unless caller();                                        ## podDocumentation

1;

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Data::Edit::Xml - Edit data held in xml format

=head1 Synopsis

Transform some DocBook xml into Dita:

 use Data::Edit::Xml;

 # Docbook

 say STDERR Data::Edit::Xml::new(<<END)
<sli>
  <li>
    <p>Diagnose the problem</p>
    <p>This can be quite difficult</p>
    <p>Sometimes impossible</p>
  </li>
  <li>
  <p><pre>ls -la</pre></p>
  <p><pre>
drwxr-xr-x  2 phil phil   4096 Jun 15  2016 Desktop
drwxr-xr-x  2 phil phil   4096 Nov  9 20:26 Downloads
</pre></p>
  </li>
</sli>
END

 # Transform to Dita

 ->by(sub
  {my ($o, $p) = @_;
   if ($o->at(qw(pre p li sli)) and $o->isOnlyChild)
    {$o->change($p->isFirst ? qw(cmd) : qw(stepresult));
     $p->unwrap;
    }
   elsif ($o->at(qw(li sli))    and $o->over(qr(\Ap( p)+\Z)))
    {$_->change($_->isFirst ? qw(cmd) : qw(info)) for $o->contents;
    }
  })

  ->by(sub
  {my ($o) = @_;
   $o->change(qw(step))          if $o->at(qw(li sli));
   $o->change(qw(steps))         if $o->at(qw(sli));
   $o->id = 's'.($o->position+1) if $o->at(qw(step));
   $o->id = 'i'.($o->index+1)    if $o->at(qw(info));
   $o->wrapWith(qw(screen))      if $o->at(qw(CDATA stepresult));
  })

  # Print
  ->prettyString;

Produces:

 <steps>
   <step id="s1">
     <cmd>Diagnose the problem</cmd>
     <info id="i1">This can be quite difficult</info>
     <info id="i2">Sometimes impossible</info>
     </step>
   <step id="s2">
     <cmd>ls -la</cmd>
     <stepresult>
       <screen>
 drwxr-xr-x  2 phil phil   4096 Jun 15  2016 Desktop
 drwxr-xr-x  2 phil phil   4096 Nov  9 20:26 Downloads
       </screen>
     </stepresult>
   </step>
 </steps>

=head1 Description

=head2 Constructor

=head3 new

New parse - call this method statically as in Data::Edit::Xml::new(file or string) B<or> with no parameters and then use L</input>, L</inputFile>, L</inputString>, L</errorFile>  to provide specific parameters for the parse, then call L</parse> to perform the parse and return the parse tree

     Parameter          Description
  1  $fileNameOrString  File name or string

=head3 parent :lvalue

Parent node of this node or undef if root node, see also L</Traversal> and L</Navigation>. Consider as read only.


=head3 parser :lvalue

Parser details: the root node of a tree is the parse node for that tree. Consider as read only.


=head3 tag :lvalue

Tag name for this node, see also L</Traversal> and L</Navigation>. Consider as read only.


=head3 input :lvalue

Source of the parse if this is the parser node. Use this parameter to specify some input either as a string or as a file name for the parser to convert into a parse tree


=head3 inputFile :lvalue

Source file of the parse if this is the parser node. Use this parameter to explicitly set the file to be parsed.


=head3 inputString :lvalue

Source string of the parse if this is the parser node. Use this parameter to explicitly set the string to be parsed.


=head3 errorsFile :lvalue

Error listing file. Use this parameter to explicitly set the name of the filw that will be used to write an parse errors to, by default this file is named: B<zzzParseErrors/out.data>


=head3 text :lvalue

Text of this node but only if it is a text node, i.e. the tag is cdata() <=> L</isText> is true


=head3 content :lvalue

Content of command: the nodes immediately below this node in the order in which they appeared in the source text, see also L</Contents>


=head3 attributes :lvalue

The attributes of this node, see also: L</Attributes>,  The frequently used attributes: class, id, href, outputclass can be accessed by an lvalue method as in: $node->id = 'c1'


=head3 conditions :lvalue

Conditional strings attached to a node, see L</Conditions>


=head3 indexes :lvalue

Indexes to sub commands by tag in the order in which they appeared in the source text


=head3 cdata

The name of the tag to be used to represent text - this tag must not also be used as a command tag otherwise chaos will occur


=head3 parse

Parse input xml

     Parameter  Description
  1  $p         Parser created by L</new>

=head3 newText

Create a new text node

     Parameter  Description
  1  undef      Any reference to this package
  2  $text      Content of new text node

=head3 newTag

Create a new non text node

     Parameter    Description
  1  undef        Any reference to this package
  2  $command     The tag for the node
  3  %attributes  Attributes as a hash

=head3 newTree

Create a new tree - this is a static method

     Parameter    Description
  1  $command     The name of the root node in the tree
  2  %attributes  Attributes of the root node in the tree as a hash

=head3 tags

Count the number of tags in a parse tree

     Parameter  Description
  1  $node      Parse tree

=head2 Stringification

Print the parse tree

=head3 string

Return a string representing a node of a parse tree and all the nodes below it

     Parameter  Description
  1  $node      Start node

=head3 contentString

Return a string representing all the nodes below a node of a parse tree

     Parameter  Description
  1  $node      Start node

=head3 prettyString

Return a readable string representing a node of a parse tree and all the nodes below it

     Parameter  Description
  1  $node      Start node
  2  $depth     Depth

=head3 PrettyContentString

Return a readable string representing all the nodes below a node of a parse tree - infrequent use and so capitialised to avoid being presented as an option by Geany

     Parameter  Description
  1  $node      Start node

=head3 Conditions

Print a subset of the the parse tree determined by the conditions attached to it

=head4 stringWithConditions

Return a string representing a node of a parse tree and all the nodes below it subject to conditions to select or reject some nodes

     Parameter    Description
  1  $node        Start node
  2  @conditions  Conditions to be regarded as in effect

=head4 addConditions

Add conditions to a node and return the node

     Parameter    Description
  1  $node        Node
  2  @conditions  Conditions to add

=head4 deleteConditions

Delete conditions applied to a node and return the node

     Parameter    Description
  1  $node        Node
  2  @conditions  Conditions to add

=head4 listConditions

Return a list of conditions applied to a node

     Parameter  Description
  1  $node      Node

=head2 Attributes

Get or set attributes

=head3 attr :lvalue

Return the value of an attribute of the current node as an assignable value

     Parameter   Description
  1  $node       Node in parse tree
  2  $attribute  Attribute name

=head3 attrs

Return the values of the specified attributes of the current node

     Parameter    Description
  1  $node        Node in parse tree
  2  @attributes  Attribute names

=head3 attrCount

Return the number of attributes in the specified node

     Parameter  Description
  1  $node      Node in parse tree

=head3 setAttr

Set the value of an attribute in a node and return the node

     Parameter  Description
  1  $node      Node in parse tree
  2  %values    (attribute name=>new value)*

=head3 deleteAttr

Delete the attribute, optionally checking its value first and return the node

     Parameter  Description
  1  $node      Node
  2  $attr      Attribute name
  3  $value     Optional attribute value to check first

=head3 deleteAttrs

Delete any attributes mentioned in a list without checking their values and return the node

     Parameter  Description
  1  $node      Node
  2  @attrs     Attribute name

=head3 renameAttr

Change the name of an attribute regardless of whether the new attribute already exists and return the node

     Parameter  Description
  1  $node      Node
  2  $old       Existing attribute name
  3  $new       New attribute name

=head3 changeAttr

Change the name of an attribute unless it has already been set and return the node

     Parameter  Description
  1  $node      Node
  2  $old       Existing attribute name
  3  $new       New attribute name

=head3 renameAttrValue

Change the name and value of an attribute regardless of whether the new attribute already exists and return the node

     Parameter  Description
  1  $node      Node
  2  $old       Existing attribute name and value
  3  $oldValue  New attribute name and value
  4  $new
  5  $newValue

=head3 changeAttrValue

Change the name and value of an attribute unless it has already been set and return the node

     Parameter  Description
  1  $node      Node
  2  $old       Existing attribute name and value
  3  $oldValue  New attribute name and value
  4  $new
  5  $newValue

=head2 Traversal

Traverse the parse tree

=head3 by

Post-order traversal of a parse tree or sub tree and return the specified starting node

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context

=head3 byReverse

Reverse post-order traversal of a parse tree or sub tree and return the specified starting node

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context

=head3 down

Pre-order traversal down through a parse tree or sub tree and return the specified starting node

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context

=head3 downReverse

Reverse pre-order traversal down through a parse tree or sub tree and return the specified starting node

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context

=head3 through

Traverse parse tree visiting each node twice and return the specified starting node

     Parameter  Description
  1  $node      Starting node
  2  $before    Sub to call when we meet a node
  3  $after     Sub to call we leave a node
  4  @context   Accumulated context

=head2 Contents

Contents of the specified node

=head3 contents

Return all the nodes contained by this node either as an array or as a reference to such an array

     Parameter  Description
  1  $node      Node

=head3 contentBeyond

Return all the nodes following this node at the level of this node

     Parameter  Description
  1  $node      Node

=head3 contentBefore

Return all the nodes preceding this node at the level of this node

     Parameter  Description
  1  $node      Node

=head3 contentAsTags

Return a string containing the tags of all the nodes contained by this node separated by single spaces

     Parameter  Description
  1  $node      Node

=head3 contentBeyondAsTags

Return a string containing the tags of all the nodes following this node separated by single spaces

     Parameter  Description
  1  $node      Node

=head3 position

Return the index of a node in its parent's content

     Parameter  Description
  1  $node      Node

=head3 index

Return the index of a node in its parent index

     Parameter  Description
  1  $node      Node

=head3 present

Return the count of the number of the specified tag types present immediately under a node

     Parameter  Description
  1  $node      Node
  2  @names     Possible tags immediately under the node

=head3 count

Return the count the number of instances of the specified tags under the specified node, either by tag in array context or in total in scalar context

     Parameter  Description
  1  $node      Node
  2  @names     Possible tags immediately under the node

=head3 isText

Confirm that this is a text node

     Parameter  Description
  1  $node      Node to test

=head2 Navigation

Move around in the parse tree

=head3 get

Return a sub node under the specified node by its position in each index with position zero assumed if no position is supplied

     Parameter  Description
  1  $node      Node
  2  @position  Position specification: (index position?)* where position defaults to zero if not specified

=head3 c

Return an array of all the nodes with the specified tag below the specified node

     Parameter  Description
  1  $node      Node
  2  $tag       Tag

=head3 first

Return the first node below this node

     Parameter  Description
  1  $node      Node

=head3 firstChild

Return the first instance of each of the specified tags under the specified node

     Parameter  Description
  1  $node      Node
  2  @tags      Tags to find the first instance of

=head3 firstContextOf

Return the first node encountered in the specified context in a depth first post-order traversal of the parse tree

     Parameter  Description
  1  $node      Node
  2  @context   Array of tags specifying context

=head3 last

Return the last node below this node

     Parameter  Description
  1  $node      Node

=head3 lastContextOf

Return the last node encountered in the specified context in a depth first reverse pre-order traversal of the parse tree

     Parameter  Description
  1  $node      Node
  2  @context   Array of tags specifying context

=head3 next

Return the node next to the specified node

     Parameter  Description
  1  $node      Node

=head3 prev

Return the node previous to the specified node

     Parameter  Description
  1  $node      Node

=head3 upto

Return the first ancestral node that matches the specified context

     Parameter  Description
  1  $node      Start node
  2  @tags      Tags identifying context

=head2 Position

=head3 at

Confirm that the node has the specified ancestry

     Parameter  Description
  1  $node      Starting node
  2  @context   Ancestry

=head3 context

Return a string containing the tag of this node and its ancestors separated by single spaces

     Parameter  Description
  1  $node      Node

=head3 isFirst

Confirm that this node is the first node under its parent

     Parameter  Description
  1  $node      Node

=head3 isLast

Confirm that this node is the last node under its parent

     Parameter  Description
  1  $node      Node

=head3 isOnlyChild

Confirm that this node is the only node under its parent

     Parameter  Description
  1  $node      Node

=head3 isEmpty

Confirm that this node is empty, that is: this node has no content, not even a blank string of text

     Parameter  Description
  1  $node      Node

=head3 over

Confirm that the string representing the tags at the level below this node match a regular expression

     Parameter  Description
  1  $node      Node
  2  $re        Regular expression

=head3 after

Confirm that the string representing the tags following this node match a regular expression

     Parameter  Description
  1  $node      Node
  2  $re        Regular expression

=head3 before

Confirm that the string representing the tags preceding this node match a regular expression

     Parameter  Description
  1  $node      Node
  2  $re        Regular expression

=head2 Editing

Edit the data in the parse tree

=head3 change

Change the name of a node in an optional tag context and return the node

     Parameter  Description
  1  $node      Node
  2  $name      New name
  3  @tags      Tags defining the context

=head3 Structure

Change the structure of the parse tree

=head4 wrapWith

Wrap the original node in a new node forcing the original node down deepening the parse tree; return the new wrapping node

     Parameter  Description
  1  $old       Node
  2  $tag       Tag for new node

=head4 wrapUp

Wrap the original node in a sequence of new nodes forcing the original node down deepening the parse tree; return the array of wrapping nodes

     Parameter  Description
  1  $node      Node to wrap
  2  @tags      Tags to wrap the node with - with the uppermost tag rightmost

=head4 wrapDown

Wrap the content of the original node in a sequence of new nodes forcing the original node up deepening the parse tree; return the array of wrapping nodes

     Parameter  Description
  1  $node      Node to wrap
  2  @tags      Tags to wrap the node with - with the uppermost tag rightmost

=head4 wrapContentWith

Wrap the content of a node in a new node, the original content then contains the new node which contains the original node's content; returns the new wrapped node

     Parameter  Description
  1  $old       Node
  2  $tag       Tag for new node

=head4 unwrap

Unwrap a node by inserting its content into its parent at the point containing the node; returns the parent node

     Parameter  Description
  1  $node      Node to unwrap

=head4 replaceWith

Replace a node (and all its content) with a new node (and all its content) and return the new node

     Parameter  Description
  1  $old       Old node
  2  $new       New node

=head4 replaceWithText

Replace a node (and all its content) with a new text node and return the new node

     Parameter  Description
  1  $old       Old node
  2  $text      Text of new node

=head4 replaceWithBlank

Replace a node (and all its content) with a new blank text node and return the new node

     Parameter  Description
  1  $old       Old node

=head3 Cut and Put

Move nodes around in the parse tree

=head4 cut

Cut out a node - remove the node from the parse tree and return the node so that it can be put else where

     Parameter  Description
  1  $node      Node to  cut out


=head1 Index


L<addConditions|/addConditions>

L<after|/after>

L<at|/at>

L<attr :lvalue|/attr :lvalue>

L<attrCount|/attrCount>

L<attributes|/attributes>

L<attrs|/attrs>

L<before|/before>

L<by|/by>

L<byReverse|/byReverse>

L<c|/c>

L<cdata|/cdata>

L<change|/change>

L<changeAttr|/changeAttr>

L<changeAttrValue|/changeAttrValue>

L<conditions|/conditions>

L<content|/content>

L<contentAsTags|/contentAsTags>

L<contentBefore|/contentBefore>

L<contentBeyond|/contentBeyond>

L<contentBeyondAsTags|/contentBeyondAsTags>

L<contents|/contents>

L<contentString|/contentString>

L<context|/context>

L<count|/count>

L<cut|/cut>

L<deleteAttr|/deleteAttr>

L<deleteAttrs|/deleteAttrs>

L<deleteConditions|/deleteConditions>

L<down|/down>

L<downReverse|/downReverse>

L<errorsFile|/errorsFile>

L<first|/first>

L<firstChild|/firstChild>

L<firstContextOf|/firstContextOf>

L<get|/get>

L<index|/index>

L<indexes|/indexes>

L<input|/input>

L<inputFile|/inputFile>

L<inputString|/inputString>

L<isEmpty|/isEmpty>

L<isFirst|/isFirst>

L<isLast|/isLast>

L<isOnlyChild|/isOnlyChild>

L<isText|/isText>

L<last|/last>

L<lastContextOf|/lastContextOf>

L<listConditions|/listConditions>

L<new|/new>

L<newTag|/newTag>

L<newText|/newText>

L<newTree|/newTree>

L<next|/next>

L<over|/over>

L<parent|/parent>

L<parse|/parse>

L<parser|/parser>

L<position|/position>

L<present|/present>

L<PrettyContentString|/PrettyContentString>

L<prettyString|/prettyString>

L<prev|/prev>

L<renameAttr|/renameAttr>

L<renameAttrValue|/renameAttrValue>

L<replaceWith|/replaceWith>

L<replaceWithBlank|/replaceWithBlank>

L<replaceWithText|/replaceWithText>

L<setAttr|/setAttr>

L<string|/string>

L<stringWithConditions|/stringWithConditions>

L<tag|/tag>

L<tags|/tags>

L<text|/text>

L<through|/through>

L<unwrap|/unwrap>

L<upto|/upto>

L<wrapContentWith|/wrapContentWith>

L<wrapDown|/wrapDown>

L<wrapUp|/wrapUp>

L<wrapWith|/wrapWith>

=head1 Installation

This module is written in 100% Pure Perl and is thus easy to read, use, modify
and install.

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

philiprbrenan@gmail.com

http://www.appaapps.com

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut
# podDocumentation
# pod2html --infile=lib/Data/Edit/Xml.pm --outfile=zzz.html

__DATA__
use warnings FATAL=>qw(all);
use strict;
use Test::More tests=>160;
use Data::Table::Text qw(:all);

#Test::More->builder->output("/dev/null");                                       # Show only errors during testing - but this must be commented out for production

sub sample1{my $x = Data::Edit::Xml::new(); $x->input = <<END; $x->parse}       # Sample test xml
<foo start="yes">
  <head id="a" key="aaa bbb" start="123">Hello
    <em>there</em>
  </head>
  <bar>Howdy
    <ref/>
  </bar>do
doo
  <head id="A" key="AAAA BBBB" start="123">HHHHello
    <b>to you</b>
  </head>
  <tail>
    <foot id="11"/>
    <middle id="mm"/>
    <foot id="22"/>
  </tail>
</foo>
END

sub sample2{my $x = Data::Edit::Xml::new(); $x->inputString = <<END; $x->parse}
<a id="aa"><b id="bb"><c id="cc"/></b></a>
END

if (1)                                                                          # Parse and string
 {my $x = sample1;
  if (my $s = $x->string)
   {ok $s eq trim(<<END);
<foo start="yes"><head id="a" key="aaa bbb" start="123">Hello
    <em>there</em></head><bar>Howdy
    <ref/></bar>do
doo
  <head id="A" key="AAAA BBBB" start="123">HHHHello
    <b>to you</b></head><tail><foot id="11"/><middle id="mm"/><foot id="22"/></tail></foo>
END
    ok $x->prettyString  =~ s/\n/N/gsr =~ s/\t/T/gsr eq '<foo start="yes">NTT<head id="a" key="aaa bbb" start="123">HelloN    NTTTT<em>thereNTTTT</em>NTT</head>NTT<bar>HowdyN    NTTTT<ref/>NTT</bar>NdoNdooN  NTT<head id="A" key="AAAA BBBB" start="123">HHHHelloN    NTTTT<b>to youNTTTT</b>NTT</head>NTT<tail>NTTTT<foot id="11"/>NTTTT<middle id="mm"/>NTTTT<foot id="22"/>NTT</tail>N</foo>N';
    ok $x->contentString =~ s/\n/N/gsr =~ s/\t/T/gsr eq '<head id="a" key="aaa bbb" start="123">HelloN    <em>there</em></head><bar>HowdyN    <ref/></bar>doNdooN  <head id="A" key="AAAA BBBB" start="123">HHHHelloN    <b>to you</b></head><tail><foot id="11"/><middle id="mm"/><foot id="22"/></tail>';
    ok $x->attr(qq(start)) eq "yes";
       $x->id  = 11;
    ok $x->id == 11;
       $x->deleteAttr(qq(id));
    ok !$x->id;
    ok join(' ', $x->get(qw(head))->attrs(qw(id start))) eq "a 123";
    ok $x->PrettyContentString  =~ s/\n/N/gsr =~ s/\t/T/gsr eq '<head id="a" key="aaa bbb" start="123">HelloN    NTT<em>thereNTT</em>N</head>N<bar>HowdyN    NTT<ref/>N</bar>NdoNdooN  N<head id="A" key="AAAA BBBB" start="123">HHHHelloN    NTT<b>to youNTT</b>N</head>N<tail>NTT<foot id="11"/>NTT<middle id="mm"/>NTT<foot id="22"/>N</tail>N';
    ok $x->tags == 17;
    ok $x->get(qw(head 1))->tags == 4;
   }
  if (1)                                                                        # Conditions
   {my $m = $x->get(qw(tail middle));
    $m->addConditions(qw(middle MIDDLE));                                       # Add
    ok join(' ', $m->listConditions) eq 'MIDDLE middle';                        # List
    $m->deleteConditions(qw(MIDDLE));                                           # Remove
    ok join('', $m->listConditions) eq 'middle';
    $_->addConditions(qw(foot)) for $x->get(qw(tail foot *));

    ok $x->stringWithConditions(qw(middle)) eq trim(<<END);
<foo start="yes"><head id="a" key="aaa bbb" start="123">Hello
    <em>there</em></head><bar>Howdy
    <ref/></bar>do
doo
  <head id="A" key="AAAA BBBB" start="123">HHHHello
    <b>to you</b></head><tail><middle id="mm"/></tail></foo>
END

    ok $x->stringWithConditions(qw(foot))  eq trim(<<END);
<foo start="yes"><head id="a" key="aaa bbb" start="123">Hello
    <em>there</em></head><bar>Howdy
    <ref/></bar>do
doo
  <head id="A" key="AAAA BBBB" start="123">HHHHello
    <b>to you</b></head><tail><foot id="11"/><foot id="22"/></tail></foo>
END

    ok $x->stringWithConditions(qw(none)) eq trim(<<END);
<foo start="yes"><head id="a" key="aaa bbb" start="123">Hello
    <em>there</em></head><bar>Howdy
    <ref/></bar>do
doo
  <head id="A" key="AAAA BBBB" start="123">HHHHello
    <b>to you</b></head><tail/></foo>
END

    ok $x->stringWithConditions(qw(foot middle)) eq $x->string;
    ok $x->stringWithConditions eq $x->string;
   }

  if (my $h = $x->get(qw(head))) {ok $h->id eq qw(a)} else {ok 0}               # Attributes and sub nodes

 # Contents
  ok formatTable([map {$_->tag} $x->contents], '')                        eq '0  head   1  bar    2  CDATA  3  head   4  tail   ';
  ok formatTable([map {$_->tag} $x->get(qw(head))   ->contentBeyond], '') eq '0  bar    1  CDATA  2  head   3  tail   ';
  ok formatTable([map {$_->tag} $x->get(qw(head), 1)->contentBefore], '') eq '0  head   1  bar    2  CDATA  ';

  ok $x->contentAsTags  eq join ' ', qw(head bar CDATA head tail);
  ok $x->get(qw(head),0)->contentBeyondAsTags eq join ' ', qw(     bar CDATA head tail);
  ok $x->get(qw(head),1)->contentBeforeAsTags eq join ' ', qw(head bar CDATA);

  ok $x->over(qr(\Ahead bar CDATA head tail\Z));
  ok $x->get(qw(head),0)->after (qr(\Abar CDATA head tail\Z));
  ok $x->get(qw(head),1)->before(qr(\Ahead bar CDATA\Z));

  ok $x->c(qw(head)) == 2;
  ok $x->get(qw(tail))->present(qw(foot middle aaa bbb)) == 2;                  # Presence of the specified tags
  ok $x->get(qw(tail))->present(qw(foot aaa bbb)) == 1;
  ok $x->get(qw(tail))->present(qw(     aaa bbb)) == 0;
  ok $x->get(qw(tail foot))->present(qw(aaa bbb)) == 0;
  if (1)
   {my $c = $x->count(qw(head tail aaa));
    ok $c == 3;
    my @c = $x->count(qw(head tail aaa));
    ok "@c" eq "2 1 0";
    my $t = $x->count(qw(CDATA));
    ok $t == 1;
    my $T = $x->count;
    ok $T == 5;
   }

  if (1)                                                                        # First child
   {my ($foot, $middle) = $x->get(qw(tail))->firstChild(qw(foot middle));
    ok $foot  ->id == 11;
    ok $middle->id eq qq(mm);
   }

  ok $x->get(qw(head *)) == 2;
  ok $x->get(qw(head),1)->position == 3;

  ok $x->get(qw(tail))->first->id == 11;
  ok $x->get(qw(tail))->last ->id == 22;
  ok $x->get(qw(tail))->first->isFirst;
  ok $x->get(qw(tail))->last ->isLast;

  ok sample2->first->isOnlyChild;
  ok sample2->first->first->isOnlyChild;
  ok sample2->first->first->isEmpty;
  ok !$x->get(qw(tail))->last->isOnlyChild;

  ok $x->get(qw(tail))->first->next->id eq 'mm';
  ok $x->get(qw(tail))->last->prev->prev->isFirst;

  ok $x->get(qw(head))->get(qw(em))->first->at(qw(CDATA em head foo));          # At

  if (1)                                                                        # Through
   {my @t;
    $x->first->by(sub {my ($o) = @_; push @t, $o->tag});
    ok formatTable([@t], '') eq '0  CDATA  1  CDATA  2  em     3  head   ';
   }

  if (1)
   {my @t;
    $x->last->by(sub {my ($o) = @_; push @t, $o->tag});
    ok formatTable([@t], '') eq '0  foot    1  middle  2  foot    3  tail    ';
   }

# Editting - outermost - wrapWith

  ok sample1->wrapWith("out")->string eq trim(<<END);
<out><foo start="yes"><head id="a" key="aaa bbb" start="123">Hello
    <em>there</em></head><bar>Howdy
    <ref/></bar>do
doo
  <head id="A" key="AAAA BBBB" start="123">HHHHello
    <b>to you</b></head><tail><foot id="11"/><middle id="mm"/><foot id="22"/></tail></foo></out>
END

  ok sample1->wrapContentWith("out")->parent->string eq trim(<<END);
<foo start="yes"><out><head id="a" key="aaa bbb" start="123">Hello
    <em>there</em></head><bar>Howdy
    <ref/></bar>do
doo
  <head id="A" key="AAAA BBBB" start="123">HHHHello
    <b>to you</b></head><tail><foot id="11"/><middle id="mm"/><foot id="22"/></tail></out></foo>
END

# Editting - inner - wrapWith
  ok sample1->get(qw(tail))->get(qw(middle))->wrapWith("MIDDLE")->parent->parent->string eq trim(<<END);
<foo start="yes"><head id="a" key="aaa bbb" start="123">Hello
    <em>there</em></head><bar>Howdy
    <ref/></bar>do
doo
  <head id="A" key="AAAA BBBB" start="123">HHHHello
    <b>to you</b></head><tail><foot id="11"/><MIDDLE><middle id="mm"/></MIDDLE><foot id="22"/></tail></foo>
END

 ok sample1->get(qw(tail))->get(qw(middle))->wrapContentWith("MIDDLE")->parent->parent->parent->string eq trim(<<END);
<foo start="yes"><head id="a" key="aaa bbb" start="123">Hello
    <em>there</em></head><bar>Howdy
    <ref/></bar>do
doo
  <head id="A" key="AAAA BBBB" start="123">HHHHello
    <b>to you</b></head><tail><foot id="11"/><middle id="mm"><MIDDLE/></middle><foot id="22"/></tail></foo>
END

# Editting - cut/put

  if (1)
   {my $a = sample2;
    ok $a->get(qw(b))->id eq qw(bb);
    ok $a->get(qw(b c))->id  eq qw(cc);
    $a->putFirst($a->get(qw(b c))->cut);                                        # First
    ok $a->string eq '<a id="aa"><c id="cc"/><b id="bb"/></a>';
    $a->putLast($a->get(qw(c))->cut);                                           # Last
    ok $a->string eq '<a id="aa"><b id="bb"/><c id="cc"/></a>';
    $a->get(qw(c))->putNext($a->get(qw(b))->cut);                               # Next
    ok $a->string eq '<a id="aa"><c id="cc"/><b id="bb"/></a>';
    $a->get(qw(c))->putPrev($a->get(qw(b))->cut);                               # Prev
    ok $a->string eq '<a id="aa"><b id="bb"/><c id="cc"/></a>';
   }

# Editting - unwrap

  ok sample2->get(qw(b))->unwrap->string eq '<a id="aa"><c id="cc"/></a>';
  ok sample2->get(qw(b c))->putFirst(sample2)->parent->parent->parent->string eq '<a id="aa"><b id="bb"><c id="cc"><a id="aa"><b id="bb"><c id="cc"/></b></a></c></b></a>';
  ok sample2->get(qw(b c))->replaceWith(sample2)->get(qw(b c))->upto(qw(a b))->string eq '<a id="aa"><b id="bb"><c id="cc"/></b></a>';

  if (1)
   {my $x = sample2;
    $x->get(qw(b c))->unwrap;
    ok $x->string eq '<a id="aa"><b id="bb"/></a>';
    $x->get(qw(b))->unwrap;
    ok $x->string eq '<a id="aa"/>';
    eval {$x->unwrap };
    ok $@ =~ m(\ACannot unwrap the outer most node)s;
   }

  if (1)
   {my $x = sample2;
    $x->get(qw(b c))->replaceWithText(qq(<d id="dd">));
    ok $x->string eq '<a id="aa"><b id="bb"><d id="dd"></b></a>';
   }

  if (1)
   {my $x = sample2;
    $x->get(qw(b c))->replaceWithBlank;
    ok $x->string eq '<a id="aa"><b id="bb"/></a>';
   }

# Editting - tag /attributes

  ok  sample2->get(qw(b))->change(qw(B b a))->parent->string eq '<a id="aa"><B id="bb"><c id="cc"/></B></a>';
  ok !sample2->get(qw(b))->change(qw(B c a));
  ok  sample2->get(qw(b))->setAttr(aa=>11, bb=>22)->parent->string eq '<a id="aa"><b aa="11" bb="22" id="bb"><c id="cc"/></b></a>';
  ok  sample2->get(qw(b c))->setAttr(aa=>11, bb=>22)->parent->parent->string eq '<a id="aa"><b id="bb"><c aa="11" bb="22" id="cc"/></b></a>';
  ok  sample2->deleteAttr(qw(id))->string eq '<a><b id="bb"><c id="cc"/></b></a>';
  ok  sample2->renameAttr(qw(id ID))->string eq '<a ID="aa"><b id="bb"><c id="cc"/></b></a>';
  ok  sample2->changeAttr(qw(ID id))->id eq qq(aa);

  ok  sample2->renameAttrValue(qw(id aa ID AA))->string eq '<a ID="AA"><b id="bb"><c id="cc"/></b></a>';
  ok  sample2->changeAttrValue(qw(ID AA id aa))->id eq qq(aa);
 }

if (1)                                                                          # Blank text
 {my $f = "zzz.xml";
  writeFile($f, "<a> <b/>   <c/> <d/> </a>");
  my $x = Data::Edit::Xml::new($f);
  unlink $f;
  $x->putFirstAsText(' ');
  $x->get(qw(b))->putNextAsText(' ');
  $x->get(qw(d))->putPrevAsText(' ');
  $x->putLastAsText(' ');

  ok $x->count == 3;
  ok $x->contentAsTags eq qq(b c d);
  my $c = $x->get(qw(c));
  $c->replaceWithBlank;
 }

if (1)                                                                          # Blank text
 {my $f = "zzz.xml";
  writeFile($f, "<a>  </a>");
  my $x = Data::Edit::Xml::new();
     $x->inputFile = $f;
     $x->parse;
  unlink $f;
  $x->putFirstAsText(' ') for 1..10;
  $x->putLastAsText(' ')  for 1..10;
  ok $x->count == 0;
  ok $x->string eq "<a/>";
 }

if (1)                                                                          # Text
 {my $x = Data::Edit::Xml::new(<<END);
<a>

</a>
END
  ok $x->count == 0;
  ok $x->isEmpty;
  ok $x->string eq "<a/>";
  $x->putFirstAsText(' ');
  ok $x->count == 0;
  $x->putFirstAsText("\n");
  ok $x->count == 0;
  $x->putFirstAsText('3');
  ok $x->string eq "<a>3</a>";
  ok $x->count == 1;
  ok !$x->isEmpty;
  $x->putFirstAsText(' ');
  ok $x->count == 1;
  $x->putFirstAsText(' ');
  ok $x->count == 1;
  $x->putFirstAsText(' 2 ');
  ok $x->count == 1;
  $x->putFirstAsText("\n");
  ok $x->count == 1;
  $x->putFirstAsText(' ');
  ok $x->count == 1;
  $x->putFirstAsText(' 1 ');
  ok $x->count == 1;
  $x->putFirstAsText(' ');
  ok $x->count == 1;
  $x->putFirstAsText(' ');
  ok $x->first->tag eq qq(CDATA);
  ok $x->first->isText;
  ok $x->count == 1;
  ok $x->string eq "<a> 1  2 3</a>";
 }

if (1)                                                                          # Text and tags
 {my $x = Data::Edit::Xml::new(<<END);
<a>

  <b/>

  <c/>
</a>
END
  $x->by(sub
   {my ($o) = @_;
    $o->putFirstAsText($_) for ('  ', 'F', '', 'F', ' ', '');
    $o->putLastAsText ($_) for ('  ', 'L', '', 'L', '',  ' ');
    unless($o == $x)
     {$o->putNextAsText ($_) for ('  ', ' N ', '', ' N ', ' N ', '');           # N will always be preceded and succeeded by spaces
      $o->putPrevAsText ($_) for (' P', '' ,   '', ' P',  ' ',   ' P')          # P will always be preceded               by spaces
     }
   });
#  say STDERR "AAAA ", $x->string;
  ok $x->string eq "<a>FF P P  P<b>FF  LL </b> N  N  N  P P  P<c>FF  LL </c> N  N  N   LL </a>";
 }

if (1)                                                                          # Create
 {my $x = sample2;
  my $c = $x->get(qw(b c));
  my $d = $c->newTag(qw(d));
  $d->id = qw(dd);
  $c->putFirst($d);
  ok $x->string eq '<a id="aa"><b id="bb"><c id="cc"><d id="dd"/></c></b></a>';
 }

if (1)                                                                          # Under
 {my $x = sample2;
  my $c = $x->get(qw(b c));
  ok $c->id eq qw(cc);

  for([qw(c cc)], [qw(b bb)], [qw(a aa)])
   {my ($tag, $id) = @$_;
    my $p = $c->upto($tag);
    ok $p->id eq $id;
   }

  my $p = $c->upto(qw(d));
  ok !$p;
 }

if (1)                                                                          # Down
 {my $x = sample1;
  my $s;
  $x->down(sub
   {$s .= "(".join(' ', map {$_->tag} @_).")";
   });
  ok $s eq "(foo)(head foo)(CDATA head foo)(em head foo)(CDATA em head foo)(bar foo)(CDATA bar foo)(ref bar foo)(CDATA foo)(head foo)(CDATA head foo)(b head foo)(CDATA b head foo)(tail foo)(foot tail foo)(middle tail foo)(foot tail foo)";
 }

if (1)                                                                          # Down revese
 {my $x = sample1;
  my $s;
  $x->downReverse(sub
   {$s .= "(".join(' ', map {$_->tag} @_).")";
   });
  ok $s eq "(foo)(tail foo)(foot tail foo)(middle tail foo)(foot tail foo)(head foo)(CDATA head foo)(b head foo)(CDATA b head foo)(CDATA foo)(bar foo)(CDATA bar foo)(ref bar foo)(head foo)(CDATA head foo)(em head foo)(CDATA em head foo)";
 }

if (1)                                                                          # By
 {my $x = sample1;
  my $s;
  $x->by(sub
   {$s .= "(".join(' ', map {$_->tag} @_).")";
   });
  ok $s eq "(CDATA head foo)(CDATA em head foo)(em head foo)(head foo)(CDATA bar foo)(ref bar foo)(bar foo)(CDATA foo)(CDATA head foo)(CDATA b head foo)(b head foo)(head foo)(foot tail foo)(middle tail foo)(foot tail foo)(tail foo)(foo)";
 }

if (1)                                                                          # By - reverse
 {my $x = sample1;
  my $s;
  $x->byReverse(sub
   {$s .= "(".join(' ', map {$_->tag} @_).")";
   });
  ok $s eq "(foot tail foo)(middle tail foo)(foot tail foo)(tail foo)(CDATA head foo)(CDATA b head foo)(b head foo)(head foo)(CDATA foo)(CDATA bar foo)(ref bar foo)(bar foo)(CDATA head foo)(CDATA em head foo)(em head foo)(head foo)(foo)";
 }

if (1)                                                                          # Through
 {my $x = sample1;
  my $s;
  $x->through(sub{$s .= "(".join(' ', map {$_->tag} @_).")"},
              sub{$s .= "[".join(' ', map {$_->tag} @_)."]"});
  ok $s eq "(foo)(head foo)(CDATA head foo)[CDATA head foo](em head foo)(CDATA em head foo)[CDATA em head foo][em head foo][head foo](bar foo)(CDATA bar foo)[CDATA bar foo](ref bar foo)[ref bar foo][bar foo](CDATA foo)[CDATA foo](head foo)(CDATA head foo)[CDATA head foo](b head foo)(CDATA b head foo)[CDATA b head foo][b head foo][head foo](tail foo)(foot tail foo)[foot tail foo](middle tail foo)[middle tail foo](foot tail foo)[foot tail foo][tail foo][foo]";
 }

if (1)                                                                          # Put as text
 {my $x = sample2;
  my $c = $x->get(qw(b c));
  $c->putFirstAsText("<d id=\"dd\">DDDD</d>");
  ok $x->string eq "<a id=\"aa\"><b id=\"bb\"><c id=\"cc\"><d id=\"dd\">DDDD</d></c></b></a>";
  $c->putLastAsText("<e id=\"ee\">EEEE</e>");
  ok $x->string eq "<a id=\"aa\"><b id=\"bb\"><c id=\"cc\"><d id=\"dd\">DDDD</d><e id=\"ee\">EEEE</e></c></b></a>";
  $c->putNextAsText("<n id=\"nn\">NNNN</n>");
  ok $x->string eq "<a id=\"aa\"><b id=\"bb\"><c id=\"cc\"><d id=\"dd\">DDDD</d><e id=\"ee\">EEEE</e></c><n id=\"nn\">NNNN</n></b></a>";
  $c->putPrevAsText("<p id=\"pp\">PPPP</p>");
  ok $x->string eq '<a id="aa"><b id="bb"><p id="pp">PPPP</p><c id="cc"><d id="dd">DDDD</d><e id="ee">EEEE</e></c><n id="nn">NNNN</n></b></a>';
 }

if (1)                                                                          # New
 {my $x = Data::Edit::Xml::newTree("a", id=>1, class=>"aa");
  ok $x->attrCount == 2;
  $x->putLast($x->newTag("b", id=>2, class=>"bb"));
  ok $x->get(qw(b))->attrCount == 2;
  ok $x->string eq '<a class="aa" id="1"><b class="bb" id="2"/></a>';
  $x->putLast($x->newText("t"));
  ok $x->string eq '<a class="aa" id="1"><b class="bb" id="2"/>t</a>';
 }

if (1)                                                                          # deleteAttrs
 {my $x = Data::Edit::Xml::newTree("a", id=>1, class=>"aa", name=>"a1");
  ok $x->attrCount == 3;
  $x->deleteAttrs(qw(class a aa bb a1 name));
  ok $x->attrCount == 1;
  ok $x->id == 1;
  ok !$x->class;
  ok !$x->attr(qw(name));
  ok !$x->attr(qw(aa));
 }

if (1)                                                                          # Wrap up
 {my $c = Data::Edit::Xml::newTree("c", id=>33);
  my ($b, $a) = $c->wrapUp(qw(b a));
  ok $a->tag eq qq(a);
  ok $b->tag eq qq(b);
  ok $c->tag eq qq(c);
  ok $a->get(qw(b c))->id == 33;
  ok $a->string eq '<a><b><c id="33"/></b></a>';
 }

if (1)                                                                          # Wrap down
 {my $a = Data::Edit::Xml::newTree("a", id=>33);
  my ($b, $c) = $a->wrapDown(qw(b c));
  ok $a->tag eq qq(a);
  ok $b->tag eq qq(b);
  ok $c->tag eq qq(c);
  ok $a->id == 33;
  ok $a->string eq '<a id="33"><b><c/></b></a>';
 }

if (1)                                                                          # Unwrap
 {my $x = Data::Edit::Xml::new("<a><b><c/></b></a>");
  $x->get(qw(b c))->unwrap;
  $x->checkParentage;
  ok $x->string eq "<a><b/></a>";
  $x->get(qw(b))->unwrap;
  ok $x->string eq "<a/>";
  eval {$x->unwrap};
  ok $@ =~ /\ACannot unwrap the outer most node/gs;
 }

if (1)                                                                          # Cut
 {my $x = Data::Edit::Xml::new("<a><b><c/></b></a>");
  $x->get(qw(b c))->cut;
  $x->checkParentage;
  ok $x->string eq "<a><b/></a>";
  $x->get(qw(b))->cut;
  ok $x->string eq "<a/>";
  eval {$x->cut};
  ok !$@;                                                                       # Permit multiple cut outs of the same node
 }

if (1)                                                                          # Errors
 {my $f = "zzz.xml";
  my $e = "zzz.data";
  writeFile($f, <<END);
<a>
END
  my $x = Data::Edit::Xml::new();
     $x->input      = $f;
     $x->errorsFile = $e;
  eval {$x->parse};
  ok $@ =~ /\AXml parse error, see file:/;
  ok -e $e;
  my $s = readFile($e);
  ok CORE::index($s, $f) > 0;
  ok $s =~ /no element found at line 2, column 0, byte 4/s;
  unlink $e, $f;
 }

if (1)                                                                          # Unwrap/Cut in by
 {my $f = "zzz.xml";
  writeFile($f, <<END);
<a>
  <b><c/><C/><c/></b>
  <b><c/><c/><C/></b>
  <B><c/><c/><C/></B>
  <b><c/><c/><C/></b>
  <b><C/><C/><c/></b>
  <B><C/><C/><C/></B>
  <B><c/><c/><C/></B>
</a>
END
  my $x = Data::Edit::Xml::new();
     $x->input = $f;
     $x->parse;
  unlink $f;

  my $A = 0;
  $x->checkParser;
  $x->by(sub                                                                    # Add stuff and move things around
   {for my $t('', ' ', 'aa', 11)
     {eval{$_->putFirst($x->newNode($_))}             if ++$A %  3 == 0;
      eval{$_->putLast ($x->newNode($_))}             if ++$A %  5 == 0;
      eval{$_->putNext ($x->newNode($_))}             if ++$A %  7 == 0;
      eval{$_->putPrev ($x->newNode($_))}             if ++$A %  2 == 0;
      eval{$_->putFirstAsText($t)}                    if ++$A %  3 == 0;
      eval{$_->putLastAsText ($t)}                    if ++$A %  2 == 0;
      eval{$_->putNextAsText ($t)}                    if ++$A %  3 == 0;
      eval{$_->putPrevAsText ($t)}                    if ++$A %  2 == 0;
      eval{$_->wrapContentWith(qw(ww))}               if ++$A %  5 == 0;
      eval{$_->wrapWith(qw(xx))}                      if ++$A %  3 == 0;
      eval{$_->wrapUp  (qw(aa bb))}                   if ++$A %  5 == 0;
      eval{$_->wrapDown(qw(cc dd))}                   if ++$A %  7 == 0;
      eval{$_->parent->        putFirst   ($_->cut_)} if ++$A %  2 == 0;
      eval{$_->parent->parent->putFirst   ($_->cut_)} if ++$A %  3 == 0;
      eval{$_->parent->        putLast    ($_->cut_)} if ++$A %  5 == 0;
      eval{$_->parent->parent->putLast    ($_->cut_)} if ++$A %  3 == 0;
      eval{$_->parent->        putNext    ($_->cut_)} if ++$A %  2 == 0;
      eval{$_->parent->parent->putNext    ($_->cut_)} if ++$A %  5 == 0;
      eval{$_->parent->        putPrev    ($_->cut_)} if ++$A %  2 == 0;
      eval{$_->parent->parent->putPrev    ($_->cut_)} if ++$A %  3 == 0;
      eval{$_->parent->        replaceWith($_->cut_)} if ++$A %  2 == 0;
      eval{$_->parent->parent->replaceWith($_->cut_)} if ++$A %  3 == 0;
     }
   });
# say STDERR "AAAA ", $x->tags; exit;
  ok $x->tags == 279;
  $x->checkParentage;

  my $a = 0;
  $x->by(sub
   {my $t = $_->tag;
    eval {$x->cut};
    eval {$x->unwrap};
    eval {$_->cut}    if ++$a % 2;
    eval {$_->unwrap} if ++$a % 2;
   });

  $x->checkParentage;
  ok $x->string eq "<a/>";
 }

if (1)                                                                          # First of
 {my $x = Data::Edit::Xml::new(<<END);
<a>
  <b id="b1"><c id="1"/></b>
  <d id="d1"><c id="2"/></d>
  <e id="e1"><c id="3"/></e>
  <b id="b2"><c id="4"/></b>
  <d id="d2"><c id="5"/></d>
  <e id="e2"><c id="6"/></e>
</a>
END

  ok !$x->firstContextOf(qw(c a));
  ok !$x-> lastContextOf(qw(c a));

  ok $x->firstContextOf(qw(c b))->id == 1;
  ok $x->firstContextOf(qw(c d))->id == 2;
  ok $x->firstContextOf(qw(c e))->id == 3;
  ok $x-> lastContextOf(qw(c b))->id == 4;
  ok $x-> lastContextOf(qw(c d))->id == 5;
  ok $x-> lastContextOf(qw(c e))->id == 6;
 }

ok Data::Edit::Xml::new(<<END)->                                                # Docbook
<sli>
  <li>
    <p>Diagnose the problem</p>
    <p>This can be quite difficult</p>
    <p>Sometimes impossible</p>
  </li>
  <li>
  <p><pre>ls -la</pre></p>
  <p><pre>
drwxr-xr-x  2 phil phil   4096 Jun 15  2016 Desktop
drwxr-xr-x  2 phil phil   4096 Nov  9 20:26 Downloads
</pre></p>
  </li>
</sli>
END

by(sub                                                                          # Transform Docbook to Dita
 {my ($o, $p) = @_;
  if ($o->at(qw(pre p li sli)) and $o->isOnlyChild)
   {$o->change($p->isFirst ? qw(cmd) : qw(stepresult));
    $p->unwrap;
   }
  elsif ($o->at(qw(li sli)) and $o->over(qr(\Ap( p)+\Z)))
   {$_->change($_->isFirst ? qw(cmd) : qw(info)) for $o->contents;
   }
 })->by(sub
 {my ($o) = @_;
  $o->change(qw(step))          if $o->at(qw(li sli));
  $o->change(qw(steps))         if $o->at(qw(sli));
  $o->id = 's'.($o->position+1) if $o->at(qw(step));
  $o->id = 'i'.($o->index+1)    if $o->at(qw(info));
  $o->wrapWith(qw(screen))      if $o->at(qw(CDATA stepresult));
 })->string =~ s/></>\n</gr eq trim(<<END);                                     # Dita
<steps>
<step id="s1">
<cmd>Diagnose the problem</cmd>
<info id="i1">This can be quite difficult</info>
<info id="i2">Sometimes impossible</info>
</step>
<step id="s2">
<cmd>ls -la</cmd>
<stepresult>
<screen>
drwxr-xr-x  2 phil phil   4096 Jun 15  2016 Desktop
drwxr-xr-x  2 phil phil   4096 Nov  9 20:26 Downloads
</screen>
</stepresult>
</step>
</steps>
END
