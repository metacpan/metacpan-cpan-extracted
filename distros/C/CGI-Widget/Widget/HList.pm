package CGI::Widget::HList;

use lib '../blib/lib';
use Tree::DAG_Node;
use CGI qw(img br);
use CGI::Widget;
use CGI::Widget::HList::Node;
use vars qw(@ISA $VERSION);
use strict;
use overload '""' => \&ashtml;

@ISA = qw(CGI::Widget);
$VERSION = '0.53';

sub _init {
  my $self = shift;

  #clean out leading -'s;
  my @t = @_;
  for(my $i = 0; $i < @t; $i+=2){ $t[$i] =~ s/^-//; }
  my %param = @t;

  $self->img_open(  $param{img_open}   || img({-src=>'../images/menu_open.gif',-border=>0}));  #-
  $self->img_close( $param{img_close}  || img({-src=>'../images/menu_close.gif',-border=>0})); #+
  $self->img_leaf(  $param{img_leaf}   || img({-src=>'../images/menu_leaf.gif',-border=>0}));  #O
  $self->img_spacer($param{img_spacer} || img({-src=>'../images/menu_space.gif',-border=>0})); #_
  $self->img_trunk( $param{img_trunk}  || img({-src=>'../images/menu_trunk.gif',-border=>0})); #|
  $self->img_branch($param{img_branch} || img({-src=>'../images/menu_branch.gif',-border=>0}));#=
  $self->img_corner($param{img_corner} || img({-src=>'../images/menu_corner.gif',-border=>0}));#L

  #open, close, and leaf are all a type of node
  $self->render_node(  $param{render_node}   || 
											 sub{
													 my $node = shift;
													 $node->pregnant  ?     return $self->img_close  :
													 $node->state     ? 
															 $node->daughters ? return $self->img_open
																	              : return $self->img_leaf   :
															 $node->daughters ? return $self->img_close  :	
 															                    return $self->img_leaf   ;
											 }
										);

  #while these are of unique types
  $self->render_spacer($param{render_spacer} || sub{return $self->img_spacer});
  $self->render_trunk( $param{render_trunk}  || sub{return $self->img_trunk});
  $self->render_branch($param{render_branch} || 
											 sub{
													 my $node = shift;
													 $node->right_sister ? return $self->img_branch
															                 : return $self->img_corner;
											 }
											);

  $param{root} ? $self->root_node($param{root}) : $self->_init_root_node();
  return 1;
}

sub root_node {
  my($self,$val) = @_;
  return $self->{root} unless defined $val;
  $self->{root} = $val;
  return $self->{root};
}

sub _init_root_node {
  my $self = shift;
  my $node = $self->node;
  my $root = $self->root_node($node) || die "$node root creation failed: $!";
  return $self->root_node;
}

sub node {
		my $self = shift;
		my $node = CGI::Widget::HList::Node->new or die "$!";
		return $node;
}

sub html {
		my ($self,@args) = @_;
		$self = __PACKAGE__->new(@args) unless ref $self;
		return $self->ashtml(@_);
}

sub ashtml {
  my $self = shift;
  my @returns = $self->root_node->dump_names(trunk  => $self->render_trunk,
                                             node   => $self->render_node,
                                             spacer => $self->render_spacer,
                                             branch => $self->render_branch,
																						 break  => br."\n",
                                            );
  return join '',@returns;
}

sub render_node {
  my($self,$val) = @_;
  return $self->{render_node} unless defined $val;
  $self->{render_node} = $val;
  return $self->{render_node};
}

sub render_spacer {
  my($self,$val) = @_;
  return $self->{render_spacer} unless defined $val;
  $self->{render_spacer} = $val;
  return $self->{render_spacer};
}

sub render_trunk {
  my($self,$val) = @_;
  return $self->{render_trunk} unless defined $val;
  $self->{render_trunk} = $val;
  return $self->{render_trunk};
}

sub render_branch {
  my($self,$val) = @_;
  return $self->{render_branch} unless defined $val;
  $self->{render_branch} = $val;
  return $self->{render_branch};
}

sub img_open {
  my($self,$val) = @_;
  return $self->{img_open} unless defined $val;
  $self->{img_open} = $val;
  return $self->{img_open};
}

sub img_close {
  my($self,$val) = @_;
  return $self->{img_close} unless defined $val;
  $self->{img_close} = $val;
  return $self->{img_close};
}

sub img_leaf {
  my($self,$val) = @_;
  return $self->{img_leaf} unless defined $val;
  $self->{img_leaf} = $val;
  return $self->{img_leaf};
}

sub img_spacer {
  my($self,$val) = @_;
  return $self->{img_spacer} unless defined $val;
  $self->{img_spacer} = $val;
  return $self->{img_spacer};
}

sub img_trunk {
  my($self,$val) = @_;
  return $self->{img_trunk} unless defined $val;
  $self->{img_trunk} = $val;
  return $self->{img_trunk};
}

sub img_branch {
  my($self,$val) = @_;
  return $self->{img_branch} unless defined $val;
  $self->{img_branch} = $val;
  return $self->{img_branch};
}

sub img_corner {
  my($self,$val) = @_;
  return $self->{img_corner} unless defined $val;
  $self->{img_corner} = $val;
  return $self->{img_corner};
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

CGI::Widget::HList - Create and manipulate Hierarchial List widgets

=head1 SYNOPSIS

  use CGI::Widget::HList;
  use CGI::Widget::HList::Node;

  #create a node
  my $root_node = CGI::Widget::HList::Node->new;
     $root_node->name("mama");

  #create an hlist to manage the node
  my $hlist = CGI::Widget::HList->new(-root=>$root_node);

  #create a daughter node via the hlist object
  my $daughter  = $hlist->node;
     $daughter->name("baby");
  $root_node->add_daughter($daughter);
 
  #render the hlist
  print $hlist; #not very exciting

=head1 DESCRIPTION

CGI::Widget::HList provides look-and-feel for displaying a 
CGI::Widget::HList::Node tree graph.  For more information, 
see L<CGI::Widget::HList::Node>.

This module is where image configurations, node rendering, 
and connector rendering methods are stored in the form of 
callbacks.

Check ex/ for example scripts

=head2 Constuctors

CGI::Widget::HList has only one constructor: new().

For convenient access to the CGI::Widget::HList::Node
constructor, you can call the node() method.

new() accepts the following parameters, with optional leading dash.
All parameters are optional.

 Parameter                   Purpose
 -------------------------------------------------------------------
 root                        Root node of the tree to be rendered

 Images to be used in the HTML rendering of the tree:
 img_open,img_close,img_leaf,img_trunk,img_branch,img_corner,img_spacer                  

 The rendering methods themselves.  All are callbacks:
 render_node,render_branch,render_spacer,render_trunk                             

The rendering methods default to sensible code that uses the (also
default) images.  This can all be over-ridden.  See Methods.

=head2 Methods

Interpreted in a scalar context, the object is overloaded to return 
the html for the HList.  Easy!  

html(), or ashtml() can also be called to produce the series html.

node() returns a CGI::Widget::HList::Node object.

root_node() returns the HList's root node.

render_*() methods allow setting/retrieving the coderefs actually
used by CGI::Widget::HList::Node objects in the rendering process.

img_*() methods allow setting/retrieving image paths or text
that will be used by the rendering coderefs.

=head1 AUTHOR

 Drop me a line if you use this, I'd like to know where it ends up.

 Allen Day <allenday@ucla.edu>
 Copyright (c) 2001.

=head1 SEE ALSO

L<perl>.
L<CGI::Widget>.
L<CGI::Widget::HList::Node>
L<Tk::HList>.

=cut
