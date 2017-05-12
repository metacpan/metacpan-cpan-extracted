use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;

use Getopt::Long;

GetOptions( 'userid=s' => \my $userid, 'password=s' => \my $password );

my $datafile = File::Spec->catfile( t => 'live.data' );
if ( $userid && $password && open my $fh, '>', $datafile )
{
  print {$fh} "$userid\n$password\n";
  close $fh;
  warn <<'EOT';
Live tests enabled.  Warning: These will add a task to your Toodledo
account (and delete it).  The tests will fail if you have no folders
in your Toodledo account, or if Toodledo cannot be contacted, or if
something else adds a task while the test is being conducted.
EOT
}
else
{
  warn "No live tests\n";
}

# Non-numeric version numbers in Extutils::MakeMaker :-(
no warnings 'numeric';
WriteMakefile(
    NAME                => 'App::Toodledo',
    AUTHOR              => 'Peter J. Scott <cpan@psdt.com>',
    VERSION_FROM        => 'lib/App/Toodledo.pm',
    ABSTRACT_FROM       => 'lib/App/Toodledo.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'       => 0,
        'Test::NoWarnings' => 0,
        'Test::Exception'  => 0,
        'Test::MockModule' => 0,
        'Test::MockObject' => 1.20110612,
	'Log::Log4perl'    => 1.36,
        'Moose'            => 2.0801,
        'MooseX::Method::Signatures' => 0.37,
	'MooseX::ClassAttribute'     => 0.27,
        'JSON'           => 0,
	'LWP::UserAgent' => 0,
	'URI::Encode'    => 0,
	'Package::Stash' => 0.31,
        'Digest::MD5'    => 0,
        'Date::Parse'    => 0,
        'File::HomeDir'  => 0,
        'YAML'           => 0.79,
	'common::sense'  => 3.6,
        'MooseX::Log::Log4perl' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Toodledo-*' },
);
