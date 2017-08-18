#!/usr/bin/perl
# -I/home/phil/z/perl/cpan/DataTableText/lib
#-------------------------------------------------------------------------------
# Edit data held in xml format
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2016-2017
#-------------------------------------------------------------------------------
# Preserve labels across a reparse by adding them to an used attribute
# upto with multiple targets
# uptoAnyOf - wide search up
# podDocumentation

package Data::Edit::Xml;
use v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Table::Text qw(:all);
use XML::Parser;                                                                # https://metacpan.org/pod/XML::Parser
use Storable qw(store retrieve freeze thaw);
our $VERSION = 20170817;

#1 Construction                                                                 # Create a parse tree, either by parsing a L<file or string|/file or string>, or, L<node by node|/Node by Node>

#2 File or String                                                               # Construct a parse tree from a file or a string

sub new(;$)                                                                     #IS New parse - call this method statically as in Data::Edit::Xml::new(file or string) B<or> with no parameters and then use L</input>, L</inputFile>, L</inputString>, L</errorFile>  to provide specific parameters for the parse, then call L</parse> to perform the parse and return the parse tree.
 {my ($fileNameOrString) = @_;                                                  # File name or string
  if (@_)
   {my $x = bless {input=>$fileNameOrString};                                   # Create xml editor with a string or file
    $x->parser = $x;                                                            # Parser root node
    return $x->parse;                                                           # Parse
   }
  my $x = bless {};                                                             # Create empty xml editor
  $x->parser = $x;                                                              # Parser root node
  $x                                                                            # Parser
 }

genLValueArrayMethods (qw(content));                                            # Content of command: the nodes immediately below this node in the order in which they appeared in the source text, see also L</Contents>.
genLValueArrayMethods (qw(numbers));                                            # Nodes by number.
genLValueHashMethods  (qw(attributes));                                         # The attributes of this node, see also: L</Attributes>.  The frequently used attributes: class, id, href, outputclass can be accessed by an lvalue method as in: $node->id = 'c1'.
genLValueHashMethods  (qw(conditions));                                         # Conditional strings attached to a node, see L</Conditions>.
genLValueHashMethods  (qw(indexes));                                            # Indexes to sub commands by tag in the order in which they appeared in the source text.
genLValueHashMethods  (qw(labels));                                             # The labels attached to a node to provide addressability from other nodes, see: L</Labels>.
genLValueScalarMethods(qw(errorsFile));                                         # Error listing file. Use this parameter to explicitly set the name of the file that will be used to write an parse errors to. By default this file is named: B<zzzParseErrors/out.data>.
genLValueScalarMethods(qw(inputFile));                                          # Source file of the parse if this is the parser root node. Use this parameter to explicitly set the file to be parsed.
genLValueScalarMethods(qw(input));                                              # Source of the parse if this is the parser root node. Use this parameter to specify some input either as a string or as a file name for the parser to convert into a parse tree.
genLValueScalarMethods(qw(inputString));                                        # Source string of the parse if this is the parser root node. Use this parameter to explicitly set the string to be parsed.
genLValueScalarMethods(qw(number));                                             # Number of this node, see L<findByNumber|/findByNumber> and L<numberTree|/numberTree>.
genLValueScalarMethods(qw(parent));                                             # Parent node of this node or undef if the oarser root node. See also L</Traversal> and L</Navigation>. Consider as read only.
genLValueScalarMethods(qw(parser));                                             # Parser details: the root node of a tree is the parse node for that tree. Consider as read only.
genLValueScalarMethods(qw(tag));                                                # Tag name for this node, see also L</Traversal> and L</Navigation>. Consider as read only.
genLValueScalarMethods(qw(text));                                               # Text of this node but only if it is a text node, i.e. the tag is cdata() <=> L</isText> is true.

sub cdata                                                                       # The name of the tag to be used to represent text - this tag must not also be used as a command tag otherwise the parser will L<confess|http://perldoc.perl.org/Carp.html#SYNOPSIS/>.
 {'CDATA'
 }

sub parse($)                                                                    # Parse input xml specified via: L<inputFile|/inputFile>, L<input|/input> or L<inputString|/inputString>.
 {my ($parser) = @_;                                                            # Parser created by L</new>
  my $badFile = $parser->errorsFile // 'zzzParseErrors/out.data';               # File to write source xml into if a parsing error occurs
  unlink $badFile if -e $badFile;                                               # Remove existing errors file

  if (my $s = $parser->input)                                                   # Source to be parsed is a file or a string
   {if ($s =~ /\n/s or !-e $s)                                                  # Parse as a string because it does not look like a file name
     {$parser->inputString = $s;
     }
    else                                                                        # Parse a file
     {$parser->inputFile = $s;
      $parser->inputString = readFile($s);
     }
   }
  elsif (my $f = $parser->inputFile)                                            # Source to be parsed is a file
   {$parser->inputString = readFile($f);
   }
  elsif ($parser->inputString) {}                                               # Source to be parsed is a string
  else                                                                          # Unknown string
   {confess "Supply a string or file to be parsed";
   }

  my $xmlParser = new XML::Parser(Style => 'Tree');                             # Extend Larry Wall's excellent XML parser
  my $d = $parser->inputString;                                                 # String to be parsed
  my $x = eval {$xmlParser->parse($d)};                                         # Parse string
  if (!$x)                                                                      # Error in parse
   {my $f = $parser->inputFile ? "Source files is:\n".                          # Source details if a file
            $parser->inputFile."\n" : '';
    writeFile($badFile, "$d\n$f\n$@\n");                                        # Write a description of the error to the errorsFile
    confess "Xml parse error, see file:\n$badFile\n";                           # Complain helpfully if parse failed
   }
  $parser->tree($x);                                                            # Structure parse results as a tree
  if (my @c = @{$parser->content})
   {confess "No xml" if !@c;
    confess "More than one outer-most tag" if @c > 1;
    my $c = $c[0];
    $parser->tag        = $c->tag;
    $parser->attributes = $c->attributes;
    $parser->content    = $c->content;
    $parser->parent     = undef;
    $parser->indexNode;
   }
  $parser                                                                       # Parse details
 }

sub tree($$)                                                                    #P Build a tree representation of the parsed xml which can be easily traversed to look for things.
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
       {$s = replaceSpecialChars($s);                                           # Restore special characters in the text
        $node->tag = cdata;                                                     # Save text. ASSUMPTION: CDATA is not used as a tag anywhere.
        $node->text = $s;
        push @{$parent->content}, $node;                                        # Save on parents content list
       }
     }
    else                                                                        # Node
     {my $children   = shift @$parse;
      my $attributes = shift @$children;
      $node->tag = $tag;                                                        # Save tag
      $_ = replaceSpecialChars($_) for values %$attributes;                     # Restore in text with xml special characters
      $node->attributes = $attributes;                                          # Save attributes
      push @{$parent->content}, $node;                                          # Save on parents content list
      $node->tree($children) if $children;                                      # Add nodes below this node
     }
   }
  $parent->indexNode;                                                           # Index this node
 }

#2 Node by Node                                                                 # Construct a parse tree node by node.

sub newText($$)                                                                 # Create a new text node.
 {my (undef, $text) = @_;                                                       # Any reference to this package, content of new text node
  my $node = bless {};                                                          # New node
  $node->parser = $node;                                                        # Root node of this parse
  $node->tag    = cdata;                                                        # Text node
  $node->text   = $text;                                                        # Content of node
  $node                                                                         # Return new non text node
 }

sub newTag($$%)                                                                 # Create a new non text node.
 {my (undef, $command, %attributes) = @_;                                       # Any reference to this package, the tag for the node, attributes as a hash.
  my $node = bless {};                                                          # New node
  $node->parser = $node;                                                        # Root node of this parse
  $node->tag    = $command;                                                     # Tag for node
  $node->attributes = \%attributes;                                             # Attributes for node
  $node                                                                         # Return new node
 }

sub newTree($%)                                                                 # Create a new tree.
 {my ($command, %attributes) = @_;                                              # The name of the root node in the tree, attributes of the root node in the tree as a hash.
  &newTag(undef, @_)
 }

sub disconnectLeafNode($)                                                       #P Remove a leaf node from the parse tree and make it into its own parse tree.
 {my ($node) = @_;                                                              # Leaf node to disconnect.
  $node->parent = undef;                                                        # No parent
  $node->parser = $node;                                                        # Own parse tree
 }

sub indexNode($)                                                                #P Index the children of a node so that we can access them by tag and number.
 {my ($node) = @_;                                                              # Node to index.
  delete $node->{indexes};                                                      # Delete the indexes
  my @contents = $node->contents;                                               # Contents of the node
  return unless @contents;                                                      # No content so no indexes

  if ((grep {$_->isText} @contents) > 1)                                        # Make parsing easier for the user by concatenating successive text nodes
   {my (@c, @t);                                                                # New content, pending intermediate texts list
    for(@contents)                                                              # Each node under the current node
     {if ($_->isText)                                                           # Text node
       {push @t, $_;                                                            # Add the text node to pending intermediate texts list
       }
      elsif (@t == 1)                                                           # Non text element encountered with one pending intermediate text
       {push @c, @t, $_;                                                        # Save the text node and the latest non text node
        @t = ();                                                                # Empty pending intermediate texts list
       }
      elsif (@t  > 1)                                                           # Non text element encountered with two or more pending intermediate texts
       {my $t = shift @t;                                                       # Reuse the first text node
        $t->text .= join '', map {$_->text} @t;                                 # Concatenate the remaining text nodes
        $_->disconnectLeafNode for @t;                                          # Disconnect the remain text nodes as they are no longer needed
        push @c, $t, $_;                                                        # Save the resulting text node and the latest non text node
        @t = ();                                                                # Empty pending intermediate texts list
       }
      else {push @c, $_}                                                        # Non text node encountered without immediately preceding text
     }

    if    (@t == 0) {}                                                          # No action required if no pending text at the end
    elsif (@t == 1) {push @c, @t}                                               # Just one text node
    else                                                                        # More than one text node - remove leading and trailing blank text nodes
     {my $t = shift @t;                                                         # Reuse the first text node
      $t->text .= join '', map {$_->text} @t;                                   # Concatenate the remaining text nodes
      $_->disconnectLeafNode for @t;                                            # Disconnect the remain text nodes as they are no longer needed
      push @c, $t;                                                              # Save resulting text element
     }

    @contents      =  @c;                                                       # The latest content of the node
    $node->content = \@c;                                                       # Node contents with concatenated text elements
   }

  for my $n(@contents)                                                          # Index content
   {push @{$node->indexes->{$n->tag}}, $n;                                      # Indices to sub nodes
    $n->parent = $node;                                                         # Point to parent
    $n->parser = $node->parser;                                                 # Point to parser
   }
 }

sub replaceSpecialChars($)                                                      # Replace < > " with &lt; &gt; &quot;  Larry Wall's excellent L<Xml parser|https://metacpan.org/pod/XML::Parser/> unfortunately replaces &lt; &gt; &quot; &amp; etc. with their expansions in text by default and does not seem to provide an obvious way to stop this behavior, so we have to put them back gain using this method. Worse, we cannot decide whether to replace & with &amp; or leave it as is: consequently you might have to examine the instances of & in your output text and guess based on the context.
 {my ($string) = @_;                                                            # String to be edited.
  $_[0] =~ s/\</&lt;/gr =~ s/\>/&gt;/gr =~ s/\"/&quot;/gr                       # Replace the special characters that we can replace.
 }

sub renew($)                                                                    # Returns a renewed copy of the parse tree: use this method if you have added nodes via the L</"Put as text"> methods and wish to reprocess them.
 {my ($node) = @_;                                                              # Parse tree.
  new($node->string)
 }

sub clone($)                                                                    # Return a clone of the parse tree: use this method if you want to make changes to an exact copy of the parse tree.
 {my ($node) = @_;                                                              # Parse tree.
  my $f = freeze($node);
  my $t = thaw($f);
  $t->parent = undef;
  $t->parser = $t;
  $t
 }

sub equals($$)                                                                  #X Return the first node if the two parse trees are equal, else B<undef> if they are not equal.
 {my ($node1, $node2) = @_;                                                     # Parse tree 1, parse tree 2.
  $node1->string eq $node2->string ? $node1 : undef                             # Test
 }

sub save($$)                                                                    # Save a copy of the parse tree to a file which can be L<restored|/restore> and return the saved node.
 {my ($node, $file) = @_;                                                       # Parse tree, file.
  makePath($file);
  store $node, $file;
  $node
 }

sub restore($)                                                                  #SX Return a parse tree from a copy saved in a file by L</save>.
 {my ($file) = @_;                                                              # File
  -e $file or confess "Cannot restore from a non existent file:\n$file";
  retrieve $file
 }

#1 Stringification                                                              # L<Create|/Print> a string representation of the parse tree with optional selection of nodes via L<conditions|/Conditions>.

#2 Print                                                                        # Print the parse tree. Normally use L<prettyString|/prettyString> string to format the xml in a readable yet reparseable manner; use L<string|/string> string to format the xml densely in a reparseable manner; use the other methods to produce unreparseable strings conveniently formatted to assist various specialized operations such as debugging CDATA, using labels or creating tests. A number of the L<file test operators|/opString> can also be conveniently used to print parse trees in these formats.

sub string($)                                                                   # Return a dense string representing a node of a parse tree and all the nodes below it. Or use L<-s|/opString> $node
 {my ($node) = @_;                                                              # Start node.
  return $node->text if $node->isText;                                          # Text node
  my $t = $node->tag;                                                           # Not text so it has a tag
  my $content = $node->content;                                                 # Sub nodes
  return '<'.$t.$node->printAttributes.'/>' if !@$content;                      # No sub nodes

  my $s = '<'.$t.$node->printAttributes.'>';                                    # Has sub nodes
  $s .= $_->string for @$content;                                               # Recurse to get the sub content
  return $s.'</'.$t.'>';
 }

sub stringQuoted($)                                                             # Return a quoted string representing a parse tree a node of a parse tree and all the nodes below it. Or use L<-o|/opString> $node
 {my ($node) = @_;                                                              # Start node
  "'".$node->string."'"
 }

sub stringReplacingIdWithLabels($)                                              # Return a string representing the specified parse tree with the id attribute of each node set to the L<Labels|/Labels> attached to each node.
 {my ($node) = @_;                                                              # Start node.
  return $node->text if $node->isText;                                          # Text node
  my $t = $node->tag;                                                           # Not text so it has a tag
  my $content = $node->content;                                                 # Sub nodes
  return '<'.$t.$node->printAttributesReplacingIdsWithLabels.'/>' if !@$content;# No sub nodes

  my $s = '<'.$t.$node->printAttributesReplacingIdsWithLabels.'>';              # Has sub nodes
  $s .= $_->stringReplacingIdWithLabels for @$content;                          # Recurse to get the sub content
  return $s.'</'.$t.'>';
 }

sub stringReplacingIdWithLabelsQuoted($)                                        # Return a quoted string representing a node of a parse tree and all the nodes below it with all the id attributes replaced with the labels attached to each node.
 {my ($node) = @_;                                                              # Start node.
  "'".$node->stringReplacingIdWithLabels."'"
 }

sub contentString($)                                                            # Return a string representing all the nodes below a node of a parse tree.
 {my ($node) = @_;                                                              # Start node.
  my $s = '';
  $s .= $_->string for $node->contents;                                         # Recurse to get the sub content
  $s
 }

sub prettyString($;$)                                                           #I Return a readable string representing a node of a parse tree and all the nodes below it. Or use L<-p|/opString> $node
 {my ($node, $depth) = @_;                                                      # Start node, optional depth.
  $depth //= 0;                                                                 # Start depth if none supplied

  if ($node->isText)                                                            # Text node
   {my $n = $node->next;
    my $s = defined($n) && $n->isText ? '' : "\n";                              # Add a new line after contiguous blocks of text to offset next node
    return $node->text.$s;
   }

  my $t = $node->tag;                                                           # Not text so it has a tag
  my $content = $node->content;                                                 # Sub nodes
  my $space   = "  "x($depth//0);
  return $space.'<'.$t.$node->printAttributes.'/>'."\n" if !@$content;          # No sub nodes

  my $s = $space.'<'.$t.$node->printAttributes.'>'.                             # Has sub nodes
    ($node->first->isText ? '' : "\n");                                         # Continue text on the same line, otherwise place nodes on following lines
  $s .= $_->prettyString($depth+1) for @$content;                               # Recurse to get the sub content
  $s.$space.'</'.$t.'>'."\n";
 }

sub prettyStringNumbered($;$)                                                   # Return a readable string representing a node of a parse tree and all the nodes below it with a L<number|/number> attached to each tag. The node numbers can then be used as described in L<Order|/Order> to monitor changes to the parse tree.
 {my ($node, $depth) = @_;                                                      # Start node, optional depth.
  $depth //= 0;                                                                 # Start depth if none supplied
  $node->numberTree unless $depth;                                              # Make sure the node and its sub nodes are fully numbered.

  if ($node->isText)                                                            # Text node
   {my $n = $node->next;
    my $s = defined($n) && $n->isText ? '' : "\n";                              # Add a new line after contiguous blocks of text to offset next node
    return $node->text.$s;
   }

  my $t = $node->tag.'_'.$node->number;                                         # Not text so it has a tag_number whcih can be skipped between in L<Geany|http://www.geany.org> using the ctrl+up and ctrl+down arrows
  my $content = $node->content;                                                 # Sub nodes
  my $space   = "  "x($depth//0);
  return $space.'<'.$t.$node->printAttributes.'/>'."\n" if !@$content;          # No sub nodes

  my $s = $space.'<'.$t.$node->printAttributes.'>'.                             # Has sub nodes
    ($node->first->isText ? '' : "\n");                                         # Continue text on the same line, otherwise place nodes on following lines
  $s .= $_->prettyStringNumbered($depth+1) for @$content;                       # Recurse to get the sub content
  $s.$space.'</'.$t.'>'."\n";
 }

sub prettyStringShowingCDATA($;$)                                               # Return a readable string representing a node of a parse tree and all the nodes below it with the text fields wrapped with <CDATA>...</CDATA>.
 {my ($node, $depth) = @_;                                                      # Start node, optional depth.
  $depth //= 0;                                                                 # Start depth if none supplied

  if ($node->isText)                                                            # Text node
   {my $n = $node->next;
    my $s = defined($n) && $n->isText ? '' : "\n";                              # Add a new line after contiguous blocks of text to offset next node
    return '<'.cdata.'>'.$node->text.'</'.cdata.'>'.$s;
   }

  my $t = $node->tag;                                                           # Not text so it has a tag
  my $content = $node->content;                                                 # Sub nodes
  my $space   = "  "x($depth//0);
  return $space.'<'.$t.$node->printAttributes.'/>'."\n" if !@$content;          # No sub nodes

  my $s = $space.'<'.$t.$node->printAttributes.'>'.                             # Has sub nodes
    ($node->first->isText ? '' : "\n");                                         # Continue text on the same line, otherwise place nodes on following lines
  $s .= $_->prettyStringShowingCDATA($depth+2) for @$content;                   # Recurse to get the sub content
  $s.$space.'</'.$t.'>'."\n";
 }

sub prettyStringEnd($)                                                          # Return a readable string representing a node of a parse tree and all the nodes below it as a here document
 {my ($node) = @_;                                                              # Start node
  my $s = -p $node;                                                             # Pretty string representation
'  ok -p $x eq <<END;'. "\n".(-p $node). "\nEND"                                # Here document
 }

sub PrettyContentString($)                                                      # Return a readable string representing all the nodes below a node of a parse tree - infrequent use and so capitalized to avoid being presented as an option by L<Geany|http://www.geany.org/>.
 {my ($node) = @_;                                                              # Start node.
  my $s = '';
  $s .= $_->prettyString for $node->contents;                                   # Recurse to get the sub content
  $s
 }

#2 Conditions                                                                   # Print a subset of the the parse tree determined by the conditions attached to it.

sub stringWithConditions($@)                                                    # Return a string representing a node of a parse tree and all the nodes below it subject to conditions to select or reject some nodes.
 {my ($node, @conditions) = @_;                                                 # Start node, conditions to be regarded as in effect.
  return $node->text if $node->isText;                                          # Text node
  my %c = %{$node->conditions};                                                 # Process conditions if any for this node
  return '' if keys %c and @conditions and !grep {$c{$_}} @conditions;          # Return if conditions are in effect and no conditions match
  my $t = $node->tag;                                                           # Not text so it has a tag
  my $content = $node->content;                                                 # Sub nodes

  my $s = ''; $s .= $_->stringWithConditions(@conditions) for @$content;        # Recurse to get the sub content
  return '<'.$t.$node->printAttributes.'/>' if !@$content or $s =~ /\A\s*\Z/;   # No sub nodes or none selected
  '<'.$t.$node->printAttributes.'>'.$s.'</'.$t.'>';                             # Has sub nodes
 }

sub addConditions($@)                                                           # Add conditions to a node and return the node.
 {my ($node, @conditions) = @_;                                                 # Node, conditions to add.
  $node->conditions->{$_}++ for @conditions;
  $node
 }

sub deleteConditions($@)                                                        # Delete conditions applied to a node and return the node.
 {my ($node, @conditions) = @_;                                                 # Node, conditions to add.
  delete $node->conditions->{$_} for @conditions;
  $node
 }

sub listConditions($)                                                           # Return a list of conditions applied to a node.
 {my ($node) = @_;                                                              # Node.
  sort keys %{$node->conditions}
 }

#1 Attributes                                                                   # Get or set the attributes of nodes in the parse tree. Well known attributes can be set directly via L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>s for less well known attributes use L<attr|/attr>.

if (0) {                                                                        # Node attributes.
genLValueScalarMethods(qw(class));                                              # Attribute B<class> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(href));                                               # Attribute B<href> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(id));                                                 # Attribute B<id> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(outputclass));                                        # Attribute B<outputclass> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
}

BEGIN
 {for(qw(class href id outputclass))                                            # Return well known attributes as an assignable value
   {eval 'sub '.$_.'($) :lvalue {&attr($_[0], qw('.$_.'))}';
    $@ and confess "Cannot create well known attribute $_\n$@";
   }
 }

sub attr($$) :lvalue                                                            #I Return the value of an attribute of the current node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
 {my ($node, $attribute) = @_;                                                  # Node in parse tree, attribute name.
  $node->attributes->{$attribute}
 }

sub attrs($@)                                                                   # Return the values of the specified attributes of the current node.
 {my ($node, @attributes) = @_;                                                 # Node in parse tree, attribute names.
  my @v;
  my $a = $node->attributes;
  push @v, $a->{$_} for @attributes;
  @v
 }

sub attrCount($)                                                                # Return the number of attributes in the specified node.
 {my ($node) = @_;                                                              # Node in parse tree, attribute names.
  keys %{$node->attributes}
 }

sub getAttrs($)                                                                 # Return a sorted list of all the attributes on this node.
 {my ($node) = @_;                                                              # Node in parse tree.
  sort keys %{$node->attributes}
 }

sub setAttr($@)                                                                 # Set the value of an attribute in a node and return the node.
 {my ($node, %values) = @_;                                                     # Node in parse tree, (attribute name=>new value)*
  s/["<>]/ /gs for grep {$_} values %values;                                    # We cannot have these characters in an attribute
  $node->attributes->{$_} = $values{$_} for keys %values;                       # Set attributes
  $node
 }

sub deleteAttr($$;$)                                                            # Delete the attribute, optionally checking its value first and return the node.
 {my ($node, $attr, $value) = @_;                                               # Node, attribute name, optional attribute value to check first.
  my $a = $node->attributes;                                                    # Attributes hash
  if (@_ == 3)
   {delete $a->{$attr} if defined($a->{$attr}) and $a->{$attr} eq $value;       # Delete user key if it has the right value
   }
  else
   {delete $a->{$attr};                                                         # Delete user key unconditionally
   }
  $node
 }

sub deleteAttrs($@)                                                             # Delete any attributes mentioned in a list without checking their values and return the node.
 {my ($node, @attrs) = @_;                                                      # Node, attribute name, optional attribute value to check first.
  my $a = $node->attributes;                                                    # Attributes hash
  delete $a->{$_} for @attrs;
  $node
 }

sub renameAttr($$$)                                                             # Change the name of an attribute regardless of whether the new attribute already exists and return the node.
 {my ($node, $old, $new) = @_;                                                  # Node, existing attribute name, new attribute name.
  my $a = $node->attributes;                                                    # Attributes hash
  if (defined($a->{$old}))                                                      # Check old attribute exists
   {my $value = $a->{$old};                                                     # Existing value
    $a->{$new} = $value;                                                        # Change the attribute name
    delete $a->{$old};
   }
  $node
 }

sub changeAttr($$$)                                                             # Change the name of an attribute unless it has already been set and return the node.
 {my ($node, $old, $new) = @_;                                                  # Node, existing attribute name, new attribute name.
  exists $node->attributes->{$new} ? $node : $node->renameAttr($old, $new)      # Check old attribute exists
 }

sub renameAttrValue($$$$$)                                                      # Change the name and value of an attribute regardless of whether the new attribute already exists and return the node.
 {my ($node, $old, $oldValue, $new, $newValue) = @_;                            # Node, existing attribute name, existing attribute value, new attribute name, new attribute value.
  my $a = $node->attributes;                                                    # Attributes hash
  if (defined($a->{$old}) and $a->{$old} eq $oldValue)                          # Check old attribute exists and has the specified value
   {$a->{$new} = $newValue;                                                     # Change the attribute name
    delete $a->{$old};
   }
  $node
 }

sub changeAttrValue($$$$$)                                                      # Change the name and value of an attribute unless it has already been set and return the node.
 {my ($node, $old, $oldValue, $new, $newValue) = @_;                            # Node, existing attribute name, existing attribute value, new attribute name, new attribute value.
  exists $node->attributes->{$new} ? $node :                                    # Check old attribute exists
    $node->renameAttrValue($old, $oldValue, $new, $newValue)
 }

#1 Traversal                                                                    # Traverse the parse tree in various orders applying a B<sub> to each node.

sub by($$;@)                                                                    #I Post-order traversal of a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  $_->by($sub, $node, @context) for @n;                                         # Recurse to process sub nodes in deeper context
  &$sub(local $_ = $node, @context);                                            # Process specified node last
  $node
 }

sub byX($$;@)                                                                   # Post-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  $_->byX($sub, $node, @context) for @n;                                        # Recurse to process sub nodes in deeper context
  eval {&$sub(local $_ = $node, @context)};                                     # Process specified node last
  $node
 }

sub byReverse($$;@)                                                             # Reverse post-order traversal of a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  $_->byReverse($sub, $node, @context) for reverse @n;                          # Recurse to process sub nodes in deeper context
  &$sub(local $_ = $node, @context);                                            # Process specified node last
  $node
 }

sub byReverseX($$;@)                                                            # Reverse post-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  $_->byReverseX($sub, $node, @context) for reverse @n;                         # Recurse to process sub nodes in deeper context
  &$sub(local $_ = $node, @context);                                            # Process specified node last
  $node
 }

sub down($$;@)                                                                  # Pre-order traversal down through a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$sub(local $_ = $node, @context);                                            # Process specified node first
  $_->down($sub, $node, @context) for @n;                                       # Recurse to process sub nodes in deeper context
  $node
 }

sub downX($$;@)                                                                 # Pre-order traversal down through a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$sub(local $_ = $node, @context);                                            # Process specified node first
  $_->downX($sub, $node, @context) for @n;                                      # Recurse to process sub nodes in deeper context
  $node
 }

sub downReverse($$;@)                                                           # Reverse pre-order traversal down through a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$sub(local $_ = $node, @context);                                            # Process specified node first
  $_->downReverse($sub, $node, @context) for reverse @n;                        # Recurse to process sub nodes in deeper context
  $node
 }

sub downReverseX($$;@)                                                          # Reverse pre-order traversal down through a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$sub(local $_ = $node, @context);                                            # Process specified node first
  $_->downReverseX($sub, $node, @context) for reverse @n;                       # Recurse to process sub nodes in deeper context
  $node
 }

sub through($$$;@)                                                              # Traverse parse tree visiting each node twice calling the specified B<sub> at each node and returning the specified starting node. The B<sub>s are passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.
 {my ($node, $before, $after, @context) = @_;                                   # Starting node, sub to call when we meet a node, sub to call we leave a node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$before(local $_ = $node, @context);                                         # Process specified node first with before()
  $_->through($before, $after, $node, @context) for @n;                         # Recurse to process sub nodes in deeper context
  &$after(local $_ = $node, @context);                                          # Process specified node last with after()
  $node
 }

sub throughX($$$;@)                                                             # Traverse parse tree visiting each node twice calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.
 {my ($node, $before, $after, @context) = @_;                                   # Starting node, sub to call when we meet a node, sub to call we leave a node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$before(local $_ = $node, @context);                                         # Process specified node first with before()
  $_->throughX($before, $after, $node, @context) for @n;                        # Recurse to process sub nodes in deeper context
  &$after(local $_ = $node, @context);                                          # Process specified node last with after()
  $node
 }

#1 Contents                                                                     # The immediate content of each node, i.e. the children of a node.

sub contents($)                                                                 # Return all the nodes contained by this node either as an array or as a reference to such an array.
 {my ($node) = @_;                                                              # Node.
  my $c = $node->content;                                                       # Contents reference
  $c ? @$c : ()                                                                 # Contents as an array
 }

sub contentBeyond($)                                                            # Return all the sibling nodes following this node at the level of this node.
 {my ($node) = @_;                                                              # Node.
  my $parent = $node->parent;                                                   # Parent
  return () if !$parent;                                                        # The uppermost node has no content beyond it
  my @c = $parent->contents;                                                    # Contents of parent
  while(@c)                                                                     # Test until no more nodes left to test
   {my $c = shift @c;                                                           # Position of current node
    return @c if $c == $node                                                    # Nodes beyond this node if it is the searched for node
   }
  confess "Node not found in parent";                                           # Something wrong with parent/child relationship
 }

sub contentBefore($)                                                            # Return all the sibling nodes preceding this node at the level of this node.
 {my ($node) = @_;                                                              # Node.
  my $parent = $node->parent;                                                   # Parent
  return () if !$parent;                                                        # The uppermost node has no content beyond it
  my @c = $parent->contents;                                                    # Contents of parent
  while(@c)                                                                     # Test until no more nodes left to test
   {my $c = pop @c;                                                             # Position of current node
    return @c if $c == $node                                                    # Nodes beyond this node if it is the searched for node
   }
  confess "Node not found in parent";                                           # Something wrong with parent/child relationship
 }

sub contentAsTags($)                                                            # Return a string containing the tags of all the nodes contained by this node separated by single spaces.
 {my ($node) = @_;                                                              # Node.
  join ' ', map {$_->tag} $node->contents
 }

sub contentBeyondAsTags($)                                                      # Return a string containing the tags of all the sibling nodes following this node separated by single spaces.
 {my ($node) = @_;                                                              # Node.
  join ' ', map {$_->tag} $node->contentBeyond
 }

sub contentBeforeAsTags($)                                                      # # Return a string containing the tags of all the sibling nodes preceding this node separated by single spaces.
 {my ($node) = @_;                                                              # Node.
  join ' ', map {$_->tag} $node->contentBefore
 }

sub position($)                                                                 # Return the index of a node in its parent's content.
 {my ($node) = @_;                                                              # Node.
  my @c = $node->parent->contents;                                              # Each node in parent content
  for(keys @c)                                                                  # Test each node
   {return $_ if $c[$_] == $node;                                               # Return index position of node which counts from zero
   }
  confess "Node not found in parent";                                           # Something wrong with parent/child relationship
 }

sub index($)                                                                    # Return the index of a node in its parent index.
 {my ($node) = @_;                                                              # Node.
  if (my @c = $node->parent->c($node->tag))                                     # Each node in parent index
   {for(keys @c)                                                                # Test each node
     {return $_ if $c[$_] == $node;                                             # Return index position of node which counts from zero
     }
   }
  confess "Node not found in parent";                                           # Something wrong with parent/child relationship
 }

sub present($@)                                                                 # Return the count of the number of the specified tag types present immediately under a node.
 {my ($node, @names) = @_;                                                      # Node, possible tags immediately under the node.
  my %i = %{$node->indexes};                                                    # Index of child nodes
  grep {$i{$_}} @names                                                          # Count of tag types present
 }

sub isText($)                                                                   #X Confirm that this is a text node.
 {my ($node) = @_;                                                              # Node to test.
$node->tag or confess;
  $node->tag eq cdata
 }

sub isBlankText($)                                                              #X Confirm that this is a text node and that it is blank.
 {my ($node) = @_;                                                              # Node to test.
  $node->isText and $node->text =~ /\A\s*\Z/s;
 }

#1 Navigation                                                                   # Move around in the parse tree

sub go($@)                                                                      #IX Return the node reached from the specified node via the specified L<path|/path>: (index positionB<?>)B<*> where index is the tag of the next node to be chosen and position is the optional zero based position within the index of those tags under the current node. Position defaults to zero if not specified. Position can also be negative to index back from the top of the index array. B<*> can be used as the last position to retrieve all nodes with the final tag.
 {my ($node, @position) = @_;                                                   # Node, search specification.
  my $p = $node;                                                                # Current node
  while(@position)                                                              # Position specification
   {my $i = shift @position;                                                    # Index name
    return undef unless $p;                                                     # There is no node of the named type under this node
    my $q = $p->indexes->{$i};                                                  # Index
    return undef unless defined $i;                                             # Complain if no such index
    if (@position)                                                              # Position within index
     {if ($position[0] =~ /\A([-+]?\d+)\Z/)                                     # Numeric position in index from start
       {shift @position;
        $p = $q->[$1]
       }
      elsif (@position == 1 and $position[0] =~ /\A\*\Z/)                       # Final index wanted
       {return @$q;
       }
      else {$p = $q->[0]}                                                       # Step into first sub node by default
     }
    else {$p = $q->[0]}                                                         # Step into first sub node by default on last step
   }
  $p
 }

sub c($$)                                                                       # Return an array of all the nodes with the specified tag below the specified node.
 {my ($node, $tag) = @_;                                                        # Node, tag.
  my $c = $node->indexes->{$tag};                                               # Index for specified tags
  $c ? @$c : ()                                                                 # Contents as an array
 }

sub first($)                                                                    #BX Return the first node below this node.
 {my ($node) = @_;                                                              # Node.
  $node->content->[0]
 }

sub firstBy($@)                                                                 # Return a list of the first instance of each specified tag encountered in a post-order traversal from the specified node or a hash of all first instances if no tags are specified.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags;                                                                     # Tags found first
  $node->byReverse(sub {$tags{$_->tag} = $_});                                  # Save first instance of each node
  return %tags unless @tags;                                                    # Return hash of all tags encountered first unless @tags filter was specified
  map {$tags{$_}} @tags;                                                        # Nodes in the requested order
 }

sub firstDown($@)                                                               # Return a list of the first instance of each specified tag encountered in a pre-order traversal from the specified node or a hash of all first instances if no tags are specified.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags;                                                                     # Tags found first
  $node->downReverse(sub {$tags{$_->tag} = $_});                                # Save first instance of each node
  return %tags unless @tags;                                                    # Return hash of all tags encountered first unless @tags filter was specified
  map {$tags{$_}} @tags;                                                        # Nodes in the requested order
 }

sub lastBy($@)                                                                  # Return a list of the last instance of each specified tag encountered in a post-order traversal from the specified node or a hash of all first instances if no tags are specified.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags;                                                                     # Tags found first
  $node->by(sub {$tags{$_->tag} = $_});                                         # Save last instance of each node
  return %tags unless @tags;                                                    # Return hash of all tags encountered last unless @tags filter was specified
  map {$tags{$_}} @tags;                                                        # Nodes in the requested order
 }

sub lastDown($@)                                                                # Return a list of the last instance of each specified tag encountered in a pre-order traversal from the specified node or a hash of all first instances if no tags are specified.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags;                                                                     # Tags found first
  $node->down(sub {$tags{$_->tag} = $_});                                       # Save last instance of each node
  return %tags unless @tags;                                                    # Return hash of all tags encountered last unless @tags filter was specified
  map {$tags{$_}} @tags;                                                        # Nodes in the requested order
 }

sub firstIn($@)                                                                 #X Return the first node matching one of the named tags under the specified node.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  for($node->contents)                                                          # Search forwards through contents
   {return $_ if $tags{$_->tag};                                                # Find first tag with the specified name
   }
  return undef                                                                  # No such node
 }

sub firstContextOf($@)                                                          #X Return the first node encountered in the specified context in a depth first post-order traversal of the parse tree.
 {my ($node, @context) = @_;                                                    # Node, array of tags specifying context.
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

sub last($)                                                                     #BX Return the last node below this node.
 {my ($node) = @_;                                                              # Node.
  $node->content->[-1]
 }

sub lastIn($@)                                                                  #X Return the first node matching one of the named tags under the specified node.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  for(reverse $node->contents)                                                  # Search backwards through contents
   {return $_ if $tags{$_->tag};                                                # Find last tag with the specified name
   }
  return undef                                                                  # No such node
 }

sub lastContextOf($@)                                                           #X Return the last node encountered in the specified context in a depth first reverse pre-order traversal of the parse tree.
 {my ($node, @context) = @_;                                                    # Node, array of tags specifying context.
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

sub next($)                                                                     #BX Return the node next to the specified node.
 {my ($node) = @_;                                                              # Node.
  return undef if $node->isLast;                                                # No node follows the last node at a level or the top most node
  my @c = $node->parent->contents;                                              # Content array of parent
  while(@c)                                                                     # Test until no more nodes left to test
   {my $c = shift @c;                                                           # Each node
    return shift @c if $c == $node                                              # Next node if this is the specified node
   }
  confess "Node not found in parent";                                           # Something wrong with parent/child relationship
 }

sub nextIn($@)                                                                  #X Return the next node matching one of the named tags.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  my $parent = $node->parent;                                                   # Parent node
  return undef unless $parent;                                                  # No nodes follow the root node
  my @c = $parent->contents;                                                    # Search forwards through contents
  shift @c while @c and $c[0] != $node;                                         # Move up to starting node
  shift @c;                                                                     # Move over starting node
  for(@c)                                                                       # Each subsequent node
   {return $_ if $tags{$_->tag};                                                # Find first tag with the specified name in the remaining nodes
   }
  return undef                                                                  # No such node
 }

sub prev($)                                                                     #BIX Return the node previous to the specified node.
 {my ($node) = @_;                                                              # Node.
  return undef if $node->isFirst;                                               # No node precedes the first node at a level or the top most node
  my @c = $node->parent->contents;                                              # Content array of parent
  while(@c)                                                                     # Test until no more nodes left to test
   {my $c = pop @c;                                                             # Each node
    return pop @c if $c == $node                                                # Previous node if this is the specified node
   }
  confess "Node not found in parent";                                           # Something wrong with parent/child relationship
 }

sub prevIn($@)                                                                  #X Return the next previous node matching one of the named tags.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  my $parent = $node->parent;                                                   # Parent node
  return undef unless $parent;                                                  # No nodes follow the root node
  my @c = reverse $parent->contents;                                            # Reverse through contents
  shift @c while @c and $c[0] != $node;                                         # Move down to starting node
  shift @c;                                                                     # Move over starting node
  for(@c)                                                                       # Each subsequent node
   {return $_ if $tags{$_->tag};                                                # Find first tag with the specified name in the remaining nodes
   }
  return undef                                                                  # No such node
 }

sub upto($@)                                                                    #X Return the first ancestral node that matches the specified context.
 {my ($node, @tags) = @_;                                                       # Start node, tags identifying context.
  for(my $p = $node; $p; $p = $p->parent)                                       # Go up
   {return $p if $p->at(@tags);                                                 # Return node which satisfies the condition
   }
  return undef                                                                  # Not found
 }

sub nextOn($@)                                                                  # Step forwards as far as possible while remaining on nodes with the specified tags and return the last such node reached or the starting node if no such steps are possible.
 {my ($node, @tags) = @_;                                                       # Start node, tags identifying nodes that can be step on to context.
  return $node if $node->isLast;                                                # Easy case
  my $parent = $node->parent;                                                   # Parent node
  confess "No parent" unless $parent;                                           # Not possible on a root node
  my @c = $parent->contents;                                                    # Content
  shift @c while @c and $c[0] != $node;                                         # Position on current node
  confess "Node not found in parent" unless @c;                                 # Something wrong with parent/child relationship
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags of acceptable commands
  shift @c while @c > 1 and $tags{$c[1]->tag};                                  # Proceed forwards but staying on acceptable tags
  return $c[0]                                                                  # Current node or last acceptable tag reached while staying on acceptable tags
 }

sub prevOn($@)                                                                  # Step backwards as far as possible while remaining on nodes with the specified tags and return the last such node reached or the starting node if no such steps are possible.
 {my ($node, @tags) = @_;                                                       # Start node, tags identifying nodes that can be step on to context.
  return $node if $node->isFirst;                                               # Easy case
  my $parent = $node->parent;                                                   # Parent node
  confess "No parent" unless $parent;                                           # Not possible on a root node
  my @c = reverse $parent->contents;                                            # Content backwards
  shift @c while @c and $c[0] != $node;                                         # Position on current node
  confess "Node not found in parent" unless @c;                                 # Something wrong with parent/child relationship
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags of acceptable commands
  shift @c while @c > 1 and $tags{$c[1]->tag};                                  # Proceed forwards but staying on acceptable tags
  return $c[0]                                                                  # Current node or last acceptable tag reached while staying on acceptable tags
 }

#1 Position                                                                     # Confirm that the position L<navigated|/Navigation> to is the expected position.

sub at($@)                                                                      #IX Confirm that the node has the specified L<ancestry|/ancestry> and return the starting node if it does else B<undef>.
 {my ($start, @context) = @_;                                                   # Starting node, ancestry.
  for(my $x = shift @_; $x; $x = $x->parent)                                    # Up through parents
   {return $start unless @_;                                                    # OK if no more required context
    next if shift @_ eq $x->tag;                                                # Carry on if contexts match
    return undef                                                                # Error if required does not match actual
   }
  !@_ ? $start : undef                                                          # Top of the tree is OK as long as there is no more required context
 }

sub ancestry($)                                                                 # Return a list containing: (the specified node, its parent, its parent's parent etc..)
 {my ($start) = @_;                                                             # Starting node.
  my @a;
  for(my $x = $start; $x; $x = $x->parent)                                      # Up through parents
   {push @a, $x;
   }
  @a                                                                            # Return ancestry
 }

sub context($)                                                                  # Return a string containing the tag of the starting node and the tags of all its ancestors separated by single spaces.
 {my ($start) = @_;                                                             # Starting node.
  my @a;                                                                        # Ancestors
  for(my $p = $start; $p; $p = $p->parent)
   {push @a, $p->tag;
    @a < 100 or confess "Overly deep tree!";
   }
  join ' ', @a
 }

sub isFirst($)                                                                  #X Confirm that this node is the first node under its parent.
 {my ($node) = @_;                                                              # Node.
  my $parent = $node->parent;                                                   # Parent
  return $node unless defined($parent);                                         # The top most node is always first
  $node == $parent->first ? $node : undef                                       # First under parent
 }

sub isLast($)                                                                   #X Confirm that this node is the last node under its parent.
 {my ($node) = @_;                                                              # Node.
  my $parent = $node->parent;                                                   # Parent
  return $node unless defined($parent);                                         # The top most node is always last
  $node == $parent->last ? $node : undef                                        # Last under parent
 }

sub isOnlyChild($@)                                                             #X Return the specified node if it is the only node under its parent (and ancestors) ignoring any surrounding blank text.
 {my ($node, @tags) = @_;                                                       # Node, optional tags to confirm context.
  return undef if @tags and !$node->at(@tags);                                  # Confirm context if supplied
  my $parent = $node->parent;                                                   # Find parent
  return undef unless $parent;                                                  # Not an only child unless there is no parent
  my @c = $parent->contents;                                                    # Contents of parent
  return $node if @c == 1;                                                      # Only child if only one child
  shift @c while @c and $c[ 0]->isBlankText;                                    # Ignore leading blank text
  pop   @c while @c and $c[-1]->isBlankText;                                    # Ignore trailing blank text
  return $node if @c == 1;                                                      # Only child if only one child after leading and trailing blank text has been ignored
  undef                                                                         # Not the only child
 }

sub isEmpty($)                                                                  #X Confirm that this node is empty, that is: this node has no content, not even a blank string of text.
 {my ($node) = @_;                                                              # Node.
  !$node->first ? $node : undef                                                 # If it has no first descendant it must be empty
 }

sub over($$)                                                                    #X Confirm that the string representing the tags at the level below this node match a regular expression.
 {my ($node, $re) = @_;                                                         # Node, regular expression.
  $node->contentAsTags =~ m/$re/ ? $node : undef
 }

sub matchAfter($$)                                                              #X Confirm that the string representing the tags following this node matches a regular expression.
 {my ($node, $re) = @_;                                                         # Node, regular expression.
  $node->contentBeyondAsTags =~ m/$re/ ? $node : undef
 }

sub matchBefore($$)                                                             #X Confirm that the string representing the tags preceding this node matches a regular expression
 {my ($node, $re) = @_;                                                         # Node, regular expression
  $node->contentBeforeAsTags =~ m/$re/ ? $node : undef
 }

sub path($)                                                                     # Return a list representing the path to a node which can then be reused by L<get|/get> to retrieve the node as long as the structure of the parse tree has not changed along the path.
 {my ($node) = @_;                                                              # Node.
  my $p = $node;                                                                # Current node
  my @p;                                                                        # Path
  for(my $p = $node; $p and $p->parent; $p = $p->parent)                        # Go up
   {my $i = $p->index;                                                          # Position in parent index
    push @p, $i if $i;                                                          # Save position unless default
    push @p, $p->tag;                                                           # Save index
   }
  reverse @p                                                                    # Return path from root
 }

sub byPosition($)                                                               # Return the position of this node in a post-order traversal of the parse tree.
 {my ($node) = @_;                                                              # Node.
  my $n = 0;                                                                    # Position
  eval {$node->parser->by(sub {die 'Found' if $_ == $node; ++$n;})};            # Find the node
  return $n if $@ =~ m/\AFound/s;                                               # Found
  confess $@ if $@;                                                             # Something went wrong
  confess 'Unable to find node in parse tree';                                  # Parse tree structure problem
 }

sub byReversePosition($)                                                        # Return the position of this node in a reverse post-order traversal of the parse tree.
 {my ($node) = @_;                                                              # Node.
  my $n = 0;                                                                    # Position
  eval {$node->parser->byReverse(sub {die 'Found' if $_ == $node; ++$n;})};     # Find the node
  return $n if $@ =~ m/\AFound/s;                                               # Found
  confess $@ if $@;                                                             # Something went wrong
  confess 'Unable to find node in parse tree';                                  # Parse tree structure problem
 }

sub downPosition($)                                                             # Return the position of this node in a pre-order traversal of the parse tree.
 {my ($node) = @_;                                                              # Node.
  my $n = 0;                                                                    # Position
  eval {$node->parser->down(sub {die 'Found' if $_ == $node; ++$n;})};          # Find the node
  return $n if $@ =~ m/\AFound/s;                                               # Found
  confess $@ if $@;                                                             # Something went wrong
  confess 'Unable to find node in parse tree';                                  # Parse tree structure problem
 }

sub downReversePosition($)                                                      # Return the position of this node in a reverse pre-order traversal of the parse tree.
 {my ($node) = @_;                                                              # Node.
  my $n = 0;                                                                    # Position
  eval {$node->parser->downReverse(sub {die 'Found' if $_ == $node; ++$n;})};   # Find the node
  return $n if $@ =~ m/\AFound/s;                                               # Found
  confess 'Unable to find node in parse tree';                                  # Parse tree structure problem
 }

#1 Order                                                                        # Number and verify the order of nodes.

my $numbers;                                                                    # Numbers for nodes

sub numberNode($)                                                               # Ensure that this node has a number.
 {my ($node) = @_;                                                              # Node
  return $node if $_->number or $_->isText;                                     # Only number non text nodes that are not already numbered
  my $n = $node->number = ++$numbers;                                           # Number node
  $node->parser->numbers->[$n] = $node                                          # Index the nodes in a parse tree
 }

sub findByNumber($$)                                                            #X Find the node with the specified number as set by L<numberTree|/numberTree> and made visible by L<prettyStringNumbered|/prettyStringNumbered> in the parse tree containing the specified node and return the found node or B<undef> if no such node exists.
 {my ($node, $number) = @_;                                                     # Node in the parse tree to search, number of the node required.
  $node->parser->numbers->[$number]
 }

sub findByNumbers($@)                                                           # Find the nodes with the specified numbers as set by L<numberTree|/numberTree> and made visible by L<prettyStringNumbered|/prettyStringNumbered> in the parse tree containing the specified node and return the found nodes in a list with B<undef> for nodes that do not exist.
 {my ($node, @numbers) = @_;                                                    # Node in the parse tree to search, numbers of the nodes required.
  map {$node->findByNumber($_)} @numbers                                        # Node corresponding to each number
 }

sub numberTree($)                                                               # Ensure that this node and any nodes below it are L<numbered|/numberNode>
 {my ($node) = @_;                                                              # Node.
  $node->down(sub {$_->numberNode});                                            # Number any nodes that are not already numbered
  $node
 }

sub above($$)                                                                   #X Return the specified node if it is above the specified target otherwise B<undef>
 {my ($node, $target) = @_;                                                     # Node, target.
  return undef if $node == $target;                                             # A node cannot be above itself
  my @n = $node  ->ancestry;
  my @t = $target->ancestry;
  pop @n, pop @t while @n and @t and $n[-1] == $t[-1];                          # Find first different ancestor
  !@n ? $node : undef                                                           # Node is above target if its ancestors are all ancestors of target
 }

sub below($$)                                                                   #X Return the specified node if it is below the specified target otherwise B<undef>
 {my ($node, $target) = @_;                                                     # Node, target.
  $target->above($node);                                                        # The target must be above the node if the node is below the target
 }

sub after($$)                                                                   #X Return the specified node if it occurs after the target node in the parse tree or else B<undef> if the node is L<above|/above>, L<below|/below> or L<before|/before> the target.
 {my ($node, $target) = @_;                                                     # Node, targe.t
  my @n = $node  ->ancestry;
  my @t = $target->ancestry;
  pop @n, pop @t while @n and @t and $n[-1] == $t[-1];                          # Find first different ancestor
  return undef unless @n and @t;                                                # Undef if we cannot decide
  $n[-1]->position > $t[-1]->position                                           # Node relative to target at first common ancestor
 }

sub before($$)                                                                  #X Return the specified node if it occurs before the target node in the parse tree or else B<undef> if the node is L<above|/above>, L<below|/below> or L<after|/after> the target.
 {my ($node, $target) = @_;                                                     # Node, target.
  my @n = $node  ->ancestry;
  my @t = $target->ancestry;
  pop @n, pop @t while @n and @t and $n[-1] == $t[-1];                          # Find first different ancestor
  return undef unless @n and @t;                                                # Undef if we cannot decide
  $n[-1]->position < $t[-1]->position                                           # Node relative to target at first common ancestor
 }

sub disordered($@)                                                              # Return the first node that is out of the specified order when performing a pre-ordered traversal of the parse tree.
 {my ($node, @nodes) = @_;                                                      # Node, following nodes.
  my $c = $node;                                                                # Node we are currently checking for
  $node->parser->down(sub {$c = shift @nodes while $c and $_ == $c});           # Preorder traversal from root looking for each specified node
  $c                                                                            # Disordered if we could not find this node
 }

sub ordered($@)                                                                 #X Return the first node if the specified nodes are all in order when performing a pre-ordered traversal of the parse tree else return B<undef>
 {my ($node, @nodes) = @_;                                                      # Node, following nodes.
  &disordered(@_) ? undef : $node
 }

#1 Editing                                                                      # Edit the data in the parse tree and change the structure of the parse tree by L<wrapping and unwrapping|/Wrap and unwrap> nodes, by L<replacing|/Replace> nodes, by L<cutting and pasting|/Cut and Put> nodes, by L<concatenating|/Fusion> nodes, by L<splitting|/Fission> nodes or by adding node as  L<text|/Put as text>

sub change($$@)                                                                 #IX Change the name of a node, optionally  confirming that the node is in a specified context and return the node.
 {my ($node, $name, @tags) = @_;                                                # Node, new name, optional: tags defining the required context.
  return undef if @tags and !$node->at(@tags);
  $node->tag = $name;                                                           # Change name
  if (my $parent = $node->parent) {$parent->indexNode}                          # Reindex parent
  $node
 }

#2 Wrap and unwrap                                                              # Wrap and unwrap nodes to alter the depth of the parse tree

sub wrapWith($$@)                                                               #I Wrap the original node in a new node  forcing the original node down deepening the parse tree; return the new wrapping node.
 {my ($old, $tag, %attributes) = @_;                                            # Node, tag for the L<new node|/newTag>, attributes for the L<new node|/newTag>.
  my $new = newTag(undef, $tag, %attributes);                                   # Create wrapping node
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

sub wrapUp($@)                                                                  # Wrap the original node in a sequence of new nodes forcing the original node down deepening the parse tree; return the array of wrapping nodes.
 {my ($node, @tags) = @_;                                                       # Node to wrap, tags to wrap the node with - with the uppermost tag rightmost.
  map {$node = $node->wrapWith($_)} @tags;                                      # Wrap up
 }

sub wrapDown($@)                                                                # Wrap the content of the specified node in a sequence of new nodes forcing the original node up deepening the parse tree; return the array of wrapping nodes.
 {my ($node, @tags) = @_;                                                       # Node to wrap, tags to wrap the node with - with the uppermost tag rightmost.
  map {$node = $node->wrapContentWith($_)} @tags;                               # Wrap up
 }

sub wrapContentWith($$@)                                                        # Wrap the content of a node in a new node, the original content then contains the new node which contains the original node's content; returns the new wrapped node.
 {my ($old, $tag, %attributes) = @_;                                            # Node, tag for new node, attributes for new node.
  my $new = newTag(undef, $tag, %attributes);                                   # Create wrapping node
  $new->parser  = $old->parser;                                                 # Assign the new node to the old parser
  $new->content = $old->content;                                                # Transfer content
  $old->content = [$new];                                                       # Insert new node
  $new->indexNode;                                                              # Create indices for new node
  $old->indexNode;                                                              # Rebuild indices for old mode
  $new                                                                          # Return new node
 }

sub wrapTo($$$@)                                                                #X Wrap all the nodes starting and ending at the specified nodes with a new node with the specified tag and attributes and return the new node.  Return B<undef> if the start and end nodes are not siblings - they must have the same parent.
 {my ($start, $end, $tag, %attributes) = @_;                                    # Start node, end node, tag for the wrapping node, attributes for the wrapping node
  my $parent = $start->parent;                                                  # Parent
  confess "Start node has no parent" unless $parent;                            # Not possible unless the start node has a parent
  confess "End node has a different parent" unless $parent = $end->parent;      # Not possible unless the start and end nodes have the same parent
  my $s = $start->position;                                                     # Start position
  my $e = $end->position;                                                       # End position
  confess "End node precedes start node" if $e < $s;                            # End must not precede start node
  $start->putPrev(my $new = $start->newTag($tag, %attributes));                 # Create and insert wrapping node
  my @c = $parent->contents;                                                    # Content of parent
  $new->putLast($c[$_]->cut) for $s+1..$e+1;                                    # Move the nodes from start to end into the new node remembering that the new node has already been inserted
  $new                                                                          # Return new node
 }

sub unwrap($)                                                                   #I Unwrap a node by inserting its content into its parent at the point containing the node; returns the parent node.
 {my ($node) = @_;                                                              # Node to unwrap.
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
    $node->disconnectLeafNode;                                                  # Disconnect node from parse tree
   }
  $parent                                                                       # Return the parent node
 }

#2 Replace                                                                      # Replace nodes in the parse tree with nodes or text

sub replaceWith($$)                                                             # Replace a node (and all its content) with a L<new node|/newTag> (and all its content) and return the new node.
 {my ($old, $new) = @_;                                                         # Old node, new node.
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

sub replaceWithText($$)                                                         # Replace a node (and all its content) with a new text node and return the new node.
 {my ($old, $text) = @_;                                                        # Old node, text of new node.
  my $n = $old->replaceWith($old->newText($text));                              # Create a new text node, replace the old node and return the result
  $n
 }

sub replaceWithBlank($)                                                         # Replace a node (and all its content) with a new blank text node and return the new node.
 {my ($old) = @_;                                                               # Old node, text of new node.
  my $n = $old->replaceWithText(' ');                                           # Create a new text node, replace the old node with a new blank text node and return the result
  $n
 }

#2 Cut and Put                                                                  # Move nodes around in the parse tree by cutting and pasting them

sub cut($)                                                                      #I Cut out a node so that it can be reinserted else where in the parse tree.
 {my ($node) = @_;                                                              # Node to cut out.
  my $parent = $node->parent;                                                   # Parent node
  # confess "Already cut out" unless $parent;                                   # We have to let thing be cut out more than once or supply an isCutOut() method
  return $node unless $parent;                                                  # Uppermost node is already cut out
  my $c = $parent->content;                                                     # Content array of parent
  my $i = $node->position;                                                      # Position in content array
  splice(@$c, $i, 1);                                                           # Remove node
  $parent->indexNode;                                                           # Rebuild indices
  $node->disconnectLeafNode;                                                    # Disconnect node no longer in parse tree
  $node                                                                         # Return node
 }

sub putFirst($$)                                                                # Place a L<cut out or new node|/cut> at the front of the content of the specified node and return the new node.
 {my ($old, $new) = @_;                                                         # Original node, new node.
  $new->parent and confess "Please cut out the node before moving it";          # The node must have be cut out first
  $new->parser == $new and $old->parser == $new and                             # Prevent a root node from being inserted into a sub tree
    confess "Recursive insertion attempted";
  $new->parser = $old->parser;                                                  # Assign the new node to the old parser
  unshift @{$old->content}, $new;                                               # Content array of original node
  $old->indexNode;                                                              # Rebuild indices for node
  $new                                                                          # Return the new node
 }

sub putLast($$)                                                                 #I Place a L<cut out or new node|/cut> last in the content of the specified node and return the new node.
 {my ($old, $new) = @_;                                                         # Original node, new node.
  $new->parent and confess "Please cut out the node before moving it";          # The node must have be cut out first
  $new->parser == $new and $old->parser == $new and                             # Prevent a root node from being inserted into a sub tree
    confess "Recursive insertion attempted";
  $new->parser = $old->parser;                                                  # Assign the new node to the old parser
  push @{$old->content}, $new;                                                  # Content array of original node
  $old->indexNode;                                                              # Rebuild indices for node
  $new                                                                          # Return the new node
 }

sub putNext($$)                                                                 # Place a L<cut out or new node|/cut> just after the specified node and return the new node.
 {my ($old, $new) = @_;                                                         # Original node, new node.
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

sub putPrev($$)                                                                 # Place a L<cut out or new node|/cut> just before the specified node and return the new node.
 {my ($old, $new) = @_;                                                         # Original node, new node.
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

#2 Fusion                                                                       # Join consecutive nodes

sub concatenate($$)                                                             # Concatenate two successive nodes and return the target node.
 {my ($target, $source) = @_;                                                   # Target node to replace, node to concatenate.
  $source->parser or confess "Cannot concatenate the root node";                # Complain if we try and concatenate the root
  if ($source = $target->next)
   {$target->content = [$target->contents, $source->contents];                  # Concatenate (target, source) to target
   }
  elsif ($source = $target->prev)
   {$target->content = [$source->contents, $target->contents];                  # Concatenate (source, target) to target
   }
  else
   {confess "Cannot concatenate non consecutive nodes";                         # Complain if the nodes are not adjacent
   }
  $source->content = [];                                                        # Concatenate
  $target->indexNode;                                                           # Index target node
  $source->indexNode;                                                           # Index source node
  $source->cut;
  $target                                                                       # Return new node
 }

sub concatenateSiblings($)                                                      # Concatenate preceding and following nodes as long as they have the same tag as the specified node and return the specified node.
 {my ($node) = @_;                                                              # Concatenate around this node.
  my $t = $node->tag;                                                           # The tag to match
  while(my $p = $node->prev)
   {last unless $p->tag eq $t;                                                  # Stop when the siblings no longer match
    $node->concatenate($p)
   }
  while(my $n = $node->next)
   {last unless $n->tag eq $t;                                                  # Stop when the siblings no longer match
    $node->concatenate($n) if $n->tag eq $t
   }
  $node                                                                         # Return concatenating node
 }

#2 Fission                                                                      # Split the content of a node by moving nodes to preceding or following nodes to a preceding or following node.

sub splitBack($$)                                                               # Move the specified node and all its preceding nodes to a newly created node preceding this node's parent and return the new node (mm July 31, 2017).
 {my ($old, $new) = @_;                                                         # Move this node and its preceding nodes, the name of the new node.
  my $o = $old;                                                                 # Shorten name
  my $p = $o->parent;                                                           # Parent node
  $p or confess "Cannot move nodes immediately under the root node";            # Complain if we try to move a child of the root node
  my $n = $o->newTag(qq($new));                                                 # New node
  my $i = $o->position;                                                         # Position of old node under its parent
  my @p = $p->contents;                                                         # Existing contents
  my @n  = splice(@p, 0, $i+1);                                                 # New contents
  $n->content = [@n]; $n->indexNode;                                            # Index new node
  $p->content = [@p]; $p->indexNode;                                            # index parent node
  $p->putPrev($n);                                                              # Put the new node before the old node
  $n                                                                            # Return new node
 }

sub splitBackEx($$)                                                             # Move all the nodes preceding a specified node to a newly created node preceding this node's parent and return the new node.
 {my ($old, $new) = @_;                                                         # Move all the nodes preceding this node, the name of the new node.
  my $o = $old;                                                                 # Shorten name
  my $p = $o->parent;                                                           # Parent node
  $p or confess "Cannot move nodes immediately under the root node";            # Complain if we try to move a child of the root node
  my $n = $o->newTag(qq($new));                                                 # New node
  my $i = $o->position;                                                         # Position of old node under its parent
  my @p = $p->contents;                                                         # Existing contents
  my @n  = splice(@p, 0, $i);                                                   # New contents
  $n->content = [@n]; $n->indexNode;                                            # Index new node
  $p->content = [@p]; $p->indexNode;                                            # index parent node
  $p->putPrev($n);                                                              # Put the new node before the old node
  $n                                                                            # Return new node
 }

sub splitForwards($$)                                                           # Move the specified node and all its following nodes to a newly created node following this node's parent and return the new node.
 {my ($old, $new) = @_;                                                         # Move this node and its following nodes, the name of the new node.
  my $o = $old;                                                                 # Shorten name
  my $p = $o->parent;                                                           # Parent node
  $p or confess "Cannot move nodes immediately under the root node";            # Complain if we try to move a child of the root node
  my $n = $o->newTag(qq($new));                                                 # New node
  my $i = $o->position;                                                         # Position of old node under its parent
  my @p = $p->contents;                                                         # Existing contents
  my @n  = splice(@p, $i);                                                      # New contents
  $n->content = [@n]; $n->indexNode;                                            # Index new node
  $p->content = [@p]; $p->indexNode;                                            # index parent node
  $p->putNext($n);                                                              # Put the new node before the old node
  $n                                                                            # Return new node
 }

sub splitForwardsEx($$)                                                         # Move all the nodes following a node to a newly created node following this node's parent and return the new node.
 {my ($old, $new) = @_;                                                         # Move the nodes following this node, the name of the new node.
  my $o = $old;                                                                 # Shorten name
  my $p = $o->parent;                                                           # Parent node
  $p or confess "Cannot move nodes immediately under the root node";            # Complain if we try to move a child of the root node
  my $n = $o->newTag(qq($new));                                                 # New node
  my $i = $o->position;                                                         # Position of old node under its parent
  my @p = $p->contents;                                                         # Existing contents
  my @n  = splice(@p, $i+1);                                                    # New contents
  $n->content = [@n]; $n->indexNode;                                            # Index new node
  $p->content = [@p]; $p->indexNode;                                            # index parent node
  $p->putNext($n);                                                              # Put the new node before the old node
  $n                                                                            # Return new node
 }

#2 Put as text                                                                  # Add text to the parse tree.

sub putFirstAsText($$)                                                          # Add a new text node first under a parent and return the new text node.
 {my ($node, $text) = @_;                                                       # The parent node, the string to be added which might contain unparsed Xml as well as text.
  $node->putFirst(my $t = $node->newText($text));                               # Add new text node
  $t                                                                            # Return new node
 }

sub putLastAsText($$)                                                           # Add a new text node last under a parent and return the new text node.
 {my ($node, $text) = @_;                                                       # The parent node, the string to be added which might contain unparsed Xml as well as text.
  $node->putLast(my $t = $node->newText($text));                                # Add new text node
  $t                                                                            # Return new node
 }

sub putNextAsText($$)                                                           # Add a new text node following this node and return the new text node.
 {my ($node, $text) = @_;                                                       # The parent node, the string to be added which might contain unparsed Xml as well as text.
  $node->putNext(my $t = $node->newText($text));                                # Add new text node
  $t                                                                            # Return new node
 }

sub putPrevAsText($$)                                                           # Add a new text node following this node and return the new text node
 {my ($node, $text) = @_;                                                       # The parent node, the string to be added which might contain unparsed Xml as well as text
  $node->putPrev(my $t = $node->newText($text));                                # Add new text node
  $t                                                                            # Return new node
 }

#2 Break in and out                                                             # Break nodes out of nodes or push them back

sub breakInForwards($)                                                          # Concatenate the nodes following the start node, unwrapping nodes whose tag matches the start node and return the start node. Example:p->breakInForwards:transforms:\m  p  bp  cp\n   xx  yy  zz\mto:\m  p\n   xxbyyczzz\mwhere the start node is the first B<p>
 {my ($start) = @_;                                                             # The start node.
  my $tag     = $start->tag;                                                    # The start node tag
  for my $item($start->contentBeyond)                                           # Each item following the start node
   {$start->putLast($item->cut);                                                # Concatenate item
    if ($item->tag eq $tag)                                                     # Unwrap items with the same tag as the start node
     {$item->unwrap;                                                            # Start a new clone of the parent
     }
   }
  $start                                                                        # Return the start node
 }

sub breakInBackwards($)                                                         # Concatenate the nodes preceding the start node, unwrapping nodes whose tag matches the start node and return the start node. Example:p->breakInBackwards:transforms:\m  p  bp  cp\n   xx  yy  zz\mto:\m  p\n   xxbyyczzz\mwhere the start node is the last B<p>
 {my ($start) = @_;                                                             # The start node.
  my $tag     = $start->tag;                                                    # The start node tag
  for my $item(reverse $start->contentBefore)                                   # Each item preceding the start node reversing from the start node
   {$start->putFirst($item->cut);                                               # Concatenate item
    if ($item->tag eq $tag)                                                     # Unwrap items with the same tag as the start node
     {$item->unwrap;                                                            # Start a new clone of the parent
     }
   }
  $start                                                                        # Return the start node
 }

sub breakIn($)                                                                  # Concatenate the nodes following and preceding the start node, unwrapping nodes whose tag matches the start node and return the start node. Example:p->breakIn:transforms:\m  p  bp  cp\n   xx  yy  zz\mto:\m  p\n   xxbyyczzz\mwhere the start node is any of the B<p>
 {my ($start) = @_;                                                             # The start node.
  $start->breakInBackwards;                                                     # The nodes before the start node
  $start->breakInForwards                                                       # The nodes following the start node
 }

sub breakOut($@)                                                                # Lift child nodes with the specified tags under the specified parent node splitting the parent node into clones and return the cut out original node. Example:p->breakOut(qw(b c)):transforms:\m  p\n   aabaacaa\mto:\m  p  bp  cp\n   aa  aa  aa
 {my ($parent, @tags) = @_;                                                     # The parent node, the tags of the modes to be broken out.
  my %tags       = map {$_=>1} @tags;                                           # Tags to break out
  my %attributes = %{$parent->attributes};                                      # Attributes of parent
  my $parentTag  = $parent->tag;                                                # The tag of the parent
  my $p;                                                                        # Clone of parent currently being built
  for my $item($parent->contents)                                               # Each item
   {if ($tags{$item->tag})                                                      # Item to break out
     {$parent->putPrev($item->cut);                                             # Position item broken out
      $p = undef;                                                               # Start a new clone of the parent
     }
    else                                                                        # Item to remain in situ
     {if (!defined($p))                                                         # Create a new parent clone
       {$parent->putPrev($p = $parent->newTag($parent->tag, %attributes));      # Position new parent clone
       }
      $p->putLast($item->cut);                                                  # Move current item into parent clone
     }
   }
  $parent->cut                                                                  # Remove the original copy of the parent from which the clones were made
 }

#1 Labels                                                                       # Label nodes so that they can be cross referenced and linked by L<Data::Edit::Xml::Lint>

sub addLabels($@)                                                               # Add the named labels to the specified node and return that node.
 {my ($node, @labels) = @_;                                                     # Node in parse tree, names of labels to add.
  my $l = $node->labels;
  $l->{$_}++ for @labels;
  $node
 }

sub countLabels($)                                                              # Return the count of the number of labels at a node.
 {my ($node) = @_;                                                              # Node in parse tree.
  my $l = $node->labels;                                                        # Labels at node
  scalar keys %$l                                                               # Count of labels
 }

sub getLabels($)                                                                # Return the names of all the labels set on a node.
 {my ($node) = @_;                                                              # Node in parse tree.
  sort keys %{$node->labels}
 }

sub deleteLabels($@)                                                            # Delete the specified labels in the specified node and return that node.
 {my ($node, @labels) = @_;                                                     # Node in parse tree, names of the labels to be deleted
  my $l = $node->labels;
  delete $l->{$_} for @labels;
  $node
 }

sub deleteAllLabels($)                                                          # Delete all the labels in the specified node and return that node.
 {my ($node) = @_;                                                              # Node in parse tree.
  $node->{labels} = {};                                                         # Delete all the labels
  $node
 }

sub copyLabels($$)                                                              # Copy all the labels from the source node to the target node and return the source node.
 {my ($source, $target) = @_;                                                   # Source node, target node.
  $target->addLabels($source->getLabels);                                       # Copy all the labels from the source to the target
  $source
 }

sub moveLabels($$)                                                              # Move all the labels from the source node to the target node and return the source node.
 {my ($source, $target) = @_;                                                   # Source node, target node.
  $target->addLabels($source->getLabels);                                       # Copy all the labels from the source to the target
  $source->deleteAllLabels;                                                     # Delete all the labels from the source
  $source
 }

#1 Operators                                                                    # Operator access to methods use the assign versions to avoid 'useless use of operator in void context' messages. Use the non assign versions to return the results of the underlying method call.  Thus '/' returns the wrapping node, whilst '/=' does not.

use overload
  '='        => sub{$_[0]},
  '-X'       => \&opString,
  '@{}'      => \&opContents,
  '>>='      => \&opOut,
  '<='       => \&opContext,
  '+'        => \&opPutFirst,
  '-'        => \&opPutLast,
  '>'        => \&opPutNext,
  '<'        => \&opPutPrev,
  'x='       => \&opBy,
  'x'        => \&opBy,
  '>>'       => \&opGet,
  '*'        => \&opWrapContentWith,
  '*='       => \&opWrapContentWith,
  '/'        => \&opWrapWith,
  '/='       => \&opWrapWith,
  '%'        => \&opAttr,
  '+='       => \&opSetTag,
  '-='       => \&opSetId,
  '--'       => \&opCut,
  '++'       => \&opUnWrap,
  "fallback" => 1;

sub opString($$)                                                                # -c : L<clone|/clone>, -e: L<prettyStringEnd|/prettyStringEnd>, -o: L<stringQuoted|/stringQuoted>, -p : L<prettyString|/prettyString>, -r : L<renew|/renew>, -s : L<string|/string>, -t : L<tag|/tag>, -z : L<prettyStringNumbered|/prettyStringNumbered>. Example: -p $x:to print node $x as a pretty string.
 {my ($node, $op) = @_;                                                         # Node, monadic operator.
  $op or confess;
  return $node->clone                if $op eq 'c';
  return $node->prettyStringEnd      if $op eq 'e';
  return $node->stringQuoted         if $op eq 'o';
  return $node->prettyString         if $op eq 'p';
  return $node->renew                if $op eq 'r';
  return $node->string               if $op eq 's';
  return $node->tag                  if $op eq 't';
  return $node->prettyStringNumbered if $op eq 'z';
  confess "Unknown operator: $op";
 }

sub opContents($)                                                               # @{} : content of a node. Example: grep {...} @$x:to search the contents of node $x
 {my ($node) = @_;                                                              # Node.
  $node->content
 }

sub opOut($$)                                                                   # >>= : Write a parse tree out on a file. Example: $x >>= *STDERR
 {my ($node, $file) = @_;                                                       # Node, file.
  say $file $node->prettyString;
  $node
 }

sub opContext($$)                                                               # <= : Check that a node is in the context specified by the referenced array of words. Example: $c <= [qw(c b a)]:to confirm that node $c has tag 'c',  parent 'b' and grand parent 'a'.
 {my ($node, $context) = @_;                                                    # Node, reference to array of words specifying the parents of the desired node.
  ref($context) =~ m/array/is or
    confess "Array of words required to specify the context";
  $node->at(@$context);
 }

sub opPutFirst($$)                                                              # + or += : put a node or string first under a node. Example: my $f = $a + '<p>first</p>'
 {my ($node, $text) = @_;                                                       # Node, node or text to place first under the node.
  return $node->putFirst($text) if ref($text) eq __PACKAGE__;
  $node->putFirstAsText($text);
 }

sub opPutLast($$)                                                               # - : put a node or string last under a node.  Example: my $l = $a + '<p>last</p>'
 {my ($node, $text) = @_;                                                       # Node, node or text to place last under the node.
  return $node->putLast($text) if ref($text) eq __PACKAGE__;
  $node->putFirstAsText($text);
 }

sub opPutNext($$)                                                               # > : put a node or string after the current node. Example: my $n = $a > '<p>next</p>'
 {my ($node, $text) = @_;                                                       # Node, node or text to place after the first node.
  return $node->putNext($text) if ref($text) eq __PACKAGE__;
  $node->putNextAsText($text);
 }

sub opPutPrev($$)                                                               # < : put a node or string before the current node, Example: my $p = $a < '<p>next</p>'
 {my ($node, $text) = @_;                                                       # Node, node or text to place before the first node.
  return $node->putPrev($text) if ref($text) eq __PACKAGE__;
  $node->putPrevAsText($text);
 }

sub opBy($$)                                                                    # x x= : Traverse a parse tree in post-order. Example: $a x= sub {say -s $_}:to print all the parse trees in a parse tree.
 {my ($node, $code) = @_;                                                       # Parse tree, code to execute against each node.
  ref($code) =~ m/code/is or
    confess "sub reference required on right hand side";
  $node->by($code);
 }

sub opGet($$)                                                                   # >> : Search for a node via a specification provided as a reference to an array of words each number.  Each word represents a tag name, each number the index of the previous tag or zero by default. Example: my $f = $a >> [qw(aa 1 bb)]:to find the first bb under the second aa under $a
 {my ($node, $get) = @_;                                                        # Node, reference to an array of search parameters.
  ref($get) =~ m/array/is or
    confess "Array of words and numbers required  on right hand side".
            " to specify the search";
  $node->go(@$get)
 }

sub opAttr($$)                                                                  # % : Get the value of an attribute of this node. Example: my $a = $x % 'href':to get the href attribute of the node at $x
 {my ($node, $attr) = @_;                                                       # Node, reference to an array of words and numbers specifying the node to search for.
  $node->attr($attr)
 }

sub opSetTag($$)                                                                # += : Set the tag for a node. Example: $a += 'tag':to change the tag to 'tag' at the node $a
 {my ($node, $tag) = @_;                                                        # Node, tag.
  $node->change($tag)
 }

sub opSetId($$)                                                                 # -= : Set the id for a node. Example:  $a -= 'id':to change the id to 'id' at node $a
 {my ($node, $id) = @_;                                                         # Node, id.
  $node->setAttr(id=>$id);
 }

sub opWrapWith($$)                                                              # / or /= : Wrap node with a tag, returning or not returning the wrapping node. Example: $x /= 'aa':to wrap node $x with a node with a tag of 'aa'.
 {my ($node, $tag) = @_;                                                        # Node, tag.
  $node->wrapWith($tag)
 }

sub opWrapContentWith($$)                                                       # * or *= : Wrap content with a tag, returning or not returning the wrapping node. Example:  $x *= 'aa':to wrap the content of node $x with a node with a tag of 'aa'.
 {my ($node, $tag) = @_;                                                        # Node, tag.
  $node->wrapContentWith($tag)
 }

sub opCut($)                                                                    # -- : Cut out a node. Example:  --$x:to cut out the node $x
 {my ($node) = @_;                                                              # Node.
  $node->cut
 }

sub opUnWrap($)                                                                 # ++ : Unwrap a node.  Example:   ++$x:to unwrap the node $x
 {my ($node) = @_;                                                              # Node.
  $node->unwrap
 }

#1 Statistics                                                                   # Statistics describing the parse tree.

sub count($@)                                                                   # Return the count of the number of instances of the specified tags under the specified node, either by tag in array context or in total in scalar context.
 {my ($node, @names) = @_;                                                      # Node, possible tags immediately under the node.
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

sub countTags($)                                                                # Count the number of tags in a parse tree.
 {my ($node) = @_;                                                              # Parse tree.
  my $n = 0;
  $node->by(sub {++$n});                                                        # Count tags including CDATA
  $n                                                                            # Number of tags encountered
 }

sub countTagNames($;$)                                                          # Return a hash showing the number of instances of each tag on and below the specified node.
 {my ($node, $count) = @_;                                                      # Node, count of tags so far.
  $count //= {};                                                                # Counts
  $$count{$node->tag}++;                                                        # Add current tag
  $_->countTagNames($count) for $node->contents;                                # Each contained node
  $count                                                                        # Count
 }

sub countAttrNames($;$)                                                         # Return a hash showing the number of instances of each attribute on and below the specified node.
 {my ($node, $count) = @_;                                                      # Node, count of attributes so far.
  $count //= {};                                                                # Counts
  $$count{$_}++ for $node->getAttrs;                                            # Attributes from current tga
  $_->countAttrNames($count) for $node->contents;                               # Each contained node
  $count                                                                        # Count
 }

#1 Debug                                                                        # Debugging methods

sub printAttributes($)                                                          # Print the attributes of a node.
 {my ($node) = @_;                                                              # Node whose attributes are to be printed.
  my $a = $node->attributes;                                                    # Attributes
  defined($$a{$_}) ? undef : delete $$a{$_} for keys %$a;                       # Remove undefined attributes
  return '' unless keys %$a;                                                    # No attributes
  my $s = ' '; $s .= $_.'="'.$a->{$_}.'" ' for sort keys %$a; chop($s);         # Attributes enclosed in "" in alphabetical order
  $s
 }

sub printAttributesReplacingIdsWithLabels($)                                    # Print the attributes of a node replacing the id with the labels.
 {my ($node) = @_;                                                              # Node whose attributes are to be printed.
  my %a = %{$node->attributes};                                                 # Clone attributes
  my %l = %{$node->labels};                                                     # Clone labels
  delete $a{id};                                                                # Remove id
  $a{id} = join ', ', sort keys %l if keys %l;                                  # Replace id with labels in cloned attributes
  defined($a{$_}) ? undef : delete $a{$_} for keys %a;                          # Remove undefined attributes
  return '' unless keys %a;                                                     # No attributes
  my $s = ' '; $s .= $_.'="'.$a{$_}.'" ' for sort keys %a; chop($s);            # Attributes enclosed in "" in alphabetical order
  $s
 }

sub checkParentage($)                                                           #P Check the parent pointers are correct in a parse tree.
 {my ($x) = @_;                                                                 # Parse tree.
  $x->by(sub
   {my ($o) = @_;
   for($o->contents)
     {my $p = $_->parent;
      $p == $o or confess "No parent: ". $_->tag;
      $p and $p == $o or confess "Wrong parent: ".$o->tag. ", ". $_->tag;
     }
   });
 }

sub checkParser($)                                                              #P Check that every node has a parser.
 {my ($x) = @_;                                                                 # Parse tree.
  $x->by(sub
   {$_->parser or confess "No parser for ". $_->tag;
    $_->parser == $x or confess "Wrong parser for ". $_->tag;
   })
 }

sub nn($)                                                                       #P Replace new lines in a string with N to make testing easier.
 {my ($s) = @_;                                                                 # String.
  $s =~ s/\n/N/gsr
 }

# Tests and documentation

sub extractDocumentationFlags($$)                                               # Generate documentation for a method with a user flag.
 {my ($flags, $method) = @_;                                                    # Flags, method name.
  my $b = "${method}NonBlank";                                                  # Not blank method name
  my $x = "${method}NonBlankX";                                                 # Not blank, die on undef method name
  my $m = $method;                                                              # Second action method
     $m =~ s/\Afirst/next/gs;
     $m =~ s/\Alast/prev/gs;
  my @doc; my @code;
  if ($flags =~ m/B/s)
   {push @doc, <<END;
Use B<$b> to skip a (rare) initial blank text CDATA. Use B<$x> to die rather
then receive a returned B<undef> or false result.
END
    push @code, <<END;
sub $b
 {my \$r = &$method(\@_);
  return \$r unless \$r and \$r->isBlankText;
  shift \@_;
  &$m(\$r, \@_)
 }

sub $x
 {my \$r = &$b(\@_);
  die '$method' unless defined(\$r);
  \$r
 }
END
   }

  return [join("\n", @doc), join("\n", @code), [$b, $x]]
 }

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Data::Edit::Xml - Edit data held in xml format

=head1 Synopsis

Create a L<new|/new> xml parse tree:

  my $a = Data::Edit::Xml::new("<a><b><c/></b><d><c/></d></a>");

L<Print|/Stringification> the parse tree:

  say STDERR -p $a;

to get:

  <a>
    <b>
      <c/>
    </b>
    <d>
      <c/>
    </d>
  </a>


L<Cut|/cut> out B<c> under B<b> but not under B<d> in the created tree
by L<traversing|/Traversal> in post-order L<applying|/by> a B<sub> to each node
to L<cut|/cut> out B<c> when we are L<at|/at> B<c> under B<b> under B<a>.

In B<object oriented> style:

  $a->by(sub {$_->cut if $_->at(qw(c b a))});

In B<chained exit> style:

  $a->byX(sub {$_->at(qw(c b a))->cut});

In B<operator> style:

  $a x= sub {--$_ if $_ <= [qw(c b a)]};

L<Print|/Stringification> the transformed parse tree

 say STDERR -p $a;

to get:

  <a>
    <b/>
    <d>
      <c/>
    </d>
  </a>

=head2 DocBook to Dita

To transform some DocBook xml into Dita:

  use Data::Edit::Xml;

  # Parse the DocBook xml

  my $a = Data::Edit::Xml::new(<<END);
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

  # Transform to Dita step 1

  $a->by(sub
   {my ($o, $p) = @_;
    if ($o->at(qw(pre p li sli)) and $o->isOnlyChild)
     {$o->change($p->isFirst ? qw(cmd) : qw(stepresult));
      $p->unwrap;
     }
    elsif ($o->at(qw(li sli))    and $o->over(qr(\Ap( p)+\Z)))
     {$_->change($_->isFirst ? qw(cmd) : qw(info)) for $o->contents;
     }
   });

  # Transform to Dita step 2

  $a->by(sub
  {my ($o) = @_;
   $o->change(qw(step))          if $o->at(qw(li sli));
   $o->change(qw(steps))         if $o->at(qw(sli));
   $o->id = 's'.($o->position+1) if $o->at(qw(step));
   $o->id = 'i'.($o->index+1)    if $o->at(qw(info));
   $o->wrapWith(qw(screen))      if $o->at(qw(CDATA stepresult));
  });

  # Print the results

  say STDERR -p $a;

Produces:

  <steps>
    <step id="s1">
      <cmd>Diagnose the problem
      </cmd>
      <info id="i1">This can be quite difficult
      </info>
      <info id="i2">Sometimes impossible
      </info>
    </step>
    <step id="s2">
      <cmd>ls -la
      </cmd>
      <stepresult>
        <screen>
  drwxr-xr-x  2 phil phil   4096 Jun 15  2016 Desktop
  drwxr-xr-x  2 phil phil   4096 Nov  9 20:26 Downloads
        </screen>
      </stepresult>
    </step>
  </steps>

=head1 Description

=head2 Immediately useful methods

These methods are the ones most likely to be of immediate useful to anyone
using this package for the first time:


L<at|/at>

Confirm that the node has the specified L<ancestry|/ancestry> and return the starting node if it does else B<undef>.

L<attr :lvalue|/attr :lvalue>

Return the value of an attribute of the current node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

L<by|/by>

Post-order traversal of a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

L<change|/change>

Change the name of a node, optionally  confirming that the node is in a specified context and return the node.

L<cut|/cut>

Cut out a node so that it can be reinserted else where in the parse tree.

L<get|/get>

Return the node reached from the specified node via the specified L<path|/path>: (index positionB<?>)B<*> where index is the tag of the next node to be chosen and position is the optional zero based position within the index of those tags under the current node. Position defaults to zero if not specified. Position can also be negative to index back from the top of the index array. B<*> can be used as the last position to retrieve all nodes with the final tag.

L<new|/new>

New parse - call this method statically as in Data::Edit::Xml::new(file or string) B<or> with no parameters and then use L</input>, L</inputFile>, L</inputString>, L</errorFile>  to provide specific parameters for the parse, then call L</parse> to perform the parse and return the parse tree.

L<prettyString|/prettyString>

Return a readable string representing a node of a parse tree and all the nodes below it. Or use L<-p|/opString> $node

L<prev|/prev>

Return the node previous to the specified node.

L<putLast|/putLast>

Place a L<cut out or new node|/cut> last in the content of the specified node and return the new node.

L<unwrap|/unwrap>

Unwrap a node by inserting its content into its parent at the point containing the node; returns the parent node.

L<wrapWith|/wrapWith>

Wrap the original node in a new node  forcing the original node down deepening the parse tree; return the new wrapping node.




=head2 Construction

Create a parse tree, either by parsing a L<file or string|/file or string>, or, L<node by node|/Node by Node>

=head3 File or String

Construct a parse tree from a file or a string

=head4 new($)

New parse - call this method statically as in Data::Edit::Xml::new(file or string) B<or> with no parameters and then use L</input>, L</inputFile>, L</inputString>, L</errorFile>  to provide specific parameters for the parse, then call L</parse> to perform the parse and return the parse tree.

  1  $fileNameOrString  File name or string

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a><b><c/></b><d><e/></d></a>
  END

  ok -p $x eq <<END;
  <a>
    <b>
      <c/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END


This is a static method and so should be invoked as:

  Data::Edit::Xml::new


=head4 content :lvalue

Content of command: the nodes immediately below this node in the order in which they appeared in the source text, see also L</Contents>.


=head4 numbers :lvalue

Nodes by number.


=head4 attributes :lvalue

The attributes of this node, see also: L</Attributes>.  The frequently used attributes: class, id, href, outputclass can be accessed by an lvalue method as in: $node->id = 'c1'.


=head4 conditions :lvalue

Conditional strings attached to a node, see L</Conditions>.


=head4 indexes :lvalue

Indexes to sub commands by tag in the order in which they appeared in the source text.


=head4 labels :lvalue

The labels attached to a node to provide addressability from other nodes, see: L</Labels>.


=head4 errorsFile :lvalue

Error listing file. Use this parameter to explicitly set the name of the file that will be used to write an parse errors to. By default this file is named: B<zzzParseErrors/out.data>.


=head4 inputFile :lvalue

Source file of the parse if this is the parser root node. Use this parameter to explicitly set the file to be parsed.


=head4 input :lvalue

Source of the parse if this is the parser root node. Use this parameter to specify some input either as a string or as a file name for the parser to convert into a parse tree.


=head4 inputString :lvalue

Source string of the parse if this is the parser root node. Use this parameter to explicitly set the string to be parsed.


=head4 number :lvalue

Number of this node, see L<findByNumber|/findByNumber> and L<numberTree|/numberTree>.


=head4 parent :lvalue

Parent node of this node or undef if the oarser root node. See also L</Traversal> and L</Navigation>. Consider as read only.


=head4 parser :lvalue

Parser details: the root node of a tree is the parse node for that tree. Consider as read only.


=head4 tag :lvalue

Tag name for this node, see also L</Traversal> and L</Navigation>. Consider as read only.


=head4 text :lvalue

Text of this node but only if it is a text node, i.e. the tag is cdata() <=> L</isText> is true.


=head4 cdata()

The name of the tag to be used to represent text - this tag must not also be used as a command tag otherwise the parser will L<confess|http://perldoc.perl.org/Carp.html#SYNOPSIS/>.


=head4 parse($)

Parse input xml specified via: L<inputFile|/inputFile>, L<input|/input> or L<inputString|/inputString>.

  1  $parser  Parser created by L</new>

Example:


  my $x = Data::Edit::Xml::new;

  $x->inputString = <<END;
  <a id="aa"><b id="bb"><c id="cc"/></b></a>
  END

  $x->parse;


=head3 Node by Node

Construct a parse tree node by node.

=head4 newText($$)

Create a new text node.

  1  undef  Any reference to this package
  2  $text  Content of new text node

Example:


  ok -p $x eq <<END;
  <a class="aa" id="1">
    <b class="bb" id="2"/>
  </a>
  END

  $x->putLast($x->newText("t"));

  ok -p $x eq <<END;
  <a class="aa" id="1">
    <b class="bb" id="2"/>
  t
  </a>
  END


=head4 newTag($$%)

Create a new non text node.

  1  undef        Any reference to this package
  2  $command     The tag for the node
  3  %attributes  Attributes as a hash.

Example:


  my $x = Data::Edit::Xml::newTree("a", id=>1, class=>"aa");

  $x->putLast($x->newTag("b", id=>2, class=>"bb"));

  ok -p $x eq <<END;
  <a class="aa" id="1">
    <b class="bb" id="2"/>
  </a>
  END


=head4 newTree($%)

Create a new tree.

  1  $command     The name of the root node in the tree
  2  %attributes  Attributes of the root node in the tree as a hash.

Example:


  my $x = Data::Edit::Xml::newTree("a", id=>1, class=>"aa");

  ok -s $x eq '<a class="aa" id="1"/>';


=head4 replaceSpecialChars($)

Replace < > " with &lt; &gt; &quot;  Larry Wall's excellent L<Xml parser|https://metacpan.org/pod/XML::Parser/> unfortunately replaces &lt; &gt; &quot; &amp; etc. with their expansions in text by default and does not seem to provide an obvious way to stop this behavior, so we have to put them back gain using this method. Worse, we cannot decide whether to replace & with &amp; or leave it as is: consequently you might have to examine the instances of & in your output text and guess based on the context.

  1  $string  String to be edited.

=head4 renew($)

Returns a renewed copy of the parse tree: use this method if you have added nodes via the L</"Put as text"> methods and wish to reprocess them.

  1  $node  Parse tree.

Example:


  ok -s $a eq '<a id="1"><b id="4"/><b id="6"/><b id="2"><d id="7"/><c id="3"/></b><b id="5"/></a>';

  my $x = $a->renew;

  ok -s $x eq '<a id="1"><b id="4"/><b id="6"/><b id="2"><d id="7"/><c id="3"/></b><b id="5"/></a>';


=head4 clone($)

Return a clone of the parse tree: use this method if you want to make changes to an exact copy of the parse tree.

  1  $node  Parse tree.

Example:


  my $s = '<a><b><c id="1"/><c id="2"/><d/><c id="3"/><c id="4"/></b></a>';

  ok -s $A eq $s;

  my $a = $A->clone;

  ok -s $a eq $s;


=head4 equals($$)

Return the first node if the two parse trees are equal, else B<undef> if they are not equal.

  1  $node1  Parse tree 1
  2  $node2  Parse tree 2.

Example:


  my $s = '<a><b><c id="1"/><c id="2"/><d/><c id="3"/><c id="4"/></b></a>';

  ok -s $A eq $s;

  my $a = $A->clone;

  ok $a->equals($A);


Use B<equalsX> to execute L<equals|/equals> but B<die> 'equals' instead of returning B<undef>

=head4 save($$)

Save a copy of the parse tree to a file which can be L<restored|/restore> and return the saved node.

  1  $node  Parse tree
  2  $file  File.

=head4 restore($)

Return a parse tree from a copy saved in a file by L</save>.

  1  $file  File

Use B<restoreX> to execute L<restore|/restore> but B<die> 'restore' instead of returning B<undef>

This is a static method and so should be invoked as:

  Data::Edit::Xml::restore


=head2 Stringification

L<Create|/Print> a string representation of the parse tree with optional selection of nodes via L<conditions|/Conditions>.

=head3 Print

Print the parse tree. Normally use L<prettyString|/prettyString> string to format the xml in a readable yet reparseable manner; use L<string|/string> string to format the xml densely in a reparseable manner; use the other methods to produce unreparseable strings conveniently formatted to assist various specialized operations such as debugging CDATA, using labels or creating tests. A number of the L<file test operators|/opString> can also be conveniently used to print parse trees in these formats.

=head4 string($)

Return a dense string representing a node of a parse tree and all the nodes below it. Or use L<-s|/opString> $node

  1  $node  Start node.

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a><b><c/></b><d><e/></d></a>
  END

  ok -p $x eq <<END;
  <a>
    <b>
      <c/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END


=head4 stringQuoted($)

Return a quoted string representing a parse tree a node of a parse tree and all the nodes below it. Or use L<-o|/opString> $node

  1  $node  Start node

=head4 stringReplacingIdWithLabels($)

Return a string representing the specified parse tree with the id attribute of each node set to the L<Labels|/Labels> attached to each node.

  1  $node  Start node.

=head4 stringReplacingIdWithLabelsQuoted($)

Return a quoted string representing a node of a parse tree and all the nodes below it with all the id attributes replaced with the labels attached to each node.

  1  $node  Start node.

=head4 contentString($)

Return a string representing all the nodes below a node of a parse tree.

  1  $node  Start node.

=head4 prettyString($$)

Return a readable string representing a node of a parse tree and all the nodes below it. Or use L<-p|/opString> $node

  1  $node   Start node
  2  $depth  Optional depth.

Example:


  my $s = <<END;
  <a>
    <b>
      <A/>
      <B/>
    </b>
    <c>
      <C/>
      <D/>
    </c>
  </a>
  END

  my $a = Data::Edit::Xml::new($s);

  ok $s eq $a->prettyString;

  ok $s eq -p $a;


=head4 prettyStringNumbered($$)

Return a readable string representing a node of a parse tree and all the nodes below it with a L<number|/number> attached to each tag. The node numbers can then be used as described in L<Order|/Order> to monitor changes to the parse tree.

  1  $node   Start node
  2  $depth  Optional depth.

=head4 prettyStringShowingCDATA($$)

Return a readable string representing a node of a parse tree and all the nodes below it with the text fields wrapped with <CDATA>...</CDATA>.

  1  $node   Start node
  2  $depth  Optional depth.

Example:


  my $a = Data::Edit::Xml::new("<a>1<A/>2<B/>3<C/>4<D/>5<E/>6<F/>7<G/>8<H/>9</a>");

  map {$_->replaceWithBlank} grep {$_->isText}               $a->contents;

  map {$_->cut}              grep {$_->tag =~ m/\A[BDFH]\Z/} $a->contents;

  ok $a->prettyStringShowingCDATA eq <<'END';
  <a><CDATA> </CDATA>
      <A/>
  <CDATA>  </CDATA>
      <C/>
  <CDATA>  </CDATA>
      <E/>
  <CDATA>  </CDATA>
      <G/>
  <CDATA>  </CDATA>
  </a>
  END


=head4 prettyStringEnd($)

Return a readable string representing a node of a parse tree and all the nodes below it as a here document

  1  $node  Start node

=head4 PrettyContentString($)

Return a readable string representing all the nodes below a node of a parse tree - infrequent use and so capitalized to avoid being presented as an option by L<Geany|http://www.geany.org/>.

  1  $node  Start node.

=head3 Conditions

Print a subset of the the parse tree determined by the conditions attached to it.

=head4 stringWithConditions($@)

Return a string representing a node of a parse tree and all the nodes below it subject to conditions to select or reject some nodes.

  1  $node        Start node
  2  @conditions  Conditions to be regarded as in effect.

=head4 addConditions($@)

Add conditions to a node and return the node.

  1  $node        Node
  2  @conditions  Conditions to add.

=head4 deleteConditions($@)

Delete conditions applied to a node and return the node.

  1  $node        Node
  2  @conditions  Conditions to add.

=head4 listConditions($)

Return a list of conditions applied to a node.

  1  $node  Node.

=head2 Attributes

Get or set the attributes of nodes in the parse tree. Well known attributes can be set directly via L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>s for less well known attributes use L<attr|/attr>.

=head3 class :lvalue

Attribute B<class> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 href :lvalue

Attribute B<href> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 id :lvalue

Attribute B<id> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 outputclass :lvalue

Attribute B<outputclass> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 attr :lvalue($$)

Return the value of an attribute of the current node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

  1  $node       Node in parse tree
  2  $attribute  Attribute name.

=head3 attrs($@)

Return the values of the specified attributes of the current node.

  1  $node        Node in parse tree
  2  @attributes  Attribute names.

=head3 attrCount($)

Return the number of attributes in the specified node.

  1  $node  Node in parse tree

Example:


  my $x = Data::Edit::Xml::newTree("a", id=>1, class=>"aa");

  ok $x->attrCount == 2;


=head3 getAttrs($)

Return a sorted list of all the attributes on this node.

  1  $node  Node in parse tree.

=head3 setAttr($@)

Set the value of an attribute in a node and return the node.

  1  $node    Node in parse tree
  2  %values  (attribute name=>new value)*

=head3 deleteAttr($$$)

Delete the attribute, optionally checking its value first and return the node.

  1  $node   Node
  2  $attr   Attribute name
  3  $value  Optional attribute value to check first.

=head3 deleteAttrs($@)

Delete any attributes mentioned in a list without checking their values and return the node.

  1  $node   Node
  2  @attrs  Attribute name

=head3 renameAttr($$$)

Change the name of an attribute regardless of whether the new attribute already exists and return the node.

  1  $node  Node
  2  $old   Existing attribute name
  3  $new   New attribute name.

=head3 changeAttr($$$)

Change the name of an attribute unless it has already been set and return the node.

  1  $node  Node
  2  $old   Existing attribute name
  3  $new   New attribute name.

=head3 renameAttrValue($$$$$)

Change the name and value of an attribute regardless of whether the new attribute already exists and return the node.

  1  $node      Node
  2  $old       Existing attribute name
  3  $oldValue  Existing attribute value
  4  $new       New attribute name
  5  $newValue  New attribute value.

=head3 changeAttrValue($$$$$)

Change the name and value of an attribute unless it has already been set and return the node.

  1  $node      Node
  2  $old       Existing attribute name
  3  $oldValue  Existing attribute value
  4  $new       New attribute name
  5  $newValue  New attribute value.

=head2 Traversal

Traverse the parse tree in various orders applying a B<sub> to each node.

=head3 by($$@)

Post-order traversal of a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

  1  $node     Starting node
  2  $sub      Sub to call for each sub node
  3  @context  Accumulated context.

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a><b><c/></b><d><e/></d></a>
  END

  my $s; $x->by(sub{$s .= $_->tag}); ok $s eq "cbeda"


=head3 byX($$@)

Post-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

  1  $node     Starting node
  2  $sub      Sub to call
  3  @context  Accumulated context.

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a><b><c/></b><d><e/></d></a>
  END

  my $s; $x->by(sub{$s .= $_->tag}); ok $s eq "cbeda"


=head3 byReverse($$@)

Reverse post-order traversal of a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

  1  $node     Starting node
  2  $sub      Sub to call for each sub node
  3  @context  Accumulated context.

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a><b><c/></b><d><e/></d></a>
  END

  my $s; $x->byReverse(sub{$s .= $_->tag}); ok $s eq "edcba"


=head3 byReverseX($$@)

Reverse post-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

  1  $node     Starting node
  2  $sub      Sub to call for each sub node
  3  @context  Accumulated context.

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a><b><c/></b><d><e/></d></a>
  END

  my $s; $x->byReverse(sub{$s .= $_->tag}); ok $s eq "edcba"


=head3 down($$@)

Pre-order traversal down through a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

  1  $node     Starting node
  2  $sub      Sub to call for each sub node
  3  @context  Accumulated context.

Example:


  my $s; $x->down(sub{$s .= $_->tag}); ok $s eq "abcde"


=head3 downX($$@)

Pre-order traversal down through a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

  1  $node     Starting node
  2  $sub      Sub to call for each sub node
  3  @context  Accumulated context.

Example:


  my $s; $x->down(sub{$s .= $_->tag}); ok $s eq "abcde"


=head3 downReverse($$@)

Reverse pre-order traversal down through a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

  1  $node     Starting node
  2  $sub      Sub to call for each sub node
  3  @context  Accumulated context.

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a><b><c/></b><d><e/></d></a>
  END

  my $s; $x->downReverse(sub{$s .= $_->tag}); ok $s eq "adebc"


=head3 downReverseX($$@)

Reverse pre-order traversal down through a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

  1  $node     Starting node
  2  $sub      Sub to call for each sub node
  3  @context  Accumulated context.

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a><b><c/></b><d><e/></d></a>
  END

  my $s; $x->downReverse(sub{$s .= $_->tag}); ok $s eq "adebc"


=head3 through($$$@)

Traverse parse tree visiting each node twice calling the specified B<sub> at each node and returning the specified starting node. The B<sub>s are passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

  1  $node     Starting node
  2  $before   Sub to call when we meet a node
  3  $after    Sub to call we leave a node
  4  @context  Accumulated context.

Example:


  my $s; my $n = sub{$s .= $_->tag}; $x->through($n, $n);

  ok $s eq "abccbdeeda"


=head3 throughX($$$@)

Traverse parse tree visiting each node twice calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

  1  $node     Starting node
  2  $before   Sub to call when we meet a node
  3  $after    Sub to call we leave a node
  4  @context  Accumulated context.

Example:


  my $s; my $n = sub{$s .= $_->tag}; $x->through($n, $n);

  ok $s eq "abccbdeeda"


=head2 Contents

The immediate content of each node, i.e. the children of a node.

=head3 contents($)

Return all the nodes contained by this node either as an array or as a reference to such an array.

  1  $node  Node.

=head3 contentBeyond($)

Return all the sibling nodes following this node at the level of this node.

  1  $node  Node.

=head3 contentBefore($)

Return all the sibling nodes preceding this node at the level of this node.

  1  $node  Node.

=head3 contentAsTags($)

Return a string containing the tags of all the nodes contained by this node separated by single spaces.

  1  $node  Node.

=head3 contentBeyondAsTags($)

Return a string containing the tags of all the sibling nodes following this node separated by single spaces.

  1  $node  Node.

=head3 contentBeforeAsTags($)

# Return a string containing the tags of all the sibling nodes preceding this node separated by single spaces.

  1  $node  Node.

=head3 position($)

Return the index of a node in its parent's content.

  1  $node  Node.

=head3 index($)

Return the index of a node in its parent index.

  1  $node  Node.

=head3 present($@)

Return the count of the number of the specified tag types present immediately under a node.

  1  $node   Node
  2  @names  Possible tags immediately under the node.

=head3 isText($)

Confirm that this is a text node.

  1  $node  Node to test.

Use B<isTextX> to execute L<isText|/isText> but B<die> 'isText' instead of returning B<undef>

=head3 isBlankText($)

Confirm that this is a text node and that it is blank.

  1  $node  Node to test.

Use B<isBlankTextX> to execute L<isBlankText|/isBlankText> but B<die> 'isBlankText' instead of returning B<undef>

=head2 Navigation

Move around in the parse tree

=head3 get($@)

Return the node reached from the specified node via the specified L<path|/path>: (index positionB<?>)B<*> where index is the tag of the next node to be chosen and position is the optional zero based position within the index of those tags under the current node. Position defaults to zero if not specified. Position can also be negative to index back from the top of the index array. B<*> can be used as the last position to retrieve all nodes with the final tag.

  1  $node      Node
  2  @position  Search specification.

Example:


  ok Data::Edit::Xml::new(<<END)->go(qw(b c -1 e))->at(qw(e c b a));
  <a>
    <b>
      <c> <d/> </c>
      <c> <e/> </c>
    </b>
  </a>
  END


Use B<getX> to execute L<get|/get> but B<die> 'get' instead of returning B<undef>

=head3 c($$)

Return an array of all the nodes with the specified tag below the specified node.

  1  $node  Node
  2  $tag   Tag.

=head3 first($)

Return the first node below this node.

  1  $node  Node.

Use B<firstNonBlank> to skip a (rare) initial blank text CDATA. Use B<firstNonBlankX> to die rather
then receive a returned B<undef> or false result.



Use B<firstX> to execute L<first|/first> but B<die> 'first' instead of returning B<undef>

=head3 firstBy($@)

Return a list of the first instance of each specified tag encountered in a post-order traversal from the specified node or a hash of all first instances if no tags are specified.

  1  $node  Node
  2  @tags  Tags to search for.

=head3 firstDown($@)

Return a list of the first instance of each specified tag encountered in a pre-order traversal from the specified node or a hash of all first instances if no tags are specified.

  1  $node  Node
  2  @tags  Tags to search for.

=head3 lastBy($@)

Return a list of the last instance of each specified tag encountered in a post-order traversal from the specified node or a hash of all first instances if no tags are specified.

  1  $node  Node
  2  @tags  Tags to search for.

=head3 lastDown($@)

Return a list of the last instance of each specified tag encountered in a pre-order traversal from the specified node or a hash of all first instances if no tags are specified.

  1  $node  Node
  2  @tags  Tags to search for.

=head3 firstIn($@)

Return the first node matching one of the named tags under the specified node.

  1  $node  Node
  2  @tags  Tags to search for.

Example:


  ok $a->prettyStringShowingCDATA eq <<'END';
  <a><CDATA> </CDATA>
      <A/>
  <CDATA>  </CDATA>
      <C/>
  <CDATA>  </CDATA>
      <E/>
  <CDATA>  </CDATA>
      <G/>
  <CDATA>  </CDATA>
  </a>
  END

  ok $a->firstIn(qw(b B c C))->tag eq qq(C);


Use B<firstInX> to execute L<firstIn|/firstIn> but B<die> 'firstIn' instead of returning B<undef>

=head3 firstContextOf($@)

Return the first node encountered in the specified context in a depth first post-order traversal of the parse tree.

  1  $node     Node
  2  @context  Array of tags specifying context.

Use B<firstContextOfX> to execute L<firstContextOf|/firstContextOf> but B<die> 'firstContextOf' instead of returning B<undef>

=head3 last($)

Return the last node below this node.

  1  $node  Node.

Use B<lastNonBlank> to skip a (rare) initial blank text CDATA. Use B<lastNonBlankX> to die rather
then receive a returned B<undef> or false result.



Use B<lastX> to execute L<last|/last> but B<die> 'last' instead of returning B<undef>

=head3 lastIn($@)

Return the first node matching one of the named tags under the specified node.

  1  $node  Node
  2  @tags  Tags to search for.

Example:


  ok $a->prettyStringShowingCDATA eq <<'END';
  <a><CDATA> </CDATA>
      <A/>
  <CDATA>  </CDATA>
      <C/>
  <CDATA>  </CDATA>
      <E/>
  <CDATA>  </CDATA>
      <G/>
  <CDATA>  </CDATA>
  </a>
  END

  ok $a->lastIn(qw(e E f F))->tag eq qq(E);


Use B<lastInX> to execute L<lastIn|/lastIn> but B<die> 'lastIn' instead of returning B<undef>

=head3 lastContextOf($@)

Return the last node encountered in the specified context in a depth first reverse pre-order traversal of the parse tree.

  1  $node     Node
  2  @context  Array of tags specifying context.

Use B<lastContextOfX> to execute L<lastContextOf|/lastContextOf> but B<die> 'lastContextOf' instead of returning B<undef>

=head3 next($)

Return the node next to the specified node.

  1  $node  Node.

Use B<nextNonBlank> to skip a (rare) initial blank text CDATA. Use B<nextNonBlankX> to die rather
then receive a returned B<undef> or false result.



Use B<nextX> to execute L<next|/next> but B<die> 'next' instead of returning B<undef>

=head3 nextIn($@)

Return the next node matching one of the named tags.

  1  $node  Node
  2  @tags  Tags to search for.

Example:


  ok $a->prettyStringShowingCDATA eq <<'END';
  <a><CDATA> </CDATA>
      <A/>
  <CDATA>  </CDATA>
      <C/>
  <CDATA>  </CDATA>
      <E/>
  <CDATA>  </CDATA>
      <G/>
  <CDATA>  </CDATA>
  </a>
  END

  ok $a->firstIn(qw(b B c C))->nextIn(qw(A G))->tag eq qq(G);


Use B<nextInX> to execute L<nextIn|/nextIn> but B<die> 'nextIn' instead of returning B<undef>

=head3 prev($)

Return the node previous to the specified node.

  1  $node  Node.

Use B<prevNonBlank> to skip a (rare) initial blank text CDATA. Use B<prevNonBlankX> to die rather
then receive a returned B<undef> or false result.



Use B<prevX> to execute L<prev|/prev> but B<die> 'prev' instead of returning B<undef>

=head3 prevIn($@)

Return the next previous node matching one of the named tags.

  1  $node  Node
  2  @tags  Tags to search for.

Example:


  ok $a->prettyStringShowingCDATA eq <<'END';
  <a><CDATA> </CDATA>
      <A/>
  <CDATA>  </CDATA>
      <C/>
  <CDATA>  </CDATA>
      <E/>
  <CDATA>  </CDATA>
      <G/>
  <CDATA>  </CDATA>
  </a>
  END

  ok $a->lastIn(qw(e E f F))->prevIn(qw(A G))->tag eq qq(A);


Use B<prevInX> to execute L<prevIn|/prevIn> but B<die> 'prevIn' instead of returning B<undef>

=head3 upto($@)

Return the first ancestral node that matches the specified context.

  1  $node  Start node
  2  @tags  Tags identifying context.

Use B<uptoX> to execute L<upto|/upto> but B<die> 'upto' instead of returning B<undef>

=head3 nextOn($@)

Step forwards as far as possible while remaining on nodes with the specified tags and return the last such node reached or the starting node if no such steps are possible.

  1  $node  Start node
  2  @tags  Tags identifying nodes that can be step on to context.

=head3 prevOn($@)

Step backwards as far as possible while remaining on nodes with the specified tags and return the last such node reached or the starting node if no such steps are possible.

  1  $node  Start node
  2  @tags  Tags identifying nodes that can be step on to context.

=head2 Position

Confirm that the position L<navigated|/Navigation> to is the expected position.

=head3 at($@)

Confirm that the node has the specified L<ancestry|/ancestry> and return the starting node if it does else B<undef>.

  1  $start    Starting node
  2  @context  Ancestry.

Example:


  ok Data::Edit::Xml::new(<<END)->go(qw(b c -1 e))->at(qw(e c b a));
  <a>
    <b>
      <c> <d/> </c>
      <c> <e/> </c>
    </b>
  </a>
  END


Use B<atX> to execute L<at|/at> but B<die> 'at' instead of returning B<undef>

=head3 ancestry($)

Return a list containing: (the specified node, its parent, its parent's parent etc..)

  1  $start  Starting node.

=head3 context($)

Return a string containing the tag of the starting node and the tags of all its ancestors separated by single spaces.

  1  $start  Starting node.

Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END

  ok $x->go(qw(d e))->context eq 'e d a';


=head3 isFirst($)

Confirm that this node is the first node under its parent.

  1  $node  Node.

Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END

  ok $x->go(qw(b))->isFirst;


Use B<isFirstX> to execute L<isFirst|/isFirst> but B<die> 'isFirst' instead of returning B<undef>

=head3 isLast($)

Confirm that this node is the last node under its parent.

  1  $node  Node.

Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END

  ok $x->go(qw(d))->isLast;


Use B<isLastX> to execute L<isLast|/isLast> but B<die> 'isLast' instead of returning B<undef>

=head3 isOnlyChild($@)

Return the specified node if it is the only node under its parent (and ancestors) ignoring any surrounding blank text.

  1  $node  Node
  2  @tags  Optional tags to confirm context.

Example:


  my $x = Data::Edit::Xml::new(<<END)->first->first;
  <a id="aa"><b id="bb"><c id="cc"/></b></a>
  END

  ok $x->isOnlyChild;

  ok $x->isOnlyChild(qw(c));

  ok $x->isOnlyChild(qw(c b));

  ok $x->isOnlyChild(qw(c b a));


Use B<isOnlyChildX> to execute L<isOnlyChild|/isOnlyChild> but B<die> 'isOnlyChild' instead of returning B<undef>

=head3 isEmpty($)

Confirm that this node is empty, that is: this node has no content, not even a blank string of text.

  1  $node  Node.

Example:


  my $x = Data::Edit::Xml::new(<<END)->first->first;
  <a id="aa"><b id="bb"><c id="cc"/></b></a>
  END

  ok $x->isEmpty;


Use B<isEmptyX> to execute L<isEmpty|/isEmpty> but B<die> 'isEmpty' instead of returning B<undef>

=head3 over($$)

Confirm that the string representing the tags at the level below this node match a regular expression.

  1  $node  Node
  2  $re    Regular expression.

Use B<overX> to execute L<over|/over> but B<die> 'over' instead of returning B<undef>

=head3 matchAfter($$)

Confirm that the string representing the tags following this node matches a regular expression.

  1  $node  Node
  2  $re    Regular expression.

Use B<matchAfterX> to execute L<matchAfter|/matchAfter> but B<die> 'matchAfter' instead of returning B<undef>

=head3 matchBefore($$)

Confirm that the string representing the tags preceding this node matches a regular expression

  1  $node  Node
  2  $re    Regular expression

Use B<matchBeforeX> to execute L<matchBefore|/matchBefore> but B<die> 'matchBefore' instead of returning B<undef>

=head3 path($)

Return a list representing the path to a node which can then be reused by L<get|/get> to retrieve the node as long as the structure of the parse tree has not changed along the path.

  1  $node  Node.

=head3 byPosition($)

Return the position of this node in a post-order traversal of the parse tree.

  1  $node  Node.

=head3 byReversePosition($)

Return the position of this node in a reverse post-order traversal of the parse tree.

  1  $node  Node.

=head3 downPosition($)

Return the position of this node in a pre-order traversal of the parse tree.

  1  $node  Node.

=head3 downReversePosition($)

Return the position of this node in a reverse pre-order traversal of the parse tree.

  1  $node  Node.

=head2 Order

Number and verify the order of nodes.

=head3 numberNode($)

Ensure that this node has a number.

  1  $node  Node

=head3 findByNumber($$)

Find the node with the specified number as set by L<numberTree|/numberTree> and made visible by L<prettyStringNumbered|/prettyStringNumbered> in the parse tree containing the specified node and return the found node or B<undef> if no such node exists.

  1  $node    Node in the parse tree to search
  2  $number  Number of the node required.

Use B<findByNumberX> to execute L<findByNumber|/findByNumber> but B<die> 'findByNumber' instead of returning B<undef>

=head3 findByNumbers($@)

Find the nodes with the specified numbers as set by L<numberTree|/numberTree> and made visible by L<prettyStringNumbered|/prettyStringNumbered> in the parse tree containing the specified node and return the found nodes in a list with B<undef> for nodes that do not exist.

  1  $node     Node in the parse tree to search
  2  @numbers  Numbers of the nodes required.

=head3 numberTree($)

Ensure that this node and any nodes below it are L<numbered|/numberNode>

  1  $node  Node.

=head3 above($$)

Return the specified node if it is above the specified target otherwise B<undef>

  1  $node    Node
  2  $target  Target.

Use B<aboveX> to execute L<above|/above> but B<die> 'above' instead of returning B<undef>

=head3 below($$)

Return the specified node if it is below the specified target otherwise B<undef>

  1  $node    Node
  2  $target  Target.

Use B<belowX> to execute L<below|/below> but B<die> 'below' instead of returning B<undef>

=head3 after($$)

Return the specified node if it occurs after the target node in the parse tree or else B<undef> if the node is L<above|/above>, L<below|/below> or L<before|/before> the target.

  1  $node    Node
  2  $target  Targe.t

Use B<afterX> to execute L<after|/after> but B<die> 'after' instead of returning B<undef>

=head3 before($$)

Return the specified node if it occurs before the target node in the parse tree or else B<undef> if the node is L<above|/above>, L<below|/below> or L<after|/after> the target.

  1  $node    Node
  2  $target  Target.

Use B<beforeX> to execute L<before|/before> but B<die> 'before' instead of returning B<undef>

=head3 disordered($@)

Return the first node that is out of the specified order when performing a pre-ordered traversal of the parse tree.

  1  $node   Node
  2  @nodes  Following nodes.

=head3 ordered($@)

Return the first node if the specified nodes are all in order when performing a pre-ordered traversal of the parse tree else return B<undef>

  1  $node   Node
  2  @nodes  Following nodes.

Use B<orderedX> to execute L<ordered|/ordered> but B<die> 'ordered' instead of returning B<undef>

=head2 Editing

Edit the data in the parse tree and change the structure of the parse tree by L<wrapping and unwrapping|/Wrap and unwrap> nodes, by L<replacing|/Replace> nodes, by L<cutting and pasting|/Cut and Put> nodes, by L<concatenating|/Fusion> nodes, by L<splitting|/Fission> nodes or by adding node as  L<text|/Put as text>

=head3 change($$@)

Change the name of a node, optionally  confirming that the node is in a specified context and return the node.

  1  $node  Node
  2  $name  New name
  3  @tags  Optional: tags defining the required context.

Example:


  my $a = Data::Edit::Xml::new('<a/>');

  $a->change(qq(b));

  ok -s $a eq '<b/>';


Use B<changeX> to execute L<change|/change> but B<die> 'change' instead of returning B<undef>

=head3 Wrap and unwrap

Wrap and unwrap nodes to alter the depth of the parse tree

=head4 wrapWith($$@)

Wrap the original node in a new node  forcing the original node down deepening the parse tree; return the new wrapping node.

  1  $old         Node
  2  $tag         Tag for the L<new node|/newTag>
  3  %attributes  Attributes for the L<new node|/newTag>.

Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c id="11"/>
    </b>
  </a>
  END

  $x->go(qw(b c))->wrapWith(qw(C id 1));

  ok -p $x eq <<END;
  <a>
    <b>
      <C id="1">
        <c id="11"/>
      </C>
    </b>
  </a>
  END


=head4 wrapUp($@)

Wrap the original node in a sequence of new nodes forcing the original node down deepening the parse tree; return the array of wrapping nodes.

  1  $node  Node to wrap
  2  @tags  Tags to wrap the node with - with the uppermost tag rightmost.

Example:


  my $c = Data::Edit::Xml::newTree("c", id=>33);

  my ($b, $a) = $c->wrapUp(qw(b a));


=head4 wrapDown($@)

Wrap the content of the specified node in a sequence of new nodes forcing the original node up deepening the parse tree; return the array of wrapping nodes.

  1  $node  Node to wrap
  2  @tags  Tags to wrap the node with - with the uppermost tag rightmost.

Example:


  my $a = Data::Edit::Xml::newTree("a", id=>33);

  my ($b, $c) = $a->wrapDown(qw(b c));


=head4 wrapContentWith($$@)

Wrap the content of a node in a new node, the original content then contains the new node which contains the original node's content; returns the new wrapped node.

  1  $old         Node
  2  $tag         Tag for new node
  3  %attributes  Attributes for new node.

=head4 unwrap($)

Unwrap a node by inserting its content into its parent at the point containing the node; returns the parent node.

  1  $node  Node to unwrap.

Example:


  ok -s $x eq "<a>A<b> c </b>B</a>";

  $b->unwrap;

  ok -s $x eq "<a>A c B</a>";


=head3 Replace

Replace nodes in the parse tree with nodes or text

=head4 replaceWith($$)

Replace a node (and all its content) with a L<new node|/newTag> (and all its content) and return the new node.

  1  $old  Old node
  2  $new  New node.

=head4 replaceWithText($$)

Replace a node (and all its content) with a new text node and return the new node.

  1  $old   Old node
  2  $text  Text of new node.

=head4 replaceWithBlank($)

Replace a node (and all its content) with a new blank text node and return the new node.

  1  $old  Old node

=head3 Cut and Put

Move nodes around in the parse tree by cutting and pasting them

=head4 cut($)

Cut out a node so that it can be reinserted else where in the parse tree.

  1  $node  Node to cut out.

Example:


  ok -p $a eq <<END;
  <a id="aa">
    <b id="bb">
      <c id="cc"/>
    </b>
  </a>
  END

  my $c = $a->go(qw(b c))->cut;

  ok -p $a eq <<END;
  <a id="aa">
    <b id="bb"/>
  </a>
  END


=head4 putFirst($$)

Place a L<cut out or new node|/cut> at the front of the content of the specified node and return the new node.

  1  $old  Original node
  2  $new  New node.

Example:


  ok -p $a eq <<END;
  <a id="aa">
    <b id="bb">
      <c id="cc"/>
    </b>
  </a>
  END

  my $c = $a->go(qw(b c))->cut;

  $a->putFirst($c);

  ok -p $a eq <<END;
  <a id="aa">
    <c id="cc"/>
    <b id="bb"/>
  </a>
  END


=head4 putLast($$)

Place a L<cut out or new node|/cut> last in the content of the specified node and return the new node.

  1  $old  Original node
  2  $new  New node.

Example:


  ok -p $a eq <<END;
  <a id="aa">
    <c id="cc"/>
    <b id="bb"/>
  </a>
  END

  $a->putLast($a->go(qw(c))->cut);

  ok -p $a eq <<END;
  <a id="aa">
    <b id="bb"/>
    <c id="cc"/>
  </a>
  END


=head4 putNext($$)

Place a L<cut out or new node|/cut> just after the specified node and return the new node.

  1  $old  Original node
  2  $new  New node.

Example:


  ok -p $a eq <<END;
  <a id="aa">
    <b id="bb"/>
    <c id="cc"/>
  </a>
  END

  $a->go(qw(c))->putNext($a->go(qw(b))->cut);

  ok -p $a eq <<END;
  <a id="aa">
    <c id="cc"/>
    <b id="bb"/>
  </a>
  END


=head4 putPrev($$)

Place a L<cut out or new node|/cut> just before the specified node and return the new node.

  1  $old  Original node
  2  $new  New node.

Example:


  ok -p $a eq <<END;
  <a id="aa">
    <c id="cc"/>
    <b id="bb"/>
  </a>
  END

  $a->go(qw(c))->putPrev($a->go(qw(b))->cut);

  ok -p $a eq <<END;
  <a id="aa">
    <b id="bb"/>
    <c id="cc"/>
  </a>
  END


=head3 Fusion

Join consecutive nodes

=head4 concatenate($$)

Concatenate two successive nodes and return the target node.

  1  $target  Target node to replace
  2  $source  Node to concatenate.

Example:


  my $s = <<END;
  <a>
    <b>
      <A/>
      <B/>
    </b>
    <c>
      <C/>
      <D/>
    </c>
  </a>
  END

  my $a = Data::Edit::Xml::new($s);

  $a->go(qw(b))->concatenate($a->go(qw(c)));

  my $t = <<END;
  <a>
    <b>
      <A/>
      <B/>
      <C/>
      <D/>
    </b>
  </a>
  END

  ok $t eq -p $a;


=head4 concatenateSiblings($)

Concatenate preceding and following nodes as long as they have the same tag as the specified node and return the specified node.

  1  $node  Concatenate around this node.

Example:


  ok -p $a eq <<END;
  <a>
    <b>
      <c id="1"/>
    </b>
    <b>
      <c id="2"/>
    </b>
    <b>
      <c id="3"/>
    </b>
    <b>
      <c id="4"/>
    </b>
  </a>
  END

  $a->go(qw(b 3))->concatenateSiblings;

  ok -p $a eq <<END;
  <a>
    <b>
      <c id="1"/>
      <c id="2"/>
      <c id="3"/>
      <c id="4"/>
    </b>
  </a>
  END


=head3 Fission

Split the content of a node by moving nodes to preceding or following nodes to a preceding or following node.

=head4 splitBack($$)

Move the specified node and all its preceding nodes to a newly created node preceding this node's parent and return the new node (mm July 31, 2017).

  1  $old  Move this node and its preceding nodes
  2  $new  The name of the new node.

=head4 splitBackEx($$)

Move all the nodes preceding a specified node to a newly created node preceding this node's parent and return the new node.

  1  $old  Move all the nodes preceding this node
  2  $new  The name of the new node.

=head4 splitForwards($$)

Move the specified node and all its following nodes to a newly created node following this node's parent and return the new node.

  1  $old  Move this node and its following nodes
  2  $new  The name of the new node.

=head4 splitForwardsEx($$)

Move all the nodes following a node to a newly created node following this node's parent and return the new node.

  1  $old  Move the nodes following this node
  2  $new  The name of the new node.

=head3 Put as text

Add text to the parse tree.

=head4 putFirstAsText($$)

Add a new text node first under a parent and return the new text node.

  1  $node  The parent node
  2  $text  The string to be added which might contain unparsed Xml as well as text.

=head4 putLastAsText($$)

Add a new text node last under a parent and return the new text node.

  1  $node  The parent node
  2  $text  The string to be added which might contain unparsed Xml as well as text.

=head4 putNextAsText($$)

Add a new text node following this node and return the new text node.

  1  $node  The parent node
  2  $text  The string to be added which might contain unparsed Xml as well as text.

=head4 putPrevAsText($$)

Add a new text node following this node and return the new text node

  1  $node  The parent node
  2  $text  The string to be added which might contain unparsed Xml as well as text

=head3 Break in and out

Break nodes out of nodes or push them back

=head4 breakInForwards($)

Concatenate the nodes following the start node, unwrapping nodes whose tag matches the start node and return the start node.

  1  $start  The start node.

Example:

  p->breakInForwards

transforms:

  p  bp  cp
   xx  yy  zz

to:

  p
   xxbyyczzz

where the start node is the first B<p>

=head4 breakInBackwards($)

Concatenate the nodes preceding the start node, unwrapping nodes whose tag matches the start node and return the start node.

  1  $start  The start node.

Example:

  p->breakInBackwards

transforms:

  p  bp  cp
   xx  yy  zz

to:

  p
   xxbyyczzz

where the start node is the last B<p>

=head4 breakIn($)

Concatenate the nodes following and preceding the start node, unwrapping nodes whose tag matches the start node and return the start node.

  1  $start  The start node.

Example:

  p->breakIn

transforms:

  p  bp  cp
   xx  yy  zz

to:

  p
   xxbyyczzz

where the start node is any of the B<p>

=head4 breakOut($@)

Lift child nodes with the specified tags under the specified parent node splitting the parent node into clones and return the cut out original node.

  1  $parent  The parent node
  2  @tags    The tags of the modes to be broken out.

Example:

  p->breakOut(qw(b c))

transforms:

  p
   aabaacaa

to:

  p  bp  cp
   aa  aa  aa

=head2 Labels

Label nodes so that they can be cross referenced and linked by L<Data::Edit::Xml::Lint>

=head3 addLabels($@)

Add the named labels to the specified node and return that node.

  1  $node    Node in parse tree
  2  @labels  Names of labels to add.

=head3 countLabels($)

Return the count of the number of labels at a node.

  1  $node  Node in parse tree.

=head3 getLabels($)

Return the names of all the labels set on a node.

  1  $node  Node in parse tree.

=head3 deleteLabels($@)

Delete the specified labels in the specified node and return that node.

  1  $node    Node in parse tree
  2  @labels  Names of the labels to be deleted

=head3 deleteAllLabels($)

Delete all the labels in the specified node and return that node.

  1  $node  Node in parse tree.

=head3 copyLabels($$)

Copy all the labels from the source node to the target node and return the source node.

  1  $source  Source node
  2  $target  Target node.

=head3 moveLabels($$)

Move all the labels from the source node to the target node and return the source node.

  1  $source  Source node
  2  $target  Target node.

=head2 Operators

Operator access to methods use the assign versions to avoid 'useless use of operator in void context' messages. Use the non assign versions to return the results of the underlying method call.  Thus '/' returns the wrapping node, whilst '/=' does not.

=head3 opString($$)

-c : L<clone|/clone>, -e: L<prettyStringEnd|/prettyStringEnd>, -o: L<stringQuoted|/stringQuoted>, -p : L<prettyString|/prettyString>, -r : L<renew|/renew>, -s : L<string|/string>, -t : L<tag|/tag>, -z : L<prettyStringNumbered|/prettyStringNumbered>.

  1  $node  Node
  2  $op    Monadic operator.

Example:

   -p $x

to print node $x as a pretty string.

=head3 opContents($)

@{} : content of a node.

  1  $node  Node.

Example:

   grep {...} @$x

to search the contents of node $x

=head3 opOut($$)

>>= : Write a parse tree out on a file.

  1  $node  Node
  2  $file  File.

Example:

   $x >>= *STDERR

=head3 opContext($$)

<= : Check that a node is in the context specified by the referenced array of words.

  1  $node     Node
  2  $context  Reference to array of words specifying the parents of the desired node.

Example:

   $c <= [qw(c b a)]

to confirm that node $c has tag 'c',  parent 'b' and grand parent 'a'.

=head3 opPutFirst($$)

+ or += : put a node or string first under a node.

  1  $node  Node
  2  $text  Node or text to place first under the node.

Example:

   my $f = $a + '<p>first</p>'

=head3 opPutLast($$)

- : put a node or string last under a node.

  1  $node  Node
  2  $text  Node or text to place last under the node.

Example:

   my $l = $a + '<p>last</p>'

=head3 opPutNext($$)

> : put a node or string after the current node.

  1  $node  Node
  2  $text  Node or text to place after the first node.

Example:

   my $n = $a > '<p>next</p>'

=head3 opPutPrev($$)

< : put a node or string before the current node,

  1  $node  Node
  2  $text  Node or text to place before the first node.

Example:

   my $p = $a < '<p>next</p>'

=head3 opBy($$)

x x= : Traverse a parse tree in post-order.

  1  $node  Parse tree
  2  $code  Code to execute against each node.

Example:

   $a x= sub {say -s $_}

to print all the parse trees in a parse tree.

=head3 opGet($$)

>> : Search for a node via a specification provided as a reference to an array of words each number.  Each word represents a tag name, each number the index of the previous tag or zero by default.

  1  $node  Node
  2  $get   Reference to an array of search parameters.

Example:

   my $f = $a >> [qw(aa 1 bb)]

to find the first bb under the second aa under $a

=head3 opAttr($$)

% : Get the value of an attribute of this node.

  1  $node  Node
  2  $attr  Reference to an array of words and numbers specifying the node to search for.

Example:

   my $a = $x % 'href'

to get the href attribute of the node at $x

=head3 opSetTag($$)

+= : Set the tag for a node.

  1  $node  Node
  2  $tag   Tag.

Example:

   $a += 'tag'

to change the tag to 'tag' at the node $a

=head3 opSetId($$)

-= : Set the id for a node.

  1  $node  Node
  2  $id    Id.

Example:

    $a -= 'id'

to change the id to 'id' at node $a

=head3 opWrapWith($$)

/ or /= : Wrap node with a tag, returning or not returning the wrapping node.

  1  $node  Node
  2  $tag   Tag.

Example:

   $x /= 'aa'

to wrap node $x with a node with a tag of 'aa'.

=head3 opWrapContentWith($$)

* or *= : Wrap content with a tag, returning or not returning the wrapping node.

  1  $node  Node
  2  $tag   Tag.

Example:

    $x *= 'aa'

to wrap the content of node $x with a node with a tag of 'aa'.

=head3 opCut($)

-- : Cut out a node.

  1  $node  Node.

Example:

    --$x

to cut out the node $x

=head3 opUnWrap($)

++ : Unwrap a node.

  1  $node  Node.

Example:

     ++$x

to unwrap the node $x

=head2 Statistics

Statistics describing the parse tree.

=head3 count($@)

Return the count of the number of instances of the specified tags under the specified node, either by tag in array context or in total in scalar context.

  1  $node   Node
  2  @names  Possible tags immediately under the node.

=head3 countTags($)

Count the number of tags in a parse tree.

  1  $node  Parse tree.

=head3 countTagNames($$)

Return a hash showing the number of instances of each tag on and below the specified node.

  1  $node   Node
  2  $count  Count of tags so far.

=head3 countAttrNames($$)

Return a hash showing the number of instances of each attribute on and below the specified node.

  1  $node   Node
  2  $count  Count of attributes so far.

=head2 Debug

Debugging methods

=head3 printAttributes($)

Print the attributes of a node.

  1  $node  Node whose attributes are to be printed.

=head3 printAttributesReplacingIdsWithLabels($)

Print the attributes of a node replacing the id with the labels.

  1  $node  Node whose attributes are to be printed.


=head1 Private Methods

=head2 tree($$)

Build a tree representation of the parsed xml which can be easily traversed to look for things.

  1  $parent  The parent node
  2  $parse   The remaining parse

=head2 disconnectLeafNode($)

Remove a leaf node from the parse tree and make it into its own parse tree.

  1  $node  Leaf node to disconnect.

=head2 indexNode($)

Index the children of a node so that we can access them by tag and number.

  1  $node  Node to index.

=head2 checkParentage($)

Check the parent pointers are correct in a parse tree.

  1  $x  Parse tree.

=head2 checkParser($)

Check that every node has a parser.

  1  $x  Parse tree.

=head2 nn($)

Replace new lines in a string with N to make testing easier.

  1  $s  String.


=head1 Index


L<above|/above>

L<aboveX|/above>

L<addConditions|/addConditions>

L<addLabels|/addLabels>

L<after|/after>

L<afterX|/after>

L<ancestry|/ancestry>

L<at|/at>

L<attr :lvalue|/attr :lvalue>

L<attrCount|/attrCount>

L<attributes|/attributes>

L<attrs|/attrs>

L<atX|/at>

L<before|/before>

L<beforeX|/before>

L<below|/below>

L<belowX|/below>

L<breakIn|/breakIn>

L<breakInBackwards|/breakInBackwards>

L<breakInForwards|/breakInForwards>

L<breakOut|/breakOut>

L<by|/by>

L<byPosition|/byPosition>

L<byReverse|/byReverse>

L<byReversePosition|/byReversePosition>

L<byReverseX|/byReverseX>

L<byX|/byX>

L<c|/c>

L<cdata|/cdata>

L<change|/change>

L<changeAttr|/changeAttr>

L<changeAttrValue|/changeAttrValue>

L<changeX|/change>

L<checkParentage|/checkParentage>

L<checkParser|/checkParser>

L<class|/class>

L<clone|/clone>

L<concatenate|/concatenate>

L<concatenateSiblings|/concatenateSiblings>

L<conditions|/conditions>

L<content|/content>

L<contentAsTags|/contentAsTags>

L<contentBefore|/contentBefore>

L<contentBeforeAsTags|/contentBeforeAsTags>

L<contentBeyond|/contentBeyond>

L<contentBeyondAsTags|/contentBeyondAsTags>

L<contents|/contents>

L<contentString|/contentString>

L<context|/context>

L<copyLabels|/copyLabels>

L<count|/count>

L<countAttrNames|/countAttrNames>

L<countLabels|/countLabels>

L<countTagNames|/countTagNames>

L<countTags|/countTags>

L<cut|/cut>

L<deleteAllLabels|/deleteAllLabels>

L<deleteAttr|/deleteAttr>

L<deleteAttrs|/deleteAttrs>

L<deleteConditions|/deleteConditions>

L<deleteLabels|/deleteLabels>

L<disconnectLeafNode|/disconnectLeafNode>

L<disordered|/disordered>

L<down|/down>

L<downPosition|/downPosition>

L<downReverse|/downReverse>

L<downReversePosition|/downReversePosition>

L<downReverseX|/downReverseX>

L<downX|/downX>

L<equals|/equals>

L<equalsX|/equals>

L<errorsFile|/errorsFile>

L<findByNumber|/findByNumber>

L<findByNumbers|/findByNumbers>

L<findByNumberX|/findByNumber>

L<first|/first>

L<firstBy|/firstBy>

L<firstContextOf|/firstContextOf>

L<firstContextOfX|/firstContextOf>

L<firstDown|/firstDown>

L<firstIn|/firstIn>

L<firstInX|/firstIn>

L<firstNonBlank|/first>

L<firstNonBlankX|/first>

L<firstX|/first>

L<get|/get>

L<getAttrs|/getAttrs>

L<getLabels|/getLabels>

L<getX|/get>

L<href|/href>

L<id|/id>

L<index|/index>

L<indexes|/indexes>

L<indexNode|/indexNode>

L<input|/input>

L<inputFile|/inputFile>

L<inputString|/inputString>

L<isBlankText|/isBlankText>

L<isBlankTextX|/isBlankText>

L<isEmpty|/isEmpty>

L<isEmptyX|/isEmpty>

L<isFirst|/isFirst>

L<isFirstX|/isFirst>

L<isLast|/isLast>

L<isLastX|/isLast>

L<isOnlyChild|/isOnlyChild>

L<isOnlyChildX|/isOnlyChild>

L<isText|/isText>

L<isTextX|/isText>

L<labels|/labels>

L<last|/last>

L<lastBy|/lastBy>

L<lastContextOf|/lastContextOf>

L<lastContextOfX|/lastContextOf>

L<lastDown|/lastDown>

L<lastIn|/lastIn>

L<lastInX|/lastIn>

L<lastNonBlank|/last>

L<lastNonBlankX|/last>

L<lastX|/last>

L<listConditions|/listConditions>

L<matchAfter|/matchAfter>

L<matchAfterX|/matchAfter>

L<matchBefore|/matchBefore>

L<matchBeforeX|/matchBefore>

L<moveLabels|/moveLabels>

L<new|/new>

L<newTag|/newTag>

L<newText|/newText>

L<newTree|/newTree>

L<next|/next>

L<nextIn|/nextIn>

L<nextInX|/nextIn>

L<nextNonBlank|/next>

L<nextNonBlankX|/next>

L<nextOn|/nextOn>

L<nextX|/next>

L<nn|/nn>

L<number|/number>

L<numberNode|/numberNode>

L<numbers|/numbers>

L<numberTree|/numberTree>

L<opAttr|/opAttr>

L<opBy|/opBy>

L<opContents|/opContents>

L<opContext|/opContext>

L<opCut|/opCut>

L<opGet|/opGet>

L<opOut|/opOut>

L<opPutFirst|/opPutFirst>

L<opPutLast|/opPutLast>

L<opPutNext|/opPutNext>

L<opPutPrev|/opPutPrev>

L<opSetId|/opSetId>

L<opSetTag|/opSetTag>

L<opString|/opString>

L<opUnWrap|/opUnWrap>

L<opWrapContentWith|/opWrapContentWith>

L<opWrapWith|/opWrapWith>

L<ordered|/ordered>

L<orderedX|/ordered>

L<outputclass|/outputclass>

L<over|/over>

L<overX|/over>

L<parent|/parent>

L<parse|/parse>

L<parser|/parser>

L<path|/path>

L<position|/position>

L<present|/present>

L<PrettyContentString|/PrettyContentString>

L<prettyString|/prettyString>

L<prettyStringEnd|/prettyStringEnd>

L<prettyStringNumbered|/prettyStringNumbered>

L<prettyStringShowingCDATA|/prettyStringShowingCDATA>

L<prev|/prev>

L<prevIn|/prevIn>

L<prevInX|/prevIn>

L<prevNonBlank|/prev>

L<prevNonBlankX|/prev>

L<prevOn|/prevOn>

L<prevX|/prev>

L<printAttributes|/printAttributes>

L<printAttributesReplacingIdsWithLabels|/printAttributesReplacingIdsWithLabels>

L<putFirst|/putFirst>

L<putFirstAsText|/putFirstAsText>

L<putLast|/putLast>

L<putLastAsText|/putLastAsText>

L<putNext|/putNext>

L<putNextAsText|/putNextAsText>

L<putPrev|/putPrev>

L<putPrevAsText|/putPrevAsText>

L<renameAttr|/renameAttr>

L<renameAttrValue|/renameAttrValue>

L<renew|/renew>

L<replaceSpecialChars|/replaceSpecialChars>

L<replaceWith|/replaceWith>

L<replaceWithBlank|/replaceWithBlank>

L<replaceWithText|/replaceWithText>

L<restore|/restore>

L<restoreX|/restore>

L<save|/save>

L<setAttr|/setAttr>

L<splitBack|/splitBack>

L<splitBackEx|/splitBackEx>

L<splitForwards|/splitForwards>

L<splitForwardsEx|/splitForwardsEx>

L<string|/string>

L<stringQuoted|/stringQuoted>

L<stringReplacingIdWithLabels|/stringReplacingIdWithLabels>

L<stringReplacingIdWithLabelsQuoted|/stringReplacingIdWithLabelsQuoted>

L<stringWithConditions|/stringWithConditions>

L<tag|/tag>

L<text|/text>

L<through|/through>

L<throughX|/throughX>

L<tree|/tree>

L<unwrap|/unwrap>

L<upto|/upto>

L<uptoX|/upto>

L<wrapContentWith|/wrapContentWith>

L<wrapDown|/wrapDown>

L<wrapUp|/wrapUp>

L<wrapWith|/wrapWith>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut

sub aboveX           {&above           (@_) || die 'above'}
sub afterX           {&after           (@_) || die 'after'}
sub atX              {&at              (@_) || die 'at'}
sub beforeX          {&before          (@_) || die 'before'}
sub belowX           {&below           (@_) || die 'below'}
sub changeX          {&change          (@_) || die 'change'}
sub equalsX          {&equals          (@_) || die 'equals'}
sub findByNumberX    {&findByNumber    (@_) || die 'findByNumber'}
sub firstX           {&first           (@_) || die 'first'}
sub firstContextOfX  {&firstContextOf  (@_) || die 'firstContextOf'}
sub firstInX         {&firstIn         (@_) || die 'firstIn'}
sub getX             {&get             (@_) || die 'get'}
sub isBlankTextX     {&isBlankText     (@_) || die 'isBlankText'}
sub isEmptyX         {&isEmpty         (@_) || die 'isEmpty'}
sub isFirstX         {&isFirst         (@_) || die 'isFirst'}
sub isLastX          {&isLast          (@_) || die 'isLast'}
sub isOnlyChildX     {&isOnlyChild     (@_) || die 'isOnlyChild'}
sub isTextX          {&isText          (@_) || die 'isText'}
sub lastX            {&last            (@_) || die 'last'}
sub lastContextOfX   {&lastContextOf   (@_) || die 'lastContextOf'}
sub lastInX          {&lastIn          (@_) || die 'lastIn'}
sub matchAfterX      {&matchAfter      (@_) || die 'matchAfter'}
sub matchBeforeX     {&matchBefore     (@_) || die 'matchBefore'}
sub nextX            {&next            (@_) || die 'next'}
sub nextInX          {&nextIn          (@_) || die 'nextIn'}
sub orderedX         {&ordered         (@_) || die 'ordered'}
sub overX            {&over            (@_) || die 'over'}
sub prevX            {&prev            (@_) || die 'prev'}
sub prevInX          {&prevIn          (@_) || die 'prevIn'}
sub restoreX         {&restore         (@_) || die 'restore'}
sub uptoX            {&upto            (@_) || die 'upto'}

sub firstNonBlank
 {my $r = &first(@_);
  return $r unless $r and $r->isBlankText;
  shift @_;
  &next($r, @_)
 }

sub firstNonBlankX
 {my $r = &firstNonBlank(@_);
  die 'first' unless defined($r);
  $r
 }

sub lastNonBlank
 {my $r = &last(@_);
  return $r unless $r and $r->isBlankText;
  shift @_;
  &prev($r, @_)
 }

sub lastNonBlankX
 {my $r = &lastNonBlank(@_);
  die 'last' unless defined($r);
  $r
 }

sub nextNonBlank
 {my $r = &next(@_);
  return $r unless $r and $r->isBlankText;
  shift @_;
  &next($r, @_)
 }

sub nextNonBlankX
 {my $r = &nextNonBlank(@_);
  die 'next' unless defined($r);
  $r
 }

sub prevNonBlank
 {my $r = &prev(@_);
  return $r unless $r and $r->isBlankText;
  shift @_;
  &prev($r, @_)
 }

sub prevNonBlankX
 {my $r = &prevNonBlank(@_);
  die 'prev' unless defined($r);
  $r
 }


# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
 }

test unless caller;

1;
# podDocumentation
__DATA__
use warnings FATAL=>qw(all);
use strict;
use Test::More tests=>361;
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

sub sample2
 {my $x = Data::Edit::Xml::new;                                                 #Tparse #TinputString
     $x->inputString = <<END;                                                   #Tparse #TinputString
<a id="aa"><b id="bb"><c id="cc"/></b></a>
END
     $x->parse;                                                                 #Tparse #TinputString
 }

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
    ok nn($x->prettyString)  eq '<foo start="yes">N  <head id="a" key="aaa bbb" start="123">HelloN    N    <em>thereN    </em>N  </head>N  <bar>HowdyN    N    <ref/>N  </bar>NdoNdooN  N  <head id="A" key="AAAA BBBB" start="123">HHHHelloN    N    <b>to youN    </b>N  </head>N  <tail>N    <foot id="11"/>N    <middle id="mm"/>N    <foot id="22"/>N  </tail>N</foo>N';
    ok nn($x->contentString) eq '<head id="a" key="aaa bbb" start="123">HelloN    <em>there</em></head><bar>HowdyN    <ref/></bar>doNdooN  <head id="A" key="AAAA BBBB" start="123">HHHHelloN    <b>to you</b></head><tail><foot id="11"/><middle id="mm"/><foot id="22"/></tail>';
    ok $x->attr(qq(start))   eq "yes";
       $x->id  = 11;
    ok $x->id == 11;
       $x->deleteAttr(qq(id));
    ok !$x->id;
    ok join(' ', $x->go(qw(head))->attrs(qw(id start))) eq "a 123";
    ok nn($x->PrettyContentString) eq '<head id="a" key="aaa bbb" start="123">HelloN    N  <em>thereN  </em>N</head>N<bar>HowdyN    N  <ref/>N</bar>NdoNdooN  N<head id="A" key="AAAA BBBB" start="123">HHHHelloN    N  <b>to youN  </b>N</head>N<tail>N  <foot id="11"/>N  <middle id="mm"/>N  <foot id="22"/>N</tail>N';
    ok $x->countTags == 17;
    ok $x->go(qw(head 1))->countTags == 4;
   }
  if (1)                                                                        # Conditions
   {my $m = $x->go(qw(tail middle));
    $m->addConditions(qw(middle MIDDLE));                                       # Add
    ok join(' ', $m->listConditions) eq 'MIDDLE middle';                        # List
    $m->deleteConditions(qw(MIDDLE));                                           # Remove
    ok join('', $m->listConditions) eq 'middle';
    $_->addConditions(qw(foot)) for $x->go(qw(tail foot *));

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

  if (my $h = $x->go(qw(head))) {ok $h->id eq qw(a)} else {ok 0}               # Attributes and sub nodes

 # Contents
  is_deeply [map {$_->tag} $x->contents]                       , [qw(head   bar    CDATA   head   tail)];
  is_deeply [map {$_->tag} $x->go(qw(head))   ->contentBeyond], [qw(bar    CDATA  head    tail)];
  is_deeply [map {$_->tag} $x->go(qw(head), 1)->contentBefore], [qw(head   bar    CDATA)];

  ok $x->contentAsTags  eq join ' ', qw(head bar CDATA head tail);
  ok $x->go(qw(head),0)->contentBeyondAsTags eq join ' ', qw(     bar CDATA head tail);
  ok $x->go(qw(head),1)->contentBeforeAsTags eq join ' ', qw(head bar CDATA);

  ok $x->over(qr(\Ahead bar CDATA head tail\Z));
  ok $x->go(qw(head),0)->matchAfter (qr(\Abar CDATA head tail\Z));
  ok $x->go(qw(head),1)->matchBefore(qr(\Ahead bar CDATA\Z));

  ok $x->c(qw(head)) == 2;
  ok $x->go(qw(tail))->present(qw(foot middle aaa bbb)) == 2;                  # Presence of the specified tags
  ok $x->go(qw(tail))->present(qw(foot aaa bbb)) == 1;
  ok $x->go(qw(tail))->present(qw(     aaa bbb)) == 0;
  ok $x->go(qw(tail foot))->present(qw(aaa bbb)) == 0;
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
   {ok $x->go(qw(tail))->firstIn(qw(foot middle))->id ==    11;
    ok $x->go(qw(tail))-> lastIn(qw(feet middle))->id eq qq(mm);
   }

  ok $x->go(qw(head *)) == 2;
  ok $x->go(qw(head),1)->position == 3;

  ok $x->go(qw(tail))->first->id == 11;
  ok $x->go(qw(tail))->last ->id == 22;
  ok $x->go(qw(tail))->first->isFirst;
  ok $x->go(qw(tail))->last ->isLast;

  ok !$x->go(qw(tail))->last->isOnlyChild;

  ok $x->go(qw(tail))->first->next->id eq 'mm';
  ok $x->go(qw(tail))->last->prev->prev->isFirst;

  ok $x->go(qw(head))->go(qw(em))->first->at(qw(CDATA em head foo));          # At

  if (1)                                                                        # Through
   {my @t;
    $x->first->by(sub {my ($o) = @_; push @t, $o->tag});
    is_deeply [@t], [qw(CDATA  CDATA  em  head)];
   }

  if (1)
   {my @t;
    $x->last->by(sub {my ($o) = @_; push @t, $o->tag});
    is_deeply [@t], [qw(foot middle foot tail)];
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
  ok sample1->go(qw(tail))->go(qw(middle))->wrapWith("MIDDLE")->parent->parent->string eq trim(<<END);
<foo start="yes"><head id="a" key="aaa bbb" start="123">Hello
    <em>there</em></head><bar>Howdy
    <ref/></bar>do
doo
  <head id="A" key="AAAA BBBB" start="123">HHHHello
    <b>to you</b></head><tail><foot id="11"/><MIDDLE><middle id="mm"/></MIDDLE><foot id="22"/></tail></foo>
END

 ok sample1->go(qw(tail))->go(qw(middle))->wrapContentWith("MIDDLE")->parent->parent->parent->string eq trim(<<END);
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
    ok $a->go(qw(b))->id eq qw(bb);
    ok $a->go(qw(b c))->id  eq qw(cc);

    ok -p $a eq <<END;                                                          #TputFirst #Tcut
<a id="aa">
  <b id="bb">
    <c id="cc"/>
  </b>
</a>
END

    my $c = $a->go(qw(b c))->cut;                                              #TputFirst #Tcut

    ok -p $a eq <<END;                                                          #Tcut
<a id="aa">
  <b id="bb"/>
</a>
END
    $a->putFirst($c);                                                           #TputFirst

    ok -p $a eq <<END;                                                          #TputFirst #TputLast
<a id="aa">
  <c id="cc"/>
  <b id="bb"/>
</a>
END


    $a->putLast($a->go(qw(c))->cut);                                           #TputLast

    ok -p $a eq <<END;                                                          #TputLast #TputNext
<a id="aa">
  <b id="bb"/>
  <c id="cc"/>
</a>
END

    $a->go(qw(c))->putNext($a->go(qw(b))->cut);                               #TputNext

    ok -p $a eq <<END;                                                          #TputNext #TputPrev
<a id="aa">
  <c id="cc"/>
  <b id="bb"/>
</a>
END

    $a->go(qw(c))->putPrev($a->go(qw(b))->cut);                               #TputPrev

    ok -p $a eq <<END;                                                          #TputPrev
<a id="aa">
  <b id="bb"/>
  <c id="cc"/>
</a>
END
   }

# Editting - unwrap

  ok sample2->go(qw(b))->unwrap->string eq '<a id="aa"><c id="cc"/></a>';
  ok sample2->go(qw(b c))->putFirst(sample2)->parent->parent->parent->string eq '<a id="aa"><b id="bb"><c id="cc"><a id="aa"><b id="bb"><c id="cc"/></b></a></c></b></a>';
  ok sample2->go(qw(b c))->replaceWith(sample2)->go(qw(b c))->upto(qw(a b))->string eq '<a id="aa"><b id="bb"><c id="cc"/></b></a>';

  if (1)
   {my $x = sample2;
    $x->go(qw(b c))->unwrap;
    ok -s $x eq '<a id="aa"><b id="bb"/></a>';
    $x->go(qw(b))->unwrap;
    ok -s $x eq '<a id="aa"/>';
    eval {$x->unwrap };
    ok $@ =~ m(\ACannot unwrap the outer most node)s;
   }

  if (1)
   {my $x = sample2;
    $x->go(qw(b c))->replaceWithText(qq(<d id="dd">));
    ok -s $x eq '<a id="aa"><b id="bb"><d id="dd"></b></a>';
   }

  if (1)
   {my $x = sample2;
    $x->go(qw(b c))->replaceWithBlank;
    ok -s $x eq '<a id="aa"><b id="bb"> </b></a>';
   }

# Editting - tag /attributes

  ok  sample2->go(qw(b))->change(qw(B b a))->parent->string eq '<a id="aa"><B id="bb"><c id="cc"/></B></a>';
  ok !sample2->go(qw(b))->change(qw(B c a));
  ok  sample2->go(qw(b))->setAttr(aa=>11, bb=>22)->parent->string eq '<a id="aa"><b aa="11" bb="22" id="bb"><c id="cc"/></b></a>';
  ok  sample2->go(qw(b c))->setAttr(aa=>11, bb=>22)->parent->parent->string eq '<a id="aa"><b id="bb"><c aa="11" bb="22" id="cc"/></b></a>';
  ok  sample2->deleteAttr(qw(id))->string eq '<a><b id="bb"><c id="cc"/></b></a>';
  ok  sample2->renameAttr(qw(id ID))->string eq '<a ID="aa"><b id="bb"><c id="cc"/></b></a>';
  ok  sample2->changeAttr(qw(ID id))->id eq qq(aa);

  ok  sample2->renameAttrValue(qw(id aa ID AA))->string eq '<a ID="AA"><b id="bb"><c id="cc"/></b></a>';
  ok  sample2->changeAttrValue(qw(ID AA id aa))->id eq qq(aa);
 }

if (1)
 {my $x = Data::Edit::Xml::new(my $s = <<END);                                  #TwrapTo #Tgo
<aa>
  <a>
    <b/>
      <c id="1"/><c id="2"/><c id="3"/><c id="4"/>
    <d/>
  </a>
</aa>
END
  ok $x->go(qw(a c))   ->id == 1;                                               #Tgo
  ok $x->go(qw(a c -2))->id == 3;                                               #Tgo
  ok $x->go(qw(a c *)) == 4;                                                    #Tgo
  ok 1234 == join '', map {$_->id} $x->go(qw(a c *));                           #Tgo
  $x->go(qw(a c))->wrapTo($x->go(qw(a c -1)), qq(C), id=>1234);                 #TwrapTo
  ok -p $x eq <<END;                                                            #TwrapTo
<aa>
  <a>
    <b/>
    <C id="1234">
      <c id="1"/>
      <c id="2"/>
      <c id="3"/>
      <c id="4"/>
    </C>
    <d/>
  </a>
</aa>
END
 }

if (1)                                                                          # Blank text
 {my $f = "zzz.xml";
  writeFile($f, "<a> <b/>   <c/> <d/> </a>");
  my $x = Data::Edit::Xml::new($f);
  unlink $f;
  $x->putFirstAsText(' ');
  $x->go(qw(b))->putNextAsText(' ');
  $x->go(qw(d))->putPrevAsText(' ');
  $x->putLastAsText(' ');

  ok $x->countTags == 8;
  ok $x->contentAsTags eq "CDATA b CDATA c CDATA d CDATA";
  my $c = $x->go(qw(c));
  $c->replaceWithBlank;

  ok $x->countTags == 6;
  ok $x->contentAsTags eq "CDATA b CDATA d CDATA";
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
  ok $x->countTags == 2;
  ok -s $x eq "<a>                    </a>";
 }

if (1)                                                                          # Text
 {my $x = Data::Edit::Xml::new(<<END);                                          #Tcount #TisEmpty
<a>

</a>
END
  ok $x->count == 0;                                                            #Tcount
  ok $x->isEmpty;                                                               #TisEmpty
  ok -s $x eq "<a/>";
  $x->putFirstAsText(' ');
  ok $x->count == 1;
  $x->putFirstAsText("\n");
  ok $x->countTags == 2;

  $x->putFirstAsText('3');
  ok nn($x->string) eq "<a>3N </a>";
  ok $x->countTags == 2;
  ok !$x->isEmpty;
  $x->putFirstAsText(' ');
  ok $x->countTags == 2;
  $x->putFirstAsText(' ');
  ok $x->countTags == 2;
  $x->putFirstAsText(' 2 ');
  ok $x->countTags == 2;
  $x->putFirstAsText("\n");
  ok $x->countTags == 2;
  $x->putFirstAsText(' ');
  ok $x->countTags == 2;
  $x->putFirstAsText(' 1 ');
  ok $x->countTags == 2;
  $x->putFirstAsText(' ');
  ok $x->countTags == 2;
  $x->putFirstAsText(' ');
  ok $x->first->tag eq qq(CDATA);
  ok $x->first->isText;
  ok $x->countTags == 2;
  ok nn($x->string) eq "<a>   1  N 2   3N </a>";
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
     {$o->putNextAsText ($_) for (' N  ', ' N ', '', ' N ', ' ', ' N ');        # N will always be preceded and succeeded by spaces
      $o->putPrevAsText ($_) for (' P', '' ,   '', ' P',  ' ',   ' P')          # P will always be preceded               by spaces
     }
   });
  ok -s $x eq "<a> FF   P P  P<b> FF    LL </b> N   N  N  N   P P  P<c> FF    LL </c> N   N  N  N    LL </a>";
 }

if (1)                                                                          # Create
 {my $x = sample2;
  my $c = $x->go(qw(b c));
  my $d = $c->newTag(qw(d));
  $d->id = qw(dd);
  $c->putFirst($d);
  ok -s $x eq '<a id="aa"><b id="bb"><c id="cc"><d id="dd"/></c></b></a>';
 }

if (1)                                                                          # Under
 {my $x = sample2;
  my $c = $x->go(qw(b c));
  ok $c->id eq qw(cc);

  for([qw(c cc)], [qw(b bb)], [qw(a aa)])
   {my ($tag, $id) = @$_;
    my $p = $c->upto($tag);
    ok $p->id eq $id;
   }

  my $p = $c->upto(qw(d));
  ok !$p;
 }

if (1)
 {my $x = Data::Edit::Xml::new(<<END);                                          #tdown #tdownX #TdownReverse #TdownReverseX #Tby #TbyX #TbyReverse #TbyReverseX #Tnew #Tstring
<a><b><c/></b><d><e/></d></a>
END

  ok -p $x eq <<END;                                                            #Tstring #Tnew #Tcontext #TisFirst #TisLast
<a>
  <b>
    <c/>
  </b>
  <d>
    <e/>
  </d>
</a>
END

  ok $x->go(qw(d e))->context eq 'e d a';                                      #Tcontext
  ok $x->go(qw(b))->isFirst;                                                   #TisFirst
  ok $x->go(qw(d))->isLast;                                                    #TisLast

  if (1)
   {my $s; $x->down(sub{$s .= $_->tag}); ok $s eq "abcde"                       #Tdown #TdownX
   }
  if (1)
   {my $s; $x->downReverse(sub{$s .= $_->tag}); ok $s eq "adebc"                #TdownReverse #TdownReverseX
   }
  if (1)
   {my $s; $x->by(sub{$s .= $_->tag}); ok $s eq "cbeda"                         #Tby #TbyX
   }
  if (1)
   {my $s; $x->byReverse(sub{$s .= $_->tag}); ok $s eq "edcba"                  #TbyReverse #TbyReverseX
   }

  if (1)
   {my $s; my $n = sub{$s .= $_->tag}; $x->through($n, $n);                     #Tthrough #TthroughX
    ok $s eq "abccbdeeda"                                                       #Tthrough #TthroughX
   }
 }

if (1)                                                                          # NextOn
 {my $a = Data::Edit::Xml::new("<a><b><c id='1'/><d id='2'/><c id='3'/><d id='4'/><e id='5'/></b></a>");
  my $c = $a->firstContextOf(qw(c));
  my $e = $a->lastContextOf(qw(e));
  ok $c->id == 1;
  ok $e->id == 5;
  ok $c->nextOn(qw(d))  ->id == 2;
  ok $c->nextOn(qw(c d))->id == 4;
  ok $e->nextOn(qw(c d))     == $e;
  ok $e->prevOn(qw(d))  ->id == 4;
  ok $e->prevOn(qw(c d))     == $c;
 }

if (1)                                                                          # Put as text
 {my $x = sample2;
  my $c = $x->go(qw(b c));
  $c->putFirstAsText("<d id=\"dd\">DDDD</d>");
  ok -s $x eq "<a id=\"aa\"><b id=\"bb\"><c id=\"cc\"><d id=\"dd\">DDDD</d></c></b></a>";
  $c->putLastAsText("<e id=\"ee\">EEEE</e>");
  ok -s $x eq "<a id=\"aa\"><b id=\"bb\"><c id=\"cc\"><d id=\"dd\">DDDD</d><e id=\"ee\">EEEE</e></c></b></a>";
  $c->putNextAsText("<n id=\"nn\">NNNN</n>");
  ok -s $x eq "<a id=\"aa\"><b id=\"bb\"><c id=\"cc\"><d id=\"dd\">DDDD</d><e id=\"ee\">EEEE</e></c><n id=\"nn\">NNNN</n></b></a>";
  $c->putPrevAsText("<p id=\"pp\">PPPP</p>");
  ok -s $x eq '<a id="aa"><b id="bb"><p id="pp">PPPP</p><c id="cc"><d id="dd">DDDD</d><e id="ee">EEEE</e></c><n id="nn">NNNN</n></b></a>';

  my $X = $x->renew;
  ok $X->equals($x);
  ok $X->firstContextOf(qw(e))     ->id      eq qq(ee);
  ok $X->firstContextOf(qw(d))     ->context eq qq(d c b a);
  ok $X->firstContextOf(qw(e))     ->context eq qq(e c b a);
  ok $X->lastContextOf(qw(CDATA d))->string  eq qq(DDDD);
 }

if (1)                                                                          # New
 {my $x = Data::Edit::Xml::newTree("a", id=>1, class=>"aa");                    #TnewTree #TnewTag #TattrCount
  ok -s $x eq '<a class="aa" id="1"/>';                                         #TnewTree
  ok $x->attrCount == 2;                                                        #TattrCount
  $x->putLast($x->newTag("b", id=>2, class=>"bb"));                             #TnewTag
  ok $x->go(qw(b))->attrCount == 2;
  ok -p $x eq <<END;                                                            #TnewText #TnewTag
<a class="aa" id="1">
  <b class="bb" id="2"/>
</a>
END
  $x->putLast($x->newText("t"));                                                #TnewText
  ok -p $x eq <<END;                                                            #TnewText
<a class="aa" id="1">
  <b class="bb" id="2"/>
t
</a>
END
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

if (1)
 {my $c = Data::Edit::Xml::newTree("c", id=>33);                                #TwrapUp
  my ($b, $a) = $c->wrapUp(qw(b a));                                            #TwrapUp
  ok $a->tag eq qq(a);
  ok $b->tag eq qq(b);
  ok $c->tag eq qq(c);
  ok $a->go(qw(b c))->id == 33;
  ok -p $a eq <<END;
<a>
  <b>
    <c id="33"/>
  </b>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::newTree("a", id=>33);                                #TwrapDown
  my ($b, $c) = $a->wrapDown(qw(b c));                                          #TwrapDown
  ok $a->tag eq qq(a);
  ok $b->tag eq qq(b);
  ok $c->tag eq qq(c);
  ok $a->id == 33;
  ok -p $a eq <<END;
<a id="33">
  <b>
    <c/>
  </b>
</a>
END
 }

if (1)                                                                          # Unwrap
 {my $x = Data::Edit::Xml::new("<a><b><c/></b></a>");
  $x->go(qw(b c))->unwrap;
  $x->checkParentage;
  ok -s $x eq "<a><b/></a>";
  $x->go(qw(b))->unwrap;
  ok -s $x eq "<a/>";
  eval {$x->unwrap};
  ok $@ =~ /\ACannot unwrap the outer most node/gs;
 }

if (1)                                                                          # Break in and out
 {my $A = Data::Edit::Xml::new("<a><b><d/><c/><c/><e/><c/><c/><d/></b></a>");

  if (1)
   {my $a = $A->clone;
    $a->go(qw(b))->breakOut($a, qw(d e));                                      # Break out
    ok -s $a eq '<a><d/><b><c/><c/></b><e/><b><c/><c/></b><d/></a>';

    $a->go(qw(b 1))->breakIn;                                                  # Break in
    ok $A->equals($a);

    $a->go(qw(b))  ->breakOut($a, qw(d e));                                    # Break backwards
    $a->go(qw(b 1))->breakInBackwards;
    ok -s $a eq '<a><b><d/><c/><c/><e/><c/><c/></b><d/></a>';
    my $d = $a->go(qw(d))->cut;
    eval {$d->putLast($d)};
    ok $@ =~ m/\ARecursive insertion attempted/s;
    $a->go(qw(b))->putLast($d);
    ok $A->equals($a);

    $a->go(qw(b))  ->breakOut($a, qw(d e));                                    # Break forwards
    $a->go(qw(b))->breakInForwards;
    ok -s $a eq '<a><d/><b><c/><c/><e/><c/><c/><d/></b></a>';
    my $D = $a->go(qw(d))->cut;
    eval {$D->putFirst($D)};
    ok $@ =~ m/\ARecursive insertion attempted/s;
    $a->go(qw(b))->putFirst($D);
    ok $A->equals($a);
   }
 }

if (1)                                                                          # Path
 {my @tags = qw(a b c d e);
  my ($a, $b, $c, $d, $e) = Data::Edit::Xml::new
   ("<a><b><c/><c/><d><e/></d><c/><c/><d><e/></d><c/><c/></b></a>")->
    firstDown(@tags);                                                           # firstDown

  my ($A, $B, $C, $D, $E) = $a->lastDown(@tags);                                # lastDown

  ok eval ' $'.$_    .'->tag eq "'.$_.'"' for @tags;                            # Tags equal their variable names
  ok eval ' $'.uc($_).'->tag eq "'.$_.'"' for @tags;                            # Tags equal their lowercased uppercase variable names
  ok eval ' $'.$_     .'->ordered($'.uc($_).')->tag eq $'.$_.'->tag'  for @tags;# Lowercase nodes precede uppercase nodes
  ok eval '!$'.uc($_).'->ordered($'.$_    .') or $'.$_.' == $'.uc($_) for @tags;# Uppercase nodes equal lowercase nodes or do not precede them

  ok $A == $a;
  ok $B == $b;
  ok $C == $b->go(qw(c 5));
  ok $D == $b->go(qw(d -1));
  ok $E == $D->go(qw(e));

  $a->by(sub {ok $a->go($_->path) == $_});                                     # Path

  ok $d == $b->disordered($c, $e, $d);                                          # Disordered
  ok $c == $e->disordered($c);

  ok $e->ordered($E);                                                           # Ordered
  ok $e->ordered($e);
  ok $e->ordered;
  ok $a->ordered($b,$c,$d,$e);
  ok $A->ordered($B,$D,$E,$C);

  is_deeply [$a->firstDown(@tags)], [$a-> lastBy(@tags)];
  is_deeply [$a-> lastDown(@tags)], [$a->firstBy(@tags)];
 }

if (1)
 {ok Data::Edit::Xml::new(<<END)->go(qw(b c -1 e))->at(qw(e c b a));           #Tat
<a>
  <b>
    <c> <d/> </c>
    <c> <e/> </c>
  </b>
</a>
END
 }

if (1)                                                                          # Numbered
 {my $s = <<END;
<a id="1">aa
  <b id="2">bb
    <c id="3">cc
      <e id="4"/>
dd
    </c>
ee
    <d id="5">ff
      <e id="6"/>
gg
    </d>
hh
    <c id="7">ii
      <d id="8">jj
        <e id="9"/>
kk
      </d>
ll
    </c>
mm
    <d id="10">nn
      <e id="11"/>
oo
    </d>
pp
    <c id="12">qq
      <d id="13">rr
        <e/>
ss
      </d>
tt
    </c>
uu
  </b>
vv
</a>

END
  my $a = Data::Edit::Xml::new($s);

  $a->numberTree;                                                               # Number tree
  ok  $a->findByNumber(11)->id == 11;                                           # FindByNumber
  ok  $a->findByNumber( 9)->id ==  9;

  ok !$a->above($a);                                                            # Above
  ok  $a->findByNumber( 7)->above($a->findByNumber(9));
  ok !$a->findByNumber( 9)->above($a->findByNumber(11));

  ok !$a->below($a);                                                            # Below
  ok  $a->findByNumber(14)->below($a->findByNumber(12));
  ok !$a->findByNumber( 9)->below($a->findByNumber(11));

  ok  $a->findByNumber(13)->after($a->findByNumber( 9));

  if (1)
   {my ($m, $n) = $a->findByNumbers(5, 10);                                     # FindByNumbers
    ok  $m->before($n);
   }
 }

if (1)                                                                          # Position
 {my $a = Data::Edit::Xml::new("<a><b><c/><d><e/></d></b></a>");
  my $b =  $a->go(qw(b));
  my $c =  $b->go(qw(c));
  my $d =  $b->go(qw(d));
  my $e =  $d->go(qw(e));
  ok $c->byPosition        < $d->byPosition;
  ok $c->byReversePosition > $d->byReversePosition;
 }

if (1)                                                                          # IsOnlyChild
 {my $a = Data::Edit::Xml::new("<a><b><c><d/></c></b></a>");
  ok $a->go(qw(b c d))->isOnlyChild;
  ok $a->go(qw(b c d))->isOnlyChild(qw(d));
  ok $a->go(qw(b c d))->isOnlyChild(qw(d c));
  ok $a->go(qw(b c d))->isOnlyChild(qw(d c b));
 }

if (1)                                                                          # Cut
 {my $x = Data::Edit::Xml::new("<a><b><c/></b></a>");
  $x->go(qw(b c))->cut;
  $x->checkParentage;
  ok -s $x eq "<a><b/></a>";
  $x->go(qw(b))->cut;
  ok -s $x eq "<a/>";
  eval {$x->cut};
  ok !$@;                                                                       # Permit multiple cut outs of the same node
 }

if (1)                                                                          # Cut blank
 {my $x = Data::Edit::Xml::new("<a>A<b/>B</a>");
  my $b = $x->go(qw(b));
  $b->putFirst($x->newText(' c '));
  ok -s $x eq "<a>A<b> c </b>B</a>";                                            #Tunwrap
  $b->unwrap;                                                                   #Tunwrap
  ok -s $x eq "<a>A c B</a>";                                                   #Tunwrap
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
  is_deeply $x->countTagNames, { a => 1, aa => 22, B => 3, b => 4, bb => 22, C => 10, c => 11, cc => 17, CDATA => 153, dd => 17, ww => 23, xx => 37};

  ok $x->countTags == 320;
  $x->checkParentage;

  ok  $x->equals($x);                                                           # Equals and clone
  my  $y = $x->clone;
  my  $z = $y->clone;
  ok  $y->equals($x);
  ok  $y->equals($y);
  ok  $y->equals($z);
  ok  $x->equals($z);
  ok  $y->by(sub
   {if ($_->at(qw(C)))
     {$_->change(qw(D));
     }
   });

  ok !$y->equals($z);

  if (1)                                                                        # Save restore
   {my $f = "zzz.data";
    unlink $f;
    my $y1 = eval {Data::Edit::Xml::restore($f)};
    ok $@ =~ /Cannot restore from a non existent file/gs;

    $y->save($f);
    my $Y = Data::Edit::Xml::restore($f);
    unlink $f;
    ok $Y->equals($y);
   }

  my $a = 0;                                                                    # Cut and unwrap
  $x->by(sub
   {my $t = $_->tag;
    eval {$x->cut};
    eval {$x->unwrap};
    eval {$_->cut}    if ++$a % 2;
    eval {$_->unwrap} if ++$a % 2;
   });

  $x->checkParentage;
  ok -s $x eq "<a/>";
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

if (1)                                                                          # Special characters
 {my $t =
   '<a id="&quot;&lt;&gt;&quot;&lt;&gt;">&quot;&lt;&gt;&quot;&lt;&gt;</a>';
  my $x = Data::Edit::Xml::new($t);
  ok -s $x eq $t;
 }

if (1)                                                                          # splitBack
 {my $A = Data::Edit::Xml::new("<a><b><c id='1'/><c id='2'/><d/><c id='3'/><c id='4'/></b></a>");

  if (my $a = $A->clone)
   {my $d = $a->go(qw(b d));
    eval {$a->splitBack(qq(D))};
    ok $@ =~ m/\ACannot move nodes immediately under the root node/s;
    my $D = $d->splitBack(qq(D));
    ok -s $a eq '<a><D><c id="1"/><c id="2"/><d/></D><b><c id="3"/><c id="4"/></b></a>';
    ok $D->string eq '<D><c id="1"/><c id="2"/><d/></D>';
    $a->go(qw(b))->concatenate($D);
    ok $a->equals($A);
   }

  if (my $a = $A->clone)
   {my $d = $a->go(qw(b d));
    eval {$a->splitBackEx(qq(D))};
    ok $@ =~ m/\ACannot move nodes immediately under the root node/s;
    my $D = $d->splitBackEx(qq(D));
    ok -s $a eq '<a><D><c id="1"/><c id="2"/></D><b><d/><c id="3"/><c id="4"/></b></a>';
    ok $D->string eq '<D><c id="1"/><c id="2"/></D>';
    $a->go(qw(b))->concatenate($D);
    ok $a->equals($A);
   }

  if (my $a = $A->clone)
   {my $d = $a->go(qw(b d));
    eval {$a->splitForwards(qq(D))};
    ok $@ =~ m/\ACannot move nodes immediately under the root node/s;
    my $D = $d->splitForwards(qq(D));
    ok -s $a eq '<a><b><c id="1"/><c id="2"/></b><D><d/><c id="3"/><c id="4"/></D></a>';
    ok $D->string eq '<D><d/><c id="3"/><c id="4"/></D>';
    $a->go(qw(b))->concatenate($D);
    ok $a->equals($A);
   }

  if (1)
   {my $s = '<a><b><c id="1"/><c id="2"/><d/><c id="3"/><c id="4"/></b></a>';   #Tclone #Tequals
    ok -s $A eq $s;                                                             #Tclone #Tequals
    my $a = $A->clone;                                                          #Tclone #Tequals
    ok -s $a eq $s;                                                             #Tclone
    ok $a->equals($A);                                                          #Tequals

    my $d = $a->go(qw(b d));
    eval {$a->splitForwardsEx(qq(D))};
    ok $@ =~ m/\ACannot move nodes immediately under the root node/s;
    my $D = $d->splitForwardsEx(qq(D));
    ok -s $a eq '<a><b><c id="1"/><c id="2"/><d/></b><D><c id="3"/><c id="4"/></D></a>';
    ok $D->string eq '<D><c id="3"/><c id="4"/></D>';
    $a->go(qw(b))->concatenate($D);
    ok $a->equals($A);
   }
 }

if (1)
 {my $s = <<END;                                                                #TprettyString #Tconcatenate
<a>
  <b>
    <A/>
    <B/>
  </b>
  <c>
    <C/>
    <D/>
  </c>
</a>
END
  my $a = Data::Edit::Xml::new($s);                                             #TprettyString #Tconcatenate
  ok $s eq $a->prettyString;                                                    #TprettyString
  ok $s eq -p $a;                                                               #TprettyString

  $a->go(qw(b))->concatenate($a->go(qw(c)));                                  #Tconcatenate

  my $t = <<END;                                                                #Tconcatenate
<a>
  <b>
    <A/>
    <B/>
    <C/>
    <D/>
  </b>
</a>
END
  ok $t eq -p $a;                                                               #Tconcatenate
 }

if (1)                                                                          # concatenateSiblings
 {my $a = Data::Edit::Xml::new('<a><b><c id="1"/></b><b><c id="2"/></b><b><c id="3"/></b><b><c id="4"/></b></a>');
  ok -p $a eq <<END;                                                            #TconcatenateSiblings
<a>
  <b>
    <c id="1"/>
  </b>
  <b>
    <c id="2"/>
  </b>
  <b>
    <c id="3"/>
  </b>
  <b>
    <c id="4"/>
  </b>
</a>
END

  $a->go(qw(b 3))->concatenateSiblings;                                        #TconcatenateSiblings

  ok -p $a eq <<END;                                                            #TconcatenateSiblings
<a>
  <b>
    <c id="1"/>
    <c id="2"/>
    <c id="3"/>
    <c id="4"/>
  </b>
</a>
END

  $a->concatenateSiblings;
  ok -s $a eq '<a><b><c id="1"/><c id="2"/><c id="3"/><c id="4"/></b></a>';
 }

if (1)
 {my $a = Data::Edit::Xml::new('<a/>');                                         #Tchange
  $a->change(qq(b));                                                            #Tchange
  ok -s $a eq '<b/>';                                                           #Tchange
 }

if (1)                                                                          # concatenateSiblings
 {my $x = sample1;
  is_deeply $x->countTagNames,  {b=>1, bar=>1, CDATA=>6, em=>1, foo=>1, foot=>2, head=>2, middle=>1, ref=>1, tail=>1};
  is_deeply $x->countAttrNames, {id=>5, key=>2, start=>3};
 }

if (1)                                                                          # *NonBlank
 {my $a = Data::Edit::Xml::new("<a>1<A/>2<B/>3<C/>4<D/>5<E/>6<F/>7<G/>8<H/>9</a>"); #TprettyStringShowingCDATA
  map {$_->replaceWithBlank} grep {$_->isText}               $a->contents;          #TprettyStringShowingCDATA
  map {$_->cut}              grep {$_->tag =~ m/\A[BDFH]\Z/} $a->contents;          #TprettyStringShowingCDATA

  ok $a->prettyStringShowingCDATA eq <<'END';                                   #TprettyStringShowingCDATA #TfirstNonBlank #TnextNonBlank #TfirstIn #TnextIn  #TlastNonBlank #TprevNonBlank #TlastIn #TprevIn
<a><CDATA> </CDATA>
    <A/>
<CDATA>  </CDATA>
    <C/>
<CDATA>  </CDATA>
    <E/>
<CDATA>  </CDATA>
    <G/>
<CDATA>  </CDATA>
</a>
END


  ok $a->firstNonBlank->tag eq qq(A);                                           #TfirstNonBlank
  ok $a->firstNonBlank->nextNonBlank->tag eq qq(C);                             #TnextNonBlank
  ok $a->firstIn(qw(b B c C))->tag eq qq(C);                                    #TfirstIn
  ok $a->firstIn(qw(b B c C))->nextIn(qw(A G))->tag eq qq(G);                   #TnextIn

  ok $a->lastNonBlank->tag eq qq(G);                                            #TlastNonBlank
  ok $a->lastNonBlank->prevNonBlank->tag eq qq(E);                              #TprevNonBlank
  ok $a->lastIn(qw(e E f F))->tag eq qq(E);                                     #TlastIn
  ok $a->lastIn(qw(e E f F))->prevIn(qw(A G))->tag eq qq(A);                    #TprevIn
 }

if (1)
 {my $x = Data::Edit::Xml::new(<<END)->first->first;                            #TisOnlyChild #TisEmpty
<a id="aa"><b id="bb"><c id="cc"/></b></a>
END

  ok $x->parent->isOnlyChild;
  ok $x->isOnlyChild;                                                           #TisOnlyChild
  ok $x->isOnlyChild(qw(c));                                                    #TisOnlyChild
  ok $x->isOnlyChild(qw(c b));                                                  #TisOnlyChild
  ok $x->isOnlyChild(qw(c b a));                                                #TisOnlyChild
  ok $x->isEmpty;                                                               #TisEmpty
 }

if (1)                                                                          # Operators
 {my $a = Data::Edit::Xml::new("<a id='1'><b id='2'><c id='3'/></b></a>");
  my $b = $a >> [qw(b)]; ok $b->id == 2;
  my $c = $b >> [qw(c)]; ok $c->id == 3;

  ok $c <= [qw(c b a)];
  $a x= sub {ok $_->id == 3 if $_ <= [qw(c b a)]};

  my $A = $a + '<b id="4"/>';
  ok -s $A eq '<b id="4"/>';
  ok -s $a eq '<a id="1"><b id="4"/><b id="2"><c id="3"/></b></a>';

  my $B = $b > '<b id="5"/>';
  ok -s $B eq  '<b id="5"/>';
  ok -s $a eq '<a id="1"><b id="4"/><b id="2"><c id="3"/></b><b id="5"/></a>';

  my $C = $b < '<b id="6"/>';
  ok -s $C eq  '<b id="6"/>';
  ok -s $a eq '<a id="1"><b id="4"/><b id="6"/><b id="2"><c id="3"/></b><b id="5"/></a>';

  my $D = $b - '<d id="7"/>';
  ok -s $D eq  '<d id="7"/>';
  ok -s $a eq '<a id="1"><b id="4"/><b id="6"/><b id="2"><d id="7"/><c id="3"/></b><b id="5"/></a>';

  ok -s $a eq '<a id="1"><b id="4"/><b id="6"/><b id="2"><d id="7"/><c id="3"/></b><b id="5"/></a>'; #Trenew
  my $x = $a->renew;                                                                                 #Trenew
  ok -s $x eq '<a id="1"><b id="4"/><b id="6"/><b id="2"><d id="7"/><c id="3"/></b><b id="5"/></a>'; #Trenew

  ok 4 == grep{$_ <= [qw(b a)] } @$x;

  ok $a % 'id' == 1;
  ok $b % 'id' == 2;
  ok $c % 'id' == 3;

  $a += qq(aa);
  ok -t $a eq 'aa';

  my $e = $a / qq(ee);
  ok -s $e eq '<ee><aa id="1"><b id="4"/><b id="6"/><b id="2"><d id="7"/><c id="3"/></b><b id="5"/></aa></ee>';

  my $f = $a * qq(f);
  ok -s $e eq '<ee><aa id="1"><f><b id="4"/><b id="6"/><b id="2"><d id="7"/><c id="3"/></b><b id="5"/></f></aa></ee>';

  --$c;
  ok -s $e eq '<ee><aa id="1"><f><b id="4"/><b id="6"/><b id="2"><d id="7"/></b><b id="5"/></f></aa></ee>';

  ++$a;
  ok -s $e eq '<ee><f><b id="4"/><b id="6"/><b id="2"><d id="7"/></b><b id="5"/></f></ee>';
 }

if (1)                                                                          # Labels
 {my $x = Data::Edit::Xml::new("<a><b><c/></b></a>");
  my $b = $x->go(qw(b));
  my $c = $b->go(qw(c));

  ok $b->countLabels == 0;
  ok $c->countLabels == 0;
  $b->addLabels(1..2);
  $b->addLabels(3..4);
  is_deeply [1..4], [$b->getLabels];

  $b->copyLabels($c) for 1..2;
  ok $b->countLabels == 4;
  ok $c->countLabels == 4;
  is_deeply [1..4], [$b->getLabels];
  is_deeply [1..4], [$c->getLabels];

  $b->deleteLabels(1,4) for 1..2;
  ok $b->countLabels == 2;
  ok $c->countLabels == 4;
  is_deeply [2..3], [$b->getLabels];
  is_deeply [1..4], [$c->getLabels];

  $b->moveLabels($c) for 1..2;
  ok $b->countLabels == 0;
  ok $c->countLabels == 4;
  is_deeply [], [$b->getLabels];
  is_deeply [1..4], [$c->getLabels];
  ok -s $x eq '<a><b><c/></b></a>';
  $c->id = 11;
  ok $x->string                      eq '<a><b><c id="11"/></b></a>';
  ok $x->stringReplacingIdWithLabels eq '<a><b><c id="1, 2, 3, 4"/></b></a>';

  ok -p $x eq <<END;                                                            #TwrapWith
<a>
  <b>
    <c id="11"/>
  </b>
</a>
END
  $x->go(qw(b c))->wrapWith(qw(C id 1));                                       #TwrapWith
  ok -p $x eq <<END;                                                            #TwrapWith
<a>
  <b>
    <C id="1">
      <c id="11"/>
    </C>
  </b>
</a>
END

  $c->wrapContentWith(qw(D id 2));                                              # WrapContentWIth
  ok -s $x eq '<a><b><C id="1"><c id="11"><D id="2"/></c></C></b></a>';
  $c->wrapContentWith(qw(E id 3));
  ok $x->string         eq '<a><b><C id="1"><c id="11"><E id="3"><D id="2"/></E></c></C></b></a>';

  ok $x->stringReplacingIdWithLabels eq '<a><b><C><c id="1, 2, 3, 4"><E><D/></E></c></C></b></a>';

  $c->wrapUp(qw(A B));                                                          # WrapUp
  ok -s $x eq '<a><b><C id="1"><B><A><c id="11"><E id="3"><D id="2"/></E></c></A></B></C></b></a>';
  $c->wrapDown(qw(G F));                                                        # WrapDown
  ok -s $x eq '<a><b><C id="1"><B><A><c id="11"><G><F><E id="3"><D id="2"/></E></F></G></c></A></B></C></b></a>';
 }

if (1)                                                                          # X versions
 {my $a = Data::Edit::Xml::new("<a><b><c/></b></a>");
  eval
   {my $c = $a->go(qw(b c));
    my $d = $a->goX(qw(b c d));
    ok 0;
   };
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);
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

  # Transform to Dita step 1

  $a->by(sub
   {my ($o, $p) = @_;
    if ($o->at(qw(pre p li sli)) and $o->isOnlyChild)
     {$o->change($p->isFirst ? qw(cmd) : qw(stepresult));
      $p->unwrap;
     }
    elsif ($o->at(qw(li sli))    and $o->over(qr(\Ap( p)+\Z)))
     {$_->change($_->isFirst ? qw(cmd) : qw(info)) for $o->contents;
     }
   });

  # Transform to Dita step 2

  $a->by(sub
  {my ($o) = @_;
   $o->change(qw(step))          if $o->at(qw(li sli));
   $o->change(qw(steps))         if $o->at(qw(sli));
   $o->id = 's'.($o->position+1) if $o->at(qw(step));
   $o->id = 'i'.($o->index+1)    if $o->at(qw(info));
   $o->wrapWith(qw(screen))      if $o->at(qw(CDATA stepresult));
  });

  # Print the results

  is_deeply [split //,  (-p $a) =~ s/\s+//gsr], [split //, <<END =~ s/\s+//gsr];# Dita
<steps>
  <step id="s1">
    <cmd>Diagnose the problem
    </cmd>
    <info id="i1">This can be quite difficult
    </info>
    <info id="i2">Sometimes impossible
    </info>
  </step>
  <step id="s2">
    <cmd>ls -la
    </cmd>
    <stepresult>
      <screen>
drwxr-xr-x  2 phil phil   4096 Jun 15  2016 Desktop
drwxr-xr-x  2 phil phil   4096 Nov  9 20:26 Downloads
      </screen>
    </stepresult>
  </step>
</steps>
END
}

if (1)                                                                          # Delete in context - methods
 {my $a = Data::Edit::Xml::new("<a><b><c/></b><d><c/></d></a>");
  ok -s $a->by(sub {$_->cut if $_->at(qw(c b a))}) eq
    '<a><b/><d><c/></d></a>';
 }

if (1)                                                                          # Delete in context - operators
 {my $a = Data::Edit::Xml::new("<a><b><c/></b><d><c/></d></a>");
  ok -s ($a x sub {--$_ if $_ <= [qw(c b a)]}) eq
    '<a><b/><d><c/></d></a>';
 }

if (1)                                                                          # Delete in context - exit chaining
 {my $a = Data::Edit::Xml::new("<a><b><c/></b><d><c/></d></a>");
  ok -s $a->byX(sub {$_->at(qw(c b a))->cut}) eq
    '<a><b/><d><c/></d></a>';
 }

1
