#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use Path::Class qw(file);
use Tie::IxHash;

use Bio::FastParsers;

my $class = 'Bio::FastParsers::CdHit';

# perl -nle 'if (m/Cluster (\d+)/) { $cluster = $1; next } ($id,$type) = m/>(\S+)\.{3} (\*|at)/; $hash{$cluster}{repr} = $id if $type eq q{*}; push @{$hash{$cluster}{memb}}, $id if $type eq q{at}; END{ for $cluster (sort { $a <=> $b } keys %hash) { print $hash{$cluster}{repr} . q{: } . join q{ }, @{$hash{$cluster}{memb}}; } }' cdHit.out.clstr > cdHit.out.groups

# perl -MSort::Naturally -nle 'my ($id, $member_str) = split ": "; my @members = split q{ }, $member_str; $hash{$id} = \@members; END{ @list = sort { scalar @{$hash{$b}} <=> scalar @{$hash{$a}} || ncmp($a, $b) } keys %hash; print join "\n", @list }' cdHit.out.groups > cdHit.out.ids

# for f in `cat cdHit.out.ids`; do grep $f cdHit.out.groups ; done

tie my %exp_members_for, 'Tie::IxHash';

my $expfile1 = file('test', 'cdHit.out.groups');
open my $in, '<', $expfile1;

while (my $line = <$in>) {
    chomp $line;
    my ($repr, $memb_str) = $line =~ m/(\S+) \s* : \s* (.*)/xms;
    $exp_members_for{$repr} = [ split /\s+/, $memb_str ];
}

my $expfile2 = file('test', 'cdHit.out.ids');
my @exp_ids = $expfile2->slurp( chomp => 1 );

my $infile = file('test', 'cdHit.out.clstr');
my $report = $class->new( file => $infile );

is_deeply [ $report->all_representatives ], [ keys %exp_members_for ],
    'got expected list of representatives';

is_deeply [ $report->all_representatives_by_cluster_size ], \@exp_ids,
    'got expected list of representatives by decreasing cluster size';

for my $repr ( $report->all_representatives ) {
    is_deeply $report->members_for($repr), $exp_members_for{$repr},
        "got expected list of members for representative: $repr";
}

done_testing;
