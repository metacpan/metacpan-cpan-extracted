#! perl

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.012000;

use v5.12;

use ExtUtils::MakeMaker;

my $master = 'lib/Comics.pm';
my $version = MM->parse_version($master);

WriteMakefile
(
 NAME		=> 'Comics',
 ABSTRACT_FROM  => $master,
 VERSION_FROM	=> $master,
 AUTHOR	        => 'Johan Vromans <jvromans@squirrel.nl>',
 MIN_PERL_VERSION => 5.12.0,
 INSTALLDIRS	=> 'site',
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
 },
 TEST_REQUIRES  =>
 {
  'Test::More'  => 0,
 },

 META_MERGE =>
 {
  license      => "perl_5",
  resources    =>
  {
   repository  =>
   {
    url  => 'git://github.com/sciurius/comics.git',
    web  => 'http://github.com/sciurius/comics',
    type => 'git',
   },
  },
  'meta-spec' =>
  {
   version => '2',
   url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
  },
 },
);

