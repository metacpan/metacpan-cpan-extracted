##-*- Mode: CPerl -*-
use strict;
use warnings;
use Alien::Base::ModuleBuild;

##-- we don't expect this package to build anywhere but linux (RT #124451)
die("cowardly refusing to build on non-linux system; edit Build.PL and try again!") if ($^O !~ /linux/i);

##-- minimum installed ddc version (for 'alien_version_check')
my $min_ddc_version = "2.2.8";

##======================================================================
my $class = Alien::Base::ModuleBuild->subclass
    (
     class => 'My::Builder',
     code => q{
       sub alien_extract_archive {
	 my ($self, $archive) = @_;
	 print "Extracting Archive ... ";
	 my $ae = Archive::Extract->new( archive => $archive, type=>'tgz' );
	 $ae->extract or Carp::croak("Archive extraction failed!");
	 print "Done\n";
	 return $ae->extract_path;
       }
     },
    );

##======================================================================
my $builder = $class->new
  (
   module_name => 'Alien::DDC::Concordance',
   license => 'perl',
   configure_requires => {
			  'Alien::Base::ModuleBuild'  => '0.027', ##-- RT #112613
			  'Module::Build' => '0.38',
			 },
   test_requires => {
		     #'File::Which'   => 0,
		     'Test::More' => 0, ##-- 1.001002
		     'Text::ParseWords' => 0, ##-- 3.29
		    },
   requires => {
		'perl'        => '5.8.9',
		'Alien::Base' => '0.005',
		'Net::SSLeay' => '1.49', ##-- else https download fails with "Internal Exception at .../Alien/Base/ModuleBuild/File.pm line 28."
	       },
   dist_author => 'Bryan Jurish <moocow@cpan.org>',
   alien_name => 'ddc',
   alien_repository => {
			protocol => 'https', ##-- RT #129102
			host     => 'sourceforge.net',
			##--
			#location => 'projects/ddc-concordance/files/ddc-concordance/2.0/',
			#pattern  => qr{/ddc-([\d\.\-]+)\.tar\.gz\b},
			##--
			location => 'projects/ddc-concordance/files/latest/',
			exact_filename => 'download',
		       },
   alien_version_check => "%{pkg_config} --atleast-version ${min_ddc_version} %n && %{pkg_config} --modversion %n",
   alien_build_commands => [
			    ##-- RT #129101: jemalloc causes segfaults on fedora 28?
			    '%c --prefix=%s --enable-shared --enable-static --disable-jemalloc',
			    'make AM_MAKEFLAGS=-j4',
			   ],
   ##
   alien_isolate_dynamic => 0, ##-- 'share'-mode builds don't work for Moot module with alien_isolate_dynamic=>1
   ##
   #sign => 1,
   #meta_merge => { ... },
   ##
   create_readme => 1,
  );
$builder->create_build_script;

