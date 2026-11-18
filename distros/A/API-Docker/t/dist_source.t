#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Cwd qw( abs_path );
use Module::Runtime qw( require_module );

# `prove -l` PREPENDS "lib" to @INC, it does not replace it: an installed copy
# of this distribution stays reachable right behind the checkout's own lib/. A
# module deleted from lib/ can keep "loading" from that copy, and t/basic.t's
# use_ok stays green. The installed copy reports the same $VERSION as the
# checkout, so a version check would not see the substitution either.
#
# This test therefore only checks a git checkout -- the dist root itself
# carries .git. It requires every .pm file the checkout ships under lib/ (what
# is on disk and what `git` still tracks there, even if the file is gone from
# disk), then asserts that whatever ended up in %INC for API::Docker::* came
# from a file under lib/. Anything else fails by name: a stale installed copy,
# a leftover blib/ picked up ahead of lib/, a module gone from disk but still
# tracked (or still referenced by another module this test loads).
#
# Outside a checkout (an unpacked tarball built by `make`, `dzil test`) the
# modules legitimately load from blib/lib, so the file skips there.
#
# API::Docker::{Container,Image,Network,Volume,Plugin,Secret,Config} are
# legacy CPAN-compatibility stubs: they ship under lib/ on purpose, but are
# allowed to croak on load rather than load silently, and t/basic.t
# deliberately carries no use_ok for them. A module that dies while loading
# still leaves its %INC key set, with an undef value, and Cwd::abs_path(undef)
# resolves to the current directory, which would read as a false pass. So a
# defined %INC value is what "actually loaded" means below; an undef one is
# treated as no entry at all. The question here is not "does everything
# compile" -- that is each module's own t/*.t -- only "whatever DID load, did
# it come from here".

my $dist_root = path(__FILE__)->parent->parent->realpath;
my $lib_dir   = $dist_root->child('lib');

plan skip_all => 'not a git checkout; modules load from blib/lib there'
  unless $dist_root->child('.git')->exists;

my @acceptable_roots = ($lib_dir->stringify);

my %rel_paths;   # e.g. "API/Docker/Image.pm" => 1

$lib_dir->visit(
  sub {
    my ($path) = @_;
    return unless $path->is_file && "$path" =~ /\.pm\z/;
    $rel_paths{ $path->relative($lib_dir)->stringify } = 1;
  },
  { recurse => 1 },
);

# `git ls-files` answers from the index, not the working tree, so a file
# `mv`d or `rm`d out of lib/ without also being `git rm`d still comes back --
# which is exactly the shape of check this test exists for.
if (open my $fh, '-|', 'git', '-C', "$dist_root", 'ls-files', '--', 'lib') {
  while (my $line = <$fh>) {
    chomp $line;
    $line =~ s{\Alib/}{} or next;
    $rel_paths{$line} = 1 if $line =~ /\.pm\z/;
  }
  close $fh;
}

ok(scalar(keys %rel_paths) > 0, 'found .pm files under lib/ to check')
  or diag("nothing found under $lib_dir -- is the checkout intact?");

for my $rel (sort keys %rel_paths) {
  ( my $pkg = $rel ) =~ s{\.pm\z}{};
  $pkg =~ s{/}{::}g;

  local $@;
  eval { require_module($pkg); 1 };
  # A load failure is tolerated here on purpose -- see the legacy-stub note above --
  # and is out of this test's remit either way: it is covered, if at all, by
  # that module's own test file.
}

my @checked;
for my $key (sort keys %INC) {
  next unless $key =~ m{^API/Docker(?:\.pm\z|/)};
  next unless defined $INC{$key};

  my $resolved = abs_path($INC{$key});
  $resolved = $INC{$key} unless defined $resolved;

  my $from_checkout = grep { index($resolved, "$_/") == 0 } @acceptable_roots;

  push @checked, $key;
  ok($from_checkout, "$key resolved inside this checkout")
    or diag("  $key => $resolved");
}

ok(scalar(@checked) > 0, '%INC actually carried API::Docker entries to check')
  or diag('nothing under API/Docker/ ever made it into %INC -- this test asserted nothing');

done_testing;
