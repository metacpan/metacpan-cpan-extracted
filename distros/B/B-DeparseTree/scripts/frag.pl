use rlib '../lib';

use B::Deparse;
use B::DeparseTree;
use B::DeparseTree::Fragment;

# Change this or comment it out
# use B::DeparseTree::P522;

use File::Basename qw(dirname basename); use File::Spec;
use strict; use warnings;

use constant data_dir => File::Spec->catfile(dirname(__FILE__));

use Getopt::Long;
my ($show_tree, $show_orig, $show_fragments) = (0, 1, 0);
GetOptions ("tree|t" => \$show_tree,
	    "frag|f" => \$show_fragments,
	    "orig|o" => \$show_orig)
    or die("Error in command line arguments\n");

my $short_name = $ARGV[0] || 'bug.pm';
my $test_data = File::Spec->catfile(data_dir, $short_name);
require $test_data;


my $deparse_tree = B::DeparseTree->new();
my $deparse_orig = B::Deparse->new();
$deparse_tree->coderef2info(\&bug);
my $orig_text;
$orig_text = $deparse_orig->coderef2text(\&bug);
if ($show_orig) {
    print $orig_text, "\n";
    print '-' x 50, "\n";
}

my $tree_text = $deparse_tree->coderef2text(\&bug);
if ($tree_text eq $orig_text) {
    print "Same as above\n";
} else {
    print $tree_text, "\n";
}

if ($show_fragments) {
    B::DeparseTree::Fragment::dump($deparse_tree);
}

if ($show_tree) {
    my $svref = B::svref_2object(\&bug);
    my $x =  $deparse_tree->deparse_sub($svref);
    B::DeparseTree::Fragment::dump_tree($deparse_tree, $x);
}
