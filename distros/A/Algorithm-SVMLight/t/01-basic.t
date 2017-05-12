
use strict;
use vars qw($TODO);
use Test::More tests => 28 ;
BEGIN { use_ok('Algorithm::SVMLight') };

use File::Spec;

#########################

my $s = new Algorithm::SVMLight;
$s->add_instance_i( 1, "My Document", [3,9], [2.7, 1234]);
$s->add_instance_i(-1, "My Document2", [3,5,7], [0.7, -1234, 3.5]);
is ($s->num_features, 9, "Nine vocabulary elements");
is ($s->num_instances, 2, "Two documents");

$s->train;
ok $s->is_trained, "Train model";

my $model_file = File::Spec->catfile("t", "model.txt");
$s->write_model($model_file);
ok -e $model_file, "Write model file";

{
  # See whether we can read our written file
  my $s2 = new Algorithm::SVMLight;
  $s2->read_model($model_file);
  ok $s2->is_trained, "Re-read model should already be trained";
  is $s2->num_features, 9, "Nine vocabulary elements";
  is $s2->num_instances, 2, "Two documents";
}

{
  # Try again with named features
  my $s = new Algorithm::SVMLight;
  $s->add_instance(label => 1,  attributes => {foo => 2.7, bar => 1234});
  $s->add_instance(label => -1, attributes => {foo => 0.7, duck => -1234, goose => 3.5});
  my $features = $s->{features};

  $s->train;

  1 while unlink $model_file;
  $s->write_model($model_file);
  ok -e $model_file, "Write model file";

  # See whether we can read our written file
  my $s2 = new Algorithm::SVMLight;
  $s2->read_model($model_file);
  is_deeply $s2->{features}, $s->{features}, "Feature indices should be preserved";
}

{
  # Test add_instance
  my $s = new Algorithm::SVMLight;
  $s->add_instance( attributes => _hash(qw(sheep very valuable farming)),
		    label => -1 );
  is $s->num_features, 4;
  is $s->feature_names, 4;

  $s->add_instance( attributes => _hash(qw(farming requires many kinds animals)),
		    label => -1 );
  is $s->num_features, 8;
  is $s->feature_names, 8;

  $s->add_instance( attributes => _hash(qw(vampires drink blood vampires may staked)),
		    label => 1 );
  is $s->num_features, 13;
  is $s->feature_names, 13;

  $s->add_instance( attributes => _hash(qw(vampires cannot see their images mirrors)),
		    label => 1 );
  is $s->num_features, 18;
  is $s->feature_names, 18;

  $s->train;
  ok $s->is_trained, "Train model";

  my $result = $s->predict(attributes => _hash(qw(sheep sheep farming animals)));
  cmp_ok($result, '<', 0);

  $result = $s->predict(attributes => _hash(qw(vampires mirrors blood)));
  cmp_ok($result, '>', 0);
}


{
  # Test read_instances()

  my $docfile = File::Spec->catfile("t", "docs.txt");
  open my($fh), "> $docfile" or die "Can't write $docfile: $!";
  print $fh <<EOF;
1 10:0.43 13:0.12 9284:0.2 # Doc1
-1 5:0.33 13:0.12 9280:0.4 # Doc2
1 12:0.23 13:0.02 9281:0.2 # Doc3
EOF
  close $fh;
  ok -e $docfile, "Wrote document file";

  my $s = new Algorithm::SVMLight;
  $s->read_instances($docfile);
  is ($s->num_instances, 3, "Three documents read");
  is ($s->num_features, 9284, "9284 vocab elements");
}

{
  # Test constructor parameters
  my $s = Algorithm::SVMLight->new(type => 3, # Ranking
				   kernel_type => 2, # RBF
				   rbf_gamma => 2, 
				  );
  is $s->get_type, 3;
  is $s->get_kernel_type, 2;
  is $s->get_rbf_gamma, 2;


  # Test constructor death
  eval { Algorithm::SVMLight->new(bad_param => 1) };
  like $@, qr{unknown}i;
}


######################################
sub _hash { my %h; $h{$_}++ for @_; \%h }
