use strict;
use warnings;

use feature ":all";
use Data::JPack;
use Test::More;

use File::Path qw<make_path remove_tree>;
use File::Basename qw<dirname basename>;

# Test file db structures
my $html_container="_data/index.html";
my $html_root=dirname $html_container;

#make_path $html_root;

my $jpack=Data::JPack->new(html_container=>$html_container);
my $set_name=$jpack->next_set_name();
say STDERR "Next set name is $set_name";

# expect a sequence of 0s
ok $set_name =~ /0{32}/, "Set name ok";

my $name=$jpack->next_file_name;
say STDERR "Next File name is $name";
ok $name =~ m|0{32}/0{32}|, "set/file name ok";



# Test file name with a forced dir/set name
$set_name=$jpack->next_set_name(4);
$name=$jpack->next_file_name();
say STDERR "Forced Next File name is $name";
ok $name =~ m|0{31}4/0{32}|, "set/file name ok";

# Cleanup
remove_tree $jpack->html_root;
done_testing;
1;
