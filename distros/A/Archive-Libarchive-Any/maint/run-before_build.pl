use strict;
use warnings;
use v5.10;
use Path::Class qw( file dir );

exit if $ENV{TRAVIS_BUILD_ID};
exit unless $ENV{USER} eq 'ollisg';
exit;

do { # import from inc
  foreach my $basename (qw( constants.txt functions.txt ))
  {
    my $source = file(__FILE__)->parent->parent->parent->parent->file('Archive-Libarchive-XS', 'inc', $basename);
    my $dest   = file(__FILE__)->parent->parent->file($basename);
    say $source->absolute;
    $dest->spew(scalar $source->slurp);
  }
};

do { # import examples from XS version

  my $source = file(__FILE__)->parent->parent->parent->parent->subdir('Archive-Libarchive-XS')->subdir('example');

  die "first checkout Archive::Libarchive::XS" unless -d $source;

  my $dest = file(__FILE__)->parent->parent->parent->subdir('example');

  foreach my $example ($source->children)
  {
    say $example->absolute;
    if($example->basename =~ /\.pl$/)
    {
      my $pl = join '', map { s/XS/Any/g; $_ } $example->slurp;
      $dest->file($example->basename)->spew($pl);
    }
    else
    {
      $dest->file($example->basename)->spew(scalar $example->slurp);
    }
  }
};

do { # import tests from XS version
  my $source = file(__FILE__)->parent->parent->parent->parent->subdir('Archive-Libarchive-XS')->subdir('t');
  my $dest = file(__FILE__)->parent->parent->parent->subdir('t');

  foreach my $archive ($source->children)
  {
    next if $archive->is_dir;
    next unless $archive->basename =~ /^foo\./;
    say $archive->absolute;
    $dest->file($archive->basename)->spew(scalar $archive->slurp);
  }

  foreach my $test ($source->children)
  {
    next if $test->is_dir;
    next unless $test->basename =~ /^common_.*\.t$/;
    say $test->absolute;
    my $pl = join '', map { s/XS/Any/g; $_ } $test->slurp;
    $dest->file($test->basename)->spew($pl);
  }
};
