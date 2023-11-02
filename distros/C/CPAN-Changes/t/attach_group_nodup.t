use strict;
use warnings;

use Test::More;

# ABSTRACT: Ensure duplicates are not created with the same group name.

use CPAN::Changes::Release;
use CPAN::Changes::Group;

my $group = CPAN::Changes::Group->new( name => 'GroupName' );
$group->add_changes("This is a test");

my $dup = CPAN::Changes::Group->new( name => 'GroupName' );
$group->add_changes("This is also a test");

my $release = CPAN::Changes::Release->new();
$release->attach_group($group);
$release->attach_group($dup);

my @groups = $release->groups;

is( scalar @groups, 1, 'Only 1 group added' );

done_testing;
