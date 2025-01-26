use 5.008008;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Required to be able to use all 5 modules ...
my %requires = ( File::Basename        => 0,
                 File::Copy            => 0,
                 File::Spec            => 0,
                 File::Glob            => 0,
                 Sys::Hostname         => 0,
                 Cwd                   => 0,
                 Fred::Fish::DBUG      => 2.09,
                 Perl::OSType          => 0
               );

# These additional modules are required to run the test scripts ...
# Support for this added in $ExtUtils::MakeMaker::VERSION >= 6.55_03.
my %build = ( ExtUtils::MakeMaker => 0,
              Config              => 0,
              Test::More          => 0.88
            );

# The NAME value controls both where to install the modules as well as what
# to call the distribution when "make dist" is run!
my $prog = 'full_developer_test.pl';
my %params = ( NAME           => 'Advanced::Config',
               VERSION_FROM   => 'Config.pm',      # Finds $VERSION
               PREREQ_PM      => \%requires,
               BUILD_REQUIRES => \%build,
               PL_FILES       => { "${prog}.src" => ${prog} }
             );
unlink ( $prog );

## Add these new keywords supported since 5.005
if ( $] >= 5.005 ) {
   $params{AUTHOR}   = 'Curtis Leach <cleach at cpan dot com>';
   $params{ABSTRACT} = 'A powerfull pure perl config file manager.';
}

## An Extra Kwalitee Metric setting.
if ( $ExtUtils::MakeMaker::VERSION >= 6.31 ) {
   $params{LICENSE} = 'perl';
}

## An Extra Kwalitee Metric setting.
## The earliest release of Perl I've personally tested this module with!
## Comment out this section out if you wish to try it with an earlier release!
if ( $ExtUtils::MakeMaker::VERSION >= 6.48 ) {
   $params{MIN_PERL_VERSION} = '5.008008';      # Perl Version 5.8.8
}

optional ();

WriteMakefile ( %params );

sub optional
{
   my $sts = eval "require Date::Language";
   unless ( $sts ) {
      warn "\nIf you wish this module to parse dates in other languages besides English\n",
             "you must install the Date::Language module.  You may defer this decision\n",
             "until later if you wish!  It's not requied for a successful install.\n\n";
   }
}

