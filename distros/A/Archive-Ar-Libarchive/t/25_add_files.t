use strict;
use warnings;
use Test::More tests => 2;
use Archive::Ar::Libarchive;
use File::Temp qw( tempdir );
use File::Spec;

my $dir = tempdir( CLEANUP => 1 );

note "dir = $dir";

my %data = (
  foo => "something completely different",
  bar => "something the same",
  baz => "Truck, not monkey",
);

foreach my $name (keys %data)
{
  open(my $fh, '>', File::Spec->catfile($dir, "$name.txt"));
  print $fh $data{$name};
  close $fh;
}

subtest 'add list' => sub {
  plan tests => 4;

  my $ar = Archive::Ar::Libarchive->new;
  
  my $count = $ar->add_files(map { File::Spec->catfile($dir, "$_.txt") } qw( foo bar baz ));
  is $count, 3, 'add_files';
  
  foreach my $name (qw( foo bar baz ))
  {
    is $ar->get_content("$name.txt")->{data}, $data{$name}, "data for $name";
  }
};

subtest 'add ref' => sub {
  plan tests => 4;

  my $ar = Archive::Ar::Libarchive->new;
  
  my $count = $ar->add_files(map { File::Spec->catfile($dir, "$_.txt") } qw( foo bar baz ));
  is $count, 3, 'add_files';
  
  foreach my $name (qw( foo bar baz ))
  {
    is $ar->get_content("$name.txt")->{data}, $data{$name}, "data for $name";
  }
};
