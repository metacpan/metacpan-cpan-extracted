#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use Path::Class qw(file);
use Tie::IxHash;

use Bio::FastParsers;


my $class = 'Bio::FastParsers::CdHit';

# perl -MData::Dumper -nle
# 'if (m/Cluster (\d+)/) { $cluster = $1; next }
# ($id,$type) = m/>(\S+)\.{3} (\*|at)/;
# $hash{$cluster}{repr} = $id if $type eq q{*};
# push @{$hash{$cluster}{memb}}, $id if $type eq q{at};
# END{ for $cluster (sort { $a <=> $b } keys %hash) {
# print $hash{$cluster}{repr} . q{: } . join q{ }, @{$hash{$cluster}{memb}};
# } }' cdHit.out.clstr > cdHit.out.groups

tie my %exp_members_for, 'Tie::IxHash';

my $expfile = file('test', 'cdHit.out.groups');
open my $in, '<', $expfile;

while (my $line = <$in>) {
    chomp $line;
    my ($repr, $memb_str) = $line =~ m/(\S+) \s* : \s* (.*)/xms;
    $exp_members_for{$repr} = [ split /\s+/, $memb_str ];
}
# explain %exp_members_for;

my $infile = file('test', 'cdHit.out.clstr');
my $report = $class->new( file => $infile );

is_deeply [ $report->all_representatives ], [ keys %exp_members_for ],
    'got expected list of representatives';

for my $repr ( $report->all_representatives ) {
    is_deeply $report->members_for($repr), $exp_members_for{$repr},
        "got expected list of members for representative: $repr";
}

done_testing;
