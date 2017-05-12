# Makes mod_xml2 functionality available to perl modules
# $Id: $
package Apache2::ModXml2;

use 5.010001;
use strict;
use warnings;

use XML::LibXML;
use XML::LibXML::Devel qw(:all);

use Apache2::RequestRec;
use APR::Pool;

use Apache2::Filter;
use APR::Brigade ( );
use APR::Bucket ( );
use APR::BucketType ( );

use Apache2::Log;  

use base qw(Exporter);

use vars qw( @EXPORT @EXPORT_OK %EXPORT_TAGS );

our %EXPORT_TAGS = ( 'all' => [ qw(	
  wrap_node
  unwrap_node
  end_bucket
  cmp_bucket
  make_start_bucket
  xpath_filter_init 
  xpath_filter 
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Apache2::ModXml2', $VERSION);


sub unwrap_node 
{
  my ($b) = @_;
  my $vn = xml2_unwrap_node($b);
  # The nodes are owned by the document.
  # We do not introduce an owner fragment
  # as LibXML does it.
  my $d = raw_owner_document($vn);
  my $rtn = node_to_perl($vn, $d);
  refcnt_inc($vn);
  return $rtn;
}

sub wrap_node 
{
  my ($a, $n, $r) = @_;
  my $vn = node_from_perl($n);
  my $b = xml2_wrap_node($a, $vn, $r);
  refcnt_inc($vn);
  return $b;
}

sub xpath_filter_init
{
  my ($f, $pattern, $namespaces, $transform ) = @_;

  if (defined($namespaces)) {
    push(@$namespaces, (undef, undef));
  }

  xml2_xpath_filter_init($f, $pattern, $namespaces, sub {
    my ($n) = @_;
    $f->r->log->debug("Transform callback called.");
    my $node = node_to_perl($n, raw_owner_document($n));
    refcnt_inc($n); 
    
    &$transform($node); 
    $f->r->log->debug("Transform callback finished.");
  });
}

#
# INTERNAL
# Called from mod_xml2 through the XS layer.
#
sub document_start 
{
  my ($r, $d) = @_;  
  my $rec = rec_to_perl($r);

  $rec->log->debug("document_start called.");

  my $doc = node_to_perl($d);
  # If the doc node has just been created, 
  # it has one reference
  die "document_start found doc with  refcnt=".refcnt($d)."." 
    unless (refcnt($d) == 1);
  # We inc. the counter to for $doc 
  refcnt_inc($d); 
  # We inc. the counter to prevent deletion 
  refcnt_inc($d); 
  # and schedule deletion at request cleanup time
  $rec->pool->cleanup_register(sub {refcnt_dec($_[0]);}, $d);  
}

1;
__END__

=head1 NAME

Apache2::ModXml2 - makes mod_xml2 funtionality available to perl modules

=head1 SYNOPSIS

  use XML::LibXML;

  use Apache2::ModXml2 qw(:all);

  # The usual filter stuff is omitted
  # ...

    for (my $b = $bb->first; $b; $b = $bb->next($b)) {      
      if ($b->type->name eq 'NODE') {
        # This is the most important interface function
        my $node = Apache2::ModXml2::unwrap_node($b);
        # The nodes are not connected but still know their document
        my $doc = $node->ownerDocument;
        if (defined($node)) {
          if ($node->isa('XML::LibXML::Element')) {
            my $end = Apache2::ModXml2::end_bucket($b);
            if ($end) {
                # If it knows the end bucket, it is a start bucket
                $node->setAttribute('class', 'mod_xml2');
            }

=head1 DESCRIPTION

C<Apache2::ModXml2> is a wrapper for the mod_xml2 API. It allows you to
write filters that modify the outgoing XML/HTML by modifying 
C<XML::LibXML> nodes.

The apache module mod_xml2 implements the "node" filter. This filter
runs the libxml2 parser on the outgoing XML/HTML and wraps the SAX 
events into a special bucket type. These are called node buckets. 

Subsequent filters then modify the outgoing by modifying the node 
bucket stream. With C<Apache2::ModXml2> this can be done with perl.

Node buckets hold a libxml node. ModXml2 wraps it into a 
XML::LibXML::Node that can be used with the set of funtions
provided by C<XML::LibXML>. 

Note that in case of element nodes start and end 
bucket hold the same node. The start bucket already knows the 
end bucket. Even so the start node continues to exist until
the end node is reached, modifying it may be pointless if it 
has been passed to the filter again. The node may have been sent
over the network.

C<Apache2::ModXml2> also offers XPath callbacks, that get called
on matches of (very) simple XPath selectors. Unlike the simpler
ModXml2 functions these can do DOM tree manipulation since the
matches get passed in as trees.

=head1 FUNCTIONS

=head2 BASIC FUNCTIONS

=over 1

=item wrap_node

  wrap_node($alloc, $node, $r_log);

Returns an APR::Bucket object that has been created wrapping $node
into a mod_xml2 node using the APR::BucketAllocator $alloc.

$r_log is a request object to use for logging. 

=item unwrap_node

  unwrap_node($b);

Returns the XML::LibXML::Node held by the  APR::Bucket $b given
as a parameter. 

=item end_bucket

  end_bucket($b);

Returns the associated end bucket provided $b is a start element bucket
and undef othewise.

=item make_start_bucket

  make_start_bucket($b);

Turns the bucket $b into a start element bucket and returns the
thereby created end bucket. 

=item init_doc

  init_doc($doc, $pool);

This function is needed since wrapping of the document node
(e.g. by calling $node->ownerDocument) will delete it when 
the perl node does out of scope. 

So in case the document is used this needs to be called
with the document and
a pool to append node deletion as a cleanup.

=back

=head2 XPATH FILTERING

mod_xml2 implements functions for a filter that builds a DOM subtree 
each time
a streaming xpath expression (named pattern by libxml2) matches.
The tree is passed passed to a callback function and decomposed
into single nodes again afterwards.  
The streaming xpath expressions are from a very limited xpath subset 
as described here:
http://www.w3.org/TR/xmlschema-1/#Selector

=over 1

=item xpath_filter_init

  xpath_filter_init($f, $xpath, $namespaces, &transform);

To create a streaming xpath filter this function needs to be called
from filter init. The return value is suitable for returning it from 
filter init.

Every time $xpath matches &transform is called with the subtrees root
node as a parameter.  The namespaces needed to compile the pattern 
are passed as a list [URI, prefix, ...]. Be aware that these prefixes 
are just aliases for pattern usage. They do not need to coincide with 
the prefixes in the document.

=item xpath_filter

  xpath_filter($f, $bb);

This is simply the work horse filter function.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

The concept for this implementation:

http://www.heute-morgen.de/site/03_Web_Tech/50_Building_an_Apache_XML_Rewriting_Stack.shtml

The mod_xml2 apache module:

http://www.heute-morgen.de/modules/mod_xml2/

=head1 AUTHOR

Joachim Zobel, E<lt>jz-2012@heute-morgen.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Joachim Zobel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
