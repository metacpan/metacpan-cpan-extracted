use Test2::V0 -no_srand => 1;
use Config;

eval q{ require Test::More };

# This .t file is generated.
# make changes instead to dist.ini

my %modules;
my $post_diag;

$modules{$_} = $_ for qw(
  Archive::Extract
  CPAN::ReleaseHistory
  Capture::Tiny
  ExtUtils::MakeMaker
  File::Copy::Recursive
  File::chdir
  Git::Wrapper
  HTTP::Date
  HTTP::Tiny
  IPC::System::Simple
  JSON::PP
  Path::Class
  PerlX::Maybe
  PerlX::Maybe::XS
  Sort::Versions
  Test2::API
  Test2::Plugin::FauxHomeDir
  Test2::V0
  URI
  URI::file
);

$post_diag = sub {
  require Git::Wrapper;
  diag "git version = ", Git::Wrapper->new('.')->version;
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

foreach my $module (sort @modules)
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

done_testing;
