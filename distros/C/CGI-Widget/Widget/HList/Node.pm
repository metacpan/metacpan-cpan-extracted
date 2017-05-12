package CGI::Widget::HList::Node;

use Tree::DAG_Node;
use vars qw(@ISA $VERSION);
use strict;

@ISA = qw(Tree::DAG_Node);
$VERSION = '0.51';

sub close {
  my $self = shift;
  $self->{state} = 0;
  return $self->{state};
}

sub open {
  my $self = shift;
  $self->{state} = 1;
  $self->pregnant(0);
  return $self->{state};
}

sub pregnant {
  my($self,$val) = @_;
  return $self->{pregnant} unless defined $val;
  $self->{pregnant} = $val;
  return $self->{pregnant};
}

sub state {
  my $self = shift;
  $self->{state} = 1 unless defined $self->{state}; #open by default
  $self->pregnant(0) if $self->{state};
  return $self->{state};
}

sub state_link {
  my($self,$val) = @_;
  return $self->{state_link} unless defined $val;
  $self->{state_link} = $val;
  return $self->{state_link};
}

sub link {
  my($self,$val) = @_;
  $self->{link} ||= sub {my $this = shift; return ($this->name) || $this};
  return $self->{link} unless defined $val;
  $self->{link} = $val;
  return $self->{link};
}

#overriding dump_names to use a more sensible output format
sub dump_names {
  my($it, %o) = @_;

  my @out = ();
  $o{_depth} ||= 0;
  $o{spacer}   ||= sub {return "z"};
  $o{trunk}    ||= sub {return "|"};
  $o{branch}   ||= sub {return "="};
  $o{node}     ||= sub {return "O "};
  $o{break}    ||= "\n";
  $o{callback}   = sub {
      my($this, $o) = @_[0,1];

			unless($this->state){                      #unless shows daughters
					$this->pregnant(1) if $this->descendants; #preserve the motherliness
					$this->clear_daughters;                #but kill the girls
			}

      my @spacer;
			my @ancestors = reverse $this->ancestors;

			my $index = 0;
			foreach my $ancestor (@ancestors){

					#last column is special (branches)
					if($ancestor->ancestors == $this->ancestors -1){
							push @spacer, $o->{branch}->($this);
					}

					#other columns
					else {
							push @spacer, $ancestors[$index+1]->right_sister ? 
								$o->{trunk}->() : 
								$o->{spacer}->();
					}
					$index++;
			}

      push(@out,join('',
             @spacer,
             $o->{node}->($this),
						 $this->link->($this),
						 $o->{break},
      ));

      return 1;
    }
  ;
  $it->walk_down(\%o);
  return @out;
}

# Below is stub documentation for your module. You better edit it!

=head1 NAME

CGI::Widget::HList::Node - Tree::DAG_Node extension for representing
Hierarchical List (HList) Nodes.

=head1 SYNOPSIS

  use CGI::Widget::HList::Node;
  my $node1 = CGI::Widget::HList::Node->new;
     $node1->name("no.1");
     $node1->link("http://some.link/");
  my $node2 = CGI::Widget::HList::Node->new;
     $node2->name("no.2");
     $node2->link("/");
  $node1->add_daughter($node1);

=head1 DESCRIPTION

CGI::Widget::HList::Node is a subclass of Tree::DAG_Node,
with a few overridden and extra methods that help it be more
specific to representation of DAGs in an HTML/CGI context.
See L<Tree::DAG_Node> for more details.

=head2 Constuctors

CGI::Widget::Series has multiple constructors.  See
L<Tree::DAG_Node>.

=head2 Methods

open() - set the value returned by state() to 1.  An open() node
is one which allows its daughters to be exposed.

close() - set the value returned by state() to 0.  A close() node
does not expose its daughter nodes.

state() - returns the open/close state of a node.

pregnant() - a node that has the potential to have daughter nodes,
but currently does not have them can be tagged by calling pregnant
with a non-zero,defined value.  Calling with zero or undef terminates
the pregnancy, as does calling open() on the node.

link() - holds a subroutine used to render the text label of the node.
Returns name() or an object reference by default.  Override this with
a callback.

dump_names() - overridden to produce a highly flexible hierarchical
list, optionally with CGI parameters and HTML tags.

Many, many methods are provided by Tree::DAG_Node, and are
available within this class.  I have only outlined here overridden/
additional methods.  For complete documentation, also consult
L<Tree::DAG_Node>.

=head1 AUTHOR

 Allen Day <allenday@ucla.edu>
 Copyright (c) 2001.

=head1 SEE ALSO

L<perl>.
L<CGI::Widget>.
L<CGI::Widget::HList>.
L<Tree::DAG_Node>.

=cut












