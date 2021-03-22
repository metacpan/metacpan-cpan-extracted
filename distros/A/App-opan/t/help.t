use strictures 2;
use Test::More;

my $app = require "./script/opan";

my %descriptions = (
  add => qr{Imports a distribution.*MY},
  carton => qr{Starts a temporary server.*carton},
  cpanm => qr{Starts a temporary server process and runs cpanm},
  fetch => qr{Fetches 02packages.*PAN},
  init => qr{Creates a pans/ directory.*},
  merge => qr{Rebuilds the combined and nopin},
  pin => qr{Fetches the file .* pinset},
  pull => qr{Does a fetch and then a merge},
  purge => qr{Deletes all files},
  purgelist => qr{Outputs a list of all non-indexed dists in pinset and custom},
  unadd => qr{custom PAN index[\s\n]+and removes the entries},
  unpin => qr{pinset PAN index[\s\n]+and removes the entries},
);

for my $cmd (
  qw(init fetch add unadd pin unpin merge pull purgelist purge cpanm carton)
) {
  my $pkg = "App::opan::Command::${cmd}";
  like $pkg->new->usage, qr/^\s+opan $cmd.*$descriptions{$cmd}/s, "$cmd usage";
  like $pkg->new->description, $descriptions{$cmd}, "$cmd description";
  unlike $pkg->new->description, qr{[<>]}, "$cmd description without pod characters";
}

done_testing;
