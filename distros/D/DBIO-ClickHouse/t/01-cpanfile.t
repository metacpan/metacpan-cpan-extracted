#!/usr/bin/env perl
# t/01-cpanfile.t — every module lib/ and t/ load directly is declared in the
# cpanfile (requires, recommends or suggests), so the dependency list does not
# silently lean on what DBIO happens to pull in.

use strict;
use warnings;
use Test::More;
use File::Find ();
use Module::CoreList ();

my %declared;
{
  open my $fh, '<', 'cpanfile' or BAIL_OUT("cannot read cpanfile: $!");
  while (my $line = <$fh>) {
    $declared{$1} = 1
      if $line =~ /^\s*(?:requires|recommends|suggests)\s+['"]([\w:]+)['"]/;
  }
}
ok(scalar(keys %declared), 'cpanfile declares something');

sub is_declared {
  my ($mod) = @_;
  return 1 if $declared{$mod};
  # a module of a declared distribution (SQL::Abstract::Test via SQL::Abstract)
  return scalar grep { index($mod, "$_\::") == 0 } keys %declared;
}

my %loads;    # module => first "file:line"
my @files;
File::Find::find(
  { no_chdir => 1, wanted => sub { push @files, $_ if /\.(?:pm|pl|t)\z/ } },
  'lib', 't',
);

for my $file (sort @files) {
  open my $fh, '<', $file or BAIL_OUT("cannot read $file: $!");
  my $in_pod = 0;
  while (my $line = <$fh>) {
    if ($line =~ /^=(\w+)/) { $in_pod = $1 ne 'cut'; next }
    next if $in_pod;
    next unless $line =~ /^\s*(?:use|require)\s+([A-Za-z]\w*(?:::\w+)*)\b/;
    my $mod = $1;
    next if $mod =~ /^[a-z]\w*\z/;    # pragmas: strict, base, mro, ...
    next if $mod =~ /^DBIO(?:::|\z)/ || $mod eq 'main';
    next if Module::CoreList::is_core($mod);
    $loads{$mod} //= "$file:$.";
  }
}

for my $mod (sort keys %loads) {
  ok(is_declared($mod), "$mod (loaded at $loads{$mod}) is declared in cpanfile");
}

done_testing;
