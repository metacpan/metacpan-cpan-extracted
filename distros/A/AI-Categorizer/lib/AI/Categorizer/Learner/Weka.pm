package AI::Categorizer::Learner::Weka;

use strict;
use AI::Categorizer::Learner::Boolean;
use base qw(AI::Categorizer::Learner::Boolean);
use Params::Validate qw(:types);
use File::Spec;
use File::Copy;
use File::Path ();
use File::Temp ();

__PACKAGE__->valid_params
  (
   java_path => {type => SCALAR, default => 'java'},
   java_args => {type => SCALAR|ARRAYREF, optional => 1},
   weka_path => {type => SCALAR, optional => 1},
   weka_classifier => {type => SCALAR, default => 'weka.classifiers.NaiveBayes'},
   weka_args => {type => SCALAR|ARRAYREF, optional => 1},
   tmpdir => {type => SCALAR, default => File::Spec->tmpdir},
  );

__PACKAGE__->contained_objects
  (
   features => {class => 'AI::Categorizer::FeatureVector', delayed => 1},
  );

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  for ('java_args', 'weka_args') {
    $self->{$_} = [] unless defined $self->{$_};
    $self->{$_} = [$self->{$_}] unless UNIVERSAL::isa($self->{$_}, 'ARRAY');
  }
  
  if (defined $self->{weka_path}) {
    push @{$self->{java_args}}, '-classpath', $self->{weka_path};
    delete $self->{weka_path};
  }
  return $self;
}

# java -classpath /Applications/Science/weka-3-2-3/weka.jar weka.classifiers.NaiveBayes -t /tmp/train_file.arff -d /tmp/weka-machine

sub create_model {
  my ($self) = shift;
  my $m = $self->{model} ||= {};
  $m->{all_features} = [ $self->knowledge_set->features->names ];
  $m->{_in_dir} = File::Temp::tempdir( DIR => $self->{tmpdir} );

  # Create a dummy test file $dummy_file in ARFF format (a kludgey WEKA requirement)
  my $dummy_features = $self->create_delayed_object('features');
  $m->{dummy_file} = $self->create_arff_file("dummy", [[$dummy_features, 0]]);

  $self->SUPER::create_model(@_);
}

sub create_boolean_model {
  my ($self, $pos, $neg, $cat) = @_;

  my @docs = (map([$_->features, 1], @$pos),
	      map([$_->features, 0], @$neg));
  my $train_file = $self->create_arff_file($cat->name . '_train', \@docs);

  my %info = (machine_file => $cat->name . '_model');
  my $outfile = File::Spec->catfile($self->{model}{_in_dir}, $info{machine_file});

  my @args = ($self->{java_path},
	      @{$self->{java_args}},
	      $self->{weka_classifier}, 
	      @{$self->{weka_args}},
	      '-t', $train_file,
	      '-T', $self->{model}{dummy_file},
	      '-d', $outfile,
	      '-v',
	      '-p', '0',
	     );
  $self->do_cmd(@args);
  unlink $train_file or warn "Couldn't remove $train_file: $!";

  return \%info;
}

# java -classpath /Applications/Science/weka-3-2-3/weka.jar weka.classifiers.NaiveBayes -l out -T test.arff -p 0

sub get_boolean_score {
  my ($self, $doc, $info) = @_;
  
  # Create document file
  my $doc_file = $self->create_arff_file('doc', [[$doc->features, 0]], $self->{tmpdir});
  my $machine_file = File::Spec->catfile($self->{model}{_in_dir}, $info->{machine_file});

  my @args = ($self->{java_path},
	      @{$self->{java_args}},
	      $self->{weka_classifier},
	      '-l', $machine_file,
	      '-T', $doc_file,
	      '-p', 0,
	     );

  my @output = $self->do_cmd(@args);

  my %scores;
  foreach (@output) {
    # <doc> <category> <score> <real_category>
    # 0 large.elem 0.4515551620220952 numberth.high
    next unless my ($index, $predicted, $score) = /^([\d.]+)\s+(\S+)\s+([\d.]+)/;
    $scores{$predicted} = $score;
  }

  return $scores{1} || 0;  # Not sure what weka's scores represent...
}

sub categorize_collection {
  my ($self, %args) = @_;
  my $c = $args{collection} or die "No collection provided";
  
  my @alldocs;
  while (my $d = $c->next) {
    push @alldocs, $d;
  }
  my $doc_file = $self->create_arff_file("docs", [map [$_->features, 0], @alldocs]);

  my @assigned;
  
  my $l = $self->{model}{learners};
  foreach my $cat (keys %$l) {
    my $machine_file = File::Spec->catfile($self->{model}{_in_dir}, "${cat}_model");
    my @args = ($self->{java_path},
		@{$self->{java_args}},
		$self->{weka_classifier},
		'-l', $machine_file,
		'-T', $doc_file,
		'-p', 0,
               );

    my @output = $self->do_cmd(@args);

    foreach my $line (@output) {
      next unless $line =~ /\S/;
      
      # 0 large.elem 0.4515551620220952 numberth.high
      unless ( $line =~ /^([\d.]+)\s+(\S+)\s+([\d.]+)\s+(\S+)/ ) {
	warn "Can't parse line $line";
	next;
      }
      my ($index, $predicted, $score) = ($1, $2, $3);
      $assigned[$index]{$cat} = $score if $predicted;  # Not sure what weka's scores represent
      print STDERR "$index: assigned=($predicted) correct=(", $alldocs[$index]->is_in_category($cat) ? 1 : 0, ")\n"
	if $self->verbose;
    }
  }

  my $experiment = $self->create_delayed_object('experiment', categories => [map $_->name, $self->categories]);
  foreach my $i (0..$#alldocs) {
    $experiment->add_result([keys %{$assigned[$i]}], [map $_->name, $alldocs[$i]->categories], $alldocs[$i]->name);
  }

  return $experiment;
}


sub do_cmd {
  my ($self, @cmd) = @_;
  print STDERR " % @cmd\n" if $self->verbose;
  
  my @output;
  local *KID_TO_READ;
  my $pid = open(KID_TO_READ, "-|");
  
  if ($pid) {   # parent
    @output = <KID_TO_READ>;
    close(KID_TO_READ) or warn "@cmd exited $?";
    
  } else {      # child
    exec(@cmd) or die "Can't exec @cmd: $!";
  }
  
  return @output;
}

sub create_arff_file {
  my ($self, $name, $docs, $dir) = @_;
  $dir = $self->{model}{_in_dir} unless defined $dir;

  my ($fh, $filename) = File::Temp::tempfile(
					     $name . "_XXXX",  # Template
					     DIR    => $dir,
					     SUFFIX => '.arff',
					    );
  print $fh "\@RELATION foo\n\n";
  
  my $feature_names = $self->{model}{all_features};
  foreach my $name (@$feature_names) {
    print $fh "\@ATTRIBUTE feature-$name REAL\n";
  }
  print $fh "\@ATTRIBUTE category {1, 0}\n\n";
  
  my %feature_indices = map {$feature_names->[$_], $_} 0..$#{$feature_names};
  my $last_index = keys %feature_indices;
  
  # We use the 'sparse' format, see http://www.cs.waikato.ac.nz/~ml/weka/arff.html
  
  print $fh "\@DATA\n";
  foreach my $doc (@$docs) {
    my ($features, $cat) = @$doc;
    my $f = $features->as_hash;
    my @ordered_keys = (sort {$feature_indices{$a} <=> $feature_indices{$b}} 
			grep {exists $feature_indices{$_}}
			keys %$f);

    print $fh ("{",
	       join(', ', map("$feature_indices{$_} $f->{$_}", @ordered_keys), "$last_index '$cat'"),
	       "}\n"
	      );
  }
  
  return $filename;
}

sub save_state {
  my ($self, $path) = @_;

  {
    local $self->{knowledge_set};
    $self->SUPER::save_state($path);
  }
  return unless $self->{model};

  my $model_dir = File::Spec->catdir($path, 'models');
  mkdir($model_dir, 0777) or die "Couldn't create $model_dir: $!";
  while (my ($name, $learner) = each %{$self->{model}{learners}}) {
    my $oldpath = File::Spec->catdir($self->{model}{_in_dir}, $learner->{machine_file});
    my $newpath = File::Spec->catfile($model_dir, "${name}_model");
    File::Copy::copy($oldpath, $newpath);
  }
  $self->{model}{_in_dir} = $model_dir;
}

sub restore_state {
  my ($pkg, $path) = @_;
  
  my $self = $pkg->SUPER::restore_state($path);

  my $model_dir = File::Spec->catdir($path, 'models');
  return $self unless -e $model_dir;
  $self->{model}{_in_dir} = $model_dir;
  
  return $self;
}

1;

__END__

=head1 NAME

AI::Categorizer::Learner::Weka - Pass-through wrapper to Weka system

=head1 SYNOPSIS

  use AI::Categorizer::Learner::Weka;
  
  # Here $k is an AI::Categorizer::KnowledgeSet object
  
  my $nb = new AI::Categorizer::Learner::Weka(...parameters...);
  $nb->train(knowledge_set => $k);
  $nb->save_state('filename');
  
  ... time passes ...
  
  $nb = AI::Categorizer::Learner->restore_state('filename');
  my $c = new AI::Categorizer::Collection::Files( path => ... );
  while (my $document = $c->next) {
    my $hypothesis = $nb->categorize($document);
    print "Best assigned category: ", $hypothesis->best_category, "\n";
  }

=head1 DESCRIPTION

This class doesn't implement any machine learners of its own, it
merely passes the data through to the Weka machine learning system
(http://www.cs.waikato.ac.nz/~ml/weka/).  This can give you access to
a collection of machine learning algorithms not otherwise implemented
in C<AI::Categorizer>.

Currently this is a simple command-line wrapper that calls C<java>
subprocesses.  In the future this may be converted to an
C<Inline::Java> wrapper for better performance (faster running
times).  However, if you're looking for really great performance,
you're probably looking in the wrong place - this Weka wrapper is
intended more as a way to try lots of different machine learning
methods.

=head1 METHODS

This class inherits from the C<AI::Categorizer::Learner> class, so all
of its methods are available unless explicitly mentioned here.

=head2 new()

Creates a new Weka Learner and returns it.  In addition to the
parameters accepted by the C<AI::Categorizer::Learner> class, the
Weka subclass accepts the following parameters:

=over 4

=item java_path

Specifies where the C<java> executable can be found on this system.
The default is simply C<java>, meaning that it will search your
C<PATH> to find java.

=item java_args

Specifies a list of any additional arguments to give to the java
process.  Commonly it's necessary to allocate more memory than the
default, using an argument like C<-Xmx130MB>.

=item weka_path

Specifies the path to the C<weka.jar> file containing the Weka
bytecode.  If Weka has been installed somewhere in your java
C<CLASSPATH>, you needn't specify a C<weka_path>.

=item weka_classifier

Specifies the Weka class to use for a categorizer.  The default is
C<weka.classifiers.NaiveBayes>.  Consult your Weka documentation for a
list of other classifiers available.

=item weka_args

Specifies a list of any additional arguments to pass to the Weka
classifier class when building the categorizer.

=item tmpdir

A directory in which temporary files will be written when training the
categorizer and categorizing new documents.  The default is given by
C<< File::Spec->tmpdir >>.

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

AI::Categorizer(3)

=cut
