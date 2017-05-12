use Module::Build;
use Config;
use File::Spec;

my $build = new Module::Build
  (
   module_name => 'AI::Categorizer',
   license => 'perl',
   requires => {
		perl                    => '5.6.0',
		Class::Container        => 0.09,
		Storable                => 0,
		Params::Validate        => 0.18,
		Statistics::Contingency => 0.06,
		Lingua::Stem            => 0.50,
		File::Spec              => 0,
	       },
   recommends => {
		  Scalar::Util          => 0,
		  Time::Progress        => 1.1,
		  Algorithm::SVM        => 0.06,
		  AI::DecisionTree      => 0.06,
		  Algorithm::NaiveBayes => 0,
		 },
   build_requires => {
		      Module::Build     => 0.20,
		     },
   create_makefile_pl => 'passthrough',
  );

my $categorizer = File::Spec->catfile('eg', 'categorizer');
if ($build->y_n("Do you want to install the $categorizer script to $Config{installscript}?", 'n')) {
  $build->scripts($categorizer);
}


$build->create_build_script;

{
  my $path = $build->prompt
    (
     "\nIf you have the Weka system installed, please specify the path\n".
     "to the 'weka.jar' file, or '-' to search CLASSPATH, or '!' to skip:",
     '!'
    );
  $build->notes(classpath => $path eq '!' ? undef : $path);
}
