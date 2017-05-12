use strict;
use Data::Dumper;
use Crypt::Chimera::User;
use Crypt::Chimera::Cracker;
use Crypt::Chimera::World;

my $world = new Crypt::Chimera::World(
				Name	=> "Earth",
				Rounds	=> 6,
				Length	=> 20000,
					);
my $alice = new Crypt::Chimera::User(
				Name	=> "Alice",
				Remote	=> "Bob",
				World	=> $world,
				Verbose	=> 1,
					);
my $bob = new Crypt::Chimera::User(
				Name	=> "Bob",
				Remote	=> "Alice",
				World	=> $world,
				Verbose	=> 1,
					);
my $eve = new Crypt::Chimera::Cracker(
				Name	=> "Eve",
				World	=> $world,
				Verbose	=> 10,
					);

$world->run;

# $alice->huffman;
# $bob->huffman;

# my %freq = $alice->freqtable(undef, 3);
# print Dumper(\%freq);

#my %data = ( %{ $eve } );
#delete $data{World};
#print Dumper(\%data);
