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

sub subroutines {
  my ($path) = @_;

  my $re = 'fun|method|sub';

  my %ignore = map +($_, 1), qw(
    BUILD
    BUILDARGS
    import
  );

  my @files = map { /^(?:$re)\s+([a-zA-Z]\w+).*/ } source("lib/$path.pm");

  return (grep !$ignore{$_}, @files);
}

sub test {
  my (@list) = @_;

  test_subroutines($_, [subroutines($_)]) for @list;

  return 1;
}

sub test_exists {
  my ($path, $subs) = @_;

  ok -f "t/0.90/can/$path/$_.t", "t/0.90/can/$path/$_.t exists" for @$subs;

  return;
}

sub test_sections {
  my ($path, $subs) = @_;

  for my $file (grep -f, map "t/0.90/can/$path/$_.t", @$subs) {
    my $headings = { map +($_, $_), headings($file) };

    ok exists $headings->{name}, "$file has pod name-section";
    ok exists $headings->{usage}, "$file has pod usage-section";
    ok exists $headings->{description}, "$file has pod description-section";
    ok exists $headings->{signature}, "$file has pod signature-section";
    ok exists $headings->{type}, "$file has pod type-section";
  }

  return;
}

sub test_subroutines {
  my ($path, $subs) = @_;

  test_exists($path, $subs);
  test_sections($path, $subs);

  return;
}

sub type {
  my ($file, $type) = @_;

  my @parts = split(/\./, $file, 2);

  return $parts[1] eq $type ? ($parts[0]) : ();
}

# TESTING

test(mods(@list)) and done_testing;
