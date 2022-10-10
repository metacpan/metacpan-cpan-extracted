use Test2::V0 -no_srand => 1;
use Config;

eval { require 'Test/More.pm' };

# This .t file is generated.
# make changes instead to dist.ini

my %modules;
my $post_diag;

$modules{$_} = $_ for qw(
  ExtUtils::MakeMaker
  FFI::C::File
  FFI::C::Stat
  FFI::CheckLib
  FFI::Platypus
  FFI::Platypus::Type::Enum
  FFI::Platypus::Type::PtrObject
  File::chdir
  Path::Tiny
  Ref::Util
  Sub::Identify
  Term::Table
  Test2::API
  Test2::Tools::MemoryCycle
  Test2::V0
  Test::Archive::Libarchive
  Test::Script
);

$post_diag = sub {
  require Archive::Libarchive::Lib;
  diag "lib = $_" for Archive::Libarchive::Lib->lib;
  spacer();
  eval {
    require Archive::Libarchive;
    require Term::Table;
    my %v = Archive::Libarchive->versions;
    my $t = Term::Table->new( header => ['component','version'], rows => [ map { [$_,$v{$_}] } sort keys %v ] );
    diag join "\n", $t->render;
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

