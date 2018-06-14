#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Edit data held in the XML format.
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2016-2017
#-------------------------------------------------------------------------------
# podDocumentation
# Consider transferring any labels on nodes unwrapped by unwrapContent to calling node
# Preserve labels across a reparse by adding them to a used attribute
# perl -d:NYTProf -Ilib test.pl && nytprofhtml --open
# Line 220 - the & problem 21.04.2018

package Data::Edit::Xml;
our $VERSION = 20180613;
use v5.8.0;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use XML::Parser;                                                                # https://metacpan.org/pod/XML::Parser
use Storable qw(store retrieve freeze thaw);
use utf8;

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

#2 Parse tree attributes                                                        # Attributes of a node in a parse tree. For instance the attributes associated with an XML tag are held in the L<attributes|/attributes> attribute. It should not be necessary to use these attributes directly unless you are writing an extension to this module.  Otherwise you should probably use the methods documented in other sections to manipulate the parse tree as they offer a safer interface at a higher level.

genLValueArrayMethods (qw(content));                                            # Content of command: the nodes immediately below this node in the order in which they appeared in the source text, see also L</Contents>.
genLValueArrayMethods (qw(numbers));                                            # Nodes by number.
genLValueHashMethods  (qw(data));                                               # A hash added to the node for use by the programmer during transformations. The data in this hash will not be printed by any of the L<printed|/Print> methods and so can be used to add data to the parse tree that will not be seen in any output xml produced from the parse tree.
genLValueHashMethods  (qw(attributes));                                         # The attributes of this node, see also: L</Attributes>.  The frequently used attributes: class, id, href, outputclass can be accessed by an lvalue method as in: $node->id = 'c1'.
genLValueHashMethods  (qw(conditions));                                         # Conditional strings attached to a node, see L</Conditions>.
genLValueHashMethods  (qw(indexes));                                            # Indexes to sub commands by tag in the order in which they appeared in the source text.
genLValueHashMethods  (qw(labels));                                             # The labels attached to a node to provide addressability from other nodes, see: L</Labels>.
genLValueScalarMethods(qw(errorsFile));                                         # Error listing file. Use this parameter to explicitly set the name of the file that will be used to write an parse errors to. By default this file is named: B<zzzParseErrors/out.data>.
genLValueScalarMethods(qw(inputFile));                                          # Source file of the parse if this is the parser root node. Use this parameter to explicitly set the file to be parsed.
genLValueScalarMethods(qw(input));                                              # Source of the parse if this is the parser root node. Use this parameter to specify some input either as a string or as a file name for the parser to convert into a parse tree.
genLValueScalarMethods(qw(inputString));                                        # Source string of the parse if this is the parser root node. Use this parameter to explicitly set the string to be parsed.
genLValueScalarMethods(qw(numbering));                                          # Last number used to number a node in this parse tree.
genLValueScalarMethods(qw(number));                                             # Number of this node, see L<findByNumber|/findByNumber>.
genLValueScalarMethods(qw(parent));                                             # Parent node of this node or undef if the parser root node. See also L</Traversal> and L</Navigation>. Consider as read only.
genLValueScalarMethods(qw(parser));                                             # Parser details: the root node of a tree is the parse node for that tree. Consider as read only.
genLValueScalarMethods(qw(tag));                                                # Tag name for this node, see also L</Traversal> and L</Navigation>. Consider as read only.
genLValueScalarMethods(qw(text));                                               # Text of this node but only if it is a text node, i.e. the tag is cdata() <=> L</isText> is true.

#2 Parse tree                                                                   # Construct a parse tree from another parse tree

sub renew($@)                                                                   #C Returns a renewed copy of the parse tree, optionally checking that the starting node is in a specified context: use this method if you have added nodes via the L</"Put as text"> methods and wish to traverse their parse tree.\mReturns the starting node of the new parse tree or B<undef> if the optional context constraint was supplied but not satisfied.
 {my ($node, @context) = @_;                                                    # Node to renew from, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  new($node->string)
 }

sub clone($@)                                                                   #C Return a clone of the parse tree optionally checking that the starting node is in a specified context: the parse tree is cloned without converting it to string and reparsing it so this method will not L<renew|/renew> any nodes added L<as text|/Put as text>.\mReturns the starting node of the new parse tree or B<undef> if the optional context constraint was supplied but not satisfied.
 {my ($node, @context) = @_;                                                    # Node to clone from, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $f = freeze($node);
  my $t = thaw($f);
  $t->parent = undef;
  $t->parser = $t;
  $t
 }

sub equals($$)                                                                  #X Return the first node if the two parse trees have identical representations via L<string>, else B<undef>.
 {my ($node1, $node2) = @_;                                                     # Parse tree 1, parse tree 2.
  $node1->string eq $node2->string ? $node1 : undef                             # Test
 }

sub normalizeWhiteSpace($)                                                      #P Normalize whitespace, remove comments DOCTYPE and xml processors from a string
 {my ($string) = @_;                                                            # String to normalize
  $string =~ s(<\?.*?\?>)     ( )gs;                                            # Processors
  $string =~ s(<!--.*?-->)    ( )gs;                                            # Comments
  $string =~ s(<!DOCTYPE.+?>) ( )gs;                                            # Doctype
  $string =~ s(\s+)           ( )gs;                                            # White space
  $string
 }

sub diff($$;$)                                                                  # Return () if the dense string representations of the two nodes are equal, else up to the first N (default 16) characters of the common prefix before the point of divergence and the remainder of the string representation of each node from the point of divergence. All <!-- ... --> comments are ignored during this comparison and all spans of whitespace are reduced to a single blank.
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
   {push @c, shift @a; shift @b;                                                # Save commion prefix
   }

  $#a = $N-1 if $N and @a > $N;                                                 # Truncate remainder if necessary
  $#b = $N-1 if $N and @b > $N;
  if ($N) {shift @c while @c > $N}

 (join ('', @c), join('', @a), join('', @b))                                    # Return common prefix and diverging strings
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

sub expandIncludes($)                                                           # Expand the includes mentioned in a parse tree: any tag that ends in B<include> is assumed to be an include directive.  The file to be included is named on the B<href> keyword.  If the file to be included is a relative file name, i.e. it does not begin with B</> then this file is made absolute relative to the file from which this parse tree was obtained.
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
  my $i = $N && !defined($node->id) ? " id=\"$N\""  : '';                       # Use id to hold tag
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

sub xmlHeader($)                                                                #S Add the standard xml header to a string
 {my ($string) = @_;                                                            # String to which a standard xml header should be prefixed
  <<END
<?xml version="1.0" encoding="UTF-8"?>
$string
END
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

sub condition($$@)                                                              #CX  Return the node if it has the specified condition and is in the optional context, else return B<undef>
 {my ($node, $condition, @context) = @_;                                        # Node, condition to check, optional context
  return undef if @context and !$node->at(@context);                            # Check optional context
  $node->conditions->{$condition} ? $node : undef                               # Return node if it has the specified condition, else undef
 }

sub anyCondition($@)                                                            #X  Return the node if it has any of the specified conditions, else return B<undef>
 {my ($node, @conditions) = @_;                                                 # Node, conditions to check
  $node->conditions->{$_} ? return $node : undef for @conditions;               # Return node if any of the specified conditions are present
  undef                                                                         # No conditions present
 }

sub allConditions($@)                                                           #X  Return the node if it has all of the specified conditions, else return B<undef>
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

#1 Attributes                                                                   # Get or set the attributes of nodes in the parse tree. L<Well Known Attributes|/Well Known Attributes>  can be set directly via L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>s. To set or get the values of other attributes use L<Get or Set Attributes|/Get or Set Attributes>. To delete or rename attributes see: L<Other Operations on Attributes|/Other Operations on Attributes>.

#2 Well Known Attributes                                                        # Get or set these attributes of nodes via L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>s as in:\m  $x->href = "#ref";
if (0) {                                                                        # Node attributes.
genLValueScalarMethods(qw(audience));                                           # Attribute B<audience> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(class));                                              # Attribute B<class> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(guid));                                               # Attribute B<guid> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(href));                                               # Attribute B<href> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(id));                                                 # Attribute B<id> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(lang));                                               # Attribute B<lang> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(navtitle));                                           # Attribute B<navtitle> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(otherprops));                                         # Attribute B<otherprops> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(outputclass));                                        # Attribute B<outputclass> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(props));                                              # Attribute B<props> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(style));                                              # Attribute B<style> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
genLValueScalarMethods(qw(type));                                               # Attribute B<type> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
}

BEGIN
 {for(qw(audience class guid href id lang navtitle),                            # Return well known attributes as an assignable value
      qw(otherprops outputclass props style type))
   {eval 'sub '.$_.'($) :lvalue {&attr($_[0], qw('.$_.'))}';
    $@ and confess "Cannot create well known attribute $_\n$@";
   }
 }
#2 Get or Set Attributes                                                        # Get or set the attributes of nodes.
sub attr($$) :lvalue                                                            #I Return the value of an attribute of the current node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.
 {my ($node, $attribute) = @_;                                                  # Node in parse tree, attribute name.
  $node->attributes->{$attribute}
 }

sub set($@)                                                                     # Set the values of some attributes in a node and return the node. Identical in effect to L<setAttrs|/setAttrs>.
 {my ($node, %values) = @_;                                                     # Node in parse tree, (attribute name=>new value)*
  s/["<>]/ /gs for grep {$_} values %values;                                    # We cannot have these characters in an attribute
  $node->attributes->{$_} = $values{$_} for keys %values;                       # Set attributes
  $node
 }

sub setAttr($@)                                                                 # Set the values of some attributes in a node and return the node. Identical in effect to L<set|/set>.
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

sub attrCount($@)                                                               # Return the number of attributes in the specified node, optionally ignoring the specified names from the count.
 {my ($node, @exclude) = @_;                                                    # Node in parse tree, optional attribute names to exclude from the count.
  my $a = $node->attributes;                                                    # Attributes
  return scalar grep {defined $a->{$_}} keys %$a if @exclude == 0;              # Count all attributes
  my %e = map{$_=>1} @exclude;                                                  # Hash of attributes to be excluded
  scalar grep {defined $a->{$_} and !$e{$_}} keys %$a;                         # Count attributes that are not excluded
 }

sub getAttrs($)                                                                 # Return a sorted list of all the attributes on this node.
 {my ($node) = @_;                                                              # Node in parse tree.
  my $a = $node->attributes;                                                    # Attributes
  grep {defined $a->{$_}} sort keys %$a                                         # Attributes
 }

sub deleteAttr($$;$)                                                            # Delete the named attribute in the specified node, optionally check its value first, return the node regardless.
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

sub deleteAttrs($@)                                                             # Delete the specified attributes of the specified node without checking their values and return the node.
 {my ($node, @attrs) = @_;                                                      # Node, Names of the attributes to delete
  my $a = $node->attributes;                                                    # Attributes hash
  delete $a->{$_} for @attrs;
  $node
 }

sub renameAttr($$$)                                                             # Change the name of an attribute in the specified node regardless of whether the new attribute already exists or not and return the node. To prevent inadvertent changes to an existing attribute use L<changeAttr|/changeAttr>.
 {my ($node, $old, $new) = @_;                                                  # Node, existing attribute name, new attribute name.
  my $a = $node->attributes;                                                    # Attributes hash
  if (defined($a->{$old}))                                                      # Check old attribute exists
   {my $value = $a->{$old};                                                     # Existing value
    $a->{$new} = $value;                                                        # Change the attribute name
    delete $a->{$old};
   }
  $node
 }

sub changeAttr($$$)                                                             # Change the name of an attribute in the specified node unless it has already been set and return the node. To make changes regardless of whether the new attribute already exists use L<renameAttr|/renameAttr>.
 {my ($node, $old, $new) = @_;                                                  # Node, existing attribute name, new attribute name.
  exists $node->attributes->{$new} ? $node : $node->renameAttr($old, $new)      # Check old attribute exists
 }

sub renameAttrValue($$$$$)                                                      # Change the name and value of an attribute in the specified node regardless of whether the new attribute already exists or not and return the node. To prevent inadvertent changes to existing attributes use L<changeAttrValue|/changeAttrValue>.
 {my ($node, $old, $oldValue, $new, $newValue) = @_;                            # Node, existing attribute name, existing attribute value, new attribute name, new attribute value.
  my $a = $node->attributes;                                                    # Attributes hash
  if (defined($a->{$old}) and $a->{$old} eq $oldValue)                          # Check old attribute exists and has the specified value
   {$a->{$new} = $newValue;                                                     # Change the attribute name
    delete $a->{$old};
   }
  $node
 }

sub changeAttrValue($$$$$)                                                      # Change the name and value of an attribute in the specified node unless it has already been set and return the node.  To make changes regardless of whether the new attribute already exists use L<renameAttrValue|/renameAttrValue>.
 {my ($node, $old, $oldValue, $new, $newValue) = @_;                            # Node, existing attribute name, existing attribute value, new attribute name, new attribute value.
  exists $node->attributes->{$new} ? $node :                                    # Check old attribute exists
    $node->renameAttrValue($old, $oldValue, $new, $newValue)
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

#1 Traversal                                                                    # Traverse the parse tree in various orders applying a B<sub> to each node.

#2 Post-order                                                                   # This order allows you to edit children before their parents.

sub by($$@)                                                                     #I Post-order traversal of a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. A reference to the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>. This is equivalent to the L<x=|/opBy> operator.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  $_->by($sub, $node, @context) for @n;                                         # Recurse to process sub nodes in deeper context
  &$sub(local $_ = $node, @context);                                            # Process specified node last
  $node
 }

sub byX($$)                                                                     #C Post-order traversal of a parse tree calling the specified B<sub> at each node as long as this sub does not L<die|http://perldoc.perl.org/functions/die.html>. The traversal is halted if the called sub does  L<die|http://perldoc.perl.org/functions/die.html> on any call with the reason in L<?@|http://perldoc.perl.org/perlvar.html#Error-Variables> The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry> up to the node on which this sub was called. A reference to the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.\mReturns the start node regardless of the outcome of calling B<sub>.
 {my ($node, $sub) = @_;                                                        # Start node, sub to call
  eval {$node->byX2($sub)};                                                     # Trap any errors that occur
  $node
 }

sub byX2($$@)                                                                   #P Post-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  $_->byX2($sub, $node, @context) for @n;                                       # Recurse to process sub nodes in deeper context
  &$sub(local $_ = $node, @context);                                            # Process specified node last
 }

sub byX22($$@)                                                                  #P Post-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  $_->byX($sub, $node, @context) for @n;                                        # Recurse to process sub nodes in deeper context
  eval {&$sub(local $_ = $node, @context)};                                     # Process specified node last
  $node
 }

sub byList($@)                                                                  #C Return a list of all the nodes at and below a node in preorder or the empty list if the node is not in the optional context.
 {my ($node, @context) = @_;                                                    # Starting node, optional context
  return () if @context and !$node->at(@context);                               # Check optional context
  my @n;                                                                        # Nodes
  $node->by(sub{push @n, $_});                                                  # Retrieve nodes in pre-order
  @n                                                                            # Return list of nodes
 }

sub byReverse($$;@)                                                             # Reverse post-order traversal of a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  $_->byReverse($sub, $node, @context) for reverse @n;                          # Recurse to process sub nodes in deeper context
  &$sub(local $_ = $node, @context);                                            # Process specified node last
  $node
 }

sub byReverseX($$;@)                                                            # Reverse post-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  $_->byReverseX($sub, $node, @context) for reverse @n;                         # Recurse to process sub nodes in deeper context
  &$sub(local $_ = $node, @context);                                            # Process specified node last
  $node
 }

sub byReverseList($@)                                                           #C Return a list of all the nodes at and below a node in reverse preorder or the empty list if the node is not in the optional context.
 {my ($node, @context) = @_;                                                    # Starting node, optional context
  return () if @context and !$node->at(@context);                               # Check optional context
  my @n;                                                                        # Nodes
  $node->byReverse(sub{push @n, $_});                                           # Retrieve nodes in reverse pre-order
  @n                                                                            # Return list of nodes
 }

#2 Pre-order                                                                    # This order allows you to edit children after their parents

sub down($$;@)                                                                  # Pre-order traversal down through a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$sub(local $_ = $node, @context);                                            # Process specified node first
  $_->down($sub, $node, @context) for @n;                                       # Recurse to process sub nodes in deeper context
  $node
 }

sub downX($$)                                                                   #C Pre-order traversal of a parse tree calling the specified B<sub> at each node as long as this sub does not L<die|http://perldoc.perl.org/functions/die.html>. The traversal is halted if the called sub does  L<die|http://perldoc.perl.org/functions/die.html> on any call with the reason in L<?@|http://perldoc.perl.org/perlvar.html#Error-Variables> The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry> up to the node on which this sub was called. A reference to the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.\mReturns the start node regardless of the outcome of calling B<sub>.
 {my ($node, $sub) = @_;                                                        # Start node, sub to call
  eval {$node->downX2($sub)};                                                   # Trap any errors that occur
  $node
 }

sub downX2($$;@)                                                                #P Pre-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$sub(local $_ = $node, @context);                                            # Process specified node last
  $_->downX2($sub, $node, @context) for @n;                                     # Recurse to process sub nodes in deeper context
 }

sub downX22($$;@)                                                               #P Pre-order traversal down through a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$sub(local $_ = $node, @context);                                            # Process specified node first
  $_->downX($sub, $node, @context) for @n;                                      # Recurse to process sub nodes in deeper context
  $node
 }

sub downReverse($$;@)                                                           # Reverse pre-order traversal down through a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$sub(local $_ = $node, @context);                                            # Process specified node first
  $_->downReverse($sub, $node, @context) for reverse @n;                        # Recurse to process sub nodes in deeper context
  $node
 }

sub downReverseX($$;@)                                                          # Reverse pre-order traversal down through a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.
 {my ($node, $sub, @context) = @_;                                              # Starting node, sub to call for each sub node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$sub(local $_ = $node, @context);                                            # Process specified node first
  $_->downReverseX($sub, $node, @context) for reverse @n;                       # Recurse to process sub nodes in deeper context
  $node
 }

#2 Pre and Post order                                                           # Visit the parent first, then the children, then the parent again.

sub through($$$;@)                                                              # Traverse parse tree visiting each node twice calling the specified B<sub> at each node and returning the specified starting node. The B<sub>s are passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.
 {my ($node, $before, $after, @context) = @_;                                   # Starting node, sub to call when we meet a node, sub to call we leave a node, accumulated context.
  my @n = $node->contents;                                                      # Clone the content array so that the tree can be modified if desired
  &$before(local $_ = $node, @context);                                         # Process specified node first with before()
  $_->through($before, $after, $node, @context) for @n;                         # Recurse to process sub nodes in deeper context
  &$after(local $_ = $node, @context);                                          # Process specified node last with after()
  $node
 }

sub throughX($$$;@)                                                             # Traverse parse tree visiting each node twice calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.
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

sub atOrBelow($@)                                                               #X Confirm that the node or one of its ancestors has the specified context as recognized by L<at|/at> and return the first node that matches the context or B<undef> if none do.
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

sub isOnlyChild($@)                                                             #CX Return the specified node if it is the only node under its parent ignoring any surrounding blank text.
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

sub singleChild($@)                                                             #CX Return the only child of a specified node if the child is the only node under its parent ignoring any surrounding blank text, else return B<undef>.
 {my ($parent, @context) = @_;                                                  # Node, optional context
  return undef if @context and !$parent->at(@context);                          # Not in specified context
  return undef unless my $child = $parent->first;                               # A possible child node
  return undef unless $child->isOnlyChild;                                      # Not an only child
  $child                                                                        # Return the only child
 }

sub isEmpty($@)                                                                 #CX Confirm that this node is empty, that is: this node has no content, not even a blank string of text. To test for blank nodes, see L<isAllBlankText|/isAllBlankText>.
 {my ($node, @context) = @_;                                                    # Node, optional context
  return undef if @context and !$node->at(@context);                            # Not in specified context
  !$node->first ? $node : undef                                                 # If it has no first descendant it must be empty
 }

sub over($$@)                                                                   #CX Confirm that the string representing the tags at the level below this node match a regular expression where each pair of tags is separated by a single space. Use L<contentAsTags|/contentAsTags> to visualize the tags at the next level.
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentAsTags =~ m/$re/ ? $node : undef
 }

sub over2($$@)                                                                   #CX Confirm that the string representing the tags at the level below this node match a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a space and the last tag is followed by a space.  This arrangement simplifies the regular expression used to detect combinations like p+ q? . Use L<contentAsTags2|/contentAsTags2> to visualize the tags at the next level.
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentAsTags2 =~ m/$re/ ? $node : undef
 }

sub matchAfter($$@)                                                             #CX Confirm that the string representing the tags following this node matches a regular expression where each pair of tags is separated by a single space. Use L<contentAfterAsTags|/contentAfterAsTags> to visualize these tags.
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentAfterAsTags =~ m/$re/ ? $node : undef
 }

sub matchAfter2($$@)                                                             #CX Confirm that the string representing the tags following this node matches a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a space and the last tag is followed by a space.  This arrangement simplifies the regular expression used to detect combinations like p+ q? Use L<contentAfterAsTags2|/contentAfterAsTags2> to visualize these tags.
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentAfterAsTags2 =~ m/$re/ ? $node : undef
 }

sub matchBefore($$@)                                                            #CX Confirm that the string representing the tags preceding this node matches a regular expression where each pair of tags is separated by a single space. Use L<contentBeforeAsTags|/contentBeforeAsTags> to visualize these tags.
 {my ($node, $re, @context) = @_;                                               # Node, regular expression, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  $node->contentBeforeAsTags =~ m/$re/ ? $node : undef
 }

sub matchBefore2($$@)                                                           #CX Confirm that the string representing the tags preceding this node matches a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a space and the last tag is followed by a space.  This arrangement simplifies the regular expression used to detect combinations like p+ q?  Use L<contentBeforeAsTags2|/contentBeforeAsTags2> to visualize these tags.
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

sub c($$)                                                                       # Return an array of all the nodes with the specified tag below the specified node. This method is deprecated in favor of applying L<grep|https://perldoc.perl.org/functions/grep.html> to L<contents|/contents>.
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

sub firstText($@)                                                               #CX Return the first node if it is a text node otherwise undef
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

sub firstSibling($@)                                                            #CX Return the first sibling of the specified node in the optional context else B<undef>
 {my ($node, @context) = @_;                                                    # Node, array of tags specifying context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $p = $node->parent;                                                        # Parent node
  $p->first                                                                     # Return first sibling
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

sub lastIn($@)                                                                  #X Return the last  node matching one of the named tags under the specified node.
 {my ($node, @tags) = @_;                                                       # Node, tags to search for.
  my %tags = map {$_=>1} @tags;                                                 # Hashify tags
  for(reverse $node->contents)                                                  # Search backwards through contents
   {return $_ if $tags{$_->tag};                                                # Find last tag with the specified name
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
  return @l                                                                     # All tags match
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

sub lastSibling($@)                                                             #CX Return the last sibling of the specified node in the optional context else B<undef>
 {my ($node, @context) = @_;                                                    # Node, array of tags specifying context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
  my $p = $node->parent;                                                        # Parent node
  $p->last                                                                      # Return last sibling
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

sub nextText($@)                                                                #CX Return the next node if it is a text node otherwise undef
 {my ($node, @context) = @_;                                                    # Node, optional context.
  my $n = &next(@_);                                                            # Next node
  $n ? $n->isText : undef                                                       # Test whether the next node exists and is a text node
 }

sub nextIn($@)                                                                  #X Return the nearest sibling after the specified node that matches one of the named tags or B<undef> if there is no such sibling node.
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

sub prevText($@)                                                                #CX Return the previous node if it is a text node otherwise undef
 {my ($node, @context) = @_;                                                    # Node, optional context.
  my $p = &prev(@_);                                                            # Previous node
  $p ? $p->isText : undef                                                       # Test whether the previous node exists and is a text node
 }

sub prevIn($@)                                                                  #X Return the nearest sibling node before the specified node which matches one of the named tags or B<undef> if there is no such sibling node.
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

#2 Up                                                                           # Methods for moving up the parse tree from a node.

sub up($@)                                                                      #CX Return the parent of the current node optionally checking the context of the specified node first or return B<undef> if the specified node is the root of the parse tree.
 {my ($node, @tags) = @_;                                                       # Start node, optional tags identifying context.
  return undef if @tags and !$node->at(@tags);                                  # Check optional context
  $node->parent                                                                 # Go up one level
 }

sub upWhile($$)                                                                 #X Move up starting from the specified node as long as the tag of each node matches the specified regular expression.  Return the last matching node if there is one else B<undef>.
 {my ($node, $re) = @_;                                                         # Start node, tags identifying context.
  my $lastMatch;                                                                # Last matching node
  for(my $p = $node; $p; $p = $p->parent)                                       # Go up
   {return $lastMatch unless $p->tag =~ m($re);                                 # Return last node which satisfied the specified regular expression
    $lastMatch = $p                                                             # Update last matching position
   }
  $lastMatch                                                                    # Root node matches
 }

sub upTo($@)                                                                    #X Return the first ancestral node that matches the specified context.
 {my ($node, @tags) = @_;                                                       # Start node, tags identifying context.
  for(my $p = $node; $p; $p = $p->parent)                                       # Go up
   {return $p if $p->at(@tags);                                                 # Return node which satisfies the condition
   }
  return undef                                                                  # Not found
 }

#1 Editing                                                                      # Edit the data in the parse tree and change the structure of the parse tree by L<wrapping and unwrapping|/Wrap and unwrap> nodes, by L<replacing|/Replace> nodes, by L<cutting and pasting|/Cut and Put> nodes, by L<concatenating|/Fusion> nodes, by L<splitting|/Fission> nodes, by adding new L<text|/Put as text> nodes or L<swapping|/swap> nodes.

sub change($$@)                                                                 #CIX Change the name of a node, optionally  confirming that the node is in a specified context and return the node.
 {my ($node, $name, @context) = @_;                                             # Node, new name, optional context.
  return undef if @context and !$node->at(@context);                            # Not in specified context
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

sub mergeDuplicateChildWithParent($@)                                           #C Merge a parent node with its only child if their tags are the same and their attributes do not collide other than possibly the id in which case the parent id is used. Any labels on the child are transferred to the parent. The child node is then unwrapped and the parent node is returned.
 {my ($parent, @context) = @_;                                                  # Parent this node, optional context.
  return undef if @context and !$parent->at(@context);                          # Not in specified context
  return undef unless my $child = $parent->singleChild;                         # Not an only child
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

sub replaceWith($$@)                                                            #C Replace a node (and all its content) with a L<new node|/newTag> (and all its content) and return the new node. If the node to be replaced is the root of the parse tree then no action is taken other then returning the new node.
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

#2 Swap                                                                         # Swap nodes both singly and in blocks

sub swap($$@)                                                                   #CX Swap two nodes optionally checking that the first node is in the specified context and return the first node.
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

sub wrapContentWith($$@)                                                        # Wrap the content of a node in a new node: the original node then contains just the new node which, in turn, contains all the content of the original node.\mReturns the new wrapped node.
 {my ($old, $tag, %attributes) = @_;                                            # Node, tag for new node, attributes for new node.
  my $new = newTag(undef, $tag, %attributes);                                   # Create wrapping node
  $new->parser  = $old->parser;                                                 # Assign the new node to the old parser
  $new->content = $old->content;                                                # Transfer content
  $old->content = [$new];                                                       # Insert new node
  $new->indexNode;                                                              # Create indices for new node
  $old->indexNode;                                                              # Rebuild indices for old mode
  $new                                                                          # Return new node
 }

sub wrapTo($$$@)                                                                #X Wrap all the nodes from the start node to the end node with a new node with the specified tag and attributes and return the new node.  Return B<undef> if the start and end nodes are not siblings - they must have the same parent for this method to work.
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

sub wrapFrom($$$@)                                                              #X Wrap all the nodes from the start node to the end node with a new node with the specified tag and attributes and return the new node.  Return B<undef> if the start and end nodes are not siblings - they must have the same parent for this method to work.
 {my ($end, $start, $tag, @attr) = @_;                                          # End node, start node, tag for the wrapping node, attributes for the wrapping node
  $start->wrapTo($end, $tag, @attr);                                            # Invert and wrapTo
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

sub unwrapParentsWithSingleChild($)                                             #CX Unwrap any immediate ancestors of the specified node which have only a single child and return the specified node regardless.
 {my ($o) = @_;                                                                 # Node
  my @p;                                                                        # Parents with single child
  for(my $p = $o->parent; $p; $p = $p->parent)                                  # Check each parent
   {$o->isOnlyChild and $p->parent ? push @p, $p : last                         # Locate parents with single child
   }
  -W $_ for @p;                                                                 # Unwrap parents with single child
  $o                                                                            # Return node
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

sub contentAsTags($@)                                                           #KX Return a string containing the tags of all the child nodes of this node separated by single spaces or the empty string if the node is empty or undef if the node does not match the optional context. Use L<over|/over> to test the sequence of tags with a regular expression.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join ' ', map {$_->tag} $node->contents
 }

sub contentAsTags2($@)                                                          #KX Return a string containing the tags of all the child nodes of this node separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or undef if the node does not match the optional context. Use L<over2|/over2> to test the sequence of tags with a regular expression. Use L<over2|/over2> to test the sequence of tags with a regular expression.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join '', map {' '.$_->tag.' '} $node->contents
 }

sub contentAfterAsTags($@)                                                      #K Return a string containing the tags of all the sibling nodes following this node separated by single spaces or the empty string if the node is empty or undef if the node does not match the optional context. Use L<matchAfter|/matchAfter> to test the sequence of tags with a regular expression.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join ' ', map {$_->tag} $node->contentAfter
 }

sub contentAfterAsTags2($@)                                                     #K Return a string containing the tags of all the sibling nodes following this node separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or undef if the node does not match the optional context. Use L<matchAfter2|/matchAfter2> to test the sequence of tags with a regular expression.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join '', map {' '.$_->tag.' '} $node->contentAfter
 }

sub contentBeforeAsTags($@)                                                     #K Return a string containing the tags of all the sibling nodes preceding this node separated by single spaces or the empty string if the node is empty or undef if the node does not match the optional context. Use L<matchBefore|/matchBefore> to test the sequence of tags with a regular expression.
 {my ($node, @context) = @_;                                                    # Node, optional context.
  return undef if @context and !$node->at(@context);                            # Optionally check the context
  join ' ', map {$_->tag} $node->contentBefore
 }

sub contentBeforeAsTags2($@)                                                    #K Return a string containing the tags of all the sibling nodes preceding this node separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or undef if the node does not match the optional context.  Use L<matchBefore2|/matchBefore2> to test the sequence of tags with a regular expression.
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

sub isFirstText($@)                                                             #CX Return the specified node if this node is a text node, the first node under its parent and that the parent is optionally in the specified context, else return B<undef>.
 {my ($node, @context) = @_;                                                    # Node to test, optional context for parent
  return undef unless $node->isText(@context) and $node->isFirst;               # Check that this node is a text node, that it is first, and, optionally check context of parent
  $node                                                                         # Return the nide as it passes all tests
 }

sub isLastText($@)                                                              #CX Return the specified node if this node is a text node, the last node under its parent and that the parent is optionally in the specified context, else return B<undef>.
 {my ($node, @context) = @_;                                                    # Node to test, optional context for parent
  return undef unless $node->isText(@context) and $node->isLast;                # Check that this node is a text node, that it is last, and, optionally check context of parent
  $node                                                                         # Return the nide as it passes all tests
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

sub above($$@)                                                                  #CX Return the first node if the first node is above the second node optionally checking that the first node is in the specified context otherwise return B<undef>
 {my ($first, $second, @context) = @_;                                          # First node, second node, optional context
  return undef if @context and !$first->at(@context);                           # Not in specified context
  return undef if $first == $second;                                            # A node cannot be above itself
  my @n = $first ->ancestry;
  my @t = $second->ancestry;
  pop @n, pop @t while @n and @t and $n[-1] == $t[-1];                          # Find first different ancestor
  !@n ? $first : undef                                                          # Node is above target if its ancestors are all ancestors of target
 }

sub below($$@)                                                                  #CX Return the first node if the first node is below the second node optionally checking that the first node is in the specified context otherwise return B<undef>
 {my ($first, $second, @context) = @_;                                          # First node, second node, optional context
  $second->above($first, @context);                                             # The second node is above the first node if the first node is below the second node
 }

sub after($$@)                                                                  #CX Return the first node if it occurs after the second node in the parse tree optionally checking that the first node is in the specified context or else B<undef> if the node is L<above|/above>, L<below|/below> or L<before|/before> the target.
 {my ($first, $second, @context) = @_;                                          # First node, second node, optional context
  return undef if @context and !$first->at(@context);                           # First node not in specified context
  my @n = $first ->ancestry;
  my @t = $second->ancestry;
  pop @n, pop @t while @n and @t and $n[-1] == $t[-1];                          # Find first different ancestor
  return undef unless @n and @t;                                                # Undef if we cannot decide
  $n[-1]->position > $t[-1]->position                                           # Node relative to target at first common ancestor
 }

sub before($$@)                                                                 #CX Return the first node if it occurs before the second node in the parse tree optionally checking that the first node is in the specified context or else B<undef> if the node is L<above|/above>, L<below|/below> or L<before|/before> the target.
 {my ($first, $second, @context) = @_;                                          # First node, second node, optional context
  $second->after($first, @context);                                             # The first node is before the second node if the second node is after the first node
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

sub opString($$)                                                                # -B: L<bitsNodeTextBlank|/bitsNodeTextBlank>\m-b: L<isAllBlankText|/isAllBlankText>\m-c: L<context|/context>\m-e: L<prettyStringEnd|/prettyStringEnd>\m-f: L<first node|/first>\m-g: L<getAttr|/getAttr>\m-l: L<last node|/last>\m-M: L<number|/number>\m-o: L<contentAsTags|/contentAsTags>\m-p: L<prettyString|/prettyString>\m-s: L<string|/string>\m-S : L<stringNode|/stringNode>\m-T : L<isText|/isText>\m-t : L<tag|/tag>\m-u: L<id|/id>\m-W: L<unWrap|/unWrap>\m-w: L<stringQuoted|/stringQuoted>\m-X: L<cut|/cut>\m-z: L<prettyStringNumbered|/prettyStringNumbered>. Dangerous operations which might destroy information are in upper case.
 {my ($node, $op) = @_;                                                         # Node, monadic operator.
  $op or confess;
  return $node->printNode                    if $op eq 'A';
  return $node->bitsNodeTextBlank            if $op eq 'B';
  return $node->isAllBlankText               if $op eq 'b';
  return $node->context                      if $op eq 'c';
# return $node->CCCC                         if $op eq 'C';
# return $node->dddd                         if $op eq 'd';
  return $node->prettyStringEnd              if $op eq 'e';
  return $node->first                        if $op eq 'f';  # Not much use
# return $node->gggg                         if $op eq 'g';
# return $node->kkkk                         if $op eq 'k';
  return $node->last                         if $op eq 'l';  # Not much use
  return $node->number                       if $op eq 'M';
  return $node->contentAsTags2               if $op eq 'O';
  return $node->contentAsTags                if $op eq 'o';
  return $node->prettyString                 if $op eq 'p';
  return $node->requiredCleanUp              if $op eq 'R';
# return $node->rrrr                         if $op eq 'r';
  return $node->stringNode                   if $op eq 'S';
  return $node->string                       if $op eq 's';
  return $node->isText                       if $op eq 'T';
  return $node->tag                          if $op eq 't';
  return $node->id                           if $op eq 'u';
  return $node->unwrap                       if $op eq 'W';
  return $node->stringQuoted                 if $op eq 'w';
  return $node->cut                          if $op eq 'X';
# return $node->xxxx                         if $op eq 'x';
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

sub changeReasonCommentSelectionSpecification :lvalue                           #S Provide a specification to select L<change reason comments|/crc> to be inserted as text into a parse tree. A specification can be either:\m=over\m=item the name of a code to be accepted,\m=item a regular expression which matches the codes to be accepted,\m=item a hash whose keys are defined for the codes to be accepted or\m=item B<undef> (the default) to specify that no such comments should be accepted.\m=back
 {CORE::state $r;
  $r
 }

sub crc($$;$)                                                                   # Insert a comment consisting of a code and an optional reason as text into the parse tree to indicate the location of changes to the parse tree.  As such comments tend to become very numerous, only comments whose codes matches the specification provided in L<changeReasonCommentSelectionSpecification|/changeReasonCommentSelectionSpecification> are accepted for insertion. Subsequently these comments can be easily located using:\mB<grep -nr "<!-->I<code>B<">\mon the file containing a printed version of the parse tree. Please note that these comments will be removed if the output file is reparsed.\mReturns the specified node.
 {my ($node, $code, $reason) = @_;                                              # Node being changed, reason code, optional text description of change
  if (sub                                                                       # Whether to make a change entry in the parse tree
   {my $s = changeReasonCommentSelectionSpecification;                          # Change selection specification
    return undef unless $s;                                                     # Do not record change reasons unless a change selection has been supplied
    my $r = ref $s;                                                             # Change selection has been supplied
    return 1 if $r and $r =~ m(Regexp) and $code =~ m($s);                      # Requested change matches the supplied regular expression
    return 1 if $r and $r =~ m(HASH)   and $s->{$code};                         # Requested change is a key in the supplied hash
    return 1 if $s and $s eq $code;                                             # Requested change equal to the supplied name
    undef                                                                       # No match so do not crate a change entry in the parse tree
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

sub requiredCleanUp($;$)                                                        # Replace a node with a required cleanup node around the text of the replaced node with special characters replaced by symbols.\mReturns the specified node.
 {my ($node, $id) = @_;                                                         # Node, optional id of required cleanup tag
  my $text = replaceSpecialChars($node->prettyString);                          # Replace xml chars with symbols
  $node->replaceWithText($id ?
    qq(<required-cleanup id="$id">$text</required-cleanup>) :
    qq(<required-cleanup>$text</required-cleanup>));
  $node
 }

sub replaceWithRequiredCleanUp($$)                                              # Replace a node with a required cleanup message and return the new node
 {my ($node, $text) = @_;                                                       # Node to be replace, clean up message
  $node->replaceWithText(qq(<required-cleanup>$text</required-cleanup>));
 }

#1 Dita                                                                         # Methods useful for convertions to L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html>.

sub ditaListToSteps($@)                                                         #C Change the specified node to B<steps> and its contents to B<cmd\step> optionally only in the specified context.
 {my ($list, @context) = @_;                                                    # Node, optional context
  return undef if @context and !$list->at(@context);                            # Not in specified context
  for(@$list)                                                                   # Each li
   {$_->change(qw(  cmd))->wrapWith(q(step));                                   # li -> cmd\step
    $_->unwrap(qw(p cmd)) for @$_;                                              # Unwrap any contained p
   }
  $list->change(q(steps));
 }

sub ditaStepsToList($@)                                                         #C Change the specified node to B<ol> and its B<cmd\step> content to B<li> optionally only in the specified context.
 {my ($steps, @context) = @_;                                                   # Node, optional context
  return undef if @context and !$steps->at(@context);                           # Not in specified context
  for(@$steps)                                                                  # Content
   {$_->change(q(li));                                                          # Change content to li
    -W $_ for @$_;                                                              # Unwrap cmd
   }
  $steps->change(q(ol));
 }

sub ditaObviousChanges($)                                                       # Make obvious changes to a parse tree to make it look more like L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html>.
 {my ($node) = @_;                                                              # Node

  $node->by(sub                                                                 # Do the obvious conversions
   {my ($o) = @_;

    my %change =                                                                # Tags that should be changed
     (book         => q(bookmap),
      code         => q(codeph),
      emphasis     => q(b),
      figure       => q(fig),
      guibutton    => q(uicontrol),
      guilabel     => q(uicontrol),
      guimenu      => q(uicontrol),
      itemizedlist => q(ol),
      listitem     => q(li),
      menuchoice   => q(uicontrol),
      orderedlist  => q(ol),
      para         => q(p),
      replaceable  => q(varname),
      variablelist => q(dl),
      varlistentry => q(dlentry),
      command      => q(codeph),                                                # Needs approval from Micalea
     );

    my %deleteAttributesDependingOnValue =                                      # Attributes that should be deleted if they have specified values
     (b=>[[qw(role bold)], [qw(role underline)]],
     );

    my @deleteAttributesUnconditionally =                                       # Attributes that should be deleted unconditionally from all tags that have them
     qw(version xml:id xmlns xmlns:xi xmlns:xl xmlns:d);

    my %renameAttributes =                                                      # Attributes that should be renamed
     (xref=>[[qw(linkend href)]],
      fig =>[[qw(role outputclass)], [qw(xml:id id)]],
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

sub ditaTopicHeaders($)                                                         # Add xml headers for the dita document type indicated by the specified parse tree
 {my ($node) = @_;                                                              # Node in parse tree
  my $parse = $node->parser;
  my ($n, $N) = topicTypeAndBody($parse->tag);
  <<END
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE $n PUBLIC "-//OASIS//DTD DITA $N//EN" "$n.dtd" []>
END
 }

sub htmlHeadersToSections($)                                                    # Position sections just before html header tags so that subsequently the document can be divided into L<divided into sections|/divideIntoSections>.
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

sub divideDocumentIntoSections($$)                                              # Divide a parse tree into sections by moving non B<section> tags into their corresponding B<section> so that the B<section> tags expand until they are contiguous. The sections are then cut out by applying the specified sub to each B<section> tag in the parse tree. The specified sub will receive the containing B<topicref> and the B<section> to be cut out as parameters allowing a reference to the cut out section to be inserted into the B<topicref>.
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

#1 Debug                                                                        # Debugging methods

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

sub goFish($@)                                                                  # A debug version of L<go|/go> that returns additional information explaining any failure to reach the node identified by the L<path|/path>.\mReturns ([B<reachable tag>...], [B<possible tag>...]) where:\m=over\m=item B<reachable tag>\mthe path elements successfully traversed;\m=item B<possible tag>\mthe possibilities at the point where the path failed if it failed else B<undef>.\m=back
 {my ($node, @path) = @_;                                                       # Node, search specification.
  my $p = $node;                                                                # Current node
  my @p;                                                                        # Elements of the path successfully processed
  while(@path)                                                                  # Position specification
   {my $i = shift @path;                                                        # Index name
    return ([@p], [sort keys %{$p->indexes}]) unless $p;                        # There is no node of the named type under this node
    reindexNode($p);                                                            # Create index for this node
    my $q = $p->indexes->{$i};                                                  # Index
    return ([@p], [sort keys %{$p->indexes}]) unless defined $q;                # Complain if no such index
    push @p, $i;
    if (@path)                                                                  # Position within index
     {if ($path[0] =~ /\A([-+]?\d+)\Z/)                                         # Numeric position in index from start
       {shift @path;
        $p = $q->[$1]
       }
      elsif (@path == 1 and $path[0] =~ /\A\*\Z/)                               # Final index wanted
       {return ($q, [@p]);
       }
      else {$p = $q->[0]}                                                       # Step into first sub node by default
     }
    else {$p = $q->[0]}                                                         # Step into first sub node by default on last step
   }
  ([@p], undef)                                                                 # Success!
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

  $a -> by(sub {$_ -> cut(qw(c b a))});

In B<operator> style:

  $a x= sub{--$_ if $_ <= [qw(c b a)]};

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

  $a->change(q(ul))->by(sub                                                     # Change to <ul> and then traverse parse tree
   {$_->up->change(q(li)) if $_->text(q(p)) and $_->text =~ s/\A•\s*//s         # Remove leading bullets from text and change <p> to <li>
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

Confirm that the node has the specified L<ancestry|/ancestry> and return the starting node if it does else B<undef>. Ancestry is specified by providing the expected tags that the parent, the parent's parent etc. must match at each level. If B<undef> is specified then any tag is assumed to match at that level. If a regular expression is specified then the current parent node tag must match the regular expression at that level. If all supplied tags match successfully then the starting node is returned else B<undef>

L<attr|/attr>

Return the value of an attribute of the current node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

L<by|/by>

Post-order traversal of a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. A reference to the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>. This is equivalent to the L<x=|/opBy> operator.

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


  my $a = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END

  ok -p $a eq <<END;
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


=head2 Parse tree attributes

Attributes of a node in a parse tree. For instance the attributes associated with an XML tag are held in the L<attributes|/attributes> attribute. It should not be necessary to use these attributes directly unless you are writing an extension to this module.  Otherwise you should probably use the methods documented in other sections to manipulate the parse tree as they offer a safer interface at a higher level.

=head3 content :lvalue

Content of command: the nodes immediately below this node in the order in which they appeared in the source text, see also L</Contents>.


=head3 numbers :lvalue

Nodes by number.


=head3 data :lvalue

A hash added to the node for use by the programmer during transformations. The data in this hash will not be printed by any of the L<printed|/Print> methods and so can be used to add data to the parse tree that will not be seen in any output xml produced from the parse tree.


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


=head3 numbering :lvalue

Last number used to number a node in this parse tree.


=head3 number :lvalue

Number of this node, see L<findByNumber|/findByNumber>.


=head3 parent :lvalue

Parent node of this node or undef if the parser root node. See also L</Traversal> and L</Navigation>. Consider as read only.


=head3 parser :lvalue

Parser details: the root node of a tree is the parse node for that tree. Consider as read only.


=head3 tag :lvalue

Tag name for this node, see also L</Traversal> and L</Navigation>. Consider as read only.


=head3 text :lvalue

Text of this node but only if it is a text node, i.e. the tag is cdata() <=> L</isText> is true.


=head2 Parse tree

Construct a parse tree from another parse tree

=head3 renew($@)

Returns a renewed copy of the parse tree, optionally checking that the starting node is in a specified context: use this method if you have added nodes via the L</"Put as text"> methods and wish to traverse their parse tree.

Returns the starting node of the new parse tree or B<undef> if the optional context constraint was supplied but not satisfied.

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

Return a clone of the parse tree optionally checking that the starting node is in a specified context: the parse tree is cloned without converting it to string and reparsing it so this method will not L<renew|/renew> any nodes added L<as text|/Put as text>.

Returns the starting node of the new parse tree or B<undef> if the optional context constraint was supplied but not satisfied.

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

  my $x = Data::Edit::Xml::new(<<END);
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

Return the first node if the two parse trees have identical representations via L<string>, else B<undef>.

     Parameter  Description
  1  $node1     Parse tree 1
  2  $node2     Parse tree 2.

Example:


  my $a = Data::Edit::Xml::new("<a> </a>");

  my $A = $a->clone;

  ok -s $A eq q(<a/>);

  ok $a->equals($A);


Use B<equalsX> to execute L<equals|/equals> but B<die> 'equals' instead of returning B<undef>

=head3 diff($$$)

Return () if the dense string representations of the two nodes are equal, else up to the first N (default 16) characters of the common prefix before the point of divergence and the remainder of the string representation of each node from the point of divergence. All <!-- ... --> comments are ignored during this comparison and all spans of whitespace are reduced to a single blank.

     Parameter  Description
  1  $first     First node
  2  $second    Second node
  3  $N         Maximum length of difference strings to return

Example:


  my $x = Data::Edit::Xml::new(<<END);
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


=head3 expandIncludes($)

Expand the includes mentioned in a parse tree: any tag that ends in B<include> is assumed to be an include directive.  The file to be included is named on the B<href> keyword.  If the file to be included is a relative file name, i.e. it does not begin with B</> then this file is made absolute relative to the file from which this parse tree was obtained.

     Parameter  Description
  1  $x         Parse tree

Example:


  my @files =

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

Print the parse tree.

=head3 string($)

Return a dense string representing a node of a parse tree and all the nodes below it. Or use L<-s|/opString> $node

     Parameter  Description
  1  $node      Start node.

Example:


  ok -p $a eq <<END;
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


  ok $x->stringReplacingIdsWithLabels eq '<a><b><c/></b></a>';

  $b->addLabels(1..4);

  $c->addLabels(5..8);

  ok $x->stringReplacingIdsWithLabels eq '<a><b id="1, 2, 3, 4"><c id="5, 6, 7, 8"/></b></a>';

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


  ok $x->stringReplacingIdsWithLabels eq '<a><b><c/></b></a>';

  my $b = $x->go(q(b));

  $b->addLabels(1..2);

  $b->addLabels(3..4);

  ok $x->stringReplacingIdsWithLabels eq '<a><b id="1, 2, 3, 4"><c/></b></a>';

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


  my $a = Data::Edit::Xml::new(<<END);
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

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  $b->addConditions(qw(bb BB));

  $c->addConditions(qw(cc CC));

  ok  $c->condition(q(cc));

  ok !$c->condition(q(dd));

  ok  $c->condition(q(cc), qw(c b a));


Use B<conditionX> to execute L<condition|/condition> but B<die> 'condition' instead of returning B<undef>

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


Use B<anyConditionX> to execute L<anyCondition|/anyCondition> but B<die> 'anyCondition' instead of returning B<undef>

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


Use B<allConditionsX> to execute L<allConditions|/allConditions> but B<die> 'allConditions' instead of returning B<undef>

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

=head3 audience :lvalue

Attribute B<audience> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 class :lvalue

Attribute B<class> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 guid :lvalue

Attribute B<guid> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 href :lvalue

Attribute B<href> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 id :lvalue

Attribute B<id> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


=head3 lang :lvalue

Attribute B<lang> for a node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.


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

=head3 attr($$)

Return the value of an attribute of the current node as an L<lvalue|http://perldoc.perl.org/perlsub.html#Lvalue-subroutines> B<sub>.

     Parameter   Description
  1  $node       Node in parse tree
  2  $attribute  Attribute name.

Example:


  my $x = Data::Edit::Xml::new(my $s = <<END);
  <a number="1"/>
  END

  ok $x->attr(qq(number)) == 1;

  $x->attr(qq(number))  = 2;

  ok $x->attr(qq(number)) == 2;

  ok -s $x eq '<a number="2"/>';


=head3 set($@)

Set the values of some attributes in a node and return the node. Identical in effect to L<setAttrs|/setAttrs>.

     Parameter  Description
  1  $node      Node in parse tree
  2  %values    (attribute name=>new value)*

Example:


  ok q(<a a="1" b="1" id="aa"/>) eq -s $a;

  $a->set(a=>11, b=>undef, c=>3, d=>4, e=>5);

  }


=head3 setAttr($@)

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

Return the number of attributes in the specified node, optionally ignoring the specified names from the count.

     Parameter  Description
  1  $node      Node in parse tree
  2  @exclude   Optional attribute names to exclude from the count.

Example:


  ok -s $x eq '<a first="1" number="2" second="2"/>';

  ok $x->attrCount == 3;

  ok $x->attrCount(qw(first second third)) == 1;


=head3 getAttrs($)

Return a sorted list of all the attributes on this node.

     Parameter  Description
  1  $node      Node in parse tree.

Example:


  ok -s $x eq '<a first="1" number="2" second="2"/>';

  is_deeply [$x->getAttrs], [qw(first number second)];


=head3 deleteAttr($$$)

Delete the named attribute in the specified node, optionally check its value first, return the node regardless.

     Parameter  Description
  1  $node      Node
  2  $attr      Attribute name
  3  $value     Optional attribute value to check first.

Example:


  ok -s $x eq '<a delete="me" number="2"/>';

  $x->deleteAttr(qq(delete));

  ok -s $x eq '<a number="2"/>';


=head3 deleteAttrs($@)

Delete the specified attributes of the specified node without checking their values and return the node.

     Parameter  Description
  1  $node      Node
  2  @attrs     Names of the attributes to delete

Example:


  ok -s $x eq '<a first="1" number="2" second="2"/>';

  $x->deleteAttrs(qw(first second third number));

  ok -s $x eq '<a/>';


=head3 renameAttr($$$)

Change the name of an attribute in the specified node regardless of whether the new attribute already exists or not and return the node. To prevent inadvertent changes to an existing attribute use L<changeAttr|/changeAttr>.

     Parameter  Description
  1  $node      Node
  2  $old       Existing attribute name
  3  $new       New attribute name.

Example:


  ok $x->printAttributes eq qq( no="1" word="first");

  $x->renameAttr(qw(no number));

  ok $x->printAttributes eq qq( number="1" word="first");


=head3 changeAttr($$$)

Change the name of an attribute in the specified node unless it has already been set and return the node. To make changes regardless of whether the new attribute already exists use L<renameAttr|/renameAttr>.

     Parameter  Description
  1  $node      Node
  2  $old       Existing attribute name
  3  $new       New attribute name.

Example:


  ok $x->printAttributes eq qq( number="1" word="first");

  $x->changeAttr(qw(number word));

  ok $x->printAttributes eq qq( number="1" word="first");


=head3 renameAttrValue($$$$$)

Change the name and value of an attribute in the specified node regardless of whether the new attribute already exists or not and return the node. To prevent inadvertent changes to existing attributes use L<changeAttrValue|/changeAttrValue>.

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

Change the name and value of an attribute in the specified node unless it has already been set and return the node.  To make changes regardless of whether the new attribute already exists use L<renameAttrValue|/renameAttrValue>.

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


=head3 copyAttrs($$@)

Copy all the attributes of the source node to the target node, or, just the named attributes if the optional list of attributes to copy is supplied, overwriting any existing attributes in the target node and return the source node.

     Parameter  Description
  1  $source    Source node
  2  $target    Target node
  3  @attr      Optional list of attributes to copy

Example:


  my $x = Data::Edit::Xml::new(<<END);
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


  my $x = Data::Edit::Xml::new(<<END);
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


  my $x = Data::Edit::Xml::new(<<END);
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


  my $x = Data::Edit::Xml::new(<<END);
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

Traverse the parse tree in various orders applying a B<sub> to each node.

=head2 Post-order

This order allows you to edit children before their parents.

=head3 by($$@)

Post-order traversal of a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. A reference to the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>. This is equivalent to the L<x=|/opBy> operator.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context.

Example:


  ok -p $a eq <<END;
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END

  my $s; $a->by(sub{$s .= $_->tag}); ok $s eq "cbeda"


=head3 byX($$)

Post-order traversal of a parse tree calling the specified B<sub> at each node as long as this sub does not L<die|http://perldoc.perl.org/functions/die.html>. The traversal is halted if the called sub does  L<die|http://perldoc.perl.org/functions/die.html> on any call with the reason in L<?@|http://perldoc.perl.org/perlvar.html#Error-Variables> The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry> up to the node on which this sub was called. A reference to the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

Returns the start node regardless of the outcome of calling B<sub>.

     Parameter  Description
  1  $node      Start node
  2  $sub       Sub to call

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  ok -p $a eq <<END;
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END

  my $s; $a->byX(sub{$s .= $_->tag}); ok $s eq "cbeda"


=head3 byList($@)

Return a list of all the nodes at and below a node in preorder or the empty list if the node is not in the optional context.

     Parameter  Description
  1  $node      Starting node
  2  @context   Optional context

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $a = Data::Edit::Xml::new(<<END);
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

Reverse post-order traversal of a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context.

Example:


  ok -p $a eq <<END;
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END

  my $s; $a->byReverse(sub{$s .= $_->tag}); ok $s eq "edcba"


=head3 byReverseX($$@)

Reverse post-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context.

Example:


  ok -p $a eq <<END;
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END

  my $s; $a->byReverse(sub{$s .= $_->tag}); ok $s eq "edcba"


=head3 byReverseList($@)

Return a list of all the nodes at and below a node in reverse preorder or the empty list if the node is not in the optional context.

     Parameter  Description
  1  $node      Starting node
  2  @context   Optional context

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $a = Data::Edit::Xml::new(<<END);
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

Pre-order traversal down through a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context.

Example:


  my $s; $a->down(sub{$s .= $_->tag}); ok $s eq "abcde"


=head3 downX($$)

Pre-order traversal of a parse tree calling the specified B<sub> at each node as long as this sub does not L<die|http://perldoc.perl.org/functions/die.html>. The traversal is halted if the called sub does  L<die|http://perldoc.perl.org/functions/die.html> on any call with the reason in L<?@|http://perldoc.perl.org/perlvar.html#Error-Variables> The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry> up to the node on which this sub was called. A reference to the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

Returns the start node regardless of the outcome of calling B<sub>.

     Parameter  Description
  1  $node      Start node
  2  $sub       Sub to call

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $s; $a->down(sub{$s .= $_->tag}); ok $s eq "abcde"


=head3 downReverse($$@)

Reverse pre-order traversal down through a parse tree or sub tree calling the specified B<sub> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context.

Example:


  ok -p $a eq <<END;
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END

  my $s; $a->downReverse(sub{$s .= $_->tag}); ok $s eq "adebc"


=head3 downReverseX($$@)

Reverse pre-order traversal down through a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context.

Example:


  ok -p $a eq <<END;
  <a>
    <b>
      <c id="42" match="mm"/>
    </b>
    <d>
      <e/>
    </d>
  </a>
  END

  my $s; $a->downReverse(sub{$s .= $_->tag}); ok $s eq "adebc"


=head2 Pre and Post order

Visit the parent first, then the children, then the parent again.

=head3 through($$$@)

Traverse parse tree visiting each node twice calling the specified B<sub> at each node and returning the specified starting node. The B<sub>s are passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $before    Sub to call when we meet a node
  3  $after     Sub to call we leave a node
  4  @context   Accumulated context.

Example:


  my $s; my $n = sub{$s .= $_->tag}; $a->through($n, $n);

  ok $s eq "abccbdeeda"


=head3 throughX($$$@)

Traverse parse tree visiting each node twice calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $before    Sub to call when we meet a node
  3  $after     Sub to call we leave a node
  4  @context   Accumulated context.

Example:


  my $s; my $n = sub{$s .= $_->tag}; $a->through($n, $n);

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


  ok -p $a eq <<END;
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


  ok -p $a eq <<END;
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


  ok -p $a eq <<END;
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


Use B<isLastX> to execute L<isLast|/isLast> but B<die> 'isLast' instead of returning B<undef>

=head2 isOnlyChild($@)

Return the specified node if it is the only node under its parent ignoring any surrounding blank text.

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

=head2 singleChild($@)

Return the only child of a specified node if the child is the only node under its parent ignoring any surrounding blank text, esle return B<undef>.

     Parameter  Description
  1  $parent    Node
  2  @context   Optional context

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a>
    <b   id="b" b="bb">
      <b id="c" c="cc"/>
    </b>
  </a>
  END

  my ($c, $b) = $a->byList;

  is_deeply [$b->id, $c->id], [qw(b c)];

  ok $c == $b->singleChild;

  ok $b == $a->singleChild;


Use B<singleChildX> to execute L<singleChild|/singleChild> but B<die> 'singleChild' instead of returning B<undef>

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

Confirm that the string representing the tags at the level below this node match a regular expression where each pair of tags is separated by a single space. Use L<contentAsTags|/contentAsTags> to visualize the tags at the next level.

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

Confirm that the string representing the tags at the level below this node match a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a space and the last tag is followed by a space.  This arrangement simplifies the regular expression used to detect combinations like p+ q? . Use L<contentAsTags2|/contentAsTags2> to visualize the tags at the next level.

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

Confirm that the string representing the tags following this node matches a regular expression where each pair of tags is separated by a single space. Use L<contentAfterAsTags|/contentAfterAsTags> to visualize these tags.

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

Confirm that the string representing the tags following this node matches a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a space and the last tag is followed by a space.  This arrangement simplifies the regular expression used to detect combinations like p+ q? Use L<contentAfterAsTags2|/contentAfterAsTags2> to visualize these tags.

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

Confirm that the string representing the tags preceding this node matches a regular expression where each pair of tags is separated by a single space. Use L<contentBeforeAsTags|/contentBeforeAsTags> to visualize these tags.

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

Confirm that the string representing the tags preceding this node matches a regular expression where each pair of tags have two spaces between them and the first tag is preceded by a space and the last tag is followed by a space.  This arrangement simplifies the regular expression used to detect combinations like p+ q?  Use L<contentBeforeAsTags2|/contentBeforeAsTags2> to visualize these tags.

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
  2  @path      Search specification.

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

Return an array of all the nodes with the specified tag below the specified node. This method is deprecated in favor of applying L<grep|https://perldoc.perl.org/functions/grep.html> to L<contents|/contents>.

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

=head3 firstOf($@)

Return an array of the nodes that are continuously first under their specified parent node and that match the specified list of tags.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags to search for.

Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a><b><c/><d/><d/><e/><d/><d/><c/></b></a>
  END

  is_deeply [qw(c d d)], [map {-t $_} $a->go(q(b))->firstOf(qw(c d))];


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

=head3 firstSibling($@)

Return the first sibling of the specified node in the optional context else B<undef>

     Parameter  Description
  1  $node      Node
  2  @context   Array of tags specifying context.

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



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

  ok  $a->go(qw(b b))->firstSibling->id == 13;


Use B<firstSiblingX> to execute L<firstSibling|/firstSibling> but B<die> 'firstSibling' instead of returning B<undef>

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

Return the last  node matching one of the named tags under the specified node.

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

=head3 lastOf($@)

Return an array of the nodes that are continuously last under their specified parent node and that match the specified list of tags.

     Parameter  Description
  1  $node      Node
  2  @tags      Tags to search for.

Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a><b><c/><d/><d/><e/><d/><d/><c/></b></a>
  END

  is_deeply [qw(d d c)], [map {-t $_} $a->go(q(b))->lastOf (qw(c d))];


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

=head3 lastSibling($@)

Return the last sibling of the specified node in the optional context else B<undef>

     Parameter  Description
  1  $node      Node
  2  @context   Array of tags specifying context.

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



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

  ok  $a->go(qw(b b))->lastSibling ->id == 22;


Use B<lastSiblingX> to execute L<lastSibling|/lastSibling> but B<die> 'lastSibling' instead of returning B<undef>

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

Return the nearest sibling after the specified node that matches one of the named tags or B<undef> if there is no such sibling node.

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

  ok $e->id == 5;

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

Return the nearest sibling node before the specified node which matches one of the named tags or B<undef> if there is no such sibling node.

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


=head2 Up

Methods for moving up the parse tree from a node.

=head3 up($@)

Return the parent of the current node optionally checking the context of the specified node first or return B<undef> if the specified node is the root of the parse tree.

     Parameter  Description
  1  $node      Start node
  2  @tags      Optional tags identifying context.

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


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

  ok  $a->findByNumber(8)->up(qw(c b b))   ->number == 7;


Use B<upX> to execute L<up|/up> but B<die> 'up' instead of returning B<undef>

=head3 upWhile($$)

Move up starting from the specified node as long as the tag of each node matches the specified regular expression.  Return the last matching node if there is one else B<undef>.

     Parameter  Description
  1  $node      Start node
  2  $re        Tags identifying context.

Example:


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

  ok  $a->findByNumber(7)->upWhile(qr(a|b))->number == 4;

  ok !$a->findByNumber(8)->upWhile(qr(a|b));

  ok  $a->findByNumber(8)->upWhile(qr(b|c))->number == 2;


Use B<upWhileX> to execute L<upWhile|/upWhile> but B<die> 'upWhile' instead of returning B<undef>

=head3 upTo($@)

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

  ok  $a->findByNumber(8)->upTo(qw(b c))   ->number == 4;


Use B<upToX> to execute L<upTo|/upTo> but B<die> 'upTo' instead of returning B<undef>

=head1 Editing

Edit the data in the parse tree and change the structure of the parse tree by L<wrapping and unwrapping|/Wrap and unwrap> nodes, by L<replacing|/Replace> nodes, by L<cutting and pasting|/Cut and Put> nodes, by L<concatenating|/Fusion> nodes, by L<splitting|/Fission> nodes, by adding new L<text|/Put as text> nodes or L<swapping|/swap> nodes.

=head2 change($$@)

Change the name of a node, optionally  confirming that the node is in a specified context and return the node.

     Parameter  Description
  1  $node      Node
  2  $name      New name
  3  @context   Optional context.

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


=head3 mergeDuplicateChildWithParent($@)

Merge a parent node with its only child if their tags are the same and their attributes do not collide other than possibly the id in which case the parent id is used. Any labels on the child are transferrred to the parent. The child node is then unwrapped and the parent node is returned.

     Parameter  Description
  1  $parent    Parent this node
  2  @context   Optional context.

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a>
    <b   id="b" b="bb">
      <b id="c" c="cc"/>
    </b>
  </a>
  END

  my ($c, $b) = $a->byList;

  is_deeply [$b->id, $c->id], [qw(b c)];

  ok $c == $b->singleChild;

  $b->mergeDuplicateChildWithParent;

  ok -p $a eq <<END;
  <a>
    <b b="bb" c="cc" id="b"/>
  </a>
  END

  ok $b == $a->singleChild;


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

Replace a node (and all its content) with a L<new node|/newTag> (and all its content) and return the new node. If the node to be replaced is the root of the parse tree then no action is taken other then returning the new node.

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


=head3 replaceContentWithMovedContent($@)

Replace the content of a specified target node with the contents of the specified source nodes removing the content from each source node and return the target node.

     Parameter  Description
  1  $node      Target node
  2  @nodes     Source nodes

Example:


  my $a = Data::Edit::Xml::new(<<END);
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

  my $a = Data::Edit::Xml::new(<<END);
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


=head2 Swap

Swap nodes both singly and in blocks

=head3 swap($$@)

Swap two nodes optionally checking that the first node is in the specified context and return the first node.

     Parameter  Description
  1  $first     First node
  2  $second    Second node
  3  @context   Optional context

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



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


Use B<swapX> to execute L<swap|/swap> but B<die> 'swap' instead of returning B<undef>

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

Wrap the content of a node in a new node: the original node then contains just the new node which, in turn, contains all the content of the original node.

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


=head3 wrapTo($$$@)

Wrap all the nodes from the start node to the end node with a new node with the specified tag and attributes and return the new node.  Return B<undef> if the start and end nodes are not siblings - they must have the same parent for this method to work.

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


Use B<wrapToX> to execute L<wrapTo|/wrapTo> but B<die> 'wrapTo' instead of returning B<undef>

=head3 wrapFrom($$$@)

Wrap all the nodes from the start node to the end node with a new node with the specified tag and attributes and return the new node.  Return B<undef> if the start and end nodes are not siblings - they must have the same parent for this method to work.

     Parameter  Description
  1  $end       End node
  2  $start     Start node
  3  $tag       Tag for the wrapping node
  4  @attr      Attributes for the wrapping node

Example:


  my $a = Data::Edit::Xml::new(my $s = <<END);
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


Use B<wrapFromX> to execute L<wrapFrom|/wrapFrom> but B<die> 'wrapFrom' instead of returning B<undef>

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

=head3 unwrapParentsWithSingleChild($)

Unwrap any immediate ancestors of the specified node which have only a single child and return the specified node regardless.

     Parameter  Description
  1  $o         Node

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $a = Data::Edit::Xml::new(<<END);
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


Use B<unwrapParentsWithSingleChildX> to execute L<unwrapParentsWithSingleChild|/unwrapParentsWithSingleChild> but B<die> 'unwrapParentsWithSingleChild' instead of returning B<undef>

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

Return a string containing the tags of all the child nodes of this node separated by single spaces or the empty string if the node is empty or undef if the node does not match the optional context. Use L<over|/over> to test the sequence of tags with a regular expression.

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

Return a string containing the tags of all the child nodes of this node separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or undef if the node does not match the optional context. Use L<over2|/over2> to test the sequence of tags with a regular expression. Use L<over2|/over2> to test the sequence of tags with a regular expression.

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

Return a string containing the tags of all the sibling nodes following this node separated by single spaces or the empty string if the node is empty or undef if the node does not match the optional context. Use L<matchAfter|/matchAfter> to test the sequence of tags with a regular expression.

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

Return a string containing the tags of all the sibling nodes following this node separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or undef if the node does not match the optional context. Use L<matchAfter2|/matchAfter2> to test the sequence of tags with a regular expression.

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

Return a string containing the tags of all the sibling nodes preceding this node separated by single spaces or the empty string if the node is empty or undef if the node does not match the optional context. Use L<matchBefore|/matchBefore> to test the sequence of tags with a regular expression.

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

Return a string containing the tags of all the sibling nodes preceding this node separated by two spaces with a single space preceding the first tag and a single space following the last tag or the empty string if the node is empty or undef if the node does not match the optional context.  Use L<matchBefore2|/matchBefore2> to test the sequence of tags with a regular expression.

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

=head2 isFirstText($@)

Return the specified node if this node is a text node, the first node under its parent and that the parent is optionally in the specified context, else return B<undef>.

     Parameter  Description
  1  $node      Node to test
  2  @context   Optional context for parent

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
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


Use B<isFirstTextX> to execute L<isFirstText|/isFirstText> but B<die> 'isFirstText' instead of returning B<undef>

=head2 isLastText($@)

Return the specified node if this node is a text node, the last node under its parent and that the parent is optionally in the specified context, else return B<undef>.

     Parameter  Description
  1  $node      Node to test
  2  @context   Optional context for parent

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



Example:


  my $x = Data::Edit::Xml::new(<<END);
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


Use B<isLastTextX> to execute L<isLastText|/isLastText> but B<die> 'isLastText' instead of returning B<undef>

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


=head2 above($$@)

Return the first node if the first node is above the second node optionally checking that the first node is in the specified context otherwise return B<undef>

     Parameter  Description
  1  $first     First node
  2  $second    Second node
  3  @context   Optional context

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



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

=head2 below($$@)

Return the first node if the first node is below the second node optionally checking that the first node is in the specified context otherwise return B<undef>

     Parameter  Description
  1  $first     First node
  2  $second    Second node
  3  @context   Optional context

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



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

=head2 after($$@)

Return the first node if it occurs after the second node in the parse tree optionally checking that the first node is in the specified context or else B<undef> if the node is L<above|/above>, L<below|/below> or L<before|/before> the target.

     Parameter  Description
  1  $first     First node
  2  $second    Second node
  3  @context   Optional context

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



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

=head2 before($$@)

Return the first node if it occurs before the second node in the parse tree optionally checking that the first node is in the specified context or else B<undef> if the node is L<above|/above>, L<below|/below> or L<before|/before> the target.

     Parameter  Description
  1  $first     First node
  2  $second    Second node
  3  @context   Optional context

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



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

Delete the specified labels in the specified node or all labels if no labels have are specified and return that node.

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


=head1 Operators

Operator access to methods use the assign versions to avoid 'useless use of operator in void context' messages. Use the non assign versions to return the results of the underlying method call.  Thus '/' returns the wrapping node, whilst '/=' does not.  Assign operators always return their left hand side even though the corresponding method usually returns the modification on the right.

=head2 opString($$)

-B: L<bitsNodeTextBlank|/bitsNodeTextBlank>

-b: L<isAllBlankText|/isAllBlankText>

-c: L<context|/context>

-e: L<prettyStringEnd|/prettyStringEnd>

-f: L<first node|/first>

-g: L<getAttr|/getAttr>

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

-X: L<cut|/cut>

-z: L<prettyStringNumbered|/prettyStringNumbered>. Dangerous operations which might destroy information are in upper case.

     Parameter  Description
  1  $node      Node
  2  $op        Monadic operator.

Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a>
    <b><c>ccc</c></b>
    <d><e>eee</e></d>
  </a>
  END

  my $a = Data::Edit::Xml::new(<<END);
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

  ok -p $a eq <<END;
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


=head2 changeReasonCommentSelectionSpecification()

Provide a specification to select L<change reason comments|/crc> to be inserted as text into a parse tree. A specification can be either:

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

Insert a comment consisting of a code and an optional reason as text into the parse tree to indicate the location of changes to the parse tree.  As such comments tend to become very numerous, only comments whose codes matches the specification provided in L<changeReasonCommentSelectionSpecification|/changeReasonCommentSelectionSpecification> are accepted for insertion. Subsequently these comments can be easily located using:

B<grep -nr "<!-->I<code>B<">

on the file containing a printed version of the parse tree. Please note that these comments will be removed if the output file is reparsed.

Returns the specified node.

     Parameter  Description
  1  $node      Node being changed
  2  $code      Reason code
  3  $reason    Optional text description of change

Example:


  my $a = Data::Edit::Xml::new("<a><b/></a>");

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


=head2 requiredCleanUp($$)

Replace a node with a required cleanup node around the text of the replaced node with special characters replaced by symbols.

Returns the specified node.

     Parameter  Description
  1  $node      Node
  2  $id        Optional id of required cleanup tag

Example:


  my $a = Data::Edit::Xml::new(<<END);
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
  <a><required-cleanup id="33">&lt;b&gt;
    &lt;c&gt;
        ccc
      &lt;/c&gt;
  &lt;/b&gt;
  </required-cleanup></a>
  END


=head2 replaceWithRequiredCleanUp($$)

Replace a node with a required cleanup message and return the new node

     Parameter  Description
  1  $node      Node to be replace
  2  $text      Clean up message

Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a>
    <b/>
  </a>
  END

  my ($b) = $a->contents;

  $b->replaceWithRequiredCleanUp(q(bb));

  ok -p $a eq <<END;
  <a><required-cleanup>bb</required-cleanup></a>
  END


=head1 Dita

Methods useful for convertions to L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html>.

=head2 ditaListToSteps($@)

Change the specified node to B<steps> and its contents to B<cmd\step> optionally only in the specified context.

     Parameter  Description
  1  $list      Node
  2  @context   Optional context

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



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


=head2 ditaStepsToList($@)

Change the specified node to B<ol> and its B<cmd\step> content to B<li> optionally only in the specified context.

     Parameter  Description
  1  $steps     Node
  2  @context   Optional context

Use the B<@context> parameter to provide an optional context for this method as
understood by method L<at|/at> .  If a context is supplied and the node
specified by the first parameter is not in this context then this method
returns B<undef> immediately.



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


=head2 ditaObviousChanges($)

Make obvious changes to a parse tree to make it look more like L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html>.

     Parameter  Description
  1  $node      Node

Example:


  my $a = Data::Edit::Xml::new(<<END);
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


=head2 ditaTopicHeaders($)

Add xml headers for the dita document type indicated by the specified parse tree

     Parameter  Description
  1  $node      Node in parse tree

Example:


  ok Data::Edit::Xml::new(q(<concept/>))->ditaTopicHeaders eq <<END;
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd" []>
  END


=head2 htmlHeadersToSections($)

Position sections just before html header tags so that subsequently the document can be divided into L<divided into sections|/divideIntoSections>.

     Parameter  Description
  1  $node      Parse tree

Example:


  my $x = Data::Edit::Xml::new(<<END);
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

  my ($topicref, $section) = @_;

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

  "0" => "<section level=\"1\">N  <h1>h1</h1>NN  H1NN</section>N",

  "1" => "<section level=\"2\">N  <h2>h2</h2>NN  H2NN</section>N",

  "2" => "<section level=\"3\">N  <h3>h3</h3>NN  H3NN</section>N",

  "3" => "<section level=\"3\">N  <h3>h3</h3>NN  H3NN</section>N",

  "4" => "<section level=\"2\">N  <h2>h2</h2>NN  H2NN</section>N",

  "5" => "<section level=\"4\">N  <h4>h4</h4>NN  H4NN</section>N",


=head2 divideDocumentIntoSections($$)

Divide a parse tree into sections by moving non B<section> tags into their corresponding B<section> so that the B<section> tags expand until they are contiguous. The sections are then cut out by applying the specified sub to each B<section> tag in the parse tree. The specified sub will receive the containing B<topicref> and the B<section> to be cut out as parameters allowing a reference to the cut out section to be inserted into the B<topicref>.

     Parameter  Description
  1  $node      Parse tree
  2  $cutSub    Cut out sub

Example:


  $x->htmlHeadersToSections;

  $x->divideDocumentIntoSections(sub

  my ($topicref, $section) = @_;

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

  "0" => "<section level=\"1\">N  <h1>h1</h1>NN  H1NN</section>N",

  "1" => "<section level=\"2\">N  <h2>h2</h2>NN  H2NN</section>N",

  "2" => "<section level=\"3\">N  <h3>h3</h3>NN  H3NN</section>N",

  "3" => "<section level=\"3\">N  <h3>h3</h3>NN  H3NN</section>N",

  "4" => "<section level=\"2\">N  <h2>h2</h2>NN  H2NN</section>N",

  "5" => "<section level=\"4\">N  <h4>h4</h4>NN  H4NN</section>N",


=head1 Debug

Debugging methods

=head2 printAttributes($)

Print the attributes of a node.

     Parameter  Description
  1  $node      Node whose attributes are to be printed.

Example:


  my $x = Data::Edit::Xml::new(my $s = <<END);
  <a no="1" word="first"/>
  END

  ok $x->printAttributes eq qq( no="1" word="first");


=head2 printNode($)

Print the tag and attributes of a node.

     Parameter  Description
  1  $node      Node to be printed.

Example:


  my $a = Data::Edit::Xml::new(<<END);
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

Returns ([B<reachable tag>...], [B<possible tag>...]) where:

=over

=item B<reachable tag>

the path elements successfully traversed;

=item B<possible tag>

the possibilities at the point where the path failed if it failed else B<undef>.

=back

     Parameter  Description
  1  $node      Node
  2  @path      Search specification.

Example:


  my $a = Data::Edit::Xml::new(<<END);
  <a>
    <b>
      <c>
        <d/>
      </c>
    </b>
  </a>
  END

  my ($good, $possible) = $a->goFish(qw(b c D));

  is_deeply  $good,                 [qw(b c)];

  is_deeply  $possible,                  [q(d)];



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

Normalize whitespace, remove comments DOCTYPE and xml processors from a string

     Parameter  Description
  1  $string    String to normalize

=head2 prettyStringEnd($)

Return a readable string representing a node of a parse tree and all the nodes below it as a here document

     Parameter  Description
  1  $node      Start node

=head2 byX2($$@)

Post-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call
  3  @context   Accumulated context.

=head2 byX22($$@)

Post-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call
  3  @context   Accumulated context.

=head2 downX2($$@)

Pre-order traversal of a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call
  3  @context   Accumulated context.

=head2 downX22($$@)

Pre-order traversal down through a parse tree or sub tree calling the specified B<sub> within L<eval|http://perldoc.perl.org/functions/eval.html>B<{}> at each node and returning the specified starting node. The B<sub> is passed references to the current node and all of its L<ancestors|/ancestry>. The value of the current node is also made available via L<$_|http://perldoc.perl.org/perlvar.html#General-Variables>.

     Parameter  Description
  1  $node      Starting node
  2  $sub       Sub to call for each sub node
  3  @context   Accumulated context.

=head2 numberNode($)

Ensure that this node has a number.

     Parameter  Description
  1  $node      Node

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

2 L<aboveNonBlank|/above>

3 L<aboveNonBlankX|/above>

4 L<aboveX|/above>

5 L<addConditions|/addConditions>

6 L<addLabels|/addLabels>

7 L<after|/after>

8 L<afterNonBlank|/after>

9 L<afterNonBlankX|/after>

10 L<afterX|/after>

11 L<allConditions|/allConditions>

12 L<allConditionsX|/allConditions>

13 L<ancestry|/ancestry>

14 L<anyCondition|/anyCondition>

15 L<anyConditionX|/anyCondition>

16 L<at|/at>

17 L<atOrBelow|/atOrBelow>

18 L<atOrBelowX|/atOrBelow>

19 L<attr|/attr>

20 L<attrCount|/attrCount>

21 L<attributes|/attributes>

22 L<attrs|/attrs>

23 L<atX|/at>

24 L<audience|/audience>

25 L<before|/before>

26 L<beforeNonBlank|/before>

27 L<beforeNonBlankX|/before>

28 L<beforeX|/before>

29 L<below|/below>

30 L<belowNonBlank|/below>

31 L<belowNonBlankX|/below>

32 L<belowX|/below>

33 L<bitsNodeTextBlank|/bitsNodeTextBlank>

34 L<breakIn|/breakIn>

35 L<breakInBackwards|/breakInBackwards>

36 L<breakInBackwardsNonBlank|/breakInBackwards>

37 L<breakInBackwardsNonBlankX|/breakInBackwards>

38 L<breakInForwards|/breakInForwards>

39 L<breakInForwardsNonBlank|/breakInForwards>

40 L<breakInForwardsNonBlankX|/breakInForwards>

41 L<breakInNonBlank|/breakIn>

42 L<breakInNonBlankX|/breakIn>

43 L<breakOut|/breakOut>

44 L<by|/by>

45 L<byList|/byList>

46 L<byListNonBlank|/byList>

47 L<byListNonBlankX|/byList>

48 L<byReverse|/byReverse>

49 L<byReverseList|/byReverseList>

50 L<byReverseListNonBlank|/byReverseList>

51 L<byReverseListNonBlankX|/byReverseList>

52 L<byReverseX|/byReverseX>

53 L<byX|/byX>

54 L<byX2|/byX2>

55 L<byX22|/byX22>

56 L<byXNonBlank|/byX>

57 L<byXNonBlankX|/byX>

58 L<c|/c>

59 L<cdata|/cdata>

60 L<change|/change>

61 L<changeAttr|/changeAttr>

62 L<changeAttrValue|/changeAttrValue>

63 L<changeNonBlank|/change>

64 L<changeNonBlankX|/change>

65 L<changeReasonCommentSelectionSpecification|/changeReasonCommentSelectionSpecification>

66 L<changeX|/change>

67 L<checkParentage|/checkParentage>

68 L<checkParser|/checkParser>

69 L<class|/class>

70 L<clone|/clone>

71 L<cloneNonBlank|/clone>

72 L<cloneNonBlankX|/clone>

73 L<commonAncestor|/commonAncestor>

74 L<commonAncestorX|/commonAncestor>

75 L<concatenate|/concatenate>

76 L<concatenateNonBlank|/concatenate>

77 L<concatenateNonBlankX|/concatenate>

78 L<concatenateSiblings|/concatenateSiblings>

79 L<concatenateSiblingsNonBlank|/concatenateSiblings>

80 L<concatenateSiblingsNonBlankX|/concatenateSiblings>

81 L<condition|/condition>

82 L<conditionNonBlank|/condition>

83 L<conditionNonBlankX|/condition>

84 L<conditions|/conditions>

85 L<conditionX|/condition>

86 L<containsSingleText|/containsSingleText>

87 L<content|/content>

88 L<contentAfter|/contentAfter>

89 L<contentAfterAsTags|/contentAfterAsTags>

90 L<contentAfterAsTags2|/contentAfterAsTags2>

91 L<contentAfterAsTags2NonBlank|/contentAfterAsTags2>

92 L<contentAfterAsTags2NonBlankX|/contentAfterAsTags2>

93 L<contentAfterAsTagsNonBlank|/contentAfterAsTags>

94 L<contentAfterAsTagsNonBlankX|/contentAfterAsTags>

95 L<contentAfterNonBlank|/contentAfter>

96 L<contentAfterNonBlankX|/contentAfter>

97 L<contentAsTags|/contentAsTags>

98 L<contentAsTags2|/contentAsTags2>

99 L<contentAsTags2NonBlank|/contentAsTags2>

100 L<contentAsTags2NonBlankX|/contentAsTags2>

101 L<contentAsTags2X|/contentAsTags2>

102 L<contentAsTagsNonBlank|/contentAsTags>

103 L<contentAsTagsNonBlankX|/contentAsTags>

104 L<contentAsTagsX|/contentAsTags>

105 L<contentBefore|/contentBefore>

106 L<contentBeforeAsTags|/contentBeforeAsTags>

107 L<contentBeforeAsTags2|/contentBeforeAsTags2>

108 L<contentBeforeAsTags2NonBlank|/contentBeforeAsTags2>

109 L<contentBeforeAsTags2NonBlankX|/contentBeforeAsTags2>

110 L<contentBeforeAsTagsNonBlank|/contentBeforeAsTags>

111 L<contentBeforeAsTagsNonBlankX|/contentBeforeAsTags>

112 L<contentBeforeNonBlank|/contentBefore>

113 L<contentBeforeNonBlankX|/contentBefore>

114 L<contents|/contents>

115 L<contentsNonBlank|/contents>

116 L<contentsNonBlankX|/contents>

117 L<context|/context>

118 L<copyAttrs|/copyAttrs>

119 L<copyLabels|/copyLabels>

120 L<copyNewAttrs|/copyNewAttrs>

121 L<count|/count>

122 L<countAttrNames|/countAttrNames>

123 L<countAttrValues|/countAttrValues>

124 L<countLabels|/countLabels>

125 L<countOutputClasses|/countOutputClasses>

126 L<countTagNames|/countTagNames>

127 L<countTags|/countTags>

128 L<crc|/crc>

129 L<cut|/cut>

130 L<cutNonBlank|/cut>

131 L<cutNonBlankX|/cut>

132 L<data|/data>

133 L<deleteAttr|/deleteAttr>

134 L<deleteAttrs|/deleteAttrs>

135 L<deleteConditions|/deleteConditions>

136 L<deleteLabels|/deleteLabels>

137 L<depth|/depth>

138 L<diff|/diff>

139 L<disconnectLeafNode|/disconnectLeafNode>

140 L<disordered|/disordered>

141 L<ditaListToSteps|/ditaListToSteps>

142 L<ditaListToStepsNonBlank|/ditaListToSteps>

143 L<ditaListToStepsNonBlankX|/ditaListToSteps>

144 L<ditaObviousChanges|/ditaObviousChanges>

145 L<ditaStepsToList|/ditaStepsToList>

146 L<ditaStepsToListNonBlank|/ditaStepsToList>

147 L<ditaStepsToListNonBlankX|/ditaStepsToList>

148 L<ditaTopicHeaders|/ditaTopicHeaders>

149 L<divideDocumentIntoSections|/divideDocumentIntoSections>

150 L<down|/down>

151 L<downReverse|/downReverse>

152 L<downReverseX|/downReverseX>

153 L<downX|/downX>

154 L<downX2|/downX2>

155 L<downX22|/downX22>

156 L<downXNonBlank|/downX>

157 L<downXNonBlankX|/downX>

158 L<equals|/equals>

159 L<equalsX|/equals>

160 L<errorsFile|/errorsFile>

161 L<expandIncludes|/expandIncludes>

162 L<findByNumber|/findByNumber>

163 L<findByNumbers|/findByNumbers>

164 L<findByNumberX|/findByNumber>

165 L<first|/first>

166 L<firstBy|/firstBy>

167 L<firstContextOf|/firstContextOf>

168 L<firstContextOfX|/firstContextOf>

169 L<firstDown|/firstDown>

170 L<firstIn|/firstIn>

171 L<firstInIndex|/firstInIndex>

172 L<firstInIndexNonBlank|/firstInIndex>

173 L<firstInIndexNonBlankX|/firstInIndex>

174 L<firstInIndexX|/firstInIndex>

175 L<firstInX|/firstIn>

176 L<firstNonBlank|/first>

177 L<firstNonBlankX|/first>

178 L<firstOf|/firstOf>

179 L<firstSibling|/firstSibling>

180 L<firstSiblingNonBlank|/firstSibling>

181 L<firstSiblingNonBlankX|/firstSibling>

182 L<firstSiblingX|/firstSibling>

183 L<firstText|/firstText>

184 L<firstTextNonBlank|/firstText>

185 L<firstTextNonBlankX|/firstText>

186 L<firstTextX|/firstText>

187 L<firstX|/first>

188 L<from|/from>

189 L<fromTo|/fromTo>

190 L<getAttrs|/getAttrs>

191 L<getLabels|/getLabels>

192 L<getSectionHeadingLevel|/getSectionHeadingLevel>

193 L<go|/go>

194 L<goFish|/goFish>

195 L<goX|/go>

196 L<guid|/guid>

197 L<href|/href>

198 L<htmlHeadersToSections|/htmlHeadersToSections>

199 L<id|/id>

200 L<index|/index>

201 L<indexes|/indexes>

202 L<indexNode|/indexNode>

203 L<input|/input>

204 L<inputFile|/inputFile>

205 L<inputString|/inputString>

206 L<isAllBlankText|/isAllBlankText>

207 L<isAllBlankTextNonBlank|/isAllBlankText>

208 L<isAllBlankTextNonBlankX|/isAllBlankText>

209 L<isAllBlankTextX|/isAllBlankText>

210 L<isBlankText|/isBlankText>

211 L<isBlankTextNonBlank|/isBlankText>

212 L<isBlankTextNonBlankX|/isBlankText>

213 L<isBlankTextX|/isBlankText>

214 L<isEmpty|/isEmpty>

215 L<isEmptyNonBlank|/isEmpty>

216 L<isEmptyNonBlankX|/isEmpty>

217 L<isEmptyX|/isEmpty>

218 L<isFirst|/isFirst>

219 L<isFirstNonBlank|/isFirst>

220 L<isFirstNonBlankX|/isFirst>

221 L<isFirstText|/isFirstText>

222 L<isFirstTextNonBlank|/isFirstText>

223 L<isFirstTextNonBlankX|/isFirstText>

224 L<isFirstTextX|/isFirstText>

225 L<isFirstX|/isFirst>

226 L<isLast|/isLast>

227 L<isLastNonBlank|/isLast>

228 L<isLastNonBlankX|/isLast>

229 L<isLastText|/isLastText>

230 L<isLastTextNonBlank|/isLastText>

231 L<isLastTextNonBlankX|/isLastText>

232 L<isLastTextX|/isLastText>

233 L<isLastX|/isLast>

234 L<isOnlyChild|/isOnlyChild>

235 L<isOnlyChildNonBlank|/isOnlyChild>

236 L<isOnlyChildNonBlankX|/isOnlyChild>

237 L<isOnlyChildX|/isOnlyChild>

238 L<isText|/isText>

239 L<isTextNonBlank|/isText>

240 L<isTextNonBlankX|/isText>

241 L<isTextX|/isText>

242 L<labels|/labels>

243 L<lang|/lang>

244 L<last|/last>

245 L<lastBy|/lastBy>

246 L<lastContextOf|/lastContextOf>

247 L<lastContextOfX|/lastContextOf>

248 L<lastDown|/lastDown>

249 L<lastIn|/lastIn>

250 L<lastInIndex|/lastInIndex>

251 L<lastInIndexNonBlank|/lastInIndex>

252 L<lastInIndexNonBlankX|/lastInIndex>

253 L<lastInIndexX|/lastInIndex>

254 L<lastInX|/lastIn>

255 L<lastNonBlank|/last>

256 L<lastNonBlankX|/last>

257 L<lastOf|/lastOf>

258 L<lastSibling|/lastSibling>

259 L<lastSiblingNonBlank|/lastSibling>

260 L<lastSiblingNonBlankX|/lastSibling>

261 L<lastSiblingX|/lastSibling>

262 L<lastText|/lastText>

263 L<lastTextNonBlank|/lastText>

264 L<lastTextNonBlankX|/lastText>

265 L<lastTextX|/lastText>

266 L<lastX|/last>

267 L<listConditions|/listConditions>

268 L<matchAfter|/matchAfter>

269 L<matchAfter2|/matchAfter2>

270 L<matchAfter2NonBlank|/matchAfter2>

271 L<matchAfter2NonBlankX|/matchAfter2>

272 L<matchAfter2X|/matchAfter2>

273 L<matchAfterNonBlank|/matchAfter>

274 L<matchAfterNonBlankX|/matchAfter>

275 L<matchAfterX|/matchAfter>

276 L<matchBefore|/matchBefore>

277 L<matchBefore2|/matchBefore2>

278 L<matchBefore2NonBlank|/matchBefore2>

279 L<matchBefore2NonBlankX|/matchBefore2>

280 L<matchBefore2X|/matchBefore2>

281 L<matchBeforeNonBlank|/matchBefore>

282 L<matchBeforeNonBlankX|/matchBefore>

283 L<matchBeforeX|/matchBefore>

284 L<matchesText|/matchesText>

285 L<matchesTextNonBlank|/matchesText>

286 L<matchesTextNonBlankX|/matchesText>

287 L<matchesTextX|/matchesText>

288 L<mergeDuplicateChildWithParent|/mergeDuplicateChildWithParent>

289 L<mergeDuplicateChildWithParentNonBlank|/mergeDuplicateChildWithParent>

290 L<mergeDuplicateChildWithParentNonBlankX|/mergeDuplicateChildWithParent>

291 L<moveAttrs|/moveAttrs>

292 L<moveLabels|/moveLabels>

293 L<moveNewAttrs|/moveNewAttrs>

294 L<navtitle|/navtitle>

295 L<new|/new>

296 L<newTag|/newTag>

297 L<newText|/newText>

298 L<newTree|/newTree>

299 L<next|/next>

300 L<nextIn|/nextIn>

301 L<nextInX|/nextIn>

302 L<nextNonBlank|/next>

303 L<nextNonBlankX|/next>

304 L<nextOn|/nextOn>

305 L<nextText|/nextText>

306 L<nextTextNonBlank|/nextText>

307 L<nextTextNonBlankX|/nextText>

308 L<nextTextX|/nextText>

309 L<nextX|/next>

310 L<nn|/nn>

311 L<normalizeWhiteSpace|/normalizeWhiteSpace>

312 L<number|/number>

313 L<numbering|/numbering>

314 L<numberNode|/numberNode>

315 L<numbers|/numbers>

316 L<numberTree|/numberTree>

317 L<opString|/opString>

318 L<ordered|/ordered>

319 L<orderedX|/ordered>

320 L<otherprops|/otherprops>

321 L<outputclass|/outputclass>

322 L<over|/over>

323 L<over2|/over2>

324 L<over2NonBlank|/over2>

325 L<over2NonBlankX|/over2>

326 L<over2X|/over2>

327 L<overNonBlank|/over>

328 L<overNonBlankX|/over>

329 L<overX|/over>

330 L<parent|/parent>

331 L<parse|/parse>

332 L<parser|/parser>

333 L<path|/path>

334 L<pathString|/pathString>

335 L<position|/position>

336 L<present|/present>

337 L<prettyString|/prettyString>

338 L<prettyStringCDATA|/prettyStringCDATA>

339 L<prettyStringContent|/prettyStringContent>

340 L<prettyStringContentNumbered|/prettyStringContentNumbered>

341 L<prettyStringEnd|/prettyStringEnd>

342 L<prettyStringNumbered|/prettyStringNumbered>

343 L<prev|/prev>

344 L<prevIn|/prevIn>

345 L<prevInX|/prevIn>

346 L<prevNonBlank|/prev>

347 L<prevNonBlankX|/prev>

348 L<prevOn|/prevOn>

349 L<prevText|/prevText>

350 L<prevTextNonBlank|/prevText>

351 L<prevTextNonBlankX|/prevText>

352 L<prevTextX|/prevText>

353 L<prevX|/prev>

354 L<printAttributes|/printAttributes>

355 L<printAttributesReplacingIdsWithLabels|/printAttributesReplacingIdsWithLabels>

356 L<printNode|/printNode>

357 L<props|/props>

358 L<putFirst|/putFirst>

359 L<putFirstAsText|/putFirstAsText>

360 L<putFirstAsTextNonBlank|/putFirstAsText>

361 L<putFirstAsTextNonBlankX|/putFirstAsText>

362 L<putFirstNonBlank|/putFirst>

363 L<putFirstNonBlankX|/putFirst>

364 L<putLast|/putLast>

365 L<putLastAsText|/putLastAsText>

366 L<putLastAsTextNonBlank|/putLastAsText>

367 L<putLastAsTextNonBlankX|/putLastAsText>

368 L<putLastNonBlank|/putLast>

369 L<putLastNonBlankX|/putLast>

370 L<putNext|/putNext>

371 L<putNextAsText|/putNextAsText>

372 L<putNextAsTextNonBlank|/putNextAsText>

373 L<putNextAsTextNonBlankX|/putNextAsText>

374 L<putNextNonBlank|/putNext>

375 L<putNextNonBlankX|/putNext>

376 L<putPrev|/putPrev>

377 L<putPrevAsText|/putPrevAsText>

378 L<putPrevAsTextNonBlank|/putPrevAsText>

379 L<putPrevAsTextNonBlankX|/putPrevAsText>

380 L<putPrevNonBlank|/putPrev>

381 L<putPrevNonBlankX|/putPrev>

382 L<reindexNode|/reindexNode>

383 L<renameAttr|/renameAttr>

384 L<renameAttrValue|/renameAttrValue>

385 L<renew|/renew>

386 L<renewNonBlank|/renew>

387 L<renewNonBlankX|/renew>

388 L<replaceContentWith|/replaceContentWith>

389 L<replaceContentWithMovedContent|/replaceContentWithMovedContent>

390 L<replaceContentWithText|/replaceContentWithText>

391 L<replaceSpecialChars|/replaceSpecialChars>

392 L<replaceWith|/replaceWith>

393 L<replaceWithBlank|/replaceWithBlank>

394 L<replaceWithBlankNonBlank|/replaceWithBlank>

395 L<replaceWithBlankNonBlankX|/replaceWithBlank>

396 L<replaceWithNonBlank|/replaceWith>

397 L<replaceWithNonBlankX|/replaceWith>

398 L<replaceWithRequiredCleanUp|/replaceWithRequiredCleanUp>

399 L<replaceWithText|/replaceWithText>

400 L<replaceWithTextNonBlank|/replaceWithText>

401 L<replaceWithTextNonBlankX|/replaceWithText>

402 L<requiredCleanUp|/requiredCleanUp>

403 L<restore|/restore>

404 L<restoreX|/restore>

405 L<save|/save>

406 L<set|/set>

407 L<setAttr|/setAttr>

408 L<singleChild|/singleChild>

409 L<singleChildNonBlank|/singleChild>

410 L<singleChildNonBlankX|/singleChild>

411 L<singleChildX|/singleChild>

412 L<string|/string>

413 L<stringContent|/stringContent>

414 L<stringNode|/stringNode>

415 L<stringQuoted|/stringQuoted>

416 L<stringReplacingIdsWithLabels|/stringReplacingIdsWithLabels>

417 L<stringWithConditions|/stringWithConditions>

418 L<style|/style>

419 L<swap|/swap>

420 L<swapNonBlank|/swap>

421 L<swapNonBlankX|/swap>

422 L<swapX|/swap>

423 L<tag|/tag>

424 L<text|/text>

425 L<through|/through>

426 L<throughX|/throughX>

427 L<to|/to>

428 L<tocNumbers|/tocNumbers>

429 L<topicTypeAndBody|/topicTypeAndBody>

430 L<tree|/tree>

431 L<type|/type>

432 L<unwrap|/unwrap>

433 L<unwrapContentsKeepingText|/unwrapContentsKeepingText>

434 L<unwrapContentsKeepingTextNonBlank|/unwrapContentsKeepingText>

435 L<unwrapContentsKeepingTextNonBlankX|/unwrapContentsKeepingText>

436 L<unwrapContentsKeepingTextX|/unwrapContentsKeepingText>

437 L<unwrapNonBlank|/unwrap>

438 L<unwrapNonBlankX|/unwrap>

439 L<unwrapParentsWithSingleChild|/unwrapParentsWithSingleChild>

440 L<unwrapParentsWithSingleChildNonBlank|/unwrapParentsWithSingleChild>

441 L<unwrapParentsWithSingleChildNonBlankX|/unwrapParentsWithSingleChild>

442 L<unwrapParentsWithSingleChildX|/unwrapParentsWithSingleChild>

443 L<unwrapX|/unwrap>

444 L<up|/up>

445 L<upNonBlank|/up>

446 L<upNonBlankX|/up>

447 L<upTo|/upTo>

448 L<upToX|/upTo>

449 L<upWhile|/upWhile>

450 L<upWhileX|/upWhile>

451 L<upX|/up>

452 L<wrapContentWith|/wrapContentWith>

453 L<wrapDown|/wrapDown>

454 L<wrapFrom|/wrapFrom>

455 L<wrapFromX|/wrapFrom>

456 L<wrapTo|/wrapTo>

457 L<wrapToX|/wrapTo>

458 L<wrapUp|/wrapUp>

459 L<wrapWith|/wrapWith>

460 L<xmlHeader|/xmlHeader>

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


sub aboveX                         {&above                         (@_) || die 'above'}
sub afterX                         {&after                         (@_) || die 'after'}
sub allConditionsX                 {&allConditions                 (@_) || die 'allConditions'}
sub anyConditionX                  {&anyCondition                  (@_) || die 'anyCondition'}
sub atX                            {&at                            (@_) || die 'at'}
sub atOrBelowX                     {&atOrBelow                     (@_) || die 'atOrBelow'}
sub beforeX                        {&before                        (@_) || die 'before'}
sub belowX                         {&below                         (@_) || die 'below'}
sub changeX                        {&change                        (@_) || die 'change'}
sub commonAncestorX                {&commonAncestor                (@_) || die 'commonAncestor'}
sub conditionX                     {&condition                     (@_) || die 'condition'}
sub contentAsTagsX                 {&contentAsTags                 (@_) || die 'contentAsTags'}
sub contentAsTags2X                {&contentAsTags2                (@_) || die 'contentAsTags2'}
sub equalsX                        {&equals                        (@_) || die 'equals'}
sub findByNumberX                  {&findByNumber                  (@_) || die 'findByNumber'}
sub firstX                         {&first                         (@_) || die 'first'}
sub firstContextOfX                {&firstContextOf                (@_) || die 'firstContextOf'}
sub firstInX                       {&firstIn                       (@_) || die 'firstIn'}
sub firstInIndexX                  {&firstInIndex                  (@_) || die 'firstInIndex'}
sub firstSiblingX                  {&firstSibling                  (@_) || die 'firstSibling'}
sub firstTextX                     {&firstText                     (@_) || die 'firstText'}
sub goX                            {&go                            (@_) || die 'go'}
sub isAllBlankTextX                {&isAllBlankText                (@_) || die 'isAllBlankText'}
sub isBlankTextX                   {&isBlankText                   (@_) || die 'isBlankText'}
sub isEmptyX                       {&isEmpty                       (@_) || die 'isEmpty'}
sub isFirstX                       {&isFirst                       (@_) || die 'isFirst'}
sub isFirstTextX                   {&isFirstText                   (@_) || die 'isFirstText'}
sub isLastX                        {&isLast                        (@_) || die 'isLast'}
sub isLastTextX                    {&isLastText                    (@_) || die 'isLastText'}
sub isOnlyChildX                   {&isOnlyChild                   (@_) || die 'isOnlyChild'}
sub isTextX                        {&isText                        (@_) || die 'isText'}
sub lastX                          {&last                          (@_) || die 'last'}
sub lastContextOfX                 {&lastContextOf                 (@_) || die 'lastContextOf'}
sub lastInX                        {&lastIn                        (@_) || die 'lastIn'}
sub lastInIndexX                   {&lastInIndex                   (@_) || die 'lastInIndex'}
sub lastSiblingX                   {&lastSibling                   (@_) || die 'lastSibling'}
sub lastTextX                      {&lastText                      (@_) || die 'lastText'}
sub matchAfterX                    {&matchAfter                    (@_) || die 'matchAfter'}
sub matchAfter2X                   {&matchAfter2                   (@_) || die 'matchAfter2'}
sub matchBeforeX                   {&matchBefore                   (@_) || die 'matchBefore'}
sub matchBefore2X                  {&matchBefore2                  (@_) || die 'matchBefore2'}
sub matchesTextX                   {&matchesText                   (@_) || die 'matchesText'}
sub nextX                          {&next                          (@_) || die 'next'}
sub nextInX                        {&nextIn                        (@_) || die 'nextIn'}
sub nextTextX                      {&nextText                      (@_) || die 'nextText'}
sub orderedX                       {&ordered                       (@_) || die 'ordered'}
sub overX                          {&over                          (@_) || die 'over'}
sub over2X                         {&over2                         (@_) || die 'over2'}
sub prevX                          {&prev                          (@_) || die 'prev'}
sub prevInX                        {&prevIn                        (@_) || die 'prevIn'}
sub prevTextX                      {&prevText                      (@_) || die 'prevText'}
sub restoreX                       {&restore                       (@_) || die 'restore'}
sub singleChildX                   {&singleChild                   (@_) || die 'singleChild'}
sub swapX                          {&swap                          (@_) || die 'swap'}
sub unwrapX                        {&unwrap                        (@_) || die 'unwrap'}
sub unwrapContentsKeepingTextX     {&unwrapContentsKeepingText     (@_) || die 'unwrapContentsKeepingText'}
sub unwrapParentsWithSingleChildX  {&unwrapParentsWithSingleChild  (@_) || die 'unwrapParentsWithSingleChild'}
sub upX                            {&up                            (@_) || die 'up'}
sub upToX                          {&upTo                          (@_) || die 'upTo'}
sub upWhileX                       {&upWhile                       (@_) || die 'upWhile'}
sub wrapFromX                      {&wrapFrom                      (@_) || die 'wrapFrom'}
sub wrapToX                        {&wrapTo                        (@_) || die 'wrapTo'}

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
#Test::More->builder->output("/dev/null");                                       # Show only errors during testing - but this must be commented out for production
use warnings FATAL=>qw(all);
use strict;
use Test::More tests=>660;
use Data::Table::Text qw(:all);

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
  ok sample2->go(qw(b c))->replaceWith(sample2)->go(qw(b c))->upTo(qw(a b))->string eq '<a id="aa"><b id="bb"><c id="cc"/></b></a>';

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

if ($^O ne 'MSWin32')                                                           # Blank text
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
else                                                                            # Skip because absFromRel in expandIncl;udes does not work on Windows
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
    my $p = $c->upTo($tag);
    ok $p->id eq $id;
   }

  my $p = $c->upTo(q(d));
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

  $a->numberTree;                                                               #TupTo
  ok -z $a eq <<END;                                                            #Tup #TupTo #TupWhile
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

  ok  $a->findByNumber(8)->up(qw(c b b))   ->number == 7;                       #Tup
  ok  $a->findByNumber(7)->upWhile(qr(a|b))->number == 4;                       #TupWhile
  ok !$a->findByNumber(8)->upWhile(qr(a|b));                                    #TupWhile
  ok  $a->findByNumber(8)->upWhile(qr(b|c))->number == 2;                       #TupWhile
  ok  $a->findByNumber(8)->upTo(qw(b c))   ->number == 4;                       #TupTo #Tnumber
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

if (1)                                                                          # Bulleted list to <ul>
 {my $a = Data::Edit::Xml::new(<<END);
<a>
<p>• Minimum 1 number</p>
<p>•   No leading, trailing, or embedded spaces</p>
<p>• Not case-sensitive</p>
</a>
END

  $a->change(q(ul))->by(sub                                                     # Change to <ul> and then traverse parse tree
   {$_->up->change(q(li)) if $_->text(q(p)) and $_->text =~ s/\A•\s*//s         # Remove leading bullets from text and change <p> to <li>
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
<a><required-cleanup id="33">&lt;b&gt;
  &lt;c&gt;
      ccc
    &lt;/c&gt;
&lt;/b&gt;
</required-cleanup></a>
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
<a><required-cleanup>bb</required-cleanup></a>
END
 }

if (1)
 {my $a = Data::Edit::Xml::new(<<END);                                          #TgoFish
<a>
  <b>
    <c>
      <d/>
    </c>
  </b>
</a>
END
  if (1) {
    my ($good, $possible) = $a->goFish(qw(b c D));                              #TgoFish
    is_deeply  $good,                 [qw(b c)];                                #TgoFish
    is_deeply  $possible,                  [q(d)];                              #TgoFish
   }

  if (1)
   {my ($g, $p) = $a->goFish(qw(b c d));
    is_deeply $g, [qw(b c d)];
    ok !$p;
   }
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
 {my $a = Data::Edit::Xml::new(<<END);                                          #TmergeDuplicateChildWithParent #TsingleChild
<a>
  <b   id="b" b="bb">
    <b id="c" c="cc"/>
  </b>
</a>
END

  my ($c, $b) = $a->byList;                                                     #TmergeDuplicateChildWithParent #TsingleChild
  is_deeply [$b->id, $c->id], [qw(b c)];                                        #TmergeDuplicateChildWithParent #TsingleChild
  ok $c == $b->singleChild;                                                     #TmergeDuplicateChildWithParent #TsingleChild
  $b->mergeDuplicateChildWithParent;                                            #TmergeDuplicateChildWithParent
  ok -p $a eq <<END;                                                            #TmergeDuplicateChildWithParent
<a>
  <b b="bb" c="cc" id="b"/>
</a>
END
  ok $b == $a->singleChild;                                                     #TmergeDuplicateChildWithParent #TsingleChild
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
  ok -p $a eq <<END;                                                            #TditaStepsToList
<dita>
  <ol>
    <li>aaa</li>
    <li>bbb</li>
  </ol>
</dita>
END

  ok Data::Edit::Xml::new(q(<concept/>))->ditaTopicHeaders eq <<END;            #TditaTopicHeaders
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd" []>
END
 }

if (1)
 {my $x = Data::Edit::Xml::new(<<END);                                          #ThtmlHeadersToSections #TdivideIntoSections
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

