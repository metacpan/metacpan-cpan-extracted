use strict;
use CPAN::Changes;
# Load from file
my $changes = CPAN::Changes->load( 'Changes' );

# Create a new Changes file
$changes = CPAN::Changes->new(
    preamble => 'Revision history for perl module ACL::Regex'
);

# Started to use the changes stuff
my $release = CPAN::Changes::Release->new( 
    version => '0.02',
    date    => '2013-11-03',
);

$release->add_changes( { group => 'Fixes' }, 'Fixed POD documentation syntax problems' );
$release->add_changes( 'Started using Changes' );

$changes->add_release( $release );

open my $fd, ">Changes";
print $fd $changes->serialize;
