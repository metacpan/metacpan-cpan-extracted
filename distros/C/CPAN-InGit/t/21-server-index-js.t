use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use File::Spec;
use v5.36;

my ($node)= grep -f $_ && -x $_, map File::Spec->catfile($_, 'node'), File::Spec->path;
plan skip_all => 'Node.js is needed to test the index JavaScript' unless $node;

# These tests use modern Node APIs, including AbortController and node: imports.
# Old or unusable installations should not cause CPAN Testers failures.
my $node_version;
if (open my $version_fh, '-|', $node, '--version') {
   $node_version= <$version_fh>;
   undef $node_version unless close $version_fh;
}
plan skip_all => 'Node.js 18 or newer is needed to test the index JavaScript'
   unless defined $node_version && $node_version =~ /^v(\d+)\./ && $1 >= 18;

is( system($node, "$FindBin::Bin/js/cpan-cves.cjs", "$FindBin::Bin/../share/public/cpan_cves.js"),
   0, 'CPANSA feed and Perl version matching' );
is( system($node, "$FindBin::Bin/js/server-index.cjs", "$FindBin::Bin/../share/public/archive_tree_index.js",
      "$FindBin::Bin/../share/public/cpan_cves.js"),
   0, 'browser pagination and filtering behavior' );
done_testing;
