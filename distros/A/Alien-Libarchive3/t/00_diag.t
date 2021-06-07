use Test2::V0 -no_srand => 1;
use Config;

eval { require 'Test/More.pm' };

# This .t file is generated.
# make changes instead to dist.ini

my %modules;
my $post_diag;

$modules{$_} = $_ for qw(
  Alien::Base
  Alien::Build
  Alien::Build::MM
  Alien::Build::Plugin::Build::SearchDep
  ExtUtils::CBuilder
  ExtUtils::MakeMaker
  FFI::CheckLib
  Path::Tiny
  Test2::V0
  Test::Alien
);

$post_diag = sub {
  foreach my $alien (qw( Alien::m4 )) {
    eval qq{ require $alien; 1 };
    next if $@;
    diag "[$alien]";
    diag "install_type   = ", $alien->install_type;
    diag "version        = ", $alien->version if defined $alien->version;
    diag "bin_dir        = ", $_ for $alien->bin_dir;
    diag "dynamic_libs   = ", $_ for $alien->dynamic_libs;
    diag '';
    diag '';
  }
  foreach my $alien (qw( Alien::Nettle Alien::xz Alien::LZO Alien::Libbz2 Alien::Libxml2 Alien::Libarchive3 )) {
    eval qq{ require $alien; 1 };
    next if $@;
    diag "[$alien]";
    diag "install_type   = ", $alien->install_type;
    diag "version        = ", $alien->version if defined $alien->version;
    diag "cflags         = ", $alien->cflags;
    diag "cflags_static  = ", $alien->cflags_static;
    diag "libs           = ", $alien->libs;
    diag "libs_static    = ", $alien->libs_static;
    diag "bin_dir        = ", $_ for $alien->bin_dir;
    diag "dynamic_libs   = ", $_ for $alien->dynamic_libs;
    diag '';
    diag '';
  }
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

diag sprintf $format, 'perl', "$] $^O $Config{archname}";

foreach my $module (sort @modules)
{
  my $pm = "$module.pm";
  $pm =~ s{::}{/}g;
  if(eval { require $pm; 1 })
  {
    my $ver = eval { $module->VERSION };
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

done_testing;

