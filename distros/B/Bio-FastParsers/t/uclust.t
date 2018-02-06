#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use Path::Class qw(file);
use Tie::IxHash;

use Bio::FastParsers;


my $class = 'Bio::FastParsers::Uclust';

# perl -MTie::IxHash -anle 'BEGIN{ tie %hash, 'Tie::IxHash' } push @{ $hash{$F[8]} }, () if $F[0] eq 'C'; push @{ $hash{$F[9]} }, $F[8] if $F[0] eq 'H'; END{ while (($repr, $members) = each %hash) { print $repr . q{: } . join q{ }, @$members } }' uclust.uc > uclust.uc.groups

# perl -MSort::Naturally -nle 'my ($id, $member_str) = split ": "; my @members = split q{ }, $member_str; $hash{$id} = \@members; END{ @list = sort { scalar @{$hash{$b}} <=> scalar @{$hash{$a}} || ncmp($a, $b) } keys %hash; print join "\n", @list }' uclust.uc.groups > uclust.uc.ids

# TODO: avoid code duplication with cd_hit.t

tie my %exp_members_for, 'Tie::IxHash';

my $expfile1 = file('test', 'uclust.uc.groups');
open my $in, '<', $expfile1;

while (my $line = <$in>) {
    chomp $line;
    my ($repr, $memb_str) = $line =~ m/(\S+) \s* : \s* (.*)/xms;
    $exp_members_for{$repr} = [ split /\s+/, $memb_str ];
}

my $expfile2 = file('test', 'uclust.uc.ids');
my @exp_ids = $expfile2->slurp( chomp => 1 );

my $infile = file('test', 'uclust.uc');
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
