use strict;
use FindBin;
use Test::More;

require q[./t/helper.pm];

foreach my $src (
    qw[
      https://github.com/p5sagit/Try-Tiny.git
      https://github.com/p5sagit/Try-Tiny.git@v0.24
      https://github.com/p5sagit/Try-Tiny/archive/v0.24.zip
    ],
  )
{
  like($src, App::MechaCPAN::url_re(), "$src is like a url");
}

my %git_srcs = (
      'git://git@github.com/p5sagit/Try-Tiny.git' => [ qw[git://git@github.com/p5sagit/Try-Tiny.git] ],
      'git://git@github.com/p5sagit/Try-Tiny.git@v0.24' => [ qw[git://git@github.com/p5sagit/Try-Tiny.git v0.24] ],
  );
foreach my $src (sort keys %git_srcs)
{
  like($src, App::MechaCPAN::git_re(), "$src is like a git_url");
  like($src, App::MechaCPAN::git_extract_re(), "$src can be extracted");

  my @exparts = @{ $git_srcs{$src} };
  my @parts = $src =~ App::MechaCPAN::git_extract_re();

  is(@parts[0], @exparts[0], 'git url is correct');
  is(@parts[1], @exparts[1], 'git branch is correct');
}

done_testing;
