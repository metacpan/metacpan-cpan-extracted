use 5.014;

use strict;
use warnings;

use Cwd;
use File::Basename;
use File::Find;
use File::Spec::Functions ':ALL';
use Test::More;

my @list;

my $this = $0;
my $home = getcwd;
my $here = dirname $this;
my $libs = join '/', $home, 'lib';
my $file = sub { push @list, $File::Find::name if -f };

find $file, $libs;

# SETUP

sub files {
  my (@files) = @_;

  return (map abs2rel($_, $libs), sort(@files));
}

sub headings {
  my ($file) = @_;

  my $re = 'head1';

  return (map { /^=(?:$re\s+)?(\w+)/ } source($file));
}

sub mods {
  my (@files) = @_;

  return (map type($_, 'pm'), files(@files));
}

sub pods {
  my (@files) = @_;

  return (map type($_, 'pod'), files(@files));
}

sub source {
  my ($file) = @_;

  open my $fh, '<', "$file" or die "Can't open $file $!";

  return (map { chomp; $_ } (<$fh>));
}

sub test {
  my (@list) = @_;

  test_modules($_) for @list;

  return 1;
}

sub test_exists {
  my ($path) = @_;

  ok -f "t/0.90/use/$path.t", "t/0.90/use/$path.t exists";

  return;
}

sub test_modules {
  my ($path) = @_;

  test_exists($path);
  test_sections($path);

  return;
}

sub test_sections {
  my ($path) = @_;

  my $file = "t/0.90/use/$path.t";

  return unless -f $file;

  my $headings = { map +($_, $_), headings($file) };

  ok exists $headings->{name}, "$file has pod name-section";
  ok exists $headings->{abstract}, "$file has pod abstract-section";
  ok exists $headings->{synopsis}, "$file has pod synopsis-section";
  ok exists $headings->{description}, "$file has pod description-section";

  return;
}

sub type {
  my ($file, $type) = @_;

  my @parts = split(/\./, $file, 2);

  return $parts[1] eq $type ? ($parts[0]) : ();
}

# TESTING

test(mods(@list)) and done_testing;
