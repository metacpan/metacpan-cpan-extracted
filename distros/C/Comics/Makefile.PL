#! perl

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.012000;

use v5.12;

use ExtUtils::MakeMaker;

my $master = 'lib/Comics/Version.pm';
my $version = MM->parse_version($master);
$master =~ s;/Version;;;

WriteMakefile
(
 NAME		=> 'Comics',
 ABSTRACT_FROM  => $master,
 VERSION	=> $version,
 AUTHOR	        => 'Johan Vromans <jvromans@squirrel.nl>',
 MIN_PERL_VERSION => 5.12.0,
 INSTALLDIRS	=> 'site',
 LICENSE	=> 'perl_5',
 EXE_FILES	=> [ 'script/collect' ],
 PL_FILES	=>
 {
  'script/pp.PL' => [ 'script/collect' ]
 },

 PREREQ_PM      =>
 {
  'Image::Info'	      => 0,
  'LWP::UserAgent'    => 0,
  'JSON'	      => 0,
  'HTTP::Cookies'     => 0,
  'Digest::MD5'	      => 0,
  'File::LoadLines'   => 1.044,
  'ExtUtils::MakeMaker' => 6.46,
 },
 TEST_REQUIRES  =>
 {
  'Test::More'  => 0,
 },

 META_MERGE =>
 {
  resources    =>
  {
   repository => 
   {
     type => 'git',
     web  => 'https://github.com/sciurius/comics',
     url  => 'https://github.com/sciurius/comics.git',
   },
   bugtracker => "https://github.com/sciurius/comics/issues",
  },
  provides => {
	       "Comics" => { file => "lib/Comics.pm",
			     version => $version },
	      },
  no_index =>
  {
   file => [
	    "lib/LWP/UserAgent/Custom.pm",
	   ],
  },
  'meta-spec' =>
  {
   version => '2',
   url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
  },
 },
);

