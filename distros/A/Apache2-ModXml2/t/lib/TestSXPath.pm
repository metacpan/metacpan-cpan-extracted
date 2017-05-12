# Test mod_xml2
# $Id: TestXML2.pm 31 2011-10-25 19:24:53Z jo $

use strict;
use warnings;

use Apache2::RequestRec;

use Apache2::Filter;

use APR::Brigade ( );
use APR::Bucket ( );
use APR::BucketType ( );

use Apache2::Log;  
use APR::Const -compile => ':common';
#use Apache2::Const;

use XML::LibXML;

# Shortcut package to prefix all ModXML2 functions
package AMX2;
use Apache2::ModXml2 qw(:all);

#use Scalar::Util qw(refaddr);
package TestSXPath;

use URI;

use base qw(Apache2::Filter);


#
# HTML/SXPATH
# 
sub init_sxpath: FilterInitHandler {
    my($filter) = @_;

    $filter->r->log->debug("SXPATH handler will be initialised.");
    $filter->ctx(1);
    return AMX2::xpath_filter_init($filter, 
                                   './/a', undef, 
                                   get_transform($filter->r));
}

sub handler: FilterHasInitHandler(\&init_sxpath)  {
    my($filter, $bb) = @_;
    $filter->r->log->debug("SXPATH handler called.");

    if (!$filter->ctx) {
        # Filter initialisation by attribute seems to not work
        init_sxpath($filter);
        $filter->r->log->debug("SXPATH handler initialised from self.");
        # Mark as initialized
        $filter->ctx(1);
    }

    my $rtn = AMX2::xpath_filter($filter, $bb);

    $filter->r->log->debug("SXPATH handler finished.");
    return $rtn;
}

sub get_transform
{
  my ($r) = @_;
  return sub {
        my($frag) = @_;
        my $tree = $frag->firstChild;    

        $r->log->debug("Tree: ".$tree->toString());

        #return APR::Const::SUCCESS();
    
        my $doc = $tree->ownerDocument;
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
# OSM
#
sub init_osm : FilterInitHandler {
    my($filter) = @_;

    $filter->r->log->debug("OSM handler will be initialised.");
    return AMX2::xpath_filter_init($filter, 
                                   './/node', undef, 
                                   get_osm_transform($filter->r));
}

sub osm : FilterHasInitHandler(\&init_osm) {
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
   
        $r->log->debug("Ref: ".ref($frag));
        $r->log->debug("Name: ".$frag->nodeName);
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

#
# Helper for debugging
#

use Apache2::FilterRec;

sub log {
    my($filter, $bb) = @_;

    $filter->r->log->info("Logging filter called.");
    my $f = $filter;
    while ($f = $f->next) {
      $filter->r->log->info("Next filter is " . $f->frec->name . ".");
    }

    for (my $b = $bb->first; $b; $b = $bb->next($b)) { 
        $filter->r->log->debug("Logging FLUSH.") if $b->is_flush;
        $filter->r->log->debug("Logging EOS.") if $b->is_eos;
    }

    my $ret = $filter->next->pass_brigade($bb);

    $filter->r->log->info("Logging filter finished.");

    return $ret;
}

1;



