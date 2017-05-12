#!/usr/bin/env perl

use v5.10;
use strictures 2;
use Path::Tiny;
use Digest::MD5 'md5_hex';

my $Dir = path(shift @ARGV || 'share/etc');
die "Not found: '$Dir'" unless $Dir->exists;
die "Not a directory: '$Dir'" unless $Dir->is_dir;

my $Manifest = path(shift @ARGV || 'share/etc/Manifest');

say "Compiling files from etcdir '$Dir'";

my $iter = $Dir->iterator(
  +{ recurse => 1, follow_symlinks => 0 }
);

my $accum = '';

ETC: while ( my $path = $iter->() ) {
  my $rel = $path->relative($Dir);
  next ETC if $rel eq 'Manifest';
  say "  -> $rel";
  my $sum = $path->is_dir ? 0 : md5_hex($path->slurp_raw);
  $accum .=
    ( $path->is_dir ? "$rel ^ DIR" : "$rel ^ $sum" )
    . "\n";
}

say "Writing Manifest to '$Manifest'";
$Manifest->spew_utf8($accum);
