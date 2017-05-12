#!perl -w
require 5.008006;
use ExtUtils::MakeMaker;

# Do our own prerequisite checking here. A lot of this
# code was borrowed from the Makefile.PL supplied with
# Net-FTPServer


my %modules = (
     'Bio::Perl'                => { status => "required" },
     'GO::Parser'               => { status => "required" }, 
     'REST::Client'             => { status => "required" }, 
     'DBD::CSV'                 => { status => "required" }, 
     'String::Approx'           => { status => "required" },
     'List::Util'               => { status => "required" }, 
     'File::Glob'               => { status => "required" }, 
     'Carp'                     => { status => "required" }, 
     'Bio::EnsEMBL::Registry'   => 
     { 
          status   => "required",
          version  => 0,
          message  => 
          "Bio::EnsEMBL::Registry could not be found.\n". 
          "This means either the Ensembl API is not present,\n". 
          "or the environment has not been set up properly.\n".
          "Please follow instructions on README file to install\n". 
          "and set up the Ensembl API before continuing.\n"
     },  
     'Getopt::Long' => 
     {
          status   => "recommended",
          version  => "2.38",
          message  => 
          "Getopt::Long is missing. This module is required if you want to\n".
          "to run the example scripts contained in the scripts/Code directory.\n"
     },
     'Graph' => 
     {
          status   => "recommended",
          version  => "0.94",
          message  => 
          "Graph::Undirected is missing. This module is required if you want to\n".
          "to compute a conservation score for each putative Protein-Protein\n".
          "Interaction obtained.\n"
     },
     'Data::PowerSet' =>
     {
          status   => "recommended",
          version  => "0.05",
          message  =>
          "Data::PowerSet is missing. This module is required if you want to\n".
          "to compute a conservation score for each putative Protein-Protein\n".
          "Interaction obtained.\n"
     },
     'URI::Escape' =>
     {
          status   => "recommended",
          version  => "1.53",
          message  =>
          "URI::Escape is missing. This module is required if you want to\n".
          "to compute a conservation score for each putative Protein-Protein\n".
          "Interaction obtained.\n"
     },
     'Algorithm::Combinatorics' =>
     {
          status   => "recommended",
          version  => "0.25",
          message  =>
          "Algorithm::Combinatorics is missing. This module is required if you want to\n".
          "to compute a conservation score for each putative Protein-Protein\n".
          "Interaction obtained.\n"
     }
);

$| = 1;

# Check for modules.

my $missing_recommended_modules = 0;
my $missing_required_packages = 0;

foreach (sort keys %modules){
     print "Checking for $modules{$_}{status} ";
     print "module $_ ";
     print ">= $modules{$_}{version} " if $modules{$_}{version};
     print "... ";

     my $eval = "require $_; ";
     $eval .= "$_->VERSION >= $modules{$_}{version}" if $modules{$_}{version};

     my $r = eval $eval;
     
     if ($@ || !$r){
          $missing_recommended_modules++ if $modules{$_}{status} eq "recommended";;
	      $missing_required_packages++ if $modules{$_}{status} eq "required";
          
          print "not found.\n\n";
          
          if (exists $modules{$_}{package}){
	         print
	              "This module is provided by the $modules{$_}{package} ",
	              "package.\n\n";
          }
          
          sleep 1;

          if (exists $modules{$_}{message}){
               print "*** ", $modules{$_}{message}, "\n";
               sleep 5;
          }
     }else{
          print "ok.\n";
     }
}

print "\n";

if ($missing_recommended_modules){
     print <<EOT;
Obtain missing modules from CPAN [http://www.cpan.org/].

EOT
     sleep 2;
}

if ($missing_required_packages){
    print <<EOT;
Required modules/packages are missing. Install these first.

EOT
    exit 0;
}


WriteMakefile(
    NAME              => 'Bio::Homology::InterologWalk',
    VERSION_FROM      => 'lib/Bio/Homology/InterologWalk.pm', # finds $VERSION
    PREREQ_PM         => {
		        Getopt::Long               => 0,
		        List::Util                 => 0,
                File::Glob                 => 0,
                Carp                       => 0			

	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Bio/Homology/InterologWalk.pm', # retrieve abstract from module
       AUTHOR         => 'Giuseppe Gallone <ggallone@cpan.org>') : ()),
);


__END__
