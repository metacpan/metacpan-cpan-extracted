# $Id: Cindy.pm 129 2014-09-24 12:07:07Z jo $
# Cindy - Content INjection 
#
# Copyright (c) 2008 Joachim Zobel <jz-2008@heute-morgen.de>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package Cindy;

use strict;
use warnings;

use base qw(Exporter);

our $VERSION = '0.22';

our @EXPORT= qw(get_html_doc get_xml_doc 
                parse_html_string parse_xml_string 
                parse_cis parse_cis_string
                inject dump_xpath_profile);

use XML::LibXML;
use Cindy::Sheet;
use Cindy::Log;
 
sub get_html_doc($)
{
  my ($file)  = @_;
  my $parser = XML::LibXML->new();

  return $parser->parse_html_file($file);
}

sub get_xml_doc($)
{
  my ($file)  = @_;
  my $parser = XML::LibXML->new();

  return $parser->parse_file($file);
}

sub omit_nodes {
  my ($doc, $tag) = @_; 

  my $found = $doc->find( "///$tag" );
  foreach my $node ($found->get_nodelist()) {
    my $parent = $node->parentNode;

    foreach my $child ($node->childNodes()) {
      $parent->insertBefore($child->cloneNode(1), $node);
    }
  
    $parent->removeChild($node);
  }
}

sub parse_html_string($;$)
{
  my ($string, $ropt)  = @_;
  $ropt ||= {};
  
  my $html_parse_noimplied = $ropt->{html_parse_noimplied}
                             || $ropt->{no_implied};

  my $dont_omit =  !$html_parse_noimplied 
               ||  ($string =~ /<html|<body/i);

  my $parser = XML::LibXML->new();

  my $doc = $parser->parse_html_string($string, $ropt);

  if (!$dont_omit) {
    # Until HTML_PARSE_NOIMPLIED is implemented by 
    # libxml2 (and passed by XML::LibXML) we need
    # to remove html/body tags that have been added to 
    # fragments.
    omit_nodes($doc, 'html');
    omit_nodes($doc, 'body');
  }
  return $doc;
}

sub parse_xml_string($)
{
  my $parser = XML::LibXML->new();

  return $parser->parse_string($_[0]);
}

sub parse_cis($)
{
  return Cindy::Sheet::parse_cis($_[0]);
}

sub parse_cis_string($)
{
  return Cindy::Sheet::parse_cis_string($_[0]);
}

#
# Get a copied doc. root for modification.
#
sub get_root_copy($)
{
  my ($doc)   = @_;
  my $root  = $doc->documentElement();
  my $rtn = $root->cloneNode( 1 );
  return $rtn;
}

sub dump_xpath_profile()
{
  Cindy::Injection::dump_profile();
}

sub inject($$$)
{
  my ($data, $doc, $descriptions) = @_;
  my $docroot = get_root_copy($doc);
#  my $dataroot = get_root_copy($data);
  my $dataroot = $data->getDocumentElement();
  # Create a root description with action none 
  # to hold the description list 
  my $descroot = Cindy::Injection->new(
      '.', 'none', '.', 'xpath', 
      sublist => $descriptions);
   
  # Connect the copied docroot with the output document.
  # This has to be done before the tree is matched.
  my $out = XML::LibXML::Document->new($doc->getVersion, $doc->getEncoding);
  # Copy doctypes
  # This worked for 2.0001/2.8.0 (wheezy),
  # but does look somewhat clumsy. 
  if ($doc->externalSubset) {
    my $ext = $doc->externalSubset;
    $out->createExternalSubset($ext->getName(),
                               $ext->publicId(),
                               $ext->systemId());
  }
  if ($doc->internalSubset) {
    my $int = $doc->internalSubset;
    $out->createInternalSubset($int->getName(),
                               $int->publicId(),
                               $int->systemId());
  }
  $out->setDocumentElement($docroot);
 
  # Run the sheet 
  $descroot->run($dataroot, $docroot);  

  return $out;
}

1;


__END__

=head1 NAME

Cindy - use unmodified XML or HTML documents as templates.

=head1 SYNOPSIS

  use Cindy;
  
  my $doc = get_html_doc('cindy.html');
  my $data = get_xml_doc('cindy.xml');
  my $descriptions = parse_cis('cindy.cjs');
  
  my $out = inject($data, $doc, $descriptions);
  
  print $out->toStringHTML();

=head1 DESCRIPTION

C<Cindy> does Content INjection into XML and HTML documents.
The positions for the modifications as well as for the data
are identified by xpath expressions. These are kept in a seperate file
called a Content inJection Sheet. The syntax of this CJS  file (the ending 
.cis implies a japanese charset in the apache defaults)
remotely resembles CSS. The actions for content modification are
those implemented by TAL.

If you want to use Cindy for web development you will probably need
Cindy::Apache2 (see  L<http://search.cpan.org/%7ejzobel/Cindy-Apache2/>) 
which is distributed separately since it introduces additional dependencies. 

=head2 CJS SYNTAX

The syntax for content injection sheets is pretty simple. In most cases
it is

  <source path> <action> <target path> ;

If the syntax for an action differs from the above this
is documented with the action.

The source and target path are xpath expressions by default. 
The action describes how to move the data. The whitespace before the 
terminating ; is required,
since xpath expressions may end with a colon. The xpath expressions must 
not contain whitespaces. Alternatively they can be enclosed in double 
quotes. 

Everything from a ; to the end of the line is ignored and can be used 
for comments. 

A first line

  use css ;

switches the interpretation of source and target path from xpath to 
CSS selectors. These are less powerful but according to Parr 
(see  L<http://www.cs.usfca.edu/~parrt/papers/mvc.templates.pdf>) this 
can be considered a good thing. Using css selectors reduces Cindies 
entanglement index from 4 to 1.

=head2 CJS ACTIONS

Actions locate data and document nodes and perform an operation that
creates a modified document.

All source paths for actions other than repeat should locate one node.
Otherwise the action is executed for all source nodes on the same target.
The action is executed for all target nodes. 

Actions are executed in the order they appear in the sheet. Subsheets 
are executed after the enclosing sheet. 

The following example illustrates the effect of exectuion order. 
If a target node is omitted, an action that changes its content 
will not have any effect. 

  true()    omit-tag  <target> ;
  <source>  content   <target> ;

So the above is not equvalent to the replace action.

Execution matches document nodes and then data nodes. Thereafter 
the actions are executed. Since execution of a repeat action copies
the document node for each repetition, changes to this node
done after the repeat are lost. At last this is recursively done for 
all subsheets.

As an unfortunate consequence matches on subsheet doc nodes do see the 
changes done by actions from enclosing sheets. This behaviour will 
hopefully change in future releases.

=head3 content

All child nodes of the target node are replaced by child nodes of the 
source node. This means that the text of the source tag with all tags 
it contains replaces the content of the target tag. If data is not
a node, it is treated as text.

If no source node matched, the target node will be left unchanged. 

=head3 replace

The child nodes of the source node replace the target node and all its 
content. This means that the target tag including any content is replaced
by the content of the source tag. This is equivalent to

  <source>  content   <target> ;
  true()    omit-tag  <target> ;

If no source node matched, the target node will be left unchanged. 

=head3 copy

The source node with all its content replaces the target node 
and all its content. This means that the target tag including any 
content is replaced by the the source tag and its content. 

If no source node matched, the target node will be left unchanged. 

Be aware that this requires the source tag to be valid in the target 
document.

=head3 omit-tag

The source node is used as a condition. If it exists and if its text 
content evaluates to true the target node is replaced by its children.
This means that if the source tag exists and its content is not '' or
0 the target tag is removed while its content remains.

=head3 comment

The source nodes content is moved into a comment node. This comment node
is appended to the children of the target node. This can be useful for 
debugging and enables injection of SSI directives.

=head3 attribute

The syntax has an additional field atname

  <source>  attribute   <target> <atname> ;

that holds the name of the attribute. If the source node exists, its 
content replaces or sets the value of the atname attribute of the 
target node. If the source node does not exist the attribute atname
is removed from the target node.

=head3 condition

The source node is used as a condition. If it exists and if its text 
content evaluates to true nothing is done. Otherwise the target node 
and its children are removed. This means that the target tag is removed 
if the source tage does not exist or contains '', 0 or 0.0 while it is 
left untouched otherwise.

=head3 repeat

The repeat action is the CJS equivalent of a template engines loop. For 
each match of the source path the source node and the target node are 
used as root nodes for a sequence of actions. The syntax is

  <source>  repeat   <target>  [condition] {
    <actions>
  } ;

The optional condition is an xpath expression that is run in the context 
of the root node of a temporary document fragment. The fragment has 
two children, DOC and DATA which hold a subtree from a repeat doc respective data 
match. Only those combinations where the condition evaluates to true are 
used, all others are discarded. 

Note that the repeat condition is an EXPERIMENTAL feature, it may well 
change.

=head2 XPATH FUNCTIONS

A small number of additional XPath functions have been implemented. 

=head3 current()

This returns the context node. It behaves like the identically 
named XSLT function.

=head1 ERROR HANDLING

As a default Cindy dies on errors. Currently there are no warnings. 
Cindy detects log4perl and uses it for trace logging 
with levels DEBUG and INFO. If Cindy is used from Cindy-Apache2 the 
apache log is used instead.

=head1 AUTHOR

Joachim Zobel <jz-2008@heute-morgen.de> 

=head1 SEE ALSO

See Cindy/CJSGrammar.rdc for the RecDescent grammar for content injection sheets.

If you prefer a classic push template engine, that uses an API to fill the template
from within the application see  L<http://search.cpan.org/~tomita/Template-Semantic>.
This also uses xpath or css selectors to move data into unmodified templates.



