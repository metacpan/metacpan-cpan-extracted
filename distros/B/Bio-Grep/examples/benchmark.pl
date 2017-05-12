#/usr/bin/perl
use strict;
use warnings;

use Time::HiRes qw(gettimeofday tv_interval);
use Data::Dumper;
use English qw( -no_match_vars ) ; 
use Template;
use Sys::Info;

use Bio::Grep;
use Bio::Perl;

my $DEBUG = 0;

my $template = Template->new();

my %be = (
   agrep  => Bio::Grep->new('Agrep'),
   agrep_tre  => Bio::Grep->new('Agrep'),
   vmatch => Bio::Grep->new('Vmatch'),
   re     => Bio::Grep->new('RE'),
   guugle => Bio::Grep->new('GUUGle'),
);

my %results;

my $query = 'ugacagaagagagugagcac';
$query =~ tr{u}{t};

my $time;
my $VERBOSE=0;
my $filenameCDNA = 'TAIR8_cdna_20080412';
my $iterations = $DEBUG ? 1 : 20;
my $iterationsdb = $DEBUG ? 1: 2;
my $maxmm = $DEBUG ? 1 : 5;

#goto CREATETMP;
DB:
for $b (sort keys %be) {
    my $sbe = $be{$b};
    $time = [gettimeofday];
    for my $i (1..$iterationsdb) {
        system("rm -rf data$b/");
        mkdir 'data' . $b;

        $sbe->generate_database({
                datapath      => 'data' . $b,
                file          => "examples/$filenameCDNA",
                prefix_length => 3,
            }); 
    }
    $results{"${b}_dbgen"} = sprintf("%.2f",
        (tv_interval($time)/$iterationsdb));
    warn "$b took " . $results{"${b}_dbgen"} . " seconds\n";
}    

MM:
for $b (sort keys %be) {
    my $sbe = $be{$b};
    my $loop_counter = 0;
    $loop_counter = 1 if $b eq 'vmatch';
    for my $online ( 0 .. $loop_counter) {
    for my $mm (0..$maxmm) {
        next MM if !defined $sbe->features->{MISMATCHES} && $mm > 0;
        $time = [gettimeofday];
        for my $i (1..$iterations) {
            print "." if ($i % 5 == 0);
            my %showdesc;
            %showdesc = ( showdesc => 100) if $b eq 'vmatch'; 
            my $gu = 1;
            $gu = 0 if $b eq 'guugle';
            eval { $sbe->search({
            query              => $query,
            mismatches         => $mm,
            reverse_complement => 1,
            datapath => 'data' . $b,
            ($b eq 'agrep_tre' ? ( execpath => 'examples/bin/agrep-tre/' ) : ()),
            no_alignments      => 1,
            online             => $online,
            database           => $filenameCDNA,
            gumismatches       => $gu,
            %showdesc,
            }); };
            my @ids;
            while (my $res = $sbe->next_res) {
                push @ids, $res->sequence->id;
            }    
            warn scalar(@ids). " results.\n" if $VERBOSE;
        }   
        warn 'Is TRE? ' . $sbe->is_tre_agrep() if $b =~/agrep/;
        
        $results{"${b}_mm_${mm}_$online"} = sprintf("%.2f",
            tv_interval($time)/$iterations);
        warn "$b (mm $mm) took " . $results{"${b}_mm_${mm}_$online"} . " seconds\n";
    }     
    }
}    

CREATETMP:
my $info = Sys::Info->new;
$results{cpuinfo} = scalar $info->device('CPU')->identify;
$results{perl} = $info->perl_long();
$results{osname} = $info->os->name( long => 1 );
$results{filenameCDNA} = $filenameCDNA;
$results{biogrepv} = $Bio::Grep::VERSION;
$results{iterations} = $iterations;
$results{iterationsdb} = $iterationsdb;
$template->process('examples/Benchmarks.tt', \%results, 'lib/Bio/Grep/Benchmarks.pod') || die
$template->error(), "\n";
