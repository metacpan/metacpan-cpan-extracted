package AI::Categorizer::Learner::SVM;
$VERSION = '0.01';

use strict;
use AI::Categorizer::Learner::Boolean;
use base qw(AI::Categorizer::Learner::Boolean);
use Algorithm::SVM;
use Algorithm::SVM::DataSet;
use Params::Validate qw(:types);
use File::Spec;

__PACKAGE__->valid_params
  (
   svm_kernel => {type => SCALAR, default => 'linear'},
  );

sub create_model {
  my $self = shift;
  my $f = $self->knowledge_set->features->as_hash;
  my $rmap = [ keys %$f ];
  $self->{model}{feature_map} = { map { $rmap->[$_], $_ } 0..$#$rmap };
  $self->{model}{feature_map_reverse} = $rmap;
  $self->SUPER::create_model(@_);
}

sub _doc_2_dataset {
  my ($self, $doc, $label, $fm) = @_;

  my $ds = new Algorithm::SVM::DataSet(Label => $label);
  my $f = $doc->features->as_hash;
  while (my ($k, $v) = each %$f) {
    next unless exists $fm->{$k};
    $ds->attribute( $fm->{$k}, $v );
  }
  return $ds;
}

sub create_boolean_model {
  my ($self, $positives, $negatives, $cat) = @_;
  my $svm = new Algorithm::SVM(Kernel => $self->{svm_kernel});
  
  my (@pos, @neg);
  foreach my $doc (@$positives) {
    push @pos, $self->_doc_2_dataset($doc, 1, $self->{model}{feature_map});
  }
  foreach my $doc (@$negatives) {
    push @neg, $self->_doc_2_dataset($doc, 0, $self->{model}{feature_map});
  }

  $svm->train(@pos, @neg);
  return $svm;
}

sub get_scores {
  my ($self, $doc) = @_;
  local $self->{current_doc} = $self->_doc_2_dataset($doc, -1, $self->{model}{feature_map});
  return $self->SUPER::get_scores($doc);
}

sub get_boolean_score {
  my ($self, $doc, $svm) = @_;
  return $svm->predict($self->{current_doc});
}

sub save_state {
  my ($self, $path) = @_;
  {
    local $self->{model}{learners};
    local $self->{knowledge_set};
    $self->SUPER::save_state($path);
  }
  return unless $self->{model};
  
  my $svm_dir = File::Spec->catdir($path, 'svms');
  mkdir($svm_dir, 0777) or die "Couldn't create $svm_dir: $!";
  while (my ($name, $learner) = each %{$self->{model}{learners}}) {
    my $path = File::Spec->catfile($svm_dir, $name);
    $learner->save($path);
  }
}

sub restore_state {
  my ($self, $path) = @_;
  $self = $self->SUPER::restore_state($path);
  
  my $svm_dir = File::Spec->catdir($path, 'svms');
  return $self unless -e $svm_dir;
  opendir my($dh), $svm_dir or die "Can't open directory $svm_dir: $!";
  while (defined (my $file = readdir $dh)) {
    my $full_file = File::Spec->catfile($svm_dir, $file);
    next if -d $full_file;
    $self->{model}{learners}{$file} = new Algorithm::SVM(Model => $full_file);
  }
  return $self;
}

1;
__END__

=head1 NAME

AI::Categorizer::Learner::SVM - Support Vector Machine Learner

=head1 SYNOPSIS

  use AI::Categorizer::Learner::SVM;
  
  # Here $k is an AI::Categorizer::KnowledgeSet object
  
  my $l = new AI::Categorizer::Learner::SVM(...parameters...);
  $l->train(knowledge_set => $k);
  $l->save_state('filename');
  
  ... time passes ...
  
  $l = AI::Categorizer::Learner->restore_state('filename');
  while (my $document = ... ) {  # An AI::Categorizer::Document object
    my $hypothesis = $l->categorize($document);
    print "Best assigned category: ", $hypothesis->best_category, "\n";
  }

=head1 DESCRIPTION

This class implements a Support Vector Machine machine learner, using
Cory Spencer's C<Algorithm::SVM> module.  In lots of the recent
academic literature, SVMs perform very well for text categorization.

=head1 METHODS

This class inherits from the C<AI::Categorizer::Learner> class, so all
of its methods are available unless explicitly mentioned here.

=head2 new()

Creates a new SVM Learner and returns it.  In addition to the
parameters accepted by the C<AI::Categorizer::Learner> class, the
SVM subclass accepts the following parameters:

=over 4

=item svm_kernel

Specifies what type of kernel should be used when building the SVM.
Default is 'linear'.  Possible values are 'linear', 'polynomial',
'radial' and 'sigmoid'.

=back

=head2 train(knowledge_set => $k)

Trains the categorizer.  This prepares it for later use in
categorizing documents.  The C<knowledge_set> parameter must provide
an object of the class C<AI::Categorizer::KnowledgeSet> (or a subclass
thereof), populated with lots of documents and categories.  See
L<AI::Categorizer::KnowledgeSet> for the details of how to create such
an object.

=head2 categorize($document)

Returns an C<AI::Categorizer::Hypothesis> object representing the
categorizer's "best guess" about which categories the given document
should be assigned to.  See L<AI::Categorizer::Hypothesis> for more
details on how to use this object.

=head2 save_state($path)

Saves the categorizer for later use.  This method is inherited from
C<AI::Categorizer::Storable>.

=head1 AUTHOR

Ken Williams, ken@mathforum.org

=head1 COPYRIGHT

Copyright 2000-2003 Ken Williams.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

AI::Categorizer(3), Algorithm::SVM(3)

=cut
