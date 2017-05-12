use strict;
use warnings;
use Config;
use Test::More tests => 1;

# This .t file is generated.
# make changes instead to dist.ini

my %modules;
my $post_diag;

$modules{$_} = $_ for qw(
  Alien::Base
  Alien::Build
  Alien::Build::MM
  ExtUtils::MakeMaker
  Test::More
);

$post_diag = sub {
  require Alien::Nettle;
  diag "version        = ", Alien::Nettle->config('version');
  diag "cflags         = ", Alien::Nettle->cflags;
  diag "cflags_static  = ", Alien::Nettle->cflags_static;
  diag "libs           = ", Alien::Nettle->libs;
  diag "libs_static    = ", Alien::Nettle->libs_static;
  diag "bin_dir        = ", $_ for Alien::Nettle->bin_dir;
};

my @modules = sort keys %modules;

sub spacer ()
{
  diag '';
  diag '';
  diag '';
}

pass 'okay';

my $max = 1;
$max = $_ > $max ? $_ : $max for map { length $_ } @modules;
our $format = "%-${max}s %s"; 

spacer;

my @keys = sort grep /(MOJO|PERL|\A(LC|HARNESS)_|\A(SHELL|LANG)\Z)/i, keys %ENV;

if(@keys > 0)
{
  diag "$_=$ENV{$_}" for @keys;
  
  if($ENV{PERL5LIB})
  {
    spacer;
    diag "PERL5LIB path";
    diag $_ for split $Config{path_sep}, $ENV{PERL5LIB};
    
  }
  elsif($ENV{PERLLIB})
  {
    spacer;
    diag "PERLLIB path";
    diag $_ for split $Config{path_sep}, $ENV{PERLLIB};
  }
  
  spacer;
}

diag sprintf $format, 'perl ', $];

foreach my $module (@modules)
{
  if(eval qq{ require $module; 1 })
  {
    my $ver = eval qq{ \$$module\::VERSION };
    $ver = 'undef' unless defined $ver;
    diag sprintf $format, $module, $ver;
  }
  else
  {
    diag sprintf $format, $module, '-';
  }
}

if($post_diag)
{
  spacer;
  $post_diag->();
}

spacer;

