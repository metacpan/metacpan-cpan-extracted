package Data::NestedSet;

use 5.008008;
use strict;
use warnings;
use Carp;


our $VERSION=1.03;

	sub new {
	    my ($class,$data,$depth_position)= @_;

	    croak 'An array ref must be supplied as the first argument. Seen '. ref($data) if(ref($data) ne 'ARRAY');
	    my $nb = scalar @{$data};

	    croak 'The number of items within the array ref must be >=1 . Seen '.$nb if($nb==0);
	    croak 'An integer must be supplied as the second argument. Seen '. $depth_position if(not defined $depth_position 
 												  || $depth_position!~m/^[0-9]+/mx);


	    my $this    = {
	      left_node           => 1,
              previous_right_node => [],
              last_depth          => 0,
              Data_length         => $nb,
              Max_right_node      => $nb*2,
              depth_position      => $depth_position,
	      data                => $data,
            };

	    $this->{Left}  = scalar @{$data->[0]};
	    $this->{Right} = $this->{Left} + 1;

	    #the first row is the root, we assign 1 to left and the maximum value possible to right
	    $this->{data}->[0]->[$this->{Left}]  = $this->{left_node};
	    $this->{data}->[0]->[$this->{Right}] = $this->{Max_right_node};

	    bless $this, $class;
	    return $this;

	}

	sub create_nodes {
	    my $this = shift;

	    for(my $i=1; $i<$this->{Data_length}; $i++) {

	       my $orientation = $this->{data}->[$i][$this->{depth_position}] - $this->{last_depth};

              if($orientation==1) { #go down in depth

	           $this->set_left_node($i);

	       }
	       elsif($orientation==0) { # same depth level

		   $this->set_previous_right_node();
	           $this->set_left_node($i);

	       }
	       else { # go back up in depth

	          $this->set_previous_right_node();

		  my $depth = abs $orientation;

		  for(0..$depth-1) {
		       $this->set_previous_right_node();
	          }
	          $this->set_left_node($i);
             }

             push @{$this->{previous_right_node}},$i;
             $this->{last_depth}=$this->{data}->[$i]->[$this->{depth_position}];
        }
	 $this->set_right_nodes();
	 return $this->{data};
     }

     sub set_previous_right_node {
	    my $this=shift;
	    $this->{left_node}++;
	    $this->{data}->[pop @{$this->{previous_right_node}}]->[$this->{Right}]=$this->{left_node};
     }

     sub set_left_node {
	   my $this=shift;
	   $this->{left_node}++;
	   $this->{data}->[shift]->[$this->{Left}]=$this->{left_node};
     }

     sub set_right_nodes {
	   my $this=shift;
	   my $last_node = $this->{data}->[$this->{Data_length}-1][$this->{Left}];
	   for(my $i=scalar(@{$this->{previous_right_node}}) -1; $i >= 0; $i--) {
		$last_node++;
		$this->{data}->[$this->{previous_right_node}->[$i]]->[$this->{Right}]=$last_node;
	   }
    }

1;

__END__

=pod

=head1 NAME

Data::NestedSet - calculate left - right values from depth (modified preorder tree traversal algorithm)

=head1 VERSION

1.03

=head1 SYNOPSIS


    use Data::NestedSet; 


    ##let's pretend that you get that from a spreadsheet...
    my $data = [
           [1,'MUSIC',0],
           [2,'M-GUITARS',1],
           [3,'M-G-GIBSON',2],
           [4,'M-G-G-SG',3],
           [5,'M-G-FENDER',2],
           [6,'M-G-F-TELECASTER',3],
           [7,'M-PIANOS',1],
           #go on....
    ];

    my $nodes   = new Data::NestedSet($data,2)->create_nodes();

    #now $nodes contains : 

    #[
    #       [1,'MUSIC',0,1,14],
    #       [2,'M-GUITARS',1,2,11],
    #       [3,'M-G-GIBSON',2,3,6],
    #       [4,'M-G-G-SG',3,4,5],
    #       [5,'M-G-FENDER',2,7,10],
    #       [6,'M-G-F-TELECASTER',3,8,9],
    #       [7,'M-PIANOS',1,12,13],
    #];


=head1 DESCRIPTION

Based on the depth,the Data::NestedSet allows you to get the left and right values
for a modified preorder tree.


=head1 MOTIVATION


You've decided to deal with hiearachical data within your database by using
the nested set model (adjacency list model is an other way of doing so)
but you do not want to write all the left and right values by hand.
It is manageable when the depth and number of categories is small like the above
example but when it changes into hundreds of categories with a lot of depth level,
this can become a real nightmare (don't even mention reorganisation of the tree!).

If you want third parts to deal with this system thru an easy-to-go process,
you may have a hard time explaining the nested model concept:

C<< Basically each rows can be considered the branch or the leaf of a tree where
the left and right value of a row represents all the sub categories
within this category...
Therefore when the right value minus the left value is equal to 1, 
you can say that this category does not contain any sub categories,
you see? >>
...
...

But explaining that categories nest with depth can be easily understood:

C<< The first category is at level 0. The next category within the first category is 
at level 1 and so on and so forth. >>

You should see in the eyes of your listener a glow of understanding.

If so, let your user fill in an excel file and let this module do the job for you!



=head1 ADVANTAGES

Even if these advantages are related to the nested set model rather than to this module,
it is interesting to notice that:

- You can build an entire tree in a snap.

- You can rebuilt the entire tree structure in a snap too:


If you insert for the first time the newly created nested model in your favorite database
and then needs to change many categories depth, reorder the tree, 
just export the data with ids (serial, autoincrement value),depth and any relevant business logic data
 into a csv file or better a spreadsheet (xls,ods, you pick), let your user
reorder the tree by modifying the depth and reimport!
Use the module to recreate the left and right values and then update or even insert if necessary
the new tree.

- You can change the order of the tree very easily.

How many times did a client come over you asking you to reorder the categories?
The nested set model allows to order the categories by their left (or right) value.
You can therefore reorder the categories and reimport them very easily
and reorder the entire tree.


=head1  SUBROUTINES/METHODS

As for now, the module is using an oo interface even if a simple
procedural interface could do the job,several methods dealing with the tree structure
(get_descendents, get_children, get_root,etc...) may be added for easy mocking.

=over 

=item B<new(Arrayref of ref,depth offset)>

Takes an array ref of array ref as its first argument
and the position of the depth as its second.
Each row within the array ref should have the same number of 'columns'.
The data should always contain the entire tree with the first row containing the 
root with a depth level of 0.
The depth offset is where the module should look for the value of the depth.

Return a NestedModel object.

=item B<create_nodes>

Built the tree and return an array ref of array ref with the left 
and right values appended at the end.

=back

=head1 DIAGNOSTICS

=over

=item C<< An array ref must be supplied as the first argument. Seen ... >>

You did not pass an array reference to the constructor as its first argument.

    my $nodes = new Data::NestedSet(@array,2);  # error
    my $nodes = new Data::NestedSet(\@array,2); # ok


=item C<< The number of items within the array ref must be >=1 . Seen ... >>

You passed an empty reference to the constructor.

    my $nodes = new Data::NestedSet([],2);              # error
    my $nodes = new Data::NestedSet([[1,'ROOT',0]],2);  # ok


=item C<< An integer must be supplied as the second argument. Seen ... >>

You didn't supply a proper depth's offset value within the array reference.

    my $nodes = new Data::NestedSet(\@array);         # error
    my $nodes = new Data::NestedSet(\@array,"wrong"); # error
    my $nodes = new Data::NestedSet(\@array,2);       # ok

=back


=head1  SEE ALSO

=over 

=item B<explanation of the nested set model>

http://dev.mysql.com/tech-resources/articles/hierarchical-data.html
(Managing Hierarchical Data in MySQL)

Even though, it is written for mysql rdb, the explanations are worth a look.

=item B<other related modules>

L<Table::ParentChild>
L<Tree::DAG_Node>
L<Sort::Tree>
L<DBIx::Tree>
L<DBIx::Tree::NestedSet>

None of this modules allows you to create a nested model 
from the depth but are related to some extends.

=back

=head1  CONFIGURATION AND ENVIRONMENT

none


=head1  DEPENDENCIES

none

=head1  INCOMPATIBILITIES

none



=head1 BUGS AND LIMITATIONS

If you do me the favor to _use_ this module and find a bug, please email me
i will try to do my best to fix it (patches welcome)!

=head1 AUTHOR

Shirirules E<lt>shiriru0111[arobas]hotmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

