use strict;
use warnings;
use Config;
use Test::More tests => 1;

# This .t file is generated.
# make changes instead to dist.ini

my %modules;
my $post_diag;

$modules{$_} = $_ for qw(
  Alien::Libarchive::Installer
  Alien::bz2::Installer
  File::ShareDir
  Module::Build
  Test::More
);

$post_diag = sub
{
  eval {
    require Alien::Libarchive;
    my $alien = Alien::Libarchive->new;
    diag 'libarchive';
    diag '  cflags       : ', join ' ', $alien->cflags;
    diag '  libs         : ', join ' ', $alien->libs;
    diag '  install_type : ', $alien->install_type;
    diag '  dlls         : ', (eval { $alien->dlls } || 'not found');
    diag '  version      : ', (eval { $alien->version } || 'unknown');
  };
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

