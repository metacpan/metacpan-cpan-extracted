#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Edit data held in the XML format.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2016-2018
#-------------------------------------------------------------------------------
# podDocumentation
# Preserve labels across a reparse by adding them to an unused attribute.
# perl -d:NYTProf -Ilib test.pl && nytprofhtml --open
# rename singleChild to hasSingleChild as the current shorther name is oconfuing with is onlyChild

package Data::Edit::Xml;
our $VERSION = 20180817;
use v5.8.0;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use XML::Parser;                                                                # https://metacpan.org/pod/XML::Parser
use Storable qw(store retrieve freeze thaw);
use utf8;

#D1 Construction                                                                # Create a parse tree, either by parsing a L<file or string|/file or string>, or, L<node by node|/Node by Node>, or, from another L<parse tree|/Parse tree>.

#D2 File or String                                                              # Construct a parse tree from a file or a string.

sub new(;$)                                                                     #IS Create a new parse tree - call this method statically as in Data::Edit::Xml::new(file or string) to parse a file or string B<or> with no parameters and then use L</input>, L</inputFile>, L</inputString>, L</errorFile>  to provide specific parameters for the parse, then call L</parse> to perform the parse and return the parse tree.
 {my ($fileNameOrString) = @_;                                                  # Optional file name or string from which to construct the parse tree
  if (@_)
   {my $x = bless {input=>$fileNameOrString};                                   # Create XML editor with a string or file
    $x->parser = $x;                                                            # Parser root node
    return $x->parse;                                                           # Parse
   }
  my $x = bless {};                                                             # Create empty XML editor
  $x->parser = $x;                                                              # Parser root node
  $x                                                                            # Parser
 }

sub cdata()                                                                     # The name of the tag to be used to represent text - this tag must not also be used as a command tag otherwise the parser will L<confess>.
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

#D2 Node by Node                                                                # Construct a parse tree node by node.

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
  for my $n($node->contents)                                                    # Index content
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

sub replaceSpecialChars($)                                                      #S Replace < > " & with &lt; &gt; &quot; &amp; Larry Wall's excellent L<Xml parser> unfortunately replaces &lt; &gt; &quot; &amp; etc. with their expansions in text by default and does not seem to provide an obvious way to stop this behavior, so we have to put them back again using this method.
 {my ($string) = @_;                                                            # String to be edited.
  $string =~ s/\&/&amp;/g;                                                      # At this point all & that prefix variables should have been expanded, so any that are left are are real &s which should be replaced with &amp;
  $string =~ s/\</&lt;/gr =~ s/\>/&gt;/gr =~ s/\"/&quot;/gr                     # Replace the special characters that we can replace.
 }

#D2 Parse tree attributes                                                       # Attributes of a node in a parse tree. For instance the attributes associated with an XML tag are held in the L<attributes|/attributes> attribute. It should not be necessary to use these attributes directly unless you are writing an extension to this module.  Otherwise you should probably use the methods documented in other sections to manipulate the parse tree as they offer a safer interface at a higher level.

genLValueArrayMethods (qw(content));                                            # Content of command: the nodes immediately below the specified B<$node> in the order in which they appeared in the source text, see also L</Contents>.
genLValueArrayMethods (qw(numbers));                                            # Nodes by number.
genLValueHashMethods  (qw(data));                                               # A hash added to the node for use by the programmer during transformations. The data in this hash will not be printed by any of the L<printed|/Print> methods and so can be used to add data to the L<parse|/parse> tree that will not be seen in any output xml produced from the L<parse|/parse> tree.
genLValueHashMethods  (qw(attributes));                                         # The attributes of the specified B<$node>, see also: L</Attributes>.  The frequently used attributes: class, id, href, outputclass can be accessed by an L<lvalueMethod> method as in: $node->id = 'c1'.
genLValueHashMethods  (qw(conditions));                                         # Conditional strings attached to a node, see L</Conditions>.
genLValueHashMethods  (qw(forestNumbers));                                      # Index to node by forest number as set by L<numberForest|/numberForest>.
genLValueHashMethods  (qw(indexes));                                            # Indexes to sub commands by tag in the order in which they appeared in the source text.
genLValueHashMethods  (qw(labels));                                             # The labels attached to a node to provide addressability from other nodes, see: L</Labels>.
genLValueScalarMethods(qw(errorsFile));                                         # Error listing file. Use this parameter to explicitly set the name of the file that will be used to write any L<parse|/parse> errors to. By default this file is named: B<zzzParseErrors/out.data>.
genLValueScalarMethods(qw(inputFile));                                          # Source file of the L<parse|/parse> if this is the L<parser|/parse> root node. Use this parameter to explicitly set the file to be L<parsed|/parse>.
genLValueScalarMethods(qw(input));                                              # Source of the L<parse|/parse> if this is the L<parser|/parse> root node. Use this parameter to specify some input either as a string or as a file name for the L<parser|/parse> to convert into a L<parse|/parse> tree.
genLValueScalarMethods(qw(inputString));                                        # Source string of the L<parse|/parse> if this is the L<parser|/parse> root node. Use this parameter to explicitly set the string to be L<parsed|/parse>.
genLValueScalarMethods(qw(numbering));                                          # Last number used to number a node in this L<parse|/parse> tree.
genLValueScalarMethods(qw(number));                                             # Number of the specified B<$node>, see L<findByNumber|/findByNumber>.
genLValueScalarMethods(qw(parent));                                             # Parent node of the specified B<$node> or B<undef> if the L<parser|/parse> root node. See also L</Traversal> and L</Navigation>. Consider as read only.
genLValueScalarMethods(qw(parser));                                             # L<Parser|/parse> details: the root node of a tree is the L<parser|/parse> node for that tree. Consider as read only.
genLValueScalarMethods(qw(tag));                                                # Tag name for the specified B<$node>, see also L</Traversal> and L</Navigation>. Consider as read only.
genLValueScalarMethods(qw(text));                                               # Text of the specified B<$node> but only if it is a text node, i.e. the tag is cdata() <=> L</isText> is true.

#D2 Parse tree                                                                  # Construct a L<parse|/parse> tree from another L<parse|/parse> tree.

sub renew($@)                                                                   #C Returns a renewed copy of the L<parse|/parse> tree, optionally checking that the starting node is in a specified context: use this method if you have added nodes via the L</"Put as text"> methods and wish to traverse their L<parse|/parse> tree.\mReturns the starting node of the new L<parse|/parse> tree or B<undef> if the optional context constraint was supplied but not satisfied.
 {my ($node, @context) = @_;                                                    # Node to renew from, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  new($node->string)
 }

sub clone($@)                                                                   #C Return a clone of the L<parse|/parse> tree optionally checking that the starting node is in a specified context: the L<parse|/parse> tree is cloned without converting it to string and reparsing it so this method will not L<renew|/renew> any nodes added L<as text|/Put as text>.\mReturns the starting node of the new L<parse|/parse> tree or B<undef> if the optional context constraint was supplied but not satisfied.
 {my ($node, @context) = @_;                                                    # Node to clone from, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $f = freeze($node);
  my $t = thaw($f);
  $t->parent = undef;
  $t->parser = $t;
  $t
 }

sub equals($$)                                                                  #Y Return the first node if the two L<parse|/parse> trees have identical representations via L<string|/string>, else B<undef>.
 {my ($node1, $node2) = @_;                                                     # Parse tree 1, parse tree 2.
  $node1->string eq $node2->string ? $node1 : undef                             # Test
 }

sub equalsIgnoringAttributes($$@)                                               # Return the first node if the two L<parse|/parse> trees have identical representations via L<string|/string> if the specified attributes are ignored, else B<undef>.
 {my ($node1, $node2, @attributes) = @_;                                        # Parse tree 1, parse tree 2, attributes to ignore during comparison
  my $p = $node1->clone;                                                        # Clone the parse trees so we can modify them
  my $q = $node2->clone;
  for my $x($p, $q)                                                             # Remove specified attributes from clones of parse trees
   {$x->by(sub
     {$_->deleteAttrs(@attributes);
     })
   }
  $p->string eq $q->string ? $node1 : undef                                     # Compare the reduced parse trees
 }

sub normalizeWhiteSpace($)                                                      #PS Normalize white space, remove comments DOCTYPE and xml processors from a string
 {my ($string) = @_;                                                            # String to normalize
  $string =~ s(<\?.*?\?>)     ( )gs;                                            # Processors
  $string =~ s(<!--.*?-->)    ( )gs;                                            # Comments
  $string =~ s(<!DOCTYPE.+?>) ( )gs;                                            # Doctype
  $string =~ s(\s+)           ( )gs;                                            # White space
  $string
 }

sub diff($$;$)                                                                  # Return () if the dense string representations of the two nodes are equal, else up to the first N (default 16) characters of the common prefix before the point of divergence and the remainder of the string representation of each node from the point of divergence. All <!-- ... --> comments are ignored during this comparison and all spans of white space are reduced to a single blank.
 {my ($first, $second, $N) = @_;                                                # First node, second node, maximum length of difference strings to return
  $first = new($first)   unless ref $first;                                     # Auto vivify the first node if necessary
  $second = new($second) unless ref $second;                                    # Auto vivify the second node if necessary
  $N //= 16;
  my $a = normalizeWhiteSpace(-s $first);                                       # Convert to normalized strings
  my $b = normalizeWhiteSpace(-s $second);
  return () if length($a) == length($b) and $a eq $b;                           # Equal strings

  my @a = split //, $a;                                                         # Split into characters
  my @b = split //, $b;
  my @c;                                                                        # Common prefix
  while(@a and @b and $a[0] eq $b[0])                                           # Remove equal prefix characters
   {push @c, shift @a; shift @b;                                                # Save common prefix
   }

  $#a = $N-1 if $N and @a > $N;                                                 # Truncate remainder if necessary
  $#b = $N-1 if $N and @b > $N;
  if ($N) {shift @c while @c > $N}

 (join ('', @c), join('', @a), join('', @b))                                    # Return common prefix and diverging strings
 }

sub save($$)                                                                    # Save a copy of the L<parse|/parse> tree to a file which can be L<restored|/restore> and return the saved node.  This method uses L<Storable> which is fast but produces large files that do not compress well.  Use L<writeCompressedFile|/writeCompressedFile> to produce smaller save files at the cost of more time.
 {my ($node, $file) = @_;                                                       # Parse tree, file.
  makePath($file);
  store $node, $file;
  $node
 }

sub restore($)                                                                  #SY Return a L<parse|/parse> tree from a copy saved in a file by L<save|/save>.
 {my ($file) = @_;                                                              # File
  -e $file or confess "Cannot restore from a non existent file:\n$file";
  retrieve $file
 }

sub expandIncludes($)                                                           # Expand the includes mentioned in a L<parse|/parse> tree: any tag that ends in B<include> is assumed to be an include directive.  The file to be included is named on the B<href> keyword.  If the file to be included is a relative file name, i.e. it does not begin with B</> then this file is made absolute relative to the file from which this L<parse|/parse> tree was obtained.
 {my ($x) = @_;                                                                 # Parse tree
  $x->by(sub                                                                    # Look for include statements
   {my ($o) = @_;
    if ($o->at(qr(include\Z)))                                                  # Include statement
     {my $href = $o->attr(q(href));                                             # Remove dots and slashes from front of file name
      my $in   = $x->inputFile;
      my $file = absFromAbsPlusRel($in, $href);
      say STDERR "Include: ", $in;
      my $i = Data::Edit::Xml::new($file);                                      # Parse the new source file
      $i->expandIncludes;                                                       # Rescan for any internal includes
      $o->replaceWith($i);                                                      # Replace include statement
     }
   });
 }

#D1 Print                                                                       # Create a string representation of the L<parse|/parse> tree with optional selection of nodes via L<conditions|/Conditions>.\mNormally use the methods in L<Pretty|/Pretty> to format the XML in a readable yet reparseable manner; use L<Dense|/Dense> string to format the XML densely in a reparseable manner; use the other methods to produce unreparseable strings conveniently formatted to assist various specialized operations such as debugging CDATA, using labels or creating tests. A number of the L<file test operators|/opString> can also be conveniently used to print L<parse|/parse> trees in these formats.

#D2 Pretty                                                                      # Pretty print the L<parse|/parse> tree.

sub prettyString($;$)                                                           #I Return a readable string representing a node of a L<parse|/parse> tree and all the nodes below it. Or use L<-p|/opString> $node
 {my ($node, $depth) = @_;                                                      # Start node, optional depth.
  $depth //= 0;                                                                 # Start depth if none supplied

  return $node->text.($node->isLast ? q() : qq(\n)) if $node->isText;           # Add a new line after contiguous blocks of text to offset next node

  my $t = $node->tag;                                                           # Not text so it has a tag
  my $content = $node->content;                                                 # Sub nodes
  my $space   = "  "x($depth//0);
  return $space.'<'.$t.$node->printAttributes.'/>'."\n" if !@$content;          # No sub nodes

  my $s = $space.'<'.$t.$node->printAttributes.'>'.                             # Has sub nodes
    ($node->first->isText ? '' : "\n");                                         # Continue text on the same line, otherwise place nodes on following lines
  $s .= $_->prettyString($depth+1) for @$content;                               # Recurse to get the sub content
  $s .= $node->last->isText ? ((grep{!$_->isText} @$content)                    # Continue text on the same line, otherwise place nodes on following lines
                            ? "\n$space": "") : $space;
  my $r = $s .  '</'.$t.'>'."\n";                                               # Closing tag
  return $r if $depth;                                                          # Return from sub tree
  $r =~ s(>\n( *[.,;:\)] *)) (>$1\n)gsr                                         # Overall result moves some punctuation through one new line to be closer to its tag
 }

sub prettyStringDitaHeaders($)                                                  # Return a readable string representing the L<parse|/parse> tree below the specified B<$node> with appropriate headers as determined by L<ditaOrganization|/ditaOrganization> . Or use L<-x|/opString> $node
 {my ($node) = @_;                                                              # Start node
  $node->ditaTopicHeaders.$node->prettyString;
 }

sub prettyStringNumbered($;$)                                                   # Return a readable string representing a node of a L<parse|/parse> tree and all the nodes below it with a L<number|/number> attached to each tag. The node numbers can then be used as described in L<Order|/Order> to monitor changes to the L<parse|/parse> tree.
 {my ($node, $depth) = @_;                                                      # Start node, optional depth.
  $depth //= 0;                                                                 # Start depth if none supplied

  my $N = $node->number;                                                        # Node number if present

  if ($node->isText)                                                            # Text node
   {my $n = $node->next;
    my $s = !defined($n) || $n->isText ? '' : "\n";                             # Add a new line after contiguous blocks of text to offset next node
    return ($N ? "($N)" : '').$node->text.$s;                                   # Number text
   }

  my $t = $node->tag;                                                           # Number tag in a way which allows us to skip between start and end tags in L<Geany|http://www.geany.org> using the ctrl+up and ctrl+down arrows
  my $i = $N && !defined($node->id) ? " id=\"$N\""  : '';                       # Use id to hold tag
  my $content = $node->content;                                                 # Sub nodes
  my $space   = "  "x($depth//0);
  return $space.'<'.$t.$i.$node->printAttributes.'/>'."\n" if !@$content;       # No sub nodes

  my $s = $space.'<'.$t.$i.$node->printAttributes.'>'.                          # Has sub nodes
    ($node->first->isText ? '' : "\n");                                         # Continue text on the same line, otherwise place nodes on following lines
  $s .= $_->prettyStringNumbered($depth+1) for @$content;                       # Recurse to get the sub content
  $s .= $node->last->isText ? ((grep{!$_->isText} @$content)                    # Continue text on the same line, otherwise place nodes on following lines
                            ? "\n$space": "") : $space;
  my $r = $s .  '</'.$t.'>'."\n";                                               # Closing tag
  return $r if $depth;                                                          # Return from sub tree
  $r =~ s(>\n( *[.,;:\)] *)) (>$1\n)gsr                                         # Overall result moves some punctuation through one new line to be closer to its tag
 }

sub prettyStringCDATA($;$)                                                      # Return a readable string representing a node of a L<parse|/parse> tree and all the nodes below it with the text fields wrapped with <CDATA>...</CDATA>.
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
  my $r = $s .  '</'.$t.'>'."\n";                                               # Closing tag
  return $r if $depth;                                                          # Return from sub tree
  $r =~ s(>\n( *[.,;:\)] *)) (>$1\n)gsr                                         # Overall result moves some punctuation through one new line to be closer to its tag
 }

sub prettyStringEnd($)                                                          #P Return a readable string representing a node of a L<parse|/parse> tree and all the nodes below it as a here document
 {my ($node) = @_;                                                              # Start node
  my $s = -p $node;                                                             # Pretty string representation
'  ok -p $x eq <<END;'. "\n".(-p $node). "\nEND"                                # Here document
 }

sub prettyStringContent($)                                                      # Return a readable string representing all the nodes below a node of a L<parse|/parse> tree.
 {my ($node) = @_;                                                              # Start node.
  my $s = '';
  $s .= $_->prettyString for $node->contents;                                   # Recurse to get the sub content
  $s
 }

sub prettyStringContentNumbered($)                                              # Return a readable string representing all the nodes below a node of a L<parse|/parse> tree with numbering added.
 {my ($node) = @_;                                                              # Start node.
  my $s = '';
  $s .= $_->prettyStringNumbered for $node->contents;                           # Recurse to get the sub content
  $s
 }

sub xmlHeader($)                                                                #S Add the standard xml header to a string
 {my ($string) = @_;                                                            # String to which a standard xml header should be prefixed
  <<END
<?xml version="1.0" encoding="UTF-8"?>
$string
END
 }

#D2 Dense                                                                       # Print the L<parse|/parse> tree.

sub string($)                                                                   # Return a dense string representing a node of a L<parse|/parse> tree and all the nodes below it. Or use L<-s|/opString> $node
 {my ($node) = @_;                                                              # Start node.
  return $node->text if $node->isText;                                          # Text node
  my $t = $node->tag;                                                           # Not text so it has a tag
  my $content = $node->content;                                                 # Sub nodes
  return '<'.$t.$node->printAttributes.'/>' if !@$content;                      # No sub nodes

  my $s = '<'.$t.$node->printAttributes.'>';                                    # Has sub nodes
  $s .= $_->string for @$content;                                               # Recurse to get the sub content
  return $s.'</'.$t.'>';
 }

sub stringQuoted($)                                                             # Return a quoted string representing a L<parse|/parse> tree a node of a L<parse|/parse> tree and all the nodes below it. Or use L<-o|/opString> $node
 {my ($node) = @_;                                                              # Start node
  "'".$node->string."'"
 }

sub stringReplacingIdsWithLabels($)                                             # Return a string representing the specified L<parse|/parse> tree with the id attribute of each node set to the L<Labels|/Labels> attached to each node.
 {my ($node) = @_;                                                              # Start node.
  return $node->text if $node->isText;                                          # Text node
  my $t = $node->tag;                                                           # Not text so it has a tag
  my $content = $node->content;                                                 # Sub nodes
  return '<'.$t.$node->printAttributesReplacingIdsWithLabels.'/>' if !@$content;# No sub nodes

  my $s = '<'.$t.$node->printAttributesReplacingIdsWithLabels.'>';              # Has sub nodes
  $s .= $_->stringReplacingIdsWithLabels for @$content;                         # Recurse to get the sub content
  return $s.'</'.$t.'>';
 }

sub stringExtendingIdsWithLabels($)                                             # Return a string representing the specified L<parse|/parse> tree with the id attribute of each node extended by the L<Labels|/Labels> attached to each node.
 {my ($node) = @_;                                                              # Start node.
  return $node->text if $node->isText;                                          # Text node
  my $t = $node->tag;                                                           # Not text so it has a tag
  my $content = $node->content;                                                 # Sub nodes
  return '<'.$t.$node->printAttributesExtendingIdsWithLabels.'/>' if !@$content;# No sub nodes

  my $s = '<'.$t.$node->printAttributesExtendingIdsWithLabels.'>';              # Has sub nodes
  $s .= $_->stringExtendingIdsWithLabels for @$content;                         # Recurse to get the sub content
  return $s.'</'.$t.'>';
 }

sub stringContent($)                                                            # Return a string representing all the nodes below a node of a L<parse|/parse> tree.
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

#D2 Conditions                                                                  # Print a subset of the the L<parse|/parse> tree determined by the conditions attached to it.

sub stringWithConditions($@)                                                    # Return a string representing the specified B<$node> of a L<parse|/parse> tree and all the nodes below it subject to conditions to select or reject some nodes.
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

sub condition($$@)                                                              #CY  Return the node if it has the specified condition and is in the optional context, else return B<undef>
 {my ($node, $condition, @context) = @_;                                        # Node, condition to check, optional context
  return undef if @context and !$node->at(@context);                            # Check optional context
  $node->conditions->{$condition} ? $node : undef                               # Return node if it has the specified condition, else B<undef>
 }

sub anyCondition($@)                                                            #Y Return the node if it has any of the specified conditions, else return B<undef>
 {my ($node, @conditions) = @_;                                                 # Node, conditions to check
  $node->conditions->{$_} ? return $node : undef for @conditions;               # Return node if any of the specified conditions are present
  undef                                                                         # No conditions present
 }

sub allConditions($@)                                                           #Y  Return the node if it has all of the specified conditions, else return B<undef>
 {my ($node, @conditions) = @_;                                                 # Node, conditions to check
  !$node->conditions->{$_} ? return undef : undef for @conditions;              # Return node if any of the specified conditions are missing
  $node                                                                         # All conditions present
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

#D1 Attributes                                                                  # Get or set the attributes of nodes in the L<parse|/parse> tree. L<Well Known Attributes|/Well Known Attributes>  can be set directly via L<lvalueMethod> B<sub>s. To set or get the values of other attributes use L<Get or Set Attributes|/Get or Set Attributes>. To delete or rename attributes see: L<Other Operations on Attributes|/Other Operations on Attributes>.

#D2 Well Known Attributes                                                       # Get or set these attributes of nodes via L<lvalueMethod> B<sub>s as in:\m  $x->href = "#ref";
if (0) {                                                                        # Node attributes.
genLValueScalarMethods(qw(audience));                                           # Attribute B<audience> for a node as an L<lvalueMethod> B<sub>.    Use B<audienceX()> to return B<q()> rather than B<undef>.
genLValueScalarMethods(qw(class));                                              # Attribute B<class> for a node as an L<lvalueMethod> B<sub>.       Use B<classX()> to return B<q()> rather than B<undef>.
genLValueScalarMethods(qw(guid));                                               # Attribute B<guid> for a node as an L<lvalueMethod> B<sub>.        Use B<guidX()> to return B<q()> rather than B<undef>.
genLValueScalarMethods(qw(href));                                               # Attribute B<href> for a node as an L<lvalueMethod> B<sub>.        Use B<hrefX()> to return B<q()> rather than B<undef>.
genLValueScalarMethods(qw(id));                                                 # Attribute B<id> for a node as an L<lvalueMethod> B<sub>.          Use B<idX()> to return B<q()> rather than B<undef>.
genLValueScalarMethods(qw(lang));                                               # Attribute B<lang> for a node as an L<lvalueMethod> B<sub>.        Use B<langX()> to return B<q()> rather than B<undef>.
genLValueScalarMethods(qw(navtitle));                                           # Attribute B<navtitle> for a node as an L<lvalueMethod> B<sub>.    Use B<navtitleX()> to return B<q()> rather than B<undef>.
genLValueScalarMethods(qw(otherprops));                                         # Attribute B<otherprops> for a node as an L<lvalueMethod> B<sub>.  Use B<otherpropsX()> to return B<q()> rather than B<undef>.
genLValueScalarMethods(qw(outputclass));                                        # Attribute B<outputclass> for a node as an L<lvalueMethod> B<sub>. Use B<outputclassX()> to return B<q()> rather than B<undef>.
genLValueScalarMethods(qw(props));                                              # Attribute B<props> for a node as an L<lvalueMethod> B<sub>.       Use B<propsX()> to return B<q()> rather than B<undef>.
genLValueScalarMethods(qw(style));                                              # Attribute B<style> for a node as an L<lvalueMethod> B<sub>.       Use B<styleX()> to return B<q()> rather than B<undef>.
genLValueScalarMethods(qw(type));                                               # Attribute B<type> for a node as an L<lvalueMethod> B<sub>.        Use B<typeX()> to return B<q()> rather than B<undef>.
}

BEGIN                                                                           # The above documents the attributes created below using the L<attr|_/attr> method.
 {for my $a(qw(audience class guid href id lang navtitle),                      # Return well known attributes as an assignable value
            qw(otherprops outputclass props style type))
   {eval 'sub '.$a. '($) :lvalue {&attr($_[0], q('.$a.'))}'.
         'sub '.$a.'X($)         {&attr($_[0], q('.$a.')) // q()}';
    $@ and confess "Cannot create well known attribute $a\n$@";

    my $A = ucfirst $a;
    for my $c(qw(at first next prev last))                                      # Commands to attach to attributes
     {my $cmd = 'sub '.$c.$A.'($)'.
      ' {my ($node, $attrValue, @context) = @_;'.
      '  my $A = $node->attr(q('.$a.'));'.
      '  return $node if $node->'.$c.'(@context) and $A and $A eq $attrValue;'.
      ' undef;}';
      eval $cmd;
      $@ and confess "Cannot create well known attribute $a\n$@";
     }
   }
 }

#D2 Get or Set Attributes                                                       # Get or set the attributes of nodes.
sub attr($$) :lvalue                                                            #I Return the value of an attribute of the current node as an L<lvalueMethod> B<sub>.
 {my ($node, $attribute) = @_;                                                  # Node in parse tree, attribute name.
  $node->attributes->{$attribute}
 }

sub set($%)                                                                     # Set the values of some attributes in a node and return the node. Identical in effect to L<setAttr|/setAttr>.
 {my ($node, %values) = @_;                                                     # Node in parse tree, (attribute name=>new value)*
  s/["<>]/ /gs for grep {$_} values %values;                                    # We cannot have these characters in an attribute
  $node->attributes->{$_} = $values{$_} for keys %values;                       # Set attributes
  $node
 }

sub setAttr($%)                                                                 # Set the values of some attributes in a node and return the node. Identical in effect to L<set|/set>.
 {my ($node, %values) = @_;                                                     # Node in parse tree, (attribute name=>new value)*
  s/["<>]/ /gs for grep {$_} values %values;                                    # We cannot have these characters in an attribute
  $node->attributes->{$_} = $values{$_} for keys %values;                       # Set attributes
  $node
 }

#D2 Other Operations on Attributes                                              # Perform operations other than get or set on the attributes of a node
sub attrs($@)                                                                   # Return the values of the specified attributes of the current node as a list
 {my ($node, @attributes) = @_;                                                 # Node in parse tree, attribute names.
  my @v;
  my $a = $node->attributes;
  push @v, $a->{$_} for @attributes;
  @v
 }

sub attrCount($@)                                                               # Return the number of attributes in the specified B<$node>, optionally ignoring the specified names from the count.
 {my ($node, @exclude) = @_;                                                    # Node in parse tree, optional attribute names to exclude from the count.
  my $a = $node->attributes;                                                    # Attributes
  return scalar grep {defined $a->{$_}} keys %$a if @exclude == 0;              # Count all attributes
  my %e = map{$_=>1} @exclude;                                                  # Hash of attributes to be excluded
  scalar grep {defined $a->{$_} and !$e{$_}} keys %$a;                          # Count attributes that are not excluded
 }

sub getAttrs($)                                                                 # Return a sorted list of all the attributes on the specified B<$node>.
 {my ($node) = @_;                                                              # Node in parse tree.
  my $a = $node->attributes;                                                    # Attributes
  grep {defined $a->{$_}} sort keys %$a                                         # Attributes
 }

sub deleteAttr($$;$)                                                            # Delete the named attribute in the specified B<$node>, optionally check its value first, return the node regardless.
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

sub deleteAttrs($@)                                                             # Delete the specified attributes of the specified B<$node> without checking their values and return the node.
 {my ($node, @attrs) = @_;                                                      # Node, Names of the attributes to delete
  my $a = $node->attributes;                                                    # Attributes hash
  delete $a->{$_} for @attrs;
  $node
 }

sub renameAttr($$$)                                                             # Change the name of an attribute in the specified B<$node> regardless of whether the new attribute already exists or not and return the node. To prevent inadvertent changes to an existing attribute use L<changeAttr|/changeAttr>.
 {my ($node, $old, $new) = @_;                                                  # Node, existing attribute name, new attribute name.
  my $a = $node->attributes;                                                    # Attributes hash
  if (defined($a->{$old}))                                                      # Check old attribute exists
   {my $value = $a->{$old};                                                     # Existing value
    $a->{$new} = $value;                                                        # Change the attribute name
    delete $a->{$old};
   }
  $node
 }

sub changeAttr($$$)                                                             # Change the name of an attribute in the specified B<$node> unless it has already been set and return the node. To make changes regardless of whether the new attribute already exists use L<renameAttr|/renameAttr>.
 {my ($node, $old, $new) = @_;                                                  # Node, existing attribute name, new attribute name.
  exists $node->attributes->{$new} ? $node : $node->renameAttr($old, $new)      # Check old attribute exists
 }

sub renameAttrValue($$$$$)                                                      # Change the name and value of an attribute in the specified B<$node> regardless of whether the new attribute already exists or not and return the node. To prevent inadvertent changes to existing attributes use L<changeAttrValue|/changeAttrValue>.
 {my ($node, $old, $oldValue, $new, $newValue) = @_;                            # Node, existing attribute name, existing attribute value, new attribute name, new attribute value.
  my $a = $node->attributes;                                                    # Attributes hash
  if (defined($a->{$old}) and $a->{$old} eq $oldValue)                          # Check old attribute exists and has the specified value
   {$a->{$new} = $newValue;                                                     # Change the attribute name
    delete $a->{$old};
   }
  $node
 }

sub changeAttrValue($$$$$)                                                      # Change the name and value of an attribute in the specified B<$node> unless it has already been set and return the node.  To make changes regardless of whether the new attribute already exists use L<renameAttrValue|/renameAttrValue>.
 {my ($node, $old, $oldValue, $new, $newValue) = @_;                            # Node, existing attribute name, existing attribute value, new attribute name, new attribute value.
  exists $node->attributes->{$new} ? $node :                                    # Check old attribute exists
    $node->renameAttrValue($old, $oldValue, $new, $newValue)
 }

sub changeAttributeValue($$$@)                                                  # Apply a sub to the value of an attribute of the specified B<$node>.  The value to be changed is supplied and returned in: L<$_>.
 {my ($node, $attribute, $sub, @context) = @_;                                  # Node, attribute name, change sub, optional context;
  return () if @context and !$node->at(@context);                               # Check optional context
  return unless local $_ = $node->attr($attribute);                             # Check that the attribute has a value we can change
  &$sub;                                                                        # Change the attribute
  $node->set($attribute, $_)                                                    # Update the attribute's value
 }

sub copyAttrs($$@)                                                              # Copy all the attributes of the source node to the target node, or, just the named attributes if the optional list of attributes to copy is supplied, overwriting any existing attributes in the target node and return the source node.
 {my ($source, $target, @attr) = @_;                                            # Source node, target node, optional list of attributes to copy
  my $s = $source->attributes;                                                  # Source attributes hash
  my $t = $target->attributes;                                                  # Target attributes hash
  if (@attr)                                                                    # Named attributes
   {$t->{$_} = $s->{$_} for @attr;                                              # Transfer each named attribute
   }
  else                                                                          # All attributes
   {$t->{$_} = $s->{$_} for sort keys %$s;                                      # Transfer each source attribute
   }
  $source                                                                       # Return source node
 }

sub copyNewAttrs($$@)                                                           # Copy all the attributes of the source node to the target node, or, just the named attributes if the optional list of attributes to copy is supplied, without overwriting any existing attributes in the target node and return the source node.
 {my ($source, $target, @attr) = @_;                                            # Source node, target node, optional list of attributes to copy
  my $s = $source->attributes;                                                  # Source attributes hash
  my $t = $target->attributes;                                                  # Target attributes hash
  if (@attr)                                                                    # Named attributes
   {$t->{$_} = $s->{$_} for grep {!exists $t->{$_}} @attr;                      # Transfer each named attribute not already present in the target
   }
  else                                                                          # All attributes
   {$t->{$_} = $s->{$_} for grep {!exists $t->{$_}} sort keys %$s;              # Transfer each source attribute not already present in the target
   }
  $source                                                                       # Return source node
 }

sub moveAttrs($$@)                                                              # Move all the attributes of the source node to the target node, or, just the named attributes if the optional list of attributes to move is supplied, overwriting any existing attributes in the target node and return the source node.
 {my ($source, $target, @attr) = @_;                                            # Source node, target node, attributes to move
  my $s = $source->attributes;                                                  # Source attributes hash
  my $t = $target->attributes;                                                  # Target attributes hash
  if (@attr)                                                                    # Named attributes
   {$t->{$_} = delete $s->{$_} for @attr;                                       # Transfer each named attribute and delete from the source node
   }
  else                                                                          # All attributes
   {$t->{$_} = delete $s->{$_} for sort keys %$s;                               # Transfer each source attribute and delete from source node
   }
  $source                                                                       # Return source node
 }

sub moveNewAttrs($$@)                                                           # Move all the attributes of the source node to the target node, or, just the named attributes if the optional list of attributes to copy is supplied, without overwriting any existing attributes in the target node and return the source node.
 {my ($source, $target, @attr) = @_;                                            # Source node, target node, optional list of attributes to move
  my $s = $source->attributes;                                                  # Source attributes hash
  my $t = $target->attributes;                                                  # Target attributes hash
  if (@attr)                                                                    # Named attributes
   {$t->{$_} = delete $s->{$_} for grep {!exists $t->{$_}} @attr;               # Transfer each named attribute and delete it from the source node as long as it does not already exist in the target
   }
  else                                                                          # All attributes
   {$t->{$_} = delete $s->{$_} for grep {!exists $t->{$_}} sort keys %$s;       # Transfer every attribute and delete it from the source node as long as it does not already exist in the target
   }
  $source                                                                       # Return source node
 }

#D1 Traversal                                                                   # Traverse the L<parse|/parse> tree in various orders applying a B<sub> to each node.

#D2 Post-order                                                                  # This order allows you to edit children before their parents.

sub by($$@)                                                                     #I Post-order traversal of a L<parse|/parse> tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. A reference to the current node is also made available via L<$_>. This is equivalent to the L<x=|/opBy> operator.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  $_->by($sub, $node, @context) for $node->contents;                            # Recurse to process sub nodes in deeper context
  &$sub(local $_ = $node, @context);                                            # Process specified node last
  $node
 }

sub byX($$)                                                                     #C Post-order traversal of a L<parse|/parse> tree calling the specified B<sub> at each node as long as this sub does not L<die>. The traversal is halted if the called sub does  L<die> on any call with the reason in L<?@|http://perldoc.perl.org/perlvar.html#Error-Variables> The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry> up to the node on which this sub was called. A reference to the current node is also made available via L<$_>.\mReturns the start node regardless of the outcome of calling B<sub>.
 {my ($node, $sub) = @_;                                                        # Start node, sub to call
  eval {$node->byX2($sub)};                                                     # Trap any errors that occur
  $node
 }

sub byX2($$@)                                                                   #P Post-order traversal of a L<parse|/parse> tree or sub tree calling the specified B<sub> within L<eval>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call, accumulated context.
  $_->byX2($sub, $node, @context) for $node->contents;                          # Recurse to process sub nodes in deeper context
  &$sub(local $_ = $node, @context);                                            # Process specified node last
 }

sub byX22($$@)                                                                  #P Post-order traversal of a L<parse|/parse> tree or sub tree calling the specified B<sub> within L<eval>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call, accumulated context.
  $_->byX($sub, $node, @context) for $node->contents;                           # Recurse to process sub nodes in deeper context
  eval {&$sub(local $_ = $node, @context)};                                     # Process specified node last
  $node
 }

sub byList($@)                                                                  #C Return a list of all the nodes at and below a specified B<$node> in pre-order or the empty list if the B<$node> is not in the optional context.
 {my ($node, @context) = @_;                                                    # Starting node, optional context
  return () if @context and !$node->at(@context);                               # Check optional context
  my @n;                                                                        # Nodes under specified node
  $node->by(sub{push @n, $_});                                                  # Retrieve nodes in pre-order
  @n                                                                            # Return list of nodes
 }

sub byReverse($$@)                                                              # Reverse post-order traversal of a L<parse|/parse> tree or sub tree calling the specified B<sub> at each node and returning the specified starting B<$node>. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  $_->byReverse($sub, $node, @context) for reverse $node->contents;             # Recurse to process sub nodes in deeper context
  &$sub(local $_ = $node, @context);                                            # Process specified node last
  $node
 }

sub byReverseX($$@)                                                             # Reverse post-order traversal of a L<parse|/parse> tree or sub tree below the specified B<$node> calling the specified B<sub> within L<eval>B<{}> at each node and returning the specified starting B<$node>. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  $_->byReverseX($sub, $node, @context) for reverse $node->contents;            # Recurse to process sub nodes in deeper context
  &$sub(local $_ = $node, @context);                                            # Process specified node last
  $node
 }

sub byReverseList($@)                                                           #C Return a list of all the nodes at and below a specified B<$node> in reverse preorder or the empty list if the specified B<$node> is not in the optional context.
 {my ($node, @context) = @_;                                                    # Starting node, optional context
  return () if @context and !$node->at(@context);                               # Check optional context
  my @n;                                                                        # Nodes
  $node->byReverse(sub{push @n, $_});                                           # Retrieve nodes in reverse pre-order
  @n                                                                            # Return list of nodes
 }

#D2 Pre-order                                                                   # This order allows you to edit children after their parents

sub down($$@)                                                                   # Pre-order traversal down through a L<parse|/parse> tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  &$sub(local $_ = $node, @context);                                            # Process specified node first
  $_->down($sub, $node, @context) for $node->contents;                          # Recurse to process sub nodes in deeper context
  $node
 }

sub downX($$)                                                                   # Pre-order traversal of a L<parse|/parse> tree calling the specified B<sub> at each node as long as this sub does not L<die>. The traversal is halted if the called sub does  L<die> on any call with the reason in L<?@|http://perldoc.perl.org/perlvar.html#Error-Variables> The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry> up to the node on which this sub was called. A reference to the current node is also made available via L<$_>.\mReturns the start node regardless of the outcome of calling B<sub>.
 {my ($node, $sub) = @_;                                                        # Start node, sub to call
  eval {$node->downX2($sub)};                                                   # Trap any errors that occur
  $node
 }

sub downX2($$@)                                                                 #P Pre-order traversal of a L<parse|/parse> tree or sub tree calling the specified B<sub> within L<eval>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call, accumulated context.
  &$sub(local $_ = $node, @context);                                            # Process specified node last
  $_->downX2($sub, $node, @context) for $node->contents;                        # Recurse to process sub nodes in deeper context
 }

sub downX22($$@)                                                                #P Pre-order traversal down through a L<parse|/parse> tree or sub tree calling the specified B<sub> within L<eval>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  &$sub(local $_ = $node, @context);                                            # Process specified node first
  $_->downX($sub, $node, @context) for $node->contents;                         # Recurse to process sub nodes in deeper context
  $node
 }

sub downReverse($$@)                                                            # Reverse pre-order traversal down through a L<parse|/parse> tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  &$sub(local $_ = $node, @context);                                            # Process specified node first
  $_->downReverse($sub, $node, @context) for reverse $node->contents;           # Recurse to process sub nodes in deeper context
  $node
 }

sub downReverseX($$@)                                                           # Reverse pre-order traversal down through a L<parse|/parse> tree or sub tree calling the specified B<sub> within L<eval>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  &$sub(local $_ = $node, @context);                                            # Process specified node first
  $_->downReverseX($sub, $node, @context) for reverse $node->contents;          # Recurse to process sub nodes in deeper context
  $node
 }

#D2 Pre and Post order                                                          # Visit the parent first, then the children, then the parent again.

sub through($$$@)                                                               # Traverse L<parse|/parse> tree visiting each node twice calling the specified B<sub> at each node and returning the specified starting node. The B<sub>s are passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_>.
 {my ($node, $before, $after, @context) = @_;                                   # Starting node, sub to call when we meet a node, sub to call we leave a node, accumulated context.
  &$before(local $_ = $node, @context);                                         # Process specified node first with before()
  $_->through($before, $after, $node, @context) for $node->contents;            # Recurse to process sub nodes in deeper context
  &$after(local $_ = $node, @context);                                          # Process specified node last with after()
  $node
 }

sub throughX($$$@)                                                              # Traverse L<parse|/parse> tree visiting each node twice calling the specified B<sub> within L<eval>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_>.
 {my ($node, $before, $after, @context) = @_;                                   # Starting node, sub to call when we meet a node, sub to call we leave a node, accumulated context.
  &$before(local $_ = $node, @context);                                         # Process specified node first with before()
  $_->throughX($before, $after, $node, @context) for $node->contents;           # Recurse to process sub nodes in deeper context
  &$after(local $_ = $node, @context);                                          # Process specified node last with after()
  $node
 }

#D2 Range                                                                       # Ranges of nodes

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
  pop @c while @c and $c[-1] != $end;                                           # Position on end
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

#D1 Position                                                                    # Confirm that the position L<navigated|/Navigation> to is the expected position.

sub atPositionMatch($$)                                                         #P Confirm that a string matches a match expression.
 {my ($tag, $match) = @_;                                                       # Starting node, ancestry.
  return 1 unless $match;                                                       # Undefined match means anything matches
  return $tag eq $match unless  ref $match;                                     # Match scalar
  return $tag =~ m($match)s if  ref($match) =~ m(regexp)i;                      # Match regular expression
  return $$match{$tag}      if  ref($match) =~ m(hash)i;                        # Match hash key
                            if (ref($match) =~ m(array)i)                       # Match array
   {my %m = map {$_=>1} @$tag;
    return $m{$tag}
   }
  confess "Unknown match type";                                                 # Do not know how to match
 }

sub at($@)                                                                      #IY Confirm that the specified B<$node> has the specified L<ancestry|/ancestry> and return the specified B<$node> if it does else B<undef>. Ancestry is specified by providing the expected tags that the B<$node>'s parent, the parent's parent etc. must match at each level. If B<undef> is specified then any tag is assumed to match at that level. If a regular expression is specified then the current parent node tag must match the regular expression at that level. If all supplied tags match successfully then the starting node is returned else B<undef>
 {my ($start, @context) = @_;                                                   # Starting node, ancestry.
  for(my $x = shift @_; $x; $x = $x->parent)                                    # Up through parents
   {return $start unless @_;                                                    # OK if no more required context
    next if atPositionMatch(-t $x, shift @_);                                   # Match tag against context
    return undef                                                                # Error if required does not match actual
   }
  !@_ ? $start : undef                                                          # Top of the tree is OK as long as there is no more required context
 }

sub not($@)                                                                     # Return the specified B<$node> if it does not match any of the specified tags, else B<undef>
 {my ($node, @tags) = @_;                                                       # Node, tags not to match
  my %tags = map {$_=>1} @tags;                                                 # Tags not to match
  return $node unless $tags{$node->tag};                                        # Ok if node does not have one of the specified tags
  undef                                                                         # Matched one of the tags that it should not match
 }

sub atOrBelow($@)                                                               #Y Confirm that the node or one of its ancestors has the specified context as recognized by L<at|/at> and return the first node that matches the context or B<undef> if none do.
 {my ($start, @context) = @_;                                                   # Starting node, ancestry.
  for(my $x = $start; $x; $x = $x->parent)                                      # Up through parents
   {return $x if $x->at(@context);                                              # Return this node if the context matches
   }
  undef                                                                         # No node that matches the context
 }

sub adjacent($$)                                                                # Return the first node if it is adjacent to the second node else B<undef>.
 {my ($first, $second) = @_;                                                    # First node, second node
  my ($n, $p) = ($first->next, $first->prev);                                   # Nodes adjacent to the first node
  return $first if $n && $n == $second or $p && $p == $second;                  # Adjacent nodes
  undef
 }

sub ancestry($)                                                                 # Return a list containing: (the specified B<$node>, its parent, its parent's parent etc..). Or use L<upn|/upn> to go up the specified number of levels.
 {my ($node) = @_;                                                              # Starting node.
  my @a;
  for(my $x = $node; $x; $x = $x->parent)                                       # Up through parents
   {push @a, $x;
   }
  @a                                                                            # Return ancestry
 }

sub context($)                                                                  # Return a string containing the tag of the starting node and the tags of all its ancestors separated by single spaces.
 {my ($node) = @_;                                                              # Starting node.
  my @a;                                                                        # Ancestors
  for(my $p = $node; $p; $p = $p->parent)
   {push @a, $p->tag;
    @a < 100 or confess "Overly deep tree!";
   }
  join ' ', @a
 }

sub containsSingleText($@)                                                      #C Return the single text element below the specified B<$node> else return B<undef>.
 {my ($node, @context) = @_;                                                    # Node, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $t = $node->hasSingleChild;                                                # Child element
  $t ? $t->isText : $t                                                          # Child element must be text
 }

sub depth($)                                                                    # Returns the depth of the specified B<$node>, the  depth of a root node is zero.
 {my ($node) = @_;                                                              # Node.
  my $a = 0;
  for(my $x = $node->parent; $x; $x = $x->parent) {++$a}                        # Up through parents
  $a                                                                            # Return depth
 }

sub isFirst($@)                                                                 #BCY Return the specified B<$node> if it is first under its parent and optionally has the specified context, else return B<undef>
 {my ($node, @context) = @_;                                                    # Node, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $parent = $node->parent;                                                   # Parent
  return $node unless defined($parent);                                         # The top most node is always first
  $node == $parent->first ? $node : undef                                       # First under parent
 }

sub isFirstToDepth($$@)                                                         #C Return the specified B<$node> if it is first to the specified depth else return B<undef>
 {my ($node, $depth, @context) = @_;                                            # Node, depth, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $p = $node;                                                                # Start
  for(1..$depth-1)                                                              # Check each ancestor is first to the specified depth but one
   {return undef unless $p->isFirst and $p = $p->parent;                        # Check node is first and that we can move up
   }
  $p->isFirst                                                                   # Confirm that the last ancestor so reached is a first node
 }

sub isLast($@)                                                                  #BCY Return the specified B<$node> if it is last under its parent and optionally has the specified context, else return B<undef>
 {my ($node, @context) = @_;                                                    # Node, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $parent = $node->parent;                                                   # Parent
  return $node unless defined($parent);                                         # The top most node is always last
  $node == $parent->last ? $node : undef                                        # Last under parent
 }

sub isLastToDepth($$@)                                                          #C Return the specified B<$node> if it is last to the specified depth else return B<undef>
 {my ($node, $depth, @context) = @_;                                            # Node, depth, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $p = $node;                                                                # Start
  for(1..$depth-1)                                                              # Check each ancestor is last to the specified depth but one
   {return undef unless $p->isLast and $p = $p->parent;                         # Check node is last and that we can move up
   }
  $p->isLast                                                                    # Confirm that the last ancestor so reached is a last node
 }

sub isOnlyChild($@)                                                             #CY Return the specified B<$node> if it is the only node under its parent ignoring any surrounding blank text.
 {my ($node, @context) = @_;                                                    # Node, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $parent = $node->parent;                                                   # Find parent
  return $node unless $parent;                                                  # The root node is an only child
  my @c = $parent->contents;                                                    # Contents of parent
  return $node if @c == 1;                                                      # Only child if only one child
  shift @c while @c and $c[ 0]->isBlankText;                                    # Ignore leading blank text
  pop   @c while @c and $c[-1]->isBlankText;                                    # Ignore trailing blank text
  return $node if @c == 1;                                                      # Only child if only one child after leading and trailing blank text has been ignored
  undef                                                                         # Not the only child
 }

sub isOnlyChildToDepth($$@)                                                     #C Return the specified B<$node> if it and its ancestors are L<only children|/isOnlyChild> to the specified depth else return B<undef>. isOnlyChildToDepth(1) is the same as L<isOnlychild|/isOnlyChild>
 {my ($node, $depth, @context) = @_;                                            # Node, depth to which each parent node must also be an only child, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $p = $node;                                                                # Walk up through ancestors
  for(1..$depth-1)                                                              # Walk up through ancestors to the specified depth but one
   {return undef unless $p->isOnlyChild and $p = $p->parent;                    # Confirm we are an only child and can move up one more level
   }
  $p->isOnlyChild;                                                              # Confirm that we are still on an only child
 }

sub hasSingleChild($@)                                                          #CY Return the only child of the specified B<$node> if the child is the only node under its parent ignoring any surrounding blank text and has the  optional specified context, else return B<undef>.
 {my ($node, @context) = @_;                                                    # Node, optional context
  return undef unless my $child = $node->first(@context);                       # A possible child node
  return undef unless $child->isOnlyChild;                                      # Not an only child
  $child                                                                        # Return the only child
 }

sub hasSingleChildToDepth($$@)                                                  #C Return the specified B<$node> if it has single children to at least the specified depth else return B<undef>.  L<hasSingleChildToDepth(0)|/hasSingleChildToDepth> is equivalent to L<hasSingleChild|/hasSingleChild>.
 {my ($node, $depth, @context) = @_;                                            # Node, depth, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  return $node->isOnlyChild if $depth < 1;                                      # Validate depth
  my $c = 0;                                                                    # Depth count
  my $p;                                                                        # Current position
  for
   ($p = $node->first;                                                          # Descend firstly
    $p and $p->isOnlyChild and ++$c < $depth;
    $p = $p->first)
   {}
  $p ? $p->isOnlyChild : $p
 }

sub isEmpty($@)                                                                 #CY Confirm that the specified B<$node> is empty, that is: the specified B<$node> has no content, not even a blank string of text. To test for blank nodes, see L<isAllBlankText|/isAllBlankText>.
 {my ($node, @context) = @_;                                                    # Node, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  !$node->first ? $node : undef                                                 # If it has no first descendant it must be empty
 }

sub over($$@)                                                                   #CY Confirm that the string representing the tags at the level below the specified B<$node> match a regular expression where each pair of tags is separated by a single space. Use L<contentAsTags|/contentAsTags> to visualize the tags at the next level.
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentAsTags =~ m/$re/ ? $node : undef
 }

sub over2($$@)                                                                  #CY Confirm that the string representing the tags at the level below the specified B<$node> match a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a single space and the last tag is followed by a single space.  This arrangement simplifies the regular expression used to detect combinations like p+ q? . Use L<contentAsTags2|/contentAsTags2> to visualize the tags at the next level.
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentAsTags2 =~ m/$re/ ? $node : undef
 }

sub overAllTags($@)                                                             # Return the specified b<$node> if all of it's child nodes L<match|/atPositionMatch> the specified <@tags> else return B<undef>.
 {my ($node, @tags) = @_;                                                       # Node, tags.
  my @c = $node->contents;                                                      # Node contents
  while(@tags and @c)                                                           # Match node contents against tags
   {return undef unless atPositionMatch(-t shift @c, shift @tags);              # Continue unless we fail to match
   }
  return $node if @c == 0 and @tags == 0;                                       # Child nodes and tags matched exactly
  undef                                                                         # Wrong number of tags
 }

BEGIN{*oat=*overAllTags}

sub overFirstTags($@)                                                           # Return the specified b<$node> if the first of it's child nodes L<match|/atPositionMatch> the specified <@tags> else return B<undef>.
 {my ($node, @tags) = @_;                                                       # Node, tags.
  my @c = $node->contents;                                                      # Node contents
  while(@tags and @c)                                                           # Match node contents against tags
   {return undef unless atPositionMatch(-t shift @c, shift @tags);              # Continue unless we fail to match
   }
  return $node if @c >= 0 and @tags == 0;                                       # The first child nodes match the specified tags
  undef                                                                         # Wrong number of tags
 }

BEGIN{*oft=*overFirstTags}

sub overLastTags($@)                                                            # Return the specified b<$node> if the last of it's child nodes L<match|/atPositionMatch> the specified <@tags> else return B<undef>.
 {my ($node, @tags) = @_;                                                       # Node, tags.
  my @c = $node->contents;                                                      # Node contents
  while(@tags and @c)                                                           # Match node contents against tags
   {return undef unless atPositionMatch(-t pop @c, pop @tags);                  # Continue unless we fail to match
   }
  return $node if @c >= 0 and @tags == 0;                                       # The last child nodes match the specified tags
  undef                                                                         # Wrong number of tags
 }

BEGIN{*olt=*overLastTags}

sub matchAfter($$@)                                                             #CY Confirm that the string representing the tags following the specified B<$node> matches a regular expression where each pair of tags is separated by a single space. Use L<contentAfterAsTags|/contentAfterAsTags> to visualize these tags.
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentAfterAsTags =~ m/$re/ ? $node : undef
 }

sub matchAfter2($$@)                                                            #CY Confirm that the string representing the tags following the specified B<$node> matches a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a single space and the last tag is followed by a single space.  This arrangement simplifies the regular expression used to detect combinations like p+ q? Use L<contentAfterAsTags2|/contentAfterAsTags2> to visualize these tags.
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentAfterAsTags2 =~ m/$re/ ? $node : undef
 }

sub matchBefore($$@)                                                            #CY Confirm that the string representing the tags preceding the specified B<$node> matches a regular expression where each pair of tags is separated by a single space. Use L<contentBeforeAsTags|/contentBeforeAsTags> to visualize these tags.
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentBeforeAsTags =~ m/$re/ ? $node : undef
 }

sub matchBefore2($$@)                                                           #CY Confirm that the string representing the tags preceding the specified B<$node> matches a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a single space and the last tag is followed by a single space.  This arrangement simplifies the regular expression used to detect combinations like p+ q?  Use L<contentBeforeAsTags2|/contentBeforeAsTags2> to visualize these tags.
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentBeforeAsTags2 =~ m/$re/ ? $node : undef
 }

sub path($)                                                                     # Return a list representing the path to a node from the root of the parse tree which can then be reused by L<go|/go> to retrieve the node as long as the structure of the L<parse|/parse> tree has not changed along the path.
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

sub pathString($)                                                               # Return a string representing the L<path|/path> to the specified B<$node> from the root of the parse tree.
 {my ($node) = @_;                                                              # Node.
  join ' ', path($node)                                                         # String representation
 }

#D2 Prev At Next                                                                # Locate adjacent nodes that match horizontally and vertically

sub an($$@)                                                                     #C Return the next node if the specified B<$node> has the specified tag and the next node is in the specified context.
 {my ($node, $tag, @context) = @_;                                              # Node, tag node must match, optional context of the next node.
  return undef unless $node->at($tag);                                          # Check node has the right tag
  $node->next(@context)                                                         # Next node if it matches the context else B<undef>
 }

sub ap($$@)                                                                     #C Return the previous node if the specified B<$node> has the specified tag and the previous node is in the specified context.
 {my ($node, $tag, @context) = @_;                                              # Node, tag node must match, optional context of the previous node.
  return undef unless $node->at($tag);                                          # Check node has the right tag
  $node->prev(@context)                                                         # Previous node if it matches the context else B<undef>
 }

sub apn($$$@)                                                                   #K Return (previous node, next node) if the previous and current nodes have the specified tags and the next node is in the specified context else return B<()>.
 {my ($node, $prev, $tag, @context) = @_;                                       # Current node, tag for the previous node, tag for specified node, context for the next node.
  return () if !$node->at($tag) or $node->isLast or $node->isFirst;             # Check existence of surrounding nodes
  my $p = $node->prev($prev);                                                   # Previous node
  my $n = $node->next(@context);                                                # Next node
  return ($p, $n) if $p and $n;                                                 # Successful match
  ()                                                                            # Match failed
 }

sub matchesNextTags($@)                                                         # Return the specified b<$node> if the siblings following the specified B<$node> L<match|/atPositionMatch> the specified <@tags> else return B<undef>.
 {my ($node, @tags) = @_;                                                       # Node, tags.
  my @c = $node->contentAfter;                                                  # Following nodes
  while(@tags and @c)                                                           # Match node contents against tags
   {return undef unless atPositionMatch(-t shift @c, shift @tags);              # Continue unless we fail to match
   }
  return $node if @tags == 0 and @c >= 0;                                       # The following nodes match the specified tags
  undef                                                                         # Wrong number of tags
 }

BEGIN{*mnt=*matchesNextTags}

sub matchesPrevTags($@)                                                         # Return the specified b<$node> if the siblings prior to the specified B<$node> L<match|/atPositionMatch> the specified <@tags> else return B<undef>.
 {my ($node, @tags) = @_;                                                       # Node, tags.
  my @c = reverse $node->contentBefore;                                         # Prior nodes
  while(@tags and @c)                                                           # Match node contents against tags
   {return undef unless atPositionMatch(-t shift @c, shift @tags);              # Continue unless we fail to match
   }
  return $node if @tags == 0 and @c >= 0;                                       # The prior nodes match the specified tags
  undef                                                                         # Wrong number of tags
 }

BEGIN{*mpt=*matchesPrevTags}

#D1 Navigation                                                                  # Move around in the L<parse|/parse> tree.

sub go($@)                                                                      #IY Return the node reached from the specified B<$node> via the specified L<path|/path>: (index positionB<?>)B<*> where index is the tag of the next node to be chosen and position is the optional zero based position within the index of those tags under the current node. Position defaults to zero if not specified. Position can also be negative to index back from the top of the index array. B<*> can be used as the last position to retrieve all nodes with the final tag.
 {my ($node, @path) = @_;                                                       # Node, search specification.
  my $p = $node;                                                                # Current node
  while(@path)                                                                  # Position specification
   {my $i = shift @path;                                                        # Index name
    return undef unless $p;                                                     # There is no node of the named type under this node
    reindexNode($p);                                                            # Create index for this node
    my $q = $p->indexes->{$i};                                                  # Index
    return undef unless defined $q;                                             # Complain if no such index
    if (@path)                                                                  # Position within index
     {if ($path[0] =~ /\A([-+]?\d+)\Z/)                                         # Numeric position in index from start
       {shift @path;
        $p = $q->[$1]
       }
      elsif (@path == 1 and $path[0] =~ /\A\*\Z/)                               # Final index wanted
       {return @$q;
       }
      else {$p = $q->[0]}                                                       # Step into first sub node by default
     }
    else {$p = $q->[0]}                                                         # Step into first sub node by default on last step
   }
  $p
 }

sub c($$)                                                                       # Return an array of all the nodes with the specified tag below the specified B<$node>. This method is deprecated in favor of applying L<grep|https://perldoc.perl.org/functions/grep.html> to L<contents|/contents>.
 {my ($node, $tag) = @_;                                                        # Node, tag.
  reindexNode($node);                                                           # Create index for this node
  my $c = $node->indexes->{$tag};                                               # Index for specified tags
  $c ? @$c : ()                                                                 # Contents as an array
 }

#D2 First                                                                       # Find nodes that are first amongst their siblings.

sub first($@)                                                                   #BCY Return the first node below the specified B<$node> optionally checking its context.  See L<addFirst|/addFirst> to ensure that an expected node is in position.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return $node->content->[0] unless @context;                                   # Return first node if no context specified
  my ($c) = $node->contents;                                                    # First node
  $c ? $c->at(@context) : undef;                                                # Return first node if in specified context
 }

sub firstn($$@)                                                                 #C Return the B<$n>'th first node below the specified B<$node> optionally checking its context or B<undef> if there is no such node.  B<firstn(1)> is identical in effect to L<first|/first>.
 {my ($node, $N, @context) = @_;                                                # Node, number of times to go first, optional context.
  return undef if @context and !$node->at(@context);                            # Check the context if supplied
  for(1..$N)                                                                    # Go first the specified number of times
   {$node = $node->first;                                                       # Go first
    last unless $node;                                                          # Cannot go further
   }
  $node
 }

sub firstText($@)                                                               #CY Return the first node if it is a text node otherwise B<undef>
 {my ($node, @context) = @_;                                                    # Node, optional context.
  my $l = &first(@_);                                                           # First node
  $l ? $l->isText : undef                                                       # Test whether the first node exists and is a text node
 }

sub firstTextMatches($$@)                                                       #C Return the first node under the specified B<$node> if: it is a text mode; its text matches the specified regular expression; the specified B<$node> is in the optional specified context. Else return B<undef>.
 {my ($node, $match, @context) = @_;                                            # Node, regular expression the text must match, optional context of specified node.
  return undef if @context and !$node->at(@context);                            # Check context
  if (my $t = $node->firstText)                                                 # First node is text
   {return $t->matchesText($match);                                             # First text node matches the specified regular expression
   }
  undef                                                                         # First node is not text or does not match the specified regular expression
 }

sub firstBy($@)                                                                 # Return a list of the first instance of each specified tag encountered in a post-order traversal from the specified B<$node> or a hash of all first instances if no tags are specified.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags;                                                                     # Tags found first
  $node->byReverse(sub {$tags{$_->tag} = $_});                                  # Save first instance of each node
  return %tags unless @tags;                                                    # Return hash of all tags encountered first unless @tags filter was specified
  map {$tags{$_}} @tags;                                                        # Nodes in the requested order
 }

sub firstDown($@)                                                               # Return a list of the first instance of each specified tag encountered in a pre-order traversal from the specified B<$node> or a hash of all first instances if no tags are specified.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags;                                                                     # Tags found first
  $node->downReverse(sub {$tags{$_->tag} = $_});                                # Save first instance of each node
  return %tags unless @tags;                                                    # Return hash of all tags encountered first unless @tags filter was specified
  map {$tags{$_}} @tags;                                                        # Nodes in the requested order
 }

sub firstIn($@)                                                                 #Y Return the first child node matching one of the named tags under the specified parent node.
 {my ($node, @tags) = @_;                                                       # Parent node, child tags to search for.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  for($node->contents)                                                          # Search forwards through contents
   {return $_ if $tags{$_->tag};                                                # Find first tag with the specified name
   }
  return undef                                                                  # No such node
 }

sub firstNot($@)                                                                # Return the first child node that does not match any of the named B<@tags> under the specified parent B<$node>. Return B<undef> if there is no such child node.
 {my ($node, @tags) = @_;                                                       # Parent node, child tags to avoid.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  for($node->contents)                                                          # Search forwards through contents
   {return $_ unless $tags{$_->tag};                                            # Find first tag that fails to match
   }
  return undef                                                                  # No such node
 }

sub firstInIndex($@)                                                            #CY Return the specified B<$node> if it is first in its index and optionally L<at|/at> the specified context else B<undef>
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Check the context if supplied
  my $parent = $node->parent;                                                   # Parent
  return undef unless $parent;                                                  # The root node is not first in anything
  my @c = $parent->c($node->tag);                                               # Index containing node
  @c && $c[0] == $node ? $node : undef                                          # First in index ?
 }

sub firstOf($@)                                                                 # Return an array of the nodes that are continuously first under their specified parent node and that match the specified list of tags.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  my @l;                                                                        # Matching last nodes
  for($node->contents)                                                          # Search through contents
   {return @l unless $tags{$_->tag};                                            # Nonmatching tag
    push @l, $_;                                                                # Save continuously matching tag in correct order
   }
  return @l                                                                     # All tags match
 }

sub firstWhile($@)                                                              # Go first from the specified B<$node> and continue deeper as long as each first child node matches one of the specified B<@tags>. Return the deepest such node encountered or else return B<undef> if no such node is encountered.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  my $p;                                                                        # Current position
  for(my $f = $node->first; $f and $tags{-t $f}; $f = $f->first) {$p = $f}      # Go ever firstly
  $p
 }

sub firstUntil($@)                                                              # Go first from the specified B<$node> and continue deeper until a first child node matches the specified B<@context> or return B<undef> if there is no such node.  Return the first child of the specified B<$node> if no B<@context> is specified.
 {my ($node, @context) = @_;                                                    # Node, context to search for.
  for(my $p = $node->first; $p; $p = $p->first)                                 # Check each first child node below the B<$node>
   {return $p if $p->at(@context);                                              # Return the node if it matches the specified context
   }
  undef
 }

sub firstContextOf($@)                                                          #Y Return the first node encountered in the specified context in a depth first post-order traversal of the L<parse|/parse> tree.
 {my ($node, @context) = @_;                                                    # Node, array of tags specifying context.
  my $x;                                                                        # Found node if found
  eval                                                                          # Trap the die which signals success
   {$node->by(sub                                                               # Traverse  L<parse|/parse> tree in depth first order
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

sub firstSibling($@)                                                            #CY Return the first sibling of the specified B<$node> in the optional context else B<undef>
 {my ($node, @context) = @_;                                                    # Node, array of tags specifying context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $p = $node->parent;                                                        # Parent node
  $p->first                                                                     # Return first sibling
 }

#D2 Last                                                                        # Find nodes that are last amongst their siblings.

sub last($@)                                                                    #BCY Return the last node below the specified B<$node> optionally checking its context. See L<addLast|/addLast> to ensure that an expected node is in position.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return $node->content->[-1] unless @context;                                  # Return last node if no context specified
  my ($c) = reverse $node->contents;                                            # Last node
  $c ? $c->at(@context) : undef;                                                # Return last node if in specified context
 }

sub lastn($$@)                                                                  #C Return the B<$n>'th last node below the specified B<$node> optionally checking its context or B<undef> if there is no such node.  B<lastn(1)> is identical in effect to L<last|/last>.
 {my ($node, $N, @context) = @_;                                                # Node, number of times to go last, optional context.
  return undef if @context and !$node->at(@context);                            # Check the context if supplied
  for(1..$N)                                                                    # Go last the specified number of times
   {$node = $node->last;                                                        # Go last
    last unless $node;                                                          # Cannot go further
   }
  $node
 }

sub lastText($@)                                                                #CY Return the last node if it is a text node otherwise B<undef>
 {my ($node, @context) = @_;                                                    # Node, optional context.
  my $l = &last(@_);                                                            # Last node
  $l ? $l->isText : undef                                                       # Test whether the last node exists and is a text node
 }

sub lastTextMatches($$@)                                                        #C Return the last node under the specified B<$node> if: it is a text mode; its text matches the specified regular expression; the specified B<$node> is in the optional specified context. Else return B<undef>.
 {my ($node, $match, @context) = @_;                                            # Node, regular expression the text must match, optional context of specified  node.
  return undef if @context and !$node->at(@context);                            # Check context
  if (my $t = $node->lastText)                                                  # Last node is text
   {return $t->matchesText($match);                                             # Last text node matches the specified regular expression
   }
  undef                                                                         # Last node is not text or does not match the specified regular expression
 }

sub lastBy($@)                                                                  # Return a list of the last instance of each specified tag encountered in a post-order traversal from the specified B<$node> or a hash of all last instances if no tags are specified.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags;                                                                     # Tags found first
  $node->by(sub {$tags{$_->tag} = $_});                                         # Save last instance of each node
  return %tags unless @tags;                                                    # Return hash of all tags encountered last unless @tags filter was specified
  map {$tags{$_}} @tags;                                                        # Nodes in the requested order
 }

sub lastDown($@)                                                                # Return a list of the last instance of each specified tag encountered in a pre-order traversal from the specified B<$node> or a hash of all last instances if no tags are specified.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags;                                                                     # Tags found first
  $node->down(sub {$tags{$_->tag} = $_});                                       # Save last instance of each node
  return %tags unless @tags;                                                    # Return hash of all tags encountered last unless @tags filter was specified
  map {$tags{$_}} @tags;                                                        # Nodes in the requested order
 }

sub lastIn($@)                                                                  #Y Return the last child node matching one of the named tags under the specified parent node.
 {my ($node, @tags) = @_;                                                       # Parent node, child tags to search for.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  for(reverse $node->contents)                                                  # Search backwards through contents
   {return $_ if $tags{$_->tag};                                                # Find last tag with the specified name
   }
  return undef                                                                  # No such node
 }

sub lastNot($@)                                                                 # Return the last child node that does not match any of the named B<@tags> under the specified parent B<$node>. Return B<undef> if there is no such child node.
 {my ($node, @tags) = @_;                                                       # Parent node, child tags to avoid.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  for(reverse $node->contents)                                                  # Search backwards through contents
   {return $_ unless $tags{$_->tag};                                            # Find last tag that fails to match
   }
  return undef                                                                  # No such node
 }

sub lastOf($@)                                                                  # Return an array of the nodes that are continuously last under their specified parent node and that match the specified list of tags.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  my @l;                                                                        # Matching last nodes
  for(reverse $node->contents)                                                  # Search backwards through contents
   {return @l unless $tags{$_->tag};                                            # Nonmatching tag
    unshift @l, $_;                                                             # Save continuously matching tag in correct order
   }
  return
   @l                                                                     # All tags match
 }

sub lastInIndex($@)                                                             #CY Return the specified B<$node> if it is last in its index and optionally L<at|/at> the specified context else B<undef>
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Check the context if supplied
  my $parent = $node->parent;                                                   # Parent
  return undef unless $parent;                                                  # The root node is not first in anything
  my @c = $parent->c($node->tag);                                               # Index containing node
  @c && $c[-1] == $node ? $node : undef                                         # Last in index ?
 }

sub lastContextOf($@)                                                           #Y Return the last node encountered in the specified context in a depth first reverse pre-order traversal of the L<parse|/parse> tree.
 {my ($node, @context) = @_;                                                    # Node, array of tags specifying context.
  my $x;                                                                        # Found node if found
  eval                                                                          # Trap the die which signals success
   {$node->downReverse(sub                                                      # Traverse  L<parse|/parse> tree in depth first order
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

sub lastSibling($@)                                                             #CY Return the last sibling of the specified B<$node> in the optional context else B<undef>
 {my ($node, @context) = @_;                                                    # Node, array of tags specifying context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $p = $node->parent;                                                        # Parent node
  $p->last                                                                      # Return last sibling
 }

sub lastWhile($@)                                                               # Go last from the specified B<$node> and continue deeper as long as each last child node matches one of the specified B<@tags>. Return the deepest such node encountered or else return B<undef> if no such node is encountered.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
 #return undef unless $tags{-t $node};                                          # Confirm that the last node matches
  my $p;                                                                        # Current position
  for(my $l = $node->last; $l and $tags{-t $l}; $l = $l->first) {$p = $l}       # Go ever lastly
  $p
 }

sub lastUntil($@)                                                               # Go last from the specified B<$node> and continue deeper until a last child node matches the specified B<@context> or return B<undef> if there is no such node.  Return the last child of the specified B<$node> if no B<@context> is specified.
 {my ($node, @context) = @_;                                                    # Node, context to search for.
  for(my $p = $node->last; $p; $p = $p->last)                                   # Check each last child node below the B<$node>
   {return $p if $p->at(@context);                                              # Return the node if it matches the specified context
   }
  undef
 }

#D2 Next                                                                        # Find sibling nodes after the specified B<$node>.

sub next($@)                                                                    #BCY Return the node next to the specified B<$node>, optionally checking its context. See L<addNext|/addNext> to ensure that an expected node is in position.
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

sub nextn($$@)                                                                  #C Return the B<$n>'th next node after the specified B<$node> optionally checking its context or B<undef> if there is no such node.  B<nextn(1)> is identical in effect to L<next|/next>.
 {my ($node, $N, @context) = @_;                                                # Node, number of times to go next, optional context.
  return undef if @context and !$node->at(@context);                            # Check the context if supplied
  for(1..$N)                                                                    # Go next the specified number of times
   {$node = $node->next;                                                        # Go next
    last unless $node;                                                          # Cannot go further
   }
  $node
 }

sub nextText($@)                                                                #CY Return the next node after the specified B<$node> if it is a text node otherwise B<undef>
 {my ($node, @context) = @_;                                                    # Node, optional context.
  my $n = &next(@_);                                                            # Next node
  $n ? $n->isText : undef                                                       # Test whether the next node exists and is a text node
 }

sub nextTextMatches($$@)                                                        #C Return the next node to the specified B<$node> if: it is a text mode; its text matches the specified regular expression; the specified B<$node> is in the optional specified context. Else return B<undef>.
 {my ($node, $match, @context) = @_;                                            # Node, regular expression the text must match, optional context of specified node.
  return undef if @context and !$node->at(@context);                            # Check context
  if (my $t = $node->nextText)                                                  # Next node is text
   {return $t->matchesText($match);                                             # Next text node matches the specified regular expression
   }
  undef                                                                         # Next node is not text or does not match the specified regular expression
 }

sub nextIn($@)                                                                  #Y Return the nearest sibling after the specified B<$node> that matches one of the named tags or B<undef> if there is no such sibling node.
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

sub nextOn($@)                                                                  # Step forwards as far as possible from the specified B<$node> while remaining on nodes with the specified tags. In scalar context return the last such node reached or the starting node if no such steps are possible. In array context return the start node and any following matching nodes.
 {my ($node, @tags) = @_;                                                       # Start node, tags identifying nodes that can be step on to context.
  return wantarray ? ($node) : $node if $node->isLast;                          # Easy case
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

sub nextWhile($@)                                                               # Go to the next sibling of the specified B<$node> and continue forwards while the tag of each sibling node matches one of the specified B<@tags>. Return the first sibling node that does not match else B<undef> if there is no such sibling.
 {my ($node, @tags) = @_;                                                       # Node, child tags to avoid.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  for($node->contentAfter)                                                      # Search forwards through siblings
   {return $_ unless $tags{$_->tag};                                            # Find first tag that fails to match
   }
  return undef                                                                  # No such node
 }

sub nextUntil($@)                                                               # Go to the next sibling of the specified B<$node> and continue forwards until the tag of a sibling node matches one of the specified B<@tags>. Return the matching sibling node else B<undef> if there is no such sibling node.
 {my ($node, @tags) = @_;                                                       # Node, tags to look for.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  for($node->contentAfter)                                                      # Search forwards through following siblings
   {return $_ if $tags{$_->tag};                                                # Find next node that matches on of the supplied tags
   }
  undef                                                                         # No such node
 }

#D2 Prev                                                                        # Find sibling nodes before the specified B<$node>.

sub prev($@)                                                                    #BCY Return the node before the specified B<$node>, optionally checking its context. See L<addLast|/addLast> to ensure that an expected node is in position.
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

sub prevText($@)                                                                #CY Return the previous node if it is a text node otherwise B<undef>
 {my ($node, @context) = @_;                                                    # Node, optional context.
  my $p = &prev(@_);                                                            # Previous node
  $p ? $p->isText : undef                                                       # Test whether the previous node exists and is a text node
 }

sub prevn($$@)                                                                  #C Return the B<$n>'th previous node after the specified B<$node> optionally checking its context or B<undef> if there is no such node.  B<prevn(1)> is identical in effect to L<prev|/prev>.
 {my ($node, $N, @context) = @_;                                                # Node, number of times to go prev, optional context.
  return undef if @context and !$node->at(@context);                            # Check the context if supplied
  for(1..$N)                                                                    # Go previous the specified number of times
   {$node = $node->prev;                                                        # Go previous
    last unless $node;                                                          # Cannot go further
   }
  $node
 }

sub prevTextMatches($$@)                                                        #C Return the previous node to the specified B<$node> if: it is a text mode; its text matches the specified regular expression; the specified B<$node> is in the optional specified context. Else return B<undef>.
 {my ($node, $match, @context) = @_;                                            # Node, regular expression the text must match, optional context of specified node.
  return undef if @context and !$node->at(@context);                            # Check context
  if (my $t = $node->prevText)                                                  # Previous node is text
   {return $t->matchesText($match);                                             # Previous text node matches the specified regular expression
   }
  undef                                                                         # Previous node is not text or does not match the specified regular expression
 }

sub prevIn($@)                                                                  #Y Return the nearest sibling node before the specified B<$node> which matches one of the named tags or B<undef> if there is no such sibling node.
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
  return wantarray ? ($node) : $node if $node->isFirst;                          # Easy case
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
   {shift @c while @c > 1 and $tags{$c[1]->tag};                                # Proceed forwards but staying on acceptable tags
    return $c[0]                                                                # Current node or last acceptable tag reached while staying on acceptable tags
   }
 }

sub prevWhile($@)                                                               # Go to the previous sibling of the specified B<$node> and continue backwards while the tag of each sibling node matches one of the specified B<@tags>. Return the first sibling node that does not match else B<undef> if there is no such sibling.
 {my ($node, @tags) = @_;                                                       # Parent node, child tags to avoid.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  for(reverse $node->contentBefore)                                             # Search backwards through siblings
   {return $_ unless $tags{$_->tag};                                            # Find first tag that fails to match
   }
  return undef                                                                  # No such node
 }

sub prevUntil($@)                                                               # Go to the previous sibling of the specified B<$node> and continue backwards until the tag of a sibling node matches one of the specified B<@tags>. Return the matching sibling node else B<undef> if there is no such sibling node.
 {my ($node, @tags) = @_;                                                       # Node, tags to look for.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  for($node->contentBefore)                                                     # Search forwards through following siblings
   {return $_ if $tags{$_->tag};                                                # Find next node that matches on of the supplied tags
   }
  undef                                                                         # No such node
 }

#D2 Up                                                                          # Methods for moving up the L<parse|/parse> tree from a node.

sub up($@)                                                                      #CY Return the parent of the current node optionally checking the context of the specified B<$node> first or return B<undef> if the specified B<$node> is the root of the L<parse|/parse> tree.   See L<addWrapWith|/addWrapWith> to ensure that an expected node is in position.
 {my ($node, @tags) = @_;                                                       # Start node, optional tags identifying context.
  return undef if @tags and !$node->at(@tags);                                  # Check optional context
  $node->parent                                                                 # Go up one level
 }

sub upn($$@)                                                                    #C Go up the specified number of levels from the specified B<$node> and return the node reached or B<undef> if there is no such node.L<upn(1)|/up> is identical in effect to L<up|/up>.  Or use L<ancestry|/ancestry> to get the path back to the root node.
 {my ($node, $levels, @context) = @_;                                           # Start node, number of levels to go up, optional context.
  return undef if @context and !$node->at(@context);                            # Check optional context
  for(my $c = 0; $node and $c < $levels; $node = $node->parent, ++$c) {}        # Number of levels move up
  $node                                                                         # Return node reached
 }

sub upWhile($@)                                                                 #Y Go up one level from the specified B<$node> and then continue up while each node matches on of the specified <@tags>. Return the last matching node or B<undef> if no node matched any of the specified B<@tags>.
 {my ($node, @tags) = @_;                                                       # Start node, tags to match
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  my $lastMatch;                                                                # Last good match
  for(my $p = $node->parent; $p; $p = $p->parent)                               # Go up
   {last unless $tags{-t $p};                                                   # Found an ancestor that does not match
    $lastMatch = $p;
   }
  $lastMatch                                                                    # Last good match
 }

sub upWhileFirst($@)                                                            #C Move up from the specified B<$node> as long as each node is a first node or return B<undef> if the specified B<$node> is not a first node.
 {my ($node, @context) = @_;                                                    # Start node, optional context
  return undef if @context && !$node->at(@context) or !$node->isFirst;          # Check the context if supplied and that the node is first
  my $lastMatch = $node;                                                        # First node
  for(my $p = $node->parent; $p; $p = $p->parent)                               # Go up
   {return $lastMatch unless $p->isFirst;                                       # Return last node which was first
    $lastMatch = $p                                                             # Update last matching position
   }
  $lastMatch                                                                    # Root node matches
 }

sub upWhileLast($@)                                                             #C Move up from the specified B<$node> as long as each node is a last node or return B<undef> if the specified B<$node> is not a last node.
 {my ($node, @context) = @_;                                                    # Start node, optional context
  return undef if @context && !$node->at(@context) or !$node->isLast;           # Check the context if supplied and that the node is last
  my $lastMatch = $node;                                                        # Last node
  for(my $p = $node->parent; $p; $p = $p->parent)                               # Go up
   {return $lastMatch unless $p->isLast;                                        # Return last node which was last
    $lastMatch = $p                                                             # Update last matching position
   }
  $lastMatch                                                                    # Root node matches
 }

sub upWhileIsOnlyChild($@)                                                      #C Move up from the specified B<$node> as long as each node is an only child or return B<undef> if the specified B<$node> is not an only child.
 {my ($node, @context) = @_;                                                    # Start node, optional context
  return undef if @context && !$node->at(@context) or !$node->isOnlyChild;      # Check the context if supplied and that the node is an only child
  my $lastMatch = $node;                                                        # Last node
  for(my $p = $node->parent; $p; $p = $p->parent)                               # Go up
   {return $lastMatch unless $p->isOnlyChild;                                   # Return last node which was an only child
    $lastMatch = $p                                                             # Update last matching position
   }
  $lastMatch                                                                    # Root node matches
 }

sub upUntil($@)                                                                 #Y Return the nearest ancestral node to the specified B<$node> that matches the specified B<@context> or B<undef> if there is no such node.  Returns the parent node of the specified B<$node> if no B<@context> is specified.
 {my ($node, @context) = @_;                                                    # Start node, context.
  for(my $p = $node->parent; $p; $p = $p->parent)                               # Go up
   {return $p if $p->at(@context);                                              # Return node which satisfies the condition
   }
  return undef                                                                  # Not found
 }

sub upUntilFirst($@)                                                            #C Move up from the specified B<$node> until we reach the root or a first node.
 {my ($node, @context) = @_;                                                    # Start node, optional context
  return undef if @context and !$node->at(@context);                            # Check the context if supplied
  for(my $p = $node; $p; $p = $p->parent)                                       # Go up
   {return $p if $p->isFirst;                                                   # Return first first node
   }
  undef                                                                         # This should not happen
 }

sub upUntilLast($@)                                                             #C Move up from the specified B<$node> until we reach the root or a last node.
 {my ($node, @context) = @_;                                                    # Start node, optional context
  return undef if @context and !$node->at(@context);                            # Check the context if supplied
  for(my $p = $node; $p; $p = $p->parent)                                       # Go up
   {return $p if $p->isLast;                                                    # Return first last node
   }
  undef                                                                         # This should not happen
 }

sub upUntilIsOnlyChild($@)                                                      #C Move up from the specified B<$node> until we reach the root or another only child.
 {my ($node, @context) = @_;                                                    # Start node, optional context
  return undef if @context and !$node->at(@context);                            # Check the context if supplied and that the node is an only child
  for(my $p = $node; $p; $p = $p->parent)                                       # Go up
   {return $p if $p->isOnlyChild;                                               # Return last node which was an only child
   }
  undef                                                                         # This should not happen
 }

sub upThru($@)                                                                  #Y Go up the specified path from the specified B<$node> returning the node at the top or B<undef> if no such node exists.
 {my ($node, @tags) = @_;                                                       # Start node, tags identifying path.
  while(@tags)                                                                  # Go up through the tags
   {$node = $node->parent;                                                      # Go up on level
    return undef unless $node and $node->at(shift @tags);                       # Failed to match next tag
   }
  $node                                                                         # Reached the top of the path
 }

#D2 down                                                                        # Methods for moving down through the L<parse|/parse> tree from a node.

sub downWhileFirst($@)                                                          #C Move down from the specified B<$node> as long as each lower node is a first node.
 {my ($node, @context) = @_;                                                    # Start node, optional context
  return undef if @context and !$node->at(@context);                            # Check the context if supplied
  for(my $p = $node->first; $p; $p = $p->first)                                 # Go down firstly
   {return $p unless $p->first;                                                 # Return node unless there is another one below it
   }
  $node->isFirst                                                                # Leaf node
 }

BEGIN{*firstLeaf=*downWhileFirst}

sub downWhileLast($@)                                                           #C Move down from the specified B<$node> as long as each lower node is a last node.
 {my ($node, @context) = @_;                                                    # Start node, optional context
  return undef if @context and !$node->at(@context);                            # Check the context if supplied
  for(my $p = $node->last; $p; $p = $p->last)                                   # Go down lastly
   {return $p unless $p->last;                                                  # Return node unless there is another one below it
   }
  $node->isLast                                                                 # Leaf node
 }

BEGIN{*lastLeaf=*downWhileLast}

sub downWhileHasSingleChild($@)                                                 #C Move down from the specified B<$node> as long as it has a single child else return undef.
 {my ($node, @context) = @_;                                                    # Start node, optional context
  return undef if @context and !$node->at(@context);                            # Check the context if supplied
  my $q;
  for(my $p = $node; $p; $q = $p, $p = $p->first)
   {last unless $p->hasSingleChild;
   }
  $q
 }

#D1 Editing                                                                     # Edit the data in the L<parse|/parse> tree and change the structure of the L<parse|/parse> tree by L<wrapping and unwrapping|/Wrap and unwrap> nodes, by L<replacing|/Replace> nodes, by L<cutting and pasting|/Cut and Put> nodes, by L<concatenating|/Fusion> nodes, by L<splitting|/Fission> nodes, by adding new L<text|/Put as text> nodes or L<swapping|/swap> nodes.

sub change($$@)                                                                 #CIY Change the name of the specified B<$node>, optionally  confirming that the B<$node> is in a specified context and return the B<$node>.
 {my ($node, $name, @context) = @_;                                             # Node, new name, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->tag = $name;                                                           # Change name
  if (my $parent = $node->parent) {$parent->indexNode}                          # Reindex parent
  $node
 }

sub changeText($$@)                                                             #CY If the specified  B<$node> is a text node in the specified context then the specified B<sub> is passed the text of the node in L<$_>, any changes to which are recorded in the text of the B<$node>.\mReturns B<undef> if the specified B<$node> is not a text node in the specified optional context else it returns the result of executing the specified B<sub>.
 {my ($node, $sub, @context) = @_;                                              # Text node, sub, optional context.
  return undef unless $node->isText(@context);                                  # Check that this is a text node in the specified context.
  local $_ = my $t = $node->text;                                               # Address text
  my $r = $sub->();                                                             # Perform change
  $node->text = $_ unless $_ eq $t;                                             # Update text if changed
  $r                                                                            # Return result of changes
 }

#D2 Cut and Put                                                                 # Move nodes around in the L<parse|/parse> tree by cutting and pasting them.

sub cut($@)                                                                     #CI Cut out the specified B<$node> so that it can be reinserted else where in the L<parse|/parse> tree.
 {my ($node, @context) = @_;                                                    # Node to cut out, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $parent = $node->parent;                                                   # Parent node
  # confess "Already cut out" unless $parent;                                   # We have to let thing be cut out more than once or supply an isCutOut() method
  return $node unless $parent;                                                  # Uppermost node is already cut out
  my $c = $parent->content;                                                     # Content array of parent
  my $i = $node->position;                                                      # Position in content array
  splice(@$c, $i, 1);                                                           # Remove node
  $parent->indexNode;                                                           # Rebuild indices
  $node->disconnectLeafNode;                                                    # Disconnect node no longer in L<parse|/parse> tree
  $node                                                                         # Return node
 }

sub deleteContent($@)                                                           #C Delete the content of the specified B<$node>.
 {my ($node, @context) = @_;                                                    # Node, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->content = [];                                                          # Delete content
  $node                                                                         # Return node
 }

sub putFirst($$@)                                                               #C Place a L<cut out|/cut> or L<new|/new> node at the front of the content of the specified B<$node> and return the new node. See L<addFirst|/addFirst> to perform this operation conditionally.
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

sub putFirstCut($$@)                                                            #C Cut out the second node, place it first under the first node and return the second node.
 {my ($old, $new, @context) = @_;                                               # First node, second node, optional context.
  $old->putFirst($new->cut, @context);
 }

sub putLast($$@)                                                                #CI Place a L<cut out|/cut> or L<new|/new> node last in the content of the specified B<$node> and return the new node.  See L<addLast|/addLast> to perform this operation conditionally.
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

sub putLastCut($$@)                                                             #C Cut out the second node, place it last under the first node and return the second node.
 {my ($old, $new, @context) = @_;                                               # First node, second node, optional context.
  $old->putLast($new->cut, @context);
 }

sub putNext($$@)                                                                #C Place a L<cut out|/cut> or L<new|/new> node just after the specified B<$node> and return the new node. See L<addNext|/addNext> to perform this operation conditionally.
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

sub putNextCut($$@)                                                             #C Cut out the second node, place it next after the first node and return the second node.
 {my ($old, $new, @context) = @_;                                               # First node, second node, optional context.
  $old->putNext($new->cut, @context);
 }

sub putPrev($$@)                                                                #C Place a L<cut out|/cut> or L<new|/new> node just before the specified B<$node> and return the new node.  See L<addPrev|/addPrev> to perform this operation conditionally.
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

sub putPrevCut($$@)                                                             #C Cut out the second node, place it before the first node and return the second node.
 {my ($old, $new, @context) = @_;                                               # First node, second node, optional context.
  $old->putPrev($new->cut, @context);
 }

#D2 Add selectively                                                             # Add new nodes unless they already exist.

sub addFirst($$%)                                                               # Add a new node L<first|/first> below the specified B<$node> and return the new node unless a node with that tag already exists in which case return the existing B<$node>.
 {my ($node, $tag, %attributes) = @_;                                           # Node, tag of new node, attributes for the new node.
  if (my $f = $node->first)                                                     # Existing first node
   {return $f if $f->tag eq $tag;                                               # Return existing first node with matching tag
   }
  $node->putFirst($node->newTag($tag, %attributes))                             # Create a new node, place it first below the specified node and return the new node.
 }

sub addNext($$%)                                                                # Add a new node L<next|/next> to the specified B<$node> and return the new node unless a node with that tag already exists in which case return the existing B<$node>.
 {my ($node, $tag, %attributes) = @_;                                           # Node, tag of new node, attributes for the new node.
  if (my $n = $node->next)                                                      # Existing next node
   {return $n if $n->tag eq $tag;                                               # Return existing next node with matching tag
   }
  $node->putNext($node->newTag($tag, %attributes))                              # Create a new node, place it next to the specified node and return the new node.
 }

sub addPrev($$%)                                                                # Add a new node L<before|/prev> the specified B<$node> and return the new node unless a node with that tag already exists in which case return the existing B<$node>.
 {my ($node, $tag, %attributes) = @_;                                           # Node, tag of new node, attributes for the new node.
  if (my $n = $node->next)                                                      # Existing previous node
   {return $n if $n->tag eq $tag;                                               # Return existing previous node with matching tag
   }
  $node->putPrev($node->newTag($tag, %attributes))                              # Create a new node, place it before the specified node and return the new node.
 }

sub addLast($$%)                                                                # Add a new node L<last|/last> below the specified B<$node> and return the new node unless a node with that tag already exists in which case return the existing B<$node>.
 {my ($node, $tag, %attributes) = @_;                                           # Node, tag of new node, attributes for the new node.
  if (my $l = $node->last)                                                      # Existing last node
   {return $l if $l->tag eq $tag;                                               # Return existing first node with matching tag
   }
  $node->putLast($node->newTag($tag, %attributes))                              # Create a new node, place it last below the specified node and return the new node.
 }

sub addWrapWith($$%)                                                            # L<Wrap|/wrap> the specified B<$node> with the specified tag if the node is not already wrapped with such a tag and return the new node unless a node with that tag already exists in which case return the existing B<$node>.
 {my ($node, $tag, %attributes) = @_;                                           # Node, tag of new node, attributes for the new node.
  if (my $l = $node->parent)                                                    # Existing wrapping node
   {return $l if $l->tag eq $tag;                                               # Return existing first node with matching tag
   }
  $node->wrapWith($tag, %attributes)                                            # Wrap with the specified node
 }

sub addSingleChild($$%)                                                         # Wrap the content of a specified B<$node> in a new node with the specified B<$tag> and optional B<%attribute> unless the content is already wrapped in a single child with the specified B<$tag>.
 {my ($node, $tag, %attributes) = @_;                                           # Node, tag of new node, attributes for the new node.
  if (my $c = $node->hasSingleChild)                                            # Return the existing child if it is an only child and has the right tag
   {return $c if -t $c eq $tag;
   }
  &wrapContentWith(@_);                                                         # Normal wrap content with new node
 }

#D2 Add text selectively                                                        # Add new text unless it already exists.

sub addFirstAsText($$)                                                          # Add a new text node first below the specified B<$node> and return the new node unless a text node already exists there and starts with the same text in which case return the existing B<$node>.
 {my ($node, $text) = @_;                                                       # Node, text
  if (my $f = $node->first)                                                     # Existing first node
   {return $f if $f->isText and $f->text =~ m(\A$text);                         # Return existing first node if is a text node with the same starting text
   }
  $node->putFirstAsText($text)                                                  # Create a new text node, place it first below the specified node and return the new text node.
 }

sub addNextAsText($$)                                                           # Add a new text node after the specified B<$node> and return the new node unless a text node already exists there and starts with the same text in which case return the existing B<$node>.
 {my ($node, $text) = @_;                                                       # Node, text
  if (my $n = $node->next)                                                      # Existing next node
   {return $n if $n->isText and $n->text =~ m(\A$text);                         # Return existing next node if is a text node with the same starting text
   }
  $node->putNextAsText($text)                                                   # Create a new text node, place it after the specified node and return the new text node.
 }

sub addPrevAsText($$)                                                           # Add a new text node before the specified B<$node> and return the new node unless a text node already exists there and ends with the same text in which case return the existing B<$node>.
 {my ($node, $text) = @_;                                                       # Node, text
  if (my $p = $node->prev)                                                      # Existing previous node
   {return $p if $p->isText and $p->text =~ m($text\Z);                         # Return existing previous node if is a text node with the same ending text
   }
  $node->putPrevAsText($text)                                                   # Create a new text node, place it before the specified node and return the new text node.
 }

sub addLastAsText($$)                                                           # Add a new text node last below the specified B<$node> and return the new node unless a text node already exists there and ends with the same text in which case return the existing B<$node>.
 {my ($node, $text) = @_;                                                       # Node, text
  if (my $l = $node->last)                                                      # Existing last node
   {return $l if $l->isText and $l->text =~ m($text\Z);                         # Return existing last node if is a text node with the same ending text
   }
  $node->putLastAsText($text)                                                   # Create a new text node, place it last below the specified node and return the new text node.
 }

#D2 Fusion                                                                      # Join consecutive nodes

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

sub concatenateSiblings($@)                                                     #C Concatenate preceding and following nodes as long as they have the same tag as the specified B<$node> and return the specified B<$node>.
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

sub mergeDuplicateChildWithParent($@)                                           #C Merge a parent node with its only child if their tags are the same and their attributes do not collide other than possibly the id in which case the parent id is used. Any labels on the child are transferred to the parent. The child node is then unwrapped and the parent node is returned.
 {my ($parent, @context) = @_;                                                  # Parent this node, optional context.
  return undef if @context and !$parent->at(@context);                          # Not in specified context
  return undef unless my $child = $parent->hasSingleChild;                      # Not an only child
  return undef unless $child->tag eq $parent->tag;                              # Tags differ
  my %c = %{$child->attributes};                                                # Child attributes
  my %p = %{$parent->attributes};                                               # Parent attributes
  $p{id} = $c{id} unless $p{id};                                                # Transfer child id unless parent already has one
  delete $c{id};                                                                # Remove child id
  for(sort keys %c)                                                             # Remaining attributes
   {return undef if $p{$_} and $p{$_} ne $c{$_};                                # Attributes collide
    $p{$_} = $c{$_};                                                            # Transfer non colliding attribute
   }
  $parent->attributes = \%p;                                                    # Transfer the attributes en masses as none of them collide
  $child->copyLabels($parent);                                                  # Copy child labels to parent
  -W $child;                                                                    # Unwrap child
  $parent                                                                       # Return original node
 }

#D2 Put as text                                                                 # Add text to the L<parse|/parse> tree.

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

sub putNextAsText($$@)                                                          #C Add a new text node following the specified B<$node> and return the new text node.
 {my ($node, $text, @context) = @_;                                             # The parent node, the string to be added which might contain unparsed Xml as well as text, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->putNext(my $t = $node->newText($text));                                # Add new text node
  $t                                                                            # Return new node
 }

sub putPrevAsText($$@)                                                          #C Add a new text node following the specified B<$node> and return the new text node
 {my ($node, $text, @context) = @_;                                             # The parent node, the string to be added which might contain unparsed Xml as well as text, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->putPrev(my $t = $node->newText($text));                                # Add new text node
  $t                                                                            # Return new node
 }

#D2 Break in and out                                                            # Break nodes out of nodes or push them back

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

#D2 Replace                                                                     # Replace nodes in the L<parse|/parse> tree with nodes or text

sub replaceWith($$@)                                                            #C Replace a node (and all its content) with a L<new node|/newTag> (and all its content) and return the new node. If the node to be replaced is the root of the L<parse|/parse> tree then no action is taken other then returning the new node.
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
sub replaceContentWithMovedContent($@)                                          # Replace the content of a specified target node with the contents of the specified source nodes removing the content from each source node and return the target node.
 {my ($node, @nodes) = @_;                                                      # Target node, source nodes
  my @content;                                                                  # Target content array
  for my $source(@nodes)                                                        # Each source node
   {push @content, $source->contents;                                           # Build target content array
    $source->content = undef;                                                   # Move content
    $source->indexNode;                                                         # Rebuild indices
   }
  $node->content = [@content];                                                  # Insert new content
  $node->indexNode;                                                             # Rebuild indices
  $node                                                                         # Return target node
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

#D2 Swap                                                                        # Swap nodes both singly and in blocks

sub invert($@)                                                                  #C Swap a parent and child node where the child is the only child of the parent and return the parent.
 {my ($parent, @context) = @_;                                                  # Parent, context
  return undef unless my $child = $parent->hasSingleChild(@context);            # Single child
  my $grandParent = $parent->parent;                                            # Grandparent
  $grandParent or confess "Cannot invert the outer most node";                  # Cannot invert root
  $parent->unwrap;                                                              # Unwrap parent
  my $content = $child->content;                                                # Child content
  $child->content  = [$parent];                                                 # Place parent under child
  $parent->content = $content;                                                  # Place child content under parent
  $child->parent   = $grandParent;                                              # Grand parent
  $parent->parent  = $child;                                                    # Parent
  $_->indexNode for $child, $parent, $grandParent;                              # Index modified nodes
  $parent                                                                       # Return parent
 }

sub invertFirst($@)                                                             #C Swap a parent and child node where the child is the first child of the parent by placing the parent last in the child. Return the parent.
 {my ($parent, @context) = @_;                                                  # Parent, context
  return undef if @context and !$parent->at(@context);                          # Not in specified context
  return undef unless my $child = $parent->first;                               # First child
  my $grandParent = $parent->parent;                                            # Grandparent
  $grandParent or confess "Cannot invertFirst the outer most node";             # Cannot invert root
  my $i = $parent->index;                                                       # Position of parent in grandparent
  $parent->cut;                                                                 # Cut out parent
  $child->cut;                                                                  # Cut out child
  $child->putLast($parent);                                                     # Put parent last under child
  $grandParent->content->[$i] = $child;                                         # Put child in position in grandparent
  $_->indexNode for $child, $parent, $grandParent;                              # Index modified nodes
  $child->parent = $grandParent;                                                # Grand parent
  $parent                                                                       # Return parent
 }

sub invertLast($@)                                                              #C Swap a parent and child node where the child is the last child of the parent by placing the parent first in the child. Return the parent.
 {my ($parent, @context) = @_;                                                  # Parent, context
  return undef if @context and !$parent->at(@context);                          # Not in specified context
  return undef unless my $child = $parent->last;                                # Last child
  my $grandParent = $parent->parent;                                            # Grandparent
  $grandParent or confess "Cannot invertLast the outer most node";              # Cannot invert root
  my $i = $parent->index;                                                       # Position of parent in grandparent
  $parent->cut;                                                                 # Cut out parent
  $child->cut;                                                                  # Cut out child
  $child->putFirst($parent);                                                    # Put parent last under child
  $grandParent->content->[$i] = $child;                                         # Put child in position in grandparent
  $child->parent = $grandParent;                                                # Grand parent
  $_->indexNode for $child, $parent, $grandParent;                              # Index modified nodes
  $parent                                                                       # Return parent
 }

sub swap($$@)                                                                   #CY Swap two nodes optionally checking that the first node is in the specified context and return the first node.
 {my ($first, $second, @context) = @_;                                          # First node, second node, optional context
  return undef if @context and !$first->at(@context);                           # First node not in specified context
  confess "First node is above second node" if $first->above($second);          # Check that the first node is not above the second node otherwise the result of the swap would not be a tree
  confess "First node is below second node" if $first->below($second);          # Check that the first node is not above the second node otherwise the result of the swap would not be a tree
  return $first if $first == $second;                                           # Do nothing if the first node is the second node
  my $f = $first ->wrapWith(q(temp));                                           # Wrap first node for transfer
  my $s = $second->wrapWith(q(temp));                                           # Wrap second node for transfer
  $f->putLast($second->cut);                                                    # Transfer second node
  $s->putLast($first ->cut);                                                    # Transfer first node
  $_->unwrap for $f, $s;                                                        # Remove wrapping
  $first                                                                        # Return first node
 }

#D2 Wrap and unwrap                                                             # Wrap and unwrap nodes to alter the depth of the L<parse|/parse> tree

sub wrapWith($$@)                                                               #I Wrap the specified B<$node> in a new node created from the specified B<$tag> and B<%attributes> forcing the specified B<$node> down - deepening the L<parse|/parse> tree - return the new wrapping node. See L<addWrapWith|/addWrapWith> to perform this operation conditionally.
 {my ($node, $tag, %attributes) = @_;                                           # Node, tag for the new node or tag, attributes for the new node or tag.
  my $new = newTag(undef, $tag, %attributes);                                   # Create wrapping node
  $new->parser = $node->parser;                                                 # Assign the new node to the old parser
  if (my $par  = $node->parent)                                                 # Parent node exists
   {my $c = $par->content;                                                      # Content array of parent
    my $i = $node->position;                                                    # Position in content array
    splice(@$c, $i, 1, $new);                                                   # Replace node
    $node->parent =  $new;                                                      # Set parent of original node as wrapping node
    $new->parent  =  $par;                                                      # Set parent of wrapping node
    $new->content = [$node];                                                    # Create content for wrapping node
    $par->indexNode;                                                            # Rebuild indices for parent
   }
  else                                                                          # At  the top - no parent
   {$new->content = [$node];                                                    # Create content for wrapping node
    $node->parent =  $new;                                                      # Set parent of original node as wrapping node
    $new->parent  = undef;                                                      # Set parent of wrapping node - there is none
   }
  $new->indexNode;                                                              # Create index for wrapping node
  $new                                                                          # Return wrapping node
 }

sub wrapUp($@)                                                                  # Wrap the specified B<$node> in a sequence of new nodes created from the specified B<@tags> forcing the original node down - deepening the L<parse|/parse> tree - return the array of wrapping nodes.
 {my ($node, @tags) = @_;                                                       # Node to wrap, tags to wrap the node with - with the uppermost tag rightmost.
  map {$node = $node->wrapWith($_)} @tags;                                      # Wrap up
 }

sub wrapDown($@)                                                                # Wrap the content of the specified B<$node> in a sequence of new nodes forcing the original node up - deepening the L<parse|/parse> tree - return the array of wrapping nodes.
 {my ($node, @tags) = @_;                                                       # Node to wrap, tags to wrap the node with - with the uppermost tag rightmost.
  map {$node = $node->wrapContentWith($_)} @tags;                               # Wrap up
 }

sub wrapContentWith($$@)                                                        # Wrap the content of the specified B<$node> in a new node created from the specified <@tag> and B<%attributes>: the specified B<$node> then contains just the new node which, in turn, contains all the content of the specified B<$node>.\mReturns the new wrapped node.
 {my ($old, $tag, %attributes) = @_;                                            # Node, tag for new node, attributes for new node.
  my $new = newTag(undef, $tag, %attributes);                                   # Create wrapping node
  $new->parser  = $old->parser;                                                 # Assign the new node to the old parser
  $new->content = $old->content;                                                # Transfer content
  $old->content = [$new];                                                       # Insert new node
  $new->indexNode;                                                              # Create indices for new node
  $old->indexNode;                                                              # Rebuild indices for old mode
  $new                                                                          # Return new node
 }

sub wrapSiblingsBefore($$@)                                                     # If there are any siblings before the specified B<$node>, wrap them with a new node created from the specified <@tag> and B<%attributes>.\mReturns the specified B<$node>.
 {my ($node, $tag, %attributes) = @_;                                           # Node to wrap before, tag for new node, attributes for new node.
  my $first = $node->firstSibling;                                              # First sibling
  return $node if $node == $first;                                              # We are the first sibling so no wrapping is required
  $first->wrapTo($node->prev, $tag, %attributes);                               # Wrap the preceding nodes
 }

sub wrapSiblingsBetween($$$@)                                                   # If there are any siblings between the specified B<$node>s, wrap them with a new node created from the specified <@tag> and B<%attributes>. Return the wrapping node else B<undef> if there are no nodes to wrap.
 {my ($first, $last, $tag, %attributes) = @_;                                   # First sibling, last sibling, tag for new node, attributes for new node.
  my $parent = $first->parent;                                                  # Check parentage
     $parent or confess "Cannot wrap between siblings using the root node";
     $parent == $last->parent or confess "Not siblings";

  my ($i, $j) = map {$_->position} my ($f, $l) = ($first, $last);               # Get the node indexes so we can order them
  return $f->next->wrapWith(          $tag, %attributes) if $i == $j - 2;       # One intervening node
  return $l->next->wrapWith(          $tag, %attributes) if $j == $i - 2;
  return $f->next->wrapTo  ($l->prev, $tag, %attributes) if $i <  $j - 2;       # Several intervening nodes
  return $l->next->wrapTo  ($f->prev, $tag, %attributes) if $j <  $i - 2;
  undef                                                                         # No intervening nodes
 }

sub wrapSiblingsAfter($$@)                                                      # If there are any siblings after the specified B<$node>, wrap them with a new node created from the specified <@tag> and B<%attributes>.\mReturn the specified B<$node>.
 {my ($node, $tag, %attributes) = @_;                                           # Node to wrap before, tag for new node, attributes for new node.
  my $last = $node->lastSibling;                                                # Last sibling
  return $node if $node == $last;                                               # We are the last sibling so no wrapping is required
  $node->next->wrapTo($last, $tag, %attributes);                                # Wrap the following nodes
 }

sub wrapTo($$$@)                                                                #Y Wrap all the nodes from the B<$start> node to the B<$end> node with a new node created from the specified <@tag> and B<%attributes> and return the new node.\mReturn B<undef> if the B<$start> and B<$end> nodes are not siblings - they must have the same parent for this method to work.
 {my ($start, $end, $tag, %attributes) = @_;                                    # Start node, end node, tag for the wrapping node, attributes for the wrapping node
  my $parent = $start->parent;                                                  # Parent
  confess "Start node has no parent" unless $parent;                            # Not possible unless the start node has a parent
  confess "End node has a different parent" unless $parent == $end->parent;     # Not possible unless the start and end nodes have the same parent
  my $s = $start->position;                                                     # Start position
  my $e = $end->position;                                                       # End position
  confess "End node precedes start node" if $e < $s;                            # End must not precede start node
  $start->putPrev(my $new = $start->newTag($tag, %attributes));                 # Create and insert wrapping node
  my @c = $parent->contents;                                                    # Content of parent
  $_ <  @c ? $new->putLast($c[$_]->cut) : undef for $s+1..$e+1;                 # Move the nodes from start to end into the new node remembering that the new node has already been inserted
  $new                                                                          # Return new node
 }

sub wrapFrom($$$%)                                                              #Y Wrap all the nodes from the B<$start> node to the B<$end> node with a new node created from the specified <@tag> and B<%attributes> and return the new node.  Return B<undef> if the B<$start> and B<$end> nodes are not siblings - they must have the same parent for this method to work.
 {my ($end, $start, $tag, %attributes) = @_;                                    # End node, start node, tag for the wrapping node, attributes for the wrapping node
  $start->wrapTo($end, $tag, %attributes);                                      # Invert and wrapTo
 }

sub unwrap($@)                                                                  #CIY Unwrap the specified B<$node> by inserting its content into its parent at the point containing the specified B<$node> and return the parent node.
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

sub unwrapParentsWithSingleChild($)                                             #CY Unwrap any immediate ancestors of the specified B<$node> which have only a single child and return the specified B<$node> regardless.
 {my ($o) = @_;                                                                 # Node
  my @p;                                                                        # Parents with single child
  for(my $p = $o->parent; $p; $p = $p->parent)                                  # Check each parent
   {$o->isOnlyChild and $p->parent ? push @p, $p : last                         # Locate parents with single child
   }
  -W $_ for @p;                                                                 # Unwrap parents with single child
  $o                                                                            # Return node
 }

sub unwrapContentsKeepingText($@)                                               #CY Unwrap all the non text nodes below the specified B<$node> adding a leading and a trailing space to prevent unwrapped content from being elided and return the specified B<$node> else B<undef> if not in the optional context.
 {my ($node, @context) = @_;                                                    # Node to unwrap, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->by(sub
   {if ($_->isText or $_ == $node) {}                                           # Keep interior text nodes
    else                                                                        # Unwrap interior node
     {$_->putPrevAsText(" ");                                                   # Separate from preceding content
      $_->putNextAsText(" ");                                                   # Separate from following content
      $node->addLabels($_->id) if $_->id;                                       # Transfer any id as a label to the specified B<$node>
      $_->copyLabels($node);                                                    # Transfer any labels to the specified node
      $_->unwrap;                                                               # Unwrap non text tag
     }
   });
  $node                                                                         # Return the node to show success
 }

#D1 Contents                                                                    # The children of each node.

sub contents($@)                                                                #K Return a list of all the nodes contained by the specified B<$node> or an empty list if the node is empty or not in the optional context.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return () if @context and !$node->at(@context);                               # Optionally check the context
  my $c = $node->content;                                                       # Contents reference
  $c ? @$c : ()                                                                 # Contents as a list
 }

sub contentAfter($@)                                                            #K Return a list of all the sibling nodes following the specified B<$node> or an empty list if the specified B<$node> is last or not in the optional context.
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

sub contentBefore($@)                                                           #K Return a list of all the sibling nodes preceding the specified B<$node> or an empty list if the specified B<$node> is last or not in the optional context.
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

sub contentAsTags($@)                                                           #KY Return a string containing the tags of all the child nodes of the specified B<$node> separated by single spaces or the empty string if the node is empty or B<undef> if the node does not match the optional context. Use L<over|/over> to test the sequence of tags with a regular expression.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join ' ', map {$_->tag} $node->contents
 }

sub contentAsTags2($@)                                                          #KY Return a string containing the tags of all the child nodes of the specified B<$node> separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or B<undef> if the node does not match the optional context. Use L<over2|/over2> to test the sequence of tags with a regular expression. Use L<over2|/over2> to test the sequence of tags with a regular expression.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join '', map {' '.$_->tag.' '} $node->contents
 }

sub contentAfterAsTags($@)                                                      #K Return a string containing the tags of all the sibling nodes following the specified B<$node> separated by single spaces or the empty string if the node is empty or B<undef> if the node does not match the optional context. Use L<matchAfter|/matchAfter> to test the sequence of tags with a regular expression.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join ' ', map {$_->tag} $node->contentAfter
 }

sub contentAfterAsTags2($@)                                                     #K Return a string containing the tags of all the sibling nodes following the specified B<$node> separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or B<undef> if the node does not match the optional context. Use L<matchAfter2|/matchAfter2> to test the sequence of tags with a regular expression.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join '', map {' '.$_->tag.' '} $node->contentAfter
 }

sub contentBeforeAsTags($@)                                                     #K Return a string containing the tags of all the sibling nodes preceding the specified B<$node> separated by single spaces or the empty string if the node is empty or B<undef> if the node does not match the optional context. Use L<matchBefore|/matchBefore> to test the sequence of tags with a regular expression.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join ' ', map {$_->tag} $node->contentBefore
 }

sub contentBeforeAsTags2($@)                                                    #K Return a string containing the tags of all the sibling nodes preceding the specified B<$node> separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or B<undef> if the node does not match the optional context.  Use L<matchBefore2|/matchBefore2> to test the sequence of tags with a regular expression.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join '', map {' '.$_->tag.' '} $node->contentBefore
 }

sub position($)                                                                 # Return the index of the specified B<$node> in the content of the parent of the B<$node>.
 {my ($node) = @_;                                                              # Node.
  my @c = $node->parent->contents;                                              # Each node in parent content
  for(keys @c)                                                                  # Test each node
   {return $_ if $c[$_] == $node;                                               # Return index position of node which counts from zero
   }
  confess "Node not found in parent";                                           # Something wrong with parent/child relationship
 }

sub index($)                                                                    # Return the index of the specified B<$node> in its parent index. Use L<position|/position> to find the position of a node under its parent.
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

sub isText($@)                                                                  #CY Return the specified B<$node> if the specified B<$node> is a text node, optionally in the specified context, else return B<undef>.
 {my ($node, @context) = @_;                                                    # Node to test, optional context
  if (@context)                                                                 # Optionally check context
   {my $p = $node->parent;                                                      # Parent
    return undef if !$p or !$p->at(@context);                                   # Parent must match context
   }
  $node->tag eq cdata ? $node : undef
 }

sub isFirstText($@)                                                             #CY Return the specified B<$node> if the specified B<$node> is a text node, the first node under its parent and that the parent is optionally in the specified context, else return B<undef>.
 {my ($node, @context) = @_;                                                    # Node to test, optional context for parent
  return undef unless $node->isText(@context) and $node->isFirst;               # Check that this node is a text node, that it is first, and, optionally check context of parent
  $node                                                                         # Return the node as it passes all tests
 }

sub isLastText($@)                                                              #CY Return the specified B<$node> if the specified B<$node> is a text node, the last node under its parent and that the parent is optionally in the specified context, else return B<undef>.
 {my ($node, @context) = @_;                                                    # Node to test, optional context for parent
  return undef unless $node->isText(@context) and $node->isLast;                # Check that this node is a text node, that it is last, and, optionally check context of parent
  $node                                                                         # Return the node as it passes all tests
 }

sub matchTree($@)                                                               #C Return a list of nodes that match the specified tree of match expressions, else B<()> if one or more match expressions fail to match nodes in the tree below the specified start node. A match expression consists of [parent node tag, [match expressions to be matched by children of parent]|tags of child nodes to match starting at the first node]. Match expressions for a single item do need to be surrounded with [] and can be merged into their predecessor. The outermost match expression should not be enclosed in [].
 {my ($node, @match) = @_;                                                      # Node to start matching from, tree of match expressions.
  my ($tag, @S) = @match;                                                       # Tag we must match, sub tag specifications
  my @nodes;                                                                    # Matching nodes
  return () unless atPositionMatch(-t $node, $tag);                             # Match tag of node
  push @nodes, $node;                                                           # The current node matches so save it
  if (my @s = map{ref($_) ? $_ : [$_]} @S)                                      # Wrap sub tags that are not references with [] so that the caller does not have to because it is a bit tedious wrapping each word in quotes and [] brackets.
   {my @c = $node->contents;                                                    # Contents of node
    return () unless @s <= @c;                                                  # Confirm that there is a node to match against for each match expression
    for my $c(@c)                                                               # Confirm each sub tag matches its sub tag expression
     {push @nodes, my @m = $c->matchTree(@{shift @s});                          # Save sub match
      return () unless @m;                                                      # No sub match so return an empty list
     }
   }
  @nodes                                                                        # The nodes that matched each match expression
 }

sub matchesText($$@)                                                            #C Returns an array of regular expression matches in the text of the specified B<$node> if it is text node and it matches the specified regular expression and optionally has the specified context otherwise returns an empty array.
 {my ($node, $re, @context) = @_;                                               # Node to test, regular expression, optional context
  return () unless $node->isText(@context);                                     # Check that this is a text node
  $node->text =~ m($re);                                                        # Return array of matches - do not add 'g' as a modifier to the regular expression as the pos() feature of Perl regular expressions will then cause matches to fail that otherwise would not.
 }

sub isBlankText($@)                                                             #CY Return the specified B<$node> if the specified B<$node> is a text node, optionally in the specified context, and contains nothing other than white space else return B<undef>. See also: L<isAllBlankText|/isAllBlankText>
 {my ($node, @context) = @_;                                                    # Node to test, optional context
  return undef if @context and !$node->at(@context);                            # Optionally check context
  $node->isText && $node->text =~ /\A\s*\Z/s ? $node : undef
 }

sub isAllBlankText($@)                                                          #CY Return the specified B<$node> if the specified B<$node>, optionally in the specified context, does not contain anything or if it does contain something it is all white space else return B<undef>. See also: L<bitsNodeTextBlank|/bitsNodeTextBlank>
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

#D1 Number                                                                      # Number the nodes of a parse tree so that they can be easily retrieved by number - either by a person reading the source xml or programmatically.

sub findByNumber($$)                                                            #Y Find the node with the specified number as made visible by L<prettyStringNumbered|/prettyStringNumbered> in the L<parse|/parse> tree containing the specified B<$node> and return the found node or B<undef> if no such node exists.
 {my ($node, $number) = @_;                                                     # Node in the parse tree to search, number of the node required.
  $node->parser->numbers->[$number]
 }

sub findByNumbers($@)                                                           # Find the nodes with the specified numbers as made visible by L<prettyStringNumbered|/prettyStringNumbered> in the L<parse|/parse> tree containing the specified B<$node> and return the found nodes in a list with B<undef> for nodes that do not exist.
 {my ($node, @numbers) = @_;                                                    # Node in the parse tree to search, numbers of the nodes required.
  map {$node->findByNumber($_)} @numbers                                        # Node corresponding to each number
 }

sub numberNode($)                                                               #P Ensure that the specified B<$node> has a number.
 {my ($node) = @_;                                                              # Node
  my $n = $node->number = ++($node->parser->numbering);                         # Number node
  $node->parser->numbers->[$n] = $node                                          # Index the nodes in a parse tree
 }

sub numberTree($)                                                               # Number the nodes in a L<parse|/parse> tree in pre-order so they are numbered in the same sequence that they appear in the source. You can see the numbers by printing the tree with L<prettyStringNumbered|/prettyStringNumbered>.  Nodes can be found using L<findByNumber|/findByNumber>.  This method differs from L<forestNumberTrees|/forestNumberTrees> in that avoids overwriting the B<id=> attribute of each node by using a system attribute instead; this system attribute can then be made visible on the id attribute of each node by printing the parse tree with L<prettyStringNumbered|/prettyStringNumbered>.
 {my ($node) = @_;                                                              # Node
  my $parser = $node->parser;                                                   # Top of tree
  my $n = 0;                                                                    # Node number
  $parser->down(sub {$parser->numbers->[$_->number = ++$n] = $_});              # Number the nodes in a parse tree in pre-order so they are numbered in the same sequence that they appear in the source
 }

sub indexIds($)                                                                 # Return a map of the ids at and below the specified B<$node>.
 {my ($node) = @_;                                                              # Node
  my %ids;                                                                      # Id map
  $node->by(sub                                                                 # Map the nodes
   {if (my $id = $_->id)                                                        # Ignore text nodes and nodes that already have an id
     {$ids{$id} and confess "Duplicate id $id";                                 # Confess to duplicate id under the specified node
      $ids{$id} = $_;                                                           # Index node by id
     }
   });
  \%ids                                                                         # Return the index
 }

sub numberTreesJustIds($$)                                                      # Number the ids of the nodes in a L<parse|/parse> tree in pre-order so they are numbered in the same sequence that they appear in the source. You can see the numbers by printing the tree with L<prettyStringNumbered()|/prettyStringNumbered>. This method differs from L<numberTree|/numberTree> in that only non text nodes without ids are numbered. The number applied to each node consists of the concatenation of the specified prefix, an underscore and a number that is unique within the specifed L<parse|/parse> tree. Consequently the ids across several trees trees can be made unique by supplying different prefixes for each tree.  Nodes can be found using L<findByNumber|/findByNumber>.  Returns the specified B<$node>.
 {my ($node, $prefix) = @_;                                                     # Node, prefix for each id at and under the specified B<$node>
  my $parser = $node->parser;                                                   # Root node
  defined($prefix) or confess "prefix required";                                # Typically the prefix separates parallel processes and so it is a good idea to have one
  my $n = 0;                                                                    # Node number
  $node->down(sub                                                               # Number the nodes in the parse tree in pre-order so they are numbered in the same sequence that they appear in the source
   {if (!$_->isText and !$_->id)                                                # Ignore text nodes and nodes that already have an id
     {$_->id = $prefix.q(_).++$n;                                               # Set id
     }
   });
  $node                                                                         # Return the specified node
 }

#D1 Forest Numbers                                                              # Number the nodes of several parse trees so that they can be easily retrieved by forest number - either by a person reading the source xml or programmatically.

sub forestNumberTrees($$)                                                       # Number the ids of the nodes in a L<parse|/parse> tree in pre-order so they are numbered in the same sequence that they appear in the source. You can see the numbers by printing the tree with L<prettyString|/prettyString>. This method differs from L<numberTree|/numberTree> in that only non text nodes are numbered and nodes with existing B<id=> attributes have the value of their B<id=> attribute transferred to a L<label|/Labels>. The number applied to each node consists of the concatenation of the specified tree number, an underscore and a number that is unique within the specified L<parse|/parse> tree. Consequently the ids across several trees can be made unique by supplying a different tree number for each tree.  Nodes can be found subsequently using L<findByForestNumber|/findByForestNumber>.  Returns the specified B<$node>.
 {my ($node, $prefix) = @_;                                                     # Node in parse tree to be numbered, tree number
  my $parser = $node->parser;                                                   # Root node
  defined($prefix) or confess "prefix required";                                # Typically the prefix separates parallel processes and so it is a good idea to have one
  $prefix =~ m(\A\d+\Z)s or confess "prefix must be an integer \\d+";           # Insist on a numeric prefix
  $parser->down(sub                                                             # Number the nodes in the parse tree in pre-order so they are numbered in the same sequence that they appear in the source
   {if (!$_->isText)                                                            # Number non text nodes
     {$_->addLabels($_->id) if $_->id;                                          # Make any existing id a label
      my $n  = $prefix.q(_).(scalar(keys %{$parser->forestNumbers}) + 1);       # Id number
      $_->id = $n;                                                              # Set id
      $parser->forestNumbers->{$n} = $_;                                        # Index node
     }
   });
  $node                                                                         # Return the specified node
 }

sub findByForestNumber($$$)                                                     # Find the node with the specified L<forest number|/forestNumberTrees> as made visible on the id attribute by L<prettyStringNumbered|/prettyStringNumbered> in the L<parse|/parse> tree containing the specified B<$node> and return the found node or B<undef> if no such node exists.
 {my ($node, $tree, $id) = @_;                                                  # Node in the parse tree to search, forest number, id number of the node required.
  $node->parser->forestNumbers->{$tree.q(_).$id}
 }

#D1 Order                                                                       # Check the order and relative position of nodes in a parse tree.

sub above($$@)                                                                  #CY Return the first node if the first node is above the second node optionally checking that the first node is in the specified context otherwise return B<undef>
 {my ($first, $second, @context) = @_;                                          # First node, second node, optional context
  return undef if @context and !$first->at(@context);                           # Not in specified context
  return undef if $first == $second;                                            # A node cannot be above itself
  my @f = $first ->ancestry;
  my @s = $second->ancestry;
  pop @f, pop @s while @f and @s and $f[-1] == $s[-1];                          # Find first different ancestor
  !@f ? $first : undef                                                          # Node is above target if its ancestors are all ancestors of target
 }

sub abovePath($$)                                                               # Return the nodes along the path from the first node down to the second node when the first node is above the second node else return B<()>.
 {my ($first, $second) = @_;                                                    # First node, second node
  return ($first) if $first == $second;                                         # A node cannot be above itself
  my @f = $first ->ancestry;
  my @s = $second->ancestry;
  pop @f, pop @s while @f and @s and $f[-1] == $s[-1];                          # Find first different ancestor
  !@f ? ($first, reverse @s) : ()                                               # Node is above target if its ancestors are all ancestors of target
 }

sub below($$@)                                                                  #CY Return the first node if the first node is below the second node optionally checking that the first node is in the specified context otherwise return B<undef>
 {my ($first, $second, @context) = @_;                                          # First node, second node, optional context
  $second->above($first, @context);                                             # The second node is above the first node if the first node is below the second node
 }

sub belowPath($$)                                                               # Return the nodes along the path from the first node up to the second node when the first node is below the second node else return B<()>.
 {my ($first, $second) = @_;                                                    # First node, second node
  reverse $second->abovePath($first)
 }

sub after($$@)                                                                  #CY Return the first node if it occurs after the second node in the L<parse|/parse> tree optionally checking that the first node is in the specified context or else B<undef> if the node is L<above|/above>, L<below|/below> or L<before|/before> the target.
 {my ($first, $second, @context) = @_;                                          # First node, second node, optional context
  return undef if @context and !$first->at(@context);                           # First node not in specified context
  my @n = $first ->ancestry;
  my @t = $second->ancestry;
  pop @n, pop @t while @n and @t and $n[-1] == $t[-1];                          # Find first different ancestor
  return undef unless @n and @t;                                                # Undef if we cannot decide
  $n[-1]->position > $t[-1]->position                                           # Node relative to target at first common ancestor
 }

sub before($$@)                                                                 #CY Return the first node if it occurs before the second node in the L<parse|/parse> tree optionally checking that the first node is in the specified context or else B<undef> if the node is L<above|/above>, L<below|/below> or L<before|/before> the target.
 {my ($first, $second, @context) = @_;                                          # First node, second node, optional context
  $second->after($first, @context);                                             # The first node is before the second node if the second node is after the first node
 }

sub disordered($@)                                                              # Return the first node that is out of the specified order when performing a pre-ordered traversal of the L<parse|/parse> tree.
 {my ($node, @nodes) = @_;                                                      # Node, following nodes.
  my $c = $node;                                                                # Node we are currently checking for
  $node->parser->down(sub {$c = shift @nodes while $c and $_ == $c});           # Preorder traversal from root looking for each specified node
  $c                                                                            # Disordered if we could not find this node
 }

sub commonAncestor($@)                                                          #Y Find the most recent common ancestor of the specified nodes or B<undef> if there is no common ancestor.
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

sub commonAdjacentAncestors($$)                                                 # Given two nodes, find a pair of adjacent ancestral siblings if such a pair exists else return B<()>.
 {my ($first, $second) = @_;                                                    # First node, second node
  my @f = $first->ancestry;                                                     # Ancestors of the first node
  my @s = $second->ancestry;                                                    # Ancestors of the second node
  while(@f and @s and $f[-1] == $s[-1])                                         # Remove common ancestors
   {pop @f; pop @s;
   }
  return () unless @f and @s;                                                   # No common ancestors
  my ($f, $s) = ($f[-1], $s[-1]);                                               # Possible common pair of ancestral siblings
  return ($f, $s) if $f->adjacent($s);                                          # Return first diverging siblings if they exist
  ()                                                                            # No such pair exists
 }

sub ordered($@)                                                                 #Y Return the first node if the specified nodes are all in order when performing a pre-ordered traversal of the L<parse|/parse> tree else return B<undef>.
 {my ($node, @nodes) = @_;                                                      # Node, following nodes.
  &disordered(@_) ? undef : $node
 }

#D1 Patching                                                                    # Analyze two similar L<parse|/parse> trees and create a patch that transforms the first L<parse|/parse> tree into the second as long as each tree has the same tag and id structure with each id being unique.

sub createPatch($$)                                                             # Create a patch that moves the source L<parse|/parse> tree to the target L<parse|/parse> tree node as long as they have the same tag and id structure with each id being unique.
 {my ($a, $A) = @_;                                                             # Source parse tree, target parse tree
  my @patches;
  my $I = $A->indexIds;
  $a->by(sub
   {my ($o) = @_;
    return unless my $id = $o->id;
    if (my $O = $I->{$id})
     {for my $a($o->getAttrs)
       {my ($v, $V)= ($o->attr($a), $O->attr($a));                              # Values
        if (defined($V) and $v ne $V)
         {push @patches, [q(changeValue), $id, $a, $v, $V]                      # Set attribute
         }
        elsif (!defined($V))
         {push @patches, [q(deleteAttr), $id, $a, $v]                           # Set attribute
         }
       }
      for my $A($O->getAttrs)
       {next if $o->attr($A);
        push @patches, [q(createAttr), $id, $A, $O->attr($A)];                  # Set attribute
       }

      if (my $f = $o->first)                                                    # First following text
       {if ($f->isText)
         {if (my $F = $O->first)
           {if ($F->isText)
             {if ($f->text ne $F->text)
               {push @patches, [q(firstText), $id, $f->text, $F->text];
               }
             }
            else
             {confess "Text expected first after node $id:\n".$f->text;
             }
           }
          else
           {confess "Node expected first after node $id:\n".$f->text;
           }
         }
       }

      if (my $n = $o->next)                                                     # Following text
       {if ($n->isText)
         {if (my $N = $O->next)
           {if ($N->isText)
             {if ($n->text ne $N->text)
               {push @patches, [q(nextText), $id, $n->text, $N->text];
               }
             }
            else
             {confess "Text expected after node $id:\n".$n->text;
             }
           }
          else
           {confess "Node expected after node $id:\n".$n->text;
           }
         }
       }

      if (my $p = $o->prev)                                                     # Preceding text
       {if ($p->isText)
         {if (my $P = $O->prev)
           {if ($P->isText)
             {if ($p->text ne $P->text)
               {push @patches, [q(prevText), $id, $p->text, $P->text];
               }
             }
            else
             {confess "Text expected before node $id:\n".$p->text;
             }
           }
          else
           {confess "Node expected before node $id:\n".$p->text;
           }
         }
       }

      if (my $l = $o->last)                                                     # Last preceding text
       {if ($l->isText)
         {if (my $L = $O->last)
           {if ($L->isText)
             {if ($l->text ne $L->text)
               {push @patches, [q(lastText), $id, $l->text, $L->text];
               }
             }
            else
             {confess "Text expected last before node $id:\n".$l->text;
             }
           }
          else
           {confess "Node expected last before node $id:\n".$l->text;
           }
         }
       }
     }
    else
     {confess "No matching id for $id";
     }
   });
  bless [@patches], q(Data::Edit::Xml::Patch);                                  # Return patch
 }

sub Data::Edit::Xml::Patch::install($$)                                         # Replay a patch created by L<createPatch|/createPatch> against a L<parse|/parse> tree that has the same tag and id structure with each id being unique.
 {my ($patches, $a) = @_;                                                       # Patch, parse tree
  my $i = $a->indexIds;
  for my $patch(@$patches)
   {my ($c, $id) = @$patch;
    my $o = $i->{$id} or confess "No node with id $id";
    if ($c eq q(changeValue))
     {my (undef, undef, $a, $v, $V) = @$patch;
      $o->attr($a) eq $v or confess "Expected $a=$v but got $a=".$o->attr($a);
      $o->setAttr($a, $V);
     }
    elsif ($c eq q(deleteAttr))
     {my (undef, undef, $a, $v) = @$patch;
      $o->attr($a) eq $v or confess "Expected $a=$v but got $a=".$o->attr($a);
      $o->deleteAttr($a);
     }
    elsif ($c eq q(createAttr))
     {my (undef, undef, $a, $v) = @$patch;
      $o->setAttr($a, $v);
     }
    else
     {my (undef, undef, $t, $T) = @$patch;
      my $update = sub
       {my ($o, $pos) = @_;
        $o                   or confess      "Node expected $pos node $id";
        my $s = $o->text;
        $s                   or confess "Text node expected $pos node $id";
        $s eq $t or $s eq $T or confess      "Text expected $pos node $id should be:\n$s";
        $o->text = $T unless $s eq $T;
       };
      if    ($c eq q(firstText)) {$update->($o->first, q(first after))}
      elsif ($c eq q(nextText))  {$update->($o->next,  q(after))}
      elsif ($c eq q(prevText))  {$update->($o->prev,  q(before))}
      elsif ($c eq q(lastText))  {$update->($o->last,  q(last before))}
      else                       {confess "Unknown command $c"}
     }
   }
 }

#D1 Propogating                                                                 # Propagate parent node attributes through a parse tree.

sub propagate($$@)                                                              #C Propagate L<new attributes|/copyNewAttrs> from nodes that match the specified tag to all their child nodes, then L<unwrap|/unwrap> all the nodes that match the specified tag. Return the specified parse tree.
 {my ($tree, $tag, @context) = @_;                                              # Parse tree, tag of nodes whose attributes are to be propagated, optional context for parse tree
  return undef if @context and !$tree->at(@context);                            # Not in specified context
  $tree->by(sub                                                                 # Copy new attributes from each matching parent for each node in the parse tree
   {my ($node, @parents) = @_;                                                  # Node, parents
    for my $parent(@parents)                                                    # For each parent of the node being visited
     {$parent->copyNewAttrs($node) if -t $parent eq $tag;                       # Copy the new attributes of a parent with the specified tag
     }
   });
  $tree->by(sub                                                                 # Unwrap nodes with the specified tag unless they are the starting node
   {my ($node) = @_;                                                            # Node
    $node->unwrap if $node != $tree and -t $node eq $tag;                       # Unwrap the node if it matches the specified tag
   });
  $tree                                                                         # Return the parse tree
 }

#D1 Table of Contents                                                           # Analyze and generate tables of contents.

sub tocNumbers($@)                                                              # Table of Contents number the nodes in a L<parse|/parse> tree.
 {my ($node, @match) = @_;                                                      # Node, optional list of tags to descend into else all tags will be descended into
  my $toc = {};
  my $match = @match ? {map{$_=>1} @match} : undef;                             # Tags to match or none
  my @context;

  my $tree; $tree = sub                                                         # Number the nodes below the current node
   {my ($node) = @_;
    my $n = 0;
    for($node->contents)                                                        # Each node below the current node
     {next if $match and !$match->{$_->tag};                                    # Skip non matching nodes
      push @context, ++$n;                                                      # New scope
      $toc->{"@context"} = $_;                                                  # Toc number for tag
      &$tree($_);                                                               # Number sub tree
      pop @context;                                                             # End scope
     }
   };

  &$tree($node);                                                                # Descend through the tree numbering matching nodes
  $toc                                                                          # Return {toc number} = <tag>
 }

#D1 Labels                                                                      # Label nodes so that they can be cross referenced and linked by L<Data::Edit::Xml::Lint>

sub addLabels($@)                                                               # Add the named labels to the specified B<$node> and return the number of labels added. Labels that are not L<defined|https://perldoc.perl.org/functions/defined.html> will be ignored.
 {my ($node, @labels) = @_;                                                     # Node in parse tree, names of labels to add.
  my $l = $node->labels;                                                        # Labels on node
  my $n = keys %$l;                                                             # Count the number of labels at the start
  $l->{$_}++ for grep {$_} @labels;                                             # Labels must be defined to be added
  keys(%$l) - $n                                                                # Number of labels added
 }

sub countLabels($)                                                              # Return the count of the number of labels at a node.
 {my ($node) = @_;                                                              # Node in parse tree.
  scalar keys %{$node->labels}                                                  # Count of labels
 }

sub labelsInTree($)                                                             # Return a hash of all the labels in a tree
 {my ($tree) = @_;                                                              # Parse tree.
  my %labels;                                                                   # Labels found
  $tree->by(sub                                                                 # Labels for each node in the parse tree
   {for($_->getLabels)                                                          # Each label
     {$labels{$_}++
     }
   });
  \%labels                                                                      # Hash of labels in the tree
 }

sub getLabels($)                                                                # Return the names of all the labels set on a node.
 {my ($node) = @_;                                                              # Node in parse tree.
  sort keys %{$node->labels}
 }

sub deleteLabels($@)                                                            # Delete the specified labels in the specified B<$node> or all labels if no labels have are specified and return that node.
 {my ($node, @labels) = @_;                                                     # Node in parse tree, names of the labels to be deleted
  my $n = keys %{$node->{labels}};                                              # Number of labels at start
  $node->{labels} = {} unless @labels;                                          # Delete all the labels if no labels supplied
  delete @{$node->{labels}}{@labels};                                           # Delete specified labels
  $n - keys %{$node->{labels}}                                                  # Number of labels deleted
 }

sub copyLabels($$)                                                              # Copy all the labels from the source node to the target node and return the source node.
 {my ($source, $target) = @_;                                                   # Source node, target node.
  $target->addLabels($source->getLabels);                                       # Copy all the labels from the source to the target
 }

sub moveLabels($$)                                                              # Move all the labels from the source node to the target node and return the source node.
 {my ($source, $target) = @_;                                                   # Source node, target node.
  $target->addLabels($source->getLabels);                                       # Copy all the labels from the source to the target
  $source->deleteLabels;                                                        # Delete all the labels from the source
 }

sub copyLabelsAndIdsInTree($$)                                                  # Copy all the labels and ids in the source parse tree to the matching nodes in the target parse tree. Nodes are matched via L<path|/path>. Return the number of labels and ids copied.
 {my ($source, $target) = @_;                                                   # Source node, target node.
  my $n = 0;                                                                    # Count modifications
  $target->by(sub                                                               # Scan the target
   {my ($o) = @_;
    my @p = $o->path;                                                           # Matching node in source
    if (my $q = $source->go(@p))
     {$n += $q->copyLabels($o) + $o->addLabels($q->id);                         # Copy labels and id from source to target
     }
   });
  $n                                                                            # Number of labels added
 }

#D1 Operators                                                                   # Operator access to methods use the assign versions to avoid 'useless use of operator in void context' messages. Use the non assign versions to return the results of the underlying method call.  Thus '/' returns the wrapping node, whilst '/=' does not.  Assign operators always return their left hand side even though the corresponding method usually returns the modification on the right.

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
  '*'        => \&opWrapContentWith,                                            # doc
  '*='       => \&opWrapContentWith,
  '/'        => \&opWrapWith,
  '/='       => \&opWrapWith,
  '%'        => \&opAttr,
  '--'       => \&opCut,                                                        # Better using -X
  '++'       => \&opUnwrap,                                                     # doc # Better using -W
  "fallback" => 1;

sub opString($$)                                                                # -B: L<bitsNodeTextBlank|/bitsNodeTextBlank>\m-b: L<isAllBlankText|/isAllBlankText>\m-c: L<context|/context>\m-e: L<prettyStringEnd|/prettyStringEnd>\m-f: L<first node|/first>\m-g: L<pathString|/pathString>\m-l: L<last node|/last>\m-M: L<number|/number>\m-o: L<contentAsTags|/contentAsTags>\m-p: L<prettyString|/prettyString>\m-s: L<string|/string>\m-S : L<stringNode|/stringNode>\m-T : L<isText|/isText>\m-t : L<tag|/tag>\m-u: L<id|/id>\m-W: L<unWrap|/unWrap>\m-w: L<stringQuoted|/stringQuoted>\m-x: L<prettyStringDitaHeaders|/prettyStringDitaHeaders>\m-X: L<cut|/cut>\m-z: L<prettyStringNumbered|/prettyStringNumbered>.
 {my ($node, $op) = @_;                                                         # Node, monadic operator.
  $op or confess;
  return $node->printNode                    if $op eq 'A';
  return $node->bitsNodeTextBlank            if $op eq 'B';
  return $node->isAllBlankText               if $op eq 'b';
  return $node->context                      if $op eq 'c';
 #return $node->CCCC                         if $op eq 'C';
 #return $node->dddd                         if $op eq 'd';
  return $node->prettyStringEnd              if $op eq 'e';
  return $node->first                        if $op eq 'f';  # Not much use
  return $node->pathString                   if $op eq 'g';
 #return $node->kkkk                         if $op eq 'k';
  return $node->last                         if $op eq 'l';  # Not much use
  return $node->number                       if $op eq 'M';
  return $node->contentAsTags2               if $op eq 'O';
  return $node->contentAsTags                if $op eq 'o';
  return $node->prettyString                 if $op eq 'p';
  return $node->requiredCleanUp              if $op eq 'R';
 #return $node->rrrr                         if $op eq 'r';
  return $node->stringNode                   if $op eq 'S';
  return $node->string                       if $op eq 's';
  return $node->isText                       if $op eq 'T';
  return $node->tag                          if $op eq 't';
  return $node->id                           if $op eq 'u';
  return $node->unwrap                       if $op eq 'W';
  return $node->stringQuoted                 if $op eq 'w';
  return $node->cut                          if $op eq 'X';
  return $node->prettyStringDitaHeaders      if $op eq 'x';
  return $node->prettyStringNumbered         if $op eq 'z';
  confess "Unknown operator: $op";
 }

sub opContents($)                                                               # @{} : nodes immediately below a node.
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

sub opPutNext($$)                                                               # > + : put a node or string after the specified B<$node> and return the new node.
 {my ($node, $text) = @_;                                                       # Node, node or text to place after the first node.
  $node->putNext(my $new = opNew($node, $text));
  $new
 }

sub opPutNextAssign($$)                                                         # += : put a node or string after the specified B<$node>.
 {my ($node, $text) = @_;                                                       # Node, node or text to place after the first node.
  opPutNext($node, $text);
  $node
 }

sub opPutPrev($$)                                                               # < - : put a node or string before the specified B<$node> and return the new node.
 {my ($node, $text) = @_;                                                       # Node, node or text to place before the first node.
  $node->putPrev(my $new = opNew($node, $text));
  $new
 }

sub opPutPrevAssign($$)                                                         # -= : put a node or string before the specified B<$node>,
 {my ($node, $text) = @_;                                                       # Node, node or text to place before the first node.
  opPutPrev($node, $text);
  $node
 }

sub opBy($$)                                                                    # x= : Traverse a L<parse|/parse> tree in post-order.
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

sub opAttr($$)                                                                  # % : Get the value of an attribute of the specified B<$node>.
 {my ($node, $attr) = @_;                                                       # Node, reference to an array of words and numbers specifying the node to search for.
  return map {$node->attr($_)} @$attr if ref($attr);
  $node->attr($attr)
 }

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

#D1 Statistics                                                                  # Statistics describing the L<parse|/parse> tree.

sub count($@)                                                                   # Return the count of the number of instances of the specified tags under the specified B<$node>, either by tag in array context or in total in scalar context.
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
    else                                                                        # In scalar context, with no tags specified, return the number of nodes under the specified B<$node>
     {my @c = $node->contents;
      return scalar(@c);                                                        # Count of all tags including CDATA
     }
   }
  confess "This should not happen"
 }

sub countTags($)                                                                # Count the number of tags in a L<parse|/parse> tree.
 {my ($node) = @_;                                                              # Parse tree.
  my $n = 0;
  $node->by(sub{++$n});                                                         # Count tags including CDATA
  $n                                                                            # Number of tags encountered
 }

sub countTagNames($;$)                                                          # Return a reference to a hash showing the number of instances of each tag on and below the specified B<$node>.
 {my ($node, $count) = @_;                                                      # Node, count of tags so far.
  $count //= {};                                                                # Counts
  $$count{$node->tag}++;                                                        # Add current tag
  $_->countTagNames($count) for $node->contents;                                # Each contained node
  $count                                                                        # Count
 }

sub countAttrNames($$)                                                          # Return a reference to a hash showing the number of instances of each attribute on and below the specified B<$node>.
 {my ($node, $count) = @_;                                                      # Node, attribute count so far
  $count //= {};                                                                # Counts
  $$count{$_}++ for $node->getAttrs;                                            # Attributes from current tag
  $_->countAttrNames($count) for $node->contents;                               # Each contained node
  $count                                                                        # Count
 }

sub countAttrNamesOnTagExcluding($@)                                            # Count the number of attributes owned by the specified B<$node> that are not in the specified list.
 {my ($node, @attr) = @_;                                                       # Node, attributes to ignore
  my %attr = map{$_=>1} @attr;                                                  # Set of attributes to ignore
  my $count;                                                                    # Count
  $count++ for grep {!$attr{$_}} $node->getAttrs;                               # Attributes from current tag
  $count                                                                        # Count
 }

sub countAttrValues($;$)                                                        # Return a reference to a hash showing the number of instances of each attribute value on and below the specified B<$node>.
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

sub changeReasonCommentSelectionSpecification :lvalue                           #S Provide a specification to select L<change reason comments|/crc> to be inserted as text into a L<parse|/parse> tree. A specification can be either:\m=over\m=item the name of a code to be accepted,\m=item a regular expression which matches the codes to be accepted,\m=item a hash whose keys are defined for the codes to be accepted or\m=item B<undef> (the default) to specify that no such comments should be accepted.\m=back
 {CORE::state $r;
  $r
 }

sub crc($$;$)                                                                   # Insert a comment consisting of a code and an optional reason as text into the L<parse|/parse> tree to indicate the location of changes to the L<parse|/parse> tree.  As such comments tend to become very numerous, only comments whose codes matches the specification provided in L<changeReasonCommentSelectionSpecification|/changeReasonCommentSelectionSpecification> are accepted for insertion. Subsequently these comments can be easily located using:\mB<grep -nr "<!-->I<code>B<">\mon the file containing a printed version of the L<parse|/parse> tree. Please note that these comments will be removed if the output file is reparsed.\mReturns the specified B<$node>.
 {my ($node, $code, $reason) = @_;                                              # Node being changed, reason code, optional text description of change
  if (sub                                                                       # Whether to make a change entry in the L<parse|/parse> tree
   {my $s = changeReasonCommentSelectionSpecification;                          # Change selection specification
    return undef unless $s;                                                     # Do not record change reasons unless a change selection has been supplied
    my $r = ref $s;                                                             # Change selection has been supplied
    return 1 if $r and $r =~ m(Regexp) and $code =~ m($s);                      # Requested change matches the supplied regular expression
    return 1 if $r and $r =~ m(HASH)   and $s->{$code};                         # Requested change is a key in the supplied hash
    return 1 if $s and $s eq $code;                                             # Requested change equal to the supplied name
    undef                                                                       # No match so do not crate a change entry in the L<parse|/parse> tree
   }->())
   {my $message = $reason ? "<!--$code - $reason -->" : "<!--$code-->";         # Insert message either eliding it with existing text or creating a new text node
    if ($node->isText)                                                          # If we are on a text node we can simply add the comment at the front
     {$node->text = $message.$node->text;
     }
    else
     {my $P = $node->prev;                                                      # At the end of a previous text node?
      if ($P and $P->isText)
       {$P->text = $node->text.$message;
       }
      else
       {my $N = $node->next;                                                    # At the start of a following text node?
        if ($N and $N->isText)
         {$N->text = $message.$node->text;
         }
        elsif ($node->parent)                                                   # Not a text node, no text node on either side, not the root
         {$node->putPrevAsText($message);
         }
        elsif (my $f = $node->first)                                            # Root node but not text
         {if ($f->isText)                                                       # At front of first text node
           {$f->text = $message.$node->text;
           }
          else                                                                  # No first node or first node is not text, place first
           {$node->putFirstAsText($message);
           }
         }
       }
     }
   }
  $node
 }

sub howFirst($)                                                                 # Return the depth to which the specified B<$node> is L<first|/isFirst> else B<0>.
 {my ($node) = @_;                                                              # Node
  my $i = 0;                                                                    # Count first depth
  for(my $p = $node; $p; $p = $p->parent)                                       # Go up
   {last unless $p->isFirst;                                                    # Go up while first
    ++$i;
   }
  $i
 }

sub howLast($)                                                                  # Return the depth to which the specified B<$node> is L<last|/isLast> else B<0>.
 {my ($node) = @_;                                                              # Node
  my $i = 0;                                                                    # Count last depth
  for(my $p = $node; $p; $p = $p->parent)                                       # Go up
   {last unless $p->isLast;                                                     # Go up while last
    ++$i;
   }
  $i
 }

sub howOnlyChild($)                                                             # Return the depth to which the specified B<$node> is an L<only child|/isOnlyChild> else B<0>.
 {my ($node) = @_;                                                              # Node
  my $i = 0;                                                                    # Count only child depth
  for(my $p = $node; $p; $p = $p->parent)                                       # Go up
   {last unless $p->isOnlyChild;                                                # Go up while only child
    ++$i;
   }
  $i
 }

sub howFar($$)                                                                  # Return how far the first node is from the second node along a path through their common ancestor.
 {my ($first, $second) = @_;                                                    # First node, second node
  my $p = $first->commonAncestor($second);                                      # Find their common ancestor
  return 0 if $first == $second;                                                # Same node
  return 1 if $first->adjacent($second);                                        # Adjacent nodes
  $p->howFarAbove($first) + $p->howFarAbove($second) -                          # Sum of the paths to their common ancestor plus any adjustment
    ($first->commonAdjacentAncestors($second) ? 1 : 0);                         # If the nodes share a pair of common ancestral siblings the path is one step shorter
 }

sub howFarAbove($$)                                                             # Return how far the first node is  L<above|/above> the second node is or B<0> if the first node is not strictly L<above|/above> the second node.
 {my ($above, $below) = @_;                                                     # First node above, second node below
  for(my ($i, $p) = (1, $below->parent); $p; $p = $p->parent, ++$i)             # Go up from below to above
   {return $i if $above == $p;                                                  # Return the height if we have reached the node above
   }
  0
 }

sub howFarBelow($$)                                                             # Return how far the first node is  L<below|/below> the second node is or B<0> if the first node is not strictly L<below|/below> the second node.
 {my ($below, $above) = @_;                                                     # First node below, second node above
  $above->howFarAbove($below)                                                   # Use howFarABove with arguments inverted
 }

#D1 Required clean up                                                           # Insert required clean up tags.

sub createRequiredCleanUp($$)                                                   #P Create a required clean up node
 {my ($node, $text) = @_;                                                       # Node, clean up message
  my $r = $node->newTag(q(required-cleanup));                                   # Create required clean up node
  $r->putFirstAsText($text);                                                    # Add text
  $r                                                                            # Return required clean up node
 }

sub requiredCleanUp($;$)                                                        # Replace a node with a required cleanup node around the text of the replaced node with special characters replaced by symbols.\mReturns the specified B<$node>.
 {my ($node, $outputclass) = @_;                                                # Node, optional outputclass attribute of required cleanup tag
  my $text = replaceSpecialChars($node->prettyString);                          # Replace xml chars with symbols
  my $r = $node->createRequiredCleanUp($text);                                  # Create required clean up node
     $r->outputclass = $outputclass if $outputclass;                            # Add outputclass if supplied
  $node->replaceWith($r);                                                       # Replace current node
  $r                                                                            # Return required clean up node
 }

sub replaceWithRequiredCleanUp($$)                                              # Replace a node with a required cleanup message and return the new node
 {my ($node, $text) = @_;                                                       # Node to be replace, clean up message
  my $r = $node->createRequiredCleanUp($text);                                  # Create required clean up node
  $node->replaceWith($r);
  $r
 }

sub putFirstRequiredCleanUp($$)                                                 # Place a required cleanup tag first under a node and return the required clean up node.
 {my ($node, $text) = @_;                                                       # Node, clean up message
  my $r = $node->createRequiredCleanUp($text);                                  # Create required clean up node
  $node->putFirst($r);                                                          # Insert required clean up node
  $r                                                                            # Return required clean up node
 }

sub putLastRequiredCleanUp($$)                                                  # Place a required cleanup tag last under a node and return the required clean up node.
 {my ($node, $text) = @_;                                                       # Node, clean up message
  my $r = $node->createRequiredCleanUp($text);                                  # Create required clean up node
  $node->putLast($r);                                                           # Insert required clean up node
  $r                                                                            # Return required clean up node
 }

sub putNextRequiredCleanUp($$)                                                  # Place a required cleanup tag after a node.
 {my ($node, $text) = @_;                                                       # Node, clean up message
  if ($node->parent)                                                            # Place after non root node
   {my $r = $node->createRequiredCleanUp($text);                                # Create required clean up node
    $node->putNext($r);                                                         # Insert required clean up node
    return $r;                                                                  # Return required clean up node
   }
  else                                                                          # Place last under a root node
   {return $node->putLastRequiredCleanUp($text);
   }
 }

sub putPrevRequiredCleanUp($$)                                                  # Place a required cleanup tag before a node.
 {my ($node, $text) = @_;                                                       # Node, clean up message
  if ($node->parent)                                                            # Place before non root node
   {my $r = $node->createRequiredCleanUp($text);                                # Create required clean up node
    $node->putPrev($r);                                                         # Insert required clean up node
    return $r;                                                                  # Return required clean up node
   }
  else                                                                          # Place first under a root node
   {return $node->putFirstRequiredCleanUp($text);
   }
 }

#D1 Conversions                                                                 # Methods useful for conversions to and from word, L<html|https://www.w3.org/TR/html52/index.html#contents> and L<Dita>.

sub ditaListToSteps($@)                                                         #C Change the specified B<$node> to B<steps> and its contents to B<cmd\step> optionally only in the specified context.
 {my ($list, @context) = @_;                                                    # Node, optional context
  return undef if @context and !$list->at(@context);                            # Not in specified context
  for(@$list)                                                                   # Each li
   {$_->change(qw(  cmd))->wrapWith(q(step));                                   # li -> cmd\step
    $_->unwrap(qw(p cmd)) for @$_;                                              # Unwrap any contained p
   }
  $list->change(q(steps));
 }

sub ditaListToStepsUnordered($@)                                                #C Change the specified B<$node> to B<steps-unordered> and its contents to B<cmd\step> optionally only in the specified context.
 {my ($list, @context) = @_;                                                    # Node, optional context
  my $steps = $list->ditaListToSteps(@context);                                        # Change to steps
  $steps->change(q(steps-unordered)) if $steps;                                 # Change to steps unordered
  $steps
 }

sub ditaListToSubSteps($@)                                                      #C Change the specified B<$node> to B<substeps> and its contents to B<cmd\step> optionally only in the specified context.
 {my ($list, @context) = @_;                                                    # Node, optional context
  return undef if @context and !$list->at(@context);                            # Not in specified context
  for(@$list)                                                                   # Each li
   {$_->change(qw(  cmd))->wrapWith(q(substep));                                # li -> cmd\step
    $_->unwrap(qw(p cmd)) for @$_;                                              # Unwrap any contained p
   }
  $list->change(q(substeps));
 }

sub ditaStepsToList($@)                                                         #C Change the specified B<$node> to B<ol> and its B<cmd\step> content to B<li> optionally only in the specified context.
 {my ($steps, @context) = @_;                                                   # Node, optional context
  return undef if @context and !$steps->at(@context);                           # Not in specified context
  for(@$steps)                                                                  # Content
   {$_->change(q(li));                                                          # Change content to li
    -W $_ for @$_;                                                              # Unwrap cmd
   }
  $steps->change(q(ol));
 }

sub ditaMergeLists($@)                                                          #C Merge the specified B<$node> with the preceding or following list or steps or substeps if possible and return the specified B<$node> regardless.
 {my ($node, @context) = @_;                                                    # Node, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->ditaMergeListsOnce for 1..2                                            # Do the merge twice to pick up all the stragglers
 }

sub ditaMergeListsOnce($)                                                       #P Merge the specified B<$node> with the preceding or following list or steps or substeps if possible and return the specified B<$node> regardless.
 {my ($node) = @_;                                                              # Node
  if ($node->at(qr(\A(ol|ul|steps|substeps)\Z)))                                # Lists
   {if (my $p = $node->prev(-t $node))                                          # Merge two lists or steps or substeps
     {$p->putLast($node->cut);
      $node->unwrap;
     }
    elsif ($node->at(qr(\A(ol|sl|ul))))                                         # List with preceding or following list elements
     {if    (my $p = $node->prev(q(li)))
       {$node->putFirst($p->cut);
       }
      elsif (my $n = $node->next(q(li)))
       {$node->putLast($n->cut);
       }
     }
    elsif ($node->at(q(steps)))                                                 # Steps with preceding or following step
     {if    (my $p = $node->prev(qr(step|stepsection)))
       {$node->putFirst($p->cut);
       }
      elsif (my $n = $node->next(q(step)))
       {$node->putLast($n->cut);
       }
     }
    elsif ($node->at(q(substeps)))                                              # Substeps with preceding or following steps
     {if    (my $p = $node->prev(q(substep)))
       {$node->putFirst($p->cut);
       }
      elsif (my $n = $node->next(q(substep)))
       {$node->putLast($n->cut);
       }
     }
    elsif ($node->at(q(step))    and !$node->up(q(steps)))                      # Step not in steps
     {$node->wrapWith(q(steps));
     }
    elsif ($node->at(q(substep)) and !$node->up(q(substeps)))                   # Substep not in substeps
     {$node->wrapWith(q(steps));
     }
    elsif ($node->at(q(li))      and !$node->up(qr(\A(ol|sl|ul)\Z)))            # Li not in list
     {$node->wrapWith(q(ol));
     }
    elsif ($node->at(q(cmd))     and  $node->up(q(steps)))                      # Cmd under steps
     {$node->wrapWith(q(step));
     }
    elsif ($node->at(q(cmd))     and  $node->up(q(substeps)))                   # Cmd under substeps
     {$node->wrapWith(q(substep));
     }
    elsif ($node->not(q(li))     and  $node->up(qr(\A(ol|sl|ul)\Z)))            # Something under a list which is not an li
     {$node->wrapWith(q(li));
     }
    elsif ($node->not(qw(step stepsection)) and  $node->up(q(steps)))           # Something under steps which is not a step or stepsection
     {if (my $p = $node->prev(q(stepsection)))
       {$p->putLast($node->cut);
       }
     else
       {$node->wrapWith(q(stepsection));
       }
     }
   }
  $node                                                                         # Return the specified B<$node>
 }

sub ditaMaximumNumberOfEntriesInARow($)                                         # Return the maximum number of entries in the rows of the specified B<$table> or B<undef> if not a table.
 {my ($table) = @_;                                                             # Table node
  $table->at_table or confess "Not a table node: ".$table->tag;                 # Confirm we are on a table
  my $N = 0;                                                                    # Maximum number of entries in a row
  $table->by(sub                                                                # Traverse table
   {if (my ($r, $hb, $g, $t) = @_)
     {if ($r->at_row_thead_tgroup_table || $r->at_row_tbody_tgroup_table
          and $t == $table)                                                     # Check this row is in the current table
       {if (my $n = $r->c_entry)                                                # Number of entries in this row
         {$N = max($N, $n);                                                     # Maximum number of entries in a row so far
         }
       }
     }
   });
  $N
 }

sub ditaAddPadEntriesToRows($$)                                                 #P Adding padding entries to a table to make sure every row has the same number of entries
 {my ($table, $nEntries) = @_;                                                  # Table node, number of entries
  $table->at_table or confess "Not a table node: ".$table->tag;                 # Confirm we are on a table
  $table->by(sub                                                                # Traverse table
   {if (my ($r, $hb, $g, $t) = @_)
     {if ($r->at_row_thead_tgroup_table || $r->at_row_tbody_tgroup_table
          and $t == $table)                                                     # Check this row is in the current table
       {my @e = $r->c_entry;                                                    # Number of entries in this row
        for(@e..$nEntries-1)                                                    # Number of pad entries in this row
         {$r->putLast($r->newTag(q(entry)));                                    # Add new padding entry
         }
       }
     }
   });
 }

sub ditaAddColSpecToTgroup($$)                                                  # Add the specified B<$number> of column specification to a specified B<$tgroup> which does not have any already.
 {my ($tgroup, $number) = @_;                                                   # Tgroup node, number of colspecs to add
  $tgroup->at_tgroup or confess "Not a tgroup node: ".$tgroup->tag;             # Confirm we are on a tgroup node
  $tgroup->set(cols=>$number);                                                  # Set cols attribute
  my @c = $tgroup->c_colspec;                                                   # Existing colspecs
  $_->unwrap for @c;                                                            # Remove existing colspecs
  for my $col(reverse 1..$number)                                               # Add colspecs
   {$tgroup->putFirst($tgroup->newTag(q(colspec),                               # Colspec
      colname=>"c$col", colnum=>"$col", colwidth=>"1*"));
   }
 }

sub ditaFixTableColSpec($)                                                      # Improve the specified B<$table> by making obvious improvements.
 {my ($table) = @_;                                                             # Table node
  $table->at_table or confess "Not a table node: ".$table->tag;                 # Check we are on a table
  my $tgroup = $table->addSingleChild(q(tgroup));                               # Add a tgroup if necessary
  my $N = $table->ditaMaximumNumberOfEntriesInARow;                             # Maximum number of entries in a row
  $tgroup->ditaAddColSpecToTgroup($N);                                          # Add colspecs
 }

sub ditaObviousChanges($)                                                       # Make obvious changes to a L<parse|/parse> tree to make it look more like L<Dita>.
 {my ($node) = @_;                                                              # Node

  $node->by(sub                                                                 # Do the obvious conversions
   {my ($o) = @_;

    my %change =                                                                # Tags that should be changed
     (book         => q(bookmap),
      code         => q(codeph),
      command      => q(codeph),                                                # Needs approval from Micalea
      emphasis     => q(b),
      figure       => q(fig),
      guibutton    => q(uicontrol),
      guilabel     => q(uicontrol),
      guimenu      => q(uicontrol),
      itemizedlist => q(ol),
      link         =>q(xref),
      listitem     => q(li),
      menuchoice   => q(uicontrol),
      orderedlist  => q(ol),
      para         => q(p),
      quote        => q(q),
      replaceable  => q(varname),
      subscript    => q(sub),
      variablelist => q(dl),
      varlistentry => q(dlentry),
     );

    my %deleteAttributesDependingOnValue =                                      # Attributes that should be deleted if they have specified values
     (b=>[[qw(role bold)], [qw(role underline)]],
     );

    my @deleteAttributesUnconditionally =                                       # Attributes that should be deleted unconditionally from all tags that have them
     qw(version xml:id xmlns xmlns:xi xmlns:xl xmlns:d);

    my %renameAttributes =                                                      # Attributes that should be renamed
     (xref=>[[qw(linkend href)], [qw(xrefstyle outputclass)]],                  # 2018.06.14 added xrefstyle->outputclass
      fig =>[[qw(role outputclass)], [qw(xml:id id)]],
      example   =>[[qw(role outputclass)]],
      imagedata =>[[qw(contentwidth width)], [qw(fileref href)]],
     );

    for my $old(sort keys %change)                                              # Perform requested tag changes
     {$o->change($change{$old}) if $o->at($old);
     }

    for my $tag(sort keys %deleteAttributesDependingOnValue)                    # Delete specified attributes if they have the right values
     {if ($o->at($tag))
       {$o->deleteAttr(@$_) for @{$deleteAttributesDependingOnValue{$tag}};
       }
     }

    $o->deleteAttrs(@deleteAttributesUnconditionally);                          # Delete attributes unconditionally from all tags that have them

    for my $tag(sort keys %renameAttributes)                                    # Rename specified attributes
     {if ($o->at($tag))
       {$o->renameAttr(@$_) for @{$renameAttributes{$tag}};
       }
     }
   });
 }

sub topicTypeAndBody($)                                                         #P Topic type and corresponding body.
 {my ($type) = @_;                                                              # Type from qw(bookmap concept reference task)
  return qw(concept     Concept    conbody)  if $type =~ /\Aconcept/i;
  return qw(reference   Reference  refbody)  if $type =~ /\Areference/i;
  return qw(task        Task       taskbody) if $type =~ /\Atask/i;
  return qw(bookmap     BookMap)             if $type =~ /\Abookmap/i;
  confess "Unknown document type: $type",
          ", choose from bookmap, concept, reference, task";
 }

my $ditaOrganization = q(OASIS);                                                # The organization field to be used in the xml headers

sub ditaOrganization :lvalue                                                    # Set the dita organization field in the xml headers, set by default to OASIS.
 {my ($organization) = @_;                                                      # Organization
  $ditaOrganization
 }

sub ditaTopicHeaders($)                                                         # Add xml headers for the dita document type indicated by the specified L<parse|/parse> tree
 {my ($node)  = @_;                                                             # Node in parse tree
  my $parse   = $node->parser;
  my $o       = $ditaOrganization;
  my ($n, $N) = topicTypeAndBody($parse->tag);
  <<END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE $n PUBLIC "-//$o//DTD DITA $N//EN" "$n.dtd" []>
END
 }

sub ditaPrettyPrintWithHeaders($)                                               # Add xml headers for the dita document type indicated by the specified L<parse|/parse> tree to a pretty print of the parse tree.
 {my ($node)  = @_;                                                             # Node in parse tree
  $node->ditaTopicHeaders.-p $node
 }

sub htmlHeadersToSections($)                                                    # Position sections just before html header tags so that subsequently the document can be divided into L<sections|/divideDocumentIntoSections>.
 {my ($node) = @_;                                                              # Parse tree

  $node->by(sub                                                                 # Move each section definition upwards so that its parent is another section. Intervening container tags such as <div> or <span> should have been unwrapped by this point as they might move the section further back than is desired.
   {my ($o) = @_;
    if ($o->tag =~ m(\Ah(\d)\Z)i)
     {my $level = $1;
      $o->putPrev($o->newTag(q(section), level=>$level));
     }
   });
 }

sub getSectionHeadingLevel($)                                                   #P Get the heading level from a section tag.
 {my ($o) = @_;                                                                 # Node
  return undef unless $o->at(qq(section));
  $o->attr(qq(level))
 }

sub divideDocumentIntoSections($$)                                              # Divide a L<parse|/parse> tree into sections by moving non B<section> tags into their corresponding B<section> so that the B<section> tags expand until they are contiguous. The sections are then cut out by applying the specified sub to each B<section> tag in the L<parse|/parse> tree. The specified sub will receive the containing B<topicref> and the B<section> to be cut out as parameters allowing a reference to the cut out section to be inserted into the B<topicref>.
 {my ($node, $cutSub) = @_;                                                     # Parse tree, cut out sub

  $node->by(sub                                                                 # In word documents the header is often buried in a list to gain a section number - here we remove these unnecessary items
   {my ($o) = @_;
    if ($o->at(qq(section)))
     {$o->unwrapParentsWithSingleChild;
     }
   });

  $node->by(sub                                                                 # Place each non heading node in its corresponding heading node
   {my ($o) = @_;
    if (my $h = getSectionHeadingLevel($o))
     {while(my $n = $o->next)
       {last if getSectionHeadingLevel($n);
        $n->cut;
        $o->putLast($n);
       }
     }
   });

  $node->by(sub                                                                 # Place each sub section in its containing section
   {my ($o) = @_;
    if (my $h = getSectionHeadingLevel($o))
     {while(my $n = $o->next)
       {my $i = getSectionHeadingLevel($n);
        last if !defined($i) or $i <= $h;
        $o->putLast($n->cut);
       }
     }
   });

  $node->by(sub                                                                 # Wrap each section in topicrefs
   {my ($o) = @_;
    if ($o->at(qq(section)))
     {my $t = $o->wrapWith(q(topicref));                                        # Topic ref
      $t->putLast($_->cut) for $o->c(q(topicref));                              # Move topics out of section into containing topic
     };
   });

  $node->by(sub                                                                 # Cut out each section
   {my ($o, $p) = @_;
    if ($o->at(qq(section)))
     {$p->at(q(topicref)) or confess "Section not in topicref";
      $cutSub->($p, $o);
     }
   });
 }

sub ditaParagraphToNote($;$)                                                    # Convert all <p> nodes to <note> if the paragraph starts with 'Note:', optionally wrapping the content of the <note> with a <p>
 {my ($node, $wrapNoteContentWithParagaph) = @_;                                # Parse tree, wrap the <note> content with a <p> if true
  $node->by(sub                                                                 # Each node
   {my ($o, $p) = @_;                                                           # Text, p
    if ($o->matchesText(qr(\A\s*Notes?\s*:\s*)) and $p->at(q(p)))               # Text under p
     {$p->change(q(note));                                                      # Change to note
      $p->wrapContentWith(q(p)) if $wrapNoteContentWithParagaph;                # Wrap content if required
      $o->text =~        s(\A\s*Notes?\s*:\s*) ();                              # Remove note text
      $o->text = ucfirst($o->text);                                             # Uppercase leading character
     }
   });
 }

sub wordStyles($)                                                               # Extract style information from a parse tree representing a word document.
 {my ($x) = @_;                                                                 # Parse tree
  my $styles;                                                                   # Styles encountered
  $x->by(sub                                                                    # Each node
   {my ($o, $p) = @_;
    if ($o->at(qw(text:list-level-style-bullet text:list-style)))               # Bulleted lists
     {my ($level, $name) = ($o->attr(q(text:level)), $p->attr(q(style:name)));
      if ($level and $name)
       {$styles->{bulletedList}{$name}{$level}++;
       }
     }
   });
  $styles                                                                       # Return styles encountered
 }

sub htmlTableToDita($)                                                          # Convert an L<html table> to a L<Dita> table.
 {my ($table) = @_;                                                             # Html table node

  $table->wrapContentWith(q(tgroup));                                           # tgroup
  my %transforms =                                                              # Obvious transformations
   (td=>q(entry),
    th=>q(entry),
    tr=>q(row),
   );

  $table->by(sub
   {if (my $c = $transforms{-t $_}) {$_->change($c)}
   });

  my $N = 0;                                                                    # Number of columns in widest row
  $table->by(sub
   {my ($r, undef, $group, $Table) = @_;
    if ($r->at(qw(row), undef, qw(tgroup table)) and $Table == $table)          # In this table, not in an embedded sub table
     {my $n = $r->c(q(entry));
      $N = $n if $n > $N;
     }
   });

  $table->by(sub                                                                # Fix colspecs
   {my ($group, $Table) = @_;
    if ($group->at(qw(tgroup table)) and $Table == $table)                      # In this table, not in an embedded sub table
     {$group->setAttr   (q(cols), $N);
      $_->unwrap for $group->c(q(colspec));
      $group->putFirst($group->newTag                                           # Insert colspecs
       (qw(colspec colname), qq(c$_), q(colnum), $_, qw(colwidth 1*)))
        for reverse 1..$N;
     }
   });

  $table->by(sub                                                                # Span last element of each row to fill row
   {my ($r, undef, $group, $Table) = @_;
    if ($r->at(qw(row), undef, qw(tgroup table)) and $Table == $table)
     {my @e = $r->c(q(entry));
      my $n = @e;
      $e[-1]->setAttr(namest=>qq(c$n), nameend=>qq(c$N)) if @e < $N;
     }
   });
 }

#D1 Debug                                                                       # Debugging methods

sub printAttributes($)                                                          # Print the attributes of a node.
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

sub printNode($)                                                                # Print the tag and attributes of a node.
 {my ($node) = @_;                                                              # Node to be printed.
  my %a = %{$node->attributes};                                                 # Attributes
  my $t = $node->tag;                                                           # Tag
  my $s = '';                                                                   # Attributes string
  for(sort keys %a)                                                             # Each attribute
   {next unless defined(my $v = $a{$_});                                        # Each defined attribute
    $s .= qq( ${_}="$v");                                                       # Attributes enclosed in "" in alphabetical order
   }
  qq($t$s)                                                                      # Result
 }

sub printAttributesReplacingIdsWithLabels($)                                    #P Print the attributes of a node replacing the id with the labels.
 {my ($node) = @_;                                                              # Node whose attributes are to be printed.
  my %a = %{$node->attributes};                                                 # Clone attributes
  my %l = %{$node->labels};                                                     # Clone labels
  delete $a{id};                                                                # Delete id
  $a{id} = join ', ', sort keys %l if keys %l;                                  # Replace id with labels in cloned attributes
  defined($a{$_}) ? undef : delete $a{$_} for keys %a;                          # Remove undefined attributes
  return '' unless keys %a;                                                     # No attributes
  my $s = ' '; $s .= $_.'="'.$a{$_}.'" ' for sort keys %a; chop($s);            # Attributes enclosed in "" in alphabetical order
  $s
 }

sub printAttributesExtendingIdsWithLabels($)                                    #P Print the attributes of a node extending the id with the labels.
 {my ($node) = @_;                                                              # Node whose attributes are to be printed.
  my %a = %{$node->attributes};                                                 # Clone attributes
  my %l = %{$node->labels};                                                     # Clone labels
  my $i = $a{id} ? $a{id}.q(, ) : q();                                          # Format id
  $a{id} = join '', $i, join ', ', sort keys %l if keys %l;                     # Extend id with labels in cloned attributes
  defined($a{$_}) ? undef : delete $a{$_} for keys %a;                          # Remove undefined attributes
  return '' unless keys %a;                                                     # No attributes
  my $s = ' '; $s .= $_.'="'.$a{$_}.'" ' for sort keys %a; chop($s);            # Attributes enclosed in "" in alphabetical order
  $s
 }

sub checkParentage($)                                                           #P Check the parent pointers are correct in a L<parse|/parse> tree.
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

sub checkParser($)                                                              #P Check that every node has a L<parse|/parse>r.
 {my ($x) = @_;                                                                 # Parse tree.
  $x->by(sub
   {$_->parser or confess "No parser for ". $_->tag;
    $_->parser == $x or confess "Wrong parser for ". $_->tag;
   })
 }

sub goFish($@)                                                                  # A debug version of L<go|/go> that returns additional information explaining any failure to reach the node identified by the L<path|/path>.\mReturns ([B<reachable tag>...], B<failing tag>, [B<possible tag>...]) where:\m=over\m=item B<reachable tag>\mthe path elements successfully traversed;\m=item B<failing tag>\mthe failing element;\m=item B<possible tag>\mthe possibilities at the point where the path failed if it failed else B<undef>.\m=back\mParameters:
 {my ($node, @path) = @_;                                                       # Node, search specification.
  my $p = $node;                                                                # Current node
  my @p;                                                                        # Elements of the path successfully processed
  while(@path)                                                                  # Position specification
   {my $i = shift @path;                                                        # Index name
    return ([@p], $i, [sort keys %{$p->indexes}]) unless $p;                    # There is no node of the named type under this node
    reindexNode($p);                                                            # Create index for this node
    my $q = $p->indexes->{$i};                                                  # Index
    return ([@p], $i, [sort keys %{$p->indexes}]) unless defined $q;            # Complain if no such index
    push @p, $i;
    if (@path)                                                                  # Position within index
     {if ($path[0] =~ /\A([-+]?\d+)\Z/)                                         # Numeric position in index from start
       {my $n = shift @path;                                                    # Next path item
        my $N = scalar(@$q);                                                    # Dimension of index
        return ([@p], $n, [0..$N]) unless defined($p = $q->[$n]);               # Complain if no such index
        push @p, $n;                                                            # Save successfully processed index
       }
      elsif (@path == 1 and $path[0] =~ /\A\*\Z/)                               # Final index wanted
       {return [@p];
       }
      else {$p = $q->[0]}                                                       # Step into first sub node by default
     }
    else {$p = $q->[0]}                                                         # Step into first sub node by default on last step
   }
  [@p]                                                                          # Success!
 }

sub nn($)                                                                       #P Replace new lines in a string with N to make testing easier.
 {my ($s) = @_;                                                                 # String.
  $s =~ s/\n/N/gsr
 }

#D Tests and documentation

sub extractDocumentationFlags($$)                                               # Generate documentation for a method with a user flag.
 {my ($flags, $method) = @_;                                                    # Flags, method name.
  my $b = "${method}NonBlank";                                                  # Not blank method name - used for a small number of navigation methods
  my $x = "${method}NonBlankX";                                                 # Not blank, die on B<undef> method name
  my $m = $method;                                                              # Second action method
     $m =~ s/\Afirst/next/gs;
     $m =~ s/\Alast/prev/gs;
  my @doc; my @code;

  if ($flags =~ m/C/is)                                                         # Context flag for a method that returns a single node or B<undef> if in the wrong context
   {push @doc, <<'END' if $flags =~ m/C/s;
Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.
END
    push @doc, <<'END' if $flags =~ m/c/s;
Use the required B<$tag> parameter to specify the expected tag on the specified
B<$node> using a single match expression as understood by method L<at|/at>. Use
the optional B<@context> parameter to test the context as understood by method
L<at|/at> of the parent node of the specified B<$node>. If either test fails
this method returns B<undef> immediately.
END
   }
  if ($flags =~ m/K/s)                                                          # Context flag for a method that returns an array of nodes or the empty array if in the wrong context
   {push @doc, <<'END';
Use the B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>.  If a context is supplied and
B<$node> is not in this context then this method returns an empty list B<()>
immediately.
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

  [join("\n", @doc), join("\n", @code), $flags =~ m/B/ ? [$b, $x] : ()]
 }

#D1 Compression                                                                 # Read and write files of compressed xml.  These methods provide a compact, efficient way to store and retrieve parse trees to/from files.

sub writeCompressedFile($$)                                                     # Write the parse tree starting at B<$node> as compressed xml to the specified B<$file>. Use L<readCompressedFile|/readCompressedFile>  to read the B<$file>.
 {my ($node, $file) = @_;                                                       # Parse tree node, file to write to.
  makePath($file);
  open my $F, "| gzip>$file" or                                                 # Compress via gzip
    confess "Cannot open file for write because:\n$file\n$!\n";
  binmode($F, ":utf8");                                                         # Input to gzip encoded as utf8
  print  {$F} -s $node;
  close  ($F);
  -e $file or confess "Failed to write to file:\n$file\n";
  $file
 }

sub readCompressedFile($)                                                       #S Read the specified B<$file> containing compressed xml and return the root node.  Use L<writeCompressedFile|/writeCompressedFile> to write the B<$file>.
 {my ($file) = @_;                                                              # File to read.
  defined($file) or
    confess "Cannot read undefined file\n";
  $file =~ m(\n) and
    confess "File name contains a new line:\n=$file=\n";
  -e $file or
    confess "Cannot read file because it does not exist, file:\n$file\n";
  open(my $F, "gunzip < $file|") or                                             # Unzip input file
    confess "Cannot open file for input, file:\n$file\n$!\n$?\n";
  local $/ = undef;
  my $string = <$F>;
  new($string)                                                                  # Reparse resulting string to recover parse tree
 }

#D1 Autoload                                                                    # Allow methods with constant parameters to be called as B<method_p1_p2>...(variable parameters) whenever it is easier to type underscores than (qw()).

our $AUTOLOAD;                                                                  # The method to be autoloaded appears here
sub  AUTOLOAD                                                                   # Allow methods with constant parameters to be called as B<method_p1_p2>...(variable parameters) whenever it is easier to type underscores than (qw()).
 {return if $AUTOLOAD =~ m(Destroy)is;                                          # Perl internal
  my $q = shift;                                                                # Object package
  if ($AUTOLOAD =~ m(__)s)                                                      # Chain of calls separated by q(__)
   {no strict q(refs);                                                          # So we can call a sub by name
    my @calls = split /__/, $AUTOLOAD;                                          # Calls in chain
    for my $call(@calls)                                                        # Each call in chain
     {my ($p, @p) = split /_/, $call;                                           # Call, parameters for call
      confess "No such method : $p" unless $q->can($p);                         # Check that the method name is valid
      $q = $p->($q, @p);                                                        # Make call
      return undef unless $q;                                                   # Abort chain of calls if any call returns undef
     }
    return $q;                                                                  # Return result of chain
   }
  else                                                                          # Optimized single call
   {my ($p, @p) = split /_/, $AUTOLOAD;                                         # Break out parameters
    confess "No such method : $p" unless $q->can($p);                           # Check that the method name is valid
    unshift @_, $q, @p;                                                         # Insert static parameters into parameter list
    goto &$p;                                                                   # Call desired routine
   }
 }

#D
# podDocumentation

#In B<chained exit> style:
#
#  $a -> byX(sub {$_ -> at(qw(c b a)) -> cut});

#Install If you receive the message:\m  Expat.xs:12:19: fatal error: expat.h: No such file or directory\mduring installation, install libexpat1-dev:\m  sudo apt install libexpat1-dev

=pod

=encoding utf-8

=head1 Name

Data::Edit::Xml - Edit data held in the XML format.

=head1 Synopsis

Create a L<new|/new> XML parse tree:

  my $a = Data::Edit::Xml::new q(<a><b><c/></b><d><c/></d></a>);

use:

  say STDERR -p $a;

to L<print|/print>:

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

  $a -> by(sub {$_ -> cut_c_b_a});

Or if you know when you are going:

  $a -> go_b_c__cut;

To get:

  <a>
    <b/>
    <d>
      <c/>
    </d>
  </a>

=head2 Bullets to unordered list

To transform a series of bullets into <ul><li>...</li></ul>, parse the input
XML:

  my $a = Data::Edit::Xml::new(<<END);
<a>
<p>• Minimum 1 number</p>
<p>•   No leading, trailing, or embedded spaces</p>
<p>• Not case-sensitive</p>
</a>
END

Traverse the resulting parse tree, removing bullets and changing <p> to <li>,
<a> to <ul>:

  $a->change_ul->by(sub
   {$_->up__change_li if $_->text_p and $_->text =~ s/\A•\s*//s
   });

Print to get:

  ok -p $a eq <<END;                                                            # Results
<ul>
  <li>Minimum 1 number</li>
  <li>No leading, trailing, or embedded spaces</li>
  <li>Not case-sensitive</li>
</ul>
END

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

Edit data held in the XML format.

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Immediately useful methods

These methods are the ones most likely to be of immediate use to anyone using
this module for the first time:


L<at|/at>

Confirm that the specified B<$node> has the specified L<ancestry|/ancestry> and return the specified B<$node> if it does else B<undef>. Ancestry is specified by providing the expected tags that the B<$node>'s parent, the parent's parent etc. must match at each level. If B<undef> is specified then any tag is assumed to match at that level. If a regular expression is specified then the current parent node tag must match the regular expression at that level. If all supplied tags match successfully then the starting node is returned else B<undef>

L<attr|/attr>

Return the value of an attribute of the current node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

L<by|/by>

Post-order traversal of a L<parse|/parse> tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. A reference to the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>. This is equivalent to the L<x=|/opBy> operator.

L<change|/change>

Change the name of the specified B<$node>, optionally  confirming that the B<$node> is in a specified context and return the B<$node>.

L<cut|/cut>

Cut out the specified B<$node> so that it can be reinserted else where in the L<parse|/parse> tree.

L<go|/go>

Return the node reached from the specified B<$node> via the specified L<path|/path>: (index positionB<?>)B<*> where index is the tag of the next node to be chosen and position is the optional zero based position within the index of those tags under the current node. Position defaults to zero if not specified. Position can also be negative to index back from the top of the index array. B<*> can be used as the last position to retrieve all nodes with the final tag.

L<new|/new>

Create a new parse tree - call this method statically as in Data::Edit::Xml::new(file or string) to parse a file or string B<or> with no parameters and then use L</input>, L</inputFile>, L</inputString>, L</errorFile>  to provide specific parameters for the parse, then call L</parse> to perform the parse and return the parse tree.

L<prettyString|/prettyString>

Return a readable string representing a node of a L<parse|/parse> tree and all the nodes below it. Or use L<-p|/opString> $node

L<putLast|/putLast>

Place a L<cut out|/cut> or L<new|/new> node last in the content of the specified B<$node> and return the new node.  See L<addLast|/addLast> to perform this operation conditionally.

L<unwrap|/unwrap>

Unwrap the specified B<$node> by inserting its content into its parent at the point containing the specified B<$node> and return the parent node.

L<wrapWith|/wrapWith>

Wrap the specified B<$node> in a new node created from the specified B<$tag> and B<%attributes> forcing the specified B<$node> down - deepening the L<parse|/parse> tree - return the new wrapping node. See L<addWrapWith|/addWrapWith> to perform this operation conditionally.




=head1 Construction

Create a parse tree, either by parsing a L<file or string|/file or string>, or, L<node by node|/Node by Node>, or, from another L<parse tree|/Parse tree>.

=head2 File or String

Construct a parse tree from a file or a string.

=head3 new($)

Create a new parse tree - call this method statically as in Data::Edit::Xml::new(file or string) to parse a file or string B<or> with no parameters and then use L</input>, L</inputFile>, L</inputString>, L</errorFile>  to provide specific parameters for the parse, then call L</parse> to perform the parse and return the parse tree.

     Parameter          Description
  1  $fileNameOrString  Optional file name or string from which to construct the parse tree

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
    ok -p $a eq <<END;                                                            #tdown #tdownX               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  

This is a static method and so should be invoked as:

  Data::Edit::Xml::new


=head3 cdata()

The name of the tag to be used to represent text - this tag must not also be used as a command tag otherwise the parser will L<confess|http://perldoc.perl.org/Carp.html#SYNOPSIS/>.


Example:


   {ok Data::Edit::Xml::cdata eq q(CDATA);                                        
  

=head3 parse($)

Parse input XML specified via: L<inputFile|/inputFile>, L<input|/input> or L<inputString|/inputString>.

     Parameter  Description
  1  $parser    Parser created by L</new>

Example:


   {my $x = Data::Edit::Xml::new;                                                 
  
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


   {my $x = Data::Edit::Xml::newTree("a", id=>1, class=>"aa");                     
  
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


   {my $x = Data::Edit::Xml::newTree("a", id=>1, class=>"aa");                     
  
    ok -s $x eq '<a class="aa" id="1"/>';                                         
  

=head3 replaceSpecialChars($)

Replace < > " & with &lt; &gt; &quot; &amp; Larry Wall's excellent L<Xml parser|https://metacpan.org/pod/XML::Parser/> unfortunately replaces &lt; &gt; &quot; &amp; etc. with their expansions in text by default and does not seem to provide an obvious way to stop this behavior, so we have to put them back again using this method.

     Parameter  Description
  1  $string    String to be edited.

Example:


    ok Data::Edit::Xml::replaceSpecialChars(q(<">)) eq "&lt;&quot;&gt;";          
  

This is a static method and so should be invoked as:

  Data::Edit::Xml::replaceSpecialChars


=head2 Parse tree attributes

Attributes of a node in a parse tree. For instance the attributes associated with an XML tag are held in the L<attributes|/attributes> attribute. It should not be necessary to use these attributes directly unless you are writing an extension to this module.  Otherwise you should probably use the methods documented in other sections to manipulate the parse tree as they offer a safer interface at a higher level.

=head3 content :lvalue

Content of command: the nodes immediately below the specified B<$node> in the order in which they appeared in the source text, see also L</Contents>.


=head3 numbers :lvalue

Nodes by number.


=head3 data :lvalue

A hash added to the node for use by the programmer during transformations. The data in this hash will not be printed by any of the L<printed|/Print> methods and so can be used to add data to the L<parse|/parse> tree that will not be seen in any output xml produced from the L<parse|/parse> tree.


=head3 attributes :lvalue

The attributes of the specified B<$node>, see also: L</Attributes>.  The frequently used attributes: class, id, href, outputclass can be accessed by an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> method as in: $node->id = 'c1'.


=head3 conditions :lvalue

Conditional strings attached to a node, see L</Conditions>.


=head3 forestNumbers :lvalue

Index to node by forest number as set by L<numberForest|/numberForest>.


=head3 indexes :lvalue

Indexes to sub commands by tag in the order in which they appeared in the source text.


=head3 labels :lvalue

The labels attached to a node to provide addressability from other nodes, see: L</Labels>.


=head3 errorsFile :lvalue

Error listing file. Use this parameter to explicitly set the name of the file that will be used to write any L<parse|/parse> errors to. By default this file is named: B<zzzParseErrors/out.data>.


=head3 inputFile :lvalue

Source file of the L<parse|/parse> if this is the L<parser|/parse> root node. Use this parameter to explicitly set the file to be L<parsed|/parse>.


=head3 input :lvalue

Source of the L<parse|/parse> if this is the L<parser|/parse> root node. Use this parameter to specify some input either as a string or as a file name for the L<parser|/parse> to convert into a L<parse|/parse> tree.


=head3 inputString :lvalue

Source string of the L<parse|/parse> if this is the L<parser|/parse> root node. Use this parameter to explicitly set the string to be L<parsed|/parse>.


=head3 numbering :lvalue

Last number used to number a node in this L<parse|/parse> tree.


=head3 number :lvalue

Number of the specified B<$node>, see L<findByNumber|/findByNumber>.


=head3 parent :lvalue

Parent node of the specified B<$node> or B<undef> if the L<parser|/parse> root node. See also L</Traversal> and L</Navigation>. Consider as read only.


=head3 parser :lvalue

L<Parser|/parse> details: the root node of a tree is the L<parser|/parse> node for that tree. Consider as read only.


=head3 tag :lvalue

Tag name for the specified B<$node>, see also L</Traversal> and L</Navigation>. Consider as read only.


=head3 text :lvalue

Text of the specified B<$node> but only if it is a text node, i.e. the tag is cdata() <=> L</isText> is true.


=head2 Parse tree

Construct a L<parse|/parse> tree from another L<parse|/parse> tree.

=head3 renew($@)

Returns a renewed copy of the L<parse|/parse> tree, optionally checking that the starting node is in a specified context: use this method if you have added nodes via the L</"Put as text"> methods and wish to traverse their L<parse|/parse> tree.

Returns the starting node of the new L<parse|/parse> tree or B<undef> if the optional context constraint was supplied but not satisfied.

     Parameter  Description
  1  $node      Node to renew from
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new("<a/>");                                         
  
    $a->putFirstAsText(qq(<b/>));                                                 
  
    ok !$a->go(q(b));                                                             
  
    my $A = $a->renew;                                                            
  
    ok -t $A->go(q(b)) eq q(b)                                                    
  

=head3 clone($@)

Return a clone of the L<parse|/parse> tree optionally checking that the starting node is in a specified context: the L<parse|/parse> tree is cloned without converting it to string and reparsing it so this method will not L<renew|/renew> any nodes added L<as text|/Put as text>.

Returns the starting node of the new L<parse|/parse> tree or B<undef> if the optional context constraint was supplied but not satisfied.

     Parameter  Description
  1  $node      Node to clone from
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new("<a> </a>");                                      
  
    my $A = $a->clone;                                                             
  
    ok -s $A eq q(<a/>);                                                           
  
    ok $a->equals($A);                                                             
  
   {my $x = Data::Edit::Xml::new(<<END);                                           
  <x>
    <a>aaa
      <b>bbb</b>
      ccc
      <d>ddd</d>
      eee
    </a>
  </x>
  END
  
    my $y = $x->clone;                                                             
  
    ok !$x->diff($y);                                                              
  

=head3 equals($$)

Return the first node if the two L<parse|/parse> trees have identical representations via L<string|/string>, else B<undef>.

     Parameter  Description
  1  $node1     Parse tree 1
  2  $node2     Parse tree 2.

Example:


   {my $a = Data::Edit::Xml::new("<a> </a>");                                      
  
    my $A = $a->clone;                                                             
  
    ok -s $A eq q(<a/>);                                                           
  
    ok $a->equals($A);                                                             
  

=head3 equalsIgnoringAttributes($$@)

Return the first node if the two L<parse|/parse> trees have identical representations via L<string|/string> if the specified attributes are ignored, else B<undef>.

     Parameter    Description
  1  $node1       Parse tree 1
  2  $node2       Parse tree 2
  3  @attributes  Attributes to ignore during comparison

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b   id="1" outputclass="1" name="b">
      <c id="2" outputclass="2" name="c"/>
    </b>
  </a>
  END
  
    my $A = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b   id="11" outputclass="11" name="b">
      <c id="22" outputclass="22" name="c"/>
    </b>
  </a>
  END
  
    ok !$a->equals($A);                                                           
  
    ok !$a->equalsIgnoringAttributes($A, qw(id));                                 
  
    ok  $a->equalsIgnoringAttributes($A, qw(id outputclass));                     
  

=head3 diff($$$)

Return () if the dense string representations of the two nodes are equal, else up to the first N (default 16) characters of the common prefix before the point of divergence and the remainder of the string representation of each node from the point of divergence. All <!-- ... --> comments are ignored during this comparison and all spans of white space are reduced to a single blank.

     Parameter  Description
  1  $first     First node
  2  $second    Second node
  3  $N         Maximum length of difference strings to return

Example:


   {my $x = Data::Edit::Xml::new(<<END);                                           
  <x>
    <a>aaa
      <b>bbb</b>
      ccc
      <d>ddd</d>
      eee
    </a>
  </x>
  END
  
    ok !$x->diff($x);                                                             
  
    my $y = $x->clone;                                                             
  
    ok !$x->diff($y);                                                              
  
    $y->first->putLast($x->newTag(q(f)));                                         
  
    ok nws(<<END) eq nws(-p $y);                                                  
  <x>
    <a>aaa
      <b>bbb</b>
      ccc
      <d>ddd</d>
      eee
      <f/>
    </a>
  </x>
  END
  
    is_deeply [$x->diff($y)],    ["<d>ddd</d> eee <", "/a></x>", "f/></a></x>"];  
  
    is_deeply [diff(-p $x, $y)], ["<d>ddd</d> eee <", "/a></x>", "f/></a></x>"];  
  
    is_deeply [$x->diff(-p $y)], ["<d>ddd</d> eee <", "/a></x>", "f/></a></x>"];  
  
    my $X = writeFile(undef, -p $x);                                              
  
    my $Y = writeFile(undef, -p $y);                                              
  
    is_deeply [diff($X, $Y)],    ["<d>ddd</d> eee <", "/a></x>", "f/></a></x>"];  
  

=head3 save($$)

Save a copy of the L<parse|/parse> tree to a file which can be L<restored|/restore> and return the saved node.  This method uses L<Storable> which is fast but produces large files that do not compress well.  Use L<writeCompressedFile|/writeCompressedFile> to produce smaller save files at the cost of more time.

     Parameter  Description
  1  $node      Parse tree
  2  $file      File.

Example:


      $y->save($f);                                                                
  
      my $Y = Data::Edit::Xml::restore($f);                                        
  
      ok $Y->equals($y);                                                           
  

=head3 restore($)

Return a L<parse|/parse> tree from a copy saved in a file by L<save|/save>.

     Parameter  Description
  1  $file      File

Example:


      $y->save($f);                                                                
  
      my $Y = Data::Edit::Xml::restore($f);                                        
  
      ok $Y->equals($y);                                                           
  

This is a static method and so should be invoked as:

  Data::Edit::Xml::restore


=head3 expandIncludes($)

Expand the includes mentioned in a L<parse|/parse> tree: any tag that ends in B<include> is assumed to be an include directive.  The file to be included is named on the B<href> keyword.  If the file to be included is a relative file name, i.e. it does not begin with B</> then this file is made absolute relative to the file from which this L<parse|/parse> tree was obtained.

     Parameter  Description
  1  $x         Parse tree

Example:


   {my @files =                                                                   
  
     (writeFile("in1/a.xml", q(<a id="a"><include href="../in2/b.xml"/></a>)),    
  
      writeFile("in2/b.xml", q(<b id="b"><include href="c.xml"/></b>)),           
  
      writeFile("in2/c.xml", q(<c id="c"/>)));                                    
  
    my $x = Data::Edit::Xml::new(fpf(currentDirectory, $files[0]));               
  
       $x->expandIncludes;                                                        
  
    ok <<END eq -p $x;                                                            
  <a id="a">
    <b id="b">
      <c id="c"/>
    </b>
  </a>
  END
  

=head1 Print

Create a string representation of the L<parse|/parse> tree with optional selection of nodes via L<conditions|/Conditions>.

Normally use the methods in L<Pretty|/Pretty> to format the XML in a readable yet reparseable manner; use L<Dense|/Dense> string to format the XML densely in a reparseable manner; use the other methods to produce unreparseable strings conveniently formatted to assist various specialized operations such as debugging CDATA, using labels or creating tests. A number of the L<file test operators|/opString> can also be conveniently used to print L<parse|/parse> trees in these formats.

=head2 Pretty

Pretty print the L<parse|/parse> tree.

=head3 prettyString($$)

Return a readable string representing a node of a L<parse|/parse> tree and all the nodes below it. Or use L<-p|/opString> $node

     Parameter  Description
  1  $node      Start node
  2  $depth     Optional depth.

Example:


   {my $s = <<END;                                                                     
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
  
   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b>bbb</b>.
    <c>ccc</c>.
  </a>
  END
  
    ok nn(-p $a) eq qq(<a>N  <b>bbb</b>.NN  N  <c>ccc</c>.NNN</a>N);              
  

=head3 prettyStringDitaHeaders($)

Return a readable string representing the L<parse|/parse> tree below the specified B<$node> with appropriate headers as determined by L<ditaOrganization|/ditaOrganization> . Or use L<-x|/opString> $node

     Parameter  Description
  1  $node      Start node

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                            
  <concept/>
  END
  
    Data::Edit::Xml::ditaOrganization = q(ACT);                                     
  
    ok $a->prettyStringDitaHeaders eq <<END;                                        
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE concept PUBLIC "-//ACT//DTD DITA Concept//EN" "concept.dtd" []>
  <concept/>
  END
  
    ok -x $a eq <<END;                                                              
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE concept PUBLIC "-//ACT//DTD DITA Concept//EN" "concept.dtd" []>
  <concept/>
  END
  

=head3 prettyStringNumbered($$)

Return a readable string representing a node of a L<parse|/parse> tree and all the nodes below it with a L<number|/number> attached to each tag. The node numbers can then be used as described in L<Order|/Order> to monitor changes to the L<parse|/parse> tree.

     Parameter  Description
  1  $node      Start node
  2  $depth     Optional depth.

Example:


   {my $s = <<END;                                                                     
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

Return a readable string representing a node of a L<parse|/parse> tree and all the nodes below it with the text fields wrapped with <CDATA>...</CDATA>.

     Parameter  Description
  1  $node      Start node
  2  $depth     Optional depth.

Example:


   {my $a = Data::Edit::Xml::new("<a><b>A</b></a>");                              
  
    my $b = $a->first;                                                            
  
       $b->first->replaceWithBlank;                                               
  
    ok $a->prettyStringCDATA eq <<END;                                              
  <a>
      <b><CDATA> </CDATA></b>
  </a>
  END
  

=head3 prettyStringContent($)

Return a readable string representing all the nodes below a node of a L<parse|/parse> tree.

     Parameter  Description
  1  $node      Start node.

Example:


   {my $s = <<END;                                                                     
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

Return a readable string representing all the nodes below a node of a L<parse|/parse> tree with numbering added.

     Parameter  Description
  1  $node      Start node.

Example:


   {my $s = <<END;                                                                
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
  

=head3 xmlHeader($)

Add the standard xml header to a string

     Parameter  Description
  1  $string    String to which a standard xml header should be prefixed

Example:


  ok xmlHeader("<a/>") eq <<END;                                                  
  <?xml version="1.0" encoding="UTF-8"?>
  <a/>
  END
  

This is a static method and so should be invoked as:

  Data::Edit::Xml::xmlHeader


=head2 Dense

Print the L<parse|/parse> tree.

=head3 string($)

Return a dense string representing a node of a L<parse|/parse> tree and all the nodes below it. Or use L<-s|/opString> $node

     Parameter  Description
  1  $node      Start node.

Example:


    ok -p $a eq <<END;                                                            #tdown #tdownX               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
    ok -s $a eq '<a><b><c id="42" match="mm"/></b><d><e/></d></a>';                
  

=head3 stringQuoted($)

Return a quoted string representing a L<parse|/parse> tree a node of a L<parse|/parse> tree and all the nodes below it. Or use L<-o|/opString> $node

     Parameter  Description
  1  $node      Start node

Example:


   {my $s = <<END;                                                                     
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

Return a string representing the specified L<parse|/parse> tree with the id attribute of each node set to the L<Labels|/Labels> attached to each node.

     Parameter  Description
  1  $node      Start node.

Example:


    ok $x->stringReplacingIdsWithLabels eq '<a><b><c/></b></a>';                                             
  
    $b->addLabels(1..4);                                                          
  
    $c->addLabels(5..8);                                                          
  
    ok $x->stringReplacingIdsWithLabels eq '<a><b id="1, 2, 3, 4"><c id="5, 6, 7, 8"/></b></a>';             
  
    my $s = $x->stringReplacingIdsWithLabels;                                     
  
    ok $s eq '<a><b id="1, 2, 3, 4"><c id="5, 6, 7, 8"/></b></a>';                
  

=head3 stringExtendingIdsWithLabels($)

Return a string representing the specified L<parse|/parse> tree with the id attribute of each node extended by the L<Labels|/Labels> attached to each node.

     Parameter  Description
  1  $node      Start node.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a id="a">
    <b id="b">
      <c id="c"/>
    </b>
    <b id="B">
      <c id="C"/>
    </b>
  </a>
  END
  
    my $N = 0; $a->by(sub{$_->addLabels((-t $_).++$N)});                          
  
    ok -p (new $a->stringExtendingIdsWithLabels) eq <<END;                         
  <a id="a, a5">
    <b id="b, b2">
      <c id="c, c1"/>
    </b>
    <b id="B, b4">
      <c id="C, c3"/>
    </b>
  </a>
  END
  

=head3 stringContent($)

Return a string representing all the nodes below a node of a L<parse|/parse> tree.

     Parameter  Description
  1  $node      Start node.

Example:


   {my $s = <<END;                                                                     
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


    ok $x->stringReplacingIdsWithLabels eq '<a><b><c/></b></a>';                                                
  
    my $b = $x->go(q(b));                                                            
  
    $b->addLabels(1..2);                                                             
  
    $b->addLabels(3..4);                                                             
  
    ok $x->stringReplacingIdsWithLabels eq '<a><b id="1, 2, 3, 4"><c/></b></a>';                                 
  
    $b->numberTree;                                                               
  
    ok -S $b eq "b(2) 0:1 1:2 2:3 3:4";                                           
  

=head2 Conditions

Print a subset of the the L<parse|/parse> tree determined by the conditions attached to it.

=head3 stringWithConditions($@)

Return a string representing the specified B<$node> of a L<parse|/parse> tree and all the nodes below it subject to conditions to select or reject some nodes.

     Parameter    Description
  1  $node        Start node
  2  @conditions  Conditions to be regarded as in effect.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b>
      <c/>
      <d/>
    </b>
  </a>
  END
  
    my $b = $a >= 'b';                                                            
  
    my ($c, $d) = $b->contents;                                                   
  
    $b->addConditions(qw(bb BB));                                                       
  
    $c->addConditions(qw(cc CC));                                                                                      
  
    ok $a->stringWithConditions         eq '<a><b><c/><d/></b></a>';              
  
    ok $a->stringWithConditions(qw(bb)) eq '<a><b><d/></b></a>';                  
  
    ok $a->stringWithConditions(qw(cc)) eq '<a/>';                                
  

=head3 condition($$@)

Return the node if it has the specified condition and is in the optional context, else return B<undef>

     Parameter   Description
  1  $node       Node
  2  $condition  Condition to check
  3  @context    Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


    $b->addConditions(qw(bb BB));                                                       
  
    $c->addConditions(qw(cc CC));                                                                                      
  
    ok  $c->condition(q(cc));                                                     
  
    ok !$c->condition(q(dd));                                                     
  
    ok  $c->condition(q(cc), qw(c b a));                                          
  

=head3 anyCondition($@)

Return the node if it has any of the specified conditions, else return B<undef>

     Parameter    Description
  1  $node        Node
  2  @conditions  Conditions to check

Example:


    $b->addConditions(qw(bb BB));                                                       
  
    $c->addConditions(qw(cc CC));                                                                                      
  
    ok  $b->anyCondition(qw(bb cc));                                              
  
    ok !$b->anyCondition(qw(cc CC));                                              
  

=head3 allConditions($@)

Return the node if it has all of the specified conditions, else return B<undef>

     Parameter    Description
  1  $node        Node
  2  @conditions  Conditions to check

Example:


    $b->addConditions(qw(bb BB));                                                       
  
    $c->addConditions(qw(cc CC));                                                                                      
  
    ok  $b->allConditions(qw(bb BB));                                             
  
    ok !$b->allConditions(qw(bb cc));                                             
  

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

Get or set the attributes of nodes in the L<parse|/parse> tree. L<Well Known Attributes|/Well Known Attributes>  can be set directly via L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>s. To set or get the values of other attributes use L<Get or Set Attributes|/Get or Set Attributes>. To delete or rename attributes see: L<Other Operations on Attributes|/Other Operations on Attributes>.

=head2 Well Known Attributes

Get or set these attributes of nodes via L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>s as in:

  $x->href = "#ref";

=head3 audience :lvalue

Attribute B<audience> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.    Use B<audienceX()> to return B<q()> rather than B<undef>.


=head3 class :lvalue

Attribute B<class> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.       Use B<classX()> to return B<q()> rather than B<undef>.


=head3 guid :lvalue

Attribute B<guid> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.        Use B<guidX()> to return B<q()> rather than B<undef>.


=head3 href :lvalue

Attribute B<href> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.        Use B<hrefX()> to return B<q()> rather than B<undef>.


=head3 id :lvalue

Attribute B<id> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.          Use B<idX()> to return B<q()> rather than B<undef>.


=head3 lang :lvalue

Attribute B<lang> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.        Use B<langX()> to return B<q()> rather than B<undef>.


=head3 navtitle :lvalue

Attribute B<navtitle> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.    Use B<navtitleX()> to return B<q()> rather than B<undef>.


=head3 otherprops :lvalue

Attribute B<otherprops> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.  Use B<otherpropsX()> to return B<q()> rather than B<undef>.


=head3 outputclass :lvalue

Attribute B<outputclass> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>. Use B<outputclassX()> to return B<q()> rather than B<undef>.


=head3 props :lvalue

Attribute B<props> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.       Use B<propsX()> to return B<q()> rather than B<undef>.


=head3 style :lvalue

Attribute B<style> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.       Use B<styleX()> to return B<q()> rather than B<undef>.


=head3 type :lvalue

Attribute B<type> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.        Use B<typeX()> to return B<q()> rather than B<undef>.


=head2 Get or Set Attributes

Get or set the attributes of nodes.

=head3 attr($$)

Return the value of an attribute of the current node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

     Parameter   Description
  1  $node       Node in parse tree
  2  $attribute  Attribute name.

Example:


   {my $x = Data::Edit::Xml::new(my $s = <<END);                                  
  <a number="1"/>
  END
  
    ok $x->attr(qq(number)) == 1;                                                 
  
       $x->attr(qq(number))  = 2;                                                 
  
    ok $x->attr(qq(number)) == 2;                                                 
  
    ok -s $x eq '<a number="2"/>';                                                
  

=head3 set($%)

Set the values of some attributes in a node and return the node. Identical in effect to L<setAttr|/setAttr>.

     Parameter  Description
  1  $node      Node in parse tree
  2  %values    (attribute name=>new value)*

Example:


    ok q(<a a="1" b="1" id="aa"/>) eq -s $a;                                      
  
    $a->set(a=>11, b=>undef, c=>3, d=>4, e=>5);                                   
  
   }                                                                              
  

=head3 setAttr($%)

Set the values of some attributes in a node and return the node. Identical in effect to L<set|/set>.

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
  

=head3 attrCount($@)

Return the number of attributes in the specified B<$node>, optionally ignoring the specified names from the count.

     Parameter  Description
  1  $node      Node in parse tree
  2  @exclude   Optional attribute names to exclude from the count.

Example:


    ok -s $x eq '<a first="1" number="2" second="2"/>';                               
  
    ok $x->attrCount == 3;                                                        
  
    ok $x->attrCount(qw(first second third)) == 1;                                
  

=head3 getAttrs($)

Return a sorted list of all the attributes on the specified B<$node>.

     Parameter  Description
  1  $node      Node in parse tree.

Example:


    ok -s $x eq '<a first="1" number="2" second="2"/>';                               
  
    is_deeply [$x->getAttrs], [qw(first number second)];                          
  

=head3 deleteAttr($$$)

Delete the named attribute in the specified B<$node>, optionally check its value first, return the node regardless.

     Parameter  Description
  1  $node      Node
  2  $attr      Attribute name
  3  $value     Optional attribute value to check first.

Example:


    ok -s $x eq '<a delete="me" number="2"/>';                                    
  
    $x->deleteAttr(qq(delete));                                                   
  
    ok -s $x eq '<a number="2"/>';                                                 
  

=head3 deleteAttrs($@)

Delete the specified attributes of the specified B<$node> without checking their values and return the node.

     Parameter  Description
  1  $node      Node
  2  @attrs     Names of the attributes to delete

Example:


    ok -s $x eq '<a first="1" number="2" second="2"/>';                               
  
    $x->deleteAttrs(qw(first second third number));                               
  
    ok -s $x eq '<a/>';                                                           
  

=head3 renameAttr($$$)

Change the name of an attribute in the specified B<$node> regardless of whether the new attribute already exists or not and return the node. To prevent inadvertent changes to an existing attribute use L<changeAttr|/changeAttr>.

     Parameter  Description
  1  $node      Node
  2  $old       Existing attribute name
  3  $new       New attribute name.

Example:


    ok $x->printAttributes eq qq( no="1" word="first");                            
  
    $x->renameAttr(qw(no number));                                                
  
    ok $x->printAttributes eq qq( number="1" word="first");                        
  

=head3 changeAttr($$$)

Change the name of an attribute in the specified B<$node> unless it has already been set and return the node. To make changes regardless of whether the new attribute already exists use L<renameAttr|/renameAttr>.

     Parameter  Description
  1  $node      Node
  2  $old       Existing attribute name
  3  $new       New attribute name.

Example:


    ok $x->printAttributes eq qq( number="1" word="first");                        
  
    $x->changeAttr(qw(number word));                                              
  
    ok $x->printAttributes eq qq( number="1" word="first");                        
  

=head3 renameAttrValue($$$$$)

Change the name and value of an attribute in the specified B<$node> regardless of whether the new attribute already exists or not and return the node. To prevent inadvertent changes to existing attributes use L<changeAttrValue|/changeAttrValue>.

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

Change the name and value of an attribute in the specified B<$node> unless it has already been set and return the node.  To make changes regardless of whether the new attribute already exists use L<renameAttrValue|/renameAttrValue>.

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
  
    $x->changeAttrValue(qw(word first greek mono));                               
  
    ok $x->printAttributes eq qq( greek="mono" numeral="I");                      
  

=head3 changeAttributeValue($$$@)

Apply a sub to the value of an attribute of the specified B<$node>.  The value to be changed is supplied and returned in: L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter   Description
  1  $node       Node
  2  $attribute  Attribute name
  3  $sub        Change sub
  4  @context    Optional context;

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a aa="abc"/>
  END
  
    $a->changeAttributeValue(q(aa), sub{s(b) (B)});                               
  
    ok -p $a eq <<END;                                                            
  <a aa="aBc"/>
  END
  

=head3 copyAttrs($$@)

Copy all the attributes of the source node to the target node, or, just the named attributes if the optional list of attributes to copy is supplied, overwriting any existing attributes in the target node and return the source node.

     Parameter  Description
  1  $source    Source node
  2  $target    Target node
  3  @attr      Optional list of attributes to copy

Example:


   {my $x = Data::Edit::Xml::new(<<END);                                           
  <x>
    <a a="1" b="2"/>
    <b b="3" c="4"/>
    <c/>
  </x>
  END
  
    my ($a, $b, $c) = $x->contents;                                                
  
    $a->copyAttrs($b, qw(aa bb));                                                 
  
    ok <<END eq -p $x;                                                            
  <x>
    <a a="1" b="2"/>
    <b b="3" c="4"/>
    <c/>
  </x>
  END
  
    $a->copyAttrs($b);                                                            
  
    ok <<END eq -p $x;                                                            
  <x>
    <a a="1" b="2"/>
    <b a="1" b="2" c="4"/>
    <c/>
  </x>
  END
  

=head3 copyNewAttrs($$@)

Copy all the attributes of the source node to the target node, or, just the named attributes if the optional list of attributes to copy is supplied, without overwriting any existing attributes in the target node and return the source node.

     Parameter  Description
  1  $source    Source node
  2  $target    Target node
  3  @attr      Optional list of attributes to copy

Example:


   {my $x = Data::Edit::Xml::new(<<END);                                           
  <x>
    <a a="1" b="2"/>
    <b b="3" c="4"/>
    <c/>
  </x>
  END
  
    my ($a, $b, $c) = $x->contents;                                                
  
    $a->copyNewAttrs($b, qw(aa bb));                                              
  
    ok <<END eq -p $x;                                                            
  <x>
    <a a="1" b="2"/>
    <b b="3" c="4"/>
    <c/>
  </x>
  END
  
    $a->copyNewAttrs($b);                                                         
  
    ok <<END eq -p $x;                                                            
  <x>
    <a a="1" b="2"/>
    <b a="1" b="3" c="4"/>
    <c/>
  </x>
  END
  

=head3 moveAttrs($$@)

Move all the attributes of the source node to the target node, or, just the named attributes if the optional list of attributes to move is supplied, overwriting any existing attributes in the target node and return the source node.

     Parameter  Description
  1  $source    Source node
  2  $target    Target node
  3  @attr      Attributes to move

Example:


   {my $x = Data::Edit::Xml::new(<<END);                                           
  <x>
    <a a="1" b="2"/>
    <b b="3" c="4"/>
    <c/>
  </x>
  END
  
    my ($a, $b, $c) = $x->contents;                                                
  
    $a->moveAttrs($c, qw(aa bb));                                                 
  
    ok <<END eq -p $x;                                                            
  <x>
    <a a="1" b="2"/>
    <b a="1" b="2" c="4"/>
    <c/>
  </x>
  END
  
    $b->moveAttrs($c);                                                            
  
    ok <<END eq -p $x;                                                            
  <x>
    <a a="1" b="2"/>
    <b/>
    <c a="1" b="2" c="4"/>
  </x>
  END
  

=head3 moveNewAttrs($$@)

Move all the attributes of the source node to the target node, or, just the named attributes if the optional list of attributes to copy is supplied, without overwriting any existing attributes in the target node and return the source node.

     Parameter  Description
  1  $source    Source node
  2  $target    Target node
  3  @attr      Optional list of attributes to move

Example:


   {my $x = Data::Edit::Xml::new(<<END);                                           
  <x>
    <a a="1" b="2"/>
    <b b="3" c="4"/>
    <c/>
  </x>
  END
  
    my ($a, $b, $c) = $x->contents;                                                
  
    $b->moveNewAttrs($c, qw(aa bb));                                              
  
    ok <<END eq -p $x;                                                            
  <x>
    <a a="1" b="2"/>
    <b a="1" b="3" c="4"/>
    <c/>
  </x>
  END
  
    $b->moveNewAttrs($c);                                                         
  
    ok <<END eq -p $x;                                                             
  <x>
    <a a="1" b="2"/>
    <b/>
    <c a="1" b="3" c="4"/>
  </x>
  END
  
    ok <<END eq -p $x;                                                             
  <x>
    <c a="1" b="3" c="4"/>
    <b/>
    <a a="1" b="2"/>
  </x>
  END
  

=head1 Traversal

Traverse the L<parse|/parse> tree in various orders applying a B<sub> to each node.

=head2 Post-order

This order allows you to edit children before their parents.

=head3 by($$@)

Post-order traversal of a L<parse|/parse> tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. A reference to the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>. This is equivalent to the L<x=|/opBy> operator.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context.

Example:


    ok -p $a eq <<END;                                                            #tdown #tdownX               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
     {my $s; $a->by(sub{$s .= $_->tag}); ok $s eq "cbeda"                         
  

=head3 byX($$)

Post-order traversal of a L<parse|/parse> tree calling the specified B<sub> at each node as long as this sub does not L<die|http://perldoc.perl.org/functions/die.html>. The traversal is halted if the called sub does  L<die> on any call with the reason in L<?@|http://perldoc.perl.org/perlvar.html#Error-Variables> The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry> up to the node on which this sub was called. A reference to the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

Returns the start node regardless of the outcome of calling B<sub>.

     Parameter  Description
  1  $node      Start node
  2  $sub       Sub to call

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


    ok -p $a eq <<END;                                                            #tdown #tdownX               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
     {my $s; $a->byX(sub{$s .= $_->tag}); ok $s eq "cbeda"                        
  
  sub byX($$)                                                                    
   {my ($node, $sub) = @_;                                                        # Start node, sub to call
    eval {$node->byX2($sub)};                                                     # Trap any errors that occur
    $node
   }
  

=head3 byList($@)

Return a list of all the nodes at and below a specified B<$node> in pre-order or the empty list if the B<$node> is not in the optional context.

     Parameter  Description
  1  $node      Starting node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
    ok -c $e eq q(e d a);                                                          
  

=head3 byReverse($$@)

Reverse post-order traversal of a L<parse|/parse> tree or sub tree calling the specified B<sub> at each node and returning the specified starting B<$node>. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context.

Example:


    ok -p $a eq <<END;                                                            #tdown #tdownX               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
     {my $s; $a->byReverse(sub{$s .= $_->tag}); ok $s eq "edcba"                   
  

=head3 byReverseX($$@)

Reverse post-order traversal of a L<parse|/parse> tree or sub tree below the specified B<$node> calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting B<$node>. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context.

Example:


    ok -p $a eq <<END;                                                            #tdown #tdownX               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
     {my $s; $a->byReverse(sub{$s .= $_->tag}); ok $s eq "edcba"                   
  

=head3 byReverseList($@)

Return a list of all the nodes at and below a specified B<$node> in reverse preorder or the empty list if the specified B<$node> is not in the optional context.

     Parameter  Description
  1  $node      Starting node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
      my ($E, $D, $C, $B) = $a->byReverseList;                                    
  
      ok -A $C eq q(c id="42" match="mm");                                        
  

=head2 Pre-order

This order allows you to edit children after their parents

=head3 down($$@)

Pre-order traversal down through a L<parse|/parse> tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context.

Example:


     {my $s; $a->down(sub{$s .= $_->tag}); ok $s eq "abcde"                        
  

=head3 downX($$)

Pre-order traversal of a L<parse|/parse> tree calling the specified B<sub> at each node as long as this sub does not L<die|http://perldoc.perl.org/functions/die.html>. The traversal is halted if the called sub does  L<die> on any call with the reason in L<?@|http://perldoc.perl.org/perlvar.html#Error-Variables> The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry> up to the node on which this sub was called. A reference to the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

Returns the start node regardless of the outcome of calling B<sub>.

     Parameter  Description
  1  $node      Start node
  2  $sub       Sub to call

Example:


     {my $s; $a->down(sub{$s .= $_->tag}); ok $s eq "abcde"                        
  
  sub downX($$)                                                                  
   {my ($node, $sub) = @_;                                                        # Start node, sub to call
    eval {$node->downX2($sub)};                                                   # Trap any errors that occur
    $node
   }
  

=head3 downReverse($$@)

Reverse pre-order traversal down through a L<parse|/parse> tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context.

Example:


    ok -p $a eq <<END;                                                            #tdown #tdownX               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
     {my $s; $a->downReverse(sub{$s .= $_->tag}); ok $s eq "adebc"                 
  

=head3 downReverseX($$@)

Reverse pre-order traversal down through a L<parse|/parse> tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context.

Example:


    ok -p $a eq <<END;                                                            #tdown #tdownX               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
     {my $s; $a->downReverse(sub{$s .= $_->tag}); ok $s eq "adebc"                 
  

=head2 Pre and Post order

Visit the parent first, then the children, then the parent again.

=head3 through($$$@)

Traverse L<parse|/parse> tree visiting each node twice calling the specified B<sub> at each node and returning the specified starting node. The B<sub>s are passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $before    Sub to call when we meet a node
  3  $after     Sub to call we leave a node
  4  @context   Accumulated context.

Example:


     {my $s; my $n = sub{$s .= $_->tag}; $a->through($n, $n);                      
  
      ok $s eq "abccbdeeda"                                                        
  

=head3 throughX($$$@)

Traverse L<parse|/parse> tree visiting each node twice calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $before    Sub to call when we meet a node
  3  $after     Sub to call we leave a node
  4  @context   Accumulated context.

Example:


     {my $s; my $n = sub{$s .= $_->tag}; $a->through($n, $n);                      
  
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
  
     {my ($d, $c, $D) = $a->findByNumbers(5, 7, 10);                                
  
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
  
     {my ($d, $c, $D) = $a->findByNumbers(5, 7, 10);                                
  
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
  
     {my ($d, $c, $D) = $a->findByNumbers(5, 7, 10);                                
  
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

Confirm that the specified B<$node> has the specified L<ancestry|/ancestry> and return the specified B<$node> if it does else B<undef>. Ancestry is specified by providing the expected tags that the B<$node>'s parent, the parent's parent etc. must match at each level. If B<undef> is specified then any tag is assumed to match at that level. If a regular expression is specified then the current parent node tag must match the regular expression at that level. If all supplied tags match successfully then the starting node is returned else B<undef>

     Parameter  Description
  1  $start     Starting node
  2  @context   Ancestry.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
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
  

=head2 not($@)

Return the specified B<$node> if it does not match any of the specified tags, else B<undef>

     Parameter  Description
  1  $node      Node
  2  @tags      Tags not to match

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b/>
  </a>
  END
  
    ok $a->first->not_a_c;                                                        
  

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
  

=head2 adjacent($$)

Return the first node if it is adjacent to the second node else B<undef>.

     Parameter  Description
  1  $first     First node
  2  $second    Second node

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <b>
      <c/>
    </b>
    <e>
      <f/>
    </e>
  </a>
  END
  
    my ($d, $c, $b, $C, $B, $f, $e) = $a->byList;                                              
  
    ok !$a->adjacent($B);                                                         
  
    ok  $b->adjacent($B);                                                         
  

=head2 ancestry($)

Return a list containing: (the specified B<$node>, its parent, its parent's parent etc..). Or use L<upn|/upn> to go up the specified number of levels.

     Parameter  Description
  1  $node      Starting node.

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
  1  $node      Starting node.

Example:


    ok -p $a eq <<END;                                                            #tdown #tdownX               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
    ok $a->go(qw(d e))->context eq 'e d a';                                       
  

=head2 containsSingleText($@)

Return the single text element below the specified B<$node> else return B<undef>.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new("<a><b>bb</b><c>cc<d/>ee</c></a>");              
  
    ok  $a->go(q(b))->containsSingleText->text eq q(bb);                          
  
    ok !$a->go(q(c))->containsSingleText;                                         
  

=head2 depth($)

Returns the depth of the specified B<$node>, the  depth of a root node is zero.

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

Return the specified B<$node> if it is first under its parent and optionally has the specified context, else return B<undef>

     Parameter  Description
  1  $node      Node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.

Use B<isFirstNonBlank> to skip a (rare) initial blank text CDATA. Use B<isFirstNonBlankX> to die rather
then receive a returned B<undef> or false result.



Example:


    ok -p $a eq <<END;                                                            #tdown #tdownX               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
    ok $a->go(q(b))->isFirst;                                                     
  
   {my $a = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <b>
      <c/>
    </b>
    <e>
      <f/>
    </e>
  </a>
  END
  
    my ($d, $c, $b, $C, $B, $f, $e) = $a->byList;                                              
  
    ok  $a->isFirst;                                                              
  

=head2 isFirstToDepth($$@)

Return the specified B<$node> if it is first to the specified depth else return B<undef>

     Parameter  Description
  1  $node      Node
  2  $depth     Depth
  3  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                              
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <e>
      <f/>
    </e>
  </a>
  END
  
    my ($d, $c, $b, $f, $e) = $a->byList;                                             
  
    ok  $d->isFirstToDepth(4);                                                    
  
    ok !$f->isFirstToDepth(2);                                                    
  
    ok  $f->isFirstToDepth(1);                                                    
  
    ok !$f->isFirstToDepth(3);                                                    
  

=head2 isLast($@)

Return the specified B<$node> if it is last under its parent and optionally has the specified context, else return B<undef>

     Parameter  Description
  1  $node      Node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.

Use B<isLastNonBlank> to skip a (rare) initial blank text CDATA. Use B<isLastNonBlankX> to die rather
then receive a returned B<undef> or false result.



Example:


    ok -p $a eq <<END;                                                            #tdown #tdownX               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
    ok $a->go(q(d))->isLast;                                                      
  
   {my $a = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <b>
      <c/>
    </b>
    <e>
      <f/>
    </e>
  </a>
  END
  
    my ($d, $c, $b, $C, $B, $f, $e) = $a->byList;                                              
  
    ok  $a->isLast;                                                               
  

=head2 isLastToDepth($$@)

Return the specified B<$node> if it is last to the specified depth else return B<undef>

     Parameter  Description
  1  $node      Node
  2  $depth     Depth
  3  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                              
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <e>
      <f/>
    </e>
  </a>
  END
  
    my ($d, $c, $b, $f, $e) = $a->byList;                                             
  
    ok  $c->isLastToDepth(1);                                                     
  
    ok !$c->isLastToDepth(3);                                                     
  
    ok  $d->isLastToDepth(2);                                                     
  
    ok !$d->isLastToDepth(4);                                                     
  

=head2 isOnlyChild($@)

Return the specified B<$node> if it is the only node under its parent ignoring any surrounding blank text.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                              
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <e>
      <f/>
    </e>
  </a>
  END
  
    my ($d, $c, $b, $f, $e) = $a->byList;                                             
  
    ok  $d->isOnlyChild;                                                          
  
    ok !$d->isOnlyChild(qw(b));                                                   
  
   {my $a = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <b>
      <c/>
    </b>
    <e>
      <f/>
    </e>
  </a>
  END
  
    my ($d, $c, $b, $C, $B, $f, $e) = $a->byList;                                              
  
    ok  $a->isOnlyChild;                                                          
  

=head2 isOnlyChildToDepth($$@)

Return the specified B<$node> if it and its ancestors are L<only children|/isOnlyChild> to the specified depth else return B<undef>. isOnlyChildToDepth(1) is the same as L<isOnlychild|/isOnlyChild>

     Parameter  Description
  1  $node      Node
  2  $depth     Depth to which each parent node must also be an only child
  3  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                              
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <e>
      <f/>
    </e>
  </a>
  END
  
    my ($d, $c, $b, $f, $e) = $a->byList;                                             
  
    ok  $d->isOnlyChildToDepth(1, qw(d c b a));                                   
  
    ok  $d->isOnlyChildToDepth(2, qw(d c b a));                                   
  
    ok !$d->isOnlyChildToDepth(3, qw(d c b a));                                   
  

=head2 hasSingleChild($@)

Return the only child of the specified B<$node> if the child is the only node under its parent ignoring any surrounding blank text and has the  optional specified context, else return B<undef>.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                           
  <a>
    <b   id="b" b="bb">
      <b id="c" c="cc"/>
    </b>
  </a>
  END
  
    my ($c, $b) = $a->byList;                                                      
  
    is_deeply [$b->id, $c->id], [qw(b c)];                                         
  
    ok $c == $b->hasSingleChild;                                                      
  
    ok $b == $a->hasSingleChild;                                                      
  

=head2 hasSingleChildToDepth($$@)

Return the specified B<$node> if it has single children to at least the specified depth else return B<undef>.  L<hasSingleChildToDepth(0)|/hasSingleChildToDepth> is equivalent to L<hasSingleChild|/hasSingleChild>.

     Parameter  Description
  1  $node      Node
  2  $depth     Depth
  3  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                      
  <a>
    <b>
      <c/>
      <d/>
      <e>
        <j/>
      </e>
      <f/>
    </b>
    <g>
      <h>
        <i>
          <k/>
          <l/>
        </i>
      </h>
    </g>
  </a>
  END
  
    my ($c, $d, $j, $e, $f, $b, $k, $l, $i, $h, $g) = $a->byList;                             
  
    ok $h == $g->hasSingleChildToDepth(1);                                        
  
    ok $i == $g->hasSingleChildToDepth(2);                                        
  
    ok      !$g->hasSingleChildToDepth(0);                                        
  
    ok      !$g->hasSingleChildToDepth(3);                                        
  
    ok $i == $i->hasSingleChildToDepth(0);                                        
  

=head2 isEmpty($@)

Confirm that the specified B<$node> is empty, that is: the specified B<$node> has no content, not even a blank string of text. To test for blank nodes, see L<isAllBlankText|/isAllBlankText>.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                           
  <a>
  
  </a>
  END
  
    ok $x->isEmpty;                                                               
  
   {my $a = Data::Edit::Xml::new(<<END);                                              
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <e>
      <f/>
    </e>
  </a>
  END
  
    my ($d, $c, $b, $f, $e) = $a->byList;                                             
  
    ok  $d->isEmpty;                                                              
  

=head2 over($$@)

Confirm that the string representing the tags at the level below the specified B<$node> match a regular expression where each pair of tags is separated by a single space. Use L<contentAsTags|/contentAsTags> to visualize the tags at the next level.

     Parameter  Description
  1  $node      Node
  2  $re        Regular expression
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
    ok $x->go(q(b))->over(qr(d.+e));                                              
  

=head2 over2($$@)

Confirm that the string representing the tags at the level below the specified B<$node> match a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a single space and the last tag is followed by a single space.  This arrangement simplifies the regular expression used to detect combinations like p+ q? . Use L<contentAsTags2|/contentAsTags2> to visualize the tags at the next level.

     Parameter  Description
  1  $node      Node
  2  $re        Regular expression
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
    ok $x->go(q(b))->over2(qr(\A c  d  e  f  g \Z));                              
  
    ok $x->go(q(b))->contentAsTags  eq q(c d e f g) ;                             
  

=head2 overAllTags($@)

Return the specified b<$node> if all of it's child nodes L<match|/atPositionMatch> the specified <@tags> else return B<undef>.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags.

Example:


  if (1)                                                                            
   {my $a = Data::Edit::Xml::new(<<END);
  <a>
    <b/>
    <c/>
    <d/>
  </a>
  END
  
    ok  $a->overAllTags_b_c_d;
    ok !$a->overAllTags_b_c;
    ok !$a->overAllTags_b_c_d_e;
    ok  $a->oat_b_c_d;
    ok !$a->oat_B_c_d;
  
    ok  $a->overFirstTags_b_c_d;
    ok  $a->overFirstTags_b_c;
    ok !$a->overFirstTags_b_c_d_e;
    ok  $a->oft_b_c;
    ok !$a->oft_B_c;
  
    ok  $a->overLastTags_b_c_d;
    ok  $a->overLastTags_c_d;
    ok !$a->overLastTags_b_c_d_e;
    ok  $a->olt_c_d;
    ok !$a->olt_C_d;
   }
  

B<oat> is a synonym for L<overAllTags|/overAllTags>.


=head2 overFirstTags($@)

Return the specified b<$node> if the first of it's child nodes L<match|/atPositionMatch> the specified <@tags> else return B<undef>.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags.

Example:


  if (1)                                                                            
   {my $a = Data::Edit::Xml::new(<<END);
  <a>
    <b/>
    <c/>
    <d/>
  </a>
  END
  
    ok  $a->overAllTags_b_c_d;
    ok !$a->overAllTags_b_c;
    ok !$a->overAllTags_b_c_d_e;
    ok  $a->oat_b_c_d;
    ok !$a->oat_B_c_d;
  
    ok  $a->overFirstTags_b_c_d;
    ok  $a->overFirstTags_b_c;
    ok !$a->overFirstTags_b_c_d_e;
    ok  $a->oft_b_c;
    ok !$a->oft_B_c;
  
    ok  $a->overLastTags_b_c_d;
    ok  $a->overLastTags_c_d;
    ok !$a->overLastTags_b_c_d_e;
    ok  $a->olt_c_d;
    ok !$a->olt_C_d;
   }
  

B<oft> is a synonym for L<overFirstTags|/overFirstTags>.


=head2 overLastTags($@)

Return the specified b<$node> if the last of it's child nodes L<match|/atPositionMatch> the specified <@tags> else return B<undef>.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags.

Example:


  if (1)                                                                            
   {my $a = Data::Edit::Xml::new(<<END);
  <a>
    <b/>
    <c/>
    <d/>
  </a>
  END
  
    ok  $a->overAllTags_b_c_d;
    ok !$a->overAllTags_b_c;
    ok !$a->overAllTags_b_c_d_e;
    ok  $a->oat_b_c_d;
    ok !$a->oat_B_c_d;
  
    ok  $a->overFirstTags_b_c_d;
    ok  $a->overFirstTags_b_c;
    ok !$a->overFirstTags_b_c_d_e;
    ok  $a->oft_b_c;
    ok !$a->oft_B_c;
  
    ok  $a->overLastTags_b_c_d;
    ok  $a->overLastTags_c_d;
    ok !$a->overLastTags_b_c_d_e;
    ok  $a->olt_c_d;
    ok !$a->olt_C_d;
   }
  

B<olt> is a synonym for L<overLastTags|/overLastTags>.


=head2 matchAfter($$@)

Confirm that the string representing the tags following the specified B<$node> matches a regular expression where each pair of tags is separated by a single space. Use L<contentAfterAsTags|/contentAfterAsTags> to visualize these tags.

     Parameter  Description
  1  $node      Node
  2  $re        Regular expression
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
    ok $x->go(qw(b e))->matchAfter  (qr(\Af g\Z));                                
  

=head2 matchAfter2($$@)

Confirm that the string representing the tags following the specified B<$node> matches a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a single space and the last tag is followed by a single space.  This arrangement simplifies the regular expression used to detect combinations like p+ q? Use L<contentAfterAsTags2|/contentAfterAsTags2> to visualize these tags.

     Parameter  Description
  1  $node      Node
  2  $re        Regular expression
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
    ok $x->go(qw(b e))->matchAfter2 (qr(\A f  g \Z));                             
  

=head2 matchBefore($$@)

Confirm that the string representing the tags preceding the specified B<$node> matches a regular expression where each pair of tags is separated by a single space. Use L<contentBeforeAsTags|/contentBeforeAsTags> to visualize these tags.

     Parameter  Description
  1  $node      Node
  2  $re        Regular expression
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
    ok $x->go(qw(b e))->matchBefore (qr(\Ac d\Z));                                
  

=head2 matchBefore2($$@)

Confirm that the string representing the tags preceding the specified B<$node> matches a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a single space and the last tag is followed by a single space.  This arrangement simplifies the regular expression used to detect combinations like p+ q?  Use L<contentBeforeAsTags2|/contentBeforeAsTags2> to visualize these tags.

     Parameter  Description
  1  $node      Node
  2  $re        Regular expression
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
    ok $x->go(qw(b e))->matchBefore2(qr(\A c  d \Z));                             
  

=head2 path($)

Return a list representing the path to a node from the root of the parse tree which can then be reused by L<go|/go> to retrieve the node as long as the structure of the L<parse|/parse> tree has not changed along the path.

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

Return a string representing the L<path|/path> to the specified B<$node> from the root of the parse tree.

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
  

=head2 Prev At Next

Locate adjacent nodes that match horizontally and vertically

=head3 an($$@)

Return the next node if the specified B<$node> has the specified tag and the next node is in the specified context.

     Parameter  Description
  1  $node      Node
  2  $tag       Tag node must match
  3  @context   Optional context of the next node.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                      
  <a>
    <b>
      <c/>
      <d/>
      <e>
        <j/>
      </e>
      <f/>
    </b>
    <g>
      <h>
        <i>
          <k/>
          <l/>
        </i>
      </h>
    </g>
  </a>
  END
  
    my ($c, $d, $j, $e, $f, $b, $k, $l, $i, $h, $g) = $a->byList;                             
  
    ok  $e == $d->an_d_e_b_a;                                                     
  
    ok  $f == $e->an_e;                                                           
  
    ok !$f->an_f;                                                                 
  

=head3 ap($$@)

Return the previous node if the specified B<$node> has the specified tag and the previous node is in the specified context.

     Parameter  Description
  1  $node      Node
  2  $tag       Tag node must match
  3  @context   Optional context of the previous node.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                      
  <a>
    <b>
      <c/>
      <d/>
      <e>
        <j/>
      </e>
      <f/>
    </b>
    <g>
      <h>
        <i>
          <k/>
          <l/>
        </i>
      </h>
    </g>
  </a>
  END
  
    my ($c, $d, $j, $e, $f, $b, $k, $l, $i, $h, $g) = $a->byList;                             
  
    ok  $c == $d->ap_d_c_b_a;                                                     
  
    ok  $c == $d->ap_d;                                                           
  
    ok !$c->ap_c;                                                                 
  

=head3 apn($$$@)

Return (previous node, next node) if the previous and current nodes have the specified tags and the next node is in the specified context else return B<()>.

     Parameter  Description
  1  $node      Current node
  2  $prev      Tag for the previous node
  3  $tag       Tag for specified node
  4  @context   Context for the next node.

Use the B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>.  If a context is supplied and
B<$node> is not in this context then this method returns an empty list B<()>
immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                      
  <a>
    <b>
      <c/>
      <d/>
      <e>
        <j/>
      </e>
      <f/>
    </b>
    <g>
      <h>
        <i>
          <k/>
          <l/>
        </i>
      </h>
    </g>
  </a>
  END
  
    my ($c, $d, $j, $e, $f, $b, $k, $l, $i, $h, $g) = $a->byList;                             
  
    is_deeply[$c, $e], [$d->apn_c_d_e_b_a];                                       
  

=head3 matchesNextTags($@)

Return the specified b<$node> if the siblings following the specified B<$node> L<match|/atPositionMatch> the specified <@tags> else return B<undef>.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags.

Example:


  if (1)                                                                           
   {my $a = Data::Edit::Xml::new(<<END);
  <a><b><c/><d/><e/><f/></b></a>
  END
  
    ok  -t $a->first__first__matchesNextTags_d_e eq q(c);
    ok  -t $a->first__first__mnt_d_e             eq q(c);
    ok    !$a->       first__matchesNextTags_d_e;
    ok  -t $a->  last->last__matchesPrevTags_e_d eq q(f);
    ok  -t $a->  last->last__mpt_e_d             eq q(f);
    ok    !$a->        last__matchesPrevTags_e_d;
   }
  

B<mnt> is a synonym for L<matchesNextTags|/matchesNextTags>.


=head3 matchesPrevTags($@)

Return the specified b<$node> if the siblings prior to the specified B<$node> L<match|/atPositionMatch> the specified <@tags> else return B<undef>.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags.

Example:


  if (1)                                                                           
   {my $a = Data::Edit::Xml::new(<<END);
  <a><b><c/><d/><e/><f/></b></a>
  END
  
    ok  -t $a->first__first__matchesNextTags_d_e eq q(c);
    ok  -t $a->first__first__mnt_d_e             eq q(c);
    ok    !$a->       first__matchesNextTags_d_e;
    ok  -t $a->  last->last__matchesPrevTags_e_d eq q(f);
    ok  -t $a->  last->last__mpt_e_d             eq q(f);
    ok    !$a->        last__matchesPrevTags_e_d;
   }
  

B<mpt> is a synonym for L<matchesPrevTags|/matchesPrevTags>.


=head1 Navigation

Move around in the L<parse|/parse> tree.

=head2 go($@)

Return the node reached from the specified B<$node> via the specified L<path|/path>: (index positionB<?>)B<*> where index is the tag of the next node to be chosen and position is the optional zero based position within the index of those tags under the current node. Position defaults to zero if not specified. Position can also be negative to index back from the top of the index array. B<*> can be used as the last position to retrieve all nodes with the final tag.

     Parameter  Description
  1  $node      Node
  2  @path      Search specification.

Example:


   {my $x = Data::Edit::Xml::new(my $s = <<END);                                   
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
  

=head2 c($$)

Return an array of all the nodes with the specified tag below the specified B<$node>. This method is deprecated in favor of applying L<grep|https://perldoc.perl.org/functions/grep.html> to L<contents|/contents>.

     Parameter  Description
  1  $node      Node
  2  $tag       Tag.

Example:


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
  
    is_deeply [map{-u $_} $x->c(q(d))],  [qw(d1 d2)];                             
  

=head2 First

Find nodes that are first amongst their siblings.

=head3 first($@)

Return the first node below the specified B<$node> optionally checking its context.  See L<addFirst|/addFirst> to ensure that an expected node is in position.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.

Use B<firstNonBlank> to skip a (rare) initial blank text CDATA. Use B<firstNonBlankX> to die rather
then receive a returned B<undef> or false result.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                   
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
  

=head3 firstn($$@)

Return the B<$n>'th first node below the specified B<$node> optionally checking its context or B<undef> if there is no such node.  B<firstn(1)> is identical in effect to L<first|/first>.

     Parameter  Description
  1  $node      Node
  2  $N         Number of times to go first
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


  if (1)                                                                           
   {my $a = Data::Edit::Xml::new(<<END);
  <a><b><c><d/><e/><f/></c></b></a>
  END
    ok -p $a eq <<END;
  <a>
    <b>
      <c>
        <d/>
        <e/>
        <f/>
      </c>
    </b>
  </a>
  END
    ok  -t $a->firstn_0 eq q(a);
    ok  -t $a->firstn_1 eq q(b);
    ok  -t $a->firstn_2 eq q(c);
    ok  -t $a->firstn_3 eq q(d);
  
    ok  -t $a->firstn_3__nextn_0 eq q(d);
    ok  -t $a->firstn_3__nextn_1 eq q(e);
    ok  -t $a->firstn_3__nextn_2 eq q(f);
   }
  

=head3 firstText($@)

Return the first node if it is a text node otherwise B<undef>

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head3 firstTextMatches($$@)

Return the first node under the specified B<$node> if: it is a text mode; its text matches the specified regular expression; the specified B<$node> is in the optional specified context. Else return B<undef>.

     Parameter  Description
  1  $node      Node
  2  $match     Regular expression the text must match
  3  @context   Optional context of specified node.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                              
  <a>
    <b>bb<c>cc</c>BB
    </b>
  </a>
  END
  
    my ($bb, $cc, $c, $BB, $b) = $a->byList;                                       
  
    ok $bb->matchesText(qr(bb));                                                  
  
    ok $b->at_b_a &&  $b->firstTextMatches(qr(bb));                               
  
    ok                $b->firstTextMatches(qr(bb), qw(b a));                      
  
    ok $c->at_c_b &&  $c->firstTextMatches(qr(cc));                               
  
    ok $c->at_c_b && !$c->firstTextMatches(qr(bb));                               
  

=head3 firstBy($@)

Return a list of the first instance of each specified tag encountered in a post-order traversal from the specified B<$node> or a hash of all first instances if no tags are specified.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags to search for.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                   
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
  
     {my %f = $a->firstBy;                                                        
  
      ok $f{b}->id == 12;                                                         
  

=head3 firstDown($@)

Return a list of the first instance of each specified tag encountered in a pre-order traversal from the specified B<$node> or a hash of all first instances if no tags are specified.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags to search for.

Example:


     {my %f = $a->firstDown;                                                      
  
      ok $f{b}->id == 15;                                                         
  

=head3 firstIn($@)

Return the first child node matching one of the named tags under the specified parent node.

     Parameter  Description
  1  $node      Parent node
  2  @tags      Child tags to search for.

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
  

=head3 firstNot($@)

Return the first child node that does not match any of the named B<@tags> under the specified parent B<$node>. Return B<undef> if there is no such child node.

     Parameter  Description
  1  $node      Parent node
  2  @tags      Child tags to avoid.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                 
  <a>
    <b/>
    <c/>
    <d/>
    <e/>
    <f/>
  </a>
  END
  
    my ($b, $c, $d, $e, $f) = $a->byList;                                                
  
    ok $c == $a->firstNot_a_b;                                                    
  

=head3 firstInIndex($@)

Return the specified B<$node> if it is first in its index and optionally L<at|/at> the specified context else B<undef>

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head3 firstOf($@)

Return an array of the nodes that are continuously first under their specified parent node and that match the specified list of tags.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags to search for.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                           
  <a><b><c/><d/><d/><e/><d/><d/><c/></b></a>
  END
  
    is_deeply [qw(c d d)], [map {-t $_} $a->go(q(b))->firstOf(qw(c d))];          
  

=head3 firstWhile($@)

Go first from the specified B<$node> and continue deeper as long as each first child node matches one of the specified B<@tags>. Return the deepest such node encountered or else return B<undef> if no such node is encountered.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags to search for.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                             
  <a><b><c><d><e><f/>
  </e></d></c></b>
  <B><C><D><E><F/>
  </E></D></C></B></a>
  END
  
    my ($f, $e, $d, $c, $b, $F, $E, $D, $C, $B) = $a->byList;                        
  
    if (1)                                                                         
  

=head3 firstUntil($@)

Go first from the specified B<$node> and continue deeper until a first child node matches the specified B<@context> or return B<undef> if there is no such node.  Return the first child of the specified B<$node> if no B<@context> is specified.

     Parameter  Description
  1  $node      Node
  2  @context   Context to search for.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                             
  <a><b><c><d><e><f/>
  </e></d></c></b>
  <B><C><D><E><F/>
  </E></D></C></B></a>
  END
  
    my ($f, $e, $d, $c, $b, $F, $E, $D, $C, $B) = $a->byList;                        
  
    if (1)                                                                         
  

=head3 firstContextOf($@)

Return the first node encountered in the specified context in a depth first post-order traversal of the L<parse|/parse> tree.

     Parameter  Description
  1  $node      Node
  2  @context   Array of tags specifying context.

Example:


   {my $x = Data::Edit::Xml::new(<<END);                                           
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
  

=head3 firstSibling($@)

Return the first sibling of the specified B<$node> in the optional context else B<undef>

     Parameter  Description
  1  $node      Node
  2  @context   Array of tags specifying context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                   
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
  
    ok  $a->go(qw(b b))->firstSibling->id == 13;                                   
  

=head2 Last

Find nodes that are last amongst their siblings.

=head3 last($@)

Return the last node below the specified B<$node> optionally checking its context. See L<addLast|/addLast> to ensure that an expected node is in position.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.

Use B<lastNonBlank> to skip a (rare) initial blank text CDATA. Use B<lastNonBlankX> to die rather
then receive a returned B<undef> or false result.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                   
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
  

=head3 lastn($$@)

Return the B<$n>'th last node below the specified B<$node> optionally checking its context or B<undef> if there is no such node.  B<lastn(1)> is identical in effect to L<last|/last>.

     Parameter  Description
  1  $node      Node
  2  $N         Number of times to go last
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


  if (1)                                                                           
   {my $a = Data::Edit::Xml::new(<<END);
  <a><b><c><d/><e/><f/></c></b>
     <B><C><D/><E/><F/></C></B></a>
  END
    ok -p $a eq <<END;
  <a>
    <b>
      <c>
        <d/>
        <e/>
        <f/>
      </c>
    </b>
    <B>
      <C>
        <D/>
        <E/>
        <F/>
      </C>
    </B>
  </a>
  END
  
    ok  -t $a->lastn_0 eq q(a);
    ok  -t $a->lastn_1 eq q(B);
    ok  -t $a->lastn_2 eq q(C);
    ok  -t $a->lastn_3 eq q(F);
  
    ok  -t $a->lastn_3__prevn_0 eq q(F);
    ok  -t $a->lastn_3__prevn_1 eq q(E);
    ok  -t $a->lastn_3__prevn_2 eq q(D);
   }
  

=head3 lastText($@)

Return the last node if it is a text node otherwise B<undef>

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head3 lastTextMatches($$@)

Return the last node under the specified B<$node> if: it is a text mode; its text matches the specified regular expression; the specified B<$node> is in the optional specified context. Else return B<undef>.

     Parameter  Description
  1  $node      Node
  2  $match     Regular expression the text must match
  3  @context   Optional context of specified  node.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                              
  <a>
    <b>bb<c>cc</c>BB
    </b>
  </a>
  END
  
    my ($bb, $cc, $c, $BB, $b) = $a->byList;                                       
  
    ok $BB->matchesText(qr(BB));                                                  
  
    ok $b->at_b_a &&  $b->lastTextMatches(qr(BB));                                
  
    ok                $b->lastTextMatches(qr(BB), qw(b a));                       
  
    ok $c->at_c_b &&  $c->lastTextMatches(qr(cc));                                
  
    ok $c->at_c_b && !$c->lastTextMatches(qr(bb));                                
  

=head3 lastBy($@)

Return a list of the last instance of each specified tag encountered in a post-order traversal from the specified B<$node> or a hash of all last instances if no tags are specified.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags to search for.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                   
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
  
     {my %l = $a->lastBy;                                                         
  
      ok $l{b}->id == 23;                                                         
  

=head3 lastDown($@)

Return a list of the last instance of each specified tag encountered in a pre-order traversal from the specified B<$node> or a hash of all last instances if no tags are specified.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags to search for.

Example:


     {my %l = $a->lastDown;                                                       
  
      ok $l{b}->id == 26;                                                         
  

=head3 lastIn($@)

Return the last child node matching one of the named tags under the specified parent node.

     Parameter  Description
  1  $node      Parent node
  2  @tags      Child tags to search for.

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
  

=head3 lastNot($@)

Return the last child node that does not match any of the named B<@tags> under the specified parent B<$node>. Return B<undef> if there is no such child node.

     Parameter  Description
  1  $node      Parent node
  2  @tags      Child tags to avoid.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                 
  <a>
    <b/>
    <c/>
    <d/>
    <e/>
    <f/>
  </a>
  END
  
    my ($b, $c, $d, $e, $f) = $a->byList;                                                
  
    ok $d == $a->lastNot_e_f;                                                     
  

=head3 lastOf($@)

Return an array of the nodes that are continuously last under their specified parent node and that match the specified list of tags.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags to search for.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                           
  <a><b><c/><d/><d/><e/><d/><d/><c/></b></a>
  END
  
    is_deeply [qw(d d c)], [map {-t $_} $a->go(q(b))->lastOf (qw(c d))];          
  

=head3 lastInIndex($@)

Return the specified B<$node> if it is last in its index and optionally L<at|/at> the specified context else B<undef>

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head3 lastContextOf($@)

Return the last node encountered in the specified context in a depth first reverse pre-order traversal of the L<parse|/parse> tree.

     Parameter  Description
  1  $node      Node
  2  @context   Array of tags specifying context.

Example:


   {my $x = Data::Edit::Xml::new(<<END);                                           
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
  

=head3 lastSibling($@)

Return the last sibling of the specified B<$node> in the optional context else B<undef>

     Parameter  Description
  1  $node      Node
  2  @context   Array of tags specifying context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                   
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
  
    ok  $a->go(qw(b b))->lastSibling ->id == 22;                                   
  

=head3 lastWhile($@)

Go last from the specified B<$node> and continue deeper as long as each last child node matches one of the specified B<@tags>. Return the deepest such node encountered or else return B<undef> if no such node is encountered.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags to search for.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                             
  <a><b><c><d><e><f/>
  </e></d></c></b>
  <B><C><D><E><F/>
  </E></D></C></B></a>
  END
  
    my ($f, $e, $d, $c, $b, $F, $E, $D, $C, $B) = $a->byList;                        
  
    if (1)                                                                         
  

=head3 lastUntil($@)

Go last from the specified B<$node> and continue deeper until a last child node matches the specified B<@context> or return B<undef> if there is no such node.  Return the last child of the specified B<$node> if no B<@context> is specified.

     Parameter  Description
  1  $node      Node
  2  @context   Context to search for.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                             
  <a><b><c><d><e><f/>
  </e></d></c></b>
  <B><C><D><E><F/>
  </E></D></C></B></a>
  END
  
    my ($f, $e, $d, $c, $b, $F, $E, $D, $C, $B) = $a->byList;                        
  
    if (1)                                                                         
  

=head2 Next

Find sibling nodes after the specified B<$node>.

=head3 next($@)

Return the node next to the specified B<$node>, optionally checking its context. See L<addNext|/addNext> to ensure that an expected node is in position.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.

Use B<nextNonBlank> to skip a (rare) initial blank text CDATA. Use B<nextNonBlankX> to die rather
then receive a returned B<undef> or false result.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                   
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
  

=head3 nextn($$@)

Return the B<$n>'th next node after the specified B<$node> optionally checking its context or B<undef> if there is no such node.  B<nextn(1)> is identical in effect to L<next|/next>.

     Parameter  Description
  1  $node      Node
  2  $N         Number of times to go next
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


  if (1)                                                                           
   {my $a = Data::Edit::Xml::new(<<END);
  <a><b><c><d/><e/><f/></c></b></a>
  END
    ok -p $a eq <<END;
  <a>
    <b>
      <c>
        <d/>
        <e/>
        <f/>
      </c>
    </b>
  </a>
  END
    ok  -t $a->firstn_0 eq q(a);
    ok  -t $a->firstn_1 eq q(b);
    ok  -t $a->firstn_2 eq q(c);
    ok  -t $a->firstn_3 eq q(d);
  
    ok  -t $a->firstn_3__nextn_0 eq q(d);
    ok  -t $a->firstn_3__nextn_1 eq q(e);
    ok  -t $a->firstn_3__nextn_2 eq q(f);
   }
  

=head3 nextText($@)

Return the next node after the specified B<$node> if it is a text node otherwise B<undef>

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head3 nextTextMatches($$@)

Return the next node to the specified B<$node> if: it is a text mode; its text matches the specified regular expression; the specified B<$node> is in the optional specified context. Else return B<undef>.

     Parameter  Description
  1  $node      Node
  2  $match     Regular expression the text must match
  3  @context   Optional context of specified node.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                              
  <a>
    <b>bb<c>cc</c>BB
    </b>
  </a>
  END
  
    ok $cc->matchesText(qr(cc));                                                   
  
    ok $c->at_c_b &&  $c->nextTextMatches(qr(BB));                                
  
    ok $b->at_b   && !$b->nextTextMatches(qr(BB));                                
  

=head3 nextIn($@)

Return the nearest sibling after the specified B<$node> that matches one of the named tags or B<undef> if there is no such sibling node.

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
  

=head3 nextOn($@)

Step forwards as far as possible from the specified B<$node> while remaining on nodes with the specified tags. In scalar context return the last such node reached or the starting node if no such steps are possible. In array context return the start node and any following matching nodes.

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
  
    ok $c->nextOn(qw(d))  ->id == 2;                                              
  
    ok $c->nextOn(qw(c d))->id == 4;                                              
  
    ok $e->nextOn(qw(c d))     == $e;                                             
  

=head3 nextWhile($@)

Go to the next sibling of the specified B<$node> and continue forwards while the tag of each sibling node matches one of the specified B<@tags>. Return the first sibling node that does not match else B<undef> if there is no such sibling.

     Parameter  Description
  1  $node      Node
  2  @tags      Child tags to avoid.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                 
  <a>
    <b/>
    <c/>
    <d/>
    <e/>
    <f/>
  </a>
  END
  
    my ($b, $c, $d, $e, $f) = $a->byList;                                                
  
    ok $e == $b->nextWhile_c_d;                                                   
  
    ok $c == $b->nextWhile;                                                       
  

=head3 nextUntil($@)

Go to the next sibling of the specified B<$node> and continue forwards until the tag of a sibling node matches one of the specified B<@tags>. Return the matching sibling node else B<undef> if there is no such sibling node.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags to look for.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                 
  <a>
    <b/>
    <c/>
    <d/>
    <e/>
    <f/>
  </a>
  END
  
    my ($b, $c, $d, $e, $f) = $a->byList;                                                
  
    ok $e == $b->nextUntil_e_f;                                                   
  
    ok      !$b->nextUntil;                                                       
  

=head2 Prev

Find sibling nodes before the specified B<$node>.

=head3 prev($@)

Return the node before the specified B<$node>, optionally checking its context. See L<addLast|/addLast> to ensure that an expected node is in position.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.

Use B<prevNonBlank> to skip a (rare) initial blank text CDATA. Use B<prevNonBlankX> to die rather
then receive a returned B<undef> or false result.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                   
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
  

=head3 prevText($@)

Return the previous node if it is a text node otherwise B<undef>

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head3 prevn($$@)

Return the B<$n>'th previous node after the specified B<$node> optionally checking its context or B<undef> if there is no such node.  B<prevn(1)> is identical in effect to L<prev|/prev>.

     Parameter  Description
  1  $node      Node
  2  $N         Number of times to go prev
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


  if (1)                                                                           
   {my $a = Data::Edit::Xml::new(<<END);
  <a><b><c><d/><e/><f/></c></b>
     <B><C><D/><E/><F/></C></B></a>
  END
    ok -p $a eq <<END;
  <a>
    <b>
      <c>
        <d/>
        <e/>
        <f/>
      </c>
    </b>
    <B>
      <C>
        <D/>
        <E/>
        <F/>
      </C>
    </B>
  </a>
  END
  
    ok  -t $a->lastn_0 eq q(a);
    ok  -t $a->lastn_1 eq q(B);
    ok  -t $a->lastn_2 eq q(C);
    ok  -t $a->lastn_3 eq q(F);
  
    ok  -t $a->lastn_3__prevn_0 eq q(F);
    ok  -t $a->lastn_3__prevn_1 eq q(E);
    ok  -t $a->lastn_3__prevn_2 eq q(D);
   }
  

=head3 prevTextMatches($$@)

Return the previous node to the specified B<$node> if: it is a text mode; its text matches the specified regular expression; the specified B<$node> is in the optional specified context. Else return B<undef>.

     Parameter  Description
  1  $node      Node
  2  $match     Regular expression the text must match
  3  @context   Optional context of specified node.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                              
  <a>
    <b>bb<c>cc</c>BB
    </b>
  </a>
  END
  
    ok $cc->matchesText(qr(cc));                                                   
  
    ok $c->at_c_b &&  $c->prevTextMatches(qr(bb));                                
  
    ok $b->at_b   && !$b->prevTextMatches(qr(bb));                                
  

=head3 prevIn($@)

Return the nearest sibling node before the specified B<$node> which matches one of the named tags or B<undef> if there is no such sibling node.

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
  

=head3 prevWhile($@)

Go to the previous sibling of the specified B<$node> and continue backwards while the tag of each sibling node matches one of the specified B<@tags>. Return the first sibling node that does not match else B<undef> if there is no such sibling.

     Parameter  Description
  1  $node      Parent node
  2  @tags      Child tags to avoid.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                 
  <a>
    <b/>
    <c/>
    <d/>
    <e/>
    <f/>
  </a>
  END
  
    my ($b, $c, $d, $e, $f) = $a->byList;                                                
  
    ok $c == $f->prevWhile_e_d;                                                   
  
    ok $b == $c->prevWhile;                                                       
  

=head3 prevUntil($@)

Go to the previous sibling of the specified B<$node> and continue backwards until the tag of a sibling node matches one of the specified B<@tags>. Return the matching sibling node else B<undef> if there is no such sibling node.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags to look for.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                 
  <a>
    <b/>
    <c/>
    <d/>
    <e/>
    <f/>
  </a>
  END
  
    my ($b, $c, $d, $e, $f) = $a->byList;                                                
  
    ok $b == $f->prevUntil_a_b;                                                   
  
    ok      !$c->prevUntil;                                                       
  

=head2 Up

Methods for moving up the L<parse|/parse> tree from a node.

=head3 up($@)

Return the parent of the current node optionally checking the context of the specified B<$node> first or return B<undef> if the specified B<$node> is the root of the L<parse|/parse> tree.   See L<addWrapWith|/addWrapWith> to ensure that an expected node is in position.

     Parameter  Description
  1  $node      Start node
  2  @tags      Optional tags identifying context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


  if (1)                                                                             
   {my $a = Data::Edit::Xml::new(<<END);
  <a><b><c><b><b><b><b><c/></b></b></b></b></c></b></a>
  END
  
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
  
    my $c = $a->findByNumber(8);
    ok -t $c eq q(c);
    ok  $c->up__number == 7;
    ok  $c->upn_2__number == 6;
    ok  $c->upWhile_b__number == 4;
    ok  $c->upWhile_a_b__number == 4;
    ok  $c->upWhile_b_c__number == 2;
  
    ok  $c->upUntil__number == 7;
    ok  $c->upUntil_b_c__number == 4;
   }
  

=head3 upn($$@)

Go up the specified number of levels from the specified B<$node> and return the node reached or B<undef> if there is no such node.L<upn(1)|/up> is identical in effect to L<up|/up>.  Or use L<ancestry|/ancestry> to get the path back to the root node.

     Parameter  Description
  1  $node      Start node
  2  $levels    Number of levels to go up
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


  if (1)                                                                             
   {my $a = Data::Edit::Xml::new(<<END);
  <a><b><c><b><b><b><b><c/></b></b></b></b></c></b></a>
  END
  
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
  
    my $c = $a->findByNumber(8);
    ok -t $c eq q(c);
    ok  $c->up__number == 7;
    ok  $c->upn_2__number == 6;
    ok  $c->upWhile_b__number == 4;
    ok  $c->upWhile_a_b__number == 4;
    ok  $c->upWhile_b_c__number == 2;
  
    ok  $c->upUntil__number == 7;
    ok  $c->upUntil_b_c__number == 4;
   }
  
  if (1)                                                                          
   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a><b><c><d><e/></d></c></b></a>
  END
  
    my ($e, $d, $c, $b) = $a->byList;                                             
  
    ok $e = $e->upn(0);                                                           
    ok $d = $e->upn(1);                                                           
    ok $c = $e->upn(2);                                                           
    ok $b = $e->upn(3);                                                           
    ok $a = $e->upn(4);                                                           
    ok     !$e->upn(5);                                                           
  
    is_deeply [$e, $d, $c, $b, $a], [$e->ancestry];
   }
  
   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a><b><c><d><e/></d></c></b></a>
  END
  
    my ($e, $d, $c, $b) = $a->byList;                                             
  
    ok $e = $e->upn(0);                                                           
  
    ok $d = $e->upn(1);                                                           
  
    ok $c = $e->upn(2);                                                           
  
    ok $b = $e->upn(3);                                                           
  
    ok $a = $e->upn(4);                                                           
  
    ok     !$e->upn(5);                                                           
  

=head3 upWhile($@)

Go up one level from the specified B<$node> and then continue up while each node matches on of the specified <@tags>. Return the last matching node or B<undef> if no node matched any of the specified B<@tags>.

     Parameter  Description
  1  $node      Start node
  2  @tags      Tags to match

Example:


  if (1)                                                                             
   {my $a = Data::Edit::Xml::new(<<END);
  <a><b><c><b><b><b><b><c/></b></b></b></b></c></b></a>
  END
  
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
  
    my $c = $a->findByNumber(8);
    ok -t $c eq q(c);
    ok  $c->up__number == 7;
    ok  $c->upn_2__number == 6;
    ok  $c->upWhile_b__number == 4;
    ok  $c->upWhile_a_b__number == 4;
    ok  $c->upWhile_b_c__number == 2;
  
    ok  $c->upUntil__number == 7;
    ok  $c->upUntil_b_c__number == 4;
   }
  

=head3 upWhileFirst($@)

Move up from the specified B<$node> as long as each node is a first node or return B<undef> if the specified B<$node> is not a first node.

     Parameter  Description
  1  $node      Start node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                      
  <a>
    <b>
      <c/>
      <d/>
      <e>
        <j/>
      </e>
      <f/>
    </b>
    <g>
      <h>
        <i>
          <k/>
          <l/>
        </i>
      </h>
    </g>
  </a>
  END
  
    my ($c, $d, $j, $e, $f, $b, $k, $l, $i, $h, $g) = $a->byList;                             
  
    ok  $h == $i->upWhileFirst;                                                   
  
    ok  $a == $c->upWhileFirst;                                                   
  
    ok !$d->upWhileFirst;                                                         
  

=head3 upWhileLast($@)

Move up from the specified B<$node> as long as each node is a last node or return B<undef> if the specified B<$node> is not a last node.

     Parameter  Description
  1  $node      Start node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                      
  <a>
    <b>
      <c/>
      <d/>
      <e>
        <j/>
      </e>
      <f/>
    </b>
    <g>
      <h>
        <i>
          <k/>
          <l/>
        </i>
      </h>
    </g>
  </a>
  END
  
    my ($c, $d, $j, $e, $f, $b, $k, $l, $i, $h, $g) = $a->byList;                             
  
    ok  $j == $j->upWhileLast;                                                    
  
    ok  $a == $l->upWhileLast;                                                    
  
    ok !$d->upWhileLast;                                                          
  
    ok  $i == $k->upUntilLast;                                                    
  

=head3 upWhileIsOnlyChild($@)

Move up from the specified B<$node> as long as each node is an only child or return B<undef> if the specified B<$node> is not an only child.

     Parameter  Description
  1  $node      Start node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                      
  <a>
    <b>
      <c/>
      <d/>
      <e>
        <j/>
      </e>
      <f/>
    </b>
    <g>
      <h>
        <i>
          <k/>
          <l/>
        </i>
      </h>
    </g>
  </a>
  END
  
    my ($c, $d, $j, $e, $f, $b, $k, $l, $i, $h, $g) = $a->byList;                             
  
    ok  $h == $i->upWhileIsOnlyChild;                                             
  
    ok  $j == $j->upWhileIsOnlyChild;                                             
  
    ok !$d->upWhileIsOnlyChild;                                                   
  

=head3 upUntil($@)

Return the nearest ancestral node to the specified B<$node> that matches the specified B<@context> or B<undef> if there is no such node.  Returns the parent node of the specified B<$node> if no B<@context> is specified.

     Parameter  Description
  1  $node      Start node
  2  @context   Context.

Example:


  if (1)                                                                             
   {my $a = Data::Edit::Xml::new(<<END);
  <a><b><c><b><b><b><b><c/></b></b></b></b></c></b></a>
  END
  
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
  
    my $c = $a->findByNumber(8);
    ok -t $c eq q(c);
    ok  $c->up__number == 7;
    ok  $c->upn_2__number == 6;
    ok  $c->upWhile_b__number == 4;
    ok  $c->upWhile_a_b__number == 4;
    ok  $c->upWhile_b_c__number == 2;
  
    ok  $c->upUntil__number == 7;
    ok  $c->upUntil_b_c__number == 4;
   }
  

=head3 upUntilFirst($@)

Move up from the specified B<$node> until we reach the root or a first node.

     Parameter  Description
  1  $node      Start node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                      
  <a>
    <b>
      <c/>
      <d/>
      <e>
        <j/>
      </e>
      <f/>
    </b>
    <g>
      <h>
        <i>
          <k/>
          <l/>
        </i>
      </h>
    </g>
  </a>
  END
  
    my ($c, $d, $j, $e, $f, $b, $k, $l, $i, $h, $g) = $a->byList;                             
  
    ok  $b == $d->upUntilFirst;                                                   
  

=head3 upUntilLast($@)

Move up from the specified B<$node> until we reach the root or a last node.

     Parameter  Description
  1  $node      Start node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                      
  <a>
    <b>
      <c/>
      <d/>
      <e>
        <j/>
      </e>
      <f/>
    </b>
    <g>
      <h>
        <i>
          <k/>
          <l/>
        </i>
      </h>
    </g>
  </a>
  END
  
    my ($c, $d, $j, $e, $f, $b, $k, $l, $i, $h, $g) = $a->byList;                             
  

=head3 upUntilIsOnlyChild($@)

Move up from the specified B<$node> until we reach the root or another only child.

     Parameter  Description
  1  $node      Start node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                      
  <a>
    <b>
      <c/>
      <d/>
      <e>
        <j/>
      </e>
      <f/>
    </b>
    <g>
      <h>
        <i>
          <k/>
          <l/>
        </i>
      </h>
    </g>
  </a>
  END
  
    my ($c, $d, $j, $e, $f, $b, $k, $l, $i, $h, $g) = $a->byList;                             
  
    ok  $i == $k->upUntilIsOnlyChild;                                             
  

=head3 upThru($@)

Go up the specified path from the specified B<$node> returning the node at the top or B<undef> if no such node exists.

     Parameter  Description
  1  $node      Start node
  2  @tags      Tags identifying path.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b>
      <c/>
      <d>
        <e/>
        <f/>
      </d>
    </b>
  </a>
  END
  
    my ($c, $e, $f, $d, $b) = $a->byList;                                         
  
    ok -t $f                eq q(f);                                              
  
    ok -t $f->upThru        eq q(f);                                              
  
    ok -t $f->upThru(qw(d)) eq q(d);                                              
  
    ok -t eval{$f->upThru(qw(d))->last->prev} eq q(e);                            
  
    ok !  eval{$f->upThru(qw(d b))->next};                                        
  

=head2 down

Methods for moving down through the L<parse|/parse> tree from a node.

=head3 downWhileFirst($@)

Move down from the specified B<$node> as long as each lower node is a first node.

     Parameter  Description
  1  $node      Start node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                      
  <a>
    <b>
      <c/>
      <d/>
      <e>
        <j/>
      </e>
      <f/>
    </b>
    <g>
      <h>
        <i>
          <k/>
          <l/>
        </i>
      </h>
    </g>
  </a>
  END
  
    my ($c, $d, $j, $e, $f, $b, $k, $l, $i, $h, $g) = $a->byList;                             
  
    ok  $k == $g->downWhileFirst;                                                 
  
    ok  $c == $a->downWhileFirst;                                                 
  
    ok  $c == $c->downWhileFirst;                                                 
  
    ok       !$d->downWhileFirst;                                                 
  

B<firstLeaf> is a synonym for L<downWhileFirst|/downWhileFirst>.


=head3 downWhileLast($@)

Move down from the specified B<$node> as long as each lower node is a last node.

     Parameter  Description
  1  $node      Start node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                      
  <a>
    <b>
      <c/>
      <d/>
      <e>
        <j/>
      </e>
      <f/>
    </b>
    <g>
      <h>
        <i>
          <k/>
          <l/>
        </i>
      </h>
    </g>
  </a>
  END
  
    my ($c, $d, $j, $e, $f, $b, $k, $l, $i, $h, $g) = $a->byList;                             
  
    ok  $l == $a->downWhileLast;                                                  
  
    ok  $l == $g->downWhileLast;                                                  
  
    ok       !$d->downWhileLast;                                                  
  

B<lastLeaf> is a synonym for L<downWhileLast|/downWhileLast>.


=head3 downWhileHasSingleChild($@)

Move down from the specified B<$node> as long as it has a single child else return undef.

     Parameter  Description
  1  $node      Start node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


    ok  $h == $g->downWhileHasSingleChild;                                        
  
    ok  $h == $h->downWhileHasSingleChild;                                        
  
    ok       !$i->downWhileHasSingleChild;                                        
  

=head1 Editing

Edit the data in the L<parse|/parse> tree and change the structure of the L<parse|/parse> tree by L<wrapping and unwrapping|/Wrap and unwrap> nodes, by L<replacing|/Replace> nodes, by L<cutting and pasting|/Cut and Put> nodes, by L<concatenating|/Fusion> nodes, by L<splitting|/Fission> nodes, by adding new L<text|/Put as text> nodes or L<swapping|/swap> nodes.

=head2 change($$@)

Change the name of the specified B<$node>, optionally  confirming that the B<$node> is in a specified context and return the B<$node>.

     Parameter  Description
  1  $node      Node
  2  $name      New name
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new('<a/>');                                         
  
    $a->change(qq(b));                                                            
  
    ok -s $a eq '<b/>';                                                           
  

=head2 changeText($$@)

If the specified  B<$node> is a text node in the specified context then the specified B<sub> is passed the text of the node in L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>, any changes to which are recorded in the text of the B<$node>.

Returns B<undef> if the specified B<$node> is not a text node in the specified optional context else it returns the result of executing the specified B<sub>.

     Parameter  Description
  1  $node      Text node
  2  $sub       Sub
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>Hello World</a>
  END
  
    $a->first->changeText(sub{s(l) (L)g});                                        
  
    ok -s $a eq q(<a>HeLLo WorLd</a>);                                            
  

=head2 Cut and Put

Move nodes around in the L<parse|/parse> tree by cutting and pasting them.

=head3 cut($@)

Cut out the specified B<$node> so that it can be reinserted else where in the L<parse|/parse> tree.

     Parameter  Description
  1  $node      Node to cut out
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head3 deleteContent($@)

Delete the content of the specified B<$node>.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                              
  <a>
    <b>bb<c>cc</c>BB
    </b>
  </a>
  END
  
    $b->deleteContent;                                                            
  
    ok -p $a eq <<END;                                                            
  <a>
    <b/>
  </a>
  END
  

=head3 putFirst($$@)

Place a L<cut out|/cut> or L<new|/new> node at the front of the content of the specified B<$node> and return the new node. See L<addFirst|/addFirst> to perform this operation conditionally.

     Parameter  Description
  1  $old       Original node
  2  $new       New node
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head3 putFirstCut($$@)

Cut out the second node, place it first under the first node and return the second node.

     Parameter  Description
  1  $old       First node
  2  $new       Second node
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b>
      <c/>
      <d/>
    </b>
  </a>
  END
  
    my ($c, $d, $b) = $a->byList;                                                 
  
    $c->putFirstCut($d, qw(c b a));                                               
  
    ok -p $a eq <<END;                                                            
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
  </a>
  END
  

=head3 putLast($$@)

Place a L<cut out|/cut> or L<new|/new> node last in the content of the specified B<$node> and return the new node.  See L<addLast|/addLast> to perform this operation conditionally.

     Parameter  Description
  1  $old       Original node
  2  $new       New node
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head3 putLastCut($$@)

Cut out the second node, place it last under the first node and return the second node.

     Parameter  Description
  1  $old       First node
  2  $new       Second node
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b>
      <c/>
      <d/>
    </b>
  </a>
  END
  
    my ($c, $d, $b) = $a->byList;                                                 
  
    $a->putLastCut($d, qw(a));                                                    
  
    ok -p $a eq <<END;                                                            
  <a>
    <b>
      <c/>
    </b>
    <d/>
  </a>
  END
  

=head3 putNext($$@)

Place a L<cut out|/cut> or L<new|/new> node just after the specified B<$node> and return the new node. See L<addNext|/addNext> to perform this operation conditionally.

     Parameter  Description
  1  $old       Original node
  2  $new       New node
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head3 putNextCut($$@)

Cut out the second node, place it next after the first node and return the second node.

     Parameter  Description
  1  $old       First node
  2  $new       Second node
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b>
      <c/>
      <d/>
    </b>
  </a>
  END
  
    my ($c, $d, $b) = $a->byList;                                                 
  
    $d->putNextCut($c, qw(d b a));                                                
  
    ok -p $a eq <<END;                                                            
  <a>
    <b>
      <d/>
      <c/>
    </b>
  </a>
  END
  

=head3 putPrev($$@)

Place a L<cut out|/cut> or L<new|/new> node just before the specified B<$node> and return the new node.  See L<addPrev|/addPrev> to perform this operation conditionally.

     Parameter  Description
  1  $old       Original node
  2  $new       New node
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head3 putPrevCut($$@)

Cut out the second node, place it before the first node and return the second node.

     Parameter  Description
  1  $old       First node
  2  $new       Second node
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b>
      <c/>
      <d/>
    </b>
  </a>
  END
  
    my ($c, $d, $b) = $a->byList;                                                 
  
    $c->putPrevCut($d, qw(c b a));                                                
  
    ok -p $a eq <<END;                                                            
  <a>
    <b>
      <d/>
      <c/>
    </b>
  </a>
  END
  

=head2 Add selectively

Add new nodes unless they already exist.

=head3 addFirst($$%)

Add a new node L<first|/first> below the specified B<$node> and return the new node unless a node with that tag already exists in which case return the existing B<$node>.

     Parameter    Description
  1  $node        Node
  2  $tag         Tag of new node
  3  %attributes  Attributes for the new node.

Example:


   {my $a = Data::Edit::Xml::newTree(q(a));                                       
  
    $a->addFirst(qw(b id b)) for 1..2;                                            
  
    ok -p $a eq <<END;                                                             
  <a>
    <b id="b"/>
  </a>
  END
  

=head3 addNext($$%)

Add a new node L<next|/next> to the specified B<$node> and return the new node unless a node with that tag already exists in which case return the existing B<$node>.

     Parameter    Description
  1  $node        Node
  2  $tag         Tag of new node
  3  %attributes  Attributes for the new node.

Example:


    ok -p $a eq <<END;                                                             
  <a>
    <b id="b"/>
    <e id="e"/>
  </a>
  END
  
    $a->addFirst(qw(b id B))->addNext(qw(c id c));                                
  
    ok -p $a eq <<END;                                                             
  <a>
    <b id="b"/>
    <c id="c"/>
    <e id="e"/>
  </a>
  END
  

=head3 addPrev($$%)

Add a new node L<before|/prev> the specified B<$node> and return the new node unless a node with that tag already exists in which case return the existing B<$node>.

     Parameter    Description
  1  $node        Node
  2  $tag         Tag of new node
  3  %attributes  Attributes for the new node.

Example:


    ok -p $a eq <<END;                                                             
  <a>
    <b id="b"/>
    <c id="c"/>
    <e id="e"/>
  </a>
  END
  
    $a->addLast(qw(e id E))->addPrev(qw(d id d));                                 
  
    ok -p $a eq <<END;                                                            
  <a>
    <b id="b"/>
    <c id="c"/>
    <d id="d"/>
    <e id="e"/>
  </a>
  END
  

=head3 addLast($$%)

Add a new node L<last|/last> below the specified B<$node> and return the new node unless a node with that tag already exists in which case return the existing B<$node>.

     Parameter    Description
  1  $node        Node
  2  $tag         Tag of new node
  3  %attributes  Attributes for the new node.

Example:


    ok -p $a eq <<END;                                                             
  <a>
    <b id="b"/>
  </a>
  END
  
    $a->addLast(qw(e id e)) for 1..2;                                             
  
    ok -p $a eq <<END;                                                             
  <a>
    <b id="b"/>
    <e id="e"/>
  </a>
  END
  

=head3 addWrapWith($$%)

L<Wrap|/wrap> the specified B<$node> with the specified tag if the node is not already wrapped with such a tag and return the new node unless a node with that tag already exists in which case return the existing B<$node>.

     Parameter    Description
  1  $node        Node
  2  $tag         Tag of new node
  3  %attributes  Attributes for the new node.

Example:


   {my $a = Data::Edit::Xml::new(q(<a><b/></a>));                                 
  
    my $b = $a->first;                                                            
  
    $b->addWrapWith(qw(c id c)) for 1..2;                                         
  
    ok -p $a eq <<END;                                                             
  <a>
    <c id="c">
      <b/>
    </c>
  </a>
  END
  

=head3 addSingleChild($$%)

Wrap the content of a specified B<$node> in a new node with the specified B<$tag> and optional B<%attribute> unless the content is already wrapped in a single child with the specified B<$tag>.

     Parameter    Description
  1  $node        Node
  2  $tag         Tag of new node
  3  %attributes  Attributes for the new node.

Example:


    ok -p $a eq <<END;                                                             
  <a>
    <c id="c">
      <b/>
    </c>
  </a>
  END
  
    $a->addSingleChild(q(d)) for 1..2;                                            
  
    ok -p $a eq <<END;                                                            
  <a>
    <d>
      <c id="c">
        <b/>
      </c>
    </d>
  </a>
  END
  

=head2 Add text selectively

Add new text unless it already exists.

=head3 addFirstAsText($$)

Add a new text node first below the specified B<$node> and return the new node unless a text node already exists there and starts with the same text in which case return the existing B<$node>.

     Parameter  Description
  1  $node      Node
  2  $text      Text

Example:


   {my $a = Data::Edit::Xml::newTree(q(a));                                       
  
    $a->addFirstAsText(q(aaaa)) for 1..2;                                         
  
    ok -s $a eq q(<a>aaaa</a>);                                                    
  

=head3 addNextAsText($$)

Add a new text node after the specified B<$node> and return the new node unless a text node already exists there and starts with the same text in which case return the existing B<$node>.

     Parameter  Description
  1  $node      Node
  2  $text      Text

Example:


   {my $a = Data::Edit::Xml::new(q(<a><b/></a>));                                 
  
    $a->go(q(b))->addNextAsText(q(bbbb)) for 1..2;                                
  
    ok -p $a eq <<END;                                                             
  <a>
    <b/>
  bbbb
  </a>
  END
  

=head3 addPrevAsText($$)

Add a new text node before the specified B<$node> and return the new node unless a text node already exists there and ends with the same text in which case return the existing B<$node>.

     Parameter  Description
  1  $node      Node
  2  $text      Text

Example:


    ok -p $a eq <<END;                                                             
  <a>
    <b/>
  bbbb
  </a>
  END
  
    $a->go(q(b))->addPrevAsText(q(aaaa)) for 1..2;                                
  
    ok -p $a eq <<END;                                                            
  <a>aaaa
    <b/>
  bbbb
  </a>
  END
  

=head3 addLastAsText($$)

Add a new text node last below the specified B<$node> and return the new node unless a text node already exists there and ends with the same text in which case return the existing B<$node>.

     Parameter  Description
  1  $node      Node
  2  $text      Text

Example:


    ok -s $a eq q(<a>aaaa</a>);                                                    
  
    $a->addLastAsText(q(dddd)) for 1..2;                                          
  
    ok -s $a eq q(<a>aaaadddd</a>);                                               
  

=head2 Fusion

Join consecutive nodes

=head3 concatenate($$@)

Concatenate two successive nodes and return the target node.

     Parameter  Description
  1  $target    Target node to replace
  2  $source    Node to concatenate
  3  @context   Optional context of $target

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $s = <<END;                                                                     
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

Concatenate preceding and following nodes as long as they have the same tag as the specified B<$node> and return the specified B<$node>.

     Parameter  Description
  1  $node      Concatenate around this node
  2  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head3 mergeDuplicateChildWithParent($@)

Merge a parent node with its only child if their tags are the same and their attributes do not collide other than possibly the id in which case the parent id is used. Any labels on the child are transferred to the parent. The child node is then unwrapped and the parent node is returned.

     Parameter  Description
  1  $parent    Parent this node
  2  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                           
  <a>
    <b   id="b" b="bb">
      <b id="c" c="cc"/>
    </b>
  </a>
  END
  
    my ($c, $b) = $a->byList;                                                      
  
    is_deeply [$b->id, $c->id], [qw(b c)];                                         
  
    ok $c == $b->hasSingleChild;                                                      
  
    $b->mergeDuplicateChildWithParent;                                            
  
    ok -p $a eq <<END;                                                            
  <a>
    <b b="bb" c="cc" id="b"/>
  </a>
  END
  
    ok $b == $a->hasSingleChild;                                                      
  

=head2 Put as text

Add text to the L<parse|/parse> tree.

=head3 putFirstAsText($$@)

Add a new text node first under a parent and return the new text node.

     Parameter  Description
  1  $node      The parent node
  2  $text      The string to be added which might contain unparsed Xml as well as text
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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

Add a new text node following the specified B<$node> and return the new text node.

     Parameter  Description
  1  $node      The parent node
  2  $text      The string to be added which might contain unparsed Xml as well as text
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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

Add a new text node following the specified B<$node> and return the new text node

     Parameter  Description
  1  $node      The parent node
  2  $text      The string to be added which might contain unparsed Xml as well as text
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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


   {my $A = Data::Edit::Xml::new("<a><b><d/><c/><c/><e/><c/><c/><d/></b></a>");   
  
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

Replace nodes in the L<parse|/parse> tree with nodes or text

=head3 replaceWith($$@)

Replace a node (and all its content) with a L<new node|/newTag> (and all its content) and return the new node. If the node to be replaced is the root of the L<parse|/parse> tree then no action is taken other then returning the new node.

     Parameter  Description
  1  $old       Old node
  2  $new       New node
  3  @context   Optional context..

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


     {my $x = Data::Edit::Xml::new(qq(<a><b><c id="cc"/></b></a>));               
  
      $x->go(qw(b c))->replaceWith($x->newTag(qw(d id dd)));                      
  
      ok -s $x eq '<a><b><d id="dd"/></b></a>';                                   
  

=head3 replaceWithText($$@)

Replace a node (and all its content) with a new text node and return the new node.

     Parameter  Description
  1  $old       Old node
  2  $text      Text of new node
  3  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


     {my $x = Data::Edit::Xml::new(qq(<a><b><c id="cc"/></b></a>));               
  
      $x->go(qw(b c))->replaceWithText(qq(BBBB));                                 
  
      ok -s $x eq '<a><b>BBBB</b></a>';                                           
  

=head3 replaceWithBlank($@)

Replace a node (and all its content) with a new blank text node and return the new node.

     Parameter  Description
  1  $old       Old node
  2  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


     {my $x = Data::Edit::Xml::new(qq(<a><b><c id="cc"/></b></a>));               
  
      $x->go(qw(b c))->replaceWithBlank;                                          
  
      ok -s $x eq '<a><b> </b></a>';                                              
  

=head3 replaceContentWithMovedContent($@)

Replace the content of a specified target node with the contents of the specified source nodes removing the content from each source node and return the target node.

     Parameter  Description
  1  $node      Target node
  2  @nodes     Source nodes

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b>
       <b1/>
       <b2/>
    </b>
    <c>
       <c1/>
       <c2/>
    </c>
    <d>
       <d1/>
       <d2/>
    </d>
  </a>
  END
  
    my ($b, $c, $d) = $a->contents;                                               
  
    $d->replaceContentWithMovedContent($c, $b);                                   
  
    ok -p $a eq <<END;                                                            
  <a>
    <b/>
    <c/>
    <d>
      <c1/>
      <c2/>
      <b1/>
      <b2/>
    </d>
  </a>
  END
  
   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <d>
       <b>
         <b1/>
         <b2/>
      </b>
      <c>
         <c1/>
         <c2/>
      </c>
    </d>
  </a>
  END
  
    my ($d)     = $a->contents;                                                   
  
    my ($b, $c) = $d->contents;                                                   
  
    $d->replaceContentWithMovedContent($c, $b);                                   
  
    ok -p $a eq <<END;                                                            
  <a>
    <d>
      <c1/>
      <c2/>
      <b1/>
      <b2/>
    </d>
  </a>
  END
  

=head3 replaceContentWith($@)

Replace the content of a node with the specified nodes and return the replaced content

     Parameter  Description
  1  $node      Node whose content is to be replaced
  2  @content   New content

Example:


     {my $x = Data::Edit::Xml::new(qq(<a><b/><c/></a>));                          
  
      $x->replaceContentWith(map {$x->newTag($_)} qw(B C));                       
  
      ok -s $x eq '<a><B/><C/></a>';                                              
  

=head3 replaceContentWithText($@)

Replace the content of a node with the specified texts and return the replaced content

     Parameter  Description
  1  $node      Node whose content is to be replaced
  2  @text      Texts to form new content

Example:


     {my $x = Data::Edit::Xml::new(qq(<a><b/><c/></a>));                          
  
      $x->replaceContentWithText(qw(b c));                                        
  
      ok -s $x eq '<a>bc</a>';                                                    
  

=head2 Swap

Swap nodes both singly and in blocks

=head3 invert($@)

Swap a parent and child node where the child is the only child of the parent and return the parent.

     Parameter  Description
  1  $parent    Parent
  2  @context   Context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b id="b">
      <c id="c">
        <d/>
        <e/>
      </c>
    </b>
  </a>
  END
  
    $a->first->invert;                                                            
  
    ok -p $a eq <<END;                                                            
  <a>
    <c id="c">
      <b id="b">
        <d/>
        <e/>
      </b>
    </c>
  </a>
  END
  
    $a->first->invert;                                                            
  
    ok -p $a eq <<END;                                                            
  <a>
    <b id="b">
      <c id="c">
        <d/>
        <e/>
      </c>
    </b>
  </a>
  END
  

=head3 invertFirst($@)

Swap a parent and child node where the child is the first child of the parent by placing the parent last in the child. Return the parent.

     Parameter  Description
  1  $parent    Parent
  2  @context   Context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                           
  <a>
    <b>
      <c>
        <d/>
        <e/>
      </c>
      <f/>
      <g/>
    </b>
  </a>
  END
  
    ok -p $a eq <<END;                                                             
  <a>
    <c>
      <d/>
      <e/>
      <b>
        <f/>
        <g/>
      </b>
    </c>
  </a>
  END
  

=head3 invertLast($@)

Swap a parent and child node where the child is the last child of the parent by placing the parent first in the child. Return the parent.

     Parameter  Description
  1  $parent    Parent
  2  @context   Context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                           
  <a>
    <b>
      <c>
        <d/>
        <e/>
      </c>
      <f/>
      <g/>
    </b>
  </a>
  END
  
    ok -p $a eq <<END;                                                             
  <a>
    <c>
      <d/>
      <e/>
      <b>
        <f/>
        <g/>
      </b>
    </c>
  </a>
  END
  
    ok -p $a eq <<END;                                                            
  <a>
    <b>
      <c>
        <d/>
        <e/>
      </c>
      <f/>
      <g/>
    </b>
  </a>
  END
  

=head3 swap($$@)

Swap two nodes optionally checking that the first node is in the specified context and return the first node.

     Parameter  Description
  1  $first     First node
  2  $second    Second node
  3  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


    ok <<END eq -p $x;                                                             
  <x>
    <a a="1" b="2"/>
    <b/>
    <c a="1" b="3" c="4"/>
  </x>
  END
  
    $a->swap($c);                                                                 
  
    ok <<END eq -p $x;                                                             
  <x>
    <c a="1" b="3" c="4"/>
    <b/>
    <a a="1" b="2"/>
  </x>
  END
  

=head2 Wrap and unwrap

Wrap and unwrap nodes to alter the depth of the L<parse|/parse> tree

=head3 wrapWith($$@)

Wrap the specified B<$node> in a new node created from the specified B<$tag> and B<%attributes> forcing the specified B<$node> down - deepening the L<parse|/parse> tree - return the new wrapping node. See L<addWrapWith|/addWrapWith> to perform this operation conditionally.

     Parameter    Description
  1  $node        Node
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

Wrap the specified B<$node> in a sequence of new nodes created from the specified B<@tags> forcing the original node down - deepening the L<parse|/parse> tree - return the array of wrapping nodes.

     Parameter  Description
  1  $node      Node to wrap
  2  @tags      Tags to wrap the node with - with the uppermost tag rightmost.

Example:


   {my $c = Data::Edit::Xml::newTree("c", id=>33);                                
  
    my ($b, $a) = $c->wrapUp(qw(b a));                                            
  
    ok -p $a eq <<'END';                                                          
  <a>
    <b>
      <c id="33"/>
    </b>
  </a>
  END
  

=head3 wrapDown($@)

Wrap the content of the specified B<$node> in a sequence of new nodes forcing the original node up - deepening the L<parse|/parse> tree - return the array of wrapping nodes.

     Parameter  Description
  1  $node      Node to wrap
  2  @tags      Tags to wrap the node with - with the uppermost tag rightmost.

Example:


   {my $a = Data::Edit::Xml::newTree("a", id=>33);                                
  
    my ($b, $c) = $a->wrapDown(qw(b c));                                          
  
    ok -p $a eq <<END;                                                            
  <a id="33">
    <b>
      <c/>
    </b>
  </a>
  END
  

=head3 wrapContentWith($$@)

Wrap the content of the specified B<$node> in a new node created from the specified <@tag> and B<%attributes>: the specified B<$node> then contains just the new node which, in turn, contains all the content of the specified B<$node>.

Returns the new wrapped node.

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
  

=head3 wrapSiblingsBefore($$@)

If there are any siblings before the specified B<$node>, wrap them with a new node created from the specified <@tag> and B<%attributes>.

Returns the specified B<$node>.

     Parameter    Description
  1  $node        Node to wrap before
  2  $tag         Tag for new node
  3  %attributes  Attributes for new node.

Example:


   {my $a = Data::Edit::Xml::new(q(<a><b/><c/><d/></a>));                         
  
    my ($b, $c, $d) = $a->byList;                                                 
  
    $c->wrapSiblingsBefore(q(X));                                                 
  
    ok -p $a eq <<END;                                                            
  <a>
    <X>
      <b/>
    </X>
    <c/>
    <d/>
  </a>
  END
  

=head3 wrapSiblingsBetween($$$@)

If there are any siblings between the specified B<$node>s, wrap them with a new node created from the specified <@tag> and B<%attributes>. Return the wrapping node else B<undef> if there are no nodes to wrap.

     Parameter    Description
  1  $first       First sibling
  2  $last        Last sibling
  3  $tag         Tag for new node
  4  %attributes  Attributes for new node.

Example:


   {my $a = Data::Edit::Xml::new(q(<a><b/><c/><d/></a>));                         
  
    my ($b, $c, $d) = $a->byList;                                                 
  
    $b->wrapSiblingsBetween($d, q(Y));                                            
  
    ok -p $a eq <<END;                                                            
  <a>
    <b/>
    <Y>
      <c/>
    </Y>
    <d/>
  </a>
  END
  

=head3 wrapSiblingsAfter($$@)

If there are any siblings after the specified B<$node>, wrap them with a new node created from the specified <@tag> and B<%attributes>.

Return the specified B<$node>.

     Parameter    Description
  1  $node        Node to wrap before
  2  $tag         Tag for new node
  3  %attributes  Attributes for new node.

Example:


   {my $a = Data::Edit::Xml::new(q(<a><b/><c/><d/></a>));                         
  
    my ($b, $c, $d) = $a->byList;                                                 
  
    $c->wrapSiblingsAfter(q(Y));                                                  
  
    ok -p $a eq <<END;                                                            
  <a>
    <b/>
    <c/>
    <Y>
      <d/>
    </Y>
  </a>
  END
  

=head3 wrapTo($$$@)

Wrap all the nodes from the B<$start> node to the B<$end> node with a new node created from the specified <@tag> and B<%attributes> and return the new node.

Return B<undef> if the B<$start> and B<$end> nodes are not siblings - they must have the same parent for this method to work.

     Parameter    Description
  1  $start       Start node
  2  $end         End node
  3  $tag         Tag for the wrapping node
  4  %attributes  Attributes for the wrapping node

Example:


   {my $x = Data::Edit::Xml::new(my $s = <<END);                                   
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
  
    my $C = $x->go(qw(a C));                                                      
  
    $C->wrapTo($C, qq(D));                                                        
  
    ok -p $x eq <<END;                                                            
  <aa>
    <a>
      <b/>
      <D>
        <C id="1234">
          <c id="1"/>
          <c id="2"/>
          <c id="3"/>
          <c id="4"/>
        </C>
      </D>
      <d/>
    </a>
  </aa>
  END
  
    ok -p $a eq <<END;                                                            
  <a>
    <b>
      <D id="DD">
        <c id="0"/>
        <c id="1"/>
      </D>
      <E id="EE">
        <c id="2"/>
      </E>
      <F id="FF">
        <c id="3"/>
      </F>
    </b>
  </a>
  END
  

=head3 wrapFrom($$$%)

Wrap all the nodes from the B<$start> node to the B<$end> node with a new node created from the specified <@tag> and B<%attributes> and return the new node.  Return B<undef> if the B<$start> and B<$end> nodes are not siblings - they must have the same parent for this method to work.

     Parameter    Description
  1  $end         End node
  2  $start       Start node
  3  $tag         Tag for the wrapping node
  4  %attributes  Attributes for the wrapping node

Example:


   {my $a = Data::Edit::Xml::new(my $s = <<END);                                  
  <a>
    <b>
      <c id="0"/><c id="1"/><c id="2"/><c id="3"/>
    </b>
  </a>
  END
  
    my $b = $a->first;                                                            
  
    my @c = $b->contents;                                                         
  
    $c[1]->wrapFrom($c[0], qw(D id DD));                                          
  
    ok -p $a eq <<END;                                                            
  <a>
    <b>
      <D id="DD">
        <c id="0"/>
        <c id="1"/>
      </D>
      <c id="2"/>
      <c id="3"/>
    </b>
  </a>
  END
  

=head3 unwrap($@)

Unwrap the specified B<$node> by inserting its content into its parent at the point containing the specified B<$node> and return the parent node.

     Parameter  Description
  1  $node      Node to unwrap
  2  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


    ok -s $x eq "<a>A<b> c </b>B</a>";                                            
  
    $b->unwrap;                                                                   
  
    ok -s $x eq "<a>A c B</a>";                                                   
  

=head3 unwrapParentsWithSingleChild($)

Unwrap any immediate ancestors of the specified B<$node> which have only a single child and return the specified B<$node> regardless.

     Parameter  Description
  1  $o         Node

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <e/>
  </a>
  END
  
    $a->go(qw(b c d))->unwrapParentsWithSingleChild;                              
  
    ok -p $a eq <<END;                                                            
  <a>
    <d/>
    <e/>
  </a>
  END
  

=head3 unwrapContentsKeepingText($@)

Unwrap all the non text nodes below the specified B<$node> adding a leading and a trailing space to prevent unwrapped content from being elided and return the specified B<$node> else B<undef> if not in the optional context.

     Parameter  Description
  1  $node      Node to unwrap
  2  @context   Optional context.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head1 Contents

The children of each node.

=head2 contents($@)

Return a list of all the nodes contained by the specified B<$node> or an empty list if the node is empty or not in the optional context.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>.  If a context is supplied and
B<$node> is not in this context then this method returns an empty list B<()>
immediately.



Example:


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
  
    is_deeply [map{-u $_} $x->contents], [qw(b1 d1 e1 b2 d2 e2)];                 
  

=head2 contentAfter($@)

Return a list of all the sibling nodes following the specified B<$node> or an empty list if the specified B<$node> is last or not in the optional context.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>.  If a context is supplied and
B<$node> is not in this context then this method returns an empty list B<()>
immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
    ok 'f g' eq join ' ', map {$_->tag} $x->go(qw(b e))->contentAfter;            
  

=head2 contentBefore($@)

Return a list of all the sibling nodes preceding the specified B<$node> or an empty list if the specified B<$node> is last or not in the optional context.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>.  If a context is supplied and
B<$node> is not in this context then this method returns an empty list B<()>
immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
    ok 'c d' eq join ' ', map {$_->tag} $x->go(qw(b e))->contentBefore;           
  

=head2 contentAsTags($@)

Return a string containing the tags of all the child nodes of the specified B<$node> separated by single spaces or the empty string if the node is empty or B<undef> if the node does not match the optional context. Use L<over|/over> to test the sequence of tags with a regular expression.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>.  If a context is supplied and
B<$node> is not in this context then this method returns an empty list B<()>
immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
    ok $x->go(q(b))->contentAsTags eq 'c d e f g';                                
  

=head2 contentAsTags2($@)

Return a string containing the tags of all the child nodes of the specified B<$node> separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or B<undef> if the node does not match the optional context. Use L<over2|/over2> to test the sequence of tags with a regular expression. Use L<over2|/over2> to test the sequence of tags with a regular expression.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>.  If a context is supplied and
B<$node> is not in this context then this method returns an empty list B<()>
immediately.



Example:


    ok $x->go(q(b))->contentAsTags2 eq q( c  d  e  f  g );                        
  

=head2 contentAfterAsTags($@)

Return a string containing the tags of all the sibling nodes following the specified B<$node> separated by single spaces or the empty string if the node is empty or B<undef> if the node does not match the optional context. Use L<matchAfter|/matchAfter> to test the sequence of tags with a regular expression.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>.  If a context is supplied and
B<$node> is not in this context then this method returns an empty list B<()>
immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
    ok 'f g' eq join ' ', map {$_->tag} $x->go(qw(b e))->contentAfter;            
  
    ok $x->go(qw(b e))->contentAfterAsTags eq 'f g';                              
  

=head2 contentAfterAsTags2($@)

Return a string containing the tags of all the sibling nodes following the specified B<$node> separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or B<undef> if the node does not match the optional context. Use L<matchAfter2|/matchAfter2> to test the sequence of tags with a regular expression.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>.  If a context is supplied and
B<$node> is not in this context then this method returns an empty list B<()>
immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
    ok $x->go(qw(b e))->contentAfterAsTags2 eq q( f  g );                         
  

=head2 contentBeforeAsTags($@)

Return a string containing the tags of all the sibling nodes preceding the specified B<$node> separated by single spaces or the empty string if the node is empty or B<undef> if the node does not match the optional context. Use L<matchBefore|/matchBefore> to test the sequence of tags with a regular expression.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>.  If a context is supplied and
B<$node> is not in this context then this method returns an empty list B<()>
immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
    ok 'c d' eq join ' ', map {$_->tag} $x->go(qw(b e))->contentBefore;           
  
    ok $x->go(qw(b e))->contentBeforeAsTags eq 'c d';                             
  

=head2 contentBeforeAsTags2($@)

Return a string containing the tags of all the sibling nodes preceding the specified B<$node> separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or B<undef> if the node does not match the optional context.  Use L<matchBefore2|/matchBefore2> to test the sequence of tags with a regular expression.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context.

Use the B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>.  If a context is supplied and
B<$node> is not in this context then this method returns an empty list B<()>
immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c/><d/><e/><f/><g/>
    </b>
  </a>
  END
  
    ok $x->go(qw(b e))->contentBeforeAsTags2 eq q( c  d );                        
  

=head2 position($)

Return the index of the specified B<$node> in the content of the parent of the B<$node>.

     Parameter  Description
  1  $node      Node.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                   
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

Return the index of the specified B<$node> in its parent index. Use L<position|/position> to find the position of a node under its parent.

     Parameter  Description
  1  $node      Node.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                   
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

Return the specified B<$node> if the specified B<$node> is a text node, optionally in the specified context, else return B<undef>.

     Parameter  Description
  1  $node      Node to test
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


    ok $a->prettyStringCDATA eq <<END;                                              
  <a>
      <b><CDATA> </CDATA></b>
  </a>
  END
  
    ok $b->first->isText;                                                         
  
    ok $b->first->isText(qw(b a));                                                
  

=head2 isFirstText($@)

Return the specified B<$node> if the specified B<$node> is a text node, the first node under its parent and that the parent is optionally in the specified context, else return B<undef>.

     Parameter  Description
  1  $node      Node to test
  2  @context   Optional context for parent

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                           
  <x>
    <a>aaa
      <b>bbb</b>
      ccc
      <d>ddd</d>
      eee
    </a>
  </x>
  END
  
    my $a = $x->first;                                                            
  
    my ($ta, $b, $tc, $d, $te) = $a->contents;                                    
  
    ok $ta      ->isFirstText(qw(a x));                                           
  
    ok $b->first->isFirstText(qw(b a x));                                         
  
    ok $b->prev ->isFirstText(qw(a x));                                           
  
    ok $d->last ->isFirstText(qw(d a x));                                         
  

=head2 isLastText($@)

Return the specified B<$node> if the specified B<$node> is a text node, the last node under its parent and that the parent is optionally in the specified context, else return B<undef>.

     Parameter  Description
  1  $node      Node to test
  2  @context   Optional context for parent

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                           
  <x>
    <a>aaa
      <b>bbb</b>
      ccc
      <d>ddd</d>
      eee
    </a>
  </x>
  END
  
    ok $d->next ->isLastText (qw(a x));                                           
  
    ok $d->last ->isLastText (qw(d a x));                                         
  
    ok $te      ->isLastText (qw(a x));                                           
  

=head2 matchTree($@)

Return a list of nodes that match the specified tree of match expressions, else B<()> if one or more match expressions fail to match nodes in the tree below the specified start node. A match expression consists of [parent node tag, [match expressions to be matched by children of parent]|tags of child nodes to match starting at the first node]. Match expressions for a single item do need to be surrounded with [] and can be merged into their predecessor. The outermost match expression should not be enclosed in [].

     Parameter  Description
  1  $node      Node to start matching from
  2  @match     Tree of match expressions.

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


  if (1)                                                                          
   {my $a = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c/>
      <d/>
    </b>
    <e>
      <f>
        <g/>
      </f>
    </e>
  </a>
  END
    my ($c, $d, $b, $g, $f, $e) = $a->byList;
  
    is_deeply [$b, $c, $d], [$b->matchTree(qw(b c d))];
    is_deeply [$e, $f, $g], [$e->matchTree(qr(\Ae\Z), [qw(f g)])];
    is_deeply [$c],         [$c->matchTree(qw(c))];
    is_deeply [$a, $b, $c, $d, $e, $f, $g],
              [$a->matchTree({a=>1}, [qw(b c d)], [qw(e), [qw(f g)]])];
   }
  

=head2 matchesText($$@)

Returns an array of regular expression matches in the text of the specified B<$node> if it is text node and it matches the specified regular expression and optionally has the specified context otherwise returns an empty array.

     Parameter  Description
  1  $node      Node to test
  2  $re        Regular expression
  3  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $x = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b>
      <c>CDECD</c>
    </b>
  </a>
  END
  
    my $c = $x->go(qw(b c))->first;                                               
  
    ok !$c->matchesText(qr(\AD));                                                 
  
    ok  $c->matchesText(qr(\AC), qw(c b a));                                      
  
    ok !$c->matchesText(qr(\AD), qw(c b a));                                      
  
    is_deeply [qw(E)], [$c->matchesText(qr(CD(.)CD))];                            
  

=head2 isBlankText($@)

Return the specified B<$node> if the specified B<$node> is a text node, optionally in the specified context, and contains nothing other than white space else return B<undef>. See also: L<isAllBlankText|/isAllBlankText>

     Parameter  Description
  1  $node      Node to test
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


    ok $a->prettyStringCDATA eq <<END;                                              
  <a>
      <b><CDATA> </CDATA></b>
  </a>
  END
  
    ok $b->first->isBlankText;                                                    
  

=head2 isAllBlankText($@)

Return the specified B<$node> if the specified B<$node>, optionally in the specified context, does not contain anything or if it does contain something it is all white space else return B<undef>. See also: L<bitsNodeTextBlank|/bitsNodeTextBlank>

     Parameter  Description
  1  $node      Node to test
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
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
  

=head1 Number

Number the nodes of a parse tree so that they can be easily retrieved by number - either by a person reading the source xml or programmatically.

=head2 findByNumber($$)

Find the node with the specified number as made visible by L<prettyStringNumbered|/prettyStringNumbered> in the L<parse|/parse> tree containing the specified B<$node> and return the found node or B<undef> if no such node exists.

     Parameter  Description
  1  $node      Node in the parse tree to search
  2  $number    Number of the node required.

Example:


  if (1)                                                                            
   {my $a = Data::Edit::Xml::new(<<END);
  <a><b><c/></b><d><e/></d></a>
  END
  
    $a->numberTree;
    ok -z $a eq <<END;
  <a id="1">
    <b id="2">
      <c id="3"/>
    </b>
    <d id="4">
      <e id="5"/>
    </d>
  </a>
  END
  
    ok -t $a->findByNumber_4 eq q(d);
    ok    $a->findByNumber_3__up__number == 2;
   }
  
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
  

=head2 findByNumbers($@)

Find the nodes with the specified numbers as made visible by L<prettyStringNumbered|/prettyStringNumbered> in the L<parse|/parse> tree containing the specified B<$node> and return the found nodes in a list with B<undef> for nodes that do not exist.

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

Number the nodes in a L<parse|/parse> tree in pre-order so they are numbered in the same sequence that they appear in the source. You can see the numbers by printing the tree with L<prettyStringNumbered|/prettyStringNumbered>.  Nodes can be found using L<findByNumber|/findByNumber>.  This method differs from L<forestNumberTrees|/forestNumberTrees> in that avoids overwriting the B<id=> attribute of each node by using a system attribute instead; this system attribute can then be made visible on the id attribute of each node by printing the parse tree with L<prettyStringNumbered|/prettyStringNumbered>.

     Parameter  Description
  1  $node      Node

Example:


    $a->numberTree;                                                                
  
    ok -z $a eq <<END;                                                             
  <a id="1">
    <b id="2">
      <c id="42" match="mm"/>
    </b>
    <d id="4">
      <e id="5"/>
    </d>
  </a>
  END
  
  if (1)                                                                            
   {my $a = Data::Edit::Xml::new(<<END);
  <a><b><c/></b><d><e/></d></a>
  END
  
    $a->numberTree;
    ok -z $a eq <<END;
  <a id="1">
    <b id="2">
      <c id="3"/>
    </b>
    <d id="4">
      <e id="5"/>
    </d>
  </a>
  END
  
    ok -t $a->findByNumber_4 eq q(d);
    ok    $a->findByNumber_3__up__number == 2;
   }
  

=head2 indexIds($)

Return a map of the ids at and below the specified B<$node>.

     Parameter  Description
  1  $node      Node

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a id="A">
    <b id="B">
      <c id="C"/>
      <d id="D">
        <e id="E"/>
        <f id="F"/>
      </d>
    </b>
  </a>
  END
  
    my $i = $a->indexIds;                                                         
  
    ok $i->{C}->tag eq q(c);                                                      
  
    ok $i->{E}->tag eq q(e);                                                      
  

=head2 numberTreesJustIds($$)

Number the ids of the nodes in a L<parse|/parse> tree in pre-order so they are numbered in the same sequence that they appear in the source. You can see the numbers by printing the tree with L<prettyStringNumbered()|/prettyStringNumbered>. This method differs from L<numberTree|/numberTree> in that only non text nodes without ids are numbered. The number applied to each node consists of the concatenation of the specified prefix, an underscore and a number that is unique within the specifed L<parse|/parse> tree. Consequently the ids across several trees trees can be made unique by supplying different prefixes for each tree.  Nodes can be found using L<findByNumber|/findByNumber>.  Returns the specified B<$node>.

     Parameter  Description
  1  $node      Node
  2  $prefix    Prefix for each id at and under the specified B<$node>

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>A
    <b id="bb">B
      <c/>
      <d>D
        <e id="ee"/>
          E
        <f/>
          F
      </d>
      G
    </b>
    H
  </a>
  END
  
    $a->numberTreesJustIds(q(T));                                                 
  
    my $A = Data::Edit::Xml::new(<<END);                                          
  <a id="T_1">A
    <b id="bb">B
      <c id="T_2"/>
      <d id="T_3">D
        <e id="ee"/>
          E
        <f id="T_4"/>
          F
      </d>
      G
    </b>
    H
  </a>
  END
  
    ok -p $a eq -p $A;                                                            
  

=head1 Forest Numbers

Number the nodes of several parse trees so that they can be easily retrieved by forest number - either by a person reading the source xml or programmatically.

=head2 forestNumberTrees($$)

Number the ids of the nodes in a L<parse|/parse> tree in pre-order so they are numbered in the same sequence that they appear in the source. You can see the numbers by printing the tree with L<prettyString|/prettyString>. This method differs from L<numberTree|/numberTree> in that only non text nodes are numbered and nodes with existing B<id=> attributes have the value of their B<id=> attribute transferred to a L<label|/Labels>. The number applied to each node consists of the concatenation of the specified tree number, an underscore and a number that is unique within the specified L<parse|/parse> tree. Consequently the ids across several trees can be made unique by supplying a different tree number for each tree.  Nodes can be found subsequently using L<findByForestNumber|/findByForestNumber>.  Returns the specified B<$node>.

     Parameter  Description
  1  $node      Node in parse tree to be numbered
  2  $prefix    Tree number

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b id="b">
      <c/>
    </b>
    <b id="B">
      <d/>
      <e/>
    </b>
  </a>
  END
  
    my $e = $a->go(qw(b -1 e));                                                   
  
    $e->forestNumberTrees(1);                                                     
  
    ok -p $a eq <<END;                                                             
  <a id="1_1">
    <b id="1_2">
      <c id="1_3"/>
    </b>
    <b id="1_4">
      <d id="1_5"/>
      <e id="1_6"/>
    </b>
  </a>
  END
  

=head2 findByForestNumber($$$)

Find the node with the specified L<forest number|/forestNumberTrees> as made visible on the id attribute by L<prettyStringNumbered|/prettyStringNumbered> in the L<parse|/parse> tree containing the specified B<$node> and return the found node or B<undef> if no such node exists.

     Parameter  Description
  1  $node      Node in the parse tree to search
  2  $tree      Forest number
  3  $id        Id number of the node required.

Example:


    ok -p $a eq <<END;                                                             
  <a id="1_1">
    <b id="1_2">
      <c id="1_3"/>
    </b>
    <b id="1_4">
      <d id="1_5"/>
      <e id="1_6"/>
    </b>
  </a>
  END
  
    my $B = $e->findByForestNumber(1, 4);                                         
  
    is_deeply [$B->getLabels], ["B"];                                             
  

=head1 Order

Check the order and relative position of nodes in a parse tree.

=head2 above($$@)

Return the first node if the first node is above the second node optionally checking that the first node is in the specified context otherwise return B<undef>

     Parameter  Description
  1  $first     First node
  2  $second    Second node
  3  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head2 abovePath($$)

Return the nodes along the path from the first node down to the second node when the first node is above the second node else return B<()>.

     Parameter  Description
  1  $first     First node
  2  $second    Second node

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
  
    my ($a, $b, $c, $d, $e) = $x->firstDown(@tags);                                
  
    is_deeply [$b, $d, $e], [$b->abovePath($e)];                                  
  
    is_deeply [],   [$c->abovePath($d)];                                          
  

=head2 below($$@)

Return the first node if the first node is below the second node optionally checking that the first node is in the specified context otherwise return B<undef>

     Parameter  Description
  1  $first     First node
  2  $second    Second node
  3  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head2 belowPath($$)

Return the nodes along the path from the first node up to the second node when the first node is below the second node else return B<()>.

     Parameter  Description
  1  $first     First node
  2  $second    Second node

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
  
    my ($a, $b, $c, $d, $e) = $x->firstDown(@tags);                                
  
    is_deeply [$e, $d, $b], [$e->belowPath($b)];                                  
  
    is_deeply [$c], [$c->belowPath($c)];                                          
  

=head2 after($$@)

Return the first node if it occurs after the second node in the L<parse|/parse> tree optionally checking that the first node is in the specified context or else B<undef> if the node is L<above|/above>, L<below|/below> or L<before|/before> the target.

     Parameter  Description
  1  $first     First node
  2  $second    Second node
  3  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head2 before($$@)

Return the first node if it occurs before the second node in the L<parse|/parse> tree optionally checking that the first node is in the specified context or else B<undef> if the node is L<above|/above>, L<below|/below> or L<before|/before> the target.

     Parameter  Description
  1  $first     First node
  2  $second    Second node
  3  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



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
  

=head2 disordered($@)

Return the first node that is out of the specified order when performing a pre-ordered traversal of the L<parse|/parse> tree.

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
  
     {my ($b, $e, @n) = $a->findByNumbers(2, 4, 6, 9);                            
  
      ok $e == $e->commonAncestor;                                                
  
      ok $e == $e->commonAncestor($e);                                            
  
      ok $b == $e->commonAncestor($b);                                            
  
      ok $b == $e->commonAncestor(@n);                                            
  

=head2 commonAdjacentAncestors($$)

Given two nodes, find a pair of adjacent ancestral siblings if such a pair exists else return B<()>.

     Parameter  Description
  1  $first     First node
  2  $second    Second node

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <b>
      <c/>
    </b>
    <e>
      <f/>
    </e>
  </a>
  END
  
    my ($d, $c, $b, $C, $B, $f, $e) = $a->byList;                                              
  
    is_deeply [$d->commonAdjacentAncestors($C)], [$b, $B];                                                       
  

=head2 ordered($@)

Return the first node if the specified nodes are all in order when performing a pre-ordered traversal of the L<parse|/parse> tree else return B<undef>.

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
  

=head1 Patching

Analyze two similar L<parse|/parse> trees and create a patch that transforms the first L<parse|/parse> tree into the second as long as each tree has the same tag and id structure with each id being unique.

=head2 createPatch($$)

Create a patch that moves the source L<parse|/parse> tree to the target L<parse|/parse> tree node as long as they have the same tag and id structure with each id being unique.

     Parameter  Description
  1  $a         Source parse tree
  2  $A         Target parse tree

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                           
  <a>Aaaaa
    <b b1="b1" b2="b2">Bbbbb
      <c c1="c1" />Ccccc
      <d d1="d1" >Ddddd
        <e  e1="e1" />
          Eeeee
        <f  f1="f1" />
          Fffff
      </d>
      Ggggg
    </b>
    Hhhhhh
  </a>
  END
  
    my $A = Data::Edit::Xml::new(<<END);                                           
  <a>AaaAaaA
    <b b1="b1" b3="B3">BbbBbbB
      <c c1="C1" />Ccccc
      <d d2="D2" >DddDddD
        <e  e3="E3" />
          EeeEeeE
        <f  f1="F1" />
          FffFffF
      </d>
      GggGggG
    </b>
    Hhhhhh
  </a>
  END
  
    $a->numberTreesJustIds(q(a));                                                  
  
    $A->numberTreesJustIds(q(a));                                                  
  
    my $patches = $a->createPatch($A);                                             
  
    $patches->install($a);                                                         
  
    ok !$a->diff  ($A);                                                            
  
    ok  $a->equals($A);                                                            
  

=head2 Data::Edit::Xml::Patch::install($$)

Replay a patch created by L<createPatch|/createPatch> against a L<parse|/parse> tree that has the same tag and id structure with each id being unique.

     Parameter  Description
  1  $patches   Patch
  2  $a         Parse tree

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                           
  <a>Aaaaa
    <b b1="b1" b2="b2">Bbbbb
      <c c1="c1" />Ccccc
      <d d1="d1" >Ddddd
        <e  e1="e1" />
          Eeeee
        <f  f1="f1" />
          Fffff
      </d>
      Ggggg
    </b>
    Hhhhhh
  </a>
  END
  
    my $A = Data::Edit::Xml::new(<<END);                                           
  <a>AaaAaaA
    <b b1="b1" b3="B3">BbbBbbB
      <c c1="C1" />Ccccc
      <d d2="D2" >DddDddD
        <e  e3="E3" />
          EeeEeeE
        <f  f1="F1" />
          FffFffF
      </d>
      GggGggG
    </b>
    Hhhhhh
  </a>
  END
  
    $a->numberTreesJustIds(q(a));                                                  
  
    $A->numberTreesJustIds(q(a));                                                  
  
    my $patches = $a->createPatch($A);                                             
  
    $patches->install($a);                                                         
  
    ok !$a->diff  ($A);                                                            
  
    ok  $a->equals($A);                                                            
  

=head1 Propogating

Propagate parent node attributes through a parse tree.

=head2 propagate($$@)

Propagate L<new attributes|/copyNewAttrs> from nodes that match the specified tag to all their child nodes, then L<unwrap|/unwrap> all the nodes that match the specified tag. Return the specified parse tree.

     Parameter  Description
  1  $tree      Parse tree
  2  $tag       Tag of nodes whose attributes are to be propagated
  3  @context   Optional context for parse tree

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b b="B">
      <b c="C">
        <c/>
        <b d="D">
          <d/>
          <b e="E">
            <e/>
          </b>
        </b>
      </b>
    </b>
  </a>
  END
  
    $a->propagate(q(b));                                                          
  
    ok -p $a eq <<END;                                                            
  <a>
    <c b="B" c="C"/>
    <d b="B" c="C" d="D"/>
    <e b="B" c="C" d="D" e="E"/>
  </a>
  END
  

=head1 Table of Contents

Analyze and generate tables of contents.

=head2 tocNumbers($@)

Table of Contents number the nodes in a L<parse|/parse> tree.

     Parameter  Description
  1  $node      Node
  2  @match     Optional list of tags to descend into else all tags will be descended into

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
  
       {"1"  =>"b",                                                               
  
        "1 1"=>"A",                                                               
  
        "1 2"=>"B",                                                               
  
        "2"  =>"c",                                                               
  
        "2 1"=> "C",                                                              
  
        "2 2"=>"D"                                                                
  
       }                                                                          
  

=head1 Labels

Label nodes so that they can be cross referenced and linked by L<Data::Edit::Xml::Lint>

=head2 addLabels($@)

Add the named labels to the specified B<$node> and return the number of labels added. Labels that are not L<defined|https://perldoc.perl.org/functions/defined.html> will be ignored.

     Parameter  Description
  1  $node      Node in parse tree
  2  @labels    Names of labels to add.

Example:


    ok $x->stringReplacingIdsWithLabels eq '<a><b><c/></b></a>';                                                
  
    my $b = $x->go(q(b));                                                            
  
    ok $b->countLabels == 0;                                                        
  
    $b->addLabels(1..2);                                                             
  
    $b->addLabels(3..4);                                                             
  
    ok $x->stringReplacingIdsWithLabels eq '<a><b id="1, 2, 3, 4"><c/></b></a>';                                 
  

=head2 countLabels($)

Return the count of the number of labels at a node.

     Parameter  Description
  1  $node      Node in parse tree.

Example:


    ok $x->stringReplacingIdsWithLabels eq '<a><b><c/></b></a>';                                                
  
    my $b = $x->go(q(b));                                                            
  
    ok $b->countLabels == 0;                                                        
  
    $b->addLabels(1..2);                                                             
  
    $b->addLabels(3..4);                                                             
  
    ok $x->stringReplacingIdsWithLabels eq '<a><b id="1, 2, 3, 4"><c/></b></a>';                                 
  
    ok $b->countLabels == 4;                                                      
  

=head2 labelsInTree($)

Return a hash of all the labels in a tree

     Parameter  Description
  1  $tree      Parse tree.

Example:


    ok -p (new $A->stringExtendingIdsWithLabels) eq <<END;                         
  <a id="aa, a, a5">
    <b id="bb, b, b2">
      <c id="cc, c, c1"/>
    </b>
    <b id="B, b4">
      <c id="C, c3"/>
    </b>
  </a>
  END
  
    is_deeply [sort keys %{$A->labelsInTree}],                                    
  
      ["B", "C", "a", "a5", "b", "b2", "b4", "c", "c1", "c3"];                    
  

=head2 getLabels($)

Return the names of all the labels set on a node.

     Parameter  Description
  1  $node      Node in parse tree.

Example:


    ok $x->stringReplacingIdsWithLabels eq '<a><b><c/></b></a>';                                                
  
    my $b = $x->go(q(b));                                                            
  
    ok $b->countLabels == 0;                                                        
  
    $b->addLabels(1..2);                                                             
  
    $b->addLabels(3..4);                                                             
  
    ok $x->stringReplacingIdsWithLabels eq '<a><b id="1, 2, 3, 4"><c/></b></a>';                                 
  
    is_deeply [1..4], [$b->getLabels];                                            
  

=head2 deleteLabels($@)

Delete the specified labels in the specified B<$node> or all labels if no labels have are specified and return that node.

     Parameter  Description
  1  $node      Node in parse tree
  2  @labels    Names of the labels to be deleted

Example:


    ok $x->stringReplacingIdsWithLabels eq '<a><b id="1, 2, 3, 4"><c id="1, 2, 3, 4"/></b></a>';              
  
    $b->deleteLabels(1,4) for 1..2;                                               
  
    ok $x->stringReplacingIdsWithLabels eq '<a><b id="2, 3"><c id="1, 2, 3, 4"/></b></a>';                    
  

=head2 copyLabels($$)

Copy all the labels from the source node to the target node and return the source node.

     Parameter  Description
  1  $source    Source node
  2  $target    Target node.

Example:


    ok $x->stringReplacingIdsWithLabels eq '<a><b id="1, 2, 3, 4"><c/></b></a>';                                 
  
    $b->copyLabels($c) for 1..2;                                                  
  
    ok $x->stringReplacingIdsWithLabels eq '<a><b id="1, 2, 3, 4"><c id="1, 2, 3, 4"/></b></a>';              
  

=head2 moveLabels($$)

Move all the labels from the source node to the target node and return the source node.

     Parameter  Description
  1  $source    Source node
  2  $target    Target node.

Example:


    ok $x->stringReplacingIdsWithLabels eq '<a><b id="2, 3"><c id="1, 2, 3, 4"/></b></a>';                    
  
    $b->moveLabels($c) for 1..2;                                                  
  
    ok $x->stringReplacingIdsWithLabels eq '<a><b><c id="1, 2, 3, 4"/></b></a>';                             
  

=head2 copyLabelsAndIdsInTree($$)

Copy all the labels and ids in the source parse tree to the matching nodes in the target parse tree. Nodes are matched via L<path|/path>. Return the number of labels and ids copied.

     Parameter  Description
  1  $source    Source node
  2  $target    Target node.

Example:


    ok -p (new $a->stringExtendingIdsWithLabels) eq <<END;                         
  <a id="a, a5">
    <b id="b, b2">
      <c id="c, c1"/>
    </b>
    <b id="B, b4">
      <c id="C, c3"/>
    </b>
  </a>
  END
  
    ok -p (new $A->stringExtendingIdsWithLabels) eq <<END;                        
  <a id="aa">
    <b id="bb">
      <c id="cc"/>
    </b>
    <b>
      <c/>
    </b>
  </a>
  END
  
    ok $a->copyLabelsAndIdsInTree($A) == 10;                                      
  
    ok -p (new $A->stringExtendingIdsWithLabels) eq <<END;                         
  <a id="aa, a, a5">
    <b id="bb, b, b2">
      <c id="cc, c, c1"/>
    </b>
    <b id="B, b4">
      <c id="C, c3"/>
    </b>
  </a>
  END
  

=head1 Operators

Operator access to methods use the assign versions to avoid 'useless use of operator in void context' messages. Use the non assign versions to return the results of the underlying method call.  Thus '/' returns the wrapping node, whilst '/=' does not.  Assign operators always return their left hand side even though the corresponding method usually returns the modification on the right.

=head2 opString($$)

-B: L<bitsNodeTextBlank|/bitsNodeTextBlank>

-b: L<isAllBlankText|/isAllBlankText>

-c: L<context|/context>

-e: L<prettyStringEnd|/prettyStringEnd>

-f: L<first node|/first>

-g: L<pathString|/pathString>

-l: L<last node|/last>

-M: L<number|/number>

-o: L<contentAsTags|/contentAsTags>

-p: L<prettyString|/prettyString>

-s: L<string|/string>

-S : L<stringNode|/stringNode>

-T : L<isText|/isText>

-t : L<tag|/tag>

-u: L<id|/id>

-W: L<unWrap|/unWrap>

-w: L<stringQuoted|/stringQuoted>

-x: L<prettyStringDitaHeaders|/prettyStringDitaHeaders>

-X: L<cut|/cut>

-z: L<prettyStringNumbered|/prettyStringNumbered>.

     Parameter  Description
  1  $node      Node
  2  $op        Monadic operator.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                           
  <a>
    <b><c>ccc</c></b>
    <d><e>eee</e></d>
  </a>
  END
  
   {my $a = Data::Edit::Xml::new(<<END);                                               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
    my ($c, $b, $e, $d) = $a->byList;                                             
  
    ok $c->printNode eq q(c id="42" match="mm");                                   
  
    ok -A $c eq q(c id="42" match="mm");                                          
  
    ok -b $e;                                                                     
  
    ok -c $e eq q(e d a);                                                          
  
    ok -f $b eq $c;                                                               
  
    ok -l $a eq $d;                                                               
  
    ok -O $a, q( b  d );                                                          
  
    ok -o $a, q(b d);                                                             
  
    ok -w $a eq q('<a><b><c id="42" match="mm"/></b><d><e/></d></a>');            
  
    ok -p $a eq <<END;                                                            #tdown #tdownX               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
    ok -s $a eq '<a><b><c id="42" match="mm"/></b><d><e/></d></a>';                
  
    ok -t $a eq 'a';                                                              
  
    $a->numberTree;                                                                
  
    ok -z $a eq <<END;                                                             
  <a id="1">
    <b id="2">
      <c id="42" match="mm"/>
    </b>
    <d id="4">
      <e id="5"/>
    </d>
  </a>
  END
  
   {my $a = Data::Edit::Xml::new(<<END);                                            
  <concept/>
  END
  
    Data::Edit::Xml::ditaOrganization = q(ACT);                                     
  
    ok $a->prettyStringDitaHeaders eq <<END;                                        
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE concept PUBLIC "-//ACT//DTD DITA Concept//EN" "concept.dtd" []>
  <concept/>
  END
  
    ok -x $a eq <<END;                                                              
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE concept PUBLIC "-//ACT//DTD DITA Concept//EN" "concept.dtd" []>
  <concept/>
  END
  

=head2 opContents($)

@{} : nodes immediately below a node.

     Parameter  Description
  1  $node      Node.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                           
  <a>
    <b><c>ccc</c></b>
    <d><e>eee</e></d>
  </a>
  END
  
    my ($b, $d) =  @$a;                                                           
  
    ok -c $b eq q(b a);                                                           
  
    my ($c)     =  @$b;                                                           
  
    ok -c $c eq q(c b a);                                                         
  

=head2 opAt($$)

<= : Check that a node is in the context specified by the referenced array of words.

     Parameter  Description
  1  $node      Node
  2  $context   Reference to array of words specifying the parents of the desired node.

Example:


    ok -p $a eq <<END;                                                            #tdown #tdownX               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
    ok (($a >= [qw(d e)]) <= [qw(e d a)]);                                         
  

=head2 opNew($$)

** : create a new node from the text on the right hand side: if the text contains a non word character \W the node will be create as text, else it will be created as a tag

     Parameter  Description
  1  $node      Node
  2  $text      Name node of node to create or text of new text element

Example:


   {my $a = Data::Edit::Xml::new("<a/>");                                         
  
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

> + : put a node or string after the specified B<$node> and return the new node.

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

+= : put a node or string after the specified B<$node>.

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

< - : put a node or string before the specified B<$node> and return the new node.

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

-= : put a node or string before the specified B<$node>,

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

x= : Traverse a L<parse|/parse> tree in post-order.

     Parameter  Description
  1  $node      Parse tree
  2  $code      Code to execute against each node.

Example:


    ok -p $a eq <<END;                                                            #tdown #tdownX               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
     {my $s; $a x= sub{$s .= -t $_}; ok $s eq "cbeda"                             
  

=head2 opGo($$)

>= : Search for a node via a specification provided as a reference to an array of words each number.  Each word represents a tag name, each number the index of the previous tag or zero by default.

     Parameter  Description
  1  $node      Node
  2  $go        Reference to an array of search parameters.

Example:


    ok -p $a eq <<END;                                                            #tdown #tdownX               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
    ok (($a >= [qw(d e)]) <= [qw(e d a)]);                                         
  

=head2 opAttr($$)

% : Get the value of an attribute of the specified B<$node>.

     Parameter  Description
  1  $node      Node
  2  $attr      Reference to an array of words and numbers specifying the node to search for.

Example:


   {my $a = Data::Edit::Xml::new('<a number="1"/>');                              
  
    ok $a %  qq(number) == 1;                                                     
  

=head2 opWrapWith($$)

/ : Wrap node with a tag, returning the wrapping node.

     Parameter  Description
  1  $node      Node
  2  $tag       Tag.

Example:


   {my $c = Data::Edit::Xml::new("<c/>");                                         
  
    my $b = $c / qq(b);                                                           
  
    ok -s $b eq "<b><c/></b>";                                                    
  
    my $a = $b / qq(a);                                                           
  
    ok -s $a eq "<a><b><c/></b></a>";                                             
  

=head2 opWrapContentWith($$)

* : Wrap content with a tag, returning the wrapping node.

     Parameter  Description
  1  $node      Node
  2  $tag       Tag.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b>
      <c/>
      <d/>
    </b>
  </a>
  END
  
    my ($c, $d, $b) = $a->byList;                                                 
  
    $b *= q(B);                                                                   
  
    ok -p $a eq <<END;                                                            
  <a>
    <b>
      <B>
        <c/>
        <d/>
      </B>
    </b>
  </a>
  END
  

=head2 opCut($)

-- : Cut out a node.

     Parameter  Description
  1  $node      Node.

Example:


   {my $x = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b><c/></b>
  </a>
  END
  
    my $b = $x >= qq(b);                                                          
  
     --$b;                                                                        
  
    ok -s $x eq "<a/>";                                                           
  
    ok -s $b eq "<b><c/></b>";                                                    
  

=head2 opUnwrap($)

++ : Unwrap a node.

     Parameter  Description
  1  $node      Node.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b>
      <c/>
      <d/>
    </b>
  </a>
  END
  
    my ($c, $d, $b) = $a->byList;                                                 
  
    $b++;                                                                         
  
    ok -p $a eq <<END;                                                            
  <a>
    <c/>
    <d/>
  </a>
  END
  

=head1 Statistics

Statistics describing the L<parse|/parse> tree.

=head2 count($@)

Return the count of the number of instances of the specified tags under the specified B<$node>, either by tag in array context or in total in scalar context.

     Parameter  Description
  1  $node      Node
  2  @names     Possible tags immediately under the node.

Example:


   {my $x = Data::Edit::Xml::new(<<END);                                           
  <a>
  
  </a>
  END
  
    ok $x->count == 0;                                                            
  

=head2 countTags($)

Count the number of tags in a L<parse|/parse> tree.

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

Return a reference to a hash showing the number of instances of each tag on and below the specified B<$node>.

     Parameter  Description
  1  $node      Node
  2  $count     Count of tags so far.

Example:


   {my $x = Data::Edit::Xml::new(<<END);                                            
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

Return a reference to a hash showing the number of instances of each attribute on and below the specified B<$node>.

     Parameter  Description
  1  $node      Node
  2  $count     Attribute count so far

Example:


   {my $x = Data::Edit::Xml::new(<<END);                                            
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
  

=head2 countAttrNamesOnTagExcluding($@)

Count the number of attributes owned by the specified B<$node> that are not in the specified list.

     Parameter  Description
  1  $node      Node
  2  @attr      Attributes to ignore

Example:


   {my $a = Data::Edit::Xml::new(q(<a a="1" b="2" c="3" d="4" e="5"/>));          
  

=head2 countAttrValues($$)

Return a reference to a hash showing the number of instances of each attribute value on and below the specified B<$node>.

     Parameter  Description
  1  $node      Node
  2  $count     Count of attributes so far.

Example:


   {my $x = Data::Edit::Xml::new(<<END);                                            
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


   {my $a = Data::Edit::Xml::newTree("a", id=>1, class=>2, href=>3, outputclass=>4); 
  
    is_deeply { 4 => 1 }, $a->countOutputClasses;                                 
  

=head2 changeReasonCommentSelectionSpecification()

Provide a specification to select L<change reason comments|/crc> to be inserted as text into a L<parse|/parse> tree. A specification can be either:

=over

=item the name of a code to be accepted,

=item a regular expression which matches the codes to be accepted,

=item a hash whose keys are defined for the codes to be accepted or

=item B<undef> (the default) to specify that no such comments should be accepted.

=back


Example:


    changeReasonCommentSelectionSpecification = {ccc=>1, ddd=>1};                  
  
    changeReasonCommentSelectionSpecification = undef;                             
  

This is a static method and so should be invoked as:

  Data::Edit::Xml::changeReasonCommentSelectionSpecification


=head2 crc($$$)

Insert a comment consisting of a code and an optional reason as text into the L<parse|/parse> tree to indicate the location of changes to the L<parse|/parse> tree.  As such comments tend to become very numerous, only comments whose codes matches the specification provided in L<changeReasonCommentSelectionSpecification|/changeReasonCommentSelectionSpecification> are accepted for insertion. Subsequently these comments can be easily located using:

B<grep -nr "<!-->I<code>B<">

on the file containing a printed version of the L<parse|/parse> tree. Please note that these comments will be removed if the output file is reparsed.

Returns the specified B<$node>.

     Parameter  Description
  1  $node      Node being changed
  2  $code      Reason code
  3  $reason    Optional text description of change

Example:


   {my $a = Data::Edit::Xml::new("<a><b/></a>");                                  
  
    my ($b) = $a->contents;                                                       
  
    changeReasonCommentSelectionSpecification = {ccc=>1, ddd=>1};                  
  
    $b->putFirst(my $c = $b->newTag(q(c)));                                       
  
    $c->crc($_) for qw(aaa ccc);                                                  
  
    ok <<END eq -p $a;                                                            
  <a>
    <b><!--ccc-->
      <c/>
    </b>
  </a>
  END
  
    changeReasonCommentSelectionSpecification = undef;                             
  
    $c->putFirst(my $d = $c->newTag(q(d)));                                       
  
    $d->crc($_) for qw(aaa ccc);                                                  
  
    ok <<END eq -p $a;                                                            
  <a>
    <b><!--ccc-->
      <c>
        <d/>
      </c>
    </b>
  </a>
  END
  

=head2 howFirst($)

Return the depth to which the specified B<$node> is L<first|/isFirst> else B<0>.

     Parameter  Description
  1  $node      Node

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <b>
      <c/>
    </b>
    <e>
      <f/>
    </e>
  </a>
  END
  
    my ($d, $c, $b, $C, $B, $f, $e) = $a->byList;                                              
  
    ok $d->howFirst     == 4;                                                     
  

=head2 howLast($)

Return the depth to which the specified B<$node> is L<last|/isLast> else B<0>.

     Parameter  Description
  1  $node      Node

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <b>
      <c/>
    </b>
    <e>
      <f/>
    </e>
  </a>
  END
  
    my ($d, $c, $b, $C, $B, $f, $e) = $a->byList;                                              
  
    ok $f->howLast      == 3;                                                     
  

=head2 howOnlyChild($)

Return the depth to which the specified B<$node> is an L<only child|/isOnlyChild> else B<0>.

     Parameter  Description
  1  $node      Node

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <b>
      <c/>
    </b>
    <e>
      <f/>
    </e>
  </a>
  END
  
    my ($d, $c, $b, $C, $B, $f, $e) = $a->byList;                                              
  
    ok $d->howOnlyChild == 2;                                                     
  

=head2 howFar($$)

Return how far the first node is from the second node along a path through their common ancestor.

     Parameter  Description
  1  $first     First node
  2  $second    Second node

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <b>
      <c/>
    </b>
    <e>
      <f/>
    </e>
  </a>
  END
  
    my ($d, $c, $b, $C, $B, $f, $e) = $a->byList;                                              
  
    is_deeply [$d->commonAdjacentAncestors($C)], [$b, $B];                                                       
  
    ok $d->howFar($d) == 0;                                                       
  
    ok $d->howFar($a) == 3;                                                       
  
    ok $b->howFar($B) == 1;                                                       
  
    ok $d->howFar($f) == 5;                                                       
  
    ok $d->howFar($C) == 4;                                                       
  

=head2 howFarAbove($$)

Return how far the first node is  L<above|/above> the second node is or B<0> if the first node is not strictly L<above|/above> the second node.

     Parameter  Description
  1  $above     First node above
  2  $below     Second node below

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <b>
      <c/>
    </b>
    <e>
      <f/>
    </e>
  </a>
  END
  
    my ($d, $c, $b, $C, $B, $f, $e) = $a->byList;                                              
  
    ok  $a->howFarAbove($d) == 3;                                                 
  
    ok !$d->howFarAbove($c);                                                      
  

=head2 howFarBelow($$)

Return how far the first node is  L<below|/below> the second node is or B<0> if the first node is not strictly L<below|/below> the second node.

     Parameter  Description
  1  $below     First node below
  2  $above     Second node above

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                                       
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
    <b>
      <c/>
    </b>
    <e>
      <f/>
    </e>
  </a>
  END
  
    my ($d, $c, $b, $C, $B, $f, $e) = $a->byList;                                              
  
    ok  $d->howFarBelow($a) == 3;                                                 
  
    ok !$c->howFarBelow($d);                                                      
  

=head1 Required clean up

Insert required clean up tags.

=head2 requiredCleanUp($$)

Replace a node with a required cleanup node around the text of the replaced node with special characters replaced by symbols.

Returns the specified B<$node>.

     Parameter     Description
  1  $node         Node
  2  $outputclass  Optional outputclass attribute of required cleanup tag

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b>
      <c>
        ccc
      </c>
    </b>
  </a>
  END
  
    my ($b) = $a->contents;                                                       
  
    $b->requiredCleanUp(q(33));                                                   
  
    ok -p $a eq <<END;                                                            
  <a>
    <required-cleanup outputclass="33">&lt;b&gt;
    &lt;c&gt;
        ccc
      &lt;/c&gt;
  &lt;/b&gt;
  </required-cleanup>
  </a>
  END
  

=head2 replaceWithRequiredCleanUp($$)

Replace a node with a required cleanup message and return the new node

     Parameter  Description
  1  $node      Node to be replace
  2  $text      Clean up message

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b/>
  </a>
  END
  
    my ($b) = $a->contents;                                                       
  
    $b->replaceWithRequiredCleanUp(q(bb));                                        
  
    ok -p $a eq <<END;                                                            
  <a>
    <required-cleanup>bb</required-cleanup>
  </a>
  END
  

=head2 putFirstRequiredCleanUp($$)

Place a required cleanup tag first under a node and return the required clean up node.

     Parameter  Description
  1  $node      Node
  2  $text      Clean up message

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b/>
  </a>
  END
  
    $a->putFirstRequiredCleanUp(qq(1111
));                                      
  
    ok -p $a eq <<END;                                                             
  <a>
    <required-cleanup>1111
  </required-cleanup>
    <b/>
  </a>
  END
  

=head2 putLastRequiredCleanUp($$)

Place a required cleanup tag last under a node and return the required clean up node.

     Parameter  Description
  1  $node      Node
  2  $text      Clean up message

Example:


    ok -p $a eq <<END;                                                             
  <a>
    <required-cleanup>1111
  </required-cleanup>
    <b/>
  </a>
  END
  
    $a->putLastRequiredCleanUp(qq(4444
));                                       
  
    ok -p $a eq <<END;                                                             
  <a>
    <required-cleanup>1111
  </required-cleanup>
    <b/>
    <required-cleanup>4444
  </required-cleanup>
  </a>
  END
  

=head2 putNextRequiredCleanUp($$)

Place a required cleanup tag after a node.

     Parameter  Description
  1  $node      Node
  2  $text      Clean up message

Example:


    ok -p $a eq <<END;                                                             
  <a>
    <required-cleanup>1111
  </required-cleanup>
    <b/>
    <required-cleanup>4444
  </required-cleanup>
  </a>
  END
  
    $a->go(q(b))->putNextRequiredCleanUp(qq(3333
));                             
  
    ok -p $a eq <<END;                                                              
  <a>
    <required-cleanup>1111
  </required-cleanup>
    <b/>
    <required-cleanup>3333
  </required-cleanup>
    <required-cleanup>4444
  </required-cleanup>
  </a>
  END
  

=head2 putPrevRequiredCleanUp($$)

Place a required cleanup tag before a node.

     Parameter  Description
  1  $node      Node
  2  $text      Clean up message

Example:


    ok -p $a eq <<END;                                                              
  <a>
    <required-cleanup>1111
  </required-cleanup>
    <b/>
    <required-cleanup>3333
  </required-cleanup>
    <required-cleanup>4444
  </required-cleanup>
  </a>
  END
  
    $a->go(q(b))->putPrevRequiredCleanUp(qq(2222
));                             
  
    ok -p $a eq <<END;                                                            
  <a>
    <required-cleanup>1111
  </required-cleanup>
    <required-cleanup>2222
  </required-cleanup>
    <b/>
    <required-cleanup>3333
  </required-cleanup>
    <required-cleanup>4444
  </required-cleanup>
  </a>
  END
  

=head1 Conversions

Methods useful for conversions to and from word, L<html|https://www.w3.org/TR/html52/index.html#contents> and L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html>.

=head2 ditaListToSteps($@)

Change the specified B<$node> to B<steps> and its contents to B<cmd\step> optionally only in the specified context.

     Parameter  Description
  1  $list      Node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


    ok -p $a eq <<END;                                                              
  <dita>
    <ol>
      <li>
        <p>aaa</p>
      </li>
      <li>
        <p>bbb</p>
      </li>
    </ol>
  </dita>
  END
  
    $a->first->ditaListToSteps;                                                   
  
    ok -p $a eq <<END;                                                            
  <dita>
    <steps>
      <step>
        <cmd>aaa</cmd>
      </step>
      <step>
        <cmd>bbb</cmd>
      </step>
    </steps>
  </dita>
  END
  

=head2 ditaListToStepsUnordered($@)

Change the specified B<$node> to B<steps-unordered> and its contents to B<cmd\step> optionally only in the specified context.

     Parameter  Description
  1  $list      Node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


    ok -p $a eq <<END;                                                             
  <dita>
    <ol>
      <li>aaa</li>
      <li>bbb</li>
    </ol>
  </dita>
  END
  
    $a->first->ditaListToStepsUnordered;                                          
  
    ok -p $a eq <<END;                                                            
  <dita>
    <steps-unordered>
      <step>
        <cmd>aaa</cmd>
      </step>
      <step>
        <cmd>bbb</cmd>
      </step>
    </steps-unordered>
  </dita>
  END
  

=head2 ditaListToSubSteps($@)

Change the specified B<$node> to B<substeps> and its contents to B<cmd\step> optionally only in the specified context.

     Parameter  Description
  1  $list      Node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <dita>
    <ol>
      <li>aaa</li>
      <li>bbb</li>
    </ol>
  </dita>
  END
  
    $a->first->ditaListToSubSteps;                                                
  
    ok -p $a eq <<END;                                                            
  <dita>
    <substeps>
      <substep>
        <cmd>aaa</cmd>
      </substep>
      <substep>
        <cmd>bbb</cmd>
      </substep>
    </substeps>
  </dita>
  END
  

=head2 ditaStepsToList($@)

Change the specified B<$node> to B<ol> and its B<cmd\step> content to B<li> optionally only in the specified context.

     Parameter  Description
  1  $steps     Node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


    ok -p $a eq <<END;                                                              
  <dita>
    <ol>
      <li>
        <p>aaa</p>
      </li>
      <li>
        <p>bbb</p>
      </li>
    </ol>
  </dita>
  END
  
    $a->first->ditaStepsToList;                                                   
  
    ok -p $a eq <<END;                                                             
  <dita>
    <ol>
      <li>aaa</li>
      <li>bbb</li>
    </ol>
  </dita>
  END
  

=head2 ditaMergeLists($@)

Merge the specified B<$node> with the preceding or following list or steps or substeps if possible and return the specified B<$node> regardless.

     Parameter  Description
  1  $node      Node
  2  @context   Optional context

Use the optional B<@context> parameter to test the context of the specified
B<$node> as understood by method L<at|/at>. If the context is supplied and
B<$node> is not in this context then this method returns B<undef> immediately.



Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <li id="1"/>
    <ol/>
    <ol>
      <li id="2"/>
      <li id="3"/>
    </ol>
  </a>
  END
  
    $a x= sub{$_->ditaMergeLists};                                                
  
    ok -p $a eq <<END;                                                            
  <a>
    <ol>
      <li id="1"/>
      <li id="2"/>
      <li id="3"/>
    </ol>
  </a>
  END
  

=head2 ditaMaximumNumberOfEntriesInARow($)

Return the maximum number of entries in the rows of the specified B<$table> or B<undef> if not a table.

     Parameter  Description
  1  $table     Table node

Example:


  if (1)                                                                           
   {my $a = Data::Edit::Xml::new(<<END);
  <table>
    <tgroup>
      <tbody>
        <row><entry/></row>
        <row><entry/><entry/></row>
        <row><entry/><entry/><entry/></row>
        <row><entry/><entry/></row>
        <row/>
      </tbody>
    </tgroup>
  </table>
  END
  
    ok 3 == $a->ditaMaximumNumberOfEntriesInARow;
    $a->first->ditaAddColSpecToTgroup(3);
  
    ok -p $a eq <<END
  <table>
    <tgroup cols="3">
      <colspec colname="c1" colnum="1" colwidth="1*"/>
      <colspec colname="c2" colnum="2" colwidth="1*"/>
      <colspec colname="c3" colnum="3" colwidth="1*"/>
      <tbody>
        <row>
          <entry/>
        </row>
        <row>
          <entry/>
          <entry/>
        </row>
        <row>
          <entry/>
          <entry/>
          <entry/>
        </row>
        <row>
          <entry/>
          <entry/>
        </row>
        <row/>
      </tbody>
    </tgroup>
  </table>
  END
   }
  

=head2 ditaAddColSpecToTgroup($$)

Add the specified B<$number> of column specification to a specified B<$tgroup> which does not have any already.

     Parameter  Description
  1  $tgroup    Tgroup node
  2  $number    Number of colspecs to add

Example:


  if (1)                                                                           
   {my $a = Data::Edit::Xml::new(<<END);
  <table>
    <tgroup>
      <tbody>
        <row><entry/></row>
        <row><entry/><entry/></row>
        <row><entry/><entry/><entry/></row>
        <row><entry/><entry/></row>
        <row/>
      </tbody>
    </tgroup>
  </table>
  END
  
    ok 3 == $a->ditaMaximumNumberOfEntriesInARow;
    $a->first->ditaAddColSpecToTgroup(3);
  
    ok -p $a eq <<END
  <table>
    <tgroup cols="3">
      <colspec colname="c1" colnum="1" colwidth="1*"/>
      <colspec colname="c2" colnum="2" colwidth="1*"/>
      <colspec colname="c3" colnum="3" colwidth="1*"/>
      <tbody>
        <row>
          <entry/>
        </row>
        <row>
          <entry/>
          <entry/>
        </row>
        <row>
          <entry/>
          <entry/>
          <entry/>
        </row>
        <row>
          <entry/>
          <entry/>
        </row>
        <row/>
      </tbody>
    </tgroup>
  </table>
  END
   }
  

=head2 ditaFixTableColSpec($)

Improve the specified B<$table> by making obvious improvements.

     Parameter  Description
  1  $table     Table node

Example:


  if (1)                                                                          
   {my $a = Data::Edit::Xml::new(<<END);
  <table>
    <tbody>
      <row><entry/></row>
      <row><entry/><entry/></row>
      <row><entry/><entry/><entry/></row>
      <row><entry/><entry/></row>
      <row>
        <entry>
          <table>
            <tbody>
              <row><entry/><entry/><entry/><entry/><entry/><entry/><entry/></row>
            </tbody>
          </table>
        </entry>
      </row>
   </tbody>
  </table>
  END
  
    $a->ditaFixTableColSpec;
  
    ok -p $a eq <<END
  <table>
    <tgroup cols="3">
      <colspec colname="c1" colnum="1" colwidth="1*"/>
      <colspec colname="c2" colnum="2" colwidth="1*"/>
      <colspec colname="c3" colnum="3" colwidth="1*"/>
      <tbody>
        <row>
          <entry/>
        </row>
        <row>
          <entry/>
          <entry/>
        </row>
        <row>
          <entry/>
          <entry/>
          <entry/>
        </row>
        <row>
          <entry/>
          <entry/>
        </row>
        <row>
          <entry>
            <table>
              <tbody>
                <row>
                  <entry/>
                  <entry/>
                  <entry/>
                  <entry/>
                  <entry/>
                  <entry/>
                  <entry/>
                </row>
              </tbody>
            </table>
          </entry>
        </row>
      </tbody>
    </tgroup>
  </table>
  END
   }
  

=head2 ditaObviousChanges($)

Make obvious changes to a L<parse|/parse> tree to make it look more like L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html>.

     Parameter  Description
  1  $node      Node

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <dita>
    <ol>
      <li><para>aaa</para></li>
      <li><para>bbb</para></li>
    </ol>
  </dita>
  END
  
    $a->ditaObviousChanges;                                                       
  
    ok -p $a eq <<END;                                                              
  <dita>
    <ol>
      <li>
        <p>aaa</p>
      </li>
      <li>
        <p>bbb</p>
      </li>
    </ol>
  </dita>
  END
  

=head2 ditaOrganization()

Set the dita organization field in the xml headers, set by default to OASIS.


Example:


   {my $a = Data::Edit::Xml::new(<<END);                                            
  <concept/>
  END
  
    Data::Edit::Xml::ditaOrganization = q(ACT);                                     
  
    ok $a->prettyStringDitaHeaders eq <<END;                                        
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE concept PUBLIC "-//ACT//DTD DITA Concept//EN" "concept.dtd" []>
  <concept/>
  END
  
    ok -x $a eq <<END;                                                              
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE concept PUBLIC "-//ACT//DTD DITA Concept//EN" "concept.dtd" []>
  <concept/>
  END
  

=head2 ditaTopicHeaders($)

Add xml headers for the dita document type indicated by the specified L<parse|/parse> tree

     Parameter  Description
  1  $node      Node in parse tree

Example:


    ok Data::Edit::Xml::new(q(<concept/>))->ditaTopicHeaders eq <<END;            
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd" []>
  END
  

=head2 ditaPrettyPrintWithHeaders($)

Add xml headers for the dita document type indicated by the specified L<parse|/parse> tree to a pretty print of the parse tree.

     Parameter  Description
  1  $node      Node in parse tree

Example:


  if (1)                                                                          
   {my $a = Data::Edit::Xml::new(q(<concept/>));
    ok $a->ditaPrettyPrintWithHeaders eq <<END;
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE concept PUBLIC "-//ACT//DTD DITA Concept//EN" "concept.dtd" []>
  <concept/>
  END
   }
  

=head2 htmlHeadersToSections($)

Position sections just before html header tags so that subsequently the document can be divided into L<sections|/divideDocumentIntoSections>.

     Parameter  Description
  1  $node      Parse tree

Example:


   {my $x = Data::Edit::Xml::new(<<END);                                           
  <x>
  <h1>h1</h1>
    H1
  <h2>h2</h2>
    H2
  <h3>h3</h3>
    H3
  <h3>h3</h3>
    H3
  <h2>h2</h2>
    H2
  <h4>h4</h4>
    H4
  </x>
  END
  
  $x->htmlHeadersToSections;                                                       
  
    $x->divideDocumentIntoSections(sub                                             
  
     {my ($topicref, $section) = @_;                                               
  
      my $file = keys %file;                                                       
  
      $topicref->href = $file;                                                     
  
      $file{$file} = -p $section;                                                  
  
      $section->cut;                                                               
  
     });                                                                           
  
    ok -p $x eq <<END;                                                             
  <x>
    <topicref href="0">
      <topicref href="1">
        <topicref href="2"/>
        <topicref href="3"/>
      </topicref>
      <topicref href="4">
        <topicref href="5"/>
      </topicref>
    </topicref>
  </x>
  END
  
    ok  nn(dump({map {$_=>nn($file{$_})} keys %file})) eq nn(dump(                 
  
     {"0" => "<section level=\"1\">N  <h1>h1</h1>NN  H1NN</section>N",             
  
      "1" => "<section level=\"2\">N  <h2>h2</h2>NN  H2NN</section>N",             
  
      "2" => "<section level=\"3\">N  <h3>h3</h3>NN  H3NN</section>N",             
  
      "3" => "<section level=\"3\">N  <h3>h3</h3>NN  H3NN</section>N",             
  
      "4" => "<section level=\"2\">N  <h2>h2</h2>NN  H2NN</section>N",             
  
      "5" => "<section level=\"4\">N  <h4>h4</h4>NN  H4NN</section>N",             
  

=head2 divideDocumentIntoSections($$)

Divide a L<parse|/parse> tree into sections by moving non B<section> tags into their corresponding B<section> so that the B<section> tags expand until they are contiguous. The sections are then cut out by applying the specified sub to each B<section> tag in the L<parse|/parse> tree. The specified sub will receive the containing B<topicref> and the B<section> to be cut out as parameters allowing a reference to the cut out section to be inserted into the B<topicref>.

     Parameter  Description
  1  $node      Parse tree
  2  $cutSub    Cut out sub

Example:


   {my $x = Data::Edit::Xml::new(<<END);                                           
  <x>
  <h1>h1</h1>
    H1
  <h2>h2</h2>
    H2
  <h3>h3</h3>
    H3
  <h3>h3</h3>
    H3
  <h2>h2</h2>
    H2
  <h4>h4</h4>
    H4
  </x>
  END
  
  $x->htmlHeadersToSections;                                                       
  
    $x->divideDocumentIntoSections(sub                                             
  
     {my ($topicref, $section) = @_;                                               
  
      my $file = keys %file;                                                       
  
      $topicref->href = $file;                                                     
  
      $file{$file} = -p $section;                                                  
  
      $section->cut;                                                               
  
     });                                                                           
  
    ok -p $x eq <<END;                                                             
  <x>
    <topicref href="0">
      <topicref href="1">
        <topicref href="2"/>
        <topicref href="3"/>
      </topicref>
      <topicref href="4">
        <topicref href="5"/>
      </topicref>
    </topicref>
  </x>
  END
  
    ok  nn(dump({map {$_=>nn($file{$_})} keys %file})) eq nn(dump(                 
  
     {"0" => "<section level=\"1\">N  <h1>h1</h1>NN  H1NN</section>N",             
  
      "1" => "<section level=\"2\">N  <h2>h2</h2>NN  H2NN</section>N",             
  
      "2" => "<section level=\"3\">N  <h3>h3</h3>NN  H3NN</section>N",             
  
      "3" => "<section level=\"3\">N  <h3>h3</h3>NN  H3NN</section>N",             
  
      "4" => "<section level=\"2\">N  <h2>h2</h2>NN  H2NN</section>N",             
  
      "5" => "<section level=\"4\">N  <h4>h4</h4>NN  H4NN</section>N",             
  

=head2 ditaParagraphToNote($$)

Convert all <p> nodes to <note> if the paragraph starts with 'Note:', optionally wrapping the content of the <note> with a <p>

     Parameter                     Description
  1  $node                         Parse tree
  2  $wrapNoteContentWithParagaph  Wrap the <note> content with a <p> if true

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <p> Note: see over for details.</p>
  </a>
  END
  
    $a->ditaParagraphToNote(1);                                                   
  
    ok -p $a eq <<END;                                                            
  <a>
    <note>
      <p>See over for details.</p>
    </note>
  </a>
  END
  

=head2 wordStyles($)

Extract style information from a parse tree representing a word document.

     Parameter  Description
  1  $x         Parse tree

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
   <text:list-style style:name="aa">
     <text:list-level-style-bullet text:level="2"/>
   </text:list-style>
  </a>
  END
  
    my $styles = $a->wordStyles;                                                  
  
    is_deeply $styles, {bulletedList=>{aa=>{2=>1}}};                              
  

=head2 htmlTableToDita($)

Convert an L<html table|https://www.w3.org/TR/html52/tabular-data.html#the-table-element> to a L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> table.

     Parameter  Description
  1  $table     Html table node

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
   <table>
     <thead>
      <tr>
         <th>Month</th>
         <th>Savings</th>
         <th>Phone</th>
         <th>Comment</th>
      </tr>
     </thead>
     <tbody>
      <tr>
         <td>January</td>
         <td>100</td>
         <td>555-1212</td>
      </tr>
      <tr>
         <td>February</td>
         <td>80</td>
      </tr>
     </tbody>
  </table>
  END
  
    $a->htmlTableToDita;                                                          
  
    ok -p $a eq <<END;                                                            
  <table>
    <tgroup cols="4">
      <colspec colname="c1" colnum="1" colwidth="1*"/>
      <colspec colname="c2" colnum="2" colwidth="1*"/>
      <colspec colname="c3" colnum="3" colwidth="1*"/>
      <colspec colname="c4" colnum="4" colwidth="1*"/>
      <thead>
        <row>
          <entry>Month</entry>
          <entry>Savings</entry>
          <entry>Phone</entry>
          <entry>Comment</entry>
        </row>
      </thead>
      <tbody>
        <row>
          <entry>January</entry>
          <entry>100</entry>
          <entry nameend="c4" namest="c3">555-1212</entry>
        </row>
        <row>
          <entry>February</entry>
          <entry nameend="c4" namest="c2">80</entry>
        </row>
      </tbody>
    </tgroup>
  </table>
  END
  

=head1 Debug

Debugging methods

=head2 printAttributes($)

Print the attributes of a node.

     Parameter  Description
  1  $node      Node whose attributes are to be printed.

Example:


   {my $x = Data::Edit::Xml::new(my $s = <<END);                                  
  <a no="1" word="first"/>
  END
  
    ok $x->printAttributes eq qq( no="1" word="first");                            
  

=head2 printNode($)

Print the tag and attributes of a node.

     Parameter  Description
  1  $node      Node to be printed.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                               
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END
  
    ok $c->printNode eq q(c id="42" match="mm");                                   
  

=head2 goFish($@)

A debug version of L<go|/go> that returns additional information explaining any failure to reach the node identified by the L<path|/path>.

Returns ([B<reachable tag>...], B<failing tag>, [B<possible tag>...]) where:

=over

=item B<reachable tag>

the path elements successfully traversed;

=item B<failing tag>

the failing element;

=item B<possible tag>

the possibilities at the point where the path failed if it failed else B<undef>.

=back

Parameters:

     Parameter  Description
  1  $node      Node
  2  @path      Search specification.

Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b>
      <c>
        <d/>
      </c>
      <c/>
    </b>
    <b/>
  </a>
  END
  
      my ($good, $fail, $possible) = $a->goFish(qw(b c D));                       
  
      ok  $fail eq q(D);                                                          
  
      is_deeply $good,     [qw(b c)];                                             
  
      is_deeply $possible, [q(d)];                                                
  

=head1 Compression

Read and write files of compressed xml.  These methods provide a compact, efficient way to store and retrieve parse trees to/from files.

=head2 writeCompressedFile($$)

Write the parse tree starting at B<$node> as compressed xml to the specified B<$file>. Use L<readCompressedFile|/readCompressedFile>  to read the B<$file>.

     Parameter  Description
  1  $node      Parse tree node
  2  $file      File to write to.

Example:


    my $a = Data::Edit::Xml::new(q(<a>).(q(<b>𝝱</b>)x1e3).q(</a>));                
  
    my $file = $a->writeCompressedFile(q(zzz.xml.zip));                            
  
    my $A = readCompressedFile($file);                                             
  
    ok $a->equals($A);                                                             
  

=head2 readCompressedFile($)

Read the specified B<$file> containing compressed xml and return the root node.  Use L<writeCompressedFile|/writeCompressedFile> to write the B<$file>.

     Parameter  Description
  1  $file      File to read.

Example:


    my $a = Data::Edit::Xml::new(q(<a>).(q(<b>𝝱</b>)x1e3).q(</a>));                
  
    my $file = $a->writeCompressedFile(q(zzz.xml.zip));                            
  
    my $A = readCompressedFile($file);                                             
  
    ok $a->equals($A);                                                             
  

This is a static method and so should be invoked as:

  Data::Edit::Xml::readCompressedFile


=head1 Autoload

Allow methods with constant parameters to be called as B<method_p1_p2>...(variable parameters) whenever it is easier to type underscores than (qw()).

=head2 AUTOLOAD()

Allow methods with constant parameters to be called as B<method_p1_p2>...(variable parameters) whenever it is easier to type underscores than (qw()).


Example:


   {my $a = Data::Edit::Xml::new(<<END);                                          
  <a>
    <b>
      <c/>
    </b>
  </a>
  END
  
    my ($c, $b) = $a->byList;                                                     
  
    ok  $c->at_c_b_a;                                                             
  
    ok !$c->at_b;                                                                 
  
    ok  -t $c->change_d_c_b eq q(d);                                              
  
    ok !   $c->change_d_b;                                                        
  
  if (1)                                                                          
   {my $a = Data::Edit::Xml::new(<<END);
  <a><b><c/><d/><e/><f/></b></a>
  END
  
    ok -t $a->first_b__first_c__next__next_e__next eq q(f);
    ok   !$a->first_b__first_c__next__next_f;
   }
  


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

=head2 normalizeWhiteSpace($)

Normalize white space, remove comments DOCTYPE and xml processors from a string

     Parameter  Description
  1  $string    String to normalize

This is a static method and so should be invoked as:

  Data::Edit::Xml::normalizeWhiteSpace


=head2 prettyStringEnd($)

Return a readable string representing a node of a L<parse|/parse> tree and all the nodes below it as a here document

     Parameter  Description
  1  $node      Start node

=head2 byX2($$@)

Post-order traversal of a L<parse|/parse> tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call
  3  @context   Accumulated context.

=head2 byX22($$@)

Post-order traversal of a L<parse|/parse> tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call
  3  @context   Accumulated context.

=head2 downX2($$@)

Pre-order traversal of a L<parse|/parse> tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call
  3  @context   Accumulated context.

=head2 downX22($$@)

Pre-order traversal down through a L<parse|/parse> tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context.

=head2 atPositionMatch($$)

Confirm that a string matches a match expression.

     Parameter  Description
  1  $tag       Starting node
  2  $match     Ancestry.

=head2 numberNode($)

Ensure that the specified B<$node> has a number.

     Parameter  Description
  1  $node      Node

=head2 createRequiredCleanUp($$)

Create a required clean up node

     Parameter  Description
  1  $node      Node
  2  $text      Clean up message

=head2 ditaMergeListsOnce($)

Merge the specified B<$node> with the preceding or following list or steps or substeps if possible and return the specified B<$node> regardless.

     Parameter  Description
  1  $node      Node

=head2 ditaAddPadEntriesToRows($$)

Adding padding entries to a table to make sure every row has the same number of entries

     Parameter  Description
  1  $table     Table node
  2  $nEntries  Number of entries

=head2 topicTypeAndBody($)

Topic type and corresponding body.

     Parameter  Description
  1  $type      Type from qw(bookmap concept reference task)

=head2 getSectionHeadingLevel($)

Get the heading level from a section tag.

     Parameter  Description
  1  $o         Node

=head2 printAttributesReplacingIdsWithLabels($)

Print the attributes of a node replacing the id with the labels.

     Parameter  Description
  1  $node      Node whose attributes are to be printed.

=head2 printAttributesExtendingIdsWithLabels($)

Print the attributes of a node extending the id with the labels.

     Parameter  Description
  1  $node      Node whose attributes are to be printed.

=head2 checkParentage($)

Check the parent pointers are correct in a L<parse|/parse> tree.

     Parameter  Description
  1  $x         Parse tree.

=head2 checkParser($)

Check that every node has a L<parse|/parse>r.

     Parameter  Description
  1  $x         Parse tree.

=head2 nn($)

Replace new lines in a string with N to make testing easier.

     Parameter  Description
  1  $s         String.


=head1 Synonyms

B<firstLeaf> is a synonym for L<downWhileFirst|/downWhileFirst> - Move down from the specified B<$node> as long as each lower node is a first node.

B<lastLeaf> is a synonym for L<downWhileLast|/downWhileLast> - Move down from the specified B<$node> as long as each lower node is a last node.

B<mnt> is a synonym for L<matchesNextTags|/matchesNextTags> - Return the specified b<$node> if the siblings following the specified B<$node> L<match|/atPositionMatch> the specified <@tags> else return B<undef>.

B<mpt> is a synonym for L<matchesPrevTags|/matchesPrevTags> - Return the specified b<$node> if the siblings prior to the specified B<$node> L<match|/atPositionMatch> the specified <@tags> else return B<undef>.

B<oat> is a synonym for L<overAllTags|/overAllTags> - Return the specified b<$node> if all of it's child nodes L<match|/atPositionMatch> the specified <@tags> else return B<undef>.

B<oft> is a synonym for L<overFirstTags|/overFirstTags> - Return the specified b<$node> if the first of it's child nodes L<match|/atPositionMatch> the specified <@tags> else return B<undef>.

B<olt> is a synonym for L<overLastTags|/overLastTags> - Return the specified b<$node> if the last of it's child nodes L<match|/atPositionMatch> the specified <@tags> else return B<undef>.



=head1 Index


1 L<above|/above> - Return the first node if the first node is above the second node optionally checking that the first node is in the specified context otherwise return B<undef>

2 L<abovePath|/abovePath> - Return the nodes along the path from the first node down to the second node when the first node is above the second node else return B<()>.

3 L<addConditions|/addConditions> - Add conditions to a node and return the node.

4 L<addFirst|/addFirst> - Add a new node L<first|/first> below the specified B<$node> and return the new node unless a node with that tag already exists in which case return the existing B<$node>.

5 L<addFirstAsText|/addFirstAsText> - Add a new text node first below the specified B<$node> and return the new node unless a text node already exists there and starts with the same text in which case return the existing B<$node>.

6 L<addLabels|/addLabels> - Add the named labels to the specified B<$node> and return the number of labels added.

7 L<addLast|/addLast> - Add a new node L<last|/last> below the specified B<$node> and return the new node unless a node with that tag already exists in which case return the existing B<$node>.

8 L<addLastAsText|/addLastAsText> - Add a new text node last below the specified B<$node> and return the new node unless a text node already exists there and ends with the same text in which case return the existing B<$node>.

9 L<addNext|/addNext> - Add a new node L<next|/next> to the specified B<$node> and return the new node unless a node with that tag already exists in which case return the existing B<$node>.

10 L<addNextAsText|/addNextAsText> - Add a new text node after the specified B<$node> and return the new node unless a text node already exists there and starts with the same text in which case return the existing B<$node>.

11 L<addPrev|/addPrev> - Add a new node L<before|/prev> the specified B<$node> and return the new node unless a node with that tag already exists in which case return the existing B<$node>.

12 L<addPrevAsText|/addPrevAsText> - Add a new text node before the specified B<$node> and return the new node unless a text node already exists there and ends with the same text in which case return the existing B<$node>.

13 L<addSingleChild|/addSingleChild> - Wrap the content of a specified B<$node> in a new node with the specified B<$tag> and optional B<%attribute> unless the content is already wrapped in a single child with the specified B<$tag>.

14 L<addWrapWith|/addWrapWith> - L<Wrap|/wrap> the specified B<$node> with the specified tag if the node is not already wrapped with such a tag and return the new node unless a node with that tag already exists in which case return the existing B<$node>.

15 L<adjacent|/adjacent> - Return the first node if it is adjacent to the second node else B<undef>.

16 L<after|/after> - Return the first node if it occurs after the second node in the L<parse|/parse> tree optionally checking that the first node is in the specified context or else B<undef> if the node is L<above|/above>, L<below|/below> or L<before|/before> the target.

17 L<allConditions|/allConditions> - Return the node if it has all of the specified conditions, else return B<undef>

18 L<an|/an> - Return the next node if the specified B<$node> has the specified tag and the next node is in the specified context.

19 L<ancestry|/ancestry> - Return a list containing: (the specified B<$node>, its parent, its parent's parent etc.

20 L<anyCondition|/anyCondition> - Return the node if it has any of the specified conditions, else return B<undef>

21 L<ap|/ap> - Return the previous node if the specified B<$node> has the specified tag and the previous node is in the specified context.

22 L<apn|/apn> - Return (previous node, next node) if the previous and current nodes have the specified tags and the next node is in the specified context else return B<()>.

23 L<at|/at> - Confirm that the specified B<$node> has the specified L<ancestry|/ancestry> and return the specified B<$node> if it does else B<undef>.

24 L<atOrBelow|/atOrBelow> - Confirm that the node or one of its ancestors has the specified context as recognized by L<at|/at> and return the first node that matches the context or B<undef> if none do.

25 L<atPositionMatch|/atPositionMatch> - Confirm that a string matches a match expression.

26 L<attr|/attr> - Return the value of an attribute of the current node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

27 L<attrCount|/attrCount> - Return the number of attributes in the specified B<$node>, optionally ignoring the specified names from the count.

28 L<attributes|/attributes> - The attributes of the specified B<$node>, see also: L</Attributes>.

29 L<attrs|/attrs> - Return the values of the specified attributes of the current node as a list

30 L<audience|/audience> - Attribute B<audience> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

31 L<AUTOLOAD|/AUTOLOAD> - Allow methods with constant parameters to be called as B<method_p1_p2>.

32 L<before|/before> - Return the first node if it occurs before the second node in the L<parse|/parse> tree optionally checking that the first node is in the specified context or else B<undef> if the node is L<above|/above>, L<below|/below> or L<before|/before> the target.

33 L<below|/below> - Return the first node if the first node is below the second node optionally checking that the first node is in the specified context otherwise return B<undef>

34 L<belowPath|/belowPath> - Return the nodes along the path from the first node up to the second node when the first node is below the second node else return B<()>.

35 L<bitsNodeTextBlank|/bitsNodeTextBlank> - Return a bit string that shows if there are any non text nodes, text nodes or blank text nodes under a node.

36 L<breakIn|/breakIn> - Concatenate the nodes following and preceding the start node, unwrapping nodes whose tag matches the start node and return the start node.

37 L<breakInBackwards|/breakInBackwards> - Concatenate the nodes preceding the start node, unwrapping nodes whose tag matches the start node and return the start node in the manner of L<breakIn|/breakIn>.

38 L<breakInForwards|/breakInForwards> - Concatenate the nodes following the start node, unwrapping nodes whose tag matches the start node and return the start node in the manner of L<breakIn|/breakIn>.

39 L<breakOut|/breakOut> - Lift child nodes with the specified tags under the specified parent node splitting the parent node into clones and return the cut out original node.

40 L<by|/by> - Post-order traversal of a L<parse|/parse> tree or sub tree calling the specified B<sub> at each node and returning the specified starting node.

41 L<byList|/byList> - Return a list of all the nodes at and below a specified B<$node> in pre-order or the empty list if the B<$node> is not in the optional context.

42 L<byReverse|/byReverse> - Reverse post-order traversal of a L<parse|/parse> tree or sub tree calling the specified B<sub> at each node and returning the specified starting B<$node>.

43 L<byReverseList|/byReverseList> - Return a list of all the nodes at and below a specified B<$node> in reverse preorder or the empty list if the specified B<$node> is not in the optional context.

44 L<byReverseX|/byReverseX> - Reverse post-order traversal of a L<parse|/parse> tree or sub tree below the specified B<$node> calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting B<$node>.

45 L<byX|/byX> - Post-order traversal of a L<parse|/parse> tree calling the specified B<sub> at each node as long as this sub does not L<die|http://perldoc.perl.org/functions/die.html>.

46 L<byX2|/byX2> - Post-order traversal of a L<parse|/parse> tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node.

47 L<byX22|/byX22> - Post-order traversal of a L<parse|/parse> tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node.

48 L<c|/c> - Return an array of all the nodes with the specified tag below the specified B<$node>.

49 L<cdata|/cdata> - The name of the tag to be used to represent text - this tag must not also be used as a command tag otherwise the parser will L<confess|http://perldoc.perl.org/Carp.html#SYNOPSIS/>.

50 L<change|/change> - Change the name of the specified B<$node>, optionally  confirming that the B<$node> is in a specified context and return the B<$node>.

51 L<changeAttr|/changeAttr> - Change the name of an attribute in the specified B<$node> unless it has already been set and return the node.

52 L<changeAttributeValue|/changeAttributeValue> - Apply a sub to the value of an attribute of the specified B<$node>.

53 L<changeAttrValue|/changeAttrValue> - Change the name and value of an attribute in the specified B<$node> unless it has already been set and return the node.

54 L<changeReasonCommentSelectionSpecification|/changeReasonCommentSelectionSpecification> - Provide a specification to select L<change reason comments|/crc> to be inserted as text into a L<parse|/parse> tree.

55 L<changeText|/changeText> - If the specified  B<$node> is a text node in the specified context then the specified B<sub> is passed the text of the node in L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>, any changes to which are recorded in the text of the B<$node>.

56 L<checkParentage|/checkParentage> - Check the parent pointers are correct in a L<parse|/parse> tree.

57 L<checkParser|/checkParser> - Check that every node has a L<parse|/parse>r.

58 L<class|/class> - Attribute B<class> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

59 L<clone|/clone> - Return a clone of the L<parse|/parse> tree optionally checking that the starting node is in a specified context: the L<parse|/parse> tree is cloned without converting it to string and reparsing it so this method will not L<renew|/renew> any nodes added L<as text|/Put as text>.

60 L<commonAdjacentAncestors|/commonAdjacentAncestors> - Given two nodes, find a pair of adjacent ancestral siblings if such a pair exists else return B<()>.

61 L<commonAncestor|/commonAncestor> - Find the most recent common ancestor of the specified nodes or B<undef> if there is no common ancestor.

62 L<concatenate|/concatenate> - Concatenate two successive nodes and return the target node.

63 L<concatenateSiblings|/concatenateSiblings> - Concatenate preceding and following nodes as long as they have the same tag as the specified B<$node> and return the specified B<$node>.

64 L<condition|/condition> - Return the node if it has the specified condition and is in the optional context, else return B<undef>

65 L<conditions|/conditions> - Conditional strings attached to a node, see L</Conditions>.

66 L<containsSingleText|/containsSingleText> - Return the single text element below the specified B<$node> else return B<undef>.

67 L<content|/content> - Content of command: the nodes immediately below the specified B<$node> in the order in which they appeared in the source text, see also L</Contents>.

68 L<contentAfter|/contentAfter> - Return a list of all the sibling nodes following the specified B<$node> or an empty list if the specified B<$node> is last or not in the optional context.

69 L<contentAfterAsTags|/contentAfterAsTags> - Return a string containing the tags of all the sibling nodes following the specified B<$node> separated by single spaces or the empty string if the node is empty or B<undef> if the node does not match the optional context.

70 L<contentAfterAsTags2|/contentAfterAsTags2> - Return a string containing the tags of all the sibling nodes following the specified B<$node> separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or B<undef> if the node does not match the optional context.

71 L<contentAsTags|/contentAsTags> - Return a string containing the tags of all the child nodes of the specified B<$node> separated by single spaces or the empty string if the node is empty or B<undef> if the node does not match the optional context.

72 L<contentAsTags2|/contentAsTags2> - Return a string containing the tags of all the child nodes of the specified B<$node> separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or B<undef> if the node does not match the optional context.

73 L<contentBefore|/contentBefore> - Return a list of all the sibling nodes preceding the specified B<$node> or an empty list if the specified B<$node> is last or not in the optional context.

74 L<contentBeforeAsTags|/contentBeforeAsTags> - Return a string containing the tags of all the sibling nodes preceding the specified B<$node> separated by single spaces or the empty string if the node is empty or B<undef> if the node does not match the optional context.

75 L<contentBeforeAsTags2|/contentBeforeAsTags2> - Return a string containing the tags of all the sibling nodes preceding the specified B<$node> separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or B<undef> if the node does not match the optional context.

76 L<contents|/contents> - Return a list of all the nodes contained by the specified B<$node> or an empty list if the node is empty or not in the optional context.

77 L<context|/context> - Return a string containing the tag of the starting node and the tags of all its ancestors separated by single spaces.

78 L<copyAttrs|/copyAttrs> - Copy all the attributes of the source node to the target node, or, just the named attributes if the optional list of attributes to copy is supplied, overwriting any existing attributes in the target node and return the source node.

79 L<copyLabels|/copyLabels> - Copy all the labels from the source node to the target node and return the source node.

80 L<copyLabelsAndIdsInTree|/copyLabelsAndIdsInTree> - Copy all the labels and ids in the source parse tree to the matching nodes in the target parse tree.

81 L<copyNewAttrs|/copyNewAttrs> - Copy all the attributes of the source node to the target node, or, just the named attributes if the optional list of attributes to copy is supplied, without overwriting any existing attributes in the target node and return the source node.

82 L<count|/count> - Return the count of the number of instances of the specified tags under the specified B<$node>, either by tag in array context or in total in scalar context.

83 L<countAttrNames|/countAttrNames> - Return a reference to a hash showing the number of instances of each attribute on and below the specified B<$node>.

84 L<countAttrNamesOnTagExcluding|/countAttrNamesOnTagExcluding> - Count the number of attributes owned by the specified B<$node> that are not in the specified list.

85 L<countAttrValues|/countAttrValues> - Return a reference to a hash showing the number of instances of each attribute value on and below the specified B<$node>.

86 L<countLabels|/countLabels> - Return the count of the number of labels at a node.

87 L<countOutputClasses|/countOutputClasses> - Count instances of outputclass attributes

88 L<countTagNames|/countTagNames> - Return a reference to a hash showing the number of instances of each tag on and below the specified B<$node>.

89 L<countTags|/countTags> - Count the number of tags in a L<parse|/parse> tree.

90 L<crc|/crc> - Insert a comment consisting of a code and an optional reason as text into the L<parse|/parse> tree to indicate the location of changes to the L<parse|/parse> tree.

91 L<createPatch|/createPatch> - Create a patch that moves the source L<parse|/parse> tree to the target L<parse|/parse> tree node as long as they have the same tag and id structure with each id being unique.

92 L<createRequiredCleanUp|/createRequiredCleanUp> - Create a required clean up node

93 L<cut|/cut> - Cut out the specified B<$node> so that it can be reinserted else where in the L<parse|/parse> tree.

94 L<data|/data> - A hash added to the node for use by the programmer during transformations.

95 L<Data::Edit::Xml::Patch::install|/Data::Edit::Xml::Patch::install> - Replay a patch created by L<createPatch|/createPatch> against a L<parse|/parse> tree that has the same tag and id structure with each id being unique.

96 L<deleteAttr|/deleteAttr> - Delete the named attribute in the specified B<$node>, optionally check its value first, return the node regardless.

97 L<deleteAttrs|/deleteAttrs> - Delete the specified attributes of the specified B<$node> without checking their values and return the node.

98 L<deleteConditions|/deleteConditions> - Delete conditions applied to a node and return the node.

99 L<deleteContent|/deleteContent> - Delete the content of the specified B<$node>.

100 L<deleteLabels|/deleteLabels> - Delete the specified labels in the specified B<$node> or all labels if no labels have are specified and return that node.

101 L<depth|/depth> - Returns the depth of the specified B<$node>, the  depth of a root node is zero.

102 L<diff|/diff> - Return () if the dense string representations of the two nodes are equal, else up to the first N (default 16) characters of the common prefix before the point of divergence and the remainder of the string representation of each node from the point of divergence.

103 L<disconnectLeafNode|/disconnectLeafNode> - Remove a leaf node from the parse tree and make it into its own parse tree.

104 L<disordered|/disordered> - Return the first node that is out of the specified order when performing a pre-ordered traversal of the L<parse|/parse> tree.

105 L<ditaAddColSpecToTgroup|/ditaAddColSpecToTgroup> - Add the specified B<$number> of column specification to a specified B<$tgroup> which does not have any already.

106 L<ditaAddPadEntriesToRows|/ditaAddPadEntriesToRows> - Adding padding entries to a table to make sure every row has the same number of entries

107 L<ditaFixTableColSpec|/ditaFixTableColSpec> - Improve the specified B<$table> by making obvious improvements.

108 L<ditaListToSteps|/ditaListToSteps> - Change the specified B<$node> to B<steps> and its contents to B<cmd\step> optionally only in the specified context.

109 L<ditaListToStepsUnordered|/ditaListToStepsUnordered> - Change the specified B<$node> to B<steps-unordered> and its contents to B<cmd\step> optionally only in the specified context.

110 L<ditaListToSubSteps|/ditaListToSubSteps> - Change the specified B<$node> to B<substeps> and its contents to B<cmd\step> optionally only in the specified context.

111 L<ditaMaximumNumberOfEntriesInARow|/ditaMaximumNumberOfEntriesInARow> - Return the maximum number of entries in the rows of the specified B<$table> or B<undef> if not a table.

112 L<ditaMergeLists|/ditaMergeLists> - Merge the specified B<$node> with the preceding or following list or steps or substeps if possible and return the specified B<$node> regardless.

113 L<ditaMergeListsOnce|/ditaMergeListsOnce> - Merge the specified B<$node> with the preceding or following list or steps or substeps if possible and return the specified B<$node> regardless.

114 L<ditaObviousChanges|/ditaObviousChanges> - Make obvious changes to a L<parse|/parse> tree to make it look more like L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html>.

115 L<ditaOrganization|/ditaOrganization> - Set the dita organization field in the xml headers, set by default to OASIS.

116 L<ditaParagraphToNote|/ditaParagraphToNote> - Convert all <p> nodes to <note> if the paragraph starts with 'Note:', optionally wrapping the content of the <note> with a <p>

117 L<ditaPrettyPrintWithHeaders|/ditaPrettyPrintWithHeaders> - Add xml headers for the dita document type indicated by the specified L<parse|/parse> tree to a pretty print of the parse tree.

118 L<ditaStepsToList|/ditaStepsToList> - Change the specified B<$node> to B<ol> and its B<cmd\step> content to B<li> optionally only in the specified context.

119 L<ditaTopicHeaders|/ditaTopicHeaders> - Add xml headers for the dita document type indicated by the specified L<parse|/parse> tree

120 L<divideDocumentIntoSections|/divideDocumentIntoSections> - Divide a L<parse|/parse> tree into sections by moving non B<section> tags into their corresponding B<section> so that the B<section> tags expand until they are contiguous.

121 L<down|/down> - Pre-order traversal down through a L<parse|/parse> tree or sub tree calling the specified B<sub> at each node and returning the specified starting node.

122 L<downReverse|/downReverse> - Reverse pre-order traversal down through a L<parse|/parse> tree or sub tree calling the specified B<sub> at each node and returning the specified starting node.

123 L<downReverseX|/downReverseX> - Reverse pre-order traversal down through a L<parse|/parse> tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node.

124 L<downWhileFirst|/downWhileFirst> - Move down from the specified B<$node> as long as each lower node is a first node.

125 L<downWhileHasSingleChild|/downWhileHasSingleChild> - Move down from the specified B<$node> as long as it has a single child else return undef.

126 L<downWhileLast|/downWhileLast> - Move down from the specified B<$node> as long as each lower node is a last node.

127 L<downX|/downX> - Pre-order traversal of a L<parse|/parse> tree calling the specified B<sub> at each node as long as this sub does not L<die|http://perldoc.perl.org/functions/die.html>.

128 L<downX2|/downX2> - Pre-order traversal of a L<parse|/parse> tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node.

129 L<downX22|/downX22> - Pre-order traversal down through a L<parse|/parse> tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node.

130 L<equals|/equals> - Return the first node if the two L<parse|/parse> trees have identical representations via L<string|/string>, else B<undef>.

131 L<equalsIgnoringAttributes|/equalsIgnoringAttributes> - Return the first node if the two L<parse|/parse> trees have identical representations via L<string|/string> if the specified attributes are ignored, else B<undef>.

132 L<errorsFile|/errorsFile> - Error listing file.

133 L<expandIncludes|/expandIncludes> - Expand the includes mentioned in a L<parse|/parse> tree: any tag that ends in B<include> is assumed to be an include directive.

134 L<findByForestNumber|/findByForestNumber> - Find the node with the specified L<forest number|/forestNumberTrees> as made visible on the id attribute by L<prettyStringNumbered|/prettyStringNumbered> in the L<parse|/parse> tree containing the specified B<$node> and return the found node or B<undef> if no such node exists.

135 L<findByNumber|/findByNumber> - Find the node with the specified number as made visible by L<prettyStringNumbered|/prettyStringNumbered> in the L<parse|/parse> tree containing the specified B<$node> and return the found node or B<undef> if no such node exists.

136 L<findByNumbers|/findByNumbers> - Find the nodes with the specified numbers as made visible by L<prettyStringNumbered|/prettyStringNumbered> in the L<parse|/parse> tree containing the specified B<$node> and return the found nodes in a list with B<undef> for nodes that do not exist.

137 L<first|/first> - Return the first node below the specified B<$node> optionally checking its context.

138 L<firstBy|/firstBy> - Return a list of the first instance of each specified tag encountered in a post-order traversal from the specified B<$node> or a hash of all first instances if no tags are specified.

139 L<firstContextOf|/firstContextOf> - Return the first node encountered in the specified context in a depth first post-order traversal of the L<parse|/parse> tree.

140 L<firstDown|/firstDown> - Return a list of the first instance of each specified tag encountered in a pre-order traversal from the specified B<$node> or a hash of all first instances if no tags are specified.

141 L<firstIn|/firstIn> - Return the first child node matching one of the named tags under the specified parent node.

142 L<firstInIndex|/firstInIndex> - Return the specified B<$node> if it is first in its index and optionally L<at|/at> the specified context else B<undef>

143 L<firstn|/firstn> - Return the B<$n>'th first node below the specified B<$node> optionally checking its context or B<undef> if there is no such node.

144 L<firstNot|/firstNot> - Return the first child node that does not match any of the named B<@tags> under the specified parent B<$node>.

145 L<firstOf|/firstOf> - Return an array of the nodes that are continuously first under their specified parent node and that match the specified list of tags.

146 L<firstSibling|/firstSibling> - Return the first sibling of the specified B<$node> in the optional context else B<undef>

147 L<firstText|/firstText> - Return the first node if it is a text node otherwise B<undef>

148 L<firstTextMatches|/firstTextMatches> - Return the first node under the specified B<$node> if: it is a text mode; its text matches the specified regular expression; the specified B<$node> is in the optional specified context.

149 L<firstUntil|/firstUntil> - Go first from the specified B<$node> and continue deeper until a first child node matches the specified B<@context> or return B<undef> if there is no such node.

150 L<firstWhile|/firstWhile> - Go first from the specified B<$node> and continue deeper as long as each first child node matches one of the specified B<@tags>.

151 L<forestNumbers|/forestNumbers> - Index to node by forest number as set by L<numberForest|/numberForest>.

152 L<forestNumberTrees|/forestNumberTrees> - Number the ids of the nodes in a L<parse|/parse> tree in pre-order so they are numbered in the same sequence that they appear in the source.

153 L<from|/from> - Return a list consisting of the specified node and its following siblings optionally including only those nodes that match one of the tags in the specified list.

154 L<fromTo|/fromTo> - Return a list of the nodes between the specified start and end nodes optionally including only those nodes that match one of the tags in the specified list.

155 L<getAttrs|/getAttrs> - Return a sorted list of all the attributes on the specified B<$node>.

156 L<getLabels|/getLabels> - Return the names of all the labels set on a node.

157 L<getSectionHeadingLevel|/getSectionHeadingLevel> - Get the heading level from a section tag.

158 L<go|/go> - Return the node reached from the specified B<$node> via the specified L<path|/path>: (index positionB<?>)B<*> where index is the tag of the next node to be chosen and position is the optional zero based position within the index of those tags under the current node.

159 L<goFish|/goFish> - A debug version of L<go|/go> that returns additional information explaining any failure to reach the node identified by the L<path|/path>.

160 L<guid|/guid> - Attribute B<guid> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

161 L<hasSingleChild|/hasSingleChild> - Return the only child of the specified B<$node> if the child is the only node under its parent ignoring any surrounding blank text and has the  optional specified context, else return B<undef>.

162 L<hasSingleChildToDepth|/hasSingleChildToDepth> - Return the specified B<$node> if it has single children to at least the specified depth else return B<undef>.

163 L<howFar|/howFar> - Return how far the first node is from the second node along a path through their common ancestor.

164 L<howFarAbove|/howFarAbove> - Return how far the first node is  L<above|/above> the second node is or B<0> if the first node is not strictly L<above|/above> the second node.

165 L<howFarBelow|/howFarBelow> - Return how far the first node is  L<below|/below> the second node is or B<0> if the first node is not strictly L<below|/below> the second node.

166 L<howFirst|/howFirst> - Return the depth to which the specified B<$node> is L<first|/isFirst> else B<0>.

167 L<howLast|/howLast> - Return the depth to which the specified B<$node> is L<last|/isLast> else B<0>.

168 L<howOnlyChild|/howOnlyChild> - Return the depth to which the specified B<$node> is an L<only child|/isOnlyChild> else B<0>.

169 L<href|/href> - Attribute B<href> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

170 L<htmlHeadersToSections|/htmlHeadersToSections> - Position sections just before html header tags so that subsequently the document can be divided into L<sections|/divideDocumentIntoSections>.

171 L<htmlTableToDita|/htmlTableToDita> - Convert an L<html table|https://www.w3.org/TR/html52/tabular-data.html#the-table-element> to a L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> table.

172 L<id|/id> - Attribute B<id> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

173 L<index|/index> - Return the index of the specified B<$node> in its parent index.

174 L<indexes|/indexes> - Indexes to sub commands by tag in the order in which they appeared in the source text.

175 L<indexIds|/indexIds> - Return a map of the ids at and below the specified B<$node>.

176 L<indexNode|/indexNode> - Merge multiple text segments and set parent and parser after changes to a node

177 L<input|/input> - Source of the L<parse|/parse> if this is the L<parser|/parse> root node.

178 L<inputFile|/inputFile> - Source file of the L<parse|/parse> if this is the L<parser|/parse> root node.

179 L<inputString|/inputString> - Source string of the L<parse|/parse> if this is the L<parser|/parse> root node.

180 L<invert|/invert> - Swap a parent and child node where the child is the only child of the parent and return the parent.

181 L<invertFirst|/invertFirst> - Swap a parent and child node where the child is the first child of the parent by placing the parent last in the child.

182 L<invertLast|/invertLast> - Swap a parent and child node where the child is the last child of the parent by placing the parent first in the child.

183 L<isAllBlankText|/isAllBlankText> - Return the specified B<$node> if the specified B<$node>, optionally in the specified context, does not contain anything or if it does contain something it is all white space else return B<undef>.

184 L<isBlankText|/isBlankText> - Return the specified B<$node> if the specified B<$node> is a text node, optionally in the specified context, and contains nothing other than white space else return B<undef>.

185 L<isEmpty|/isEmpty> - Confirm that the specified B<$node> is empty, that is: the specified B<$node> has no content, not even a blank string of text.

186 L<isFirst|/isFirst> - Return the specified B<$node> if it is first under its parent and optionally has the specified context, else return B<undef>

187 L<isFirstText|/isFirstText> - Return the specified B<$node> if the specified B<$node> is a text node, the first node under its parent and that the parent is optionally in the specified context, else return B<undef>.

188 L<isFirstToDepth|/isFirstToDepth> - Return the specified B<$node> if it is first to the specified depth else return B<undef>

189 L<isLast|/isLast> - Return the specified B<$node> if it is last under its parent and optionally has the specified context, else return B<undef>

190 L<isLastText|/isLastText> - Return the specified B<$node> if the specified B<$node> is a text node, the last node under its parent and that the parent is optionally in the specified context, else return B<undef>.

191 L<isLastToDepth|/isLastToDepth> - Return the specified B<$node> if it is last to the specified depth else return B<undef>

192 L<isOnlyChild|/isOnlyChild> - Return the specified B<$node> if it is the only node under its parent ignoring any surrounding blank text.

193 L<isOnlyChildToDepth|/isOnlyChildToDepth> - Return the specified B<$node> if it and its ancestors are L<only children|/isOnlyChild> to the specified depth else return B<undef>.

194 L<isText|/isText> - Return the specified B<$node> if the specified B<$node> is a text node, optionally in the specified context, else return B<undef>.

195 L<labels|/labels> - The labels attached to a node to provide addressability from other nodes, see: L</Labels>.

196 L<labelsInTree|/labelsInTree> - Return a hash of all the labels in a tree

197 L<lang|/lang> - Attribute B<lang> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

198 L<last|/last> - Return the last node below the specified B<$node> optionally checking its context.

199 L<lastBy|/lastBy> - Return a list of the last instance of each specified tag encountered in a post-order traversal from the specified B<$node> or a hash of all last instances if no tags are specified.

200 L<lastContextOf|/lastContextOf> - Return the last node encountered in the specified context in a depth first reverse pre-order traversal of the L<parse|/parse> tree.

201 L<lastDown|/lastDown> - Return a list of the last instance of each specified tag encountered in a pre-order traversal from the specified B<$node> or a hash of all last instances if no tags are specified.

202 L<lastIn|/lastIn> - Return the last child node matching one of the named tags under the specified parent node.

203 L<lastInIndex|/lastInIndex> - Return the specified B<$node> if it is last in its index and optionally L<at|/at> the specified context else B<undef>

204 L<lastn|/lastn> - Return the B<$n>'th last node below the specified B<$node> optionally checking its context or B<undef> if there is no such node.

205 L<lastNot|/lastNot> - Return the last child node that does not match any of the named B<@tags> under the specified parent B<$node>.

206 L<lastOf|/lastOf> - Return an array of the nodes that are continuously last under their specified parent node and that match the specified list of tags.

207 L<lastSibling|/lastSibling> - Return the last sibling of the specified B<$node> in the optional context else B<undef>

208 L<lastText|/lastText> - Return the last node if it is a text node otherwise B<undef>

209 L<lastTextMatches|/lastTextMatches> - Return the last node under the specified B<$node> if: it is a text mode; its text matches the specified regular expression; the specified B<$node> is in the optional specified context.

210 L<lastUntil|/lastUntil> - Go last from the specified B<$node> and continue deeper until a last child node matches the specified B<@context> or return B<undef> if there is no such node.

211 L<lastWhile|/lastWhile> - Go last from the specified B<$node> and continue deeper as long as each last child node matches one of the specified B<@tags>.

212 L<listConditions|/listConditions> - Return a list of conditions applied to a node.

213 L<matchAfter|/matchAfter> - Confirm that the string representing the tags following the specified B<$node> matches a regular expression where each pair of tags is separated by a single space.

214 L<matchAfter2|/matchAfter2> - Confirm that the string representing the tags following the specified B<$node> matches a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a single space and the last tag is followed by a single space.

215 L<matchBefore|/matchBefore> - Confirm that the string representing the tags preceding the specified B<$node> matches a regular expression where each pair of tags is separated by a single space.

216 L<matchBefore2|/matchBefore2> - Confirm that the string representing the tags preceding the specified B<$node> matches a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a single space and the last tag is followed by a single space.

217 L<matchesNextTags|/matchesNextTags> - Return the specified b<$node> if the siblings following the specified B<$node> L<match|/atPositionMatch> the specified <@tags> else return B<undef>.

218 L<matchesPrevTags|/matchesPrevTags> - Return the specified b<$node> if the siblings prior to the specified B<$node> L<match|/atPositionMatch> the specified <@tags> else return B<undef>.

219 L<matchesText|/matchesText> - Returns an array of regular expression matches in the text of the specified B<$node> if it is text node and it matches the specified regular expression and optionally has the specified context otherwise returns an empty array.

220 L<matchTree|/matchTree> - Return a list of nodes that match the specified tree of match expressions, else B<()> if one or more match expressions fail to match nodes in the tree below the specified start node.

221 L<mergeDuplicateChildWithParent|/mergeDuplicateChildWithParent> - Merge a parent node with its only child if their tags are the same and their attributes do not collide other than possibly the id in which case the parent id is used.

222 L<moveAttrs|/moveAttrs> - Move all the attributes of the source node to the target node, or, just the named attributes if the optional list of attributes to move is supplied, overwriting any existing attributes in the target node and return the source node.

223 L<moveLabels|/moveLabels> - Move all the labels from the source node to the target node and return the source node.

224 L<moveNewAttrs|/moveNewAttrs> - Move all the attributes of the source node to the target node, or, just the named attributes if the optional list of attributes to copy is supplied, without overwriting any existing attributes in the target node and return the source node.

225 L<navtitle|/navtitle> - Attribute B<navtitle> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

226 L<new|/new> - Create a new parse tree - call this method statically as in Data::Edit::Xml::new(file or string) to parse a file or string B<or> with no parameters and then use L</input>, L</inputFile>, L</inputString>, L</errorFile>  to provide specific parameters for the parse, then call L</parse> to perform the parse and return the parse tree.

227 L<newTag|/newTag> - Create a new non text node.

228 L<newText|/newText> - Create a new text node.

229 L<newTree|/newTree> - Create a new tree.

230 L<next|/next> - Return the node next to the specified B<$node>, optionally checking its context.

231 L<nextIn|/nextIn> - Return the nearest sibling after the specified B<$node> that matches one of the named tags or B<undef> if there is no such sibling node.

232 L<nextn|/nextn> - Return the B<$n>'th next node after the specified B<$node> optionally checking its context or B<undef> if there is no such node.

233 L<nextOn|/nextOn> - Step forwards as far as possible from the specified B<$node> while remaining on nodes with the specified tags.

234 L<nextText|/nextText> - Return the next node after the specified B<$node> if it is a text node otherwise B<undef>

235 L<nextTextMatches|/nextTextMatches> - Return the next node to the specified B<$node> if: it is a text mode; its text matches the specified regular expression; the specified B<$node> is in the optional specified context.

236 L<nextUntil|/nextUntil> - Go to the next sibling of the specified B<$node> and continue forwards until the tag of a sibling node matches one of the specified B<@tags>.

237 L<nextWhile|/nextWhile> - Go to the next sibling of the specified B<$node> and continue forwards while the tag of each sibling node matches one of the specified B<@tags>.

238 L<nn|/nn> - Replace new lines in a string with N to make testing easier.

239 L<normalizeWhiteSpace|/normalizeWhiteSpace> - Normalize white space, remove comments DOCTYPE and xml processors from a string

240 L<not|/not> - Return the specified B<$node> if it does not match any of the specified tags, else B<undef>

241 L<number|/number> - Number of the specified B<$node>, see L<findByNumber|/findByNumber>.

242 L<numbering|/numbering> - Last number used to number a node in this L<parse|/parse> tree.

243 L<numberNode|/numberNode> - Ensure that the specified B<$node> has a number.

244 L<numbers|/numbers> - Nodes by number.

245 L<numberTree|/numberTree> - Number the nodes in a L<parse|/parse> tree in pre-order so they are numbered in the same sequence that they appear in the source.

246 L<numberTreesJustIds|/numberTreesJustIds> - Number the ids of the nodes in a L<parse|/parse> tree in pre-order so they are numbered in the same sequence that they appear in the source.

247 L<opAt|/opAt> - <= : Check that a node is in the context specified by the referenced array of words.

248 L<opAttr|/opAttr> - % : Get the value of an attribute of the specified B<$node>.

249 L<opBy|/opBy> - x= : Traverse a L<parse|/parse> tree in post-order.

250 L<opContents|/opContents> - @{} : nodes immediately below a node.

251 L<opCut|/opCut> - -- : Cut out a node.

252 L<opGo|/opGo> - >= : Search for a node via a specification provided as a reference to an array of words each number.

253 L<opNew|/opNew> - ** : create a new node from the text on the right hand side: if the text contains a non word character \W the node will be create as text, else it will be created as a tag

254 L<opPutFirst|/opPutFirst> - >> : put a node or string first under a node and return the new node.

255 L<opPutFirstAssign|/opPutFirstAssign> - >>= : put a node or string first under a node.

256 L<opPutLast|/opPutLast> - << : put a node or string last under a node and return the new node.

257 L<opPutLastAssign|/opPutLastAssign> - <<= : put a node or string last under a node.

258 L<opPutNext|/opPutNext> - > + : put a node or string after the specified B<$node> and return the new node.

259 L<opPutNextAssign|/opPutNextAssign> - += : put a node or string after the specified B<$node>.

260 L<opPutPrev|/opPutPrev> - < - : put a node or string before the specified B<$node> and return the new node.

261 L<opPutPrevAssign|/opPutPrevAssign> - -= : put a node or string before the specified B<$node>,

262 L<opString|/opString> - -B: L<bitsNodeTextBlank|/bitsNodeTextBlank>

-b: L<isAllBlankText|/isAllBlankText>

-c: L<context|/context>

-e: L<prettyStringEnd|/prettyStringEnd>

-f: L<first node|/first>

-g: L<pathString|/pathString>

-l: L<last node|/last>

-M: L<number|/number>

-o: L<contentAsTags|/contentAsTags>

-p: L<prettyString|/prettyString>

-s: L<string|/string>

-S : L<stringNode|/stringNode>

-T : L<isText|/isText>

-t : L<tag|/tag>

-u: L<id|/id>

-W: L<unWrap|/unWrap>

-w: L<stringQuoted|/stringQuoted>

-x: L<prettyStringDitaHeaders|/prettyStringDitaHeaders>

-X: L<cut|/cut>

-z: L<prettyStringNumbered|/prettyStringNumbered>.

263 L<opUnwrap|/opUnwrap> - ++ : Unwrap a node.

264 L<opWrapContentWith|/opWrapContentWith> - * : Wrap content with a tag, returning the wrapping node.

265 L<opWrapWith|/opWrapWith> - / : Wrap node with a tag, returning the wrapping node.

266 L<ordered|/ordered> - Return the first node if the specified nodes are all in order when performing a pre-ordered traversal of the L<parse|/parse> tree else return B<undef>.

267 L<otherprops|/otherprops> - Attribute B<otherprops> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

268 L<outputclass|/outputclass> - Attribute B<outputclass> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

269 L<over|/over> - Confirm that the string representing the tags at the level below the specified B<$node> match a regular expression where each pair of tags is separated by a single space.

270 L<over2|/over2> - Confirm that the string representing the tags at the level below the specified B<$node> match a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a single space and the last tag is followed by a single space.

271 L<overAllTags|/overAllTags> - Return the specified b<$node> if all of it's child nodes L<match|/atPositionMatch> the specified <@tags> else return B<undef>.

272 L<overFirstTags|/overFirstTags> - Return the specified b<$node> if the first of it's child nodes L<match|/atPositionMatch> the specified <@tags> else return B<undef>.

273 L<overLastTags|/overLastTags> - Return the specified b<$node> if the last of it's child nodes L<match|/atPositionMatch> the specified <@tags> else return B<undef>.

274 L<parent|/parent> - Parent node of the specified B<$node> or B<undef> if the L<parser|/parse> root node.

275 L<parse|/parse> - Parse input XML specified via: L<inputFile|/inputFile>, L<input|/input> or L<inputString|/inputString>.

276 L<parser|/parser> - L<Parser|/parse> details: the root node of a tree is the L<parser|/parse> node for that tree.

277 L<path|/path> - Return a list representing the path to a node from the root of the parse tree which can then be reused by L<go|/go> to retrieve the node as long as the structure of the L<parse|/parse> tree has not changed along the path.

278 L<pathString|/pathString> - Return a string representing the L<path|/path> to the specified B<$node> from the root of the parse tree.

279 L<position|/position> - Return the index of the specified B<$node> in the content of the parent of the B<$node>.

280 L<present|/present> - Return the count of the number of the specified tag types present immediately under a node or a hash {tag} = count for all the tags present under the node if no names are specified.

281 L<prettyString|/prettyString> - Return a readable string representing a node of a L<parse|/parse> tree and all the nodes below it.

282 L<prettyStringCDATA|/prettyStringCDATA> - Return a readable string representing a node of a L<parse|/parse> tree and all the nodes below it with the text fields wrapped with <CDATA>.

283 L<prettyStringContent|/prettyStringContent> - Return a readable string representing all the nodes below a node of a L<parse|/parse> tree.

284 L<prettyStringContentNumbered|/prettyStringContentNumbered> - Return a readable string representing all the nodes below a node of a L<parse|/parse> tree with numbering added.

285 L<prettyStringDitaHeaders|/prettyStringDitaHeaders> - Return a readable string representing the L<parse|/parse> tree below the specified B<$node> with appropriate headers as determined by L<ditaOrganization|/ditaOrganization> .

286 L<prettyStringEnd|/prettyStringEnd> - Return a readable string representing a node of a L<parse|/parse> tree and all the nodes below it as a here document

287 L<prettyStringNumbered|/prettyStringNumbered> - Return a readable string representing a node of a L<parse|/parse> tree and all the nodes below it with a L<number|/number> attached to each tag.

288 L<prev|/prev> - Return the node before the specified B<$node>, optionally checking its context.

289 L<prevIn|/prevIn> - Return the nearest sibling node before the specified B<$node> which matches one of the named tags or B<undef> if there is no such sibling node.

290 L<prevn|/prevn> - Return the B<$n>'th previous node after the specified B<$node> optionally checking its context or B<undef> if there is no such node.

291 L<prevOn|/prevOn> - Step backwards as far as possible while remaining on nodes with the specified tags.

292 L<prevText|/prevText> - Return the previous node if it is a text node otherwise B<undef>

293 L<prevTextMatches|/prevTextMatches> - Return the previous node to the specified B<$node> if: it is a text mode; its text matches the specified regular expression; the specified B<$node> is in the optional specified context.

294 L<prevUntil|/prevUntil> - Go to the previous sibling of the specified B<$node> and continue backwards until the tag of a sibling node matches one of the specified B<@tags>.

295 L<prevWhile|/prevWhile> - Go to the previous sibling of the specified B<$node> and continue backwards while the tag of each sibling node matches one of the specified B<@tags>.

296 L<printAttributes|/printAttributes> - Print the attributes of a node.

297 L<printAttributesExtendingIdsWithLabels|/printAttributesExtendingIdsWithLabels> - Print the attributes of a node extending the id with the labels.

298 L<printAttributesReplacingIdsWithLabels|/printAttributesReplacingIdsWithLabels> - Print the attributes of a node replacing the id with the labels.

299 L<printNode|/printNode> - Print the tag and attributes of a node.

300 L<propagate|/propagate> - Propagate L<new attributes|/copyNewAttrs> from nodes that match the specified tag to all their child nodes, then L<unwrap|/unwrap> all the nodes that match the specified tag.

301 L<props|/props> - Attribute B<props> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

302 L<putFirst|/putFirst> - Place a L<cut out|/cut> or L<new|/new> node at the front of the content of the specified B<$node> and return the new node.

303 L<putFirstAsText|/putFirstAsText> - Add a new text node first under a parent and return the new text node.

304 L<putFirstCut|/putFirstCut> - Cut out the second node, place it first under the first node and return the second node.

305 L<putFirstRequiredCleanUp|/putFirstRequiredCleanUp> - Place a required cleanup tag first under a node and return the required clean up node.

306 L<putLast|/putLast> - Place a L<cut out|/cut> or L<new|/new> node last in the content of the specified B<$node> and return the new node.

307 L<putLastAsText|/putLastAsText> - Add a new text node last under a parent and return the new text node.

308 L<putLastCut|/putLastCut> - Cut out the second node, place it last under the first node and return the second node.

309 L<putLastRequiredCleanUp|/putLastRequiredCleanUp> - Place a required cleanup tag last under a node and return the required clean up node.

310 L<putNext|/putNext> - Place a L<cut out|/cut> or L<new|/new> node just after the specified B<$node> and return the new node.

311 L<putNextAsText|/putNextAsText> - Add a new text node following the specified B<$node> and return the new text node.

312 L<putNextCut|/putNextCut> - Cut out the second node, place it next after the first node and return the second node.

313 L<putNextRequiredCleanUp|/putNextRequiredCleanUp> - Place a required cleanup tag after a node.

314 L<putPrev|/putPrev> - Place a L<cut out|/cut> or L<new|/new> node just before the specified B<$node> and return the new node.

315 L<putPrevAsText|/putPrevAsText> - Add a new text node following the specified B<$node> and return the new text node

316 L<putPrevCut|/putPrevCut> - Cut out the second node, place it before the first node and return the second node.

317 L<putPrevRequiredCleanUp|/putPrevRequiredCleanUp> - Place a required cleanup tag before a node.

318 L<readCompressedFile|/readCompressedFile> - Read the specified B<$file> containing compressed xml and return the root node.

319 L<reindexNode|/reindexNode> - Index the children of a node so that we can access them by tag and number.

320 L<renameAttr|/renameAttr> - Change the name of an attribute in the specified B<$node> regardless of whether the new attribute already exists or not and return the node.

321 L<renameAttrValue|/renameAttrValue> - Change the name and value of an attribute in the specified B<$node> regardless of whether the new attribute already exists or not and return the node.

322 L<renew|/renew> - Returns a renewed copy of the L<parse|/parse> tree, optionally checking that the starting node is in a specified context: use this method if you have added nodes via the L</"Put as text"> methods and wish to traverse their L<parse|/parse> tree.

323 L<replaceContentWith|/replaceContentWith> - Replace the content of a node with the specified nodes and return the replaced content

324 L<replaceContentWithMovedContent|/replaceContentWithMovedContent> - Replace the content of a specified target node with the contents of the specified source nodes removing the content from each source node and return the target node.

325 L<replaceContentWithText|/replaceContentWithText> - Replace the content of a node with the specified texts and return the replaced content

326 L<replaceSpecialChars|/replaceSpecialChars> - Replace < > " & with &lt; &gt; &quot; &amp; Larry Wall's excellent L<Xml parser|https://metacpan.org/pod/XML::Parser/> unfortunately replaces &lt; &gt; &quot; &amp; etc.

327 L<replaceWith|/replaceWith> - Replace a node (and all its content) with a L<new node|/newTag> (and all its content) and return the new node.

328 L<replaceWithBlank|/replaceWithBlank> - Replace a node (and all its content) with a new blank text node and return the new node.

329 L<replaceWithRequiredCleanUp|/replaceWithRequiredCleanUp> - Replace a node with a required cleanup message and return the new node

330 L<replaceWithText|/replaceWithText> - Replace a node (and all its content) with a new text node and return the new node.

331 L<requiredCleanUp|/requiredCleanUp> - Replace a node with a required cleanup node around the text of the replaced node with special characters replaced by symbols.

332 L<restore|/restore> - Return a L<parse|/parse> tree from a copy saved in a file by L<save|/save>.

333 L<save|/save> - Save a copy of the L<parse|/parse> tree to a file which can be L<restored|/restore> and return the saved node.

334 L<set|/set> - Set the values of some attributes in a node and return the node.

335 L<setAttr|/setAttr> - Set the values of some attributes in a node and return the node.

336 L<string|/string> - Return a dense string representing a node of a L<parse|/parse> tree and all the nodes below it.

337 L<stringContent|/stringContent> - Return a string representing all the nodes below a node of a L<parse|/parse> tree.

338 L<stringExtendingIdsWithLabels|/stringExtendingIdsWithLabels> - Return a string representing the specified L<parse|/parse> tree with the id attribute of each node extended by the L<Labels|/Labels> attached to each node.

339 L<stringNode|/stringNode> - Return a string representing a node showing the attributes, labels and node number

340 L<stringQuoted|/stringQuoted> - Return a quoted string representing a L<parse|/parse> tree a node of a L<parse|/parse> tree and all the nodes below it.

341 L<stringReplacingIdsWithLabels|/stringReplacingIdsWithLabels> - Return a string representing the specified L<parse|/parse> tree with the id attribute of each node set to the L<Labels|/Labels> attached to each node.

342 L<stringWithConditions|/stringWithConditions> - Return a string representing the specified B<$node> of a L<parse|/parse> tree and all the nodes below it subject to conditions to select or reject some nodes.

343 L<style|/style> - Attribute B<style> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

344 L<swap|/swap> - Swap two nodes optionally checking that the first node is in the specified context and return the first node.

345 L<tag|/tag> - Tag name for the specified B<$node>, see also L</Traversal> and L</Navigation>.

346 L<text|/text> - Text of the specified B<$node> but only if it is a text node, i.

347 L<through|/through> - Traverse L<parse|/parse> tree visiting each node twice calling the specified B<sub> at each node and returning the specified starting node.

348 L<throughX|/throughX> - Traverse L<parse|/parse> tree visiting each node twice calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node.

349 L<to|/to> - Return a list of the sibling nodes preceding the specified node optionally including only those nodes that match one of the tags in the specified list.

350 L<tocNumbers|/tocNumbers> - Table of Contents number the nodes in a L<parse|/parse> tree.

351 L<topicTypeAndBody|/topicTypeAndBody> - Topic type and corresponding body.

352 L<tree|/tree> - Build a tree representation of the parsed XML which can be easily traversed to look for things.

353 L<type|/type> - Attribute B<type> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

354 L<unwrap|/unwrap> - Unwrap the specified B<$node> by inserting its content into its parent at the point containing the specified B<$node> and return the parent node.

355 L<unwrapContentsKeepingText|/unwrapContentsKeepingText> - Unwrap all the non text nodes below the specified B<$node> adding a leading and a trailing space to prevent unwrapped content from being elided and return the specified B<$node> else B<undef> if not in the optional context.

356 L<unwrapParentsWithSingleChild|/unwrapParentsWithSingleChild> - Unwrap any immediate ancestors of the specified B<$node> which have only a single child and return the specified B<$node> regardless.

357 L<up|/up> - Return the parent of the current node optionally checking the context of the specified B<$node> first or return B<undef> if the specified B<$node> is the root of the L<parse|/parse> tree.

358 L<upn|/upn> - Go up the specified number of levels from the specified B<$node> and return the node reached or B<undef> if there is no such node.

359 L<upThru|/upThru> - Go up the specified path from the specified B<$node> returning the node at the top or B<undef> if no such node exists.

360 L<upUntil|/upUntil> - Return the nearest ancestral node to the specified B<$node> that matches the specified B<@context> or B<undef> if there is no such node.

361 L<upUntilFirst|/upUntilFirst> - Move up from the specified B<$node> until we reach the root or a first node.

362 L<upUntilIsOnlyChild|/upUntilIsOnlyChild> - Move up from the specified B<$node> until we reach the root or another only child.

363 L<upUntilLast|/upUntilLast> - Move up from the specified B<$node> until we reach the root or a last node.

364 L<upWhile|/upWhile> - Go up one level from the specified B<$node> and then continue up while each node matches on of the specified <@tags>.

365 L<upWhileFirst|/upWhileFirst> - Move up from the specified B<$node> as long as each node is a first node or return B<undef> if the specified B<$node> is not a first node.

366 L<upWhileIsOnlyChild|/upWhileIsOnlyChild> - Move up from the specified B<$node> as long as each node is an only child or return B<undef> if the specified B<$node> is not an only child.

367 L<upWhileLast|/upWhileLast> - Move up from the specified B<$node> as long as each node is a last node or return B<undef> if the specified B<$node> is not a last node.

368 L<wordStyles|/wordStyles> - Extract style information from a parse tree representing a word document.

369 L<wrapContentWith|/wrapContentWith> - Wrap the content of the specified B<$node> in a new node created from the specified <@tag> and B<%attributes>: the specified B<$node> then contains just the new node which, in turn, contains all the content of the specified B<$node>.

370 L<wrapDown|/wrapDown> - Wrap the content of the specified B<$node> in a sequence of new nodes forcing the original node up - deepening the L<parse|/parse> tree - return the array of wrapping nodes.

371 L<wrapFrom|/wrapFrom> - Wrap all the nodes from the B<$start> node to the B<$end> node with a new node created from the specified <@tag> and B<%attributes> and return the new node.

372 L<wrapSiblingsAfter|/wrapSiblingsAfter> - If there are any siblings after the specified B<$node>, wrap them with a new node created from the specified <@tag> and B<%attributes>.

373 L<wrapSiblingsBefore|/wrapSiblingsBefore> - If there are any siblings before the specified B<$node>, wrap them with a new node created from the specified <@tag> and B<%attributes>.

374 L<wrapSiblingsBetween|/wrapSiblingsBetween> - If there are any siblings between the specified B<$node>s, wrap them with a new node created from the specified <@tag> and B<%attributes>.

375 L<wrapTo|/wrapTo> - Wrap all the nodes from the B<$start> node to the B<$end> node with a new node created from the specified <@tag> and B<%attributes> and return the new node.

376 L<wrapUp|/wrapUp> - Wrap the specified B<$node> in a sequence of new nodes created from the specified B<@tags> forcing the original node down - deepening the L<parse|/parse> tree - return the array of wrapping nodes.

377 L<wrapWith|/wrapWith> - Wrap the specified B<$node> in a new node created from the specified B<$tag> and B<%attributes> forcing the specified B<$node> down - deepening the L<parse|/parse> tree - return the new wrapping node.

378 L<writeCompressedFile|/writeCompressedFile> - Write the parse tree starting at B<$node> as compressed xml to the specified B<$file>.

379 L<xmlHeader|/xmlHeader> - Add the standard xml header to a string

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Data::Edit::Xml

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2018 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut


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
  1
 }

test unless caller;

1;
# podDocumentation
#__DATA__
use warnings FATAL=>qw(all);
use strict;
use Test::More tests=>943;
use Data::Table::Text qw(:all);

my $windows = $^O =~ m(MSWin32)is;
my $mac     = $^O =~ m(darwin)is;

Test::More->builder->output("/dev/null")                                        # Show only errors during testing
  if ((caller(1))[0]//'Data::Edit::Xml') eq "Data::Edit::Xml";

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

# Editing - outermost - wrapWith

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

# Editing - inner - wrapWith
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

# Editing - cut/put

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

# Editing - unwrap

  ok sample2->go(qw(b))->unwrap->string eq '<a id="aa"><c id="cc"/></a>';
  ok sample2->go(qw(b c))->putFirst(sample2)->parent->parent->parent->string eq '<a id="aa"><b id="bb"><c id="cc"><a id="aa"><b id="bb"><c id="cc"/></b></a></c></b></a>';
  ok sample2->go(qw(b c))->replaceWith(sample2)->go(qw(b c))->upUntil(qw(a b))->string eq '<a id="aa"><b id="bb"><c id="cc"/></b></a>';

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
 {my $a = Data::Edit::Xml::new(<<END);                                          #TstringWithConditions
<a>
  <b>
    <c/>
    <d/>
  </b>
</a>
END

  my $b = $a >= 'b';                                                            #TstringWithConditions
  my ($c, $d) = $b->contents;                                                   #TstringWithConditions

  $b->addConditions(qw(bb BB));                                                 #TstringWithConditions #TaddConditions #TlistConditions  #Tcondition #TanyCondition #TallConditions
  $c->addConditions(qw(cc CC));                                                 #TstringWithConditions                                   #Tcondition #TanyCondition #TallConditions

  ok  $c->condition(q(cc));                                                     #Tcondition
  ok !$c->condition(q(dd));                                                     #Tcondition
  ok  $c->condition(q(cc), qw(c b a));                                          #Tcondition

  ok  $b->anyCondition(qw(bb cc));                                              #TanyCondition
  ok !$b->anyCondition(qw(cc CC));                                              #TanyCondition
  ok  $b->allConditions(qw(bb BB));                                             #TallConditions
  ok !$b->allConditions(qw(bb cc));                                             #TallConditions

  ok join(' ', $b->listConditions) eq 'BB bb';                                  #TdeleteConditions     #TaddConditions #TlistConditions
  $b->deleteConditions(qw(BB));                                                 #TdeleteConditions
  ok join(' ', $b->listConditions) eq 'bb';                                     #TdeleteConditions

  ok $a->stringWithConditions         eq '<a><b><c/><d/></b></a>';              #TstringWithConditions
  ok $a->stringWithConditions(qw(bb)) eq '<a><b><d/></b></a>';                  #TstringWithConditions
  ok $a->stringWithConditions(qw(cc)) eq '<a/>';                                #TstringWithConditions
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
  ok $x->attrCount(qw(first second third)) == 1;                                #TattrCount
  is_deeply [$x->attrs(qw(third second first ))], [undef, 2, 1];                #Tattrs
  is_deeply [$x->getAttrs], [qw(first number second)];                          #TgetAttrs

  $x->deleteAttrs(qw(first second third number));                               #TdeleteAttrs
  ok -s $x eq '<a/>';                                                           #TdeleteAttrs
 }

if (1)
 {my $a = newTag(undef, q(a), id=>"aa", a=>"1", b=>"1");
  ok q(<a a="1" b="1" id="aa"/>) eq -s $a;                                      #Tset
  $a->set(a=>11, b=>undef, c=>3, d=>4, e=>5);                                   #Tset
  ok q(<a a="11" c="3" d="4" e="5" id="aa"/>) eq -s $a;
 }                                                                              #Tset

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

  $x->changeAttrValue(qw(word first greek mono));                               #TchangeAttrValue
  ok $x->printAttributes eq qq( greek="mono" numeral="I");                      #TchangeAttrValue
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
  my $C = $x->go(qw(a C));                                                      #TwrapTo
  $C->wrapTo($C, qq(D));                                                        #TwrapTo
  ok -p $x eq <<END;                                                            #TwrapTo
<aa>
  <a>
    <b/>
    <D>
      <C id="1234">
        <c id="1"/>
        <c id="2"/>
        <c id="3"/>
        <c id="4"/>
      </C>
    </D>
    <d/>
  </a>
</aa>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(my $s = <<END);                                  #TwrapFrom
<a>
  <b>
    <c id="0"/><c id="1"/><c id="2"/><c id="3"/>
  </b>
</a>
END
  my $b = $a->first;                                                            #TwrapFrom
  my @c = $b->contents;                                                         #TwrapFrom
  $c[1]->wrapFrom($c[0], qw(D id DD));                                          #TwrapFrom
  ok -p $a eq <<END;                                                            #TwrapFrom
<a>
  <b>
    <D id="DD">
      <c id="0"/>
      <c id="1"/>
    </D>
    <c id="2"/>
    <c id="3"/>
  </b>
</a>
END
  $c[2]->wrapTo  ($c[2], qw(E id EE));
  $c[3]->wrapTo  ($c[3], qw(F id FF));
  ok -p $a eq <<END;                                                            #TwrapTo
<a>
  <b>
    <D id="DD">
      <c id="0"/>
      <c id="1"/>
    </D>
    <E id="EE">
      <c id="2"/>
    </E>
    <F id="FF">
      <c id="3"/>
    </F>
  </b>
</a>
END
 }

if (1)                                                                          # Blank text
 {my $f = temporaryFile;
  overWriteFile($f, "<a> <b/>   <c/> <d/> </a>");
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
  overWriteFile($f, "<a>  </a>");
  my $x = Data::Edit::Xml::new();
     $x->inputFile = $f;
     $x->parse;
  unlink $f;
  $x->putFirstAsText(' ') for 1..10;
  $x->putLastAsText(' ')  for 1..10;
  ok $x->countTags == 2;
  ok -s $x eq "<a>                    </a>";
 }

if (!$windows)
 {my @files =                                                                   #TexpandIncludes
   (writeFile("in1/a.xml", q(<a id="a"><include href="../in2/b.xml"/></a>)),    #TexpandIncludes
    writeFile("in2/b.xml", q(<b id="b"><include href="c.xml"/></b>)),           #TexpandIncludes
    writeFile("in2/c.xml", q(<c id="c"/>)));                                    #TexpandIncludes

  my $x = Data::Edit::Xml::new(fpf(currentDirectory, $files[0]));               #TexpandIncludes
     $x->expandIncludes;                                                        #TexpandIncludes
  ok <<END eq -p $x;                                                            #TexpandIncludes
<a id="a">
  <b id="b">
    <c id="c"/>
  </b>
</a>
END
  map{unlink $_} @files;
  map{rmdir  $_} map {my ($p) = parseFileName $_; $p} @files;
 }
else                                                                            # Skip because absFromRel in expandIncludes does not work on windows
 {ok 1;
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
 {my $a = Data::Edit::Xml::new(<<END);                                          #TopString #TopContents
<a>
  <b><c>ccc</c></b>
  <d><e>eee</e></d>
</a>
END
  my ($b, $d) =  @$a;                                                           #TopContents
  ok -c $b eq q(b a);                                                           #TopContents
  my ($c)     =  @$b;                                                           #TopContents
  my ($e)     =  @$d;
  ok -c $c eq q(c b a);                                                         #TopContents
  -X $c;
  ok -p $a eq <<END;
<a>
  <b/>
  <d>
    <e>eee</e>
  </d>
</a>
END
  -W $e;
  ok -p $a eq <<END;
<a>
  <b/>
  <d>eee</d>
</a>
END
  -R $d;
  ok -p $a eq <<END;
<a>
  <b/>
  <required-cleanup>&lt;d&gt;eee&lt;/d&gt;
</required-cleanup>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #Tnew #TopString #TbyList #TbyReverseList  #TprintNode
<a>
  <b>
    <c id="42" match="mm"/>
  </b>
  <d>
    <e/>
  </d>
</a>
END

  my ($c, $b, $e, $d) = $a->byList;                                             #TopString
  ok $c->printNode eq q(c id="42" match="mm");                                  #TopString #TprintNode
  ok -A $c eq q(c id="42" match="mm");                                          #TopString

    my ($E, $D, $C, $B) = $a->byReverseList;                                    #TbyReverseList
    ok -A $C eq q(c id="42" match="mm");                                        #TbyReverseList

  ok -b $e;                                                                     #TopString
  ok -c $e eq q(e d a);                                                         #TopString #TbyList

  ok -f $b eq $c;                                                               #TopString
  ok -l $a eq $d;                                                               #TopString

  ok -O $a, q( b  d );                                                          #TopString
  ok -o $a, q(b d);                                                             #TopString

  ok -w $a eq q('<a><b><c id="42" match="mm"/></b><d><e/></d></a>');            #TopString

  ok -p $a eq <<END;                                                            #tdown #tdownX #TdownReverse #TdownReverseX #Tby #TopBy #TbyX #TbyReverse #TbyReverseX #Tnew #Tstring #TopString #Tcontext #TisFirst #TisLast #TopGo #TopAt
<a>
  <b>
    <c id="42" match="mm"/>
  </b>
  <d>
    <e/>
  </d>
</a>
END

  ok -s $a eq '<a><b><c id="42" match="mm"/></b><d><e/></d></a>';               #TopString #Tstring
  ok -t $a eq 'a';                                                              #TopString

  $a->numberTree;                                                               #TopString #TnumberTree

  ok -z $a eq <<END;                                                            #TopString #TnumberTree
<a id="1">
  <b id="2">
    <c id="42" match="mm"/>
  </b>
  <d id="4">
    <e id="5"/>
  </d>
</a>
END

  ok 'bd' eq join '', map {$_->tag} @$a ;
  ok (($a >= [qw(d e)]) <= [qw(e d a)]);                                        #TopGo #TopAt

  ok $a->go(qw(d e))->context eq 'e d a';                                       #Tcontext
  ok $a->go(q(b))->isFirst;                                                     #TisFirst
  ok $a->go(q(d))->isLast;                                                      #TisLast

  if (1)
   {my $s; $a->down(sub{$s .= $_->tag}); ok $s eq "abcde"                       #Tdown #TdownX
   }
  if (1)
   {my $s; $a->downReverse(sub{$s .= $_->tag}); ok $s eq "adebc"                #TdownReverse #TdownReverseX
   }
  if (1)
   {my $s; $a->by(sub{$s .= $_->tag}); ok $s eq "cbeda"                         #Tby
   }
  if (1)
   {my $s; $a->byX(sub{$s .= $_->tag}); ok $s eq "cbeda"                        #TbyX
   }
  if (1)
   {my $s; $a x= sub{$s .= -t $_}; ok $s eq "cbeda"                             #TopBy
   }
  if (1)
   {my $s; $a->byReverse(sub{$s .= $_->tag}); ok $s eq "edcba"                  #TbyReverse #TbyReverseX
   }

  if (1)
   {my $s; my $n = sub{$s .= $_->tag}; $a->through($n, $n);                     #Tthrough #TthroughX
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
  ok $e->id == 5;                                                               #TnextOn #TprevOn
  ok $c->nextOn(qw(d))  ->id == 2;                                              #TnextOn
  ok $c->nextOn(qw(c d))->id == 4;                                              #TnextOn
  ok $e->nextOn(qw(c d))     == $e;                                             #TnextOn
  ok $e->prevOn(qw(d))  ->id == 4;                                              #TprevOn
  ok $e->prevOn(qw(c d))     == $c;                                             #TprevOn

  my $x = $a >= [qw(b c 1)];
  my $w = $x->prev;
  my $y = $x->next;
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
 {my $a = Data::Edit::Xml::new(<<END);
<a>
  <b>
     <c>
       <d>ddd</d>
    </c>
  </b>
</a>
END

  $a->first->replaceContentWithMovedContent($a->go(qw(b c d)));
  ok -p $a eq <<END;
<a>
  <b>ddd</b>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TreplaceContentWithMovedContent
<a>
  <b>
     <b1/>
     <b2/>
  </b>
  <c>
     <c1/>
     <c2/>
  </c>
  <d>
     <d1/>
     <d2/>
  </d>
</a>
END

  my ($b, $c, $d) = $a->contents;                                               #TreplaceContentWithMovedContent
  $d->replaceContentWithMovedContent($c, $b);                                   #TreplaceContentWithMovedContent
  ok -p $a eq <<END;                                                            #TreplaceContentWithMovedContent
<a>
  <b/>
  <c/>
  <d>
    <c1/>
    <c2/>
    <b1/>
    <b2/>
  </d>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TreplaceContentWithMovedContent
<a>
  <d>
     <b>
       <b1/>
       <b2/>
    </b>
    <c>
       <c1/>
       <c2/>
    </c>
  </d>
</a>
END

  my ($d)     = $a->contents;                                                   #TreplaceContentWithMovedContent
  my ($b, $c) = $d->contents;                                                   #TreplaceContentWithMovedContent
  $d->replaceContentWithMovedContent($c, $b);                                   #TreplaceContentWithMovedContent
  ok -p $a eq <<END;                                                            #TreplaceContentWithMovedContent
<a>
  <d>
    <c1/>
    <c2/>
    <b1/>
    <b2/>
  </d>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #Tfirst #Tlast #Tnext #Tprev #TfirstBy #TlastBy #Tindex #Tposition #TfirstSibling #TlastSibling
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

  ok  $a->go(qw(b b))->firstSibling->id == 13;                                   #TfirstSibling
  ok  $a->go(qw(b b))->lastSibling ->id == 22;                                   #TlastSibling

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
  ok !$c->matchesText(qr(\AD));                                                 #TmatchesText
  ok  $c->matchesText(qr(\AC), qw(c b a));                                      #TmatchesText
  ok !$c->matchesText(qr(\AD), qw(c b a));                                      #TmatchesText
  is_deeply [qw(E)], [$c->matchesText(qr(CD(.)CD))];                            #TmatchesText
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

if (1)                                                                          #TnumberTree #TfindByNumber #Tnumber
 {my $a = Data::Edit::Xml::new(<<END);
<a><b><c/></b><d><e/></d></a>
END

  $a->numberTree;
  ok -z $a eq <<END;
<a id="1">
  <b id="2">
    <c id="3"/>
  </b>
  <d id="4">
    <e id="5"/>
  </d>
</a>
END

  ok -t $a->findByNumber_4 eq q(d);
  ok    $a->findByNumber_3__up__number == 2;
 }

if (1)                                                                          #Tup #Tupn #TupUntil #TupWhile
 {my $a = Data::Edit::Xml::new(<<END);
<a><b><c><b><b><b><b><c/></b></b></b></b></c></b></a>
END

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

  my $c = $a->findByNumber(8);
  ok -t $c eq q(c);
  ok  $c->up__number == 7;
  ok  $c->upn_2__number == 6;
  ok  $c->upWhile_b__number == 4;
  ok  $c->upWhile_a_b__number == 4;
  ok  $c->upWhile_b_c__number == 2;

  ok  $c->upUntil__number == 7;
  ok  $c->upUntil_b_c__number == 4;
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
  my $x = Data::Edit::Xml::new(<<END);                                          #Tordered #Tpath #Tdisordered #Tabove #Tbelow #Tbefore #Tafter #TabovePath #TbelowPath
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
  my ($a, $b, $c, $d, $e) = $x->firstDown(@tags);                               #TabovePath #TbelowPath
  my ($A, $B, $C, $D, $E) = $x->lastDown(@tags);

  is_deeply [$b, $d, $e], [$b->abovePath($e)];                                  #TabovePath
  is_deeply [$e, $d, $b], [$e->belowPath($b)];                                  #TbelowPath
  is_deeply [],   [$c->abovePath($d)];                                          #TabovePath
  is_deeply [$c], [$c->belowPath($c)];                                          #TbelowPath

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

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TfirstOf #TlastOf
<a><b><c/><d/><d/><e/><d/><d/><c/></b></a>
END
  is_deeply [qw(c d d)], [map {-t $_} $a->go(q(b))->firstOf(qw(c d))];          #TfirstOf
  is_deeply [qw(d d c)], [map {-t $_} $a->go(q(b))->lastOf (qw(c d))];          #TlastOf
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
  overWriteFile($f, <<END);
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
  overWriteFile($f, <<END);
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
   {my ($o) = @_;
    for my $t('', ' ', 'aa', 11)
     {$o->putFirst($x->newTag(q(a)))           if ++$A %  3 == 0;
      $o->putLast ($x->newTag(q(b)))           if ++$A %  5 == 0;
      if ($o->parent)
       {$o->putNext ($x->newTag(q(c)))         if ++$A %  7 == 0;
        $o->putPrev ($x->newTag(q(d)))         if ++$A %  2 == 0;
        $o->putFirstAsText($t)                 if ++$A %  3 == 0;
        $o->putLastAsText ($t)                 if ++$A %  2 == 0;
        $o->putNextAsText ($t)                 if ++$A %  3 == 0;
        $o->putPrevAsText ($t)                 if ++$A %  2 == 0;
       }
      $o->wrapContentWith(qw(ww))              if ++$A %  5 == 0;
      $o->wrapWith(qw(xx))                     if ++$A %  3 == 0;
      $o->wrapUp  (qw(aa bb))                  if ++$A %  5 == 0;
      $o->wrapDown(qw(cc dd))                  if ++$A %  7 == 0;
      if (my $p = $o->parent)
       {if(!$p->above($o))
         {$p->putFirst     ($o->cut) if ++$A % 2 == 0;
          $p->putLast      ($o->cut) if ++$A % 5 == 0;
          $p->replaceWith  ($o->cut) if ++$A % 2 == 0;
          if (my $q = $p->parent)
           {$p->putNext    ($o->cut) if ++$A % 2 == 0;
            $p->putPrev    ($o->cut) if ++$A % 2 == 0;
            $q->putLast    ($o->cut) if ++$A % 3 == 0;
            $q->putNext    ($o->cut) if ++$A % 5 == 0;
            $q->putPrev    ($o->cut) if ++$A % 3 == 0;
            $q->putFirst   ($o->cut) if ++$A % 3 == 0;
            $q->replaceWith($o->cut) if ++$A % 3 == 0;
           }
         }
       }
     }
   });
  is_deeply $x->countTagNames,
   {a     => 1,
    aa    => 22,
    b     => 27,
    B     => 3,
    bb    => 22,
    C     => 10,
    c     => 27,
    cc    => 16,
    CDATA => 168,
    d     => 112,
    dd    => 16,
    ww    => 23,
  };

  ok $x->countTags == 447;
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
 {my $a = Data::Edit::Xml::new(<<END);                                          #TisOnlyChild #TisOnlyChildToDepth #TisEmpty #TisFirstToDepth #TisLastToDepth
<a>
  <b>
    <c>
      <d/>
    </c>
  </b>
  <e>
    <f/>
  </e>
</a>
END

  my ($d, $c, $b, $f, $e) = $a->byList;                                         #TisOnlyChild #TisOnlyChildToDepth #TisEmpty #TisFirstToDepth #TisLastToDepth

  ok  $d->parent->isOnlyChild;
  ok  $d->isOnlyChild;                                                          #TisOnlyChild
  ok  $d->isOnlyChild(qw(d c));
  ok  $d->isOnlyChild(qw(d c b));
  ok  $d->isOnlyChild(qw(d c b a));
  ok !$d->isOnlyChild(qw(b));                                                   #TisOnlyChild
  ok  $d->isOnlyChildToDepth(1, qw(d c b a));                                   #TisOnlyChildToDepth
  ok  $d->isOnlyChildToDepth(2, qw(d c b a));                                   #TisOnlyChildToDepth
  ok !$d->isOnlyChildToDepth(3, qw(d c b a));                                   #TisOnlyChildToDepth
  ok  $d->isEmpty;                                                              #TisEmpty

  ok  $d->isFirstToDepth(4);                                                    #TisFirstToDepth
  ok !$f->isFirstToDepth(2);                                                    #TisFirstToDepth
  ok  $f->isFirstToDepth(1);                                                    #TisFirstToDepth
  ok !$f->isFirstToDepth(3);                                                    #TisFirstToDepth

  ok  $c->isLastToDepth(1);                                                     #TisLastToDepth
  ok !$c->isLastToDepth(3);                                                     #TisLastToDepth
  ok  $d->isLastToDepth(2);                                                     #TisLastToDepth
  ok !$d->isLastToDepth(4);                                                     #TisLastToDepth
 }

#if (1)                                                                         # Operators
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
  ok $x->stringReplacingIdsWithLabels eq '<a><b><c/></b></a>';                                             #TaddLabels #TcountLabels #TgetLabels #TstringNode
  my $b = $x->go(q(b));                                                         #TaddLabels #TcountLabels #TgetLabels #TstringNode
  my $c = $b->go(q(c));
  ok $b->countLabels == 0;                                                      #TaddLabels #TcountLabels #TgetLabels
  ok $c->countLabels == 0;
  $b->addLabels(1..2);                                                          #TaddLabels #TcountLabels #TgetLabels #TstringNode
  $b->addLabels(3..4);                                                          #TaddLabels #TcountLabels #TgetLabels #TstringNode
  ok $x->stringReplacingIdsWithLabels eq '<a><b id="1, 2, 3, 4"><c/></b></a>';                             #TaddLabels #TgetLabels #TcopyLabels #TcountLabels #TstringNode

  $b->numberTree;                                                               #TstringNode
  ok -S $b eq "b(2) 0:1 1:2 2:3 3:4";                                           #TstringNode
  ok $b->countLabels == 4;                                                      #TcountLabels
  is_deeply [1..4], [$b->getLabels];                                            #TgetLabels

  $b->copyLabels($c) for 1..2;                                                  #TcopyLabels
  ok $x->stringReplacingIdsWithLabels eq '<a><b id="1, 2, 3, 4"><c id="1, 2, 3, 4"/></b></a>';             #TcopyLabels #TdeleteLabels
  ok $b->countLabels == 4;
  ok $c->countLabels == 4;
  is_deeply [1..4], [$b->getLabels];
  is_deeply [1..4], [$c->getLabels];

  $b->deleteLabels(1,4) for 1..2;                                               #TdeleteLabels
  ok $x->stringReplacingIdsWithLabels eq '<a><b id="2, 3"><c id="1, 2, 3, 4"/></b></a>';                   #TdeleteLabels #TmoveLabels
  ok $b->countLabels == 2;
  ok $c->countLabels == 4;
  is_deeply [2..3], [$b->getLabels];
  is_deeply [1..4], [$c->getLabels];

  $b->moveLabels($c) for 1..2;                                                  #TmoveLabels
  ok $x->stringReplacingIdsWithLabels eq '<a><b><c id="1, 2, 3, 4"/></b></a>';                             #TmoveLabels
  ok $b->countLabels == 0;
  ok $c->countLabels == 4;
  is_deeply [], [$b->getLabels];
  is_deeply [1..4], [$c->getLabels];

  ok -s $x eq '<a><b><c/></b></a>';
  $c->id = 11;
  ok -s $x eq '<a><b><c id="11"/></b></a>';
  ok $x->stringReplacingIdsWithLabels eq '<a><b><c id="1, 2, 3, 4"/></b></a>';
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

  ok $x->stringReplacingIdsWithLabels eq '<a><b><C><c id="1, 2, 3, 4"><E><D/></E></c></C></b></a>';

  $c->wrapUp(qw(A B));                                                          # WrapUp
  ok -s $x eq '<a><b><C id="1"><B><A><c id="11"><E id="3"><D id="2"/></E></c></A></B></C></b></a>';
  $c->wrapDown(qw(G F));                                                        # WrapDown
  ok -s $x eq '<a><b><C id="1"><B><A><c id="11"><G><F><E id="3"><D id="2"/></E></F></G></c></A></B></C></b></a>';
}

if (1)
 {my $x = Data::Edit::Xml::new("<a><b><c/></b></a>");
  my $b = $x->go(q(b));
  my $c = $x->go(qw(b c));

  ok $x->stringReplacingIdsWithLabels eq '<a><b><c/></b></a>';                                             #TstringReplacingIdsWithLabels
  $b->addLabels(1..4);                                                          #TstringReplacingIdsWithLabels
  $c->addLabels(5..8);                                                          #TstringReplacingIdsWithLabels

  ok $x->stringReplacingIdsWithLabels eq '<a><b id="1, 2, 3, 4"><c id="5, 6, 7, 8"/></b></a>';             #TstringReplacingIdsWithLabels
  my $s = $x->stringReplacingIdsWithLabels;                                     #TstringReplacingIdsWithLabels
  ok $s eq '<a><b id="1, 2, 3, 4"><c id="5, 6, 7, 8"/></b></a>';                #TstringReplacingIdsWithLabels

  $b->deleteLabels;
  $c->deleteLabels;
  ok $x->stringReplacingIdsWithLabels eq '<a><b><c/></b></a>';
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

if (0)                                                                          # X versions
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
 {my $a = Data::Edit::Xml::new q(<a><b><c/></b><d><c/></d></a>);
  ok -s $a -> by(sub {$_ -> cut(qw(c b a))}) eq
    '<a><b/><d><c/></d></a>';
 }

if (1)                                                                          # Delete in context - methods
 {my $a = Data::Edit::Xml::new q(<a><b><c/></b><d><c/></d></a>);
  ok -s $a -> by(sub {$_ -> cut_c_b_a}) eq
    '<a><b/><d><c/></d></a>';
 }

if (1)                                                                          # Delete in context - chaining
 {my $a = Data::Edit::Xml::new("<a><b><c/></b><d><c/></d></a>");
  $a->go_b_c__cut;
  ok -s $a eq
    '<a><b/><d><c/></d></a>';
 }

if (1)                                                                          # Delete in context - operators
 {my $a = Data::Edit::Xml::new("<a><b><c/></b><d><c/></d></a>");
  ok -s ($a x sub {--$_ if $_ <= [qw(c b a)]}) eq
    '<a><b/><d><c/></d></a>';
 }

if (1)                                                                          # Delete in context - operators
 {my $a = Data::Edit::Xml::new("<a><b><c/></b><d><c/></d></a>");
  ok -s ($a x sub{$_->cut_c_b_a}) eq
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

if (1)                                                                          # Bulleted list to <ul>
 {my $a = Data::Edit::Xml::new(<<END);
<a>
<p>• Minimum 1 number</p>
<p>•   No leading, trailing, or embedded spaces</p>
<p>• Not case-sensitive</p>
</a>
END

$a->change_ul->by(sub
 {$_->up__change_li if $_->text_p and $_->text =~ s/\A•\s*//s
 });

  ok -p $a eq <<END;                                                            # Results
<ul>
  <li>Minimum 1 number</li>
  <li>No leading, trailing, or embedded spaces</li>
  <li>Not case-sensitive</li>
</ul>
END
 }

if (1)
 {my $x = Data::Edit::Xml::new(<<END);                                          #TcopyAttrs #TmoveAttrs
<x>
  <a a="1" b="2"/>
  <b b="3" c="4"/>
  <c/>
</x>
END
  my ($a, $b, $c) = $x->contents;                                               #TcopyAttrs #TmoveAttrs
  $a->copyAttrs($b, qw(aa bb));                                                 #TcopyAttrs
  ok <<END eq -p $x;                                                            #TcopyAttrs
<x>
  <a a="1" b="2"/>
  <b b="3" c="4"/>
  <c/>
</x>
END
  $a->copyAttrs($b);                                                            #TcopyAttrs
  ok <<END eq -p $x;                                                            #TcopyAttrs
<x>
  <a a="1" b="2"/>
  <b a="1" b="2" c="4"/>
  <c/>
</x>
END
  $a->moveAttrs($c, qw(aa bb));                                                 #TmoveAttrs
  ok <<END eq -p $x;                                                            #TmoveAttrs
<x>
  <a a="1" b="2"/>
  <b a="1" b="2" c="4"/>
  <c/>
</x>
END
  $b->moveAttrs($c);                                                            #TmoveAttrs
  ok <<END eq -p $x;                                                            #TmoveAttrs
<x>
  <a a="1" b="2"/>
  <b/>
  <c a="1" b="2" c="4"/>
</x>
END
 }

if (1)
 {my $x = Data::Edit::Xml::new(<<END);                                          #TcopyNewAttrs #TmoveNewAttrs
<x>
  <a a="1" b="2"/>
  <b b="3" c="4"/>
  <c/>
</x>
END
  my ($a, $b, $c) = $x->contents;                                               #TcopyNewAttrs #TmoveNewAttrs
  $a->copyNewAttrs($b, qw(aa bb));                                              #TcopyNewAttrs
  ok <<END eq -p $x;                                                            #TcopyNewAttrs
<x>
  <a a="1" b="2"/>
  <b b="3" c="4"/>
  <c/>
</x>
END
  $a->copyNewAttrs($b);                                                         #TcopyNewAttrs
  ok <<END eq -p $x;                                                            #TcopyNewAttrs
<x>
  <a a="1" b="2"/>
  <b a="1" b="3" c="4"/>
  <c/>
</x>
END
  $b->moveNewAttrs($c, qw(aa bb));                                              #TmoveNewAttrs
  ok <<END eq -p $x;                                                            #TmoveNewAttrs
<x>
  <a a="1" b="2"/>
  <b a="1" b="3" c="4"/>
  <c/>
</x>
END
  $b->moveNewAttrs($c);                                                         #TmoveNewAttrs
  ok <<END eq -p $x;                                                            #TmoveNewAttrs #Tswap
<x>
  <a a="1" b="2"/>
  <b/>
  <c a="1" b="3" c="4"/>
</x>
END

  $a->swap($c);                                                                 #Tswap
  ok <<END eq -p $x;                                                            #TmoveNewAttrs #Tswap
<x>
  <c a="1" b="3" c="4"/>
  <b/>
  <a a="1" b="2"/>
</x>
END
 }

if (1)
 {my $x = Data::Edit::Xml::new(<<END);                                          #TisFirstText #TisLastText
<x>
  <a>aaa
    <b>bbb</b>
    ccc
    <d>ddd</d>
    eee
  </a>
</x>
END
  my $a = $x->first;                                                            #TisFirstText
  my ($ta, $b, $tc, $d, $te) = $a->contents;                                    #TisFirstText
  ok $ta      ->isFirstText(qw(a x));                                           #TisFirstText
  ok $b->first->isFirstText(qw(b a x));                                         #TisFirstText
  ok $b->prev ->isFirstText(qw(a x));                                           #TisFirstText
  ok $d->last ->isFirstText(qw(d a x));                                         #TisFirstText
  ok $d->next ->isLastText (qw(a x));                                           #TisLastText
  ok $d->last ->isLastText (qw(d a x));                                         #TisLastText
  ok $te      ->isLastText (qw(a x));                                           #TisLastText
 }

if (1)
 {my $x = Data::Edit::Xml::new(<<END);                                          #Tdiff #Tclone
<x>
  <a>aaa
    <b>bbb</b>
    ccc
    <d>ddd</d>
    eee
  </a>
</x>
END

  ok !$x->diff($x);                                                             #Tdiff
  my $y = $x->clone;                                                            #Tdiff #Tclone
  ok !$x->diff($y);                                                             #Tdiff #Tclone
  $y->first->putLast($x->newTag(q(f)));                                         #Tdiff

  ok nws(<<END) eq nws(-p $y);                                                  #Tdiff
<x>
  <a>aaa
    <b>bbb</b>
    ccc
    <d>ddd</d>
    eee
    <f/>
  </a>
</x>
END

  is_deeply [$x->diff($y)],    ["<d>ddd</d> eee <", "/a></x>", "f/></a></x>"];  #Tdiff
  is_deeply [diff(-p $x, $y)], ["<d>ddd</d> eee <", "/a></x>", "f/></a></x>"];  #Tdiff
  is_deeply [$x->diff(-p $y)], ["<d>ddd</d> eee <", "/a></x>", "f/></a></x>"];  #Tdiff

  my $X = writeFile(undef, -p $x);                                              #Tdiff
  my $Y = writeFile(undef, -p $y);                                              #Tdiff
  is_deeply [diff($X, $Y)],    ["<d>ddd</d> eee <", "/a></x>", "f/></a></x>"];  #Tdiff

  unlink $X, $Y;
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #Tdata
<a   id="1">
  <b id="2"/>
  <c id="3"/>
  <d id="4"/>
</a>
END

  my ($b, $c, $d) = $a->contents;                                               #Tdata
  $c->data->{transform} = 1;                                                    #Tdata

  ok <<END eq -p $a;                                                            #Tdata
<a id="1">
  <b id="2"/>
  <c id="3"/>
  <d id="4"/>
</a>
END

  $a x= sub                                                                     #Tdata
   {$_->cut if $_->data->{transform};
   };

  ok <<END eq -p $a;                                                            #Tdata
<a id="1">
  <b id="2"/>
  <d id="4"/>
</a>
END
 }

ok xmlHeader("<a/>") eq <<END;                                                  #TxmlHeader
<?xml version="1.0" encoding="UTF-8"?>
<a/>
END

if (1)
 {my $a = Data::Edit::Xml::new("<a><b/></a>");                                  #Tcrc

  my ($b) = $a->contents;                                                       #Tcrc

  changeReasonCommentSelectionSpecification = {ccc=>1, ddd=>1};                 #Tcrc #TchangeReasonCommentSelectionSpecification
  $b->putFirst(my $c = $b->newTag(q(c)));                                       #Tcrc
  $c->crc($_) for qw(aaa ccc);                                                  #Tcrc

  ok <<END eq -p $a;                                                            #Tcrc
<a>
  <b><!--ccc-->
    <c/>
  </b>
</a>
END
  changeReasonCommentSelectionSpecification = undef;                            #Tcrc #TchangeReasonCommentSelectionSpecification
  $c->putFirst(my $d = $c->newTag(q(d)));                                       #Tcrc
  $d->crc($_) for qw(aaa ccc);                                                  #Tcrc

  ok <<END eq -p $a;                                                            #Tcrc
<a>
  <b><!--ccc-->
    <c>
      <d/>
    </c>
  </b>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TrequiredCleanUp
<a>
  <b>
    <c>
      ccc
    </c>
  </b>
</a>
END
  my ($b) = $a->contents;                                                       #TrequiredCleanUp
  $b->requiredCleanUp(q(33));                                                   #TrequiredCleanUp
  ok -p $a eq <<END;                                                            #TrequiredCleanUp
<a>
  <required-cleanup outputclass="33">&lt;b&gt;
  &lt;c&gt;
      ccc
    &lt;/c&gt;
&lt;/b&gt;
</required-cleanup>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TreplaceWithRequiredCleanUp
<a>
  <b/>
</a>
END
  my ($b) = $a->contents;                                                       #TreplaceWithRequiredCleanUp
  $b->replaceWithRequiredCleanUp(q(bb));                                        #TreplaceWithRequiredCleanUp
  ok -p $a eq <<END;                                                            #TreplaceWithRequiredCleanUp
<a>
  <required-cleanup>bb</required-cleanup>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TunwrapParentsWithSingleChild
<a>
  <b>
    <c>
      <d/>
    </c>
  </b>
  <e/>
</a>
END

  $a->go(qw(b c d))->unwrapParentsWithSingleChild;                              #TunwrapParentsWithSingleChild
  ok -p $a eq <<END;                                                            #TunwrapParentsWithSingleChild
<a>
  <d/>
  <e/>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TputFirstRequiredCleanUp
<a>
  <b/>
</a>
END
  $a->putFirstRequiredCleanUp(qq(1111\n));                                      #TputFirstRequiredCleanUp
  ok -p $a eq <<END;                                                            #TputFirstRequiredCleanUp #TputLastRequiredCleanUp
<a>
  <required-cleanup>1111
</required-cleanup>
  <b/>
</a>
END
  $a->putLastRequiredCleanUp(qq(4444\n));                                       #TputLastRequiredCleanUp

  ok -p $a eq <<END;                                                            #TputLastRequiredCleanUp #TputNextRequiredCleanUp
<a>
  <required-cleanup>1111
</required-cleanup>
  <b/>
  <required-cleanup>4444
</required-cleanup>
</a>
END

  $a->go(q(b))->putNextRequiredCleanUp(qq(3333\n));                             #TputNextRequiredCleanUp
  ok -p $a eq <<END;                                                            #TputNextRequiredCleanUp  #TputPrevRequiredCleanUp
<a>
  <required-cleanup>1111
</required-cleanup>
  <b/>
  <required-cleanup>3333
</required-cleanup>
  <required-cleanup>4444
</required-cleanup>
</a>
END

  $a->go(q(b))->putPrevRequiredCleanUp(qq(2222\n));                             #TputPrevRequiredCleanUp
  ok -p $a eq <<END;                                                            #TputPrevRequiredCleanUp
<a>
  <required-cleanup>1111
</required-cleanup>
  <required-cleanup>2222
</required-cleanup>
  <b/>
  <required-cleanup>3333
</required-cleanup>
  <required-cleanup>4444
</required-cleanup>
</a>
END
 }


if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #Tinvert
<a>
  <b id="b">
    <c id="c">
      <d/>
      <e/>
    </c>
  </b>
</a>
END

  $a->first->invert;                                                            #Tinvert
  ok -p $a eq <<END;                                                            #Tinvert
<a>
  <c id="c">
    <b id="b">
      <d/>
      <e/>
    </b>
  </c>
</a>
END

  $a->first->invert;                                                            #Tinvert
  ok -p $a eq <<END;                                                            #Tinvert
<a>
  <b id="b">
    <c id="c">
      <d/>
      <e/>
    </c>
  </b>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TinvertFirst #TinvertLast
<a>
  <b>
    <c>
      <d/>
      <e/>
    </c>
    <f/>
    <g/>
  </b>
</a>
END

  $a->first->invertFirst;
  ok -p $a eq <<END;                                                            #TinvertFirst #TinvertLast
<a>
  <c>
    <d/>
    <e/>
    <b>
      <f/>
      <g/>
    </b>
  </c>
</a>
END

  $a->first->invertLast;
  ok -p $a eq <<END;                                                            #TinvertLast
<a>
  <b>
    <c>
      <d/>
      <e/>
    </c>
    <f/>
    <g/>
  </b>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TmergeDuplicateChildWithParent #ThasSingleChild
<a>
  <b   id="b" b="bb">
    <b id="c" c="cc"/>
  </b>
</a>
END

  my ($c, $b) = $a->byList;                                                     #TmergeDuplicateChildWithParent #ThasSingleChild
  is_deeply [$b->id, $c->id], [qw(b c)];                                        #TmergeDuplicateChildWithParent #ThasSingleChild
  ok $c == $b->hasSingleChild;                                                     #TmergeDuplicateChildWithParent #ThasSingleChild
  $b->mergeDuplicateChildWithParent;                                            #TmergeDuplicateChildWithParent
  ok -p $a eq <<END;                                                            #TmergeDuplicateChildWithParent
<a>
  <b b="bb" c="cc" id="b"/>
</a>
END

  ok $b == $a->hasSingleChild;                                                     #TmergeDuplicateChildWithParent #ThasSingleChild
 }

# Dita tests

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TditaObviousChanges
<dita>
  <ol>
    <li><para>aaa</para></li>
    <li><para>bbb</para></li>
  </ol>
</dita>
END

  $a->ditaObviousChanges;                                                       #TditaObviousChanges
  ok -p $a eq <<END;                                                            #TditaListToSteps #TditaStepsToList #TditaObviousChanges
<dita>
  <ol>
    <li>
      <p>aaa</p>
    </li>
    <li>
      <p>bbb</p>
    </li>
  </ol>
</dita>
END

  $a->first->ditaListToSteps;                                                   #TditaListToSteps
  ok -p $a eq <<END;                                                            #TditaListToSteps
<dita>
  <steps>
    <step>
      <cmd>aaa</cmd>
    </step>
    <step>
      <cmd>bbb</cmd>
    </step>
  </steps>
</dita>
END

  $a->first->ditaStepsToList;                                                   #TditaStepsToList
  ok -p $a eq <<END;                                                            #TditaStepsToList #TditaListToStepsUnordered
<dita>
  <ol>
    <li>aaa</li>
    <li>bbb</li>
  </ol>
</dita>
END

  $a->first->ditaListToStepsUnordered;                                          #TditaListToStepsUnordered
  ok -p $a eq <<END;                                                            #TditaListToStepsUnordered
<dita>
  <steps-unordered>
    <step>
      <cmd>aaa</cmd>
    </step>
    <step>
      <cmd>bbb</cmd>
    </step>
  </steps-unordered>
</dita>
END

  ok Data::Edit::Xml::new(q(<concept/>))->ditaTopicHeaders eq <<END;            #TditaTopicHeaders
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd" []>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TditaListToSubSteps
<dita>
  <ol>
    <li>aaa</li>
    <li>bbb</li>
  </ol>
</dita>
END

  $a->first->ditaListToSubSteps;                                                #TditaListToSubSteps
  ok -p $a eq <<END;                                                            #TditaListToSubSteps
<dita>
  <substeps>
    <substep>
      <cmd>aaa</cmd>
    </substep>
    <substep>
      <cmd>bbb</cmd>
    </substep>
  </substeps>
</dita>
END
}

if (1)
 {my $x = Data::Edit::Xml::new(<<END);                                          #ThtmlHeadersToSections #TdivideDocumentIntoSections
<x>
<h1>h1</h1>
  H1
<h2>h2</h2>
  H2
<h3>h3</h3>
  H3
<h3>h3</h3>
  H3
<h2>h2</h2>
  H2
<h4>h4</h4>
  H4
</x>
END

my %file;

$x->htmlHeadersToSections;                                                      #ThtmlHeadersToSections #TdivideDocumentIntoSections

  $x->divideDocumentIntoSections(sub                                            #ThtmlHeadersToSections #TdivideDocumentIntoSections
   {my ($topicref, $section) = @_;                                              #ThtmlHeadersToSections #TdivideDocumentIntoSections
    my $file = keys %file;                                                      #ThtmlHeadersToSections #TdivideDocumentIntoSections
    $topicref->href = $file;                                                    #ThtmlHeadersToSections #TdivideDocumentIntoSections
    $file{$file} = -p $section;                                                 #ThtmlHeadersToSections #TdivideDocumentIntoSections
    $section->cut;                                                              #ThtmlHeadersToSections #TdivideDocumentIntoSections
   });                                                                          #ThtmlHeadersToSections #TdivideDocumentIntoSections

  ok -p $x eq <<END;                                                            #ThtmlHeadersToSections #TdivideDocumentIntoSections
<x>
  <topicref href="0">
    <topicref href="1">
      <topicref href="2"/>
      <topicref href="3"/>
    </topicref>
    <topicref href="4">
      <topicref href="5"/>
    </topicref>
  </topicref>
</x>
END

  ok  nn(dump({map {$_=>nn($file{$_})} keys %file})) eq nn(dump(                #ThtmlHeadersToSections #TdivideDocumentIntoSections
   {"0" => "<section level=\"1\">N  <h1>h1</h1>NN  H1NN</section>N",            #ThtmlHeadersToSections #TdivideDocumentIntoSections
    "1" => "<section level=\"2\">N  <h2>h2</h2>NN  H2NN</section>N",            #ThtmlHeadersToSections #TdivideDocumentIntoSections
    "2" => "<section level=\"3\">N  <h3>h3</h3>NN  H3NN</section>N",            #ThtmlHeadersToSections #TdivideDocumentIntoSections
    "3" => "<section level=\"3\">N  <h3>h3</h3>NN  H3NN</section>N",            #ThtmlHeadersToSections #TdivideDocumentIntoSections
    "4" => "<section level=\"2\">N  <h2>h2</h2>NN  H2NN</section>N",            #ThtmlHeadersToSections #TdivideDocumentIntoSections
    "5" => "<section level=\"4\">N  <h4>h4</h4>NN  H4NN</section>N",            #ThtmlHeadersToSections #TdivideDocumentIntoSections
   }));
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TnumberTreesJustIds
<a>A
  <b id="bb">B
    <c/>
    <d>D
      <e id="ee"/>
        E
      <f/>
        F
    </d>
    G
  </b>
  H
</a>
END
  $a->numberTreesJustIds(q(T));                                                 #TnumberTreesJustIds
  my $A = Data::Edit::Xml::new(<<END);                                          #TnumberTreesJustIds
<a id="T_1">A
  <b id="bb">B
    <c id="T_2"/>
    <d id="T_3">D
      <e id="ee"/>
        E
      <f id="T_4"/>
        F
    </d>
    G
  </b>
  H
</a>
END
  ok -p $a eq -p $A;                                                            #TnumberTreesJustIds
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TchangeText
<a>Hello World</a>
END

  $a->first->changeText(sub{s(l) (L)g});                                        #TchangeText
  ok -s $a eq q(<a>HeLLo WorLd</a>);                                            #TchangeText
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TindexIds
<a id="A">
  <b id="B">
    <c id="C"/>
    <d id="D">
      <e id="E"/>
      <f id="F"/>
    </d>
  </b>
</a>
END

  my $i = $a->indexIds;                                                         #TindexIds
  ok $i->{C}->tag eq q(c);                                                      #TindexIds
  ok $i->{E}->tag eq q(e);                                                      #TindexIds
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TcreatePatch #TData::Edit::Xml::Patch::install
<a>Aaaaa
  <b b1="b1" b2="b2">Bbbbb
    <c c1="c1" />Ccccc
    <d d1="d1" >Ddddd
      <e  e1="e1" />
        Eeeee
      <f  f1="f1" />
        Fffff
    </d>
    Ggggg
  </b>
  Hhhhhh
</a>
END

  my $A = Data::Edit::Xml::new(<<END);                                          #TcreatePatch #TData::Edit::Xml::Patch::install
<a>AaaAaaA
  <b b1="b1" b3="B3">BbbBbbB
    <c c1="C1" />Ccccc
    <d d2="D2" >DddDddD
      <e  e3="E3" />
        EeeEeeE
      <f  f1="F1" />
        FffFffF
    </d>
    GggGggG
  </b>
  Hhhhhh
</a>
END

  $a->numberTreesJustIds(q(a));                                                 #TcreatePatch #TData::Edit::Xml::Patch::install
  $A->numberTreesJustIds(q(a));                                                 #TcreatePatch #TData::Edit::Xml::Patch::install

  my $patches = $a->createPatch($A);                                            #TcreatePatch #TData::Edit::Xml::Patch::install
  $patches->install($a);                                                        #TcreatePatch #TData::Edit::Xml::Patch::install

  ok !$a->diff  ($A);                                                           #TcreatePatch #TData::Edit::Xml::Patch::install
  ok  $a->equals($A);                                                           #TcreatePatch #TData::Edit::Xml::Patch::install
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TupThru
<a>
  <b>
    <c/>
    <d>
      <e/>
      <f/>
    </d>
  </b>
</a>
END

  my ($c, $e, $f, $d, $b) = $a->byList;                                         #TupThru
  ok -t $f                eq q(f);                                              #TupThru
  ok -t $f->upThru        eq q(f);                                              #TupThru
  ok -t $f->upThru(qw(d)) eq q(d);                                              #TupThru
  ok -t eval{$f->upThru(qw(d))->last->prev} eq q(e);                            #TupThru
  ok !  eval{$f->upThru(qw(d b))->next};                                        #TupThru
 }

if (1)
 {my $a = Data::Edit::Xml::newTree(q(a));                                       #TaddFirst
  $a->addFirst(qw(b id b)) for 1..2;                                            #TaddFirst
  ok -p $a eq <<END;                                                            #TaddFirst #TaddLast
<a>
  <b id="b"/>
</a>
END
  $a->addLast(qw(e id e)) for 1..2;                                             #TaddLast
  ok -p $a eq <<END;                                                            #TaddLast #TaddNext
<a>
  <b id="b"/>
  <e id="e"/>
</a>
END
  $a->addFirst(qw(b id B))->addNext(qw(c id c));                                #TaddNext
  ok -p $a eq <<END;                                                            #TaddNext #TaddPrev
<a>
  <b id="b"/>
  <c id="c"/>
  <e id="e"/>
</a>
END
  $a->addLast(qw(e id E))->addPrev(qw(d id d));                                 #TaddPrev
  ok -p $a eq <<END;                                                            #TaddPrev
<a>
  <b id="b"/>
  <c id="c"/>
  <d id="d"/>
  <e id="e"/>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(q(<a><b/></a>));                                 #TaddWrapWith
  my $b = $a->first;                                                            #TaddWrapWith
  $b->addWrapWith(qw(c id c)) for 1..2;                                         #TaddWrapWith
  ok -p $a eq <<END;                                                            #TaddWrapWith #TaddSingleChild
<a>
  <c id="c">
    <b/>
  </c>
</a>
END
  $a->addSingleChild(q(d)) for 1..2;                                            #TaddSingleChild
  ok -p $a eq <<END;                                                            #TaddSingleChild
<a>
  <d>
    <c id="c">
      <b/>
    </c>
  </d>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::newTree(q(a));                                       #TaddFirstAsText
  $a->addFirstAsText(q(aaaa)) for 1..2;                                         #TaddFirstAsText
  ok -s $a eq q(<a>aaaa</a>);                                                   #TaddFirstAsText #TaddLastAsText
  $a->addLastAsText(q(dddd)) for 1..2;                                          #TaddLastAsText
  ok -s $a eq q(<a>aaaadddd</a>);                                               #TaddLastAsText
 }

if (1)
 {my $a = Data::Edit::Xml::new(q(<a><b/></a>));                                 #TaddNextAsText
  $a->go(q(b))->addNextAsText(q(bbbb)) for 1..2;                                #TaddNextAsText
  ok -p $a eq <<END;                                                            #TaddNextAsText #TaddPrevAsText
<a>
  <b/>
bbbb
</a>
END
  $a->go(q(b))->addPrevAsText(q(aaaa)) for 1..2;                                #TaddPrevAsText
  ok -p $a eq <<END;                                                            #TaddPrevAsText
<a>aaaa
  <b/>
bbbb
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TditaParagraphToNote
<a>
  <p> Note: see over for details.</p>
</a>
END

  $a->ditaParagraphToNote(1);                                                   #TditaParagraphToNote
  ok -p $a eq <<END;                                                            #TditaParagraphToNote
<a>
  <note>
    <p>See over for details.</p>
  </note>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #Tpropagate
<a>
  <b b="B">
    <b c="C">
      <c/>
      <b d="D">
        <d/>
        <b e="E">
          <e/>
        </b>
      </b>
    </b>
  </b>
</a>
END

  $a->propagate(q(b));                                                          #Tpropagate
  ok -p $a eq <<END;                                                            #Tpropagate
<a>
  <c b="B" c="C"/>
  <d b="B" c="C" d="D"/>
  <e b="B" c="C" d="D" e="E"/>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(q(<a><b/><c/><d/></a>));                         #TwrapSiblingsBefore

  my ($b, $c, $d) = $a->byList;                                                 #TwrapSiblingsBefore

  $c->wrapSiblingsBefore(q(X));                                                 #TwrapSiblingsBefore
  ok -p $a eq <<END;                                                            #TwrapSiblingsBefore
<a>
  <X>
    <b/>
  </X>
  <c/>
  <d/>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(q(<a><b/><c/><d/></a>));                         #TwrapSiblingsAfter

  my ($b, $c, $d) = $a->byList;                                                 #TwrapSiblingsAfter

  $c->wrapSiblingsAfter(q(Y));                                                  #TwrapSiblingsAfter
  ok -p $a eq <<END;                                                            #TwrapSiblingsAfter
<a>
  <b/>
  <c/>
  <Y>
    <d/>
  </Y>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(q(<a><b/><c/><d/></a>));                         #TwrapSiblingsBetween

  my ($b, $c, $d) = $a->byList;                                                 #TwrapSiblingsBetween

  $b->wrapSiblingsBetween($d, q(Y));                                            #TwrapSiblingsBetween
  ok -p $a eq <<END;                                                            #TwrapSiblingsBetween
<a>
  <b/>
  <Y>
    <c/>
  </Y>
  <d/>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TwordStyles
<a>
 <text:list-style style:name="aa">
   <text:list-level-style-bullet text:level="2"/>
 </text:list-style>
</a>
END

  my $styles = $a->wordStyles;                                                  #TwordStyles
  is_deeply $styles, {bulletedList=>{aa=>{2=>1}}};                              #TwordStyles
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #ThtmlTableToDita
 <table>
   <thead>
    <tr>
       <th>Month</th>
       <th>Savings</th>
       <th>Phone</th>
       <th>Comment</th>
    </tr>
   </thead>
   <tbody>
    <tr>
       <td>January</td>
       <td>100</td>
       <td>555-1212</td>
    </tr>
    <tr>
       <td>February</td>
       <td>80</td>
    </tr>
   </tbody>
</table>
END
  $a->htmlTableToDita;                                                          #ThtmlTableToDita
  ok -p $a eq <<END;                                                            #ThtmlTableToDita
<table>
  <tgroup cols="4">
    <colspec colname="c1" colnum="1" colwidth="1*"/>
    <colspec colname="c2" colnum="2" colwidth="1*"/>
    <colspec colname="c3" colnum="3" colwidth="1*"/>
    <colspec colname="c4" colnum="4" colwidth="1*"/>
    <thead>
      <row>
        <entry>Month</entry>
        <entry>Savings</entry>
        <entry>Phone</entry>
        <entry>Comment</entry>
      </row>
    </thead>
    <tbody>
      <row>
        <entry>January</entry>
        <entry>100</entry>
        <entry nameend="c4" namest="c3">555-1212</entry>
      </row>
      <row>
        <entry>February</entry>
        <entry nameend="c4" namest="c2">80</entry>
      </row>
    </tbody>
  </tgroup>
</table>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TforestNumberTrees
<a>
  <b id="b">
    <c/>
  </b>
  <b id="B">
    <d/>
    <e/>
  </b>
</a>
END

  my $e = $a->go(qw(b -1 e));                                                   #TforestNumberTrees
  $e->forestNumberTrees(1);                                                     #TforestNumberTrees
  ok -p $a eq <<END;                                                            #TforestNumberTrees #TfindByForestNumber
<a id="1_1">
  <b id="1_2">
    <c id="1_3"/>
  </b>
  <b id="1_4">
    <d id="1_5"/>
    <e id="1_6"/>
  </b>
</a>
END
  my $b = $e->findByForestNumber(1, 2);
  is_deeply [$b->getLabels], ["b"];
  my $B = $e->findByForestNumber(1, 4);                                         #TfindByForestNumber
  is_deeply [$B->getLabels], ["B"];                                             #TfindByForestNumber
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TgoFish
<a>
  <b>
    <c>
      <d/>
    </c>
    <c/>
  </b>
  <b/>
</a>
END
  if (1) {
    my ($good, $fail, $possible) = $a->goFish(qw(b c D));                       #TgoFish
    ok  $fail eq q(D);                                                          #TgoFish
    is_deeply $good,     [qw(b c)];                                             #TgoFish
    is_deeply $possible, [q(d)];                                                #TgoFish
   }

  if (1)
   {my ($good, $fail, $possible) = $a->goFish(qw(b 3));
    ok  $fail eq q(3);
    is_deeply $good,     [q(b)];
    is_deeply $possible, [0..2];
   }

  if (1)
   {my ($good, $fail, $possible) = $a->goFish(qw(b 0 c D));
    ok  $fail eq q(D);
    is_deeply $good,     [qw(b 0 c)];
    is_deeply $possible, [qw(d)];
   }

  if (1)
   {my ($g, $f, $p) = $a->goFish(qw(b c d));
    is_deeply $g, [qw(b c d)];
    ok !$f;
    ok !$p;
   }
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TisFirst  #TisLast  #TisOnlyChild #ThowFirst #ThowLast #ThowOnlyChild #ThowFarAbove  #ThowFarBelow #ThowFar #Tadjacent #TcommonAdjacentAncestors
<a>
  <b>
    <c>
      <d/>
    </c>
  </b>
  <b>
    <c/>
  </b>
  <e>
    <f/>
  </e>
</a>
END
  my ($d, $c, $b, $C, $B, $f, $e) = $a->byList;                                 #TisFirst  #TisLast  #TisOnlyChild #ThowFirst #ThowLast #ThowOnlyChild #ThowFarAbove  #ThowFarBelow #ThowFar #Tadjacent #TcommonAdjacentAncestors

  is_deeply [$d->commonAdjacentAncestors($C)], [$b, $B];                        #TcommonAdjacentAncestors                               #ThowFar

  ok $d->howFar($d) == 0;                                                       #ThowFar
  ok $d->howFar($a) == 3;                                                       #ThowFar
  ok $b->howFar($B) == 1;                                                       #ThowFar
  ok $d->howFar($f) == 5;                                                       #ThowFar
  ok $d->howFar($C) == 4;                                                       #ThowFar

  ok  $a->isFirst;                                                              #TisFirst
  ok  $a->isLast;                                                               #TisLast
  ok  $a->isOnlyChild;                                                          #TisOnlyChild
  ok !$a->adjacent($B);                                                         #Tadjacent
  ok  $b->adjacent($B);                                                         #Tadjacent

  ok $d->howFirst     == 4;                                                     #ThowFirst
  ok $f->howLast      == 3;                                                     #ThowLast
  ok $d->howOnlyChild == 2;                                                     #ThowOnlyChild

  ok  $a->howFarAbove($d) == 3;                                                 #ThowFarAbove
  ok !$d->howFarAbove($c);                                                      #ThowFarAbove

  ok  $d->howFarBelow($a) == 3;                                                 #ThowFarBelow
  ok !$c->howFarBelow($d);                                                      #ThowFarBelow
 }


if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #Tnot
<a>
  <b/>
</a>
END
  ok $a->first->not_a_c;                                                        #Tnot
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TAUTOLOAD
<a>
  <b>
    <c/>
  </b>
</a>
END
  my ($c, $b) = $a->byList;                                                     #TAUTOLOAD
  ok  $c->at_c_b_a;                                                             #TAUTOLOAD
  ok !$c->at_b;                                                                 #TAUTOLOAD
  ok  -t $c->change_d_c_b eq q(d);                                              #TAUTOLOAD
  ok !   $c->change_d_b;                                                        #TAUTOLOAD
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TditaMergeLists
<a>
  <li id="1"/>
  <ol/>
  <ol>
    <li id="2"/>
    <li id="3"/>
  </ol>
</a>
END
  $a x= sub{$_->ditaMergeLists};                                                #TditaMergeLists
  ok -p $a eq <<END;                                                            #TditaMergeLists
<a>
  <ol>
    <li id="1"/>
    <li id="2"/>
    <li id="3"/>
  </ol>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(q(<a a="1" b="2" c="3" d="4" e="5"/>));          #TcountAttrNamesOnTagExcluding
  ok $a->countAttrNamesOnTagExcluding_a_b == 3;
END
 }


if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #Tapn #Tap #Tan #TupWhileFirst #TupUntilFirst #TupWhileLast #TupUntilLast #TupWhileIsOnlyChild #TupUntilIsOnlyChild #TdownWhileFirst #TdownWhileLast #TdownWhileIsOnlyChild #ThasSingleChildToDepth
<a>
  <b>
    <c/>
    <d/>
    <e>
      <j/>
    </e>
    <f/>
  </b>
  <g>
    <h>
      <i>
        <k/>
        <l/>
      </i>
    </h>
  </g>
</a>
END
  my ($c, $d, $j, $e, $f, $b, $k, $l, $i, $h, $g) = $a->byList;                 #Tapn #Tap #Tan #TupWhileFirst #TupUntilFirst #TupWhileLast #TupUntilLast #TupWhileIsOnlyChild #TupUntilIsOnlyChild #TdownWhileFirst #TdownWhileLast #TdownWhileSingleChild #ThasSingleChildToDepth

  ok $h == $g->hasSingleChildToDepth(1);                                        #ThasSingleChildToDepth
  ok $i == $g->hasSingleChildToDepth(2);                                        #ThasSingleChildToDepth
  ok      !$g->hasSingleChildToDepth(0);                                        #ThasSingleChildToDepth
  ok      !$g->hasSingleChildToDepth(3);                                        #ThasSingleChildToDepth
  ok $i == $i->hasSingleChildToDepth(0);                                        #ThasSingleChildToDepth

  ok  $h == $g->downWhileHasSingleChild;                                        #TdownWhileHasSingleChild
  ok  $h == $h->downWhileHasSingleChild;                                        #TdownWhileHasSingleChild
  ok       !$i->downWhileHasSingleChild;                                        #TdownWhileHasSingleChild

  ok  $k == $g->downWhileFirst;                                                 #TdownWhileFirst
  ok  $c == $a->downWhileFirst;                                                 #TdownWhileFirst
  ok  $c == $c->downWhileFirst;                                                 #TdownWhileFirst
  ok       !$d->downWhileFirst;                                                 #TdownWhileFirst
  ok  $l == $a->downWhileLast;                                                  #TdownWhileLast
  ok  $l == $g->downWhileLast;                                                  #TdownWhileLast
  ok       !$d->downWhileLast;                                                  #TdownWhileLast

  ok  $h == $i->upWhileIsOnlyChild;                                             #TupWhileIsOnlyChild
  ok  $j == $j->upWhileIsOnlyChild;                                             #TupWhileIsOnlyChild
  ok !$d->upWhileIsOnlyChild;                                                   #TupWhileIsOnlyChild

  ok  $i == $k->upUntilIsOnlyChild;                                             #TupUntilIsOnlyChild

  is_deeply[$c, $e], [$d->apn_c_d_e_b_a];                                       #Tapn

  ok  $c == $d->ap_d_c_b_a;                                                     #Tap
  ok  $c == $d->ap_d;                                                           #Tap
  ok !$c->ap_c;                                                                 #Tap

  ok  $e == $d->an_d_e_b_a;                                                     #Tan
  ok  $f == $e->an_e;                                                           #Tan
  ok !$f->an_f;                                                                 #Tan

  ok  $h == $i->upWhileFirst;                                                   #TupWhileFirst
  ok  $a == $c->upWhileFirst;                                                   #TupWhileFirst
  ok !$d->upWhileFirst;                                                         #TupWhileFirst

  ok  $b == $d->upUntilFirst;                                                   #TupUntilFirst

  ok  $j == $j->upWhileLast;                                                    #TupWhileLast
  ok  $a == $l->upWhileLast;                                                    #TupWhileLast
  ok !$d->upWhileLast;                                                          #TupWhileLast

  ok  $i == $k->upUntilLast;                                                    #TupWhileLast
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TputFirstCut
<a>
  <b>
    <c/>
    <d/>
  </b>
</a>
END
  my ($c, $d, $b) = $a->byList;                                                 #TputFirstCut

  $c->putFirstCut($d, qw(c b a));                                               #TputFirstCut
  ok -p $a eq <<END;                                                            #TputFirstCut
<a>
  <b>
    <c>
      <d/>
    </c>
  </b>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TputLastCut
<a>
  <b>
    <c/>
    <d/>
  </b>
</a>
END
  my ($c, $d, $b) = $a->byList;                                                 #TputLastCut

  $a->putLastCut($d, qw(a));                                                    #TputLastCut

  ok -p $a eq <<END;                                                            #TputLastCut
<a>
  <b>
    <c/>
  </b>
  <d/>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TputNextCut
<a>
  <b>
    <c/>
    <d/>
  </b>
</a>
END
  my ($c, $d, $b) = $a->byList;                                                 #TputNextCut

  $d->putNextCut($c, qw(d b a));                                                #TputNextCut
  ok -p $a eq <<END;                                                            #TputNextCut
<a>
  <b>
    <d/>
    <c/>
  </b>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TputPrevCut
<a>
  <b>
    <c/>
    <d/>
  </b>
</a>
END
  my ($c, $d, $b) = $a->byList;                                                 #TputPrevCut

  $c->putPrevCut($d, qw(c b a));                                                #TputPrevCut
  ok -p $a eq <<END;                                                            #TputPrevCut
<a>
  <b>
    <d/>
    <c/>
  </b>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TopWrapContentWith
<a>
  <b>
    <c/>
    <d/>
  </b>
</a>
END
  my ($c, $d, $b) = $a->byList;                                                 #TopWrapContentWith

  $b *= q(B);                                                                   #TopWrapContentWith
  ok -p $a eq <<END;                                                            #TopWrapContentWith
<a>
  <b>
    <B>
      <c/>
      <d/>
    </B>
  </b>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TopUnwrap
<a>
  <b>
    <c/>
    <d/>
  </b>
</a>
END
  my ($c, $d, $b) = $a->byList;                                                 #TopUnwrap

  $b++;                                                                         #TopUnwrap

  ok -p $a eq <<END;                                                            #TopUnwrap
<a>
  <c/>
  <d/>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TequalsIgnoringAttributes
<a>
  <b   id="1" outputclass="1" name="b">
    <c id="2" outputclass="2" name="c"/>
  </b>
</a>
END
  my $A = Data::Edit::Xml::new(<<END);                                          #TequalsIgnoringAttributes
<a>
  <b   id="11" outputclass="11" name="b">
    <c id="22" outputclass="22" name="c"/>
  </b>
</a>
END

  ok !$a->equals($A);                                                           #TequalsIgnoringAttributes
  ok !$a->equalsIgnoringAttributes($A, qw(id));                                 #TequalsIgnoringAttributes
  ok  $a->equalsIgnoringAttributes($A, qw(id outputclass));                     #TequalsIgnoringAttributes
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TstringExtendingIdsWithLabels
<a id="a">
  <b id="b">
    <c id="c"/>
  </b>
  <b id="B">
    <c id="C"/>
  </b>
</a>
END

  my $A =  Data::Edit::Xml::new(<<END);
<a id="aa">
  <b id="bb">
    <c id="cc"/>
  </b>
  <b>
    <c/>
  </b>
</a>
END

  my $N = 0; $a->by(sub{$_->addLabels((-t $_).++$N)});                          #TstringExtendingIdsWithLabels

  ok -p (new $a->stringExtendingIdsWithLabels) eq <<END;                        #TcopyLabelsAndIdsInTree #TstringExtendingIdsWithLabels
<a id="a, a5">
  <b id="b, b2">
    <c id="c, c1"/>
  </b>
  <b id="B, b4">
    <c id="C, c3"/>
  </b>
</a>
END

  ok -p (new $A->stringExtendingIdsWithLabels) eq <<END;                        #TcopyLabelsAndIdsInTree
<a id="aa">
  <b id="bb">
    <c id="cc"/>
  </b>
  <b>
    <c/>
  </b>
</a>
END

  ok $a->copyLabelsAndIdsInTree($A) == 10;                                      #TcopyLabelsAndIdsInTree

  ok -p (new $A->stringExtendingIdsWithLabels) eq <<END;                        #TcopyLabelsAndIdsInTree #TlabelsInTree
<a id="aa, a, a5">
  <b id="bb, b, b2">
    <c id="cc, c, c1"/>
  </b>
  <b id="B, b4">
    <c id="C, c3"/>
  </b>
</a>
END

  is_deeply [sort keys %{$A->labelsInTree}],                                    #TlabelsInTree
    ["B", "C", "a", "a5", "b", "b2", "b4", "c", "c1", "c3"];                    #TlabelsInTree

 }

if (1)                                                                          #TmatchTree
 {my $a = Data::Edit::Xml::new(<<END);
<a>
  <b>
    <c/>
    <d/>
  </b>
  <e>
    <f>
      <g/>
    </f>
  </e>
</a>
END
  my ($c, $d, $b, $g, $f, $e) = $a->byList;

  is_deeply [$b, $c, $d], [$b->matchTree(qw(b c d))];
  is_deeply [$e, $f, $g], [$e->matchTree(qr(\Ae\Z), [qw(f g)])];
  is_deeply [$c],         [$c->matchTree(qw(c))];
  is_deeply [$a, $b, $c, $d, $e, $f, $g],
            [$a->matchTree({a=>1}, [qw(b c d)], [qw(e), [qw(f g)]])];
 }

if (1)                                                                          #Toat #Toft #Tolt
 {my $a = Data::Edit::Xml::new(<<END);
<a>
  <b>
    <c/>
    <d/>
  </b>
  <e>
    <f>
      <g/>
    </f>
  </e>
</a>
END
  my ($c, $d, $b, $g, $f, $e) = $a->byList;

  ok  $b->oat_c_d;
  ok  $a->oat_b_e;
  ok  $g->oat;
  ok !$b->oat_d;

  ok $a->oft_b;
  ok $b->oft_c;
  ok $f->oft_g;
  ok $g->oft;
  ok !$b->oft_d;

  ok $a->olt_e;
  ok $b->olt_d;
  ok $f->olt_g;
  ok $g->olt;
  ok !$b->olt_c;
 }

if (1)                                                                          #Tmpt #Tmnt
 {my $a = Data::Edit::Xml::new(<<END);
<a>
  <b/>
  <c/>
  <d/>
  <e/>
  <f/>
  <g/>
</a>
END
  my ($b, $c, $d, $e, $f, $g) = $a->contents;

  ok  $f->mpt_e_d_c;
  ok !$f->mpt_e_d_b;

  ok  $c->mnt_d_e_f;
  ok !$c->mnt_e;
 }

if (1)                                                                          #ToverAllTags #ToverFirstTags #ToverLastTags
 {my $a = Data::Edit::Xml::new(<<END);
<a>
  <b/>
  <c/>
  <d/>
</a>
END

  ok  $a->overAllTags_b_c_d;
  ok !$a->overAllTags_b_c;
  ok !$a->overAllTags_b_c_d_e;
  ok  $a->oat_b_c_d;
  ok !$a->oat_B_c_d;

  ok  $a->overFirstTags_b_c_d;
  ok  $a->overFirstTags_b_c;
  ok !$a->overFirstTags_b_c_d_e;
  ok  $a->oft_b_c;
  ok !$a->oft_B_c;

  ok  $a->overLastTags_b_c_d;
  ok  $a->overLastTags_c_d;
  ok !$a->overLastTags_b_c_d_e;
  ok  $a->olt_c_d;
  ok !$a->olt_C_d;
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TfirstTextMatches #TlastTextMatches #TnextTextMatches #TprevTextMatches #TdeleteContent
<a>
  <b>bb<c>cc</c>BB
  </b>
</a>
END
  my ($bb, $cc, $c, $BB, $b) = $a->byList;                                      #TfirstTextMatches #TlastTextMatches

  ok $bb->matchesText(qr(bb));                                                  #TfirstTextMatches
  ok $b->at_b_a &&  $b->firstTextMatches(qr(bb));                               #TfirstTextMatches
  ok                $b->firstTextMatches(qr(bb), qw(b a));                      #TfirstTextMatches
  ok $c->at_c_b &&  $c->firstTextMatches(qr(cc));                               #TfirstTextMatches
  ok $c->at_c_b && !$c->firstTextMatches(qr(bb));                               #TfirstTextMatches

  ok $BB->matchesText(qr(BB));                                                  #TlastTextMatches
  ok $b->at_b_a &&  $b->lastTextMatches(qr(BB));                                #TlastTextMatches
  ok                $b->lastTextMatches(qr(BB), qw(b a));                       #TlastTextMatches
  ok $c->at_c_b &&  $c->lastTextMatches(qr(cc));                                #TlastTextMatches
  ok $c->at_c_b && !$c->lastTextMatches(qr(bb));                                #TlastTextMatches

  ok $cc->matchesText(qr(cc));                                                  #TnextTextMatches #TprevTextMatches
  ok $c->at_c_b &&  $c->prevTextMatches(qr(bb));                                #TprevTextMatches
  ok $c->at_c_b &&  $c->nextTextMatches(qr(BB));                                #TnextTextMatches
  ok $b->at_b   && !$b->prevTextMatches(qr(bb));                                #TprevTextMatches
  ok $b->at_b   && !$b->nextTextMatches(qr(BB));                                #TnextTextMatches

  $b->deleteContent;                                                            #TdeleteContent
  ok -p $a eq <<END;                                                            #TdeleteContent
<a>
  <b/>
</a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TprettyString
<a>
  <b>bbb</b>.
  <c>ccc</c>.
</a>
END

  ok nn(-p $a) eq qq(<a>N  <b>bbb</b>.NN  N  <c>ccc</c>.NNN</a>N);              #TprettyString
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TchangeAttributeValue
<a aa="abc"/>
END
  $a->changeAttributeValue(q(aa), sub{s(b) (B)});                               #TchangeAttributeValue
  ok -p $a eq <<END;                                                            #TchangeAttributeValue
<a aa="aBc"/>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TditaOrganization #TprettyStringDitaHeaders #TopString
<concept/>
END

  Data::Edit::Xml::ditaOrganization = q(ACT);                                   #TditaOrganization #TprettyStringDitaHeaders #TopString

  ok $a->prettyStringDitaHeaders eq <<END;                                      #TditaOrganization #TprettyStringDitaHeaders #TopString
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//ACT//DTD DITA Concept//EN" "concept.dtd" []>
<concept/>
END

  ok -x $a eq <<END;                                                            #TditaOrganization #TprettyStringDitaHeaders #TopString
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//ACT//DTD DITA Concept//EN" "concept.dtd" []>
<concept/>
END
 }

if (1)                                                                          #Tupn
 {my $a = Data::Edit::Xml::new(<<END);                                          #Tupn
<a><b><c><d><e/></d></c></b></a>
END

  my ($e, $d, $c, $b) = $a->byList;                                             #Tupn

  ok $e = $e->upn(0);                                                           #Tupn
  ok $d = $e->upn(1);                                                           #Tupn
  ok $c = $e->upn(2);                                                           #Tupn
  ok $b = $e->upn(3);                                                           #Tupn
  ok $a = $e->upn(4);                                                           #Tupn
  ok     !$e->upn(5);                                                           #Tupn

  is_deeply [$e, $d, $c, $b, $a], [$e->ancestry];
 }

if (1)                                                                          #Tattributes
 {my $a = Data::Edit::Xml::new(q(<a/>));

  $a->id  = q(id);
  ok $a->id eq q(id);
  ok !defined($a->href);
  ok $a->hrefX eq q();
  ok -s $a eq q(<a id="id"/>);
  $a->href = q(href);
  ok $a->href  eq q(href);
  ok $a->hrefX eq q(href);
  ok -s $a eq q(<a href="href" id="id"/>);
  $a->href = undef;
  ok !defined($a->href);
  ok $a->hrefX eq q();
  ok -s $a eq q(<a id="id"/>);
 }

if (1)                                                                          #TditaMaximumNumberOfEntriesInARow #TditaAddColSpecToTgroup
 {my $a = Data::Edit::Xml::new(<<END);
<table>
  <tgroup>
    <tbody>
      <row><entry/></row>
      <row><entry/><entry/></row>
      <row><entry/><entry/><entry/></row>
      <row><entry/><entry/></row>
      <row/>
    </tbody>
  </tgroup>
</table>
END

  ok 3 == $a->ditaMaximumNumberOfEntriesInARow;
  $a->first->ditaAddColSpecToTgroup(3);

  ok -p $a eq <<END
<table>
  <tgroup cols="3">
    <colspec colname="c1" colnum="1" colwidth="1*"/>
    <colspec colname="c2" colnum="2" colwidth="1*"/>
    <colspec colname="c3" colnum="3" colwidth="1*"/>
    <tbody>
      <row>
        <entry/>
      </row>
      <row>
        <entry/>
        <entry/>
      </row>
      <row>
        <entry/>
        <entry/>
        <entry/>
      </row>
      <row>
        <entry/>
        <entry/>
      </row>
      <row/>
    </tbody>
  </tgroup>
</table>
END
 }

if (1)                                                                          #TditaFixTableColSpec
 {my $a = Data::Edit::Xml::new(<<END);
<table>
  <tbody>
    <row><entry/></row>
    <row><entry/><entry/></row>
    <row><entry/><entry/><entry/></row>
    <row><entry/><entry/></row>
    <row>
      <entry>
        <table>
          <tbody>
            <row><entry/><entry/><entry/><entry/><entry/><entry/><entry/></row>
          </tbody>
        </table>
      </entry>
    </row>
 </tbody>
</table>
END

  $a->ditaFixTableColSpec;

  ok -p $a eq <<END
<table>
  <tgroup cols="3">
    <colspec colname="c1" colnum="1" colwidth="1*"/>
    <colspec colname="c2" colnum="2" colwidth="1*"/>
    <colspec colname="c3" colnum="3" colwidth="1*"/>
    <tbody>
      <row>
        <entry/>
      </row>
      <row>
        <entry/>
        <entry/>
      </row>
      <row>
        <entry/>
        <entry/>
        <entry/>
      </row>
      <row>
        <entry/>
        <entry/>
      </row>
      <row>
        <entry>
          <table>
            <tbody>
              <row>
                <entry/>
                <entry/>
                <entry/>
                <entry/>
                <entry/>
                <entry/>
                <entry/>
              </row>
            </tbody>
          </table>
        </entry>
      </row>
    </tbody>
  </tgroup>
</table>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TfirstNot #TlastNot #TnextNot #TprevNot #TnextWhile #TprevWhile #TnextUntil #TprevUntil
<a>
  <b/>
  <c/>
  <d/>
  <e/>
  <f/>
</a>
END
  my ($b, $c, $d, $e, $f) = $a->byList;                                         #TfirstNot #TlastNot #TnextNot #TprevNot #TnextWhile #TprevWhile #TnextUntil #TprevUntil
  ok $c == $a->firstNot_a_b;                                                    #TfirstNot
  ok $d == $a->lastNot_e_f;                                                     #TlastNot

  ok $e == $b->nextWhile_c_d;                                                   #TnextWhile
  ok $c == $f->prevWhile_e_d;                                                   #TprevWhile
  ok $c == $b->nextWhile;                                                       #TnextWhile
  ok $b == $c->prevWhile;                                                       #TprevWhile

  ok $e == $b->nextUntil_e_f;                                                   #TnextUntil
  ok $b == $f->prevUntil_a_b;                                                   #TprevUntil
  ok      !$b->nextUntil;                                                       #TnextUntil
  ok      !$c->prevUntil;                                                       #TprevUntil
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TfirstWhile #TfirstUntil #TlastWhile #TlastUntil
<a><b><c><d><e><f/>
</e></d></c></b>
<B><C><D><E><F/>
</E></D></C></B></a>
END
  my ($f, $e, $d, $c, $b, $F, $E, $D, $C, $B) = $a->byList;                     #TfirstWhile #TfirstUntil #TlastWhile #TlastUntil

  if (1)                                                                        #TfirstWhile #TfirstUntil
   {ok  $d == $a->firstWhile_a_d_c_b;
    ok  $f == $a->firstWhile_a_d_c_b_e_f_g_h;
    ok !$b->firstWhile_a;

    ok  $e == $a->firstUntil_e_d;
    ok       !$c->firstUntil_c;
    ok       !$b->firstUntil_a;
   }

  if (1)                                                                        #TlastWhile #TlastUntil
   {ok  $D == $a->lastWhile_a_D_C_B;
    ok  $F == $a->lastWhile_a_D_C_B_E_F_G_H;
    ok !$B->lastWhile_a;

    ok  $E == $a->lastUntil_E_D;
    ok       !$C->lastUntil_C;
    ok !$B->lastUntil_a;
   }
 }

if (1)                                                                          #TAUTOLOAD
 {my $a = Data::Edit::Xml::new(<<END);
<a><b><c/><d/><e/><f/></b></a>
END

  ok -t $a->first_b__first_c__next__next_e__next eq q(f);
  ok   !$a->first_b__first_c__next__next_f;
 }

if (1)                                                                          #TmatchesNextTags #TmatchesPrevTags
 {my $a = Data::Edit::Xml::new(<<END);
<a><b><c/><d/><e/><f/></b></a>
END

  ok  -t $a->first__first__matchesNextTags_d_e eq q(c);
  ok  -t $a->first__first__mnt_d_e             eq q(c);
  ok    !$a->       first__matchesNextTags_d_e;
  ok  -t $a->  last->last__matchesPrevTags_e_d eq q(f);
  ok  -t $a->  last->last__mpt_e_d             eq q(f);
  ok    !$a->        last__matchesPrevTags_e_d;
 }

if (1)                                                                          #Tfirstn #Tnextn
 {my $a = Data::Edit::Xml::new(<<END);
<a><b><c><d/><e/><f/></c></b></a>
END
  ok -p $a eq <<END;
<a>
  <b>
    <c>
      <d/>
      <e/>
      <f/>
    </c>
  </b>
</a>
END
  ok  -t $a->firstn_0 eq q(a);
  ok  -t $a->firstn_1 eq q(b);
  ok  -t $a->firstn_2 eq q(c);
  ok  -t $a->firstn_3 eq q(d);

  ok  -t $a->firstn_3__nextn_0 eq q(d);
  ok  -t $a->firstn_3__nextn_1 eq q(e);
  ok  -t $a->firstn_3__nextn_2 eq q(f);
 }

if (1)                                                                          #Tlastn #Tprevn
 {my $a = Data::Edit::Xml::new(<<END);
<a><b><c><d/><e/><f/></c></b>
   <B><C><D/><E/><F/></C></B></a>
END
  ok -p $a eq <<END;
<a>
  <b>
    <c>
      <d/>
      <e/>
      <f/>
    </c>
  </b>
  <B>
    <C>
      <D/>
      <E/>
      <F/>
    </C>
  </B>
</a>
END

  ok  -t $a->lastn_0 eq q(a);
  ok  -t $a->lastn_1 eq q(B);
  ok  -t $a->lastn_2 eq q(C);
  ok  -t $a->lastn_3 eq q(F);

  ok  -t $a->lastn_3__prevn_0 eq q(F);
  ok  -t $a->lastn_3__prevn_1 eq q(E);
  ok  -t $a->lastn_3__prevn_2 eq q(D);
 }

if (!$windows) {
  my $a = Data::Edit::Xml::new(q(<a>).(q(<b>𝝱</b>)x1e3).q(</a>));               #TwriteCompressedFile #TreadCompressedFile
  my $file = $a->writeCompressedFile(q(zzz.xml.zip));                           #TwriteCompressedFile #TreadCompressedFile
  ok length(-s $a) eq 8007;
  ok -e $file;
  my $A = readCompressedFile($file);                                            #TwriteCompressedFile #TreadCompressedFile
  ok $a->equals($A);                                                            #TwriteCompressedFile #TreadCompressedFile
  ok length(-s $a) == length(-s $A);
  ok -t $a->firstn_0    eq q(a);
  ok -t $a->firstn_1    eq q(b);
  ok $a->firstn_2__text eq q(𝝱);
  unlink $file;
 }
else
 {ok 1 for 1..7
 }

if (1)                                                                          #TditaPrettyPrintWithHeaders
 {my $a = Data::Edit::Xml::new(q(<concept/>));
  ok $a->ditaPrettyPrintWithHeaders eq <<END;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//ACT//DTD DITA Concept//EN" "concept.dtd" []>
<concept/>
END
 }

if (1)                                                                          # Command and attributes
 {my $a = Data::Edit::Xml::new(<<END);
<a><b><c><d/><e/><e/><f/><f/></c></b></a>
END
  my $n = 0;
  $a->by(sub
   {my ($o) = @_;
    $o->id    = ++$n % 2;
    $o->class =   $n % 3;
   });

  ok -p $a eq <<END;
<a class="2" id="0">
  <b class="1" id="1">
    <c class="0" id="0">
      <d class="1" id="1"/>
      <e class="2" id="0"/>
      <e class="0" id="1"/>
      <f class="1" id="0"/>
      <f class="2" id="1"/>
    </c>
  </b>
</a>
END

  $a->by(sub
   {my ($o) = @_;
    ok  $o->class == 2 if $o->atId_0_e;
    ok  $o->class == 0 if $o->atId_1_e_c_b;
    ok !$o->atId_1_e_b;
   });
 }

1
