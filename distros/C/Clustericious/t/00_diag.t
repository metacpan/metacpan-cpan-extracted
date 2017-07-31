use strict;
use warnings;
use Config;
use Test::More tests => 1;

# This .t file is generated.
# make changes instead to dist.ini

my %modules;
my $post_diag;

BEGIN { eval q{ use EV; } }
$modules{$_} = $_ for qw(
  Capture::Tiny
  Cpanel::JSON::XS
  Data::Rmap
  DateTime::Format::DateParse
  DateTime::Format::ISO8601
  EV
  ExtUtils::MakeMaker
  File::ReadBackwards
  File::ShareDir::Dist
  File::ShareDir::Install
  File::Which
  File::chdir
  Hash::Merge
  JSON::MaybeXS
  JSON::PP
  JSON::XS
  List::Util
  Log::Log4perl
  Log::Log4perl::Appender::TAP
  MojoX::Log::Log4perl
  Mojolicious
  Path::Class
  PerlX::Maybe
  PerlX::Maybe::XS
  PlugAuth::Lite
  Sub::Exporter
  Sub::Identify
  Term::Prompt
  Test2::Bundle::Extended
  Test2::Plugin::FauxHomeDir
  Test::Clustericious::Cluster
  Test::More
  Test::Script
  Test::Warn
  YAML::XS
  autodie
);



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

