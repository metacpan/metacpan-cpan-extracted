#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Edit data held in the XML format.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2016-2017
#-------------------------------------------------------------------------------
# podDocumentation
# Example for sub attr is not showing up in the documentation
# Consider transferring any labels on nodes unwrapped by unwrapContent to calling node
# Line 220 - the & problem 21.04.2018

package Data::Edit::Xml;
our $VERSION = 20180427;
use v5.8.0;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Table::Text qw(filePathExt fullFileName genLValueArrayMethods genLValueHashMethods genLValueScalarMethods readFile temporaryFile writeFile);
use XML::Parser;                                                                # https://metacpan.org/pod/XML::Parser
use Storable qw(store retrieve freeze thaw);

#1 Construction                                                                 # Create a parse tree, either by parsing a L<file or string|/file or string>, or, L<node by node|/Node by Node>, or, from another L<parse tree|/Parse tree>

#2 File or String                                                               # Construct a parse tree from a file or a string

sub new(;$)                                                                     #IS New parse - call this method statically as in Data::Edit::Xml::new(file or string) B<or> with no parameters and then use L</input>, L</inputFile>, L</inputString>, L</errorFile>  to provide specific parameters for the parse, then call L</parse> to perform the parse and return the parse tree.
 {my ($fileNameOrString) = @_;                                                  # File name or string
  if (@_)
   {my $x = bless {input=>$fileNameOrString};                                   # Create XML editor with a string or file
    $x->parser = $x;                                                            # Parser root node
    return $x->parse;                                                           # Parse
   }
  my $x = bless {};                                                             # Create empty XML editor
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
genLValueScalarMethods(qw(number));                                             # Number of this node, see L<findByNumber|/findByNumber>.
genLValueScalarMethods(qw(numbering));                                          # Last number used to number a node in this parse tree.
genLValueScalarMethods(qw(parent));                                             # Parent node of this node or undef if the oarser root node. See also L</Traversal> and L</Navigation>. Consider as read only.
genLValueScalarMethods(qw(parser));                                             # Parser details: the root node of a tree is the parse node for that tree. Consider as read only.
genLValueScalarMethods(qw(tag));                                                # Tag name for this node, see also L</Traversal> and L</Navigation>. Consider as read only.
genLValueScalarMethods(qw(text));                                               # Text of this node but only if it is a text node, i.e. the tag is cdata() <=> L</isText> is true.

sub cdata()                                                                     # The name of the tag to be used to represent text - this tag must not also be used as a command tag otherwise the parser will L<confess|http://perldoc.perl.org/Carp.html#SYNOPSIS/>.
 {'CDATA'
 }

sub parse($)                                                                    # Parse input XML specified via: L<inputFile|/inputFile>, L<input|/input> or L<inputString|/inputString>.
 {my ($parser) = @_;                                                            # Parser created by L</new>

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
  if (!$x)                                                                      # Error in parse: write a message to STDERR and to a file if possible
   {my $f = $parser->inputFile ? "Source file is:\n".                           # Source details if a file
            $parser->inputFile."\n" : '';
    my $e = "$d\n$f\n$@\n";                                                     # Error
    # warn "Xml parse error: $e";                                               # Write a description of the error to STDERR before attempting to write to a file
    my $badFile  = $parser->errorsFile ||                                       # File name to write error analysis to
                   fullFileName(filePathExt(qw(zzzParseErrors out data)));
    unlink $badFile if -e $badFile;                                             # Remove existing errors file
    writeFile($badFile, $e);                                                    # Write a description of the error to the errorsFile
    confess "Xml parse error, see file:\n$badFile\n";                           # Complain helpfully if parse failed
   }
  $parser->tree($x);                                                            # Structure parse results as a tree
  if (my @c = @{$parser->content})
   {confess "No XML" if !@c;
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

sub tree($$)                                                                    #P Build a tree representation of the parsed XML which can be easily traversed to look for things.
 {my ($parent, $parse) = @_;                                                    # The parent node, the remaining parse
  while(@$parse)
   {my $tag  = shift @$parse;                                                   # Tag for node
    my $node = bless {parser=>$parent->parser};                                 # New node
    if ($tag eq cdata)
     {confess cdata.' tag encountered';                                         # We use this tag for text and so it cannot be used as a user tag in the document
     }
    elsif ($tag eq '0')                                                         # Text
     {my $s = shift @$parse;
      if ($s !~ /\A\s*\Z/)                                                      # Ignore entirely blank strings
       {$s = replaceSpecialChars($s);                                           # Restore special characters in the text
        $node->tag  = cdata;                                                    # Save text. ASSUMPTION: CDATA is not used as a tag anywhere.
        $node->text = $s;
        push @{$parent->content}, $node;                                        # Save on parents content list
       }
     }
    else                                                                        # Node
     {my $children   = shift @$parse;
      my $attributes = shift @$children;
      $node->tag = $tag;                                                        # Save tag
      $_ = replaceSpecialChars($_) for values %$attributes;                     # Restore in text with XML special characters
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

sub reindexNode($)                                                              #P Index the children of a node so that we can access them by tag and number.
 {my ($node) = @_;                                                              # Node to index.
  delete $node->{indexes};                                                      # Delete the indexes
  for my $n($node->contents)                                                          # Index content
   {push @{$node->indexes->{$n->tag}}, $n;                                      # Indices to sub nodes
   }
 }

sub indexNode($)                                                                #P Merge multiple text segments and set parent and parser after changes to a node
 {my ($node) = @_;                                                              # Node to index.
  my @contents = $node->contents;                                               # Contents of the node
  return unless @contents;                                                      # No content so no indexes

  if ((grep {$_->{tag} eq cdata} @contents) > 1)                                # Make parsing easier for the user by concatenating successive text nodes - NB: this statement has been optimized
   {my (@c, @t);                                                                # New content, pending intermediate texts list
    for(@contents)                                                              # Each node under the current node
     {if ($_->{tag} eq cdata)                                                   # Text node. NB: optimized
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
   {$n->parent = $node;                                                         # Point to parent
    $n->parser = $node->parser;                                                 # Point to parser
   }
 }

sub replaceSpecialChars($)                                                      # Replace < > " with &lt; &gt; &quot;  Larry Wall's excellent L<Xml parser|https://metacpan.org/pod/XML::Parser/> unfortunately replaces &lt; &gt; &quot; &amp; etc. with their expansions in text by default and does not seem to provide an obvious way to stop this behavior, so we have to put them back gain using this method. Worse, we cannot decide whether to replace & with &amp; or leave it as is: consequently you might have to examine the instances of & in your output text and guess based on the context.
 {my ($string) = @_;                                                            # String to be edited.
  $string =~ s/\&/&amp;/g;                                                      # At this point all & that prefix variables should have been expanded, so any that are left are are real &s which should be replaced with &amp;
  $string =~ s/\</&lt;/gr =~ s/\>/&gt;/gr =~ s/\"/&quot;/gr                     # Replace the special characters that we can replace.
 }

#2 Parse tree                                                                   # Construct a parse tree from another parse tree

sub renew($@)                                                                   #C Returns a renewed copy of the parse tree, optionally checking that the starting node is in a specified context: use this method if you have added nodes via the L</"Put as text"> methods and wish to add them to the parse tree.  Returns the starting node of the new parse tree or B<undef> if the optional context constraint was not supplied but not satisfied.
 {my ($node, @context) = @_;                                                    # Node to renew from, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  new($node->string)
 }

sub clone($@)                                                                   #C Return a clone of the parse tree optionally checking that the starting node is in a specified context: the parse tree is cloned without converting it to string and reparsing it so this method will not L<renew|/renew> any nodes added L<as text|/Put as text>.  Returns the starting node of the new parse tree or B<undef> if the optional context constraint was not supplied but not satisfied.
 {my ($node, @context) = @_;                                                    # Node to clone from, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
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

#1 Print                                                                        # Create a string representation of the parse tree with optional selection of nodes via L<conditions|/Conditions>.\mNormally use the methods in L<Pretty|/Pretty> to format the XML in a readable yet reparseable manner; use L<Dense|/Dense> string to format the XML densely in a reparseable manner; use the other methods to produce unreparseable strings conveniently formatted to assist various specialized operations such as debugging CDATA, using labels or creating tests. A number of the L<file test operators|/opString> can also be conveniently used to print parse trees in these formats.

#2 Pretty                                                                       # Pretty print the parse tree.

sub prettyString($;$)                                                           #I Return a readable string representing a node of a parse tree and all the nodes below it. Or use L<-p|/opString> $node
 {my ($node, $depth) = @_;                                                      # Start node, optional depth.
  $depth //= 0;                                                                 # Start depth if none supplied

  if ($node->isText)                                                            # Text node
   {my $n = $node->next;
    my $s = !defined($n) || $n->isText ? '' : "\n";                             # Add a new line after contiguous blocks of text to offset next node
    return $node->text.$s;
   }

  my $t = $node->tag;                                                           # Not text so it has a tag
  my $content = $node->content;                                                 # Sub nodes
  my $space   = "  "x($depth//0);
  return $space.'<'.$t.$node->printAttributes.'/>'."\n" if !@$content;          # No sub nodes

  my $s = $space.'<'.$t.$node->printAttributes.'>'.                             # Has sub nodes
    ($node->first->isText ? '' : "\n");                                         # Continue text on the same line, otherwise place nodes on following lines
  $s .= $_->prettyString($depth+1) for @$content;                               # Recurse to get the sub content
  $s .= $node->last->isText ? ((grep{!$_->isText} @$content)                    # Continue text on the same line, otherwise place nodes on following lines
                            ? "\n$space": "") : $space;
  $s .  '</'.$t.'>'."\n";                                                       # Closing tag
 }

sub prettyStringNumbered($;$)                                                   # Return a readable string representing a node of a parse tree and all the nodes below it with a L<number|/number> attached to each tag. The node numbers can then be used as described in L<Order|/Order> to monitor changes to the parse tree.
 {my ($node, $depth) = @_;                                                      # Start node, optional depth.
  $depth //= 0;                                                                 # Start depth if none supplied

  my $N = $node->number;                                                        # Node number if present

  if ($node->isText)                                                            # Text node
   {my $n = $node->next;
    my $s = !defined($n) || $n->isText ? '' : "\n";                             # Add a new line after contiguous blocks of text to offset next node
    return ($N ? "($N)" : '').$node->text.$s;                                   # Number text
   }

  my $t = $node->tag;                                                           # Number tag in a way which allows us to skip between start and end tags in L<Geany|http://www.geany.org> using the ctrl+up and ctrl+down arrows
  my $i = $N && !defined($node->id) ? " id=\"$N\""  : '';                                              # Use id to hold tag
  my $content = $node->content;                                                 # Sub nodes
  my $space   = "  "x($depth//0);
  return $space.'<'.$t.$i.$node->printAttributes.'/>'."\n" if !@$content;       # No sub nodes

  my $s = $space.'<'.$t.$i.$node->printAttributes.'>'.                          # Has sub nodes
    ($node->first->isText ? '' : "\n");                                         # Continue text on the same line, otherwise place nodes on following lines
  $s .= $_->prettyStringNumbered($depth+1) for @$content;                       # Recurse to get the sub content
  $s .= $node->last->isText ? ((grep{!$_->isText} @$content)                    # Continue text on the same line, otherwise place nodes on following lines
                            ? "\n$space": "") : $space;
  $s .  '</'.$t.'>'."\n";                                                       # Closing tag
 }

sub prettyStringCDATA($;$)                                                      # Return a readable string representing a node of a parse tree and all the nodes below it with the text fields wrapped with <CDATA>...</CDATA>.
 {my ($node, $depth) = @_;                                                      # Start node, optional depth.
  $depth //= 0;                                                                 # Start depth if none supplied

  if ($node->isText)                                                            # Text node
   {my $n = $node->next;
    my $s = !defined($n) || $n->isText ? '' : "\n";                             # Add a new line after contiguous blocks of text to offset next node
    return '<'.cdata.'>'.$node->text.'</'.cdata.'>'.$s;
   }

  my $t = $node->tag;                                                           # Not text so it has a tag
  my $content = $node->content;                                                 # Sub nodes
  my $space   = "  "x($depth//0);
  return $space.'<'.$t.$node->printAttributes.'/>'."\n" if !@$content;          # No sub nodes

  my $s = $space.'<'.$t.$node->printAttributes.'>'.                             # Has sub nodes
    ($node->first->isText ? '' : "\n");                                         # Continue text on the same line, otherwise place nodes on following lines
  $s .= $_->prettyStringCDATA($depth+2) for @$content;                          # Recurse to get the sub content
  $s .= $node->last->isText ? ((grep{!$_->isText} @$content)                    # Continue text on the same line, otherwise place nodes on following lines
                            ? "\n$space": "") : $space;
  $s .  '</'.$t.'>'."\n";                                                       # Closing tag
 }

sub prettyStringEnd($)                                                          #P Return a readable string representing a node of a parse tree and all the nodes below it as a here document
 {my ($node) = @_;                                                              # Start node
  my $s = -p $node;                                                             # Pretty string representation
'  ok -p $x eq <<END;'. "\n".(-p $node). "\nEND"                                # Here document
 }

sub prettyStringContent($)                                                      # Return a readable string representing all the nodes below a node of a parse tree.
 {my ($node) = @_;                                                              # Start node.
  my $s = '';
  $s .= $_->prettyString for $node->contents;                                   # Recurse to get the sub content
  $s
 }

sub prettyStringContentNumbered($)                                              # Return a readable string representing all the nodes below a node of a parse tree with numbering added.
 {my ($node) = @_;                                                              # Start node.
  my $s = '';
  $s .= $_->prettyStringNumbered for $node->contents;                           # Recurse to get the sub content
  $s
 }

#2 Dense                                                                        # Print the parse tree.

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

sub stringReplacingIdsWithLabels($)                                             # Return a string representing the specified parse tree with the id attribute of each node set to the L<Labels|/Labels> attached to each node.
 {my ($node) = @_;                                                              # Start node.
  return $node->text if $node->isText;                                          # Text node
  my $t = $node->tag;                                                           # Not text so it has a tag
  my $content = $node->content;                                                 # Sub nodes
  return '<'.$t.$node->printAttributesReplacingIdsWithLabels.'/>' if !@$content;# No sub nodes

  my $s = '<'.$t.$node->printAttributesReplacingIdsWithLabels.'>';              # Has sub nodes
  $s .= $_->stringReplacingIdsWithLabels for @$content;                         # Recurse to get the sub content
  return $s.'</'.$t.'>';
 }

sub stringContent($)                                                            # Return a string representing all the nodes below a node of a parse tree.
 {my ($node) = @_;                                                              # Start node.
  my $s = '';
  $s .= $_->string for $node->contents;                                         # Recurse to get the sub content
  $s
 }

sub stringNode($)                                                               # Return a string representing a node showing the attributes, labels and node number
 {my ($node) = @_;                                                              # Node.
  my $s = '';

  if ($node->isText)                                                            # Text node
   {$s = 'CDATA='.$node->text;
   }
  else                                                                          # Non text node
   {$s = $node->tag.$node->printAttributes;
   }

  if (my $n = $node->number)                                                    # Node number if present
   {$s .= "($n)"
   }

  if (my @l = $node->getLabels)                                                 # Labels
   {$s .= " ${_}:".$l[$_] for keys @l;
   }

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

#1 Attributes                                                                   # Get or set the attributes of nodes in the parse tree. L<Well Known Attributes|/Well Known Attributes>  can be set directly via L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>s. To set or get the values of other attributes use L<Get or Set Attributes|/Get or Set Attributes>. To delete or rename attributes see: L<Other Operations on Attributes|/Other Operations on Attributes>.

#2 Well Known Attributes                                                        # Get or set these attributes of nodes via L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>s as in:\m  $x->href = "#ref";
if (0) {                                                                        # Node attributes.
genLValueScalarMethods(qw(class));                                              # Attribute B<class> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(guid));                                               # Attribute B<guid> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(href));                                               # Attribute B<href> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(id));                                                 # Attribute B<id> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(navtitle));                                           # Attribute B<navtitle> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(otherprops));                                         # Attribute B<otherprops> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(outputclass));                                        # Attribute B<outputclass> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(props));                                              # Attribute B<props> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(style));                                              # Attribute B<style> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(type));                                               # Attribute B<type> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
}

BEGIN
 {for(qw(class guid href id navtitle otherprops outputclass props style type))  # Return well known attributes as an assignable value
   {eval 'sub '.$_.'($) :lvalue {&attr($_[0], qw('.$_.'))}';
    $@ and confess "Cannot create well known attribute $_\n$@";
   }
 }
#2 Get or Set Attributes                                                        # Get or set the attributes of nodes.
sub attr($$) :lvalue                                                            #I Return the value of an attribute of the current node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
 {my ($node, $attribute) = @_;                                                  # Node in parse tree, attribute name.
  $node->attributes->{$attribute}
 }

sub setAttr($@)                                                                 # Set the values of some attributes in a node and return the node.
 {my ($node, %values) = @_;                                                     # Node in parse tree, (attribute name=>new value)*
  s/["<>]/ /gs for grep {$_} values %values;                                    # We cannot have these characters in an attribute
  $node->attributes->{$_} = $values{$_} for keys %values;                       # Set attributes
  $node
 }

#2 Other Operations on Attributes                                               # Perform operations other than get or set on the attributes of a node
sub attrs($@)                                                                   # Return the values of the specified attributes of the current node as a list
 {my ($node, @attributes) = @_;                                                 # Node in parse tree, attribute names.
  my @v;
  my $a = $node->attributes;
  push @v, $a->{$_} for @attributes;
  @v
 }

sub attrCount($)                                                                # Return the number of attributes in the specified node.
 {my ($node) = @_;                                                              # Node in parse tree.
  my $a = $node->attributes;                                                    # Attributes
  scalar grep {defined $a->{$_}} keys %$a                                       # Attributes
 }

sub getAttrs($)                                                                 # Return a sorted list of all the attributes on this node.
 {my ($node) = @_;                                                              # Node in parse tree.
  my $a = $node->attributes;                                                    # Attributes
  grep {defined $a->{$_}} sort keys %$a                                         # Attributes
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
 {my ($node, @attrs) = @_;                                                      # Node, attribute names to delete
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

#2 Post-order                                                                    # This order allows you to edit children before their parents

sub by($$;@)                                                                    #I Post-order traversal of a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  $_->by($sub, $node, @context) for @n;                                         # Recurse to process sub nodes in deeper context
  &$sub(local $_ = $node, @context);                                            # Process specified node last
  $node
 }

sub byX($$)                                                                     #C Post-order traversal of a parse tree calling the specified B<sub> at each node as long as this sub does not L<die|http://perldoc.perl.org/functions/die.html>. The traversal is halted if the called sub does  L<die|http://perldoc.perl.org/functions/die.html> on any call with the reason in L<?@|http://perldoc.perl.org/perlvar.html#Error-Variables> The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry> up to the node on which this sub was called. A reference to the current node is also made available via B<$_>. Regardless of the outcome of calling B<sub>, byX returns the start node.
 {my ($node, $sub) = @_;                                                        # Start node, sub to call
  eval {$node->byX2($sub)};                                                     # Trap any errors that occur
  $node
 }

sub byX2($$;@)                                                                  #P Post-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  $_->byX2($sub, $node, @context) for @n;                                       # Recurse to process sub nodes in deeper context
  &$sub(local $_ = $node, @context);                                            # Process specified node last
 }

sub byX22($$;@)                                                                 #P Post-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.
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

#2 Pre-order                                                                    # This order allows you to edit children after their parents

sub down($$;@)                                                                  # Pre-order traversal down through a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$sub(local $_ = $node, @context);                                            # Process specified node first
  $_->down($sub, $node, @context) for @n;                                       # Recurse to process sub nodes in deeper context
  $node
 }

sub downX($$)                                                                   #C Pre-order traversal of a parse tree calling the specified B<sub> at each node as long as this sub does not L<die|http://perldoc.perl.org/functions/die.html>. The traversal is halted if the called sub does  L<die|http://perldoc.perl.org/functions/die.html> on any call with the reason in L<?@|http://perldoc.perl.org/perlvar.html#Error-Variables> The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry> up to the node on which this sub was called. A reference to the current node is also made available via B<$_>. Regardless of the outcome of calling B<sub>, byX returns the start node.
 {my ($node, $sub) = @_;                                                        # Start node, sub to call
  eval {$node->downX2($sub)};                                                   # Trap any errors that occur
  $node
 }

sub downX2($$;@)                                                                #P Pre-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$sub(local $_ = $node, @context);                                            # Process specified node last
  $_->downX2($sub, $node, @context) for @n;                                     # Recurse to process sub nodes in deeper context
 }

sub downX22($$;@)                                                               #P Pre-order traversal down through a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.
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

#2 Pre and Post order                                                           # Visit the parent first, then the children, then the parent again.

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

#2 Range                                                                        # Ranges of nodes

sub from($@)                                                                    # Return a list consisting of the specified node and its following siblings optionally including only those nodes that match one of the tags in the specified list.
 {my ($start, @match) = @_;                                                     # Start node, optional list of tags to match
  my $p = $start->parent;                                                       # Parent node
  confess "No parent" unless $p;                                                # Not possible on a root node
  my @c = $p->contents;                                                         # Content
  shift @c while @c and $c[ 0] != $start;                                       # Position on start node
  if (@match)                                                                   # Select matching nodes if requested
   {my %m = map {$_=>1} @match;
    return grep {$m{$_->tag}} @c;
   }
  @c                                                                            # Elements in the specified range
 }

sub to($@)                                                                      # Return a list of the sibling nodes preceding the specified node optionally including only those nodes that match one of the tags in the specified list.
 {my ($end, @match) = @_;                                                       # End node, optional list of tags to match
  my $q = $end->parent;                                                         # Parent node
  confess "No parent" unless $q;                                                # Not possible on a root node
  my @c = $q->contents;                                                         # Content
  pop   @c while @c and $c[-1] != $end;                                         # Position on end
  if (@match)                                                                   # Select matching nodes if requested
   {my %m = map {$_=>1} @match;
    return grep {$m{$_->tag}} @c;
   }
  @c                                                                            # Elements in the specified range
 }

sub fromTo($$@)                                                                 # Return a list of the nodes between the specified start and end nodes optionally including only those nodes that match one of the tags in the specified list.
 {my ($start, $end, @match) = @_;                                               # Start node, end node, optional list of tags to match
  my $p = $start->parent;                                                       # Parent node
  confess "No parent" unless $p;                                                # Not possible on a root node
  my $q = $end->parent;                                                         # Parent node
  confess "No parent" unless $q;                                                # Not possible on a root node
  confess "Not siblings" unless $p == $q;                                       # Not possible unless the two nodes are siblings under the same parent
  my @c = $p->contents;                                                         # Content
  shift @c while @c and $c[ 0] != $start;                                       # Position on start node
  pop   @c while @c and $c[-1] != $end;                                         # Position on end
  if (@match)                                                                   # Select matching nodes if requested
   {my %m = map {$_=>1} @match;
    return grep {$m{$_->tag}} @c;
   }
  @c                                                                            # Elements in the specified range
 }

#1 Position                                                                     # Confirm that the position L<navigated|/Navigation> to is the expected position.

sub at($@)                                                                      #IX Confirm that the node has the specified L<ancestry|/ancestry> and return the starting node if it does else B<undef>. Ancestry is specified by providing the expected tags that the parent, the parent's parent etc. must match at each level. If B<undef> is specified then any tag is assumed to match at that level. If a regular expression is specified then the current parent node tag must match the regular expression at that level. If all supplied tags match successfully then the starting node is returned else B<undef>
 {my ($start, @context) = @_;                                                   # Starting node, ancestry.
  for(my $x = shift @_; $x; $x = $x->parent)                                    # Up through parents
   {return $start unless @_;                                                    # OK if no more required context
    my $p = shift @_;                                                           # Next parent tag
    my $t = $x->tag;                                                            # Tag to match
    next if !$p or $p eq $t or ref($p) =~ m(regexp)i && $t =~ m($p)s;           # Carry on if contexts match
    return undef                                                                # Error if required does not match actual
   }
  !@_ ? $start : undef                                                          # Top of the tree is OK as long as there is no more required context
 }

sub atOrBelow($@)                                                               #IX Confirm that the node or one of its ancestors has the specified context as recognized by L<at|/at> and return the first node that matches the context or B<undef> if none do.
 {my ($start, @context) = @_;                                                   # Starting node, ancestry.
  for(my $x = $start; $x; $x = $x->parent)                                      # Up through parents
   {return $x if $x->at(@context);                                              # Return this node if the context matches
   }
  undef                                                                         # No node that matches the context
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

sub containsSingleText($)                                                       # Return the singleton text element below this node else return B<undef>
 {my ($node) = @_;                                                              # Node.
  return undef unless $node->countTags == 2;                                    # Must have just one child (plus the node itself)
  my $f = $node->first;                                                         # Child element
  return undef unless $f->isText;                                               # Child element must be text
  $f
 }

sub depth($)                                                                    # Returns the depth of the specified node, the  depth of a root node is zero.
 {my ($node) = @_;                                                              # Node.
  my $a = 0;
  for(my $x = $node->parent; $x; $x = $x->parent) {++$a}                        # Up through parents
  $a                                                                            # Return ancestry
 }

sub isFirst($@)                                                                 #BCX Return the specified node if it is first under its parent and optionally has the specified context, else return B<undef>
 {my ($node, @context) = @_;                                                    # Node, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $parent = $node->parent;                                                   # Parent
  return $node unless defined($parent);                                         # The top most node is always first
  $node == $parent->first ? $node : undef                                       # First under parent
 }

sub isLast($@)                                                                  #BCX Return the specified node if it is last under its parent and optionally has the specified context, else return B<undef>
 {my ($node, @context) = @_;                                                    # Node, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $parent = $node->parent;                                                   # Parent
  return $node unless defined($parent);                                         # The top most node is always last
  $node == $parent->last ? $node : undef                                        # Last under parent
 }

sub isOnlyChild($@)                                                             #CX Return the specified node if it is the only node under its parent (and ancestors) ignoring any surrounding blank text.
 {my ($node, @context) = @_;                                                    # Node, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $parent = $node->parent;                                                   # Find parent
  return undef unless $parent;                                                  # Not an only child unless there is no parent
  my @c = $parent->contents;                                                    # Contents of parent
  return $node if @c == 1;                                                      # Only child if only one child
  shift @c while @c and $c[ 0]->isBlankText;                                    # Ignore leading blank text
  pop   @c while @c and $c[-1]->isBlankText;                                    # Ignore trailing blank text
  return $node if @c == 1;                                                      # Only child if only one child after leading and trailing blank text has been ignored
  undef                                                                         # Not the only child
 }

sub isEmpty($@)                                                                 #CX Confirm that this node is empty, that is: this node has no content, not even a blank string of text. To test for blank nodes, see L<isAllBlankText|/isAllBlankText>.
 {my ($node, @context) = @_;                                                    # Node, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  !$node->first ? $node : undef                                                 # If it has no first descendant it must be empty
 }

sub over($$@)                                                                   #CX Confirm that the string representing the tags at the level below this node match a regular expression where each pair of tags is separated by a single space.
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentAsTags =~ m/$re/ ? $node : undef
 }

sub over2($$@)                                                                   #CX Confirm that the string representing the tags at the level below this node match a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a space and the last tag is followed by a space.  This arrangement simplifies the regular expression used to detect combinations like p+ q?
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentAsTags2 =~ m/$re/ ? $node : undef
 }

sub matchAfter($$@)                                                             #CX Confirm that the string representing the tags following this node matches a regular expression where each pair of tags is separated by a single space.
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentAfterAsTags =~ m/$re/ ? $node : undef
 }

sub matchAfter2($$@)                                                             #CX Confirm that the string representing the tags following this node matches a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a space and the last tag is followed by a space.  This arrangement simplifies the regular expression used to detect combinations like p+ q?
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentAfterAsTags2 =~ m/$re/ ? $node : undef
 }

sub matchBefore($$@)                                                            #CX Confirm that the string representing the tags preceding this node matches a regular expression where each pair of tags is separated by a single space.
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentBeforeAsTags =~ m/$re/ ? $node : undef
 }

sub matchBefore2($$@)                                                           #CX Confirm that the string representing the tags preceding this node matches a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a space and the last tag is followed by a space.  This arrangement simplifies the regular expression used to detect combinations like p+ q?
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentBeforeAsTags2 =~ m/$re/ ? $node : undef
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

sub pathString($)                                                               # Return a string representing the L<path|/path> to a node
 {my ($node) = @_;                                                              # Node.
  join ' ', path($node)                                                         # String representation
 }

#1 Navigation                                                                   # Move around in the parse tree

sub go($@)                                                                      #IX Return the node reached from the specified node via the specified L<path|/path>: (index positionB<?>)B<*> where index is the tag of the next node to be chosen and position is the optional zero based position within the index of those tags under the current node. Position defaults to zero if not specified. Position can also be negative to index back from the top of the index array. B<*> can be used as the last position to retrieve all nodes with the final tag.
 {my ($node, @position) = @_;                                                   # Node, search specification.
  my $p = $node;                                                                # Current node
  while(@position)                                                              # Position specification
   {my $i = shift @position;                                                    # Index name
    return undef unless $p;                                                     # There is no node of the named type under this node
    reindexNode($p);                                                            # Create index for this node
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
  reindexNode($node);                                                           # Create index for this node
  my $c = $node->indexes->{$tag};                                               # Index for specified tags
  $c ? @$c : ()                                                                 # Contents as an array
 }

#2 First                                                                        # Find nodes that are first amongst their siblings.

sub first($@)                                                                   #BCX Return the first node below this node optionally checking its context.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return $node->content->[0] unless @context;                                   # Return first node if no context specified
  my ($c) = $node->contents;                                                    # First node
  $c ? $c->at(@context) : undef;                                                # Return first node if in specified context
 }

sub firstText($@)                                                             #CX Return the first node if it is a text node otherwise undef
 {my ($node, @context) = @_;                                                    # Node, optional context.
  my $l = &first(@_);                                                           # First node
  $l ? $l->isText : undef                                                       # Test whether the first node exists and is a text node
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

sub firstIn($@)                                                                 #X Return the first node matching one of the named tags under the specified node.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  for($node->contents)                                                          # Search forwards through contents
   {return $_ if $tags{$_->tag};                                                # Find first tag with the specified name
   }
  return undef                                                                  # No such node
 }

sub firstInIndex($@)                                                            #CX Return the specified node if it is first in its index and optionally L<at|/at> the specified context else B<undef>
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Check the context if supplied
  my $parent = $node->parent;                                                   # Parent
  return undef unless $parent;                                                  # The root node is not first in anything
  my @c = $parent->c($node->tag);                                               # Index containing node
  @c && $c[0] == $node ? $node : undef                                          # First in index ?
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

#2 Last                                                                         # Find nodes that are last amongst their siblings.

sub last($@)                                                                    #BCX Return the last node below this node optionally checking its context.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return $node->content->[-1] unless @context;                                  # Return last node if no context specified
  my ($c) = reverse $node->contents;                                            # Last node
  $c ? $c->at(@context) : undef;                                                # Return last node if in specified context
 }

sub lastText($@)                                                              #CX Return the last node if it is a text node otherwise undef
 {my ($node, @context) = @_;                                                    # Node, optional context.
  my $l = &last(@_);                                                            # Last node
  $l ? $l->isText : undef                                                       # Test whether the last node exists and is a text node
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

sub lastIn($@)                                                                  #X Return the first node matching one of the named tags under the specified node.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  for(reverse $node->contents)                                                  # Search backwards through contents
   {return $_ if $tags{$_->tag};                                                # Find last tag with the specified name
   }
  return undef                                                                  # No such node
 }

sub lastInIndex($@)                                                             #CX Return the specified node if it is last in its index and optionally L<at|/at> the specified context else B<undef>
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Check the context if supplied
  my $parent = $node->parent;                                                   # Parent
  return undef unless $parent;                                                  # The root node is not first in anything
  my @c = $parent->c($node->tag);                                               # Index containing node
  @c && $c[-1] == $node ? $node : undef                                         # Last in index ?
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

#2 Next                                                                         # Find sibling nodes after the specified node.

sub next($@)                                                                    #BCX Return the node next to the specified node, optionally checking its context.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if $node->isLast;                                                # No node follows the last node at a level or the top most node
  my @c = $node->parent->contents;                                              # Content array of parent
  while(@c)                                                                     # Test until no more nodes left to test
   {my $c = shift @c;                                                           # Each node
    if ($c == $node)                                                            # Current node
     {my $n = shift @c;                                                         # Next node
      return undef if @context and !$n->at(@context);                           # Next node is not in specified context
      return $n;                                                                # Found node
     }
   }
  confess "Node not found in parent";                                           # Something wrong with parent/child relationship
 }

sub nextText($@)                                                              #CX Return the next node if it is a text node otherwise undef
 {my ($node, @context) = @_;                                                    # Node, optional context.
  my $n = &next(@_);                                                            # Next node
  $n ? $n->isText : undef                                                       # Test whether the next node exists and is a text node
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

sub nextOn($@)                                                                  # Step forwards as far as possible while remaining on nodes with the specified tags. In scalar context return the last such node reached or the starting node if no such steps are possible. In array context return the start node and any following matching nodes.
 {my ($node, @tags) = @_;                                                       # Start node, tags identifying nodes that can be step on to context.
  return $node if $node->isLast;                                                # Easy case
  my $parent = $node->parent;                                                   # Parent node
  confess "No parent" unless $parent;                                           # Not possible on a root node
  my @c = $parent->contents;                                                    # Content
  shift @c while @c and $c[0] != $node;                                         # Position on current node
  confess "Node not found in parent" unless @c;                                 # Something wrong with parent/child relationship
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags of acceptable commands
  if (wantarray)                                                                # Return node and following matching nodes if array wanted
   {my @a = (shift @c);
    push @a, shift @c while @c and $tags{$c[0]->tag};                           # Proceed forwards staying on acceptable tags
    @a                                                                          # Current node and matching following nodes
   }
  else
   {shift @c while @c > 1 and $tags{$c[1]->tag};                                # Proceed forwards but staying on acceptable tags
    return $c[0]                                                                # Current node or last acceptable tag reached while staying on acceptable tags
   }
 }

#2 Prev                                                                         # Find sibling nodes before the specified node.

sub prev($@)                                                                    #BCX Return the node before the specified node, optionally checking its context.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if $node->isFirst;                                               # No node follows the last node at a level or the top most node
  my @c = $node->parent->contents;                                              # Content array of parent
  while(@c)                                                                     # Test until no more nodes left to test
   {my $c = pop @c;                                                             # Each node
    if ($c == $node)                                                            # Current node
     {my $n = pop @c;                                                           # Prior node
      return undef if @context and !$n->at(@context);                           # Prior node is not in specified context
      return $n;                                                                # Found node
     }
   }
  confess "Node not found in parent";                                           # Something wrong with parent/child relationship
 }

sub prevText($@)                                                              #CX Return the previous node if it is a text node otherwise undef
 {my ($node, @context) = @_;                                                    # Node, optional context.
  my $p = &prev(@_);                                                            # Previous node
  $p ? $p->isText : undef                                                       # Test whether the previous node exists and is a text node
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

sub prevOn($@)                                                                  # Step backwards as far as possible while remaining on nodes with the specified tags. In scalar context return the last such node reached or the starting node if no such steps are possible. In array context return the start node and any preceding matching nodes.
 {my ($node, @tags) = @_;                                                       # Start node, tags identifying nodes that can be step on to context.
  return $node if $node->isFirst;                                               # Easy case
  my $parent = $node->parent;                                                   # Parent node
  confess "No parent" unless $parent;                                           # Not possible on a root node
  my @c = reverse $parent->contents;                                            # Content backwards
  shift @c while @c and $c[0] != $node;                                         # Position on current node
  confess "Node not found in parent" unless @c;                                 # Something wrong with parent/child relationship
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags of acceptable commands
  if (wantarray)                                                                # Return node and following matching nodes if array wanted
   {my @a = (shift @c);
    push @a, shift @c while @c and $tags{$c[0]->tag};                           # Proceed forwards staying on acceptable tags
    @a                                                                          # Current node and matching following nodes
   }
  else
   {shift @c while @c > 1 and $tags{$c[1]->tag};                                  # Proceed forwards but staying on acceptable tags
    return $c[0]                                                                  # Current node or last acceptable tag reached while staying on acceptable tags
   }
 }

#2 Upto                                                                         # Methods for moving up the parse tree from a node.

sub upto($@)                                                                    #X Return the first ancestral node that matches the specified context.
 {my ($node, @tags) = @_;                                                       # Start node, tags identifying context.
  for(my $p = $node; $p; $p = $p->parent)                                       # Go up
   {return $p if $p->at(@tags);                                                 # Return node which satisfies the condition
   }
  return undef                                                                  # Not found
 }

#1 Editing                                                                      # Edit the data in the parse tree and change the structure of the parse tree by L<wrapping and unwrapping|/Wrap and unwrap> nodes, by L<replacing|/Replace> nodes, by L<cutting and pasting|/Cut and Put> nodes, by L<concatenating|/Fusion> nodes, by L<splitting|/Fission> nodes or by adding new L<text|/Put as text> nodes.

sub change($$@)                                                                 #CIX Change the name of a node, optionally  confirming that the node is in a specified context and return the node.
 {my ($node, $name, @tags) = @_;                                                # Node, new name, optional: tags defining the required context.
  return undef if @tags and !$node->at(@tags);
  $node->tag = $name;                                                           # Change name
  if (my $parent = $node->parent) {$parent->indexNode}                          # Reindex parent
  $node
 }

#2 Cut and Put                                                                  # Move nodes around in the parse tree by cutting and pasting them.

sub cut($@)                                                                     #CI Cut out a node so that it can be reinserted else where in the parse tree.
 {my ($node, @context) = @_;                                                    # Node to cut out, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
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

sub putFirst($$@)                                                               #C Place a L<cut out|/cut> or L<new|/new> node at the front of the content of the specified node and return the new node.
 {my ($old, $new, @context) = @_;                                               # Original node, new node, optional context.
  return undef if @context and !$old->at(@context);                             # Not in specified context
  $new->parent and confess "Please cut out the node before moving it";          # The node must have be cut out first
  $new->parser == $new and $old->parser == $new and                             # Prevent a root node from being inserted into a sub tree
    confess "Recursive insertion attempted";
  $new->parser = $old->parser;                                                  # Assign the new node to the old parser
  unshift @{$old->content}, $new;                                               # Content array of original node
  $old->indexNode;                                                              # Rebuild indices for node
  $new                                                                          # Return the new node
 }

sub putLast($$@)                                                                #CI Place a L<cut out|/cut> or L<new|/new> node last in the content of the specified node and return the new node.
 {my ($old, $new, @context) = @_;                                               # Original node, new node, optional context.
  return undef if @context and !$old->at(@context);                             # Not in specified context
  $new->parent and confess "Please cut out the node before moving it";          # The node must have be cut out first
  $new->parser == $new and $old->parser == $new and                             # Prevent a root node from being inserted into a sub tree
    confess "Recursive insertion attempted";
  $new->parser = $old->parser;                                                  # Assign the new node to the old parser
  push @{$old->content}, $new;                                                  # Content array of original node
  $old->indexNode;                                                              # Rebuild indices for node
  $new                                                                          # Return the new node
 }

sub putNext($$@)                                                                #C Place a L<cut out|/cut> or L<new|/new> node just after the specified node and return the new node.
 {my ($old, $new, @context) = @_;                                               # Original node, new node, optional context.
  return undef if @context and !$old->at(@context);                             # Not in specified context
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

sub putPrev($$@)                                                                #C Place a L<cut out|/cut> or L<new|/new> node just before the specified node and return the new node.
 {my ($old, $new, @context) = @_;                                               # Original node, new node, optional context.
  return undef if @context and !$old->at(@context);                             # Not in specified context
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

sub concatenate($$@)                                                            #C Concatenate two successive nodes and return the target node.
 {my ($target, $source, @context) = @_;                                         # Target node to replace, node to concatenate, optional context of $target
  return undef if @context and !$target->at(@context);                          # Not in specified context
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

sub concatenateSiblings($@)                                                     #C Concatenate preceding and following nodes as long as they have the same tag as the specified node and return the specified node.
 {my ($node, @context) = @_;                                                    # Concatenate around this node, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
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

#2 Put as text                                                                  # Add text to the parse tree.

sub putFirstAsText($$@)                                                         #C Add a new text node first under a parent and return the new text node.
 {my ($node, $text, @context) = @_;                                             # The parent node, the string to be added which might contain unparsed Xml as well as text, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->putFirst(my $t = $node->newText($text));                               # Add new text node
  $t                                                                            # Return new node
 }

sub putLastAsText($$@)                                                          #C Add a new text node last under a parent and return the new text node.
 {my ($node, $text, @context) = @_;                                             # The parent node, the string to be added which might contain unparsed Xml as well as text, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->putLast(my $t = $node->newText($text));                                # Add new text node
  $t                                                                            # Return new node
 }

sub putNextAsText($$@)                                                          #C Add a new text node following this node and return the new text node.
 {my ($node, $text, @context) = @_;                                             # The parent node, the string to be added which might contain unparsed Xml as well as text, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->putNext(my $t = $node->newText($text));                                # Add new text node
  $t                                                                            # Return new node
 }

sub putPrevAsText($$@)                                                          #C Add a new text node following this node and return the new text node
 {my ($node, $text, @context) = @_;                                             # The parent node, the string to be added which might contain unparsed Xml as well as text, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->putPrev(my $t = $node->newText($text));                                # Add new text node
  $t                                                                            # Return new node
 }

#2 Break in and out                                                             # Break nodes out of nodes or push them back

sub breakIn($@)                                                                 #C Concatenate the nodes following and preceding the start node, unwrapping nodes whose tag matches the start node and return the start node. To concatenate only the preceding nodes, use L<breakInBackwards|/breakInBackwards>, to concatenate only the following nodes, use L<breakInForwards|/breakInForwards>.
 {my ($start, @context) = @_;                                                   # The start node, optional context.
  return undef if @context and !$start->at(@context);                           # Not in specified context
  $start->breakInBackwards;                                                     # The nodes before the start node
  $start->breakInForwards                                                       # The nodes following the start node
 }

sub breakInForwards($@)                                                         #C Concatenate the nodes following the start node, unwrapping nodes whose tag matches the start node and return the start node in the manner of L<breakIn|/breakIn>.
 {my ($start, @context) = @_;                                                   # The start node, optional context..
  return undef if @context and !$start->at(@context);                           # Not in specified context
  my $tag     = $start->tag;                                                    # The start node tag
  for my $item($start->contentAfter)                                            # Each item following the start node
   {$start->putLast($item->cut);                                                # Concatenate item
    if ($item->tag eq $tag)                                                     # Unwrap items with the same tag as the start node
     {$item->unwrap;                                                            # Start a new clone of the parent
     }
   }
  $start                                                                        # Return the start node
 }

sub breakInBackwards($@)                                                        #C Concatenate the nodes preceding the start node, unwrapping nodes whose tag matches the start node and return the start node in the manner of L<breakIn|/breakIn>.
 {my ($start, @context) = @_;                                                   # The start node, optional context..
  return undef if @context and !$start->at(@context);                           # Not in specified context
  my $tag     = $start->tag;                                                    # The start node tag
  for my $item(reverse $start->contentBefore)                                   # Each item preceding the start node reversing from the start node
   {$start->putFirst($item->cut);                                               # Concatenate item
    if ($item->tag eq $tag)                                                     # Unwrap items with the same tag as the start node
     {$item->unwrap;                                                            # Start a new clone of the parent
     }
   }
  $start                                                                        # Return the start node
 }

sub breakOut($@)                                                                # Lift child nodes with the specified tags under the specified parent node splitting the parent node into clones and return the cut out original node.
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

#2 Replace                                                                      # Replace nodes in the parse tree with nodes or text

sub replaceWith($$@)                                                            #C Replace a node (and all its content) with a L<new node|/newTag> (and all its content) and return the new node.
 {my ($old, $new, @context) = @_;                                               # Old node, new node, optional context..
  return undef if @context and !$old->at(@context);                             # Not in specified context
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

sub replaceWithText($$@)                                                        #C Replace a node (and all its content) with a new text node and return the new node.
 {my ($old, $text, @context) = @_;                                              # Old node, text of new node, optional context.
  return undef if @context and !$old->at(@context);                             # Not in specified context
  my $n = $old->replaceWith($old->newText($text));                              # Create a new text node, replace the old node and return the result
  $n
 }

sub replaceWithBlank($@)                                                        #C Replace a node (and all its content) with a new blank text node and return the new node.
 {my ($old, @context) = @_;                                                     # Old node, optional context.
  return undef if @context and !$old->at(@context);                             # Not in specified context
  my $n = $old->replaceWithText(' ');                                           # Create a new text node, replace the old node with a new blank text node and return the result
  $n
 }

sub replaceContentWith($@)                                                      # Replace the content of a node with the specified nodes and return the replaced content
 {my ($node, @content) = @_;                                                    # Node whose content is to be replaced, new content
  my @c = $node->contents;                                                      # Content
  $node->content = [@content];                                                  # Insert new content
  $node->indexNode;                                                             # Rebuild indices
  @c                                                                            # Return old content
 }

sub replaceContentWithText($@)                                                  # Replace the content of a node with the specified texts and return the replaced content
 {my ($node, @text) = @_;                                                       # Node whose content is to be replaced, texts to form new content
  my @c = $node->contents;                                                      # Content
  $node->content = [map {$node->newText($_)} @text];                            # Insert new content
  $node->indexNode;                                                             # Rebuild indices
  @c                                                                            # Return old content
 }

#2 Wrap and unwrap                                                              # Wrap and unwrap nodes to alter the depth of the parse tree

sub wrapWith($$@)                                                               #I Wrap the original node in a new node  forcing the original node down - deepening the parse tree - return the new wrapping node.
 {my ($old, $tag, %attributes) = @_;                                            # Node, tag for the new node or tag, attributes for the new node or tag.
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

sub wrapUp($@)                                                                  # Wrap the original node in a sequence of new nodes forcing the original node down - deepening the parse tree - return the array of wrapping nodes.
 {my ($node, @tags) = @_;                                                       # Node to wrap, tags to wrap the node with - with the uppermost tag rightmost.
  map {$node = $node->wrapWith($_)} @tags;                                      # Wrap up
 }

sub wrapDown($@)                                                                # Wrap the content of the specified node in a sequence of new nodes forcing the original node up - deepening the parse tree - return the array of wrapping nodes.
 {my ($node, @tags) = @_;                                                       # Node to wrap, tags to wrap the node with - with the uppermost tag rightmost.
  map {$node = $node->wrapContentWith($_)} @tags;                               # Wrap up
 }

sub wrapContentWith($$@)                                                        # Wrap the content of a node in a new node: the original node then contains just the new node which, in turn, contains all the content of the original node - returns the new wrapped node.
 {my ($old, $tag, %attributes) = @_;                                            # Node, tag for new node, attributes for new node.
  my $new = newTag(undef, $tag, %attributes);                                   # Create wrapping node
  $new->parser  = $old->parser;                                                 # Assign the new node to the old parser
  $new->content = $old->content;                                                # Transfer content
  $old->content = [$new];                                                       # Insert new node
  $new->indexNode;                                                              # Create indices for new node
  $old->indexNode;                                                              # Rebuild indices for old mode
  $new                                                                          # Return new node
 }

sub wrapTo($$$@)                                                                #X Wrap all the nodes starting and ending at the specified nodes with a new node with the specified tag and attributes and return the new node.  Return B<undef> if the start and end nodes are not siblings - they must have the same parent for this method to work.
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

sub unwrap($@)                                                                  #CIX Unwrap a node by inserting its content into its parent at the point containing the node and return the parent node.
 {my ($node, @context) = @_;                                                    # Node to unwrap, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
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

sub unwrapContentsKeepingText($@)                                               #CX Unwrap all the non text nodes below a specified node adding a leading and a trailing space to prevent unwrapped content from being elided and return the specified node else undef if not in the optional context.
 {my ($node, @context) = @_;                                                    # Node to unwrap, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->by(sub
   {if ($_->isText or $_ == $node) {}                                           # Keep interior text nodes
    else                                                                        # Unwrap interior node
     {$_->putPrevAsText(" ");                                                   # Separate from preceding content
      $_->putNextAsText(" ");                                                   # Separate from following content
      $node->addLabel($_->id) if $_->id;                                        # Transfer any id as a label to the specified node
      $_->copyLabels($node);                                                    # Transfer any labels to the specified node
      $_->unwrap;                                                               # Unwrap non text tag
     }
   });
  $node                                                                         # Return the node to show success
 }

#1 Contents                                                                     # The children of each node.

sub contents($@)                                                                #K Return a list of all the nodes contained by this node or an empty list if the node is empty or not in the optional context.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return () if @context and !$node->at(@context);                               # Optionally check the context
  my $c = $node->content;                                                       # Contents reference
  $c ? @$c : ()                                                                 # Contents as a list
 }

sub contentAfter($@)                                                            #K Return a list of all the sibling nodes following this node or an empty list if this node is last or not in the optional context.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return () if @context and !$node->at(@context);                               # Optionally check the context
  my $parent = $node->parent;                                                   # Parent
  return () if !$parent;                                                        # The uppermost node has no content beyond it
  my @c = $parent->contents;                                                    # Contents of parent
  while(@c)                                                                     # Test until no more nodes left to test
   {my $c = shift @c;                                                           # Position of current node
    return @c if $c == $node                                                    # Nodes beyond this node if it is the searched for node
   }
  confess "Node not found in parent";                                           # Something wrong with parent/child relationship
 }

sub contentBefore($@)                                                           #K Return a list of all the sibling nodes preceding this node or an empty list if this node is last or not in the optional context.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return () if @context and !$node->at(@context);                               # Optionally check the context
  my $parent = $node->parent;                                                   # Parent
  return () if !$parent;                                                        # The uppermost node has no content beyond it
  my @c = $parent->contents;                                                    # Contents of parent
  while(@c)                                                                     # Test until no more nodes left to test
   {my $c = pop @c;                                                             # Position of current node
    return @c if $c == $node                                                    # Nodes beyond this node if it is the searched for node
   }
  confess "Node not found in parent";                                           # Something wrong with parent/child relationship
 }

sub contentAsTags($@)                                                           #KX Return a string containing the tags of all the nodes contained by this node separated by single spaces or the empty string if the node is empty or undef if the node does not match the optional context.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join ' ', map {$_->tag} $node->contents
 }

sub contentAsTags2($@)                                                          #KX Return a string containing the tags of all the nodes contained by this node separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or undef if the node does not match the optional context.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join '', map {' '.$_->tag.' '} $node->contents
 }

sub contentAfterAsTags($@)                                                      #K Return a string containing the tags of all the sibling nodes following this node separated by single spaces or the empty string if the node is empty or undef if the node does not match the optional context.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join ' ', map {$_->tag} $node->contentAfter
 }

sub contentAfterAsTags2($@)                                                     #K Return a string containing the tags of all the sibling nodes following this node separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or undef if the node does not match the optional context.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join '', map {' '.$_->tag.' '} $node->contentAfter
 }

sub contentBeforeAsTags($@)                                                     #K Return a string containing the tags of all the sibling nodes preceding this node separated by single spaces or the empty string if the node is empty or undef if the node does not match the optional context.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join ' ', map {$_->tag} $node->contentBefore
 }

sub contentBeforeAsTags2($@)                                                    #K Return a string containing the tags of all the sibling nodes preceding this node separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or undef if the node does not match the optional context.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join '', map {' '.$_->tag.' '} $node->contentBefore
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

sub present($@)                                                                 # Return the count of the number of the specified tag types present immediately under a node or a hash {tag} = count for all the tags present under the node if no names are specified.
 {my ($node, @names) = @_;                                                      # Node, possible tags immediately under the node.
  reindexNode($node);                                                           # Create index for this node
  my %i = %{$node->indexes};                                                    # Index of child nodes
  return map {$_=>scalar @{$i{$_}}} keys %i unless @names;                      # Hash of all names
  grep {$i{$_}} @names                                                          # Count of tag types present
 }

sub isText($@)                                                                  #CX Return the specified node if this node is a text node, optionally in the specified context, else return B<undef>.
 {my ($node, @context) = @_;                                                    # Node to test, optional context
  if (@context)                                                                 # Optionally check context
   {my $p = $node->parent;                                                      # Parent
    return undef if !$p or !$p->at(@context);                                   # Parent must match context
   }
  $node->tag eq cdata ? $node : undef
 }

sub matchesText($$@)                                                            #CX Returns an array of regular expression matches in the text of the specified node if it is text node and it matches the specified regular expression and optionally has the specified context otherwise returns an empty array
 {my ($node, $re, @context) = @_;                                               # Node to test, regular expression, optional context
  return () unless $node->isText(@context);                                     # Check that this is a text node
  $node->text =~ m($re);                                                        # Return array of matches
 }

sub isBlankText($@)                                                             #CX Return the specified node if this node is a text node, optionally in the specified context, and contains nothing other than whitespace else return B<undef>. See also: L<isAllBlankText|/isAllBlankText>
 {my ($node, @context) = @_;                                                    # Node to test, optional context
  return undef if @context and !$node->at(@context);                            # Optionally check context
  $node->isText && $node->text =~ /\A\s*\Z/s ? $node : undef
 }

sub isAllBlankText($@)                                                          #CX Return the specified node if this node, optionally in the specified context, does not contain anything or if it does contain something it is all whitespace else return B<undef>. See also: L<bitsNodeTextBlank|/bitsNodeTextBlank>
 {my ($node, @context) = @_;                                                    # Node to test, optional context
  return undef if @context and !$node->at(@context);                            # Optionally check context
  if ($node->isText)                                                            # If this is a text node test the text of the node
   {return $node->text =~ m(\A\s*\Z)s ? $node : undef;
   }
  my @c = $node->contents;
  return $node if @c == 0;                                                      # No content
  return undef if @c  > 1;                                                      # Content other than text (adjacent text elements are merged so there can only be one)
  $node->stringContent =~ m(\A\s*\Z)s ? $node : undef
 }

sub bitsNodeTextBlank($)                                                        # Return a bit string that shows if there are any non text nodes, text nodes or blank text nodes under a node. An empty string is returned if there are no child nodes.
 {my ($node) = @_;                                                              # Node to test.
  my ($n, $t, $b) = (0,0,0);                                                    # Non text, text, blank text count
  my @c = $node->contents;                                                      # Contents of node
  return '' unless @c;                                                          # Return empty string if no children

  for(@c)                                                                       # Contents of node
   {if ($_->isText)                                                             # Text node
     {++$t;
      ++$b if $_->isBlankText;                                                  # Blank text node
     }
    else                                                                        # Non text node
     {++$n;
     }
   }
  join '', map {$_ ? 1 : 0} ($n, $t, $b);                                       # Multiple content so there must be some tags present because L<indexNode|/indexNode> concatenates contiguous text
 }

#1 Order                                                                        # Number and verify the order of nodes.

sub findByNumber($$)                                                            #X Find the node with the specified number as made visible by L<prettyStringNumbered|/prettyStringNumbered> in the parse tree containing the specified node and return the found node or B<undef> if no such node exists.
 {my ($node, $number) = @_;                                                     # Node in the parse tree to search, number of the node required.
  $node->parser->numbers->[$number]
 }

sub findByNumbers($@)                                                           # Find the nodes with the specified numbers as made visible by L<prettyStringNumbered|/prettyStringNumbered> in the parse tree containing the specified node and return the found nodes in a list with B<undef> for nodes that do not exist.
 {my ($node, @numbers) = @_;                                                    # Node in the parse tree to search, numbers of the nodes required.
  map {$node->findByNumber($_)} @numbers                                        # Node corresponding to each number
 }

sub numberNode($)                                                               #P Ensure that this node has a number.
 {my ($node) = @_;                                                              # Node
  my $n = $node->number = ++($node->parser->numbering);                         # Number node
  $node->parser->numbers->[$n] = $node                                          # Index the nodes in a parse tree
 }

sub numberTree($)                                                               # Number the nodes in a parse tree in pre-order so they are numbered in the same sequence that they appear in the source. You can see the numbers by printing the tree with L<prettyStringNumbered()|/prettyStringNumbered>.
 {my ($node) = @_;                                                              # Node
  my $parser = $node->parser;                                                   # Top of tree
  my $n = 0;                                                                    # Node number
  $parser->down(sub {$parser->numbers->[$_->number = ++$n] = $_});              # Number the nodes in a parse tree in pre-order so they are numbered in the same sequence that they appear in the source
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
 {my ($node, $target) = @_;                                                     # Node, target
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

sub commonAncestor($@)                                                          #X Find the most recent common ancestor of the specified nodes or B<undef> if there is no common ancestor.
 {my ($node, @nodes) = @_;                                                      # Node, @nodes
  return $node unless @nodes;                                                   # A single node is it its own common ancestor
  my @n = $node->ancestry;                                                      # The common ancestor so far
  for(@nodes)                                                                   # Each node
   {my @t = $_->ancestry;                                                       # Ancestry of latest node
    my @c;                                                                      # Common ancestors
    while(@n and @t and $n[-1] == $t[-1])                                       # Find common ancestors
     {push @c, pop @n; pop @t;                                                  # Save common ancestor
     }
    return undef unless @c;                                                     # No common ancestors
    @n = reverse @c;                                                            # Update common ancestry so far
   }
  $n[0]                                                                         # Most recent common ancestor
 }

sub ordered($@)                                                                 #X Return the first node if the specified nodes are all in order when performing a pre-ordered traversal of the parse tree else return B<undef>
 {my ($node, @nodes) = @_;                                                      # Node, following nodes.
  &disordered(@_) ? undef : $node
 }


#1 Table of Contents                                                            # Analyze and generate tables of contents

sub tocNumbers($@)                                                              # Table of Contents number the nodes in a parse tree.
 {my ($node, @match) = @_;                                                      # Node, optional list of tags to descend into e3se all tags will be descended into
  my $toc = {};
  my $match = @match ? {map{$_=>1} @match} : undef;                             # Tags to match or none
  my @context;

  my $tree; $tree = sub                                                         # Number the nodes below the current node
   {my ($node) = @_;
    my $n = 0;
    for($node->contents)                                                        # Each node belkow the current node
     {next if $match and !$match->{$_->tag};                                    # Skip non matching nodes
      push @context, ++$n;                                                      # New scope
      $toc->{"@context"} = $_;                                                  # Toc number for tag
      &$tree($_);                                                               # Number sub tree
      pop @context;                                                             # End scope
     }
   };

  &$tree($node);                                                                # Descend through the tree neumbering matching nodes
  $toc                                                                          # Return {toc number} = <tag>
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

sub deleteLabels($@)                                                            # Delete the specified labels in the specified node or all labels if no labels have are specified and return that node.
 {my ($node, @labels) = @_;                                                     # Node in parse tree, names of the labels to be deleted
  $node->{labels} = {} unless @labels;                                          # Delete all the labels if no labels supplied
  delete @{$node->{labels}}{@labels};                                           # Delete specified labels
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
  $source->deleteLabels;                                                        # Delete all the labels from the source
  $source
 }

#1 Operators                                                                    # Operator access to methods use the assign versions to avoid 'useless use of operator in void context' messages. Use the non assign versions to return the results of the underlying method call.  Thus '/' returns the wrapping node, whilst '/=' does not.  Assign operators always return their left hand side even though the corresponding method usually returns the modification on the right.

use overload
  '='        => sub{$_[0]},
  '**'       => \&opNew,
  '-X'       => \&opString,
  '@{}'      => \&opContents,
  '<='       => \&opAt,
  '>>'       => \&opPutFirst,
  '>>='      => \&opPutFirstAssign,
  '<<'       => \&opPutLast,
  '<<='      => \&opPutLastAssign,
  '>'        => \&opPutNext,
  '+='       => \&opPutNextAssign,
  '+'        => \&opPutNext,
  '<'        => \&opPutPrev,
  '-='       => \&opPutPrevAssign,
  '-'        => \&opPutPrev,
  'x='       => \&opBy,
  'x'        => \&opBy,
  '>='       => \&opGo,
  '*'        => \&opWrapContentWith,
  '*='       => \&opWrapContentWith,
  '/'        => \&opWrapWith,
  '/='       => \&opWrapWith,
  '%'        => \&opAttr,
  '--'       => \&opCut,
  '++'       => \&opUnwrap,
  "fallback" => 1;

sub opString($$)                                                                # -B: L<bitsNodeTextBlank|/bitsNodeTextBlank>\m-b: L<previous node|/prev>\m-c: L<next node|/next>\m-e: L<prettyStringEnd|/prettyStringEnd>\m-f: L<first node|/first>\m-l: L<last node|/last>\m-M: L<number|/number>\m-o: L<stringQuoted|/stringQuoted>\m-p: L<prettyString|/prettyString>\m-r: L<stringReplacingIdsWithLabels|/stringReplacingIdsWithLabels>\m-s: L<string|/string>\m-S : L<stringNode|/stringNode>\m-t : L<tag|/tag>\m-u: L<id|/id>\m-z: L<prettyStringNumbered|/prettyStringNumbered>.
 {my ($node, $op) = @_;                                                         # Node, monadic operator.
  $op or confess;
  return $node->bitsNodeTextBlank            if $op eq 'B';
  return $node->prev                         if $op eq 'b';
  return $node->next                         if $op eq 'c';
  return $node->prettyStringEnd              if $op eq 'e';
  return $node->first                        if $op eq 'f';
  return $node->last                         if $op eq 'l';
  return $node->number                       if $op eq 'M';
  return $node->stringQuoted                 if $op eq 'o';
  return $node->prettyString                 if $op eq 'p';
  return $node->stringReplacingIdsWithLabels if $op eq 'r';
  return $node->string                       if $op eq 's';
  return $node->stringNode                   if $op eq 'S';
  return $node->tag                          if $op eq 't';
  return $node->id                           if $op eq 'u';
  return $node->prettyStringNumbered         if $op eq 'z';
  confess "Unknown operator: $op";
 # A B C d g k M O R T w W x X
 }

sub opContents($)                                                               # @{} : content of a node.
 {my ($node) = @_;                                                              # Node.
  $node->content
 }

sub opAt($$)                                                                    # <= : Check that a node is in the context specified by the referenced array of words.
 {my ($node, $context) = @_;                                                    # Node, reference to array of words specifying the parents of the desired node.
  ref($context) =~ m/array/is or
    confess "Array of words required to specify the context";
  $node->at(@$context);
 }

sub opNew($$)                                                                   # ** : create a new node from the text on the right hand side: if the text contains a non word character \W the node will be create as text, else it will be created as a tag
 {my ($node, $text) = @_;                                                       # Node, name node of node to create or text of new text element
  return $text                if ref($text) eq __PACKAGE__;                     # The right hand side is already a node
  return $node->newTag($text) unless $text =~ m/\W/s;                           # Create a new node as tag
  $node->newText($text)                                                         # Create a new node as text if nothing lse worked
 }

sub opPutFirst($$)                                                              # >> : put a node or string first under a node and return the new node.
 {my ($node, $text) = @_;                                                       # Node, node or text to place first under the node.
  $node->putFirst(my $new = opNew($node, $text));
  $new
 }

sub opPutFirstAssign($$)                                                        # >>= : put a node or string first under a node.
 {my ($node, $text) = @_;                                                       # Node, node or text to place first under the node.
  opPutFirst($node, $text);
  $node
 }

sub opPutLast($$)                                                               # << : put a node or string last under a node and return the new node.
 {my ($node, $text) = @_;                                                       # Node, node or text to place last under the node.
  $node->putLast(my $new = opNew($node, $text));
  $new
 }

sub opPutLastAssign($$)                                                         # <<= : put a node or string last under a node.
 {my ($node, $text) = @_;                                                       # Node, node or text to place last under the node.
  opPutLast($node, $text);
  $node
 }

sub opPutNext($$)                                                               # > + : put a node or string after the specified node and return the new node.
 {my ($node, $text) = @_;                                                       # Node, node or text to place after the first node.
  $node->putNext(my $new = opNew($node, $text));
  $new
 }

sub opPutNextAssign($$)                                                         # += : put a node or string after the specified node.
 {my ($node, $text) = @_;                                                       # Node, node or text to place after the first node.
  opPutNext($node, $text);
  $node
 }

sub opPutPrev($$)                                                               # < - : put a node or string before the specified node and return the new node.
 {my ($node, $text) = @_;                                                       # Node, node or text to place before the first node.
  $node->putPrev(my $new = opNew($node, $text));
  $new
 }

sub opPutPrevAssign($$)                                                         # -= : put a node or string before the specified node,
 {my ($node, $text) = @_;                                                       # Node, node or text to place before the first node.
  opPutPrev($node, $text);
  $node
 }

sub opBy($$)                                                                    # x= : Traverse a parse tree in post-order.
 {my ($node, $code) = @_;                                                       # Parse tree, code to execute against each node.
  ref($code) =~ m/code/is or
    confess "sub reference required on right hand side";
  $node->by($code);
 }

sub opGo($$)                                                                    # >= : Search for a node via a specification provided as a reference to an array of words each number.  Each word represents a tag name, each number the index of the previous tag or zero by default.
 {my ($node, $go) = @_;                                                         # Node, reference to an array of search parameters.
  return $node->go(@$go) if ref($go);
  $node->go($go)
 }

sub opAttr($$)                                                                  # % : Get the value of an attribute of this node.
 {my ($node, $attr) = @_;                                                       # Node, reference to an array of words and numbers specifying the node to search for.
  return map {$node->attr($_)} @$attr if ref($attr);
  $node->attr($attr)
 }

#sub opSetTag($$)                                                                # + : Set the tag for a node.
# {my ($node, $tag) = @_;                                                        # Node, tag.
#  $node->change($tag)
# }
#
#sub opSetId($$)                                                                 # - : Set the id for a node.
# {my ($node, $id) = @_;                                                         # Node, id.
#  $node->setAttr(id=>$id);
# }

sub opWrapWith($$)                                                              # / : Wrap node with a tag, returning the wrapping node.
 {my ($node, $tag) = @_;                                                        # Node, tag.
  return $node->wrapUp(@$tag) if ref($tag);
  $node->wrapWith($tag)
 }

sub opWrapContentWith($$)                                                       # * : Wrap content with a tag, returning the wrapping node.
 {my ($node, $tag) = @_;                                                        # Node, tag.
  return $node->wrapDown(@$tag) if ref($tag);
  $node->wrapContentWith($tag)
 }

sub opCut($)                                                                    # -- : Cut out a node.
 {my ($node) = @_;                                                              # Node.
  $node->cut
 }

sub opUnwrap($)                                                                 # ++ : Unwrap a node.
 {my ($node) = @_;                                                              # Node.
  $node->unwrap
 }

#1 Statistics                                                                   # Statistics describing the parse tree.

sub count($@)                                                                   # Return the count of the number of instances of the specified tags under the specified node, either by tag in array context or in total in scalar context.
 {my ($node, @names) = @_;                                                      # Node, possible tags immediately under the node.
  if (wantarray)                                                                # In array context return the count for each tag specified
   {my @c;                                                                      # Count for the corresponding tag
    reindexNode($node);                                                         # Create index for this node
    my %i = %{$node->indexes};                                                  # Index of child nodes
    for(@names)
     {if (my $i = $i{$_}) {push @c, scalar(@$i)} else {push @c, 0};             # Save corresponding count
     }
    return @c;                                                                  # Return count for each tag specified
   }
  else                                                                          # In scalar context count the total number of instances of the named tags
   {if (@names)
     {my $c = 0;                                                                # Tag count
      reindexNode($node);                                                       # Create index for this node
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
  $node->by(sub{++$n});                                                         # Count tags including CDATA
  $n                                                                            # Number of tags encountered
 }

sub countTagNames($;$)                                                          # Return a reference to a hash showing the number of instances of each tag on and below the specified node.
 {my ($node, $count) = @_;                                                      # Node, count of tags so far.
  $count //= {};                                                                # Counts
  $$count{$node->tag}++;                                                        # Add current tag
  $_->countTagNames($count) for $node->contents;                                # Each contained node
  $count                                                                        # Count
 }

sub countAttrNames($;$)                                                         # Return a reference to a hash showing the number of instances of each attribute on and below the specified node.
 {my ($node, $count) = @_;                                                      # Node, count of attributes so far.
  $count //= {};                                                                # Counts
  $$count{$_}++ for $node->getAttrs;                                            # Attributes from current tag
  $_->countAttrNames($count) for $node->contents;                               # Each contained node
  $count                                                                        # Count
 }

sub countAttrValues($;$)                                                        # Return a reference to a hash showing the number of instances of each attribute value on and below the specified node.
 {my ($node, $count) = @_;                                                      # Node, count of attributes so far.
  $count //= {};                                                                # Counts
  $count->{$node->attr($_)}++ for $node->getAttrs;                              # Attribute values from current tag
  $_->countAttrValues($count) for $node->contents;                              # Each contained node
  $count                                                                        # Count
 }

sub countOutputClasses($$)                                                      # Count instances of outputclass attributes
 {my ($node, $count) = @_;                                                      # Node, count so far.
  $count //= {};                                                                # Counts
  my $a = $node->attr(qw(outputclass));                                         # Outputclass attribute
  $$count{$a}++ if $a ;                                                         # Add current output class
  &countOutputClasses($_, $count) for $node->contents;                          # Each contained node
  $count                                                                        # Count
 }


#1 Debug                                                                        # Debugging methods

sub printAttributes($)                                                          #P Print the attributes of a node.
 {my ($node) = @_;                                                              # Node whose attributes are to be printed.
  my %a = %{$node->attributes};                                                 # Attributes
  my $s = '';
  for(sort keys %a)
   {next unless defined(my $v = $a{$_});
    $s .= $_.'="'.$v.'" ';                                                      # Attributes enclosed in "" in alphabetical order
   }
  chop($s);
  length($s) ? ' '.$s : '';
 }

sub printAttributesReplacingIdsWithLabels($)                                    #P Print the attributes of a node replacing the id with the labels.
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

  if ($flags =~ m/C/s)                                                          # Context flag for a method that returns a single node or undef if in the wrong context
   {push @doc, <<'END';
Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.
END
   }
  if ($flags =~ m/K/s)                                                          # Context flag for a method that returns an array of nodes or the empty array if in the wrong context
   {push @doc, <<'END';
Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns an empty list B<()> immediately.
END
   }

  if ($flags =~ m/B/s)                                                          # Skip blank text
   {push @doc, <<END;
Use B<$b> to skip a (rare) initial blank text CDATA. Use B<$x> to die rather
then receive a returned B<undef> or false result.
END
    push @code, <<END;
sub $b
 {my \$r = &$method(\$_[0]);
  return undef unless \$r;
  if (\$r->isBlankText)
   {shift \@_;
    return &$m(\$r, \@_)
   }
  else
   {return &$m(\@_);
   }
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

Data::Edit::Xml - Edit data held in the XML format.

=head1 Synopsis

Create a L<new|/new> XML parse tree:

  my $a = Data::Edit::Xml::new("<a><b><c/></b><d><c/></d></a>");

L<Print|/Print> the parse tree:

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

  $a -> by(sub {$_ -> cut(qw(c b a))})

In B<chained exit> style:

  $a -> byX(sub {$_ -> at(qw(c b a)) -> cut});

In B<operator> style:

  $a x= sub {--$_ if $_ <= [qw(c b a)]};

L<Print|/Print> the transformed parse tree

 say STDERR -p $a;

to get:

  <a>
    <b/>
    <d>
      <c/>
    </d>
  </a>


=head2 Bullets to unordered list

To transform a series of bullets in to <ul> <li> ...  first parse the input XML:

 {my $a = Data::Edit::Xml::new(<<END);
<a>
<p>• Minimum 1 number</p>
<p>•   No leading, trailing, or embedded spaces</p>
<p>• Not case-sensitive</p>
</a>
END

Traverse the resulting parse tree, changing bullets to <li> and either wrapping
with <ul> or appending to a previous <ul>

  $a->by(sub                                                                    # Bulleted list to <ul>
   {if ($_->at(qw(p)))                                                          # <p>
     {if (my $t = $_->containsSingleText)                                       # <p> with single text
       {if ($t->text =~ s(\A\x{2022}\s*) ()s)                                   # Starting with a bullet
         {$_->change(qw(li));                                                   # <p> to <li>
          if (my $p = $_->prev(qw(ul)))                                         # Previous element is ul?
           {$p->putLast($_->cut);                                               # Put in preceding list or create a new list
           }
          else
           {$_->wrapWith(qw(ul))
           }
         }
       }
     }
   });

To get:

  <a>
    <ul>
      <li>Minimum 1 number</li>
      <li>No leading, trailing, or embedded spaces</li>
      <li>Not case-sensitive</li>
    </ul>
  </a>

=head2 DocBook to Dita

To transform some DocBook XML into Dita:

  use Data::Edit::Xml;

  # Parse the DocBook XML

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

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Immediately useful methods

These methods are the ones most likely to be of immediate use to anyone using
this module for the first time:


L<at|/at>

Confirm that the node has the specified L<ancestry|/ancestry> and return the starting node if it does else B<undef>. Ancestry is specified by providing the expected tags that the parent, the parent's parent etc. must match at each level. If B<undef> is specified then any tag is assumed to match at that level. If a regular expression is specified then the current parent node tag must match the regular expression at that level. If all supplied tags match successfully then the starting node is returned else B<undef>

L<atOrBelow|/atOrBelow>

Confirm that the node or one of its ancestors has the specified context as recognized by L<at|/at> and return the first node that matches the context or B<undef> if none do.

L<attr :lvalue|/attr :lvalue>

Return the value of an attribute of the current node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

L<by|/by>

Post-order traversal of a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

L<change|/change>

Change the name of a node, optionally  confirming that the node is in a specified context and return the node.

L<cut|/cut>

Cut out a node so that it can be reinserted else where in the parse tree.

L<go|/go>

Return the node reached from the specified node via the specified L<path|/path>: (index positionB<?>)B<*> where index is the tag of the next node to be chosen and position is the optional zero based position within the index of those tags under the current node. Position defaults to zero if not specified. Position can also be negative to index back from the top of the index array. B<*> can be used as the last position to retrieve all nodes with the final tag.

L<new|/new>

New parse - call this method statically as in Data::Edit::Xml::new(file or string) B<or> with no parameters and then use L</input>, L</inputFile>, L</inputString>, L</errorFile>  to provide specific parameters for the parse, then call L</parse> to perform the parse and return the parse tree.

L<prettyString|/prettyString>

Return a readable string representing a node of a parse tree and all the nodes below it. Or use L<-p|/opString> $node

L<putLast|/putLast>

Place a L<cut out|/cut> or L<new|/new> node last in the content of the specified node and return the new node.

L<unwrap|/unwrap>

Unwrap a node by inserting its content into its parent at the point containing the node and return the parent node.

L<wrapWith|/wrapWith>

Wrap the original node in a new node  forcing the original node down - deepening the parse tree - return the new wrapping node.




=head1 Construction

Create a parse tree, either by parsing a L<file or string|/file or string>, or, L<node by node|/Node by Node>, or, from another L<parse tree|/Parse tree>

=head2 File or String

Construct a parse tree from a file or a string

=head3 new($)

New parse - call this method statically as in Data::Edit::Xml::new(file or string) B<or> with no parameters and then use L</input>, L</inputFile>, L</inputString>, L</errorFile>  to provide specific parameters for the parse, then call L</parse> to perform the parse and return the parse tree.

     Parameter          Description          
  1  $fileNameOrString  File name or string  

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  ok -p $x eq <<END;
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  

This is a static method and so should be invoked as:

  Data::Edit::Xml::new


=head3 content :lvalue

Content of command: the nodes immediately below this node in the order in which they appeared in the source text, see also L</Contents>.


=head3 numbers :lvalue

Nodes by number.


=head3 attributes :lvalue

The attributes of this node, see also: L</Attributes>.  The frequently used attributes: class, id, href, outputclass can be accessed by an lvalue method as in: $node->id = 'c1'.


=head3 conditions :lvalue

Conditional strings attached to a node, see L</Conditions>.


=head3 indexes :lvalue

Indexes to sub commands by tag in the order in which they appeared in the source text.


=head3 labels :lvalue

The labels attached to a node to provide addressability from other nodes, see: L</Labels>.


=head3 errorsFile :lvalue

Error listing file. Use this parameter to explicitly set the name of the file that will be used to write an parse errors to. By default this file is named: B<zzzParseErrors/out.data>.


=head3 inputFile :lvalue

Source file of the parse if this is the parser root node. Use this parameter to explicitly set the file to be parsed.


=head3 input :lvalue

Source of the parse if this is the parser root node. Use this parameter to specify some input either as a string or as a file name for the parser to convert into a parse tree.


=head3 inputString :lvalue

Source string of the parse if this is the parser root node. Use this parameter to explicitly set the string to be parsed.


=head3 number :lvalue

Number of this node, see L<findByNumber|/findByNumber>.


=head3 numbering :lvalue

Last number used to number a node in this parse tree.


=head3 parent :lvalue

Parent node of this node or undef if the oarser root node. See also L</Traversal> and L</Navigation>. Consider as read only.


=head3 parser :lvalue

Parser details: the root node of a tree is the parse node for that tree. Consider as read only.


=head3 tag :lvalue

Tag name for this node, see also L</Traversal> and L</Navigation>. Consider as read only.


=head3 text :lvalue

Text of this node but only if it is a text node, i.e. the tag is cdata() <=> L</isText> is true.


=head3 cdata()

The name of the tag to be used to represent text - this tag must not also be used as a command tag otherwise the parser will L<confess|http://perldoc.perl.org/Carp.html#SYNOPSIS/>.


Example:


  ok Data::Edit::Xml::cdata eq q(CDATA);
  

=head3 parse($)

Parse input XML specified via: L<inputFile|/inputFile>, L<input|/input> or L<inputString|/inputString>.

     Parameter  Description                
  1  $parser    Parser created by L</new>  

Example:


  my $x = Data::Edit::Xml::new;
  
  $x->inputString = <<END;
  <a id="aa"><b id="bb"><c id="cc"/></b></a>
  END
  
  $x->parse;
  
  ok -p $x eq <<END;
  <a id="aa">
    <b id="bb">
      <c id="cc"/>
    </b>
  </a>
  END
  

=head2 Node by Node

Construct a parse tree node by node.

=head3 newText($$)

Create a new text node.

     Parameter  Description                    
  1  undef      Any reference to this package  
  2  $text      Content of new text node       

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
  

=head3 newTag($$%)

Create a new non text node.

     Parameter    Description                    
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
  

=head3 newTree($%)

Create a new tree.

     Parameter    Description                                         
  1  $command     The name of the root node in the tree               
  2  %attributes  Attributes of the root node in the tree as a hash.  

Example:


  my $x = Data::Edit::Xml::newTree("a", id=>1, class=>"aa");
  
  ok -s $x eq '<a class="aa" id="1"/>';
  

=head3 replaceSpecialChars($)

Replace < > " with &lt; &gt; &quot;  Larry Wall's excellent L<Xml parser|https://metacpan.org/pod/XML::Parser/> unfortunately replaces &lt; &gt; &quot; &amp; etc. with their expansions in text by default and does not seem to provide an obvious way to stop this behavior, so we have to put them back gain using this method. Worse, we cannot decide whether to replace & with &amp; or leave it as is: consequently you might have to examine the instances of & in your output text and guess based on the context.

     Parameter  Description           
  1  $string    String to be edited.  

Example:


  ok Data::Edit::Xml::replaceSpecialChars(q(<">)) eq "&lt;&quot;&gt;";
  

=head2 Parse tree

Construct a parse tree from another parse tree

=head3 renew($@)

Returns a renewed copy of the parse tree, optionally checking that the starting node is in a specified context: use this method if you have added nodes via the L</"Put as text"> methods and wish to add them to the parse tree.  Returns the starting node of the new parse tree or B<undef> if the optional context constraint was not supplied but not satisfied.

     Parameter  Description         
  1  $node      Node to renew from  
  2  @context   Optional context    

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $a = Data::Edit::Xml::new("<a/>");
  
  $a->putFirstAsText(qq(<b/>));
  
  ok !$a->go(q(b));
  
  my $A = $a->renew;
  
  ok -t $A->go(q(b)) eq q(b)
  

=head3 clone($@)

Return a clone of the parse tree optionally checking that the starting node is in a specified context: the parse tree is cloned without converting it to string and reparsing it so this method will not L<renew|/renew> any nodes added L<as text|/Put as text>.  Returns the starting node of the new parse tree or B<undef> if the optional context constraint was not supplied but not satisfied.

     Parameter  Description         
  1  $node      Node to clone from  
  2  @context   Optional context    

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $a = Data::Edit::Xml::new("<a> </a>");
  
  my $A = $a->clone;
  
  ok -s $A eq q(<a/>);
  
  ok $a->equals($A);
  

=head3 equals($$)

Return the first node if the two parse trees are equal, else B<undef> if they are not equal.

     Parameter  Description    
  1  $node1     Parse tree 1   
  2  $node2     Parse tree 2.  

Example:


  my $a = Data::Edit::Xml::new("<a> </a>");
  
  my $A = $a->clone;
  
  ok -s $A eq q(<a/>);
  
  ok $a->equals($A);
  

Use B<equalsX> to execute L<equals|/equals> but B<die> 'equals' instead of returning B<undef>

=head3 save($$)

Save a copy of the parse tree to a file which can be L<restored|/restore> and return the saved node.

     Parameter  Description  
  1  $node      Parse tree   
  2  $file      File.        

Example:


  $y->save($f);
  
  my $Y = Data::Edit::Xml::restore($f);
  
  ok $Y->equals($y);
  

=head3 restore($)

Return a parse tree from a copy saved in a file by L</save>.

     Parameter  Description  
  1  $file      File         

Example:


  $y->save($f);
  
  my $Y = Data::Edit::Xml::restore($f);
  
  ok $Y->equals($y);
  

Use B<restoreX> to execute L<restore|/restore> but B<die> 'restore' instead of returning B<undef>

This is a static method and so should be invoked as:

  Data::Edit::Xml::restore


=head1 Print

Create a string representation of the parse tree with optional selection of nodes via L<conditions|/Conditions>.

Normally use the methods in L<Pretty|/Pretty> to format the XML in a readable yet reparseable manner; use L<Dense|/Dense> string to format the XML densely in a reparseable manner; use the other methods to produce unreparseable strings conveniently formatted to assist various specialized operations such as debugging CDATA, using labels or creating tests. A number of the L<file test operators|/opString> can also be conveniently used to print parse trees in these formats.

=head2 Pretty

Pretty print the parse tree.

=head3 prettyString($$)

Return a readable string representing a node of a parse tree and all the nodes below it. Or use L<-p|/opString> $node

     Parameter  Description      
  1  $node      Start node       
  2  $depth     Optional depth.  

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
  

=head3 prettyStringNumbered($$)

Return a readable string representing a node of a parse tree and all the nodes below it with a L<number|/number> attached to each tag. The node numbers can then be used as described in L<Order|/Order> to monitor changes to the parse tree.

     Parameter  Description      
  1  $node      Start node       
  2  $depth     Optional depth.  

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
  
  $a->numberTree;
  
  ok $a->prettyStringNumbered eq <<END;
  <a id="1">
    <b id="2">
      <A id="3"/>
      <B id="4"/>
    </b>
    <c id="5">
      <C id="6"/>
      <D id="7"/>
    </c>
  </a>
  END
  

=head3 prettyStringCDATA($$)

Return a readable string representing a node of a parse tree and all the nodes below it with the text fields wrapped with <CDATA>...</CDATA>.

     Parameter  Description      
  1  $node      Start node       
  2  $depth     Optional depth.  

Example:


  my $a = Data::Edit::Xml::new("<a><b>A</b></a>");
  
  my $b = $a->first;
  
  $b->first->replaceWithBlank;
  
  ok $a->prettyStringCDATA eq <<END;
  <a>
      <b><CDATA> </CDATA></b>
  </a>
  END
  

=head3 prettyStringContent($)

Return a readable string representing all the nodes below a node of a parse tree.

     Parameter  Description  
  1  $node      Start node.  

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
  
  ok $a->prettyStringContent eq <<END;
  <b>
    <A/>
    <B/>
  </b>
  <c>
    <C/>
    <D/>
  </c>
  END
  

=head3 prettyStringContentNumbered($)

Return a readable string representing all the nodes below a node of a parse tree with numbering added.

     Parameter  Description  
  1  $node      Start node.  

Example:


  my $s = <<END;
  <a>
    <b>
      <c/>
    </b>
  </a>
  END
  
  my $a = Data::Edit::Xml::new($s);
  
  $a->numberTree;
  
  ok $a->prettyStringContentNumbered eq <<END;
  <b id="2">
    <c id="3"/>
  </b>
  END
  
  ok $a->go(qw(b))->prettyStringContentNumbered eq <<END;
  <c id="3"/>
  END
  

=head2 Dense

Print the parse tree.

=head3 string($)

Return a dense string representing a node of a parse tree and all the nodes below it. Or use L<-s|/opString> $node

     Parameter  Description  
  1  $node      Start node.  

Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  ok -s $x eq '<a><b><c id="42"/></b><d><e/></d></a>';
  

=head3 stringQuoted($)

Return a quoted string representing a parse tree a node of a parse tree and all the nodes below it. Or use L<-o|/opString> $node

     Parameter  Description  
  1  $node      Start node   

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
  
  ok $a->stringQuoted eq q('<a><b><A/><B/></b><c><C/><D/></c></a>');
  

=head3 stringReplacingIdsWithLabels($)

Return a string representing the specified parse tree with the id attribute of each node set to the L<Labels|/Labels> attached to each node.

     Parameter  Description  
  1  $node      Start node.  

Example:


  ok -r $x eq '<a><b id="1, 2, 3, 4"><c id="5, 6, 7, 8"/></b></a>';
  
  my $s = $x->stringReplacingIdsWithLabels;
  
  ok $s eq '<a><b id="1, 2, 3, 4"><c id="5, 6, 7, 8"/></b></a>';
  

=head3 stringContent($)

Return a string representing all the nodes below a node of a parse tree.

     Parameter  Description  
  1  $node      Start node.  

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
  
  ok $a->stringContent eq "<b><A/><B/></b><c><C/><D/></c>";
  

=head3 stringNode($)

Return a string representing a node showing the attributes, labels and node number

     Parameter  Description  
  1  $node      Node.        

Example:


  ok -r $x eq '<a><b><c/></b></a>';
  
  my $b = $x->go(q(b));
  
  $b->addLabels(1..2);
  
  $b->addLabels(3..4);
  
  ok -r $x eq '<a><b id="1, 2, 3, 4"><c/></b></a>';
  
  $b->numberTree;
  
  ok -S $b eq "b(2) 0:1 1:2 2:3 3:4";
  

=head2 Conditions

Print a subset of the the parse tree determined by the conditions attached to it.

=head3 stringWithConditions($@)

Return a string representing a node of a parse tree and all the nodes below it subject to conditions to select or reject some nodes.

     Parameter    Description                              
  1  $node        Start node                               
  2  @conditions  Conditions to be regarded as in effect.  

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b/>
    <c/>
  </a>
  END
  
  my $b = $x >= 'b';
  
  my $c = $x >= 'c';
  
  $b->addConditions(qw(bb BB));
  
  $c->addConditions(qw(cc CC));
  
  ok $x->stringWithConditions         eq '<a><b/><c/></a>';
  
  ok $x->stringWithConditions(qw(bb)) eq '<a><b/></a>';
  
  ok $x->stringWithConditions(qw(cc)) eq '<a><c/></a>';
  

=head3 addConditions($@)

Add conditions to a node and return the node.

     Parameter    Description         
  1  $node        Node                
  2  @conditions  Conditions to add.  

Example:


  $b->addConditions(qw(bb BB));
  
  ok join(' ', $b->listConditions) eq 'BB bb';
  

=head3 deleteConditions($@)

Delete conditions applied to a node and return the node.

     Parameter    Description         
  1  $node        Node                
  2  @conditions  Conditions to add.  

Example:


  ok join(' ', $b->listConditions) eq 'BB bb';
  
  $b->deleteConditions(qw(BB));
  
  ok join(' ', $b->listConditions) eq 'bb';
  

=head3 listConditions($)

Return a list of conditions applied to a node.

     Parameter  Description  
  1  $node      Node.        

Example:


  $b->addConditions(qw(bb BB));
  
  ok join(' ', $b->listConditions) eq 'BB bb';
  

=head1 Attributes

Get or set the attributes of nodes in the parse tree. L<Well Known Attributes|/Well Known Attributes>  can be set directly via L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>s. To set or get the values of other attributes use L<Get or Set Attributes|/Get or Set Attributes>. To delete or rename attributes see: L<Other Operations on Attributes|/Other Operations on Attributes>.

=head2 Well Known Attributes

Get or set these attributes of nodes via L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>s as in:

  $x->href = "#ref";

=head3 class :lvalue

Attribute B<class> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 guid :lvalue

Attribute B<guid> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 href :lvalue

Attribute B<href> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 id :lvalue

Attribute B<id> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 navtitle :lvalue

Attribute B<navtitle> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 otherprops :lvalue

Attribute B<otherprops> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 outputclass :lvalue

Attribute B<outputclass> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 props :lvalue

Attribute B<props> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 style :lvalue

Attribute B<style> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 type :lvalue

Attribute B<type> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head2 Get or Set Attributes

Get or set the attributes of nodes.

=head3 attr :lvalue($$)

Return the value of an attribute of the current node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

     Parameter   Description         
  1  $node       Node in parse tree  
  2  $attribute  Attribute name.     

=head3 setAttr($@)

Set the values of some attributes in a node and return the node.

     Parameter  Description                   
  1  $node      Node in parse tree            
  2  %values    (attribute name=>new value)*  

Example:


  ok -s $x eq '<a number="2"/>';
  
  $x->setAttr(first=>1, second=>2, last=>undef);
  
  ok -s $x eq '<a first="1" number="2" second="2"/>';
  

=head2 Other Operations on Attributes

Perform operations other than get or set on the attributes of a node

=head3 attrs($@)

Return the values of the specified attributes of the current node as a list

     Parameter    Description         
  1  $node        Node in parse tree  
  2  @attributes  Attribute names.    

Example:


  ok -s $x eq '<a first="1" number="2" second="2"/>';
  
  is_deeply [$x->attrs(qw(third second first ))], [undef, 2, 1];
  

=head3 attrCount($)

Return the number of attributes in the specified node.

     Parameter  Description          
  1  $node      Node in parse tree.  

Example:


  ok -s $x eq '<a first="1" number="2" second="2"/>';
  
  ok $x->attrCount == 3;
  

=head3 getAttrs($)

Return a sorted list of all the attributes on this node.

     Parameter  Description          
  1  $node      Node in parse tree.  

Example:


  ok -s $x eq '<a first="1" number="2" second="2"/>';
  
  is_deeply [$x->getAttrs], [qw(first number second)];
  

=head3 deleteAttr($$$)

Delete the attribute, optionally checking its value first and return the node.

     Parameter  Description                               
  1  $node      Node                                      
  2  $attr      Attribute name                            
  3  $value     Optional attribute value to check first.  

Example:


  ok -s $x eq '<a delete="me" number="2"/>';
  
  $x->deleteAttr(qq(delete));
  
  ok -s $x eq '<a number="2"/>';
  

=head3 deleteAttrs($@)

Delete any attributes mentioned in a list without checking their values and return the node.

     Parameter  Description                
  1  $node      Node                       
  2  @attrs     Attribute names to delete  

Example:


  ok -s $x eq '<a first="1" number="2" second="2"/>';
  
  $x->deleteAttrs(qw(first second third number));
  
  ok -s $x eq '<a/>';
  

=head3 renameAttr($$$)

Change the name of an attribute regardless of whether the new attribute already exists and return the node.

     Parameter  Description              
  1  $node      Node                     
  2  $old       Existing attribute name  
  3  $new       New attribute name.      

Example:


  ok $x->printAttributes eq qq( no="1" word="first");
  
  $x->renameAttr(qw(no number));
  
  ok $x->printAttributes eq qq( number="1" word="first");
  

=head3 changeAttr($$$)

Change the name of an attribute unless it has already been set and return the node.

     Parameter  Description              
  1  $node      Node                     
  2  $old       Existing attribute name  
  3  $new       New attribute name.      

Example:


  ok $x->printAttributes eq qq( number="1" word="first");
  
  $x->changeAttr(qw(number word));
  
  ok $x->printAttributes eq qq( number="1" word="first");
  

=head3 renameAttrValue($$$$$)

Change the name and value of an attribute regardless of whether the new attribute already exists and return the node.

     Parameter  Description               
  1  $node      Node                      
  2  $old       Existing attribute name   
  3  $oldValue  Existing attribute value  
  4  $new       New attribute name        
  5  $newValue  New attribute value.      

Example:


  ok $x->printAttributes eq qq( number="1" word="first");
  
  $x->renameAttrValue(qw(number 1 numeral I));
  
  ok $x->printAttributes eq qq( numeral="I" word="first");
  

=head3 changeAttrValue($$$$$)

Change the name and value of an attribute unless it has already been set and return the node.

     Parameter  Description               
  1  $node      Node                      
  2  $old       Existing attribute name   
  3  $oldValue  Existing attribute value  
  4  $new       New attribute name        
  5  $newValue  New attribute value.      

Example:


  ok $x->printAttributes eq qq( numeral="I" word="first");
  
  $x->changeAttrValue(qw(word second greek mono));
  
  ok $x->printAttributes eq qq( numeral="I" word="first");
  

=head1 Traversal

Traverse the parse tree in various orders applying a B<sub> to each node.

=head2 Post-order

This order allows you to edit children before their parents

=head3 by($$@)

Post-order traversal of a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

     Parameter  Description                    
  1  $node      Starting node                  
  2  $sub       Sub to call for each sub node  
  3  @context   Accumulated context.           

Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  my $s; $x->by(sub{$s .= $_->tag}); ok $s eq "cbeda"
  

=head3 byX($$)

Post-order traversal of a parse tree calling the specified B<sub> at each node as long as this sub does not L<die|http://perldoc.perl.org/functions/die.html>. The traversal is halted if the called sub does  L<die|http://perldoc.perl.org/functions/die.html> on any call with the reason in L<?@|http://perldoc.perl.org/perlvar.html#Error-Variables> The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry> up to the node on which this sub was called. A reference to the current node is also made available via B<$_>. Regardless of the outcome of calling B<sub>, byX returns the start node.

     Parameter  Description  
  1  $node      Start node   
  2  $sub       Sub to call  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  my $s; $x->byX(sub{$s .= $_->tag}); ok $s eq "cbeda"
  

=head3 byReverse($$@)

Reverse post-order traversal of a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

     Parameter  Description                    
  1  $node      Starting node                  
  2  $sub       Sub to call for each sub node  
  3  @context   Accumulated context.           

Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  my $s; $x->byReverse(sub{$s .= $_->tag}); ok $s eq "edcba"
  

=head3 byReverseX($$@)

Reverse post-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

     Parameter  Description                    
  1  $node      Starting node                  
  2  $sub       Sub to call for each sub node  
  3  @context   Accumulated context.           

Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  my $s; $x->byReverse(sub{$s .= $_->tag}); ok $s eq "edcba"
  

=head2 Pre-order

This order allows you to edit children after their parents

=head3 down($$@)

Pre-order traversal down through a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

     Parameter  Description                    
  1  $node      Starting node                  
  2  $sub       Sub to call for each sub node  
  3  @context   Accumulated context.           

Example:


  my $s; $x->down(sub{$s .= $_->tag}); ok $s eq "abcde"
  

=head3 downX($$)

Pre-order traversal of a parse tree calling the specified B<sub> at each node as long as this sub does not L<die|http://perldoc.perl.org/functions/die.html>. The traversal is halted if the called sub does  L<die|http://perldoc.perl.org/functions/die.html> on any call with the reason in L<?@|http://perldoc.perl.org/perlvar.html#Error-Variables> The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry> up to the node on which this sub was called. A reference to the current node is also made available via B<$_>. Regardless of the outcome of calling B<sub>, byX returns the start node.

     Parameter  Description  
  1  $node      Start node   
  2  $sub       Sub to call  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $s; $x->down(sub{$s .= $_->tag}); ok $s eq "abcde"
  

=head3 downReverse($$@)

Reverse pre-order traversal down through a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

     Parameter  Description                    
  1  $node      Starting node                  
  2  $sub       Sub to call for each sub node  
  3  @context   Accumulated context.           

Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  my $s; $x->downReverse(sub{$s .= $_->tag}); ok $s eq "adebc"
  

=head3 downReverseX($$@)

Reverse pre-order traversal down through a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

     Parameter  Description                    
  1  $node      Starting node                  
  2  $sub       Sub to call for each sub node  
  3  @context   Accumulated context.           

Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  my $s; $x->downReverse(sub{$s .= $_->tag}); ok $s eq "adebc"
  

=head2 Pre and Post order

Visit the parent first, then the children, then the parent again.

=head3 through($$$@)

Traverse parse tree visiting each node twice calling the specified B<sub> at each node and returning the specified starting node. The B<sub>s are passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

     Parameter  Description                      
  1  $node      Starting node                    
  2  $before    Sub to call when we meet a node  
  3  $after     Sub to call we leave a node      
  4  @context   Accumulated context.             

Example:


  my $s; my $n = sub{$s .= $_->tag}; $x->through($n, $n);
  
  ok $s eq "abccbdeeda"
  

=head3 throughX($$$@)

Traverse parse tree visiting each node twice calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

     Parameter  Description                      
  1  $node      Starting node                    
  2  $before    Sub to call when we meet a node  
  3  $after     Sub to call we leave a node      
  4  @context   Accumulated context.             

Example:


  my $s; my $n = sub{$s .= $_->tag}; $x->through($n, $n);
  
  ok $s eq "abccbdeeda"
  

=head2 Range

Ranges of nodes

=head3 from($@)

Return a list consisting of the specified node and its following siblings optionally including only those nodes that match one of the tags in the specified list.

     Parameter  Description                     
  1  $start     Start node                      
  2  @match     Optional list of tags to match  

Example:


  ok -z $a eq <<END;
  <a id="1">
    <b id="2">
      <c id="3">
        <e id="4"/>
      </c>
      <d id="5">
        <e id="6"/>
      </d>
      <c id="7">
        <d id="8">
          <e id="9"/>
        </d>
      </c>
      <d id="10">
        <e id="11"/>
      </d>
      <c id="12">
        <d id="13">
          <e id="14"/>
        </d>
      </c>
    </b>
  </a>
  END
  
  my ($d, $c, $D) = $a->findByNumbers(5, 7, 10);
  
  my @f = $d->from;
  
  ok @f == 4;
  
  ok $d == $f[0];
  
  my @F = $d->from(qw(c));
  
  ok @F == 2;
  
  ok -M $F[1] == 12;
  
  ok $D == $t[-1];
  

=head3 to($@)

Return a list of the sibling nodes preceding the specified node optionally including only those nodes that match one of the tags in the specified list.

     Parameter  Description                     
  1  $end       End node                        
  2  @match     Optional list of tags to match  

Example:


  ok -z $a eq <<END;
  <a id="1">
    <b id="2">
      <c id="3">
        <e id="4"/>
      </c>
      <d id="5">
        <e id="6"/>
      </d>
      <c id="7">
        <d id="8">
          <e id="9"/>
        </d>
      </c>
      <d id="10">
        <e id="11"/>
      </d>
      <c id="12">
        <d id="13">
          <e id="14"/>
        </d>
      </c>
    </b>
  </a>
  END
  
  my ($d, $c, $D) = $a->findByNumbers(5, 7, 10);
  
  my @t = $D->to;
  
  ok @t == 4;
  
  my @T = $D->to(qw(c));
  
  ok @T == 2;
  
  ok -M $T[1] == 7;
  

=head3 fromTo($$@)

Return a list of the nodes between the specified start and end nodes optionally including only those nodes that match one of the tags in the specified list.

     Parameter  Description                     
  1  $start     Start node                      
  2  $end       End node                        
  3  @match     Optional list of tags to match  

Example:


  ok -z $a eq <<END;
  <a id="1">
    <b id="2">
      <c id="3">
        <e id="4"/>
      </c>
      <d id="5">
        <e id="6"/>
      </d>
      <c id="7">
        <d id="8">
          <e id="9"/>
        </d>
      </c>
      <d id="10">
        <e id="11"/>
      </d>
      <c id="12">
        <d id="13">
          <e id="14"/>
        </d>
      </c>
    </b>
  </a>
  END
  
  my ($d, $c, $D) = $a->findByNumbers(5, 7, 10);
  
  my @r = $d->fromTo($D);
  
  ok @r == 3;
  
  my @R = $d->fromTo($D, qw(c));
  
  ok @R == 1;
  
  ok -M $R[0] == 7;
  
  ok !$D->fromTo($d);
  
  ok 1 == $d->fromTo($d);
  

=head1 Position

Confirm that the position L<navigated|/Navigation> to is the expected position.

=head2 at($@)

Confirm that the node has the specified L<ancestry|/ancestry> and return the starting node if it does else B<undef>. Ancestry is specified by providing the expected tags that the parent, the parent's parent etc. must match at each level. If B<undef> is specified then any tag is assumed to match at that level. If a regular expression is specified then the current parent node tag must match the regular expression at that level. If all supplied tags match successfully then the starting node is returned else B<undef>

     Parameter  Description    
  1  $start     Starting node  
  2  @context   Ancestry.      

Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c> <d/> </c>
      <c> <e/> </c>
      <c> <f/> </c>
    </b>
  </a>
  END
  
  ok  $a->go(qw(b c -1 f))->at(qw(f c b a));
  
  ok  $a->go(qw(b c  1 e))->at(undef, qr(c|d), undef, qq(a));
  
  ok $d->context eq q(d c b a);
  
  ok  $d->at(qw(d c b), undef);
  
  ok !$d->at(qw(d c b), undef, undef);
  
  ok !$d->at(qw(d e b));
  

Use B<atX> to execute L<at|/at> but B<die> 'at' instead of returning B<undef>

=head2 atOrBelow($@)

Confirm that the node or one of its ancestors has the specified context as recognized by L<at|/at> and return the first node that matches the context or B<undef> if none do.

     Parameter  Description    
  1  $start     Starting node  
  2  @context   Ancestry.      

Example:


  ok $d->context eq q(d c b a);
  
  ok  $d->atOrBelow(qw(d c b a));
  
  ok  $d->atOrBelow(qw(  c b a));
  
  ok  $d->atOrBelow(qw(    b a));
  
  ok !$d->atOrBelow(qw(  c   a));
  

Use B<atOrBelowX> to execute L<atOrBelow|/atOrBelow> but B<die> 'atOrBelow' instead of returning B<undef>

=head2 ancestry($)

Return a list containing: (the specified node, its parent, its parent's parent etc..)

     Parameter  Description     
  1  $start     Starting node.  

Example:


  $a->numberTree;
  
  ok $a->prettyStringNumbered eq <<END;
  <a id="1">
    <b id="2">
      <A id="3"/>
      <B id="4"/>
    </b>
    <c id="5">
      <C id="6"/>
      <D id="7"/>
    </c>
  </a>
  END
  
  is_deeply [map {-t $_} $a->findByNumber(7)->ancestry], [qw(D c a)];
  

=head2 context($)

Return a string containing the tag of the starting node and the tags of all its ancestors separated by single spaces.

     Parameter  Description     
  1  $start     Starting node.  

Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  ok $x->go(qw(d e))->context eq 'e d a';
  

=head2 containsSingleText($)

Return the singleton text element below this node else return B<undef>

     Parameter  Description  
  1  $node      Node.        

Example:


  my $a = Data::Edit::Xml::new("<a><b>bb</b><c>cc<d/>ee</c></a>");
  
  ok  $a->go(q(b))->containsSingleText->text eq q(bb);
  
  ok !$a->go(q(c))->containsSingleText;
  

=head2 depth($)

Returns the depth of the specified node, the  depth of a root node is zero.

     Parameter  Description  
  1  $node      Node.        

Example:


  ok -z $a eq <<END;
  <a id="1">
    <b id="2">
      <c id="3">
        <e id="4"/>
      </c>
      <d id="5">
        <e id="6"/>
      </d>
      <c id="7">
        <d id="8">
          <e id="9"/>
        </d>
      </c>
      <d id="10">
        <e id="11"/>
      </d>
      <c id="12">
        <d id="13">
          <e id="14"/>
        </d>
      </c>
    </b>
  </a>
  END
  
  ok 0 == $a->depth;
  
  ok 4 == $a->findByNumber(14)->depth;
  

=head2 isFirst($@)

Return the specified node if it is first under its parent and optionally has the specified context, else return B<undef>

     Parameter  Description       
  1  $node      Node              
  2  @context   Optional context  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.

Use B<isFirstNonBlank> to skip a (rare) initial blank text CDATA. Use B<isFirstNonBlankX> to die rather
then receive a returned B<undef> or false result.



Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  ok $x->go(q(b))->isFirst;
  

Use B<isFirstX> to execute L<isFirst|/isFirst> but B<die> 'isFirst' instead of returning B<undef>

=head2 isLast($@)

Return the specified node if it is last under its parent and optionally has the specified context, else return B<undef>

     Parameter  Description       
  1  $node      Node              
  2  @context   Optional context  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.

Use B<isLastNonBlank> to skip a (rare) initial blank text CDATA. Use B<isLastNonBlankX> to die rather
then receive a returned B<undef> or false result.



Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  ok $x->go(q(d))->isLast;
  

Use B<isLastX> to execute L<isLast|/isLast> but B<die> 'isLast' instead of returning B<undef>

=head2 isOnlyChild($@)

Return the specified node if it is the only node under its parent (and ancestors) ignoring any surrounding blank text.

     Parameter  Description       
  1  $node      Node              
  2  @context   Optional context  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END)->first->first;
  <a id="aa"><b id="bb"><c id="cc"/></b></a>
  END
  
  ok $x->isOnlyChild;
  
  ok $x->isOnlyChild(qw(c));
  
  ok $x->isOnlyChild(qw(c b));
  
  ok $x->isOnlyChild(qw(c b a));
  

Use B<isOnlyChildX> to execute L<isOnlyChild|/isOnlyChild> but B<die> 'isOnlyChild' instead of returning B<undef>

=head2 isEmpty($@)

Confirm that this node is empty, that is: this node has no content, not even a blank string of text. To test for blank nodes, see L<isAllBlankText|/isAllBlankText>.

     Parameter  Description       
  1  $node      Node              
  2  @context   Optional context  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
  
  </a>
  END
  
  ok $x->isEmpty;
  
  my $x = Data::Edit::Xml::new(<<END)->first->first;
  <a id="aa"><b id="bb"><c id="cc"/></b></a>
  END
  
  ok $x->isEmpty;
  

Use B<isEmptyX> to execute L<isEmpty|/isEmpty> but B<die> 'isEmpty' instead of returning B<undef>

=head2 over($$@)

Confirm that the string representing the tags at the level below this node match a regular expression where each pair of tags is separated by a single space.

     Parameter  Description         
  1  $node      Node                
  2  $re        Regular expression  
  3  @context   Optional context.   

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
  ok $x->go(q(b))->over(qr(d.+e));
  

Use B<overX> to execute L<over|/over> but B<die> 'over' instead of returning B<undef>

=head2 over2($$@)

Confirm that the string representing the tags at the level below this node match a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a space and the last tag is followed by a space.  This arrangement simplifies the regular expression used to detect combinations like p+ q?

     Parameter  Description         
  1  $node      Node                
  2  $re        Regular expression  
  3  @context   Optional context.   

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
  ok $x->go(q(b))->over2(qr(\A c  d  e  f  g \Z));
  
  ok $x->go(q(b))->contentAsTags  eq q(c d e f g) ;
  

Use B<over2X> to execute L<over2|/over2> but B<die> 'over2' instead of returning B<undef>

=head2 matchAfter($$@)

Confirm that the string representing the tags following this node matches a regular expression where each pair of tags is separated by a single space.

     Parameter  Description         
  1  $node      Node                
  2  $re        Regular expression  
  3  @context   Optional context.   

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
  ok $x->go(qw(b e))->matchAfter  (qr(\Af g\Z));
  

Use B<matchAfterX> to execute L<matchAfter|/matchAfter> but B<die> 'matchAfter' instead of returning B<undef>

=head2 matchAfter2($$@)

Confirm that the string representing the tags following this node matches a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a space and the last tag is followed by a space.  This arrangement simplifies the regular expression used to detect combinations like p+ q?

     Parameter  Description         
  1  $node      Node                
  2  $re        Regular expression  
  3  @context   Optional context.   

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
  ok $x->go(qw(b e))->matchAfter2 (qr(\A f  g \Z));
  

Use B<matchAfter2X> to execute L<matchAfter2|/matchAfter2> but B<die> 'matchAfter2' instead of returning B<undef>

=head2 matchBefore($$@)

Confirm that the string representing the tags preceding this node matches a regular expression where each pair of tags is separated by a single space.

     Parameter  Description         
  1  $node      Node                
  2  $re        Regular expression  
  3  @context   Optional context.   

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
  ok $x->go(qw(b e))->matchBefore (qr(\Ac d\Z));
  

Use B<matchBeforeX> to execute L<matchBefore|/matchBefore> but B<die> 'matchBefore' instead of returning B<undef>

=head2 matchBefore2($$@)

Confirm that the string representing the tags preceding this node matches a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a space and the last tag is followed by a space.  This arrangement simplifies the regular expression used to detect combinations like p+ q?

     Parameter  Description         
  1  $node      Node                
  2  $re        Regular expression  
  3  @context   Optional context.   

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
  ok $x->go(qw(b e))->matchBefore2(qr(\A c  d \Z));
  

Use B<matchBefore2X> to execute L<matchBefore2|/matchBefore2> but B<die> 'matchBefore2' instead of returning B<undef>

=head2 path($)

Return a list representing the path to a node which can then be reused by L<get|/get> to retrieve the node as long as the structure of the parse tree has not changed along the path.

     Parameter  Description  
  1  $node      Node.        

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a       id='a1'>
    <b     id='b1'>
      <c   id='c1'/>
      <c   id='c2'/>
      <d   id='d1'>
        <e id='e1'/>
      </d>
      <c   id='c3'/>
      <c   id='c4'/>
      <d   id='d2'>
        <e id='e2'/>
      </d>
      <c   id='c5'/>
      <c   id='c6'/>
    </b>
  </a>
  END
  
  is_deeply [$x->go(qw(b d 1 e))->path], [qw(b d 1 e)];
  
  $x->by(sub {ok $x->go($_->path) == $_});
  

=head2 pathString($)

Return a string representing the L<path|/path> to a node

     Parameter  Description  
  1  $node      Node.        

Example:


  ok -z $a eq <<END;
  <a id="1">
    <b id="2">
      <c id="3">
        <e id="4"/>
      </c>
      <d id="5">
        <e id="6"/>
      </d>
      <c id="7">
        <d id="8">
          <e id="9"/>
        </d>
      </c>
      <d id="10">
        <e id="11"/>
      </d>
      <c id="12">
        <d id="13">
          <e id="14"/>
        </d>
      </c>
    </b>
  </a>
  END
  
  ok $a->findByNumber(9)->pathString eq 'b c 1 d e';
  

=head1 Navigation

Move around in the parse tree

=head2 go($@)

Return the node reached from the specified node via the specified L<path|/path>: (index positionB<?>)B<*> where index is the tag of the next node to be chosen and position is the optional zero based position within the index of those tags under the current node. Position defaults to zero if not specified. Position can also be negative to index back from the top of the index array. B<*> can be used as the last position to retrieve all nodes with the final tag.

     Parameter  Description            
  1  $node      Node                   
  2  @position  Search specification.  

Example:


  my $x = Data::Edit::Xml::new(my $s = <<END);
  <aa>
    <a>
      <b/>
        <c id="1"/><c id="2"/><c id="3"/><c id="4"/>
      <d/>
    </a>
  </aa>
  END
  
  ok $x->go(qw(a c))   ->id == 1;
  
  ok $x->go(qw(a c -2))->id == 3;
  
  ok $x->go(qw(a c *)) == 4;
  
  ok 1234 == join '', map {$_->id} $x->go(qw(a c *));
  

Use B<goX> to execute L<go|/go> but B<die> 'go' instead of returning B<undef>

=head2 c($$)

Return an array of all the nodes with the specified tag below the specified node.

     Parameter  Description  
  1  $node      Node         
  2  $tag       Tag.         

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b id="b1"><c id="1"/></b>
    <d id="d1"><c id="2"/></d>
    <e id="e1"><c id="3"/></e>
    <b id="b2"><c id="4"/></b>
    <d id="d2"><c id="5"/></d>
    <e id="e2"><c id="6"/></e>
  </a>
  END
  
  is_deeply [map{-u $_} $x->c(q(d))],  [qw(d1 d2)];
  

=head2 First

Find nodes that are first amongst their siblings.

=head3 first($@)

Return the first node below this node optionally checking its context.

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.

Use B<firstNonBlank> to skip a (rare) initial blank text CDATA. Use B<firstNonBlankX> to die rather
then receive a returned B<undef> or false result.



Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a         id="11">
    <b       id="12">
       <c    id="13"/>
       <d    id="14"/>
       <b    id="15">
          <c id="16"/>
          <d id="17"/>
          <e id="18"/>
          <f id="19"/>
          <g id="20"/>
       </b>
       <f    id="21"/>
       <g    id="22"/>
    </b>
    <b       id="23">
       <c    id="24"/>
       <d    id="25"/>
       <b    id="26">
          <c id="27"/>
          <d id="28"/>
          <e id="29"/>
          <f id="30"/>
          <g id="31"/>
       </b>
       <f    id="32"/>
       <g    id="33"/>
    </b>
  </a>
  END
  
  ok  $a->go(q(b))->first->id == 13;
  
  ok  $a->go(q(b))->first(qw(c b a));
  
  ok !$a->go(q(b))->first(qw(b a));
  

Use B<firstX> to execute L<first|/first> but B<die> 'first' instead of returning B<undef>

=head3 firstText($@)

Return the first node if it is a text node otherwise undef

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -p $a eq <<END;
  <a>AA
    <b/>
  BB
    <c/>
  CC
    <d/>
    <e/>
    <f/>
  DD
    <g/>
  HH
  </a>
  END
  
  ok  $a->firstText;
  
  ok !$a->go(qw(c))->firstText;
  

Use B<firstTextX> to execute L<firstText|/firstText> but B<die> 'firstText' instead of returning B<undef>

=head3 firstBy($@)

Return a list of the first instance of each specified tag encountered in a post-order traversal from the specified node or a hash of all first instances if no tags are specified.

     Parameter  Description          
  1  $node      Node                 
  2  @tags      Tags to search for.  

Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a         id="11">
    <b       id="12">
       <c    id="13"/>
       <d    id="14"/>
       <b    id="15">
          <c id="16"/>
          <d id="17"/>
          <e id="18"/>
          <f id="19"/>
          <g id="20"/>
       </b>
       <f    id="21"/>
       <g    id="22"/>
    </b>
    <b       id="23">
       <c    id="24"/>
       <d    id="25"/>
       <b    id="26">
          <c id="27"/>
          <d id="28"/>
          <e id="29"/>
          <f id="30"/>
          <g id="31"/>
       </b>
       <f    id="32"/>
       <g    id="33"/>
    </b>
  </a>
  END
  
  my %f = $a->firstBy;
  
  ok $f{b}->id == 12;
  

=head3 firstDown($@)

Return a list of the first instance of each specified tag encountered in a pre-order traversal from the specified node or a hash of all first instances if no tags are specified.

     Parameter  Description          
  1  $node      Node                 
  2  @tags      Tags to search for.  

Example:


  my %f = $a->firstDown;
  
  ok $f{b}->id == 15;
  

=head3 firstIn($@)

Return the first node matching one of the named tags under the specified node.

     Parameter  Description          
  1  $node      Node                 
  2  @tags      Tags to search for.  

Example:


  ok $a->prettyStringCDATA eq <<'END';
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

=head3 firstInIndex($@)

Return the specified node if it is first in its index and optionally L<at|/at> the specified context else B<undef>

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -z $a eq <<END;
  <a id="1">
    <b id="2">
      <c id="3">
        <e id="4"/>
      </c>
      <d id="5">
        <e id="6"/>
      </d>
      <c id="7">
        <d id="8">
          <e id="9"/>
        </d>
      </c>
      <d id="10">
        <e id="11"/>
      </d>
      <c id="12">
        <d id="13">
          <e id="14"/>
        </d>
      </c>
    </b>
  </a>
  END
  
  ok  $a->findByNumber (5)->firstInIndex;
  
  ok !$a->findByNumber(7) ->firstInIndex;
  

Use B<firstInIndexX> to execute L<firstInIndex|/firstInIndex> but B<die> 'firstInIndex' instead of returning B<undef>

=head3 firstContextOf($@)

Return the first node encountered in the specified context in a depth first post-order traversal of the parse tree.

     Parameter  Description                        
  1  $node      Node                               
  2  @context   Array of tags specifying context.  

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a        id="a1">
    <b1     id="b1">
       <c   id="c1">
         <d id="d1">DD11</d>
         <e id="e1">EE11</e>
      </c>
    </b1>
    <b2     id="b2">
       <c   id="c2">
         <d id="d2">DD22</d>
         <e id="e2">EE22</e>
      </c>
    </b2>
    <b3     id="b3">
       <c   id="c3">
         <d id="d3">DD33</d>
         <e id="e3">EE33</e>
      </c>
    </b3>
  </a>
  END
  
  ok $x->firstContextOf(qw(d c))         ->id     eq qq(d1);
  
  ok $x->firstContextOf(qw(e c b2))      ->id     eq qq(e2);
  
  ok $x->firstContextOf(qw(CDATA d c b2))->string eq qq(DD22);
  

Use B<firstContextOfX> to execute L<firstContextOf|/firstContextOf> but B<die> 'firstContextOf' instead of returning B<undef>

=head2 Last

Find nodes that are last amongst their siblings.

=head3 last($@)

Return the last node below this node optionally checking its context.

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.

Use B<lastNonBlank> to skip a (rare) initial blank text CDATA. Use B<lastNonBlankX> to die rather
then receive a returned B<undef> or false result.



Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a         id="11">
    <b       id="12">
       <c    id="13"/>
       <d    id="14"/>
       <b    id="15">
          <c id="16"/>
          <d id="17"/>
          <e id="18"/>
          <f id="19"/>
          <g id="20"/>
       </b>
       <f    id="21"/>
       <g    id="22"/>
    </b>
    <b       id="23">
       <c    id="24"/>
       <d    id="25"/>
       <b    id="26">
          <c id="27"/>
          <d id="28"/>
          <e id="29"/>
          <f id="30"/>
          <g id="31"/>
       </b>
       <f    id="32"/>
       <g    id="33"/>
    </b>
  </a>
  END
  
  ok  $a->go(q(b))->last ->id == 22;
  
  ok  $a->go(q(b))->last(qw(g b a));
  
  ok !$a->go(q(b))->last(qw(b a));
  
  ok !$a->go(q(b))->last(qw(b a));
  

Use B<lastX> to execute L<last|/last> but B<die> 'last' instead of returning B<undef>

=head3 lastText($@)

Return the last node if it is a text node otherwise undef

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -p $a eq <<END;
  <a>AA
    <b/>
  BB
    <c/>
  CC
    <d/>
    <e/>
    <f/>
  DD
    <g/>
  HH
  </a>
  END
  
  ok  $a->lastText;
  
  ok !$a->go(qw(c))->lastText;
  

Use B<lastTextX> to execute L<lastText|/lastText> but B<die> 'lastText' instead of returning B<undef>

=head3 lastBy($@)

Return a list of the last instance of each specified tag encountered in a post-order traversal from the specified node or a hash of all first instances if no tags are specified.

     Parameter  Description          
  1  $node      Node                 
  2  @tags      Tags to search for.  

Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a         id="11">
    <b       id="12">
       <c    id="13"/>
       <d    id="14"/>
       <b    id="15">
          <c id="16"/>
          <d id="17"/>
          <e id="18"/>
          <f id="19"/>
          <g id="20"/>
       </b>
       <f    id="21"/>
       <g    id="22"/>
    </b>
    <b       id="23">
       <c    id="24"/>
       <d    id="25"/>
       <b    id="26">
          <c id="27"/>
          <d id="28"/>
          <e id="29"/>
          <f id="30"/>
          <g id="31"/>
       </b>
       <f    id="32"/>
       <g    id="33"/>
    </b>
  </a>
  END
  
  my %l = $a->lastBy;
  
  ok $l{b}->id == 23;
  

=head3 lastDown($@)

Return a list of the last instance of each specified tag encountered in a pre-order traversal from the specified node or a hash of all first instances if no tags are specified.

     Parameter  Description          
  1  $node      Node                 
  2  @tags      Tags to search for.  

Example:


  my %l = $a->lastDown;
  
  ok $l{b}->id == 26;
  

=head3 lastIn($@)

Return the first node matching one of the named tags under the specified node.

     Parameter  Description          
  1  $node      Node                 
  2  @tags      Tags to search for.  

Example:


  ok $a->prettyStringCDATA eq <<'END';
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

=head3 lastInIndex($@)

Return the specified node if it is last in its index and optionally L<at|/at> the specified context else B<undef>

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -z $a eq <<END;
  <a id="1">
    <b id="2">
      <c id="3">
        <e id="4"/>
      </c>
      <d id="5">
        <e id="6"/>
      </d>
      <c id="7">
        <d id="8">
          <e id="9"/>
        </d>
      </c>
      <d id="10">
        <e id="11"/>
      </d>
      <c id="12">
        <d id="13">
          <e id="14"/>
        </d>
      </c>
    </b>
  </a>
  END
  
  ok  $a->findByNumber(10)->lastInIndex;
  
  ok !$a->findByNumber(7) ->lastInIndex;
  

Use B<lastInIndexX> to execute L<lastInIndex|/lastInIndex> but B<die> 'lastInIndex' instead of returning B<undef>

=head3 lastContextOf($@)

Return the last node encountered in the specified context in a depth first reverse pre-order traversal of the parse tree.

     Parameter  Description                        
  1  $node      Node                               
  2  @context   Array of tags specifying context.  

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a        id="a1">
    <b1     id="b1">
       <c   id="c1">
         <d id="d1">DD11</d>
         <e id="e1">EE11</e>
      </c>
    </b1>
    <b2     id="b2">
       <c   id="c2">
         <d id="d2">DD22</d>
         <e id="e2">EE22</e>
      </c>
    </b2>
    <b3     id="b3">
       <c   id="c3">
         <d id="d3">DD33</d>
         <e id="e3">EE33</e>
      </c>
    </b3>
  </a>
  END
  
  ok $x-> lastContextOf(qw(d c))         ->id     eq qq(d3);
  
  ok $x-> lastContextOf(qw(e c b2     )) ->id     eq qq(e2);
  
  ok $x-> lastContextOf(qw(CDATA e c b2))->string eq qq(EE22);
  

Use B<lastContextOfX> to execute L<lastContextOf|/lastContextOf> but B<die> 'lastContextOf' instead of returning B<undef>

=head2 Next

Find sibling nodes after the specified node.

=head3 next($@)

Return the node next to the specified node, optionally checking its context.

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.

Use B<nextNonBlank> to skip a (rare) initial blank text CDATA. Use B<nextNonBlankX> to die rather
then receive a returned B<undef> or false result.



Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a         id="11">
    <b       id="12">
       <c    id="13"/>
       <d    id="14"/>
       <b    id="15">
          <c id="16"/>
          <d id="17"/>
          <e id="18"/>
          <f id="19"/>
          <g id="20"/>
       </b>
       <f    id="21"/>
       <g    id="22"/>
    </b>
    <b       id="23">
       <c    id="24"/>
       <d    id="25"/>
       <b    id="26">
          <c id="27"/>
          <d id="28"/>
          <e id="29"/>
          <f id="30"/>
          <g id="31"/>
       </b>
       <f    id="32"/>
       <g    id="33"/>
    </b>
  </a>
  END
  
  ok  $a->go(qw(b b e))->next ->id == 19;
  
  ok  $a->go(qw(b b e))->next(qw(f b b a));
  
  ok !$a->go(qw(b b e))->next(qw(f b a));
  

Use B<nextX> to execute L<next|/next> but B<die> 'next' instead of returning B<undef>

=head3 nextText($@)

Return the next node if it is a text node otherwise undef

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -p $a eq <<END;
  <a>AA
    <b/>
  BB
    <c/>
  CC
    <d/>
    <e/>
    <f/>
  DD
    <g/>
  HH
  </a>
  END
  
  ok  $a->go(qw(c))->nextText->text eq q(CC);
  
  ok !$a->go(qw(e))->nextText;
  

Use B<nextTextX> to execute L<nextText|/nextText> but B<die> 'nextText' instead of returning B<undef>

=head3 nextIn($@)

Return the next node matching one of the named tags.

     Parameter  Description          
  1  $node      Node                 
  2  @tags      Tags to search for.  

Example:


  ok $a->prettyStringCDATA eq <<'END';
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

=head3 nextOn($@)

Step forwards as far as possible while remaining on nodes with the specified tags. In scalar context return the last such node reached or the starting node if no such steps are possible. In array context return the start node and any following matching nodes.

     Parameter  Description                                             
  1  $node      Start node                                              
  2  @tags      Tags identifying nodes that can be step on to context.  

Example:


  ok -p $a eq <<END;
  <a>
    <b>
      <c id="1"/>
      <d id="2"/>
      <c id="3"/>
      <d id="4"/>
      <e id="5"/>
    </b>
  </a>
  END
  
  ok $c->id == 1;
  
  ok $c->nextOn(qw(d))  ->id == 2;
  
  ok $c->nextOn(qw(c d))->id == 4;
  
  ok $e->nextOn(qw(c d))     == $e;
  

=head2 Prev

Find sibling nodes before the specified node.

=head3 prev($@)

Return the node before the specified node, optionally checking its context.

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.

Use B<prevNonBlank> to skip a (rare) initial blank text CDATA. Use B<prevNonBlankX> to die rather
then receive a returned B<undef> or false result.



Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a         id="11">
    <b       id="12">
       <c    id="13"/>
       <d    id="14"/>
       <b    id="15">
          <c id="16"/>
          <d id="17"/>
          <e id="18"/>
          <f id="19"/>
          <g id="20"/>
       </b>
       <f    id="21"/>
       <g    id="22"/>
    </b>
    <b       id="23">
       <c    id="24"/>
       <d    id="25"/>
       <b    id="26">
          <c id="27"/>
          <d id="28"/>
          <e id="29"/>
          <f id="30"/>
          <g id="31"/>
       </b>
       <f    id="32"/>
       <g    id="33"/>
    </b>
  </a>
  END
  
  ok  $a->go(qw(b b e))->prev ->id == 17;
  
  ok  $a->go(qw(b b e))->prev(qw(d b b a));
  
  ok !$a->go(qw(b b e))->prev(qw(d b a));
  

Use B<prevX> to execute L<prev|/prev> but B<die> 'prev' instead of returning B<undef>

=head3 prevText($@)

Return the previous node if it is a text node otherwise undef

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -p $a eq <<END;
  <a>AA
    <b/>
  BB
    <c/>
  CC
    <d/>
    <e/>
    <f/>
  DD
    <g/>
  HH
  </a>
  END
  
  ok  $a->go(qw(c))->prevText->text eq q(BB);
  
  ok !$a->go(qw(e))->prevText;
  

Use B<prevTextX> to execute L<prevText|/prevText> but B<die> 'prevText' instead of returning B<undef>

=head3 prevIn($@)

Return the next previous node matching one of the named tags.

     Parameter  Description          
  1  $node      Node                 
  2  @tags      Tags to search for.  

Example:


  ok $a->prettyStringCDATA eq <<'END';
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

=head3 prevOn($@)

Step backwards as far as possible while remaining on nodes with the specified tags. In scalar context return the last such node reached or the starting node if no such steps are possible. In array context return the start node and any preceding matching nodes.

     Parameter  Description                                             
  1  $node      Start node                                              
  2  @tags      Tags identifying nodes that can be step on to context.  

Example:


  ok -p $a eq <<END;
  <a>
    <b>
      <c id="1"/>
      <d id="2"/>
      <c id="3"/>
      <d id="4"/>
      <e id="5"/>
    </b>
  </a>
  END
  
  ok $c->id == 1;
  
  ok $e->id == 5;
  
  ok $e->prevOn(qw(d))  ->id == 4;
  
  ok $e->prevOn(qw(c d))     == $c;
  

=head2 Upto

Methods for moving up the parse tree from a node.

=head3 upto($@)

Return the first ancestral node that matches the specified context.

     Parameter  Description                
  1  $node      Start node                 
  2  @tags      Tags identifying context.  

Example:


  $a->numberTree;
  
  ok -z $a eq <<END;
  <a id="1">
    <b id="2">
      <c id="3">
        <b id="4">
          <b id="5">
            <b id="6">
              <b id="7">
                <c id="8"/>
              </b>
            </b>
          </b>
        </b>
      </c>
    </b>
  </a>
  END
  
  ok $a->findByNumber(8)->upto(qw(b c))->number == 4;
  

Use B<uptoX> to execute L<upto|/upto> but B<die> 'upto' instead of returning B<undef>

=head1 Editing

Edit the data in the parse tree and change the structure of the parse tree by L<wrapping and unwrapping|/Wrap and unwrap> nodes, by L<replacing|/Replace> nodes, by L<cutting and pasting|/Cut and Put> nodes, by L<concatenating|/Fusion> nodes, by L<splitting|/Fission> nodes or by adding new L<text|/Put as text> nodes.

=head2 change($$@)

Change the name of a node, optionally  confirming that the node is in a specified context and return the node.

     Parameter  Description                                    
  1  $node      Node                                           
  2  $name      New name                                       
  3  @tags      Optional: tags defining the required context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $a = Data::Edit::Xml::new('<a/>');
  
  $a->change(qq(b));
  
  ok -s $a eq '<b/>';
  

Use B<changeX> to execute L<change|/change> but B<die> 'change' instead of returning B<undef>

=head2 Cut and Put

Move nodes around in the parse tree by cutting and pasting them.

=head3 cut($@)

Cut out a node so that it can be reinserted else where in the parse tree.

     Parameter  Description       
  1  $node      Node to cut out   
  2  @context   Optional context  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



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
  

=head3 putFirst($$@)

Place a L<cut out|/cut> or L<new|/new> node at the front of the content of the specified node and return the new node.

     Parameter  Description        
  1  $old       Original node      
  2  $new       New node           
  3  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



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
  

=head3 putLast($$@)

Place a L<cut out|/cut> or L<new|/new> node last in the content of the specified node and return the new node.

     Parameter  Description        
  1  $old       Original node      
  2  $new       New node           
  3  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



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
  

=head3 putNext($$@)

Place a L<cut out|/cut> or L<new|/new> node just after the specified node and return the new node.

     Parameter  Description        
  1  $old       Original node      
  2  $new       New node           
  3  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -p $a eq <<END;
  <a id="aa">
    <b id="bb"/>
    <c id="cc"/>
  </a>
  END
  
  $a->go(qw(c))->putNext($a->go(q(b))->cut);
  
  ok -p $a eq <<END;
  <a id="aa">
    <c id="cc"/>
    <b id="bb"/>
  </a>
  END
  

=head3 putPrev($$@)

Place a L<cut out|/cut> or L<new|/new> node just before the specified node and return the new node.

     Parameter  Description        
  1  $old       Original node      
  2  $new       New node           
  3  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -p $a eq <<END;
  <a id="aa">
    <c id="cc"/>
    <b id="bb"/>
  </a>
  END
  
  $a->go(qw(c))->putPrev($a->go(q(b))->cut);
  
  ok -p $a eq <<END;
  <a id="aa">
    <b id="bb"/>
    <c id="cc"/>
  </a>
  END
  

=head2 Fusion

Join consecutive nodes

=head3 concatenate($$@)

Concatenate two successive nodes and return the target node.

     Parameter  Description                  
  1  $target    Target node to replace       
  2  $source    Node to concatenate          
  3  @context   Optional context of $target  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



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
  
  $a->go(q(b))->concatenate($a->go(q(c)));
  
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
  

=head3 concatenateSiblings($@)

Concatenate preceding and following nodes as long as they have the same tag as the specified node and return the specified node.

     Parameter  Description                   
  1  $node      Concatenate around this node  
  2  @context   Optional context.             

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



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
  

=head2 Put as text

Add text to the parse tree.

=head3 putFirstAsText($$@)

Add a new text node first under a parent and return the new text node.

     Parameter  Description                                                              
  1  $node      The parent node                                                          
  2  $text      The string to be added which might contain unparsed Xml as well as text  
  3  @context   Optional context.                                                        

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -p $x eq <<END;
  <a id="aa">
    <b id="bb">
      <c id="cc"/>
    </b>
  </a>
  END
  
  $x->go(qw(b c))->putFirstAsText("<d id=\"dd\">DDDD</d>");
  
  ok -p $x eq <<END;
  <a id="aa">
    <b id="bb">
      <c id="cc"><d id="dd">DDDD</d></c>
    </b>
  </a>
  END
  

=head3 putLastAsText($$@)

Add a new text node last under a parent and return the new text node.

     Parameter  Description                                                              
  1  $node      The parent node                                                          
  2  $text      The string to be added which might contain unparsed Xml as well as text  
  3  @context   Optional context.                                                        

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -p $x eq <<END;
  <a id="aa">
    <b id="bb">
      <c id="cc"><d id="dd">DDDD</d></c>
    </b>
  </a>
  END
  
  $x->go(qw(b c))->putLastAsText("<e id=\"ee\">EEEE</e>");
  
  ok -p $x eq <<END;
  <a id="aa">
    <b id="bb">
      <c id="cc"><d id="dd">DDDD</d><e id="ee">EEEE</e></c>
    </b>
  </a>
  END
  

=head3 putNextAsText($$@)

Add a new text node following this node and return the new text node.

     Parameter  Description                                                              
  1  $node      The parent node                                                          
  2  $text      The string to be added which might contain unparsed Xml as well as text  
  3  @context   Optional context.                                                        

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -p $x eq <<END;
  <a id="aa">
    <b id="bb">
      <c id="cc"><d id="dd">DDDD</d><e id="ee">EEEE</e></c>
    </b>
  </a>
  END
  
  $x->go(qw(b c))->putNextAsText("<n id=\"nn\">NNNN</n>");
  
  ok -p $x eq <<END;
  <a id="aa">
    <b id="bb">
      <c id="cc"><d id="dd">DDDD</d><e id="ee">EEEE</e></c>
  <n id="nn">NNNN</n>
    </b>
  </a>
  END
  

=head3 putPrevAsText($$@)

Add a new text node following this node and return the new text node

     Parameter  Description                                                              
  1  $node      The parent node                                                          
  2  $text      The string to be added which might contain unparsed Xml as well as text  
  3  @context   Optional context.                                                        

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -p $x eq <<END;
  <a id="aa">
    <b id="bb">
      <c id="cc"><d id="dd">DDDD</d><e id="ee">EEEE</e></c>
  <n id="nn">NNNN</n>
    </b>
  </a>
  END
  
  $x->go(qw(b c))->putPrevAsText("<p id=\"pp\">PPPP</p>");
  
  ok -p $x eq <<END;
  <a id="aa">
    <b id="bb"><p id="pp">PPPP</p>
      <c id="cc"><d id="dd">DDDD</d><e id="ee">EEEE</e></c>
  <n id="nn">NNNN</n>
    </b>
  </a>
  END
  

=head2 Break in and out

Break nodes out of nodes or push them back

=head3 breakIn($@)

Concatenate the nodes following and preceding the start node, unwrapping nodes whose tag matches the start node and return the start node. To concatenate only the preceding nodes, use L<breakInBackwards|/breakInBackwards>, to concatenate only the following nodes, use L<breakInForwards|/breakInForwards>.

     Parameter  Description        
  1  $start     The start node     
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -p $a eq <<END;
  <a>
    <d/>
    <b>
      <c/>
      <c/>
    </b>
    <e/>
    <b>
      <c/>
      <c/>
    </b>
    <d/>
  </a>
  END
  
  $a->go(qw(b 1))->breakIn;
  
  ok -p $a eq <<END;
  <a>
    <b>
      <d/>
      <c/>
      <c/>
      <e/>
      <c/>
      <c/>
      <d/>
    </b>
  </a>
  END
  

=head3 breakInForwards($@)

Concatenate the nodes following the start node, unwrapping nodes whose tag matches the start node and return the start node in the manner of L<breakIn|/breakIn>.

     Parameter  Description         
  1  $start     The start node      
  2  @context   Optional context..  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -p $a eq <<END;
  <a>
    <d/>
    <b>
      <c/>
      <c/>
    </b>
    <e/>
    <b>
      <c/>
      <c/>
    </b>
    <d/>
  </a>
  END
  
  $a->go(q(b))->breakInForwards;
  
  ok -p $a eq <<END;
  <a>
    <d/>
    <b>
      <c/>
      <c/>
      <e/>
      <c/>
      <c/>
      <d/>
    </b>
  </a>
  END
  

=head3 breakInBackwards($@)

Concatenate the nodes preceding the start node, unwrapping nodes whose tag matches the start node and return the start node in the manner of L<breakIn|/breakIn>.

     Parameter  Description         
  1  $start     The start node      
  2  @context   Optional context..  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -p $a eq <<END;
  <a>
    <d/>
    <b>
      <c/>
      <c/>
    </b>
    <e/>
    <b>
      <c/>
      <c/>
    </b>
    <d/>
  </a>
  END
  
  $a->go(qw(b 1))->breakInBackwards;
  
  ok -p $a eq <<END;
  <a>
    <b>
      <d/>
      <c/>
      <c/>
      <e/>
      <c/>
      <c/>
    </b>
    <d/>
  </a>
  END
  

=head3 breakOut($@)

Lift child nodes with the specified tags under the specified parent node splitting the parent node into clones and return the cut out original node.

     Parameter  Description                              
  1  $parent    The parent node                          
  2  @tags      The tags of the modes to be broken out.  

Example:


  my $A = Data::Edit::Xml::new("<a><b><d/><c/><c/><e/><c/><c/><d/></b></a>");
  
  $a->go(q(b))->breakOut($a, qw(d e));
  
  ok -p $a eq <<END;
  <a>
    <d/>
    <b>
      <c/>
      <c/>
    </b>
    <e/>
    <b>
      <c/>
      <c/>
    </b>
    <d/>
  </a>
  END
  

=head2 Replace

Replace nodes in the parse tree with nodes or text

=head3 replaceWith($$@)

Replace a node (and all its content) with a L<new node|/newTag> (and all its content) and return the new node.

     Parameter  Description         
  1  $old       Old node            
  2  $new       New node            
  3  @context   Optional context..  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $x = Data::Edit::Xml::new(qq(<a><b><c id="cc"/></b></a>));
  
  $x->go(qw(b c))->replaceWith($x->newTag(qw(d id dd)));
  
  ok -s $x eq '<a><b><d id="dd"/></b></a>';
  

=head3 replaceWithText($$@)

Replace a node (and all its content) with a new text node and return the new node.

     Parameter  Description        
  1  $old       Old node           
  2  $text      Text of new node   
  3  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $x = Data::Edit::Xml::new(qq(<a><b><c id="cc"/></b></a>));
  
  $x->go(qw(b c))->replaceWithText(qq(BBBB));
  
  ok -s $x eq '<a><b>BBBB</b></a>';
  

=head3 replaceWithBlank($@)

Replace a node (and all its content) with a new blank text node and return the new node.

     Parameter  Description        
  1  $old       Old node           
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $x = Data::Edit::Xml::new(qq(<a><b><c id="cc"/></b></a>));
  
  $x->go(qw(b c))->replaceWithBlank;
  
  ok -s $x eq '<a><b> </b></a>';
  

=head3 replaceContentWith($@)

Replace the content of a node with the specified nodes and return the replaced content

     Parameter  Description                           
  1  $node      Node whose content is to be replaced  
  2  @content   New content                           

Example:


  my $x = Data::Edit::Xml::new(qq(<a><b/><c/></a>));
  
  $x->replaceContentWith(map {$x->newTag($_)} qw(B C));
  
  ok -s $x eq '<a><B/><C/></a>';
  

=head3 replaceContentWithText($@)

Replace the content of a node with the specified texts and return the replaced content

     Parameter  Description                           
  1  $node      Node whose content is to be replaced  
  2  @text      Texts to form new content             

Example:


  my $x = Data::Edit::Xml::new(qq(<a><b/><c/></a>));
  
  $x->replaceContentWithText(qw(b c));
  
  ok -s $x eq '<a>bc</a>';
  

=head2 Wrap and unwrap

Wrap and unwrap nodes to alter the depth of the parse tree

=head3 wrapWith($$@)

Wrap the original node in a new node  forcing the original node down - deepening the parse tree - return the new wrapping node.

     Parameter    Description                          
  1  $old         Node                                 
  2  $tag         Tag for the new node or tag          
  3  %attributes  Attributes for the new node or tag.  

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
  

=head3 wrapUp($@)

Wrap the original node in a sequence of new nodes forcing the original node down - deepening the parse tree - return the array of wrapping nodes.

     Parameter  Description                                                     
  1  $node      Node to wrap                                                    
  2  @tags      Tags to wrap the node with - with the uppermost tag rightmost.  

Example:


  my $c = Data::Edit::Xml::newTree("c", id=>33);
  
  my ($b, $a) = $c->wrapUp(qw(b a));
  
  ok -p $a eq <<'END';
  <a>
    <b>
      <c id="33"/>
    </b>
  </a>
  END
  

=head3 wrapDown($@)

Wrap the content of the specified node in a sequence of new nodes forcing the original node up - deepening the parse tree - return the array of wrapping nodes.

     Parameter  Description                                                     
  1  $node      Node to wrap                                                    
  2  @tags      Tags to wrap the node with - with the uppermost tag rightmost.  

Example:


  my $a = Data::Edit::Xml::newTree("a", id=>33);
  
  my ($b, $c) = $a->wrapDown(qw(b c));
  
  ok -p $a eq <<END;
  <a id="33">
    <b>
      <c/>
    </b>
  </a>
  END
  

=head3 wrapContentWith($$@)

Wrap the content of a node in a new node: the original node then contains just the new node which, in turn, contains all the content of the original node - returns the new wrapped node.

     Parameter    Description               
  1  $old         Node                      
  2  $tag         Tag for new node          
  3  %attributes  Attributes for new node.  

Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c/>
      <c/>
      <c/>
    </b>
  </a>
  END
  
  $x->go(q(b))->wrapContentWith(qw(D id DD));
  
  ok -p $x eq <<END;
  <a>
    <b>
      <D id="DD">
        <c/>
        <c/>
        <c/>
      </D>
    </b>
  </a>
  END
  
  ok -p $a eq <<END;
  <a>
    <b id="1"/>
    <c id="2"/>
    <d id="3"/>
    <c id="4"/>
    <d id="5"/>
    <e id="6"/>
    <b id="7"/>
    <c id="8"/>
    <d id="9"/>
    <f id="10"/>
  </a>
  END
  

=head3 wrapTo($$$@)

Wrap all the nodes starting and ending at the specified nodes with a new node with the specified tag and attributes and return the new node.  Return B<undef> if the start and end nodes are not siblings - they must have the same parent for this method to work.

     Parameter    Description                       
  1  $start       Start node                        
  2  $end         End node                          
  3  $tag         Tag for the wrapping node         
  4  %attributes  Attributes for the wrapping node  

Example:


  my $x = Data::Edit::Xml::new(my $s = <<END);
  <aa>
    <a>
      <b/>
        <c id="1"/><c id="2"/><c id="3"/><c id="4"/>
      <d/>
    </a>
  </aa>
  END
  
  $x->go(qw(a c))->wrapTo($x->go(qw(a c -1)), qq(C), id=>1234);
  
  ok -p $x eq <<END;
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
  

Use B<wrapToX> to execute L<wrapTo|/wrapTo> but B<die> 'wrapTo' instead of returning B<undef>

=head3 unwrap($@)

Unwrap a node by inserting its content into its parent at the point containing the node and return the parent node.

     Parameter  Description        
  1  $node      Node to unwrap     
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -s $x eq "<a>A<b> c </b>B</a>";
  
  $b->unwrap;
  
  ok -s $x eq "<a>A c B</a>";
  

Use B<unwrapX> to execute L<unwrap|/unwrap> but B<die> 'unwrap' instead of returning B<undef>

=head3 unwrapContentsKeepingText($@)

Unwrap all the non text nodes below a specified node adding a leading and a trailing space to prevent unwrapped content from being elided and return the specified node else undef if not in the optional context.

     Parameter  Description        
  1  $node      Node to unwrap     
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c>
        <d>DD</d>
  EE
        <f>FF</f>
      </c>
    </b>
  </a>
  END
  
  $x->go(qw(b))->unwrapContentsKeepingText;
  
  ok -p $x eq <<END;
  <a>
    <b>  DD EE FF  </b>
  </a>
  END
  

Use B<unwrapContentsKeepingTextX> to execute L<unwrapContentsKeepingText|/unwrapContentsKeepingText> but B<die> 'unwrapContentsKeepingText' instead of returning B<undef>

=head1 Contents

The children of each node.

=head2 contents($@)

Return a list of all the nodes contained by this node or an empty list if the node is empty or not in the optional context.

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns an empty list B<()> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b id="b1"><c id="1"/></b>
    <d id="d1"><c id="2"/></d>
    <e id="e1"><c id="3"/></e>
    <b id="b2"><c id="4"/></b>
    <d id="d2"><c id="5"/></d>
    <e id="e2"><c id="6"/></e>
  </a>
  END
  
  is_deeply [map{-u $_} $x->contents], [qw(b1 d1 e1 b2 d2 e2)];
  

=head2 contentAfter($@)

Return a list of all the sibling nodes following this node or an empty list if this node is last or not in the optional context.

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns an empty list B<()> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
  ok 'f g' eq join ' ', map {$_->tag} $x->go(qw(b e))->contentAfter;
  

=head2 contentBefore($@)

Return a list of all the sibling nodes preceding this node or an empty list if this node is last or not in the optional context.

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns an empty list B<()> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
  ok 'c d' eq join ' ', map {$_->tag} $x->go(qw(b e))->contentBefore;
  

=head2 contentAsTags($@)

Return a string containing the tags of all the nodes contained by this node separated by single spaces or the empty string if the node is empty or undef if the node does not match the optional context.

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns an empty list B<()> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
  ok $x->go(q(b))->contentAsTags eq 'c d e f g';
  

Use B<contentAsTagsX> to execute L<contentAsTags|/contentAsTags> but B<die> 'contentAsTags' instead of returning B<undef>

=head2 contentAsTags2($@)

Return a string containing the tags of all the nodes contained by this node separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or undef if the node does not match the optional context.

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns an empty list B<()> immediately.



Example:


  ok $x->go(q(b))->contentAsTags2 eq q( c  d  e  f  g );
  

Use B<contentAsTags2X> to execute L<contentAsTags2|/contentAsTags2> but B<die> 'contentAsTags2' instead of returning B<undef>

=head2 contentAfterAsTags($@)

Return a string containing the tags of all the sibling nodes following this node separated by single spaces or the empty string if the node is empty or undef if the node does not match the optional context.

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns an empty list B<()> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
  ok 'f g' eq join ' ', map {$_->tag} $x->go(qw(b e))->contentAfter;
  
  ok $x->go(qw(b e))->contentAfterAsTags eq 'f g';
  

=head2 contentAfterAsTags2($@)

Return a string containing the tags of all the sibling nodes following this node separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or undef if the node does not match the optional context.

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns an empty list B<()> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
  ok $x->go(qw(b e))->contentAfterAsTags2 eq q( f  g );
  

=head2 contentBeforeAsTags($@)

Return a string containing the tags of all the sibling nodes preceding this node separated by single spaces or the empty string if the node is empty or undef if the node does not match the optional context.

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns an empty list B<()> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
  ok 'c d' eq join ' ', map {$_->tag} $x->go(qw(b e))->contentBefore;
  
  ok $x->go(qw(b e))->contentBeforeAsTags eq 'c d';
  

=head2 contentBeforeAsTags2($@)

Return a string containing the tags of all the sibling nodes preceding this node separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or undef if the node does not match the optional context.

     Parameter  Description        
  1  $node      Node               
  2  @context   Optional context.  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns an empty list B<()> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
  ok $x->go(qw(b e))->contentBeforeAsTags2 eq q( c  d );
  

=head2 position($)

Return the index of a node in its parent's content.

     Parameter  Description  
  1  $node      Node.        

Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a         id="11">
    <b       id="12">
       <c    id="13"/>
       <d    id="14"/>
       <b    id="15">
          <c id="16"/>
          <d id="17"/>
          <e id="18"/>
          <f id="19"/>
          <g id="20"/>
       </b>
       <f    id="21"/>
       <g    id="22"/>
    </b>
    <b       id="23">
       <c    id="24"/>
       <d    id="25"/>
       <b    id="26">
          <c id="27"/>
          <d id="28"/>
          <e id="29"/>
          <f id="30"/>
          <g id="31"/>
       </b>
       <f    id="32"/>
       <g    id="33"/>
    </b>
  </a>
  END
  
  ok $a->go(qw(b 1 b))->id == 26;
  
  ok $a->go(qw(b 1 b))->position == 2;
  

=head2 index($)

Return the index of a node in its parent index.

     Parameter  Description  
  1  $node      Node.        

Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a         id="11">
    <b       id="12">
       <c    id="13"/>
       <d    id="14"/>
       <b    id="15">
          <c id="16"/>
          <d id="17"/>
          <e id="18"/>
          <f id="19"/>
          <g id="20"/>
       </b>
       <f    id="21"/>
       <g    id="22"/>
    </b>
    <b       id="23">
       <c    id="24"/>
       <d    id="25"/>
       <b    id="26">
          <c id="27"/>
          <d id="28"/>
          <e id="29"/>
          <f id="30"/>
          <g id="31"/>
       </b>
       <f    id="32"/>
       <g    id="33"/>
    </b>
  </a>
  END
  
  ok $a->go(qw(b 1))->id == 23;
  
  ok $a->go(qw(b 1))->index == 1;
  

=head2 present($@)

Return the count of the number of the specified tag types present immediately under a node or a hash {tag} = count for all the tags present under the node if no names are specified.

     Parameter  Description                                
  1  $node      Node                                       
  2  @names     Possible tags immediately under the node.  

Example:


  is_deeply {$a->first->present}, {c=>2, d=>2, e=>1};
  

=head2 isText($@)

Return the specified node if this node is a text node, optionally in the specified context, else return B<undef>.

     Parameter  Description       
  1  $node      Node to test      
  2  @context   Optional context  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok $a->prettyStringCDATA eq <<END;
  <a>
      <b><CDATA> </CDATA></b>
  </a>
  END
  
  ok $b->first->isText;
  
  ok $b->first->isText(qw(b a));
  

Use B<isTextX> to execute L<isText|/isText> but B<die> 'isText' instead of returning B<undef>

=head2 matchesText($$@)

Returns an array of regular expression matches in the text of the specified node if it is text node and it matches the specified regular expression and optionally has the specified context otherwise returns an empty array

     Parameter  Description         
  1  $node      Node to test        
  2  $re        Regular expression  
  3  @context   Optional context    

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c>CDECD</c>
    </b>
  </a>
  END
  
  my $c = $x->go(qw(b c))->first;
  
  is_deeply [qw(E)], [$c->matchesText(qr(CD(.)CD))];
  
  ok !$c->matchesText(qr(\AD));
  
  ok  $c->matchesText(qr(\AC), qw(c b a));
  
  ok !$c->matchesText(qr(\AD), qw(c b a));
  

Use B<matchesTextX> to execute L<matchesText|/matchesText> but B<die> 'matchesText' instead of returning B<undef>

=head2 isBlankText($@)

Return the specified node if this node is a text node, optionally in the specified context, and contains nothing other than whitespace else return B<undef>. See also: L<isAllBlankText|/isAllBlankText>

     Parameter  Description       
  1  $node      Node to test      
  2  @context   Optional context  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok $a->prettyStringCDATA eq <<END;
  <a>
      <b><CDATA> </CDATA></b>
  </a>
  END
  
  ok $b->first->isBlankText;
  

Use B<isBlankTextX> to execute L<isBlankText|/isBlankText> but B<die> 'isBlankText' instead of returning B<undef>

=head2 isAllBlankText($@)

Return the specified node if this node, optionally in the specified context, does not contain anything or if it does contain something it is all whitespace else return B<undef>. See also: L<bitsNodeTextBlank|/bitsNodeTextBlank>

     Parameter  Description       
  1  $node      Node to test      
  2  @context   Optional context  

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c>
        <z/>
      </c>
    </b>
    <d/>
  </a>
  END
  
  $a->by(sub{$_->replaceWithBlank(qw(z))});
  
  my ($b, $c, $d) = $a->firstBy(qw(b c d));
  
  ok  $c->isAllBlankText;
  
  ok  $c->isAllBlankText(qw(c b a));
  
  ok !$c->isAllBlankText(qw(c a));
  

Use B<isAllBlankTextX> to execute L<isAllBlankText|/isAllBlankText> but B<die> 'isAllBlankText' instead of returning B<undef>

=head2 bitsNodeTextBlank($)

Return a bit string that shows if there are any non text nodes, text nodes or blank text nodes under a node. An empty string is returned if there are no child nodes.

     Parameter  Description    
  1  $node      Node to test.  

Example:


  ok $x->prettyStringCDATA eq <<END;
  <a>
      <b>
          <C/>
      </b>
      <c>
          <D/>
  <CDATA>
       E
      </CDATA>
      </c>
      <d>
          <F/>
  <CDATA> </CDATA>
          <H/>
      </d>
      <e/>
  </a>
  END
  
  ok '100' eq -B $x;
  
  ok '100' eq -B $x->go(q(b));
  
  ok '110' eq -B $x->go(q(c));
  
  ok '111' eq -B $x->go(q(d));
  
  ok !-B $x->go(qw(e));
  

=head1 Order

Number and verify the order of nodes.

=head2 findByNumber($$)

Find the node with the specified number as made visible by L<prettyStringNumbered|/prettyStringNumbered> in the parse tree containing the specified node and return the found node or B<undef> if no such node exists.

     Parameter  Description                       
  1  $node      Node in the parse tree to search  
  2  $number    Number of the node required.      

Example:


  $a->numberTree;
  
  ok $a->prettyStringNumbered eq <<END;
  <a id="1">
    <b id="2">
      <A id="3"/>
      <B id="4"/>
    </b>
    <c id="5">
      <C id="6"/>
      <D id="7"/>
    </c>
  </a>
  END
  
  ok q(D) eq -t $a->findByNumber(7);
  

Use B<findByNumberX> to execute L<findByNumber|/findByNumber> but B<die> 'findByNumber' instead of returning B<undef>

=head2 findByNumbers($@)

Find the nodes with the specified numbers as made visible by L<prettyStringNumbered|/prettyStringNumbered> in the parse tree containing the specified node and return the found nodes in a list with B<undef> for nodes that do not exist.

     Parameter  Description                       
  1  $node      Node in the parse tree to search  
  2  @numbers   Numbers of the nodes required.    

Example:


  $a->numberTree;
  
  ok $a->prettyStringNumbered eq <<END;
  <a id="1">
    <b id="2">
      <A id="3"/>
      <B id="4"/>
    </b>
    <c id="5">
      <C id="6"/>
      <D id="7"/>
    </c>
  </a>
  END
  
  is_deeply [map {-t $_} $a->findByNumbers(1..3)], [qw(a b A)];
  

=head2 numberTree($)

Number the nodes in a parse tree in pre-order so they are numbered in the same sequence that they appear in the source. You can see the numbers by printing the tree with L<prettyStringNumbered()|/prettyStringNumbered>.

     Parameter  Description  
  1  $node      Node         

Example:


  $x->numberTree;
  
  ok -z $x eq <<END;
  <a id="1">
    <b id="2">
      <c id="42"/>
    </b>
    <d id="4">
      <e id="5"/>
    </d>
  </a>
  END
  

=head2 above($$)

Return the specified node if it is above the specified target otherwise B<undef>

     Parameter  Description  
  1  $node      Node         
  2  $target    Target.      

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a       id='a1'>
    <b     id='b1'>
      <c   id='c1'/>
      <c   id='c2'/>
      <d   id='d1'>
        <e id='e1'/>
      </d>
      <c   id='c3'/>
      <c   id='c4'/>
      <d   id='d2'>
        <e id='e2'/>
      </d>
      <c   id='c5'/>
      <c   id='c6'/>
    </b>
  </a>
  END
  
  ok $b->id eq 'b1';
  
  ok $e->id eq "e1";
  
  ok $E->id eq "e2";
  
  ok  $b->above($e);
  
  ok !$E->above($e);
  

Use B<aboveX> to execute L<above|/above> but B<die> 'above' instead of returning B<undef>

=head2 below($$)

Return the specified node if it is below the specified target otherwise B<undef>

     Parameter  Description  
  1  $node      Node         
  2  $target    Target.      

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a       id='a1'>
    <b     id='b1'>
      <c   id='c1'/>
      <c   id='c2'/>
      <d   id='d1'>
        <e id='e1'/>
      </d>
      <c   id='c3'/>
      <c   id='c4'/>
      <d   id='d2'>
        <e id='e2'/>
      </d>
      <c   id='c5'/>
      <c   id='c6'/>
    </b>
  </a>
  END
  
  ok $d->id eq 'd1';
  
  ok $e->id eq "e1";
  
  ok !$d->below($e);
  

Use B<belowX> to execute L<below|/below> but B<die> 'below' instead of returning B<undef>

=head2 after($$)

Return the specified node if it occurs after the target node in the parse tree or else B<undef> if the node is L<above|/above>, L<below|/below> or L<before|/before> the target.

     Parameter  Description  
  1  $node      Node         
  2  $target    Target       

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a       id='a1'>
    <b     id='b1'>
      <c   id='c1'/>
      <c   id='c2'/>
      <d   id='d1'>
        <e id='e1'/>
      </d>
      <c   id='c3'/>
      <c   id='c4'/>
      <d   id='d2'>
        <e id='e2'/>
      </d>
      <c   id='c5'/>
      <c   id='c6'/>
    </b>
  </a>
  END
  
  ok $c->id eq 'c1';
  
  ok $e->id eq "e1";
  
  ok $e->after($c);
  

Use B<afterX> to execute L<after|/after> but B<die> 'after' instead of returning B<undef>

=head2 before($$)

Return the specified node if it occurs before the target node in the parse tree or else B<undef> if the node is L<above|/above>, L<below|/below> or L<after|/after> the target.

     Parameter  Description  
  1  $node      Node         
  2  $target    Target.      

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a       id='a1'>
    <b     id='b1'>
      <c   id='c1'/>
      <c   id='c2'/>
      <d   id='d1'>
        <e id='e1'/>
      </d>
      <c   id='c3'/>
      <c   id='c4'/>
      <d   id='d2'>
        <e id='e2'/>
      </d>
      <c   id='c5'/>
      <c   id='c6'/>
    </b>
  </a>
  END
  
  ok $e->id eq "e1";
  
  ok $E->id eq "e2";
  
  ok $e->before($E);
  

Use B<beforeX> to execute L<before|/before> but B<die> 'before' instead of returning B<undef>

=head2 disordered($@)

Return the first node that is out of the specified order when performing a pre-ordered traversal of the parse tree.

     Parameter  Description       
  1  $node      Node              
  2  @nodes     Following nodes.  

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a       id='a1'>
    <b     id='b1'>
      <c   id='c1'/>
      <c   id='c2'/>
      <d   id='d1'>
        <e id='e1'/>
      </d>
      <c   id='c3'/>
      <c   id='c4'/>
      <d   id='d2'>
        <e id='e2'/>
      </d>
      <c   id='c5'/>
      <c   id='c6'/>
    </b>
  </a>
  END
  
  ok $b->id eq 'b1';
  
  ok $c->id eq 'c1';
  
  ok $d->id eq 'd1';
  
  ok $e->id eq "e1";
  
  ok  $e->disordered($c        )->id eq "c1";
  
  ok  $b->disordered($c, $e, $d)->id eq "d1";
  
  ok !$c->disordered($e);
  

=head2 commonAncestor($@)

Find the most recent common ancestor of the specified nodes or B<undef> if there is no common ancestor.

     Parameter  Description  
  1  $node      Node         
  2  @nodes     @nodes       

Example:


  ok -z $a eq <<END;
  <a id="1">
    <b id="2">
      <c id="3">
        <e id="4"/>
      </c>
      <d id="5">
        <e id="6"/>
      </d>
      <c id="7">
        <d id="8">
          <e id="9"/>
        </d>
      </c>
      <d id="10">
        <e id="11"/>
      </d>
      <c id="12">
        <d id="13">
          <e id="14"/>
        </d>
      </c>
    </b>
  </a>
  END
  
  my ($b, $e, @n) = $a->findByNumbers(2, 4, 6, 9);
  
  ok $e == $e->commonAncestor;
  
  ok $e == $e->commonAncestor($e);
  
  ok $b == $e->commonAncestor($b);
  
  ok $b == $e->commonAncestor(@n);
  

Use B<commonAncestorX> to execute L<commonAncestor|/commonAncestor> but B<die> 'commonAncestor' instead of returning B<undef>

=head2 ordered($@)

Return the first node if the specified nodes are all in order when performing a pre-ordered traversal of the parse tree else return B<undef>

     Parameter  Description       
  1  $node      Node              
  2  @nodes     Following nodes.  

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a       id='a1'>
    <b     id='b1'>
      <c   id='c1'/>
      <c   id='c2'/>
      <d   id='d1'>
        <e id='e1'/>
      </d>
      <c   id='c3'/>
      <c   id='c4'/>
      <d   id='d2'>
        <e id='e2'/>
      </d>
      <c   id='c5'/>
      <c   id='c6'/>
    </b>
  </a>
  END
  
  ok $e->id eq "e1";
  
  ok $E->id eq "e2";
  
  ok  $e->ordered($E);
  
  ok !$E->ordered($e);
  
  ok  $e->ordered($e);
  
  ok  $e->ordered;
  

Use B<orderedX> to execute L<ordered|/ordered> but B<die> 'ordered' instead of returning B<undef>

=head1 Table of Contents

Analyze and generate tables of contents

=head2 tocNumbers($@)

Table of Contents number the nodes in a parse tree.

     Parameter  Description                                                                 
  1  $node      Node                                                                        
  2  @match     Optional list of tags to descend into e3se all tags will be descended into  

Example:


  ok $a->prettyStringNumbered eq <<END;
  <a id="1">
    <b id="2">
      <A id="3"/>
      <B id="4"/>
    </b>
    <c id="5">
      <C id="6"/>
      <D id="7"/>
    </c>
  </a>
  END
  
  my $t = $a->tocNumbers();
  
  is_deeply {map {$_=>$t->{$_}->tag} keys %$t},
  
  "1"  =>"b",
  
  "1 1"=>"A",
  
  "1 2"=>"B",
  
  "2"  =>"c",
  
  "2 1"=> "C",
  
  "2 2"=>"D"
  
  }
  

=head1 Labels

Label nodes so that they can be cross referenced and linked by L<Data::Edit::Xml::Lint>

=head2 addLabels($@)

Add the named labels to the specified node and return that node.

     Parameter  Description              
  1  $node      Node in parse tree       
  2  @labels    Names of labels to add.  

Example:


  ok -r $x eq '<a><b><c/></b></a>';
  
  my $b = $x->go(q(b));
  
  ok $b->countLabels == 0;
  
  $b->addLabels(1..2);
  
  $b->addLabels(3..4);
  
  ok -r $x eq '<a><b id="1, 2, 3, 4"><c/></b></a>';
  

=head2 countLabels($)

Return the count of the number of labels at a node.

     Parameter  Description          
  1  $node      Node in parse tree.  

Example:


  ok -r $x eq '<a><b><c/></b></a>';
  
  my $b = $x->go(q(b));
  
  ok $b->countLabels == 0;
  
  $b->addLabels(1..2);
  
  $b->addLabels(3..4);
  
  ok -r $x eq '<a><b id="1, 2, 3, 4"><c/></b></a>';
  
  ok $b->countLabels == 4;
  

=head2 getLabels($)

Return the names of all the labels set on a node.

     Parameter  Description          
  1  $node      Node in parse tree.  

Example:


  ok -r $x eq '<a><b><c/></b></a>';
  
  my $b = $x->go(q(b));
  
  ok $b->countLabels == 0;
  
  $b->addLabels(1..2);
  
  $b->addLabels(3..4);
  
  ok -r $x eq '<a><b id="1, 2, 3, 4"><c/></b></a>';
  
  is_deeply [1..4], [$b->getLabels];
  

=head2 deleteLabels($@)

Delete the specified labels in the specified node or all labels if no labels have are specified and return that node.

     Parameter  Description                        
  1  $node      Node in parse tree                 
  2  @labels    Names of the labels to be deleted  

Example:


  ok -r $x eq '<a><b id="1, 2, 3, 4"><c id="1, 2, 3, 4"/></b></a>';
  
  $b->deleteLabels(1,4) for 1..2;
  
  ok -r $x eq '<a><b id="2, 3"><c id="1, 2, 3, 4"/></b></a>';
  

=head2 copyLabels($$)

Copy all the labels from the source node to the target node and return the source node.

     Parameter  Description   
  1  $source    Source node   
  2  $target    Target node.  

Example:


  ok -r $x eq '<a><b id="1, 2, 3, 4"><c/></b></a>';
  
  $b->copyLabels($c) for 1..2;
  
  ok -r $x eq '<a><b id="1, 2, 3, 4"><c id="1, 2, 3, 4"/></b></a>';
  

=head2 moveLabels($$)

Move all the labels from the source node to the target node and return the source node.

     Parameter  Description   
  1  $source    Source node   
  2  $target    Target node.  

Example:


  ok -r $x eq '<a><b id="2, 3"><c id="1, 2, 3, 4"/></b></a>';
  
  $b->moveLabels($c) for 1..2;
  
  ok -r $x eq '<a><b><c id="1, 2, 3, 4"/></b></a>';
  

=head1 Operators

Operator access to methods use the assign versions to avoid 'useless use of operator in void context' messages. Use the non assign versions to return the results of the underlying method call.  Thus '/' returns the wrapping node, whilst '/=' does not.  Assign operators always return their left hand side even though the corresponding method usually returns the modification on the right.

=head2 opString($$)

-B: L<bitsNodeTextBlank|/bitsNodeTextBlank>

-b: L<previous node|/prev>

-c: L<next node|/next>

-e: L<prettyStringEnd|/prettyStringEnd>

-f: L<first node|/first>

-l: L<last node|/last>

-M: L<number|/number>

-o: L<stringQuoted|/stringQuoted>

-p: L<prettyString|/prettyString>

-r: L<stringReplacingIdsWithLabels|/stringReplacingIdsWithLabels>

-s: L<string|/string>

-S : L<stringNode|/stringNode>

-t : L<tag|/tag>

-u: L<id|/id>

-z: L<prettyStringNumbered|/prettyStringNumbered>.

     Parameter  Description        
  1  $node      Node               
  2  $op        Monadic operator.  

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  my $prev = -b $x->go(q(d));
  
  ok -t $prev eq q(b);
  
  my $next = -c $x->go(q(b));
  
  ok -t $next eq q(d);
  
  my $first = -f $x;
  
  ok -t $first eq q(b);
  
  my $last  = -l $x;
  
  ok -t $last eq q(d);
  
  ok -o $x eq "'<a><b><c id=\"42\"/></b><d><e/></d></a>'";
  
  ok -p $x eq <<END;
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  ok -s $x eq '<a><b><c id="42"/></b><d><e/></d></a>';
  
  ok -t $x eq 'a';
  
  $x->numberTree;
  
  ok -z $x eq <<END;
  <a id="1">
    <b id="2">
      <c id="42"/>
    </b>
    <d id="4">
      <e id="5"/>
    </d>
  </a>
  END
  

=head2 opContents($)

@{} : content of a node.

     Parameter  Description  
  1  $node      Node.        

Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  ok 'bd' eq join '', map {$_->tag} @$x ;
  

=head2 opAt($$)

<= : Check that a node is in the context specified by the referenced array of words.

     Parameter  Description                                                              
  1  $node      Node                                                                     
  2  $context   Reference to array of words specifying the parents of the desired node.  

Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  ok (($x >= [qw(d e)]) <= [qw(e d a)]);
  

=head2 opNew($$)

** : create a new node from the text on the right hand side: if the text contains a non word character \W the node will be create as text, else it will be created as a tag

     Parameter  Description                                              
  1  $node      Node                                                     
  2  $text      Name node of node to create or text of new text element  

Example:


  my $a = Data::Edit::Xml::new("<a/>");
  
  my $b = $a ** q(b);
  
  ok -s $b eq "<b/>";
  

=head2 opPutFirst($$)

>> : put a node or string first under a node and return the new node.

     Parameter  Description                                  
  1  $node      Node                                         
  2  $text      Node or text to place first under the node.  

Example:


  ok -p $a eq <<END;
  <a/>
  END
  
  my $f = $a >> qq(first);
  
  ok -p $a eq <<END;
  <a>
    <first/>
  </a>
  END
  

=head2 opPutFirstAssign($$)

>>= : put a node or string first under a node.

     Parameter  Description                                  
  1  $node      Node                                         
  2  $text      Node or text to place first under the node.  

Example:


  ok -p $a eq <<END;
  <a/>
  END
  
  $a >>= qq(first);
  
  ok -p $a eq <<END;
  <a>
    <first/>
  </a>
  END
  

=head2 opPutLast($$)

<< : put a node or string last under a node and return the new node.

     Parameter  Description                                 
  1  $node      Node                                        
  2  $text      Node or text to place last under the node.  

Example:


  ok -p $a eq <<END;
  <a>
    <first/>
  </a>
  END
  
  my $l = $a << qq(last);
  
  ok -p $a eq <<END;
  <a>
    <first/>
    <last/>
  </a>
  END
  

=head2 opPutLastAssign($$)

<<= : put a node or string last under a node.

     Parameter  Description                                 
  1  $node      Node                                        
  2  $text      Node or text to place last under the node.  

Example:


  ok -p $a eq <<END;
  <a>
    <first/>
  </a>
  END
  
  $a <<= qq(last);
  
  ok -p $a eq <<END;
  <a>
    <first/>
    <last/>
  </a>
  END
  

=head2 opPutNext($$)

> + : put a node or string after the specified node and return the new node.

     Parameter  Description                                  
  1  $node      Node                                         
  2  $text      Node or text to place after the first node.  

Example:


  ok -p $a eq <<END;
  <a>
    <first/>
    <last/>
  </a>
  END
  
  $f += qq(next);
  
  ok -p $a eq <<END;
  <a>
    <first/>
    <next/>
    <last/>
  </a>
  END
  

=head2 opPutNextAssign($$)

+= : put a node or string after the specified node.

     Parameter  Description                                  
  1  $node      Node                                         
  2  $text      Node or text to place after the first node.  

Example:


  ok -p $a eq <<END;
  <a>
    <first/>
    <last/>
  </a>
  END
  
  my $f = -f $a;
  
  $f += qq(next);
  
  ok -p $a eq <<END;
  <a>
    <first/>
    <next/>
    <last/>
  </a>
  END
  

=head2 opPutPrev($$)

< - : put a node or string before the specified node and return the new node.

     Parameter  Description                                   
  1  $node      Node                                          
  2  $text      Node or text to place before the first node.  

Example:


  ok -p $a eq <<END;
  <a>
    <first/>
    <next/>
    <last/>
  </a>
  END
  
  $l -= qq(prev);
  
  ok -p $a eq <<END;
  <a>
    <first/>
    <next/>
    <prev/>
    <last/>
  </a>
  END
  

=head2 opPutPrevAssign($$)

-= : put a node or string before the specified node,

     Parameter  Description                                   
  1  $node      Node                                          
  2  $text      Node or text to place before the first node.  

Example:


  ok -p $a eq <<END;
  <a>
    <first/>
    <next/>
    <last/>
  </a>
  END
  
  my $l = -l $a;
  
  $l -= qq(prev);
  
  ok -p $a eq <<END;
  <a>
    <first/>
    <next/>
    <prev/>
    <last/>
  </a>
  END
  

=head2 opBy($$)

x= : Traverse a parse tree in post-order.

     Parameter  Description                         
  1  $node      Parse tree                          
  2  $code      Code to execute against each node.  

Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  my $s; $x x= sub{$s .= -t $_}; ok $s eq "cbeda"
  

=head2 opGo($$)

>= : Search for a node via a specification provided as a reference to an array of words each number.  Each word represents a tag name, each number the index of the previous tag or zero by default.

     Parameter  Description                                  
  1  $node      Node                                         
  2  $go        Reference to an array of search parameters.  

Example:


  ok -p $x eq <<END;
  <a>
    <b>
      <c id="42"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
  ok (($x >= [qw(d e)]) <= [qw(e d a)]);
  

=head2 opAttr($$)

% : Get the value of an attribute of this node.

     Parameter  Description                                                                    
  1  $node      Node                                                                           
  2  $attr      Reference to an array of words and numbers specifying the node to search for.  

Example:


  my $a = Data::Edit::Xml::new('<a number="1"/>');
  
  ok $a %  qq(number) == 1;
  

=head1 Statistics

Statistics describing the parse tree.

=head2 count($@)

Return the count of the number of instances of the specified tags under the specified node, either by tag in array context or in total in scalar context.

     Parameter  Description                                
  1  $node      Node                                       
  2  @names     Possible tags immediately under the node.  

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a>
  
  </a>
  END
  
  ok $x->count == 0;
  

=head2 countTags($)

Count the number of tags in a parse tree.

     Parameter  Description  
  1  $node      Parse tree.  

Example:


  ok -p $a eq <<END;
  <a id="aa">
    <b id="bb">
      <c id="cc"/>
    </b>
  </a>
  END
  
  ok $a->countTags == 3;
  

=head2 countTagNames($$)

Return a reference to a hash showing the number of instances of each tag on and below the specified node.

     Parameter  Description            
  1  $node      Node                   
  2  $count     Count of tags so far.  

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a A="A" B="B" C="C">
    <b  B="B" C="C">
      <c  C="C">
      </c>
      <c/>
    </b>
    <b  C="C">
      <c/>
    </b>
  </a>
  END
  
  is_deeply $x->countTagNames,  { a => 1, b => 2, c => 3 };
  

=head2 countAttrNames($$)

Return a reference to a hash showing the number of instances of each attribute on and below the specified node.

     Parameter  Description                  
  1  $node      Node                         
  2  $count     Count of attributes so far.  

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a A="A" B="B" C="C">
    <b  B="B" C="C">
      <c  C="C">
      </c>
      <c/>
    </b>
    <b  C="C">
      <c/>
    </b>
  </a>
  END
  
  is_deeply $x->countAttrNames, { A => 1, B => 2, C => 4 };
  

=head2 countAttrValues($$)

Return a reference to a hash showing the number of instances of each attribute value on and below the specified node.

     Parameter  Description                  
  1  $node      Node                         
  2  $count     Count of attributes so far.  

Example:


  my $x = Data::Edit::Xml::new(<<END);
  <a A="A" B="B" C="C">
    <b  B="B" C="C">
      <c  C="C">
      </c>
      <c/>
    </b>
    <b  C="C">
      <c/>
    </b>
  </a>
  END
  
  is_deeply $x->countAttrValues, { A => 1, B => 2, C => 4 };
  

=head2 countOutputClasses($$)

Count instances of outputclass attributes

     Parameter  Description    
  1  $node      Node           
  2  $count     Count so far.  

Example:


  my $a = Data::Edit::Xml::newTree("a", id=>1, class=>2, href=>3, outputclass=>4);
  
  is_deeply { 4 => 1 }, $a->countOutputClasses;
  

=head1 Debug

Debugging methods


=head1 Private Methods

=head2 tree($$)

Build a tree representation of the parsed XML which can be easily traversed to look for things.

     Parameter  Description          
  1  $parent    The parent node      
  2  $parse     The remaining parse  

=head2 disconnectLeafNode($)

Remove a leaf node from the parse tree and make it into its own parse tree.

     Parameter  Description               
  1  $node      Leaf node to disconnect.  

=head2 reindexNode($)

Index the children of a node so that we can access them by tag and number.

     Parameter  Description     
  1  $node      Node to index.  

=head2 indexNode($)

Merge multiple text segments and set parent and parser after changes to a node

     Parameter  Description     
  1  $node      Node to index.  

=head2 prettyStringEnd($)

Return a readable string representing a node of a parse tree and all the nodes below it as a here document

     Parameter  Description  
  1  $node      Start node   

=head2 byX2($$@)

Post-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

     Parameter  Description           
  1  $node      Starting node         
  2  $sub       Sub to call           
  3  @context   Accumulated context.  

=head2 byX22($$@)

Post-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

     Parameter  Description           
  1  $node      Starting node         
  2  $sub       Sub to call           
  3  @context   Accumulated context.  

=head2 downX2($$@)

Pre-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

     Parameter  Description           
  1  $node      Starting node         
  2  $sub       Sub to call           
  3  @context   Accumulated context.  

=head2 downX22($$@)

Pre-order traversal down through a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via B<$_>.

     Parameter  Description                    
  1  $node      Starting node                  
  2  $sub       Sub to call for each sub node  
  3  @context   Accumulated context.           

=head2 numberNode($)

Ensure that this node has a number.

     Parameter  Description  
  1  $node      Node         

=head2 printAttributes($)

Print the attributes of a node.

     Parameter  Description                               
  1  $node      Node whose attributes are to be printed.  

Example:


  my $x = Data::Edit::Xml::new(my $s = <<END);
  <a no="1" word="first"/>
  END
  
  ok $x->printAttributes eq qq( no="1" word="first");
  

=head2 printAttributesReplacingIdsWithLabels($)

Print the attributes of a node replacing the id with the labels.

     Parameter  Description                               
  1  $node      Node whose attributes are to be printed.  

=head2 checkParentage($)

Check the parent pointers are correct in a parse tree.

     Parameter  Description  
  1  $x         Parse tree.  

=head2 checkParser($)

Check that every node has a parser.

     Parameter  Description  
  1  $x         Parse tree.  

=head2 nn($)

Replace new lines in a string with N to make testing easier.

     Parameter  Description  
  1  $s         String.      


=head1 Index


1 L<above|/above>

2 L<aboveX|/above>

3 L<addConditions|/addConditions>

4 L<addLabels|/addLabels>

5 L<after|/after>

6 L<afterX|/after>

7 L<ancestry|/ancestry>

8 L<at|/at>

9 L<atOrBelow|/atOrBelow>

10 L<atOrBelowX|/atOrBelow>

11 L<attr :lvalue|/attr :lvalue>

12 L<attrCount|/attrCount>

13 L<attributes|/attributes>

14 L<attrs|/attrs>

15 L<atX|/at>

16 L<before|/before>

17 L<beforeX|/before>

18 L<below|/below>

19 L<belowX|/below>

20 L<bitsNodeTextBlank|/bitsNodeTextBlank>

21 L<breakIn|/breakIn>

22 L<breakInBackwards|/breakInBackwards>

23 L<breakInBackwardsNonBlank|/breakInBackwards>

24 L<breakInBackwardsNonBlankX|/breakInBackwards>

25 L<breakInForwards|/breakInForwards>

26 L<breakInForwardsNonBlank|/breakInForwards>

27 L<breakInForwardsNonBlankX|/breakInForwards>

28 L<breakInNonBlank|/breakIn>

29 L<breakInNonBlankX|/breakIn>

30 L<breakOut|/breakOut>

31 L<by|/by>

32 L<byReverse|/byReverse>

33 L<byReverseX|/byReverseX>

34 L<byX|/byX>

35 L<byX2|/byX2>

36 L<byX22|/byX22>

37 L<byXNonBlank|/byX>

38 L<byXNonBlankX|/byX>

39 L<c|/c>

40 L<cdata|/cdata>

41 L<change|/change>

42 L<changeAttr|/changeAttr>

43 L<changeAttrValue|/changeAttrValue>

44 L<changeNonBlank|/change>

45 L<changeNonBlankX|/change>

46 L<changeX|/change>

47 L<checkParentage|/checkParentage>

48 L<checkParser|/checkParser>

49 L<class|/class>

50 L<clone|/clone>

51 L<cloneNonBlank|/clone>

52 L<cloneNonBlankX|/clone>

53 L<commonAncestor|/commonAncestor>

54 L<commonAncestorX|/commonAncestor>

55 L<concatenate|/concatenate>

56 L<concatenateNonBlank|/concatenate>

57 L<concatenateNonBlankX|/concatenate>

58 L<concatenateSiblings|/concatenateSiblings>

59 L<concatenateSiblingsNonBlank|/concatenateSiblings>

60 L<concatenateSiblingsNonBlankX|/concatenateSiblings>

61 L<conditions|/conditions>

62 L<containsSingleText|/containsSingleText>

63 L<content|/content>

64 L<contentAfter|/contentAfter>

65 L<contentAfterAsTags|/contentAfterAsTags>

66 L<contentAfterAsTags2|/contentAfterAsTags2>

67 L<contentAfterAsTags2NonBlank|/contentAfterAsTags2>

68 L<contentAfterAsTags2NonBlankX|/contentAfterAsTags2>

69 L<contentAfterAsTagsNonBlank|/contentAfterAsTags>

70 L<contentAfterAsTagsNonBlankX|/contentAfterAsTags>

71 L<contentAfterNonBlank|/contentAfter>

72 L<contentAfterNonBlankX|/contentAfter>

73 L<contentAsTags|/contentAsTags>

74 L<contentAsTags2|/contentAsTags2>

75 L<contentAsTags2NonBlank|/contentAsTags2>

76 L<contentAsTags2NonBlankX|/contentAsTags2>

77 L<contentAsTags2X|/contentAsTags2>

78 L<contentAsTagsNonBlank|/contentAsTags>

79 L<contentAsTagsNonBlankX|/contentAsTags>

80 L<contentAsTagsX|/contentAsTags>

81 L<contentBefore|/contentBefore>

82 L<contentBeforeAsTags|/contentBeforeAsTags>

83 L<contentBeforeAsTags2|/contentBeforeAsTags2>

84 L<contentBeforeAsTags2NonBlank|/contentBeforeAsTags2>

85 L<contentBeforeAsTags2NonBlankX|/contentBeforeAsTags2>

86 L<contentBeforeAsTagsNonBlank|/contentBeforeAsTags>

87 L<contentBeforeAsTagsNonBlankX|/contentBeforeAsTags>

88 L<contentBeforeNonBlank|/contentBefore>

89 L<contentBeforeNonBlankX|/contentBefore>

90 L<contents|/contents>

91 L<contentsNonBlank|/contents>

92 L<contentsNonBlankX|/contents>

93 L<context|/context>

94 L<copyLabels|/copyLabels>

95 L<count|/count>

96 L<countAttrNames|/countAttrNames>

97 L<countAttrValues|/countAttrValues>

98 L<countLabels|/countLabels>

99 L<countOutputClasses|/countOutputClasses>

100 L<countTagNames|/countTagNames>

101 L<countTags|/countTags>

102 L<cut|/cut>

103 L<cutNonBlank|/cut>

104 L<cutNonBlankX|/cut>

105 L<deleteAttr|/deleteAttr>

106 L<deleteAttrs|/deleteAttrs>

107 L<deleteConditions|/deleteConditions>

108 L<deleteLabels|/deleteLabels>

109 L<depth|/depth>

110 L<disconnectLeafNode|/disconnectLeafNode>

111 L<disordered|/disordered>

112 L<down|/down>

113 L<downReverse|/downReverse>

114 L<downReverseX|/downReverseX>

115 L<downX|/downX>

116 L<downX2|/downX2>

117 L<downX22|/downX22>

118 L<downXNonBlank|/downX>

119 L<downXNonBlankX|/downX>

120 L<equals|/equals>

121 L<equalsX|/equals>

122 L<errorsFile|/errorsFile>

123 L<findByNumber|/findByNumber>

124 L<findByNumbers|/findByNumbers>

125 L<findByNumberX|/findByNumber>

126 L<first|/first>

127 L<firstBy|/firstBy>

128 L<firstContextOf|/firstContextOf>

129 L<firstContextOfX|/firstContextOf>

130 L<firstDown|/firstDown>

131 L<firstIn|/firstIn>

132 L<firstInIndex|/firstInIndex>

133 L<firstInIndexNonBlank|/firstInIndex>

134 L<firstInIndexNonBlankX|/firstInIndex>

135 L<firstInIndexX|/firstInIndex>

136 L<firstInX|/firstIn>

137 L<firstNonBlank|/first>

138 L<firstNonBlankX|/first>

139 L<firstText|/firstText>

140 L<firstTextNonBlank|/firstText>

141 L<firstTextNonBlankX|/firstText>

142 L<firstTextX|/firstText>

143 L<firstX|/first>

144 L<from|/from>

145 L<fromTo|/fromTo>

146 L<getAttrs|/getAttrs>

147 L<getLabels|/getLabels>

148 L<go|/go>

149 L<goX|/go>

150 L<guid|/guid>

151 L<href|/href>

152 L<id|/id>

153 L<index|/index>

154 L<indexes|/indexes>

155 L<indexNode|/indexNode>

156 L<input|/input>

157 L<inputFile|/inputFile>

158 L<inputString|/inputString>

159 L<isAllBlankText|/isAllBlankText>

160 L<isAllBlankTextNonBlank|/isAllBlankText>

161 L<isAllBlankTextNonBlankX|/isAllBlankText>

162 L<isAllBlankTextX|/isAllBlankText>

163 L<isBlankText|/isBlankText>

164 L<isBlankTextNonBlank|/isBlankText>

165 L<isBlankTextNonBlankX|/isBlankText>

166 L<isBlankTextX|/isBlankText>

167 L<isEmpty|/isEmpty>

168 L<isEmptyNonBlank|/isEmpty>

169 L<isEmptyNonBlankX|/isEmpty>

170 L<isEmptyX|/isEmpty>

171 L<isFirst|/isFirst>

172 L<isFirstNonBlank|/isFirst>

173 L<isFirstNonBlankX|/isFirst>

174 L<isFirstX|/isFirst>

175 L<isLast|/isLast>

176 L<isLastNonBlank|/isLast>

177 L<isLastNonBlankX|/isLast>

178 L<isLastX|/isLast>

179 L<isOnlyChild|/isOnlyChild>

180 L<isOnlyChildNonBlank|/isOnlyChild>

181 L<isOnlyChildNonBlankX|/isOnlyChild>

182 L<isOnlyChildX|/isOnlyChild>

183 L<isText|/isText>

184 L<isTextNonBlank|/isText>

185 L<isTextNonBlankX|/isText>

186 L<isTextX|/isText>

187 L<labels|/labels>

188 L<last|/last>

189 L<lastBy|/lastBy>

190 L<lastContextOf|/lastContextOf>

191 L<lastContextOfX|/lastContextOf>

192 L<lastDown|/lastDown>

193 L<lastIn|/lastIn>

194 L<lastInIndex|/lastInIndex>

195 L<lastInIndexNonBlank|/lastInIndex>

196 L<lastInIndexNonBlankX|/lastInIndex>

197 L<lastInIndexX|/lastInIndex>

198 L<lastInX|/lastIn>

199 L<lastNonBlank|/last>

200 L<lastNonBlankX|/last>

201 L<lastText|/lastText>

202 L<lastTextNonBlank|/lastText>

203 L<lastTextNonBlankX|/lastText>

204 L<lastTextX|/lastText>

205 L<lastX|/last>

206 L<listConditions|/listConditions>

207 L<matchAfter|/matchAfter>

208 L<matchAfter2|/matchAfter2>

209 L<matchAfter2NonBlank|/matchAfter2>

210 L<matchAfter2NonBlankX|/matchAfter2>

211 L<matchAfter2X|/matchAfter2>

212 L<matchAfterNonBlank|/matchAfter>

213 L<matchAfterNonBlankX|/matchAfter>

214 L<matchAfterX|/matchAfter>

215 L<matchBefore|/matchBefore>

216 L<matchBefore2|/matchBefore2>

217 L<matchBefore2NonBlank|/matchBefore2>

218 L<matchBefore2NonBlankX|/matchBefore2>

219 L<matchBefore2X|/matchBefore2>

220 L<matchBeforeNonBlank|/matchBefore>

221 L<matchBeforeNonBlankX|/matchBefore>

222 L<matchBeforeX|/matchBefore>

223 L<matchesText|/matchesText>

224 L<matchesTextNonBlank|/matchesText>

225 L<matchesTextNonBlankX|/matchesText>

226 L<matchesTextX|/matchesText>

227 L<moveLabels|/moveLabels>

228 L<navtitle|/navtitle>

229 L<new|/new>

230 L<newTag|/newTag>

231 L<newText|/newText>

232 L<newTree|/newTree>

233 L<next|/next>

234 L<nextIn|/nextIn>

235 L<nextInX|/nextIn>

236 L<nextNonBlank|/next>

237 L<nextNonBlankX|/next>

238 L<nextOn|/nextOn>

239 L<nextText|/nextText>

240 L<nextTextNonBlank|/nextText>

241 L<nextTextNonBlankX|/nextText>

242 L<nextTextX|/nextText>

243 L<nextX|/next>

244 L<nn|/nn>

245 L<number|/number>

246 L<numbering|/numbering>

247 L<numberNode|/numberNode>

248 L<numbers|/numbers>

249 L<numberTree|/numberTree>

250 L<opAt|/opAt>

251 L<opAttr|/opAttr>

252 L<opBy|/opBy>

253 L<opContents|/opContents>

254 L<opGo|/opGo>

255 L<opNew|/opNew>

256 L<opPutFirst|/opPutFirst>

257 L<opPutFirstAssign|/opPutFirstAssign>

258 L<opPutLast|/opPutLast>

259 L<opPutLastAssign|/opPutLastAssign>

260 L<opPutNext|/opPutNext>

261 L<opPutNextAssign|/opPutNextAssign>

262 L<opPutPrev|/opPutPrev>

263 L<opPutPrevAssign|/opPutPrevAssign>

264 L<opString|/opString>

265 L<ordered|/ordered>

266 L<orderedX|/ordered>

267 L<otherprops|/otherprops>

268 L<outputclass|/outputclass>

269 L<over|/over>

270 L<over2|/over2>

271 L<over2NonBlank|/over2>

272 L<over2NonBlankX|/over2>

273 L<over2X|/over2>

274 L<overNonBlank|/over>

275 L<overNonBlankX|/over>

276 L<overX|/over>

277 L<parent|/parent>

278 L<parse|/parse>

279 L<parser|/parser>

280 L<path|/path>

281 L<pathString|/pathString>

282 L<position|/position>

283 L<present|/present>

284 L<prettyString|/prettyString>

285 L<prettyStringCDATA|/prettyStringCDATA>

286 L<prettyStringContent|/prettyStringContent>

287 L<prettyStringContentNumbered|/prettyStringContentNumbered>

288 L<prettyStringEnd|/prettyStringEnd>

289 L<prettyStringNumbered|/prettyStringNumbered>

290 L<prev|/prev>

291 L<prevIn|/prevIn>

292 L<prevInX|/prevIn>

293 L<prevNonBlank|/prev>

294 L<prevNonBlankX|/prev>

295 L<prevOn|/prevOn>

296 L<prevText|/prevText>

297 L<prevTextNonBlank|/prevText>

298 L<prevTextNonBlankX|/prevText>

299 L<prevTextX|/prevText>

300 L<prevX|/prev>

301 L<printAttributes|/printAttributes>

302 L<printAttributesReplacingIdsWithLabels|/printAttributesReplacingIdsWithLabels>

303 L<props|/props>

304 L<putFirst|/putFirst>

305 L<putFirstAsText|/putFirstAsText>

306 L<putFirstAsTextNonBlank|/putFirstAsText>

307 L<putFirstAsTextNonBlankX|/putFirstAsText>

308 L<putFirstNonBlank|/putFirst>

309 L<putFirstNonBlankX|/putFirst>

310 L<putLast|/putLast>

311 L<putLastAsText|/putLastAsText>

312 L<putLastAsTextNonBlank|/putLastAsText>

313 L<putLastAsTextNonBlankX|/putLastAsText>

314 L<putLastNonBlank|/putLast>

315 L<putLastNonBlankX|/putLast>

316 L<putNext|/putNext>

317 L<putNextAsText|/putNextAsText>

318 L<putNextAsTextNonBlank|/putNextAsText>

319 L<putNextAsTextNonBlankX|/putNextAsText>

320 L<putNextNonBlank|/putNext>

321 L<putNextNonBlankX|/putNext>

322 L<putPrev|/putPrev>

323 L<putPrevAsText|/putPrevAsText>

324 L<putPrevAsTextNonBlank|/putPrevAsText>

325 L<putPrevAsTextNonBlankX|/putPrevAsText>

326 L<putPrevNonBlank|/putPrev>

327 L<putPrevNonBlankX|/putPrev>

328 L<reindexNode|/reindexNode>

329 L<renameAttr|/renameAttr>

330 L<renameAttrValue|/renameAttrValue>

331 L<renew|/renew>

332 L<renewNonBlank|/renew>

333 L<renewNonBlankX|/renew>

334 L<replaceContentWith|/replaceContentWith>

335 L<replaceContentWithText|/replaceContentWithText>

336 L<replaceSpecialChars|/replaceSpecialChars>

337 L<replaceWith|/replaceWith>

338 L<replaceWithBlank|/replaceWithBlank>

339 L<replaceWithBlankNonBlank|/replaceWithBlank>

340 L<replaceWithBlankNonBlankX|/replaceWithBlank>

341 L<replaceWithNonBlank|/replaceWith>

342 L<replaceWithNonBlankX|/replaceWith>

343 L<replaceWithText|/replaceWithText>

344 L<replaceWithTextNonBlank|/replaceWithText>

345 L<replaceWithTextNonBlankX|/replaceWithText>

346 L<restore|/restore>

347 L<restoreX|/restore>

348 L<save|/save>

349 L<setAttr|/setAttr>

350 L<string|/string>

351 L<stringContent|/stringContent>

352 L<stringNode|/stringNode>

353 L<stringQuoted|/stringQuoted>

354 L<stringReplacingIdsWithLabels|/stringReplacingIdsWithLabels>

355 L<stringWithConditions|/stringWithConditions>

356 L<style|/style>

357 L<tag|/tag>

358 L<text|/text>

359 L<through|/through>

360 L<throughX|/throughX>

361 L<to|/to>

362 L<tocNumbers|/tocNumbers>

363 L<tree|/tree>

364 L<type|/type>

365 L<unwrap|/unwrap>

366 L<unwrapContentsKeepingText|/unwrapContentsKeepingText>

367 L<unwrapContentsKeepingTextNonBlank|/unwrapContentsKeepingText>

368 L<unwrapContentsKeepingTextNonBlankX|/unwrapContentsKeepingText>

369 L<unwrapContentsKeepingTextX|/unwrapContentsKeepingText>

370 L<unwrapNonBlank|/unwrap>

371 L<unwrapNonBlankX|/unwrap>

372 L<unwrapX|/unwrap>

373 L<upto|/upto>

374 L<uptoX|/upto>

375 L<wrapContentWith|/wrapContentWith>

376 L<wrapDown|/wrapDown>

377 L<wrapTo|/wrapTo>

378 L<wrapToX|/wrapTo>

379 L<wrapUp|/wrapUp>

380 L<wrapWith|/wrapWith>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard L<Module::Build> process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2018 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut


sub aboveX                      {&above                      (@_) || die 'above'}                      
sub afterX                      {&after                      (@_) || die 'after'}                      
sub atX                         {&at                         (@_) || die 'at'}                         
sub atOrBelowX                  {&atOrBelow                  (@_) || die 'atOrBelow'}                  
sub beforeX                     {&before                     (@_) || die 'before'}                     
sub belowX                      {&below                      (@_) || die 'below'}                      
sub changeX                     {&change                     (@_) || die 'change'}                     
sub commonAncestorX             {&commonAncestor             (@_) || die 'commonAncestor'}             
sub contentAsTagsX              {&contentAsTags              (@_) || die 'contentAsTags'}              
sub contentAsTags2X             {&contentAsTags2             (@_) || die 'contentAsTags2'}             
sub equalsX                     {&equals                     (@_) || die 'equals'}                     
sub findByNumberX               {&findByNumber               (@_) || die 'findByNumber'}               
sub firstX                      {&first                      (@_) || die 'first'}                      
sub firstContextOfX             {&firstContextOf             (@_) || die 'firstContextOf'}             
sub firstInX                    {&firstIn                    (@_) || die 'firstIn'}                    
sub firstInIndexX               {&firstInIndex               (@_) || die 'firstInIndex'}               
sub firstTextX                  {&firstText                  (@_) || die 'firstText'}                  
sub goX                         {&go                         (@_) || die 'go'}                         
sub isAllBlankTextX             {&isAllBlankText             (@_) || die 'isAllBlankText'}             
sub isBlankTextX                {&isBlankText                (@_) || die 'isBlankText'}                
sub isEmptyX                    {&isEmpty                    (@_) || die 'isEmpty'}                    
sub isFirstX                    {&isFirst                    (@_) || die 'isFirst'}                    
sub isLastX                     {&isLast                     (@_) || die 'isLast'}                     
sub isOnlyChildX                {&isOnlyChild                (@_) || die 'isOnlyChild'}                
sub isTextX                     {&isText                     (@_) || die 'isText'}                     
sub lastX                       {&last                       (@_) || die 'last'}                       
sub lastContextOfX              {&lastContextOf              (@_) || die 'lastContextOf'}              
sub lastInX                     {&lastIn                     (@_) || die 'lastIn'}                     
sub lastInIndexX                {&lastInIndex                (@_) || die 'lastInIndex'}                
sub lastTextX                   {&lastText                   (@_) || die 'lastText'}                   
sub matchAfterX                 {&matchAfter                 (@_) || die 'matchAfter'}                 
sub matchAfter2X                {&matchAfter2                (@_) || die 'matchAfter2'}                
sub matchBeforeX                {&matchBefore                (@_) || die 'matchBefore'}                
sub matchBefore2X               {&matchBefore2               (@_) || die 'matchBefore2'}               
sub matchesTextX                {&matchesText                (@_) || die 'matchesText'}                
sub nextX                       {&next                       (@_) || die 'next'}                       
sub nextInX                     {&nextIn                     (@_) || die 'nextIn'}                     
sub nextTextX                   {&nextText                   (@_) || die 'nextText'}                   
sub orderedX                    {&ordered                    (@_) || die 'ordered'}                    
sub overX                       {&over                       (@_) || die 'over'}                       
sub over2X                      {&over2                      (@_) || die 'over2'}                      
sub prevX                       {&prev                       (@_) || die 'prev'}                       
sub prevInX                     {&prevIn                     (@_) || die 'prevIn'}                     
sub prevTextX                   {&prevText                   (@_) || die 'prevText'}                   
sub restoreX                    {&restore                    (@_) || die 'restore'}                    
sub unwrapX                     {&unwrap                     (@_) || die 'unwrap'}                     
sub unwrapContentsKeepingTextX  {&unwrapContentsKeepingText  (@_) || die 'unwrapContentsKeepingText'}  
sub uptoX                       {&upto                       (@_) || die 'upto'}                       
sub wrapToX                     {&wrapTo                     (@_) || die 'wrapTo'}                     

sub firstNonBlank
 {my $r = &first($_[0]);
  return undef unless $r;
  if ($r->isBlankText)
   {shift @_;
    return &next($r, @_)
   }
  else
   {return &next(@_);
   }
 }

sub firstNonBlankX
 {my $r = &firstNonBlank(@_);
  die 'first' unless defined($r);
  $r
 }

sub isFirstNonBlank
 {my $r = &isFirst($_[0]);
  return undef unless $r;
  if ($r->isBlankText)
   {shift @_;
    return &isFirst($r, @_)
   }
  else
   {return &isFirst(@_);
   }
 }

sub isFirstNonBlankX
 {my $r = &isFirstNonBlank(@_);
  die 'isFirst' unless defined($r);
  $r
 }

sub isLastNonBlank
 {my $r = &isLast($_[0]);
  return undef unless $r;
  if ($r->isBlankText)
   {shift @_;
    return &isLast($r, @_)
   }
  else
   {return &isLast(@_);
   }
 }

sub isLastNonBlankX
 {my $r = &isLastNonBlank(@_);
  die 'isLast' unless defined($r);
  $r
 }

sub lastNonBlank
 {my $r = &last($_[0]);
  return undef unless $r;
  if ($r->isBlankText)
   {shift @_;
    return &prev($r, @_)
   }
  else
   {return &prev(@_);
   }
 }

sub lastNonBlankX
 {my $r = &lastNonBlank(@_);
  die 'last' unless defined($r);
  $r
 }

sub nextNonBlank
 {my $r = &next($_[0]);
  return undef unless $r;
  if ($r->isBlankText)
   {shift @_;
    return &next($r, @_)
   }
  else
   {return &next(@_);
   }
 }

sub nextNonBlankX
 {my $r = &nextNonBlank(@_);
  die 'next' unless defined($r);
  $r
 }

sub prevNonBlank
 {my $r = &prev($_[0]);
  return undef unless $r;
  if ($r->isBlankText)
   {shift @_;
    return &prev($r, @_)
   }
  else
   {return &prev(@_);
   }
 }

sub prevNonBlankX
 {my $r = &prevNonBlank(@_);
  die 'prev' unless defined($r);
  $r
 }


# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
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
use Test::More tests=>580;
use Data::Table::Text qw(:all);

#Test::More->builder->output("/dev/null");                                       # Show only errors during testing - but this must be commented out for production

sub sample1{my $x = Data::Edit::Xml::new(); $x->input = <<END; $x->parse}       # Sample test XML
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

if (1)
 {my $x = Data::Edit::Xml::new;                                                 #Tparse
     $x->inputString = <<END;                                                   #Tparse
<a id="aa"><b id="bb"><c id="cc"/></b></a>
END
     $x->parse;                                                                 #Tparse
     ok -p $x eq <<END;                                                         #Tparse
<a id="aa">
  <b id="bb">
    <c id="cc"/>
  </b>
</a>
END
 }

sub sample2
 {my $x = Data::Edit::Xml::new;                                                 #TinputString
     $x->inputString = <<END;                                                   #TinputString
<a id="aa"><b id="bb"><c id="cc"/></b></a>
END
     $x->parse;                                                                 #TinputString
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
#   ok nn($x->prettyString)  eq '<foo start="yes">N  <head id="a" key="aaa bbb" start="123">HelloN    N    <em>thereN    </em>N  </head>N  <bar>HowdyN    N    <ref/>N  </bar>NdoNdooN  N  <head id="A" key="AAAA BBBB" start="123">HHHHelloN    N    <b>to youN    </b>N  </head>N  <tail>N    <foot id="11"/>N    <middle id="mm"/>N    <foot id="22"/>N  </tail>N</foo>N';
    ok nn($x->stringContent) eq '<head id="a" key="aaa bbb" start="123">HelloN    <em>there</em></head><bar>HowdyN    <ref/></bar>doNdooN  <head id="A" key="AAAA BBBB" start="123">HHHHelloN    <b>to you</b></head><tail><foot id="11"/><middle id="mm"/><foot id="22"/></tail>';
    ok $x->attr(qq(start))   eq "yes";
       $x->id  = 11;
    ok $x->id == 11;
       $x->deleteAttr(qq(id));
    ok !$x->id;
    ok join(' ', $x->go(qw(head))->attrs(qw(id start))) eq "a 123";
#   ok nn($x->prettyStringContent) eq '<head id="a" key="aaa bbb" start="123">HelloN    N  <em>thereN  </em>N</head>N<bar>HowdyN    N  <ref/>N</bar>NdoNdooN  N<head id="A" key="AAAA BBBB" start="123">HHHHelloN    N  <b>to youN  </b>N</head>N<tail>N  <foot id="11"/>N  <middle id="mm"/>N  <foot id="22"/>N</tail>N';
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

  if (my $h = $x->go(qw(head))) {ok $h->id eq q(a)} else {ok 0}                 # Attributes and sub nodes

 # Contents
  is_deeply [map {$_->tag} $x->contents]                       , [qw(head   bar    CDATA   head   tail)];
  is_deeply [map {$_->tag} $x->go(qw(head))   ->contentAfter],  [qw(bar    CDATA  head    tail)];
  is_deeply [map {$_->tag} $x->go(qw(head), 1)->contentBefore], [qw(head   bar    CDATA)];

  ok $x->contentAsTags  eq join ' ', qw(head bar CDATA head tail);
  ok $x->go(qw(head),0)->contentAfterAsTags eq join ' ', qw(     bar CDATA head tail);
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

  ok $x->go(qw(head))->go(qw(em))->first->at(qw(CDATA em head foo));            # At

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
    ok $a->go(qw(b))  ->id eq q(bb);
    ok $a->go(qw(b c))->id eq q(cc);

    ok -p $a eq <<END;                                                          #TputFirst #Tcut #TcountTags
<a id="aa">
  <b id="bb">
    <c id="cc"/>
  </b>
</a>
END
    ok $a->countTags == 3;                                                      #TcountTags
    my $c = $a->go(qw(b c))->cut;                                               #TputFirst #Tcut

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

    $a->putLast($a->go(qw(c))->cut);                                            #TputLast

    ok -p $a eq <<END;                                                          #TputLast #TputNext
<a id="aa">
  <b id="bb"/>
  <c id="cc"/>
</a>
END

    $a->go(qw(c))->putNext($a->go(q(b))->cut);                                  #TputNext

    ok -p $a eq <<END;                                                          #TputNext #TputPrev
<a id="aa">
  <c id="cc"/>
  <b id="bb"/>
</a>
END

    $a->go(qw(c))->putPrev($a->go(q(b))->cut);                                  #TputPrev

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
    $x->go(q(b))->unwrap;
    ok -s $x eq '<a id="aa"/>';
    eval {$x->unwrap };
    ok $@ =~ m(\ACannot unwrap the outer most node)s;
   }

  if (1) {
    my $x = Data::Edit::Xml::new(qq(<a><b><c><d>DD</d>EE<f>FF</f></c></b></a>));#TunwrapContentsKeepingText
    ok -p $x eq <<END;                                                          #TunwrapContentsKeepingText
<a>
  <b>
    <c>
      <d>DD</d>
EE
      <f>FF</f>
    </c>
  </b>
</a>
END
    $x->go(qw(b))->unwrapContentsKeepingText;                                   #TunwrapContentsKeepingText
    ok -p $x eq <<END;                                                          #TunwrapContentsKeepingText
<a>
  <b>  DD EE FF  </b>
</a>
END
   }

  if (1)
   {my $x = Data::Edit::Xml::new(qq(<a><b><c id="cc"/></b></a>));               #TreplaceWith
    $x->go(qw(b c))->replaceWith($x->newTag(qw(d id dd)));                      #TreplaceWith
    ok -s $x eq '<a><b><d id="dd"/></b></a>';                                   #TreplaceWith
   }

  if (1)
   {my $x = Data::Edit::Xml::new(qq(<a><b><c id="cc"/></b></a>));               #TreplaceWithText
    $x->go(qw(b c))->replaceWithText(qq(BBBB));                                 #TreplaceWithText
    ok -s $x eq '<a><b>BBBB</b></a>';                                           #TreplaceWithText
   }

  if (1)
   {my $x = Data::Edit::Xml::new(qq(<a><b/><c/></a>));                          #TreplaceContentWith
    $x->replaceContentWith(map {$x->newTag($_)} qw(B C));                       #TreplaceContentWith
    ok -s $x eq '<a><B/><C/></a>';                                              #TreplaceContentWith
   }

  if (1)
   {my $x = Data::Edit::Xml::new(qq(<a><b/><c/></a>));                          #TreplaceContentWithText
    $x->replaceContentWithText(qw(b c));                                        #TreplaceContentWithText
    ok -s $x eq '<a>bc</a>';                                                    #TreplaceContentWithText
   }

  if (1)
   {my $x = Data::Edit::Xml::new(qq(<a><b><c id="cc"/></b></a>));               #TreplaceWithBlank
    $x->go(qw(b c))->replaceWithBlank;                                          #TreplaceWithBlank
    ok -s $x eq '<a><b> </b></a>';                                              #TreplaceWithBlank
   }

# Editing - tag /attributes

  ok  sample2->go(q(b))->change(qw(B b a))->parent->string eq '<a id="aa"><B id="bb"><c id="cc"/></B></a>';
  ok !sample2->go(q(b))->change(qw(B c a));
  ok  sample2->go(q(b))->setAttr(aa=>11, bb=>22)->parent->string eq '<a id="aa"><b aa="11" bb="22" id="bb"><c id="cc"/></b></a>';
  ok  sample2->go(qw(b c))->setAttr(aa=>11, bb=>22)->parent->parent->string eq '<a id="aa"><b id="bb"><c aa="11" bb="22" id="cc"/></b></a>';
  ok  sample2->deleteAttr(qw(id))->string eq '<a><b id="bb"><c id="cc"/></b></a>';
  ok  sample2->renameAttr(qw(id ID))->string eq '<a ID="aa"><b id="bb"><c id="cc"/></b></a>';
  ok  sample2->changeAttr(qw(ID id))->id eq qq(aa);

  ok  sample2->renameAttrValue(qw(id aa ID AA))->string eq '<a ID="AA"><b id="bb"><c id="cc"/></b></a>';
  ok  sample2->changeAttrValue(qw(ID AA id aa))->id eq qq(aa);
 }

if (1)
 {my $x = Data::Edit::Xml::new(<<END);                                          #TstringWithConditions
<a>
  <b/>
  <c/>
</a>
END

  my $b = $x >= 'b';                                                            #TstringWithConditions
  my $c = $x >= 'c';                                                            #TstringWithConditions

  $b->addConditions(qw(bb BB));                                                 #TstringWithConditions #TaddConditions #TlistConditions
  $c->addConditions(qw(cc CC));                                                 #TstringWithConditions

  ok join(' ', $b->listConditions) eq 'BB bb';                                  #TdeleteConditions     #TaddConditions #TlistConditions
  $b->deleteConditions(qw(BB));                                                 #TdeleteConditions
  ok join(' ', $b->listConditions) eq 'bb';                                     #TdeleteConditions

  ok $x->stringWithConditions         eq '<a><b/><c/></a>';                     #TstringWithConditions
  ok $x->stringWithConditions(qw(bb)) eq '<a><b/></a>';                         #TstringWithConditions
  ok $x->stringWithConditions(qw(cc)) eq '<a><c/></a>';                         #TstringWithConditions
 }

if (1)
 {my $x = Data::Edit::Xml::new(my $s = <<END);                                  #Tattr
<a number="1"/>
END
  ok $x->attr(qq(number)) == 1;                                                 #Tattr
     $x->attr(qq(number))  = 2;                                                 #Tattr
  ok $x->attr(qq(number)) == 2;                                                 #Tattr
  ok -s $x eq '<a number="2"/>';                                                #Tattr

  $x->attr(qq(delete))  = "me";
  ok -s $x eq '<a delete="me" number="2"/>';                                    #TdeleteAttr
  $x->deleteAttr(qq(delete));                                                   #TdeleteAttr
  ok -s $x eq '<a number="2"/>';                                                #TdeleteAttr #TsetAttr

  $x->setAttr(first=>1, second=>2, last=>undef);                                #TsetAttr

  ok -s $x eq '<a first="1" number="2" second="2"/>';                           #TdeleteAttrs #Tattrs #TsetAttr #TgetAttrs #TattrCount
  ok $x->attrCount == 3;                                                        #TattrCount
  is_deeply [$x->attrs(qw(third second first ))], [undef, 2, 1];                #Tattrs
  is_deeply [$x->getAttrs], [qw(first number second)];                          #TgetAttrs

  $x->deleteAttrs(qw(first second third number));                               #TdeleteAttrs
  ok -s $x eq '<a/>';                                                           #TdeleteAttrs
 }

if (1)
 {my $a = Data::Edit::Xml::new('<a number="1"/>');                              #TopAttr
  ok $a %  qq(number) == 1;                                                     #TopAttr
 }

#if (1)
# {my $a = Data::Edit::Xml::new("<a/>");                                        TopSetTag
#  $a += qq(b);                                                                 TopSetTag
#  ok -s $a eq "<b/>";                                                          TopSetTag
# }

if (1)
 {my $c = Data::Edit::Xml::new("<c/>");                                         #TopWrapWith
  my $b = $c / qq(b);                                                           #TopWrapWith
  ok -s $b eq "<b><c/></b>";                                                    #TopWrapWith
  my $a = $b / qq(a);                                                           #TopWrapWith
  ok -s $a eq "<a><b><c/></b></a>";                                             #TopWrapWith
 }

if (1)
 {my $a = Data::Edit::Xml::new("<a><b><c/></b></a>");                           #TopUnWrap
  my $b = $a >= 'b';                                                            #TopUnWrap
   ++$b;                                                                        #TopUnWrap
  ok -s $a eq "<a><c/></a>";                                                    #TopUnWrap
 }

if (1)
 {my $x = Data::Edit::Xml::new(my $s = <<END);                                  #TprintAttributes
<a no="1" word="first"/>
END
  ok $x->printAttributes eq qq( no="1" word="first");                           #TrenameAttr #TprintAttributes
  $x->renameAttr(qw(no number));                                                #TrenameAttr
  ok $x->printAttributes eq qq( number="1" word="first");                       #TrenameAttr #TchangeAttr
  $x->changeAttr(qw(number word));                                              #TchangeAttr
  ok $x->printAttributes eq qq( number="1" word="first");                       #TchangeAttr #TrenameAttrValue

  $x->renameAttrValue(qw(number 1 numeral I));                                  #TrenameAttrValue
  ok $x->printAttributes eq qq( numeral="I" word="first");                      #TrenameAttrValue #TchangeAttrValue

  $x->changeAttrValue(qw(word second greek mono));                              #TchangeAttrValue
  ok $x->printAttributes eq qq( numeral="I" word="first");                      #TchangeAttrValue
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
 {my $f = temporaryFile;
  writeFile($f, "<a> <b/>   <c/> <d/> </a>");
  my $x = Data::Edit::Xml::new($f);
  unlink $f;
  $x->putFirstAsText(' ');
  $x->go(q(b))->putNextAsText(' ');
  $x->go(q(d))->putPrevAsText(' ');
  $x->putLastAsText(' ');

  ok $x->countTags == 8;
  ok $x->contentAsTags eq "CDATA b CDATA c CDATA d CDATA";
  my $c = $x->go(qw(c));
  $c->replaceWithBlank;

  ok $x->countTags == 6;
  ok $x->contentAsTags eq "CDATA b CDATA d CDATA";
 }

if (1)                                                                          # Blank text
 {my $f = temporaryFile;
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

if (1)
 {my $a = Data::Edit::Xml::new("<a><b>A</b></a>");                              #TprettyStringCDATA
  my $b = $a->first;                                                            #TprettyStringCDATA
     $b->first->replaceWithBlank;                                               #TprettyStringCDATA
  ok $a->prettyStringCDATA eq <<END;                                            #TprettyStringCDATA #TisText #TisBlankText
<a>
    <b><CDATA> </CDATA></b>
</a>
END
  ok $b->first->isText;                                                         #TisText
  ok $b->first->isText(qw(b a));                                                #TisText
  ok $b->first->isBlankText;                                                    #TisBlankText
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
  my $d = $c->newTag(q(d));
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

  my $p = $c->upto(q(d));
  ok !$p;
 }

if (1)
 {my $x = Data::Edit::Xml::new(<<END);                                          #TcontentAsTags #TcontentAfterAsTags #TcontentBeforeAsTags #TcontentAfter #Tover #Tover2 #TmatchAfter #TmatchAfter2  #TcontentAfterAsTags2 #TmatchBefore #TmatchBefore2 #TcontentBefore #TcontentBeforeAsTags2
<a>
  <b>
    <c/><d/><e/><f/><g/>
  </b>
</a>
END

  ok $x->go(q(b))->contentAsTags eq 'c d e f g';                                #TcontentAsTags

  ok 'f g' eq join ' ', map {$_->tag} $x->go(qw(b e))->contentAfter;            #TcontentAfterAsTags
  ok 'c d' eq join ' ', map {$_->tag} $x->go(qw(b e))->contentBefore;           #TcontentBeforeAsTags

  ok $x->go(qw(b e))->contentAfterAsTags eq 'f g';                              #TcontentAfterAsTags
  ok $x->go(qw(b e))->contentBeforeAsTags eq 'c d';                             #TcontentBeforeAsTags

  ok 'f g' eq join ' ', map {$_->tag} $x->go(qw(b e))->contentAfter;            #TcontentAfter
  ok 'c d' eq join ' ', map {$_->tag} $x->go(qw(b e))->contentBefore;           #TcontentBefore

  ok $x->go(q(b))->over(qr(d.+e));                                              #Tover
  ok $x->go(q(b))->over2(qr(\A c  d  e  f  g \Z));                              #Tover2
  ok $x->go(q(b))->contentAsTags  eq q(c d e f g) ;                             #Tover2
  ok $x->go(q(b))->contentAsTags2 eq q( c  d  e  f  g );                        #TcontentAsTags2
  ok $x->go(qw(b e))->matchAfter  (qr(\Af g\Z));                                #TmatchAfter
  ok $x->go(qw(b e))->matchAfter2 (qr(\A f  g \Z));                             #TmatchAfter2
  ok $x->go(qw(b e))->contentAfterAsTags2 eq q( f  g );                         #TcontentAfterAsTags2
  ok $x->go(qw(b e))->matchBefore (qr(\Ac d\Z));                                #TmatchBefore
  ok $x->go(qw(b e))->matchBefore2(qr(\A c  d \Z));                             #TmatchBefore2
  ok $x->go(qw(b e))->contentBeforeAsTags2 eq q( c  d );                        #TcontentBeforeAsTags2
 }

if (1)
 {my $x = Data::Edit::Xml::new(<<END);                                          #Tnew #TopString
<a>
  <b>
    <c id="42"/>
  </b>
  <d>
    <e/>
  </d>
</a>
END

  my $prev = -b $x->go(q(d));                                                   #TopString
  ok -t $prev eq q(b);                                                          #TopString

  my $next = -c $x->go(q(b));                                                   #TopString
  ok -t $next eq q(d);                                                          #TopString

  my $first = -f $x;                                                            #TopString
  ok -t $first eq q(b);                                                         #TopString

  my $last  = -l $x;                                                            #TopString
  ok -t $last eq q(d);                                                          #TopString

  ok -o $x eq "'<a><b><c id=\"42\"/></b><d><e/></d></a>'";                      #TopString

  ok -p $x eq <<END;                                                            #tdown #tdownX #TdownReverse #TdownReverseX #Tby #TopBy #TbyX #TbyReverse #TbyReverseX #Tnew #Tstring #TopString #Tcontext #TisFirst #TisLast #TopContents #TopGo #TopAt
<a>
  <b>
    <c id="42"/>
  </b>
  <d>
    <e/>
  </d>
</a>
END

  ok -s $x eq '<a><b><c id="42"/></b><d><e/></d></a>';                          #TopString

  ok -t $x eq 'a';                                                              #TopString

  $x->numberTree;                                                               #TopString #TnumberTree
  ok -z $x eq <<END;                                                            #TopString #TnumberTree
<a id="1">
  <b id="2">
    <c id="42"/>
  </b>
  <d id="4">
    <e id="5"/>
  </d>
</a>
END

  ok 'bd' eq join '', map {$_->tag} @$x ;                                       #TopContents
  ok (($x >= [qw(d e)]) <= [qw(e d a)]);                                        #TopGo #TopAt
  ok -s $x eq '<a><b><c id="42"/></b><d><e/></d></a>';                          #Tstring

  ok $x->go(qw(d e))->context eq 'e d a';                                       #Tcontext
  ok $x->go(q(b))->isFirst;                                                     #TisFirst
  ok $x->go(q(d))->isLast;                                                      #TisLast

  if (1)
   {my $s; $x->down(sub{$s .= $_->tag}); ok $s eq "abcde"                       #Tdown #TdownX
   }
  if (1)
   {my $s; $x->downReverse(sub{$s .= $_->tag}); ok $s eq "adebc"                #TdownReverse #TdownReverseX
   }
  if (1)
   {my $s; $x->by(sub{$s .= $_->tag}); ok $s eq "cbeda"                         #Tby
   }
  if (1)
   {my $s; $x->byX(sub{$s .= $_->tag}); ok $s eq "cbeda"                        #TbyX
   }
  if (1)
   {my $s; $x x= sub{$s .= -t $_}; ok $s eq "cbeda"                             #TopBy
   }
  if (1)
   {my $s; $x->byReverse(sub{$s .= $_->tag}); ok $s eq "edcba"                  #TbyReverse #TbyReverseX
   }

  if (1)
   {my $s; my $n = sub{$s .= $_->tag}; $x->through($n, $n);                     #Tthrough #TthroughX
    ok $s eq "abccbdeeda"                                                       #Tthrough #TthroughX
   }
 }

if (1)
 {my $x = Data::Edit::Xml::new(<<END);                                          #TopCut
<a>
  <b><c/></b>
</a>
END

  my $b = $x >= qq(b);                                                          #TopCut
   --$b;                                                                        #TopCut
  ok -s $x eq "<a/>";                                                           #TopCut
  ok -s $b eq "<b><c/></b>";                                                    #TopCut
 }

if (1)
 {my $a = Data::Edit::Xml::new('<a/>');
  ok -p $a eq <<END;                                                            #TopPutFirst
<a/>
END
  my $f = $a >> qq(first);                                                      #TopPutFirst
  ok -p $a eq <<END;                                                            #TopPutFirst #TopPutLast
<a>
  <first/>
</a>
END
  my $l = $a << qq(last);                                                       #TopPutLast
  ok -p $a eq <<END;                                                            #TopPutLast #TopPutNext
<a>
  <first/>
  <last/>
</a>
END

  $f += qq(next);                                                               #TopPutNext
  ok -p $a eq <<END;                                                            #TopPutNext  #TopPutPrev
<a>
  <first/>
  <next/>
  <last/>
</a>
END
  $l -= qq(prev);                                                               #TopPutPrev
  ok -p $a eq <<END;                                                            #TopPutPrev
<a>
  <first/>
  <next/>
  <prev/>
  <last/>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new('<a/>');
  ok -p $a eq <<END;                                                            #TopPutFirstAssign
<a/>
END
  my $n = $a ** qq(z);
  ok $n->tag eq q(z);

  $a >>= qq(first);                                                             #TopPutFirstAssign
  ok -p $a eq <<END;                                                            #TopPutFirstAssign #TopPutLastAssign
<a>
  <first/>
</a>
END
  $a <<= qq(last);                                                              #TopPutLastAssign
  ok -p $a eq <<END;                                                            #TopPutLastAssign #TopPutNextAssign
<a>
  <first/>
  <last/>
</a>
END

  my $f = -f $a;                                                                #TopPutNextAssign
  $f += qq(next);                                                               #TopPutNextAssign
  ok -p $a eq <<END;                                                            #TopPutNextAssign  #TopPutPrevAssign
<a>
  <first/>
  <next/>
  <last/>
</a>
END
  my $l = -l $a;                                                                #TopPutPrevAssign
  $l -= qq(prev);                                                               #TopPutPrevAssign
  ok -p $a eq <<END;                                                            #TopPutPrevAssign
<a>
  <first/>
  <next/>
  <prev/>
  <last/>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new("<a/>");                                         #TopNew
  my $b = $a ** q(b);                                                           #TopNew
  ok -s $b eq "<b/>";                                                           #TopNew
 }

if (1)                                                                          # NextOn
 {my $a = Data::Edit::Xml::new("<a><b><c id='1'/><d id='2'/><c id='3'/><d id='4'/><e id='5'/></b></a>");
  ok -p $a eq <<END;                                                            #TnextOn #TprevOn
<a>
  <b>
    <c id="1"/>
    <d id="2"/>
    <c id="3"/>
    <d id="4"/>
    <e id="5"/>
  </b>
</a>
END
  my $c = $a->firstContextOf(qw(c));
  my $e = $a->lastContextOf(qw(e));
  ok $c->id == 1;                                                               #TnextOn #TprevOn
  ok $e->id == 5;                                                               ##TnextOn #TprevOn
  ok $c->nextOn(qw(d))  ->id == 2;                                              #TnextOn
  ok $c->nextOn(qw(c d))->id == 4;                                              #TnextOn
  ok $e->nextOn(qw(c d))     == $e;                                             #TnextOn
  ok $e->prevOn(qw(d))  ->id == 4;                                              #TprevOn
  ok $e->prevOn(qw(c d))     == $c;                                             #TprevOn

  my $x = $a >= [qw(b c 1)];
  my $w = -b $x;
  my $y = -c $x;
  ok -s $w eq '<d id="2"/>';
  ok -s $y eq '<d id="4"/>';

  is_deeply {$a->first->present}, {c=>2, d=>2, e=>1};                           #Tpresent
 }

if (1)                                                                          # Put as text
 {my $x = Data::Edit::Xml::new(<<END);
<a id="aa"><b id="bb"><c id="cc"/></b></a>
END

  ok -p $x eq <<END;                                                            #TputFirstAsText
<a id="aa">
  <b id="bb">
    <c id="cc"/>
  </b>
</a>
END

  $x->go(qw(b c))->putFirstAsText("<d id=\"dd\">DDDD</d>");                     #TputFirstAsText
  ok -p $x eq <<END;                                                            #TputFirstAsText #TputLastAsText
<a id="aa">
  <b id="bb">
    <c id="cc"><d id="dd">DDDD</d></c>
  </b>
</a>
END

  $x->go(qw(b c))->putLastAsText("<e id=\"ee\">EEEE</e>");                      #TputLastAsText
  ok -p $x eq <<END;                                                            #TputLastAsText #TputNextAsText
<a id="aa">
  <b id="bb">
    <c id="cc"><d id="dd">DDDD</d><e id="ee">EEEE</e></c>
  </b>
</a>
END

  $x->go(qw(b c))->putNextAsText("<n id=\"nn\">NNNN</n>");                      #TputNextAsText
  ok -p $x eq <<END;                                                            #TputNextAsText  #TputPrevAsText
<a id="aa">
  <b id="bb">
    <c id="cc"><d id="dd">DDDD</d><e id="ee">EEEE</e></c>
<n id="nn">NNNN</n>
  </b>
</a>
END

  $x->go(qw(b c))->putPrevAsText("<p id=\"pp\">PPPP</p>");                      #TputPrevAsText

  ok -p $x eq <<END;                                                            #TputPrevAsText
<a id="aa">
  <b id="bb"><p id="pp">PPPP</p>
    <c id="cc"><d id="dd">DDDD</d><e id="ee">EEEE</e></c>
<n id="nn">NNNN</n>
  </b>
</a>
END
}

if (1)                                                                          # Next/Prev Text
 {my $a = Data::Edit::Xml::new("<a>AA<b/>BB<c/>CC<d/><e/><f/>DD<g/>HH</a>");
  ok -p $a eq <<END;                                                            #TfirstText #TlastText #TnextText #TprevText
<a>AA
  <b/>
BB
  <c/>
CC
  <d/>
  <e/>
  <f/>
DD
  <g/>
HH
</a>
END
  ok  $a->firstText;                                                            #TfirstText
  ok !$a->go(qw(c))->firstText;                                                 #TfirstText
  ok  $a->lastText;                                                             #TlastText
  ok !$a->go(qw(c))->lastText;                                                  #TlastText
  ok  $a->go(qw(c))->nextText->text eq q(CC);                                   #TnextText
  ok !$a->go(qw(e))->nextText;                                                  #TnextText
  ok  $a->go(qw(c))->prevText->text eq q(BB);                                   #TprevText
  ok !$a->go(qw(e))->prevText;                                                  #TprevText
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #Tfirst #Tlast #Tnext #Tprev #TfirstBy #TlastBy #Tindex #Tposition
<a         id="11">
  <b       id="12">
     <c    id="13"/>
     <d    id="14"/>
     <b    id="15">
        <c id="16"/>
        <d id="17"/>
        <e id="18"/>
        <f id="19"/>
        <g id="20"/>
     </b>
     <f    id="21"/>
     <g    id="22"/>
  </b>
  <b       id="23">
     <c    id="24"/>
     <d    id="25"/>
     <b    id="26">
        <c id="27"/>
        <d id="28"/>
        <e id="29"/>
        <f id="30"/>
        <g id="31"/>
     </b>
     <f    id="32"/>
     <g    id="33"/>
  </b>
</a>
END

  ok $a->go(qw(b 1))->id == 23;                                                 #Tindex
  ok $a->go(qw(b 1))->index == 1;                                               #Tindex

  ok $a->go(qw(b 1 b))->id == 26;                                               #Tposition
  ok $a->go(qw(b 1 b))->position == 2;                                          #Tposition

  ok  $a->go(q(b))->first->id == 13;                                            #Tfirst
  ok  $a->go(q(b))->first(qw(c b a));                                           #Tfirst
  ok !$a->go(q(b))->first(qw(b a));                                             #Tfirst

  ok  $a->go(q(b))->last ->id == 22;                                            #Tlast
  ok  $a->go(q(b))->last(qw(g b a));                                            #Tlast
  ok !$a->go(q(b))->last(qw(b a));                                              #Tlast
  ok !$a->go(q(b))->last(qw(b a));                                              #Tlast

  ok  $a->go(qw(b b e))->next ->id == 19;                                       #Tnext
  ok  $a->go(qw(b b e))->next(qw(f b b a));                                     #Tnext
  ok !$a->go(qw(b b e))->next(qw(f b a));                                       #Tnext

  ok  $a->go(qw(b b e))->prev ->id == 17;                                       #Tprev
  ok  $a->go(qw(b b e))->prev(qw(d b b a));                                     #Tprev
  ok !$a->go(qw(b b e))->prev(qw(d b a));                                       #Tprev

  if (1)
   {my %f = $a->firstBy;                                                        #TfirstBy
    ok $f{b}->id == 12;                                                         #TfirstBy
   }

  if (1)
   {my %f = $a->firstDown;                                                      #TfirstDown
    ok $f{b}->id == 15;                                                         #TfirstDown
   }

  if (1)
   {my %l = $a->lastBy;                                                         #TlastBy
    ok $l{b}->id == 23;                                                         #TlastBy
   }

  if (1)
   {my %l = $a->lastDown;                                                       #TlastDown
    ok $l{b}->id == 26;                                                         #TlastDown
   }
 }

if (1)
 {my $x = Data::Edit::Xml::new(<<END);                                          #TfirstContextOf #TlastContextOf
<a        id="a1">
  <b1     id="b1">
     <c   id="c1">
       <d id="d1">DD11</d>
       <e id="e1">EE11</e>
    </c>
  </b1>
  <b2     id="b2">
     <c   id="c2">
       <d id="d2">DD22</d>
       <e id="e2">EE22</e>
    </c>
  </b2>
  <b3     id="b3">
     <c   id="c3">
       <d id="d3">DD33</d>
       <e id="e3">EE33</e>
    </c>
  </b3>
</a>
END

  ok $x->firstContextOf(qw(d c))         ->id     eq qq(d1);                    #TfirstContextOf
  ok $x->firstContextOf(qw(e c b2))      ->id     eq qq(e2);                    #TfirstContextOf
  ok $x->firstContextOf(qw(CDATA d c b2))->string eq qq(DD22);                  #TfirstContextOf

  ok $x-> lastContextOf(qw(d c))         ->id     eq qq(d3);                    #TlastContextOf
  ok $x-> lastContextOf(qw(e c b2     )) ->id     eq qq(e2);                    #TlastContextOf
  ok $x-> lastContextOf(qw(CDATA e c b2))->string eq qq(EE22);                  #TlastContextOf
 }

if (1)                                                                          # New
 {my $x = Data::Edit::Xml::newTree("a", id=>1, class=>"aa");                    #TnewTree #TnewTag
  ok -s $x eq '<a class="aa" id="1"/>';                                         #TnewTree
  ok $x->attrCount == 2;
  $x->putLast($x->newTag("b", id=>2, class=>"bb"));                             #TnewTag
  ok $x->go(q(b))->attrCount == 2;
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

if (1)                                                                          # Well known attributes
 {my $a = Data::Edit::Xml::newTree("a", id=>1, class=>2, href=>3, outputclass=>4); #TcountOutputClasses

  ok $a->id          == 1;
  ok $a->class       == 2;
  ok $a->href        == 3;
  ok $a->outputclass == 4;

  is_deeply { 4 => 1 }, $a->countOutputClasses;                                 #TcountOutputClasses
 }

if (1)                                                                          # Spares
 {my $c = Data::Edit::Xml::newTree("c", id=>33);                                #TwrapUp
  my ($b, $a) = $c->wrapUp(qw(b a));                                            #TwrapUp
  ok -p $a eq <<'END';                                                          #TwrapUp
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
  ok -p $a eq <<END;                                                            #TwrapDown
<a id="33">
  <b>
    <c/>
  </b>
</a>
END
 }

if (1)                                                                          # Matches text
 {my $x = Data::Edit::Xml::new(<<END);                                          #TmatchesText
<a>
  <b>
    <c>CDECD</c>
  </b>
</a>
END
  my $c = $x->go(qw(b c))->first;                                               #TmatchesText
  is_deeply [qw(E)], [$c->matchesText(qr(CD(.)CD))];                            #TmatchesText
  ok !$c->matchesText(qr(\AD));                                                 #TmatchesText
  ok  $c->matchesText(qr(\AC), qw(c b a));                                      #TmatchesText
  ok !$c->matchesText(qr(\AD), qw(c b a));                                      #TmatchesText
 }

if (1)                                                                          # Create
 {my $x = Data::Edit::Xml::new(<<END);
<a>
  <b>
    <C/>
  </b>
  <c>
    <D/>
     E
    </c>
  <d>
    <F/>
    <G/>
    <H/>
  </d>
  <e/>
</a>
END

  $x->go(qw(d G))->replaceWithBlank;
  ok $x->prettyStringCDATA eq <<END;                                            #TbitsNodeTextBlank
<a>
    <b>
        <C/>
    </b>
    <c>
        <D/>
<CDATA>
     E
    </CDATA>
    </c>
    <d>
        <F/>
<CDATA> </CDATA>
        <H/>
    </d>
    <e/>
</a>
END

  ok '100' eq -B $x;                                                            #TbitsNodeTextBlank
  ok '100' eq -B $x->go(q(b));                                                  #TbitsNodeTextBlank
  ok '110' eq -B $x->go(q(c));                                                  #TbitsNodeTextBlank
  ok '111' eq -B $x->go(q(d));                                                  #TbitsNodeTextBlank
  ok !-B $x->go(qw(e));                                                         #TbitsNodeTextBlank
 }

if (1)                                                                          # Default error file
 {my $a = eval {Data::Edit::Xml::new("</a>")};
  my ($m, $f) = split /\n/, $@;
  ok $m =~ m(Xml parse error, see file:)s;
  ok -e $f;
  unlink $f;
  $f =~ s'out.data'';
  rmdir $f;
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TisAllBlankText
<a>
  <b>
    <c>
      <z/>
    </c>
  </b>
  <d/>
</a>
END
  $a->by(sub{$_->replaceWithBlank(qw(z))});                                     #TisAllBlankText
  my ($b, $c, $d) = $a->firstBy(qw(b c d));                                     #TisAllBlankText
  ok !$b->isEmpty;
  ok !$b->isAllBlankText;
  ok !$c->isEmpty;
  ok  $c->isAllBlankText;                                                       #TisAllBlankText
  ok  $c->isAllBlankText(qw(c b a));                                            #TisAllBlankText
  ok !$c->isAllBlankText(qw(c a));                                              #TisAllBlankText
  ok  $d->isEmpty;
  ok  $d->isEmpty(qw(d a));
  ok !$d->isEmpty(qw(d b));
  ok  $d->isAllBlankText;
  ok  $d->isAllBlankText(qw(d a));
  ok !$d->isAllBlankText(qw(d b));
  ok  $a->first(qw(b a)) == $b;
  ok !$a->first(qw(a));
  ok  $a->last(qw(d a))  == $d;
  ok !$a->last(qw(a));
  ok  $b->next(qw(d a))  == $d;
  ok !$b->next(qw(a));
  ok  $d->prev(qw(b a))  == $b;
  ok !$d->prev(qw(a));

  ok  $b->isFirst;
  ok  $b->isFirst(qw(b a));
  ok !$b->isFirst(qw(a));

  ok  $d->isLast;
  ok  $d->isLast(qw(d a));
  ok !$d->isLast(qw(a));

  $d->props = q(Props);
  $d->otherprops = q(OtherProps);
  $d->style = q(Style);
  ok $d->printAttributes eq
    q( otherprops="OtherProps" props="Props" style="Style");
  my $D = $d->countAttrNames;
  is_deeply $D, { otherprops => 1, props => 1, style => 1 };

  ok  $c->at(q(c), undef, q(a));
  ok !$c->cut(qw(b a));
}

if (1)                                                                          # Unwrap
 {my $x = Data::Edit::Xml::new("<a><b><c/></b></a>");
  $x->go(qw(b c))->unwrap;
  $x->checkParentage;
  ok -s $x eq "<a><b/></a>";
  $x->go(q(b))->unwrap;
  ok -s $x eq "<a/>";
  eval {$x->unwrap};
  ok $@ =~ /\ACannot unwrap the outer most node/gs;
 }

if (1)
 {my $a = Data::Edit::Xml::new("<a> </a>");                                     #Tequals #Tclone
  my $A = $a->clone;                                                            #Tequals #Tclone
  ok -s $A eq q(<a/>);                                                          #Tequals #Tclone
  ok $a->equals($A);                                                            #Tequals #Tclone
 }

if (1)
 {my $a = Data::Edit::Xml::new("<a/>");                                         #Trenew
  $a->putFirstAsText(qq(<b/>));                                                 #Trenew
  ok !$a->go(q(b));                                                             #Trenew
  my $A = $a->renew;                                                            #Trenew
  ok -t $A->go(q(b)) eq q(b)                                                    #Trenew
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);
<a><b><c><b><b><b><b><c/></b></b></b></b></c></b></a>
END

  $a->numberTree;                                                               #Tupto
  ok -z $a eq <<END;                                                            #Tupto
<a id="1">
  <b id="2">
    <c id="3">
      <b id="4">
        <b id="5">
          <b id="6">
            <b id="7">
              <c id="8"/>
            </b>
          </b>
        </b>
      </b>
    </c>
  </b>
</a>
END

  ok $a->findByNumber(8)->upto(qw(b c))->number == 4;                           #Tupto #Tnumber
 }

if (1)
 {ok Data::Edit::Xml::cdata eq q(CDATA);                                        #Tcdata
  ok Data::Edit::Xml::replaceSpecialChars(q(<">)) eq "&lt;&quot;&gt;";          #TreplaceSpecialChars
 }

if (1)                                                                          # Break in and out
 {my $A = Data::Edit::Xml::new("<a><b><d/><c/><c/><e/><c/><c/><d/></b></a>");   #TbreakOut
  ok -p $A eq <<END;
<a>
  <b>
    <d/>
    <c/>
    <c/>
    <e/>
    <c/>
    <c/>
    <d/>
  </b>
</a>
END

  if (1)
   {my $a = $A->clone;
    $a->go(q(b))->breakOut($a, qw(d e));                                        #TbreakOut
    ok -p $a eq <<END;                                                          #TbreakOut #TbreakIn
<a>
  <d/>
  <b>
    <c/>
    <c/>
  </b>
  <e/>
  <b>
    <c/>
    <c/>
  </b>
  <d/>
</a>
END

    $a->go(qw(b 1))->breakIn;                                                   #TbreakIn
    ok -p $a eq <<END;                                                          #TbreakIn
<a>
  <b>
    <d/>
    <c/>
    <c/>
    <e/>
    <c/>
    <c/>
    <d/>
  </b>
</a>
END

    $a->go(q(b))->breakOut($a, qw(d e));                                        # Break backwards

    ok -p $a eq <<END;                                                          #TbreakInBackwards
<a>
  <d/>
  <b>
    <c/>
    <c/>
  </b>
  <e/>
  <b>
    <c/>
    <c/>
  </b>
  <d/>
</a>
END

    $a->go(qw(b 1))->breakInBackwards;                                          #TbreakInBackwards
    ok -p $a eq <<END;                                                          #TbreakInBackwards
<a>
  <b>
    <d/>
    <c/>
    <c/>
    <e/>
    <c/>
    <c/>
  </b>
  <d/>
</a>
END

    my $d = $a->go(q(d))->cut;
    eval {$d->putLast($d)};
    ok $@ =~ m/\ARecursive insertion attempted/s;
    $a->go(q(b))->putLast($d);
    ok $A->equals($a);

    $a->go(q(b))->breakOut($a, qw(d e));

    ok -p $a eq <<END;                                                          #TbreakInForwards
<a>
  <d/>
  <b>
    <c/>
    <c/>
  </b>
  <e/>
  <b>
    <c/>
    <c/>
  </b>
  <d/>
</a>
END

    $a->go(q(b))->breakInForwards;                                              #TbreakInForwards
    ok -p $a eq <<END;                                                          #TbreakInForwards
<a>
  <d/>
  <b>
    <c/>
    <c/>
    <e/>
    <c/>
    <c/>
    <d/>
  </b>
</a>
END

    my $D = $a->go(q(d))->cut;
    eval {$D->putFirst($D)};
    ok $@ =~ m/\ARecursive insertion attempted/s;
    $a->go(q(b))->putFirst($D);
    ok $A->equals($a);
   }
 }

if (1)
 {my @tags = qw(a b c d e);
  my $x = Data::Edit::Xml::new(<<END);                                          #Tordered #Tpath #Tdisordered #Tabove #Tbelow #Tbefore #Tafter
<a       id='a1'>
  <b     id='b1'>
    <c   id='c1'/>
    <c   id='c2'/>
    <d   id='d1'>
      <e id='e1'/>
    </d>
    <c   id='c3'/>
    <c   id='c4'/>
    <d   id='d2'>
      <e id='e2'/>
    </d>
    <c   id='c5'/>
    <c   id='c6'/>
  </b>
</a>
END
  my ($a, $b, $c, $d, $e) = $x->firstDown(@tags);                               # firstDown
  my ($A, $B, $C, $D, $E) = $x->lastDown(@tags);                                # lastDown

  ok eval ' $'.$_    .'->tag eq "'.$_.'"' for @tags;                            # Tags equal their variable names
  ok eval ' $'.uc($_).'->tag eq "'.$_.'"' for @tags;                            # Tags equal their lowercased uppercase variable names
  ok eval ' $'.$_     .'->ordered($'.uc($_).')->tag eq $'.$_.'->tag'  for @tags;# Lowercase nodes precede uppercase nodes
  ok eval '!$'.uc($_).'->ordered($'.$_    .') or $'.$_.' == $'.uc($_) for @tags;# Uppercase nodes equal lowercase nodes or do not precede them

  ok $A == $a;
  ok $B == $b;
  ok $C == $b->go(qw(c 5));
  ok $D == $b->go(qw(d -1));
  ok $E == $D->go(qw(e));

  is_deeply [$x->go(qw(b d 1 e))->path], [qw(b d 1 e)];                         #Tpath
  $x->by(sub {ok $x->go($_->path) == $_});                                      #Tpath

  ok $a->id eq 'a1';
  ok $b->id eq 'b1';                                                            #Tdisordered #Tabove
  ok $c->id eq 'c1';                                                            #Tdisordered #Tafter
  ok $d->id eq 'd1';                                                            #Tdisordered #Tbelow
  ok $e->id eq "e1";                                                            #Tordered    #Tabove #Tbelow #Tdisordered #Tbefore #Tafter
  ok $E->id eq "e2";                                                            #Tordered    #Tabove #Tbefore

  ok  $b->above($e);                                                            #Tabove
  ok !$E->above($e);                                                            #Tabove
  ok !$d->below($e);                                                            #Tbelow

  ok  $e->disordered($c        )->id eq "c1";                                   #Tdisordered
  ok  $b->disordered($c, $e, $d)->id eq "d1";                                   #Tdisordered
  ok !$c->disordered($e);                                                       #Tdisordered

  ok  $e->ordered($E);                                                          #Tordered
  ok !$E->ordered($e);                                                          #Tordered
  ok  $e->ordered($e);                                                          #Tordered
  ok  $e->ordered;                                                              #Tordered
  ok  $a->ordered($b,$c,$d,$e);
  ok  $A->ordered($B,$D,$E,$C);

  is_deeply[map{$_->tag}$a->firstDown(@tags)],[map{$_->tag}$a-> lastBy(@tags)];
  is_deeply[map{$_->tag}$a-> lastDown(@tags)],[map{$_->tag}$a->firstBy(@tags)];

  ok $e->before($E);                                                            #Tbefore
  ok $e->after($c);                                                             #Tafter

 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #Tat
<a>
  <b>
    <c> <d/> </c>
    <c> <e/> </c>
    <c> <f/> </c>
  </b>
</a>
END
  ok  $a->go(qw(b c -1 f))->at(qw(f c b a));                                    #Tat
  ok  $a->go(qw(b c  1 e))->at(undef, qr(c|d), undef, qq(a));                   #Tat

  my $d = $a->go(qw(b c d));

  ok $d->context eq q(d c b a);                                                 #Tat #TatOrBelow
  ok  $d->at(qw(d c b), undef);                                                 #Tat
  ok !$d->at(qw(d c b), undef, undef);                                          #Tat
  ok !$d->at(qw(d e b));                                                        #Tat

  ok  $d->atOrBelow(qw(d c b a));                                               #TatOrBelow
  ok  $d->atOrBelow(qw(  c b a));                                               #TatOrBelow
  ok  $d->atOrBelow(qw(    b a));                                               #TatOrBelow
  ok !$d->atOrBelow(qw(  c   a));                                               #TatOrBelow
 }

if (1)
 {my $a = Data::Edit::Xml::new(qq(<a> </a>));
  ok !$a->bitsNodeTextBlank &&  $a->isEmpty;
 }

if (1)
 {my $a = Data::Edit::Xml::new(qq(<a><b>B</b><c/> </a>));
  ok  $a->bitsNodeTextBlank && !$a->isEmpty;
 }

if (1)                                                                          # Numbered
 {my $a = Data::Edit::Xml::new(<<END);
<a>
  <b>
    <c>
      <e/>
    </c>
    <d>
      <e/>
    </d>
    <c>
      <d>
        <e/>
      </d>
    </c>
    <d>
      <e/>
    </d>
    <c>
      <d>
        <e/>
      </d>
    </c>
  </b>
</a>
END
  $a->numberTree;
  ok -z $a eq <<END;                                                            #TpathString #TfirstInIndex #TlastInIndex #TcommonAncestor #Tdepth #Tto #Tfrom #TfromTo
<a id="1">
  <b id="2">
    <c id="3">
      <e id="4"/>
    </c>
    <d id="5">
      <e id="6"/>
    </d>
    <c id="7">
      <d id="8">
        <e id="9"/>
      </d>
    </c>
    <d id="10">
      <e id="11"/>
    </d>
    <c id="12">
      <d id="13">
        <e id="14"/>
      </d>
    </c>
  </b>
</a>
END

  is_deeply [$a->findByNumber(11)->path], [(qw(b d 1 e))];                      # FindByNumber
  ok $a->findByNumber(9)->pathString eq 'b c 1 d e';                            #TpathString

  ok !$a->above($a);                                                            # Above
  ok  $a->findByNumber(12)->above($a->findByNumber(14));
  ok !$a->findByNumber( 7)->above($a->findByNumber(12));

  ok !$a->below($a);                                                            # Below
  ok  $a->findByNumber( 9)->below($a->findByNumber(7));
  ok !$a->findByNumber( 8)->below($a->findByNumber(10));

  ok  $a->findByNumber(13)->after($a->findByNumber(10));

  if (1)
   {my ($m, $n) = $a->findByNumbers(5, 10);
    ok  $m->before($n);
   }

  ok  $a->findByNumber (5)->firstInIndex;                                       #TfirstInIndex
  ok  $a->findByNumber(10)->lastInIndex;                                        #TlastInIndex

  ok !$a->findByNumber(7) ->firstInIndex;                                       #TfirstInIndex
  ok !$a->findByNumber(7) ->lastInIndex;                                        #TlastInIndex

  if (1)
   {my ($b, $e, @n) = $a->findByNumbers(2, 4, 6, 9);                            #TcommonAncestor
    ok -t $b eq 'b';
    ok -t $e eq 'e';
    ok $e == $e->commonAncestor;                                                #TcommonAncestor
    ok $e == $e->commonAncestor($e);                                            #TcommonAncestor
    ok $b == $e->commonAncestor($b);                                            #TcommonAncestor
    ok $e == $e->commonAncestor($e, $e);
    ok $b == $e->commonAncestor($e, $b);
    ok $b == $e->commonAncestor(@n);                                            #TcommonAncestor
   }

  if (1)
   {my ($d, $c, $D) = $a->findByNumbers(5, 7, 10);                              #TfromTo #Tto #Tfrom
    ok -t $d eq 'd';
    ok -t $c eq 'c';
    ok -t $D eq 'd';
    my @r = $d->fromTo($D);                                                     #TfromTo
    ok @r == 3;                                                                 #TfromTo
    my @R = $d->fromTo($D, qw(c));                                              #TfromTo
    ok @R == 1;                                                                 #TfromTo
    ok -M $R[0] == 7;                                                           #TfromTo
    ok !$D->fromTo($d);                                                         #TfromTo
    ok 1 == $d->fromTo($d);                                                     #TfromTo

    my @f = $d->from;                                                           #Tfrom
    ok @f == 4;                                                                 #Tfrom
    ok $d == $f[0];                                                             #Tfrom
    my @F = $d->from(qw(c));                                                    #Tfrom
    ok @F == 2;                                                                 #Tfrom
    ok -M $F[1] == 12;                                                          #Tfrom

    my @t = $D->to;                                                             #Tto
    ok $D == $t[-1];                                                            #Tfrom
    ok @t == 4;                                                                 #Tto
    my @T = $D->to(qw(c));                                                      #Tto
    ok @T == 2;                                                                 #Tto
    ok -M $T[1] == 7;                                                           #Tto
   }

  ok 0 == $a->depth;                                                            #Tdepth
  ok 4 == $a->findByNumber(14)->depth;                                          #Tdepth
 }

if (1)                                                                          # IsOnlyChild
 {my $a = Data::Edit::Xml::new("<a><b><c><d/></c></b></a>");
  ok $a->go(qw(b c d))->isOnlyChild;
  ok $a->go(qw(b c d))->isOnlyChild(qw(d));
  ok $a->go(qw(b c d))->isOnlyChild(qw(d c));
  ok $a->go(qw(b c d))->isOnlyChild(qw(d c b));
 }

if (1)
 {my $a = Data::Edit::Xml::new("<a><b>bb</b><c>cc<d/>ee</c></a>");              #TcontainsSingleText
  ok  $a->go(q(b))->containsSingleText->text eq q(bb);                          #TcontainsSingleText
  ok !$a->go(q(c))->containsSingleText;                                         #TcontainsSingleText
 }

if (1)                                                                          # Cut
 {my $x = Data::Edit::Xml::new("<a><b><c/></b></a>");
  $x->go(qw(b c))->cut;
  $x->checkParentage;
  ok -s $x eq "<a><b/></a>";
  $x->go(q(b))->cut;
  ok -s $x eq "<a/>";
  eval {$x->cut};
  ok !$@;                                                                       # Permit multiple cut outs of the same node
 }

if (1)                                                                          # Cut blank
 {my $x = Data::Edit::Xml::new("<a>A<b/>B</a>");
  my $b = $x->go(q(b));
  $b->putFirst($x->newText(' c '));
  ok -s $x eq "<a>A<b> c </b>B</a>";                                            #Tunwrap
  $b->unwrap;                                                                   #Tunwrap
  ok -s $x eq "<a>A c B</a>";                                                   #Tunwrap
 }

if (1)                                                                          # Errors
 {my $f = temporaryFile;
  my $e = temporaryFile;
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
 {my $f = temporaryFile;
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
   {if ($_->at(q(C)))
     {$_->change(q(D));
     }
   });

  ok !$y->equals($z);

  if (1)                                                                        # Save restore
   {my $f = temporaryFile;
    unlink $f;
    my $y1 = eval {Data::Edit::Xml::restore($f)};
    ok $@ =~ /Cannot restore from a non existent file/gs;

    $y->save($f);                                                               #Tsave #Trestore
    my $Y = Data::Edit::Xml::restore($f);                                       #Tsave #Trestore
    unlink $f;
    ok $Y->equals($y);                                                          #Tsave #Trestore
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
 {my $x = Data::Edit::Xml::new(<<END);                                          #Tc #Tcontents
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

  is_deeply [map{-u $_} $x->c(q(d))],  [qw(d1 d2)];                             #Tc
  is_deeply [map{-u $_} $x->contents], [qw(b1 d1 e1 b2 d2 e2)];                 #Tcontents
 }

if (1)                                                                          # Special characters
 {my $t =
   '<a id="&quot;&lt;&gt;&quot;&lt;&gt;">&quot;&lt;&gt;&quot;&lt;&gt;</a>';
  my $x = Data::Edit::Xml::new($t);
  ok -s $x eq $t;
 }

if (1)
 {my $s = <<END;                                                                #TprettyString #Tconcatenate #TprettyStringContent #TprettyStringNumbered #TstringContent #TstringQuoted
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

  ok $a->stringContent eq "<b><A/><B/></b><c><C/><D/></c>";                     #TstringContent
  ok $a->stringQuoted eq q('<a><b><A/><B/></b><c><C/><D/></c></a>');            #TstringQuoted

  ok $a->prettyStringContent eq <<END;                                          #TprettyStringContent
<b>
  <A/>
  <B/>
</b>
<c>
  <C/>
  <D/>
</c>
END

  $a->numberTree;                                                               #TprettyStringNumbered #TfindByNumber #TfindByNumbers #Tancestry
  ok $a->prettyStringNumbered eq <<END;                                         #TprettyStringNumbered #TfindByNumber #TfindByNumbers #Tancestry #TtocNumbers
<a id="1">
  <b id="2">
    <A id="3"/>
    <B id="4"/>
  </b>
  <c id="5">
    <C id="6"/>
    <D id="7"/>
  </c>
</a>
END

  if (1)
   {my $t = $a->tocNumbers(qw(b A B));
    is_deeply {map {$_=>$t->{$_}->tag} keys %$t}, {"1"=>"b", "1 1"=>"A", "1 2"=>"B"}
   }
  if (1)
   {my $t = $a->tocNumbers(qw(b c A B C));
    is_deeply {map {$_=>$t->{$_}->tag} keys %$t}, { "1" => "b", "1 1" => "A", "1 2" => "B", "2" => "c", "2 1" => "C" }
   }
  if (1) {
    my $t = $a->tocNumbers();                                                   #TtocNumbers
    is_deeply {map {$_=>$t->{$_}->tag} keys %$t},                               #TtocNumbers
     {"1"  =>"b",                                                               #TtocNumbers
      "1 1"=>"A",                                                               #TtocNumbers
      "1 2"=>"B",                                                               #TtocNumbers
      "2"  =>"c",                                                               #TtocNumbers
      "2 1"=> "C",                                                              #TtocNumbers
      "2 2"=>"D"                                                                #TtocNumbers
     }                                                                          #TtocNumbers
   }

  ok q(D) eq -t $a->findByNumber(7);                                            #TfindByNumber
  is_deeply [map {-t $_} $a->findByNumbers(1..3)], [qw(a b A)];                 #TfindByNumbers
  is_deeply [map {-t $_} $a->findByNumber(7)->ancestry], [qw(D c a)];           #Tancestry

  $a->go(q(b))->concatenate($a->go(q(c)));                                      #Tconcatenate

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

if (1)
 {my $s = <<END;                                                                #TprettyStringContentNumbered
<a>
  <b>
    <c/>
  </b>
</a>
END
  my $a = Data::Edit::Xml::new($s);                                             #TprettyStringContentNumbered
  $a->numberTree;                                                               #TprettyStringContentNumbered
  ok $a->prettyStringContentNumbered eq <<END;                                  #TprettyStringContentNumbered
<b id="2">
  <c id="3"/>
</b>
END

  ok $a->go(qw(b))->prettyStringContentNumbered eq <<END;                                  #TprettyStringContentNumbered
<c id="3"/>
END
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

if (1)
 {my $x = Data::Edit::Xml::new(<<END);                                          #TcountTagNames #TcountAttrNames #TcountAttrValues
<a A="A" B="B" C="C">
  <b  B="B" C="C">
    <c  C="C">
    </c>
    <c/>
  </b>
  <b  C="C">
    <c/>
  </b>
</a>
END
  is_deeply $x->countTagNames,  { a => 1, b => 2, c => 3 };                     #TcountTagNames
  is_deeply $x->countAttrNames, { A => 1, B => 2, C => 4 };                     #TcountAttrNames
  is_deeply $x->countAttrValues, { A => 1, B => 2, C => 4 };                    #TcountAttrValues
 }

if (1)                                                                          # *NonBlank
 {my $a = Data::Edit::Xml::new
   ("<a>1<A/>2<B/>3<C/>4<D/>5<E/>6<F/>7<G/>8<H/>9</a>");
  map {$_->replaceWithBlank} grep {$_->isText}               $a->contents;
  map {$_->cut}              grep {$_->tag =~ m/\A[BDFH]\Z/} $a->contents;

  ok $a->prettyStringCDATA eq <<'END';                                          #TfirstNonBlank #TnextNonBlank #TfirstIn #TnextIn  #TlastNonBlank #TprevNonBlank #TlastIn #TprevIn
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
  ok $a->firstNonBlank(qw(A a));                                                #TfirstNonBlank

  ok $a->firstNonBlank->nextNonBlank->tag eq qq(C);                             #TnextNonBlank
  ok $a->firstNonBlank->nextNonBlank(qw(C a));                                  #TnextNonBlank

  ok $a->firstIn(qw(b B c C))->tag eq qq(C);                                    #TfirstIn
  ok $a->firstIn(qw(b B c C))->nextIn(qw(A G))->tag eq qq(G);                   #TnextIn

  ok $a->lastNonBlank->tag eq qq(G);                                            #TlastNonBlank
  ok $a->lastNonBlank(qw(G a));                                                 #TlastNonBlank

  ok $a->lastNonBlank->prevNonBlank->tag eq qq(E);                              #TprevNonBlank
  ok $a->lastNonBlank->prevNonBlank(qw(E a));                                   #TprevNonBlank

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

#if (1)                                                                          # Operators
# {my $a = Data::Edit::Xml::new("<a id='1'><b id='2'><c id='3'/></b></a>");
#  my $b = $a >= [qw(b)]; ok $b->id == 2;
#  my $c = $b >= [qw(c)]; ok $c->id == 3;
#
#  ok $c <= [qw(c b a)];
#  $a x= sub {ok $_->id == 3 if $_ <= [qw(c b a)]};
#
#  my $A = $a >> '<b id="4"/>';
#  ok -s $A eq '<b id="4"/>';
#  ok -s $a eq '<a id="1"><b id="4"/><b id="2"><c id="3"/></b></a>';
#
#  my $B = $b > '<b id="5"/>';
#  ok -s $B eq  '<b id="5"/>';
#  ok -s $a eq '<a id="1"><b id="4"/><b id="2"><c id="3"/></b><b id="5"/></a>';
#
#  my $C = $b < '<b id="6"/>';
#  ok -s $C eq  '<b id="6"/>';
#  ok -s $a eq '<a id="1"><b id="4"/><b id="6"/><b id="2"><c id="3"/></b><b id="5"/></a>';
#
#  my $D = $b << qq(<d id="7"/>);
#  ok -s $D eq  '<d id="7"/>';
#  ok -s $a eq '<a id="1"><b id="4"/><b id="6"/><b id="2"><c id="3"/><d id="7"/></b><b id="5"/></a>'; Trenew
#  my $x = $a->renew;                                                                                 Trenew
#  ok -s $a eq '<a id="1"><b id="4"/><b id="6"/><b id="2"><c id="3"/><d id="7"/></b><b id="5"/></a>'; Trenew

#  ok 4 == grep{$_ <= [qw(b a)] } @$x;

#  ok $a % 'id' == 1;
#  ok $b % 'id' == 2;
#  ok $c % 'id' == 3;

#  $a += qq(aa);
#  ok -t $a eq 'aa';

#  my $e = $a / qq(ee);
#  ok -s $e eq '<ee><aa id="1"><b id="4"/><b id="6"/><b id="2"><c id="3"/><d id="7"/></b><b id="5"/></aa></ee>';
#
#  my $f = $a * qq(f);
#  ok -s $e eq '<ee><aa id="1"><f><b id="4"/><b id="6"/><b id="2"><c id="3"/><d id="7"/></b><b id="5"/></f></aa></ee>';
#
#  --$c;
#  ok -s $e eq '<ee><aa id="1"><f><b id="4"/><b id="6"/><b id="2"><d id="7"/></b><b id="5"/></f></aa></ee>';
#
#  ++$a;
#  ok -s $e eq '<ee><f><b id="4"/><b id="6"/><b id="2"><d id="7"/></b><b id="5"/></f></ee>';
# }

if (1)                                                                          # Labels
 {my $x = Data::Edit::Xml::new("<a><b><c/></b></a>");
  ok -r $x eq '<a><b><c/></b></a>';                                             #TaddLabels #TcountLabels #TgetLabels #TstringNode
  my $b = $x->go(q(b));                                                         #TaddLabels #TcountLabels #TgetLabels #TstringNode
  my $c = $b->go(q(c));
  ok $b->countLabels == 0;                                                      #TaddLabels #TcountLabels #TgetLabels
  ok $c->countLabels == 0;
  $b->addLabels(1..2);                                                          #TaddLabels #TcountLabels #TgetLabels #TstringNode
  $b->addLabels(3..4);                                                          #TaddLabels #TcountLabels #TgetLabels #TstringNode
  ok -r $x eq '<a><b id="1, 2, 3, 4"><c/></b></a>';                             #TaddLabels #TgetLabels #TcopyLabels #TcountLabels #TstringNode

  $b->numberTree;                                                               #TstringNode
  ok -S $b eq "b(2) 0:1 1:2 2:3 3:4";                                           #TstringNode
  ok $b->countLabels == 4;                                                      #TcountLabels
  is_deeply [1..4], [$b->getLabels];                                            #TgetLabels

  $b->copyLabels($c) for 1..2;                                                  #TcopyLabels
  ok -r $x eq '<a><b id="1, 2, 3, 4"><c id="1, 2, 3, 4"/></b></a>';             #TcopyLabels #TdeleteLabels
  ok $b->countLabels == 4;
  ok $c->countLabels == 4;
  is_deeply [1..4], [$b->getLabels];
  is_deeply [1..4], [$c->getLabels];

  $b->deleteLabels(1,4) for 1..2;                                               #TdeleteLabels
  ok -r $x eq '<a><b id="2, 3"><c id="1, 2, 3, 4"/></b></a>';                   #TdeleteLabels #TmoveLabels
  ok $b->countLabels == 2;
  ok $c->countLabels == 4;
  is_deeply [2..3], [$b->getLabels];
  is_deeply [1..4], [$c->getLabels];

  $b->moveLabels($c) for 1..2;                                                  #TmoveLabels
  ok -r $x eq '<a><b><c id="1, 2, 3, 4"/></b></a>';                             #TmoveLabels
  ok $b->countLabels == 0;
  ok $c->countLabels == 4;
  is_deeply [], [$b->getLabels];
  is_deeply [1..4], [$c->getLabels];

  ok -s $x eq '<a><b><c/></b></a>';
  $c->id = 11;
  ok -s $x eq '<a><b><c id="11"/></b></a>';
  ok -r $x eq '<a><b><c id="1, 2, 3, 4"/></b></a>';
  ok -p $x eq <<END;                                                            #TwrapWith
<a>
  <b>
    <c id="11"/>
  </b>
</a>
END

  $x->go(qw(b c))->wrapWith(qw(C id 1));                                        #TwrapWith
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
  ok -s $x eq '<a><b><C id="1"><c id="11"><E id="3"><D id="2"/></E></c></C></b></a>';

  ok -r $x eq '<a><b><C><c id="1, 2, 3, 4"><E><D/></E></c></C></b></a>';

  $c->wrapUp(qw(A B));                                                          # WrapUp
  ok -s $x eq '<a><b><C id="1"><B><A><c id="11"><E id="3"><D id="2"/></E></c></A></B></C></b></a>';
  $c->wrapDown(qw(G F));                                                        # WrapDown
  ok -s $x eq '<a><b><C id="1"><B><A><c id="11"><G><F><E id="3"><D id="2"/></E></F></G></c></A></B></C></b></a>';
}

if (1)
 {my $x = Data::Edit::Xml::new("<a><b><c/></b></a>");
  my $b = $x->go(q(b));
  my $c = $x->go(qw(b c));

  ok -r $x eq '<a><b><c/></b></a>';
  $b->addLabels(1..4);
  $c->addLabels(5..8);

  ok -r $x eq '<a><b id="1, 2, 3, 4"><c id="5, 6, 7, 8"/></b></a>';             #TstringReplacingIdsWithLabels
  my $s = $x->stringReplacingIdsWithLabels;                                     #TstringReplacingIdsWithLabels
  ok $s eq '<a><b id="1, 2, 3, 4"><c id="5, 6, 7, 8"/></b></a>';                #TstringReplacingIdsWithLabels

  $b->deleteLabels;
  $c->deleteLabels;
  ok -r $x eq '<a><b><c/></b></a>';
 }

if (1)                                                                          # X versions
 {my $x = Data::Edit::Xml::new("<a><b><c/><c/><c/></b></a>");
  ok -p $x eq <<END;                                                            #TwrapContentWith
<a>
  <b>
    <c/>
    <c/>
    <c/>
  </b>
</a>
END
  $x->go(q(b))->wrapContentWith(qw(D id DD));                                   #TwrapContentWith
  ok -p $x eq <<END;                                                            #TwrapContentWith
<a>
  <b>
    <D id="DD">
      <c/>
      <c/>
      <c/>
    </D>
  </b>
</a>
END
 }

if (1)                                                                          # X versions
 {my $a = Data::Edit::Xml::new(<<END);
<a>
  <b id="1"/><c id="2"/><d id="3"/><c id="4"/><d id="5"/>
  <e id="6"/>
  <b id="7"/><c id="8"/><d id="9"/>
  <f id="10"/>
</a>
END
  ok -p $a eq <<END;                                                            #TwrapContentWith
<a>
  <b id="1"/>
  <c id="2"/>
  <d id="3"/>
  <c id="4"/>
  <d id="5"/>
  <e id="6"/>
  <b id="7"/>
  <c id="8"/>
  <d id="9"/>
  <f id="10"/>
</a>
END

  my ($b, $e, $f) = $a->firstBy(qw(b e f));
  ok $b->id ==  1;
  ok $e->id ==  6;
  ok $f->id == 10;

  ok $b->nextOn(qw(c))  ->id == 2;
  ok $b->nextOn(qw(c d))->id == 5;
  ok '1 2 3 4 5' eq join ' ', map {$_->id}    $b->nextOn(qw(b c d));

  ok $e->prevOn(qw(b c d))->id == 1;
  ok '6 5 4 3 2 1' eq join ' ', map {$_->id}  $e->prevOn(qw(b c d));
  ok '6 5 4 3 2'   eq join ' ', map {$_->id}  $e->prevOn(qw(  c d));
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
  ok -s $a -> by(sub {$_ -> cut(qw(c b a))}) eq
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

if (1)                                                                          # Delete in context - exit chaining
 {my $a = Data::Edit::Xml::new("<a><b><c/></b></a>");
  $a->byX(sub {die "found: c\n" if $_->at(qw(c b a))});
  ok $@ =~ m(\Afound: c)s
 }

if (1)                                                                          # Delete in context - exit chaining
 {my $a = Data::Edit::Xml::new(<<END);
<a>
<p>• Minimum 1 number</p>
<p>•   No leading, trailing, or embedded spaces</p>
<p>• Not case-sensitive</p>
</a>
END

  $a->by(sub                                                                    # Bulleted list to <ul>
   {if ($_->at(qw(p)))                                                          # <p>
     {if (my $t = $_->containsSingleText)                                       # <p> with single text
       {if ($t->text =~ s(\A\x{2022}\s*) ()s)                                   # Starting with a bullet
         {$_->change(qw(li));                                                   # <p> to <li>
          if (my $p = $_->prev(qw(ul)))                                         # Previous element is ul?
           {$p->putLast($_->cut);                                               # Put in preceding list or create a new list
           }
          else
           {$_->wrapWith(qw(ul))
           }
         }
       }
     }
   });

  ok -p $a eq <<END;
<a>
  <ul>
    <li>Minimum 1 number</li>
    <li>No leading, trailing, or embedded spaces</li>
    <li>Not case-sensitive</li>
  </ul>
</a>
END
 }

1
# Preserve labels across a reparse by adding them to a used attribute
# writeFile("/home/phil/zzz.data", -p $x);
# perl -d:NYTProf -Ilib test.pl && nytprofhtml --open
