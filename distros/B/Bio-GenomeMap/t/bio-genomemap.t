#!/usr/bin/env perl
use strict;
use warnings;
use 5.010_000;
use Data::Dumper;
use autodie;
use Test::More;
use Scalar::Util qw/looks_like_number/;
use_ok 'Bio::GenomeMap';

my $gff = 't/test.gff';
my $db = 't/test.gff.sqlite3';
unlink $db if -e $db;

my $in_memory = load_into_memory($gff);
my $in_file = load_into_file($gff, $db);

# say Dumper $in_memory, $on_disk;
# say Dumper $in_memory->slurp_overlaps('Chr1', 30000, 32000);
# say Dumper $on_disk->slurp_overlaps('Chr1', 30000, 32000);

for my $gm ($in_memory, $in_file){
    is_deeply(
        [$gm->sequences()],
        [qw/Chr1 Chr2 Chr3 Chr4 Chr5 ChrC ChrM/],
        'sequence list'
    );

    is_deeply(
        $gm->slurp_overlaps('Chr1', 30000, 32000),
        [
            [23146,31227,4], [23519,31079,1], [29160,30065,5], [30147,30311,9],
            [30410,30816,3], [30902,31079,4], [30902,31227,2], [31080,31227,3],
            [31170,31381,3], [31170,31424,1], [31382,31424,9], [31382,32670,4],
            [31521,31602,1], [31693,31813,6], [31933,31998,9],
        ], 
        "slurp_overlaps",
    );

    {
        my @res;
        $gm->iter_overlaps('Chr1', 30000, 32000, sub{
                my ($start, $end, $data) = @_;
                push @res, [$start, $end, $data];
            });
        is_deeply(
            $gm->slurp_overlaps('Chr1', 30000, 32000),
            \@res,
            "iter_overlaps",
        );
    }

    is_deeply(
        $gm->slurp_within('Chr1', 30000, 32000),
        [
            [30147,30311,9], [30410,30816,3], [30902,31079,4], [30902,31227,2],
            [31080,31227,3], [31170,31381,3], [31170,31424,1], [31382,31424,9],
            [31521,31602,1], [31693,31813,6], [31933,31998,9],
        ], 
        "slurp_within",
    );

    is_deeply(
        $gm->slurp_surrounding('Chr1', 31000, 31050),
        [
            [23146,31227,4], [23519,31079,1], [30902,31079,4], [30902,31227,2],
        ], 
        "slurp_surrounding",
    );

    is_deeply(scalar(@{$gm->slurp_all}), 1293, 'slurp_all');
    # data col is just dummy numbers, so just search for a number
    is(scalar($gm->search(9, 0, 40)), 40, 'search returns expected number of results');

    is( scalar($gm->search('9', 0, 10)), 10, "search with limit" );
    is( scalar($gm->search('9', 0, 9999)), 119, "search with no limit" );
}

# unlink $db if -e $db;

sub load_into_memory{
    my $file = shift;

    my $gm = Bio::GenomeMap->new(); 
    my $in = IO::File->new($file);
    $gm->bulk_insert(sub{
            my $inserter = shift;
            while (defined(my $line = <$in>)){
                $line =~ tr/\n\r//d;
                my @fields = split /\t/, $line;

                if (@fields == 9 and looks_like_number($fields[3]) and looks_like_number($fields[4])){
                    $inserter->($fields[0], $fields[3], $fields[4], $fields[5]);
                }
            }
        });
    $in->close;
    return $gm;
}

sub load_into_file {
    my ($input, $output) = @_;

    my $in = IO::File->new($input);
    my $gm = Bio::GenomeMap->new(sqlite_file => $output); 
    $gm->bulk_insert(sub{
            my $inserter = shift;
            while (defined(my $line = <$in>)){
                $line =~ tr/\n\r//d;
                my @fields = split /\t/, $line;
                next if @fields != 9;

                my ($seqid, $feature, $start, $end, $score, $strand, $attr) = @fields[qw/0 2 3 4 5 6 8/];

                if (looks_like_number($start) and looks_like_number($end) and $start <= $end){
                    $inserter->($seqid, $start, $end, $score);
                }
            }
        });

    $gm->commit();
    return $gm;
}

done_testing();
