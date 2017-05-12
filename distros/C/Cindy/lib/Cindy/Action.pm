# $Id: Action.pm 115 2011-04-28 16:28:51Z jo $
# Cindy::Action - Action (content, replace,...) implementation
#
# Copyright (c) 2008 Joachim Zobel <jz-2008@heute-morgen.de>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

#
# The funtions  in this package manipulate the 
# given node using the given data.  
# 

package Cindy::Action;

use strict;
use warnings;

use XML::LibXML;

#
# Helpers/Wrappers
#

#
# Evaluate data node as boolean
#
sub is_true($)
{
  my ($data) = @_;

  return 0 if (!$data); 
  return $data->textContent if ($data->can('textContent'));
  return $data->value if ($data->can('value')); 
}

#
# Evaluate data node text
#
sub text($)
{
  my ($data) = @_;

  return $data->textContent if ($data->can('textContent'));
  return $data->value if ($data->can('value')); 
  # This may be text by some perl magic
  return $data;
}


#
# Get list of child nodes
#
sub copy_children($$)
{
  my ($data, $node) =@_;

  if (defined($data)) {
    if ($data->isa('XML::LibXML::Attr') ) {
      # Replace an attribute node with a text node
      return ($node->ownerDocument->createTextNode(
                      $data->textContent));
    } else {
      return map {$_->cloneNode(1);} $data->childNodes() ;
    }
  } else {
    return ();
  }
}

#
# The node only survives if data exists and its content
# evalutes to true. 
#
sub condition($$) 
{
  my ($node, $data) = @_;  

	#	remove node 
  if  (!is_true($data)) {
    my $parent = $node->parentNode;
    $parent->removeChild( $node );
  }

  return 0;
}

#
# The node gets a copy of the data children to replace
# the existing ones. This copies the text held by data
# as well as possible element nodes (e.g. <b>). If data
# is not a node its treated as text.
#
sub content($$) 
{
  my ($node, $data) = @_;  

  # An a node without children will remove all
  # target children. If however no node matched,
  # the target node will be left unchanged. 
  if (defined($data)) {
    $node->removeChildNodes();	
    if ( $data->can('childNodes')
      || $data->isa('XML::LibXML::Attr')) {
      foreach my $child (copy_children($data, $node)) {
        $node->appendChild($child);
      }
    } else {
      # No child nodes, not an attr. so its hopefully text
      $node->appendChild(
          $node->ownerDocument->createTextNode(text($data)));
    }
  }  

  return 0;
}

#
# Appends a comment as a child of the node. Data is
# interpreted as the text for the comment.
#
sub comment($$) 
{
  my ($node, $data) = @_;  

  if (defined($data)) {
    $node->appendChild(
      $node->ownerDocument->createComment(text($data)));
  }  

  return 0;
}

#
# The node is removed and the parent node gets 
# the data children instead. 
#
sub replace($$) 
{
  my ($node, $data) = @_;  

  my $parent = $node->parentNode;
  
  foreach my $child (copy_children($data, $node)) {
    $parent->insertBefore($child, $node);
  }

  # An a node without children will remove all
  # target children. If however no node matched,
  # the target node will be left unchanged. 
  if (defined($data)) {
    $parent->removeChild($node);
  }

  return 0;
}

#
# The node is removed and the parent node gets 
# the data node and its children instead. 
#
sub copy($$) 
{
  my ($node, $data) = @_;  
  
  # If no node matched,
  # the target node will be left unchanged. 
  if (defined($data)) {
    my $parent = $node->parentNode;
    $parent->insertBefore($data->cloneNode(1), $node);
    $parent->removeChild($node);
  }

  return 0;
}


#
# If data and its text content evaluate to true the node is 
# removed and the parent node gets the children instead.
#
sub omit_tag($$) 
{
  my ($node, $data) = @_;  

  if (is_true($data)) {
    my $parent = $node->parentNode;

    foreach my $child ($node->childNodes()) {
      $parent->insertBefore($child->cloneNode(1), $node);
    }
  
    $parent->removeChild($node);
  }
  return 0;
}

#
# Sets or removes an attribute from an element node.
# If data is undefined the element is removed, otherwise
# the data text content is used as the attribute value. 
# Note the additional parameter name which passes the
# attribute name. 
#
sub attribute($$$) 
{
  my ($node, $data, $name) = @_;  

  if ($data) {
    $node->setAttribute($name, text($data));    
  } else {
    $node->removeAttribute($name);
  }

  return 0;
}

#
# Copies the doc node and inserts the copy before
# the original. 
# The actual repetion is done by the data xpath.
#
# return The cloned node
#
sub repeat($$) 
{
  my ($node, $data) = @_;  

  if (defined($data)) {
    my $parent = $node->parentNode;
    # Note that we do a deep copy here.
    my $new = $node->cloneNode(1);
  
    $parent->insertBefore($new, $node);
    return $new;
  } else {
    return;
  }
}

#
# Special actions for internal use
#

#
# Removes the given node. Data is ignored. 
#
sub remove($$) 
{
  my ($node, $data) = @_;  
    
  my $parent = $node->parentNode;
  $parent->removeChild($node);

  return 0;
}

#
# Does nothing. Used for subsheet holders.
#
sub none($$) 
{
}


1;

