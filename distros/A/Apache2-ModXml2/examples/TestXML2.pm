# Test mod_xml2
# $Id: TestXML2.pm 50 2012-04-20 17:48:27Z jo $

use strict;
use warnings;


use Apache2::RequestRec;
use APR::Pool;

use Apache2::Filter;

use APR::Brigade ( );
use APR::Bucket ( );
use APR::BucketType ( );

use Apache2::Log;  
use APR::Const -compile => ':common';
#use Apache2::Const;

use XML::LibXML;

use lib qw(
  /home/jo/projects/local/Apache2-ModXml2/trunk/blib/lib
  /home/jo/projects/local/Apache2-ModXml2/trunk/blib/arch );

# Shortcut package to prefix all ModXML2 functions
package AMX2;
use Apache2::ModXml2 qw(:all);

#use Scalar::Util qw(refaddr);
package TestXML2;

use URI;

use base qw(Apache2::Filter);


#
# XML
#
sub handler {
    my($filter, $bb) = @_;
    my $alloc = $bb->bucket_alloc;

    my $last_end = undef;
    for (my $b = $bb->first; $b; $b = $bb->next($b)) {      
      
      if ($b->type->name eq 'NODE') {
        # This is the most important interface function
        my $node = AMX2::unwrap_node($b);
        # The nodes are not connected but still know their document
        my $doc = $node->ownerDocument;
        if (defined($node)) {
          if ($node->isa('XML::LibXML::Element')) {
            my $end = AMX2::end_bucket($b);
            if (!$end) {
                # We set the attribute from the end node !
                $node->setAttribute('class', 'mod_xml2');
            }
            if ($node->nodeName eq 'first'
                and defined ($end)) {
                $b->insert_after(
                    APR::Bucket::flush_create($alloc));
            }
            if ($node->nodeName eq 'second'
                and defined ($end)) {
                my $node = XML::LibXML::Element->new( 'mod-xml2' );
                # Add a small subtree
                $node->addChild($doc->createTextNode("mod xml2"));
                $b->insert_after(
                    AMX2::wrap_node($alloc,
                                               $node,
                                               $filter->r));
            }
            if ($node->nodeName eq 'third') {
                # If it has an end bucket it must be a start bucket
                $last_end = $end if (defined($end));
                if (AMX2::cmp_bucket($b, $last_end) == 0) {
                    $b->insert_after(
                        AMX2::wrap_node($alloc, 
                                                   $doc->createComment("mod_xml2"), 
                                                   $filter->r));
                } else { 
                    $b->insert_after(
                        AMX2::wrap_node($alloc, 
                                                   $doc->createTextNode("mod_xml2: "), 
                                                   $filter->r));
                }
            }
            if ($node->nodeName eq 'filter'
                and defined ($end)) {
                my $node = XML::LibXML::Element->new( 'before-first' );
                my $start = AMX2::wrap_node($alloc, 
                                                       $node,
                                                       $filter->r);
                my $end = AMX2::make_start_bucket($start);
                die "makeStartBucket failed." if (not defined ($end));
                my $content = AMX2::wrap_node($alloc, 
                                                   $doc->createTextNode("0"), 
                                                   $filter->r);
                $b->insert_after($end);
                $b->insert_after($content);
                $b->insert_after($start);
                
            }
          }
        } else {
          $filter->r->log->error("No node in bucket data:".$b->data);
        }
      }

    }

    my $rv = $filter->next->pass_brigade($bb);
    return $rv unless $rv == APR::Const::SUCCESS();

    return APR::Const::SUCCESS();
}

#
# HTML/SXPATH
# 
sub init_html : FilterInitHandler {
    my($filter) = @_;

    $filter->r->log->debug("HTML handler will be initialised.");
    return AMX2::xpath_filter_init($filter, 
                                   './/a', undef, 
                                   get_transform($filter->r));
}

sub handler_html : FilterHasInitHandler(\&init_html) {
    my($filter, $bb) = @_;

    if (!$filter->ctx) {
        init_html($filter);
    }

    $filter->r->log->debug("HTML handler called.");
    return AMX2::xpath_filter($filter, $bb);
}

sub get_transform
{
  my ($r) = @_;
  return sub {
        my($tree) = @_;
    
        $r->log->debug("Tree: ".$tree->toString());

        #return APR::Const::SUCCESS();
    
        my $doc = $tree->ownerDocument;
        my $frag = $tree->parentNode;
        my $xpc = XML::LibXML::XPathContext->new($frag);
        $r->log->debug("XPathContext created.");
        my @tags = $xpc->findnodes(q|.//*[@tag='param']|);    

        $r->log->debug(scalar(@tags)." parameter tags found.");
        
        $tree->addChild($doc->createComment("mod_xml2"));

        my @params = ();
        foreach my $tag (@tags) {
            push(@params, $tag->getAttribute( 'name' ));
            push(@params, $tag->textContent());
            $tag->unbindNode();
        }
    
        my $uri = URI->new($tree->getAttribute('href'));
        $uri->query_form(@params);
        $r->log->debug("Setting new href ".$uri.".");
        $tree->setAttribute('href', $uri);

        $r->log->debug("transform is done.");    
        return APR::Const::SUCCESS();
    };
}


#
# OSM/SXPATH
# 
sub init_osm : FilterInitHandler {
    my($filter) = @_;

    $filter->r->log->debug("OSM handler will be initialised.");
    return AMX2::xpath_filter_init($filter, 
                                   './/node', undef, 
                                   get_osm_transform($filter->r));
}

sub handler_osm : FilterHasInitHandler(\&init_osm) {
    my($filter, $bb) = @_;
    $filter->r->log->debug("OSM handler called.");

    if (!$filter->ctx) {
        init_osm($filter);
        $filter->ctx(1);
    }

    return AMX2::xpath_filter($filter, $bb);
}

sub get_osm_transform
{
  my ($r) = @_;
  return sub {
        my($frag) = @_;
   
        $r->log->debug("Tree: ".$frag->toString());
        my $tree = $frag->firstChild;        
        return unless ($tree);

        #return APR::Const::SUCCESS();
    
        my $doc = $frag->ownerDocument;
        $r->log->debug("XPathContext will be created.");
        my $xpc = XML::LibXML::XPathContext->new($frag);
        $r->log->debug("XPathContext created.");
        # check if the node is a gas station.
        my @tags = $xpc->findnodes(q|.//tag[@k='amenity'][@v='fuel']|);    

        $r->log->debug(scalar(@tags)." fuel tags found.");

        if (!@tags) {
          # We remove the whole tree.
          $frag->removeChild($tree);
        }

        return APR::Const::SUCCESS();
    };
}


1;



