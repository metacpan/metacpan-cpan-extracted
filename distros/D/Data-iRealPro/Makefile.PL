#! perl

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.010000;

# EU::MM 6.5503 is the first version to understand *_REQUIRES.
use ExtUtils::MakeMaker 6.5503;

my $master = 'lib/Data/iRealPro.pm';
#my $version = '1.011_001';
my $version = MM->parse_version($master);

WriteMakefile
(
 NAME		=> 'Data::iRealPro',
 ABSTRACT_FROM  => $master,
 VERSION	=> "$version",
 AUTHOR	        => 'Johan Vromans <jvromans@squirrel.nl>',

 INSTALLDIRS	=> 'site',
 EXE_FILES	=> [ 'script/irealcvt' ],
 PL_FILES	=> {
		    'script/pp.PL' => [ 'script/irealcvt' ]
		   },

 PREREQ_PM      => {
		    'PDF::API2'      => 2.026,
		    'Font::TTF'      => 1.06,
		    'Data::Struct'   => 1.701,
		    'Text::CSV_XS'   => 1.19,
		    'JSON::PP'	     => 2.27300,
		    'HTML::Entities' => 3.69,
		    'App::Packager'  => 1.430,
		    $ENV{DATA_IREALPRO_MUSICXML} ? ( 'XML::LibXML' => 2.0132 ) : (),
		   },
 BUILD_REQUIRES  => {
		    'Test::More'   => 1.001014,
		   },

 MIN_PERL_VERSION => '5.010001',
 LICENSE => 'perl',
 META_MERGE => {
     'meta-spec' => { version => 2 },
     resources        => {
	 repository => {
		type => 'git',
		url  => "https://github.com/sciurius/perl-Data-iRealPro.git",
		web  => "https://github.com/sciurius/perl-Data-iRealPro",
	 },
	 bugtracker => "https://github.com/sciurius/perl-Data-iRealPro/issues",
     },
     provides => {
	 irealcvt => { file => "script/irealcvt",
		       version => $version },
	 "Data::iRealPro"
		  => { file => "lib/Data/iRealPro.pm",
		       version => $version },
     },
     no_index => {
         directory => [
	    "lib/Data/iRealPro",
	 ],
     },
 },

);

1;
