# Test mod_xml2
# $Id: TestXML2.pm 31 2011-10-25 19:24:53Z jo $

use strict;
use warnings;

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
sub test1 {
    my($filter, $bb) = @_;
    my $alloc = $bb->bucket_alloc;

    $filter->r->log->debug("test1 filter called.");

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
            # If it has no end node it is an end node.
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
                    # Wrap the subtree into a bucket. 
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

# Too long 
sub test2 {
    my($filter, $bb) = @_;
    my $alloc = $bb->bucket_alloc;

    $filter->r->log->debug("test2 filter called.");

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


1;



