package Bio::Tools::Phylo::PAML::ModelResult;
$Bio::Tools::Phylo::PAML::ModelResult::VERSION = '1.7.2';
use utf8;
use strict;
use warnings;

use base qw(Bio::Root::Root);

# ABSTRACT: A container for NSSite Model Result from PAML
# AUTHOR: Jason Stajich <jason@bioperl.org>
# OWNER: Jason Stajich <jason@bioperl.org>
# LICENSE: Perl_5



sub new {
  my($class,@args) = @_;

  my $self = $class->SUPER::new(@args);
  my ($modelnum,$modeldesc,$kappa,
      $timeused,$trees,
      $pos_sites,$neb_sites,$beb_sites,
      $num_site_classes, $shape_params,
      $dnds_classes,
      $likelihood) =          $self->_rearrange([qw(MODEL_NUM
                              MODEL_DESCRIPTION
                              KAPPA
                              TIME_USED
                              TREES
                              POS_SITES
                                                      NEB_SITES BEB_SITES
                              NUM_SITE_CLASSES
                              SHAPE_PARAMS
                              DNDS_SITE_CLASSES
                              LIKELIHOOD)],
                         @args);
  if( $trees ) {
      if(ref($trees) !~ /ARRAY/i ) {
      $self->warn("Must provide a valid array reference to initialize trees");
      } else {
      foreach my $t ( @$trees ) {
          $self->add_tree($t);
      }
      }
  }
  $self->{'_treeiterator'} = 0;
  if( $pos_sites ) {
      if(ref($pos_sites) !~ /ARRAY/i ) {
      $self->warn("Must provide a valid array reference to initialize pos_sites");
      } else {
      foreach my $s ( @$pos_sites ) {
          if( ref($s) !~ /ARRAY/i ) {
          $self->warn("Need an array reference for each entry in the pos_sites object");
          next;
          }
          $self->add_pos_selected_site(@$s);
      }
      }
  }
  if( $beb_sites ) {
    if(ref($beb_sites) !~ /ARRAY/i ) {
      $self->warn("Must provide a valid array reference to initialize beb_sites");
      } else {
      foreach my $s ( @$beb_sites ) {
          if( ref($s) !~ /ARRAY/i ) {
          $self->warn("need an array ref for each entry in the beb_sites object");
          next;
          }
          $self->add_BEB_pos_selected_site(@$s);
      }
      }
  }
  if( $neb_sites ) {
    if(ref($neb_sites) !~ /ARRAY/i ) {
      $self->warn("Must provide a valid array reference to initialize neb_sites");
      } else {
      foreach my $s ( @$neb_sites ) {
          if( ref($s) !~ /ARRAY/i ) {
          $self->warn("need an array ref for each entry in the neb_sites object");
          next;
          }
          $self->add_NEB_pos_selected_site(@$s);
      }
      }
  }

  defined $modelnum  && $self->model_num($modelnum);
  defined $modeldesc && $self->model_description($modeldesc);
  defined $kappa     && $self->kappa($kappa);
  defined $timeused  && $self->time_used($timeused);
  defined $likelihood  && $self->likelihood($likelihood);

  $self->num_site_classes($num_site_classes || 0);
  if( defined $dnds_classes ) {
      if( ref($dnds_classes) !~ /HASH/i ||
      ! defined $dnds_classes->{'p'} ||
      ! defined $dnds_classes->{'w'} ) {
      $self->warn("-dnds_site_classes expects a hashref with keys p and w");
      } else {
      $self->dnds_site_classes($dnds_classes);
      }
  }
  if( defined $shape_params ) {
      if( ref($shape_params) !~ /HASH/i ) {
      $self->warn("-shape_params expects a hashref not $shape_params\n");
      } else {
      $self->shape_params($shape_params);
      }
  }
  return $self;
}



sub model_num {
    my $self = shift;
    return $self->{'_num'} = shift if @_;
    return $self->{'_num'};
}


sub model_description{
    my $self = shift;
    return $self->{'_model_description'} = shift if @_;
    return $self->{'_model_description'};
}


sub time_used{
    my $self = shift;
    return $self->{'_time_used'} = shift if @_;
    return $self->{'_time_used'};
}


sub kappa{
    my $self = shift;
    return $self->{'_kappa'} = shift if @_;
    return $self->{'_kappa'};
}


sub num_site_classes{
    my $self = shift;
    return $self->{'_num_site_classes'} = shift if @_;
    return $self->{'_num_site_classes'};
}


sub dnds_site_classes{
    my $self = shift;
    return $self->{'_dnds_site_classes'} = shift if @_;
    return $self->{'_dnds_site_classes'};
}


sub get_pos_selected_sites{
   return @{$_[0]->{'_posselsites'} || []};
}


sub add_pos_selected_site{
   my ($self,$site,$aa,$pvalue,$signif) = @_;
   push @{$self->{'_posselsites'}}, [ $site,$aa,$pvalue,$signif ];
   return scalar @{$self->{'_posselsites'}};
}


sub get_NEB_pos_selected_sites{
   return @{$_[0]->{'_NEBposselsites'} || []};
}


sub add_NEB_pos_selected_site{
   my ($self,@args) = @_;
   push @{$self->{'_NEBposselsites'}}, [ @args ];
   return scalar @{$self->{'_NEBposselsites'}};
}




sub get_BEB_pos_selected_sites{
   return @{$_[0]->{'_BEBposselsites'} || []};
}


sub add_BEB_pos_selected_site{
   my ($self,@args) = @_;
   push @{$self->{'_BEBposselsites'}}, [ @args ];
   return scalar @{$self->{'_BEBposselsites'}};
}


sub next_tree{
   my ($self,@args) = @_;
   return $self->{'_trees'}->[$self->{'_treeiterator'}++] || undef;
}


sub get_trees{
   my ($self) = @_;
   return @{$self->{'_trees'} || []};
}


sub rewind_tree_iterator {
    shift->{'_treeiterator'} = 0;
}


sub add_tree{
   my ($self,$tree) = @_;
   if( $tree && ref($tree) && $tree->isa('Bio::Tree::TreeI') ) {
       push @{$self->{'_trees'}},$tree;
   }
   return scalar @{$self->{'_trees'}};
}


sub shape_params{
    my $self = shift;
    return $self->{'_shape_params'} = shift if @_;
    return $self->{'_shape_params'};
}


sub likelihood{
    my $self = shift;
    return $self->{'likelihood'} = shift if @_;
    return $self->{'likelihood'};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Tools::Phylo::PAML::ModelResult - A container for NSSite Model Result from PAML

=head1 VERSION

version 1.7.2

=head1 SYNOPSIS

  # get a ModelResult from a PAML::Result object
  use Bio::Tools::Phylo::PAML;
  my $paml = Bio::Tools::Phylo::PAML->new(-file => 'mlc');
  my $result = $paml->next_result;
  foreach my $model ( $result->get_NSSite_results ) {
    print $model->model_num, " ", $model->model_description, "\n";
    print $model->kappa, "\n";
    print $model->run_time, "\n";
# if you are using PAML < 3.15 then only one place for POS sites
   for my $sites ( $model->get_pos_selected_sites ) {
    print join("\t",@$sites),"\n";
   }
# otherwise query NEB and BEB slots
   for my $sites ( $model->get_NEB_pos_selected_sites ) {
     print join("\t",@$sites),"\n";
   }

   for my $sites ( $model->get_BEB_pos_selected_sites ) {
    print join("\t",@$sites),"\n";
   }

  }

=head1 METHODS

=head2 new

 Title   : new
 Usage   : my $obj = Bio::Tools::Phylo::PAML::ModelResult->new();
 Function: Builds  a new Bio::Tools::Phylo::PAML::ModelResult object
 Returns : an instance of Bio::Tools::Phylo::PAML::ModelResult
 Args    : -model_num           => model number
           -model_description   => model description
           -kappa               => value of kappa
           -time_used           => amount of time
           -pos_sites           => arrayref of sites under positive selection
           -neb_sites           => arrayref of sites under positive selection (by NEB analysis)
           -beb_sites           => arrayref of sites under positive selection (by BEB analysis)
           -trees               => arrayref of tree(s) data for this model
           -shape_params        => hashref of parameters
                                   ('shape' => 'alpha',
                    'gamma' => $g,
                    'r' => $r,
                    'f' => $f
                    )
                                    OR
                    ( 'shape' => 'beta',
                      'p' => $p,
                      'q' => $q
                     )
           -likelihood          => likelihood
           -num_site_classes    => number of site classes
           -dnds_site_classes   => hashref with two keys, 'p' and 'w'
                                   which each point to an array, each
                                   slot is for a different site class.
                                   'w' is for dN/dS and 'p' is probability

=head2 model_num

 Title   : model_num
 Usage   : $obj->model_num($newval)
 Function: Get/Set the Model number (0,1,2,3...)
 Returns : value of model_num (a scalar)
 Args    : on set, new value (a scalar or undef, optional)

=head2 model_description

 Title   : model_description
 Usage   : $obj->model_description($newval)
 Function: Get/Set the model description
           This is something like 'one-ratio', 'neutral', 'selection'
 Returns : value of description (a scalar)
 Args    : on set, new value (a scalar or undef, optional)

=head2 time_used

 Title   : time_used
 Usage   : $obj->time_used($newval)
 Function: Get/Set the time it took to run this analysis
 Returns : value of time_used (a scalar)
 Args    : on set, new value (a scalar or undef, optional)

=head2 kappa

 Title   : kappa
 Usage   : $obj->kappa($newval)
 Function: Get/Set kappa (ts/tv)
 Returns : value of kappa (a scalar)
 Args    : on set, new value (a scalar or undef, optional)

=head2 num_site_classes

 Title   : num_site_classes
 Usage   : $obj->num_site_classes($newval)
 Function: Get/Set the number of site classes for this model
 Returns : value of num_site_classes (a scalar)
 Args    : on set, new value (a scalar or undef, optional)

=head2 dnds_site_classes

 Title   : dnds_site_classes
 Usage   : $obj->dnds_site_classes($newval)
 Function: Get/Set dN/dS site classes, a hashref
           with 2 keys, 'p' and 'w' which point to arrays
           one slot for each site class.
 Returns : value of dnds_site_classes (a hashref)
 Args    : on set, new value (a scalar or undef, optional)

=head2 get_pos_selected_sites

 Title   : get_pos_selected_sites
 Usage   : my @sites = $modelresult->get_pos_selected_sites();
 Function: Get the sites which PAML has identified as under positive
           selection (w > 1).  This returns an array with each slot
           being a site, 4 values,
           site location (in the original alignment)
           Amino acid    (I *think* in the first sequence)
           P             (P value)
           Significance  (** indicated > 99%, * indicates >=95%)
 Returns : Array
 Args    : none

=head2 add_pos_selected_site

 Title   : add_pos_selected_site
 Usage   : $result->add_pos_selected_site($site,$aa,$pvalue,$signif);
 Function: Add a site to the list of positively selected sites
 Returns : count of the number of sites stored
 Args    : $site   - site number (in the alignment)
           $aa     - amino acid under selection
           $pvalue - float from 0->1 represent probability site is under selection according to this model
           $signif - significance (coded as either empty, '*', or '**'

=head2 get_NEB_pos_selected_sites

 Title   : get_NEB_pos_selected_sites
 Usage   : my @sites = $modelresult->get_NEB_pos_selected_sites();
 Function: Get the sites which PAML has identified as under positive
           selection (w > 1) using Naive Empirical Bayes.
           This returns an array with each slot being a site, 4 values,
           site location (in the original alignment)
           Amino acid    (I *think* in the first sequence)
           P             (P value)
           Significance  (** indicated > 99%, * indicates > 95%)
           post mean for w
 Returns : Array
 Args    : none

=head2 add_NEB_pos_selected_site

 Title   : add_NEB_pos_selected_site
 Usage   : $result->add_NEB_pos_selected_site($site,$aa,$pvalue,$signif);
 Function: Add a site to the list of positively selected sites
 Returns : count of the number of sites stored
 Args    : $site   - site number (in the alignment)
           $aa     - amino acid under selection
           $pvalue - float from 0->1 represent probability site is under selection according to this model
           $signif - significance (coded as either empty, '*', or '**'
           $postmean - post mean for w

=head2 get_BEB_pos_selected_sites

 Title   : get_BEB_pos_selected_sites
 Usage   : my @sites = $modelresult->get_BEB_pos_selected_sites();
 Function: Get the sites which PAML has identified as under positive
           selection (w > 1) using Bayes Empirical Bayes.
           This returns an array with each slot being a site, 6 values,
           site location (in the original alignment)
           Amino acid    (I *think* in the first sequence)
           P             (P value)
           Significance  (** indicated > 99%, * indicates > 95%)
           post mean for w (mean)
           Standard Error for w (SE)
 Returns : Array
 Args    : none

=head2 add_BEB_pos_selected_site

 Title   : add_BEB_pos_selected_site
 Usage   : $result->add_BEB_pos_selected_site($site,$aa,$pvalue,$signif);
 Function: Add a site to the list of positively selected sites
 Returns : count of the number of sites stored
 Args    : $site   - site number (in the alignment)
           $aa     - amino acid under selection
           $pvalue - float from 0->1 represent probability site is under selection according to this model
           $signif - significance (coded as either empty, '*', or '**'
           $postmean - post mean for w
           $SE       - Standard Error for w

=head2 next_tree

 Title   : next_tree
 Usage   : my $tree = $factory->next_tree;
 Function: Get the next tree from the factory
 Returns : L<Bio::Tree::TreeI>
 Args    : none

=head2 get_trees

 Title   : get_trees
 Usage   : my @trees = $result->get_trees;
 Function: Get all the parsed trees as an array
 Returns : Array of trees
 Args    : none

=head2 rewind_tree_iterator

 Title   : rewind_tree_iterator
 Usage   : $result->rewind_tree_iterator()
 Function: Rewinds the tree iterator so that next_tree can be
           called again from the beginning
 Returns : none
 Args    : none

=head2 add_tree

 Title   : add_tree
 Usage   : $result->add_tree($tree);
 Function: Adds a tree
 Returns : integer which is the number of trees stored
 Args    : L<Bio::Tree::TreeI>

=head2 shape_params

 Title   : shape_params
 Usage   : $obj->shape_params($newval)
 Function: Get/Set shape params for the distribution, 'alpha', 'beta'
           which is a hashref
           with 1 keys, 'p' and 'q'
 Returns : value of shape_params (a scalar)
 Args    : on set, new value (a scalar or undef, optional)

=head2 likelihood

 Title   : likelihood
 Usage   : $obj->likelihood($newval)
 Function: log likelihood
 Returns : value of likelihood (a scalar)
 Args    : on set, new value (a scalar or undef, optional)

=head1 FEEDBACK

=head2 Mailing lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/Support.html    - About the mailing lists

=head2 Support

Please direct usage questions or support issues to the mailing list:
I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and
reponsive experts will be able look at the problem and quickly
address it. Please include a thorough description of the problem
with code and data examples if at all possible.

=head2 Reporting bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  https://github.com/bioperl/bio-tools-phylo-paml/issues

=head1 AUTHOR

Jason Stajich <jason@bioperl.org>

=head1 COPYRIGHT

This software is copyright (c) by Jason Stajich <jason@bioperl.org>.

This software is available under the same terms as the perl 5 programming language system itself.

=cut
