#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  vcf-to-table.pl
#
#        USAGE:  ./vcf-to-table.pl  
#
#  DESCRIPTION:  Flatten each line so it is in tabular format instead of INFO,FORMAT,etc
#
#      VERSION:  1.0
#      CREATED:  08/11/2014 09:55:09 AM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
no warnings 'uninitialized';

use Vcf;
use Data::Dumper;
use IO::File;

#Initialize VCF
my $vcffile = $ARGV[0];

my $vcf = Vcf->new(file=>$vcffile);
$vcf->parse_header();
my $href = get_agg_columns($vcf);

my(@columns, @infos, @format, @samples);
@columns = @{$href->{columns}};
@infos = @{$href->{infos}};
@format = @{$href->{format}};
@samples = @{$href->{samples}};

#Initialize Text::Csv
my $fh;
if($ARGV[1]){
    $fh = IO::File->new(">".$ARGV[1]);
}
else{
    $fh = IO::File->new(">".$vcffile.".table.tsv");
}
print $fh join("\t", @columns)."\n";

my $z=0;
while(my $line = $vcf->next_line()){
#    die if $z>=500;

# Some of the info fields, mainly the refgene ones, don't parse correctly with the next_data_hash method...
# my $x = $vcf->next_data_hash($line);

    my %hashline = ();
    my @items = split(/\t/,$line);

    for(my $y=0; $y<=$#items; $y++){
        $hashline{$columns[$y]} = $items[$y];
    }


    foreach my $i (@infos){
        next unless $i;
        my $af = $vcf->get_info_field($items[7], $i);
#        print "I is $i ".Dumper($af);
        $hashline{$i} = $af;
    }

    foreach my $f (@format){
        next unless $f;
        my($idx, $pl);

        my $y=9;
        foreach my $s (@samples){
            $idx = $vcf->get_tag_index($items[8], $f, ':');
            if($idx != -1 ){
                $pl  = $vcf->get_field($items[$y],$idx);
                if($f eq "GT"){
                    my $call = genotype($vcf, $pl);
#                    print "Call for Sample $s is $call\n";
                    $hashline{$s.".GenoCall"} = $call;
                }
                $hashline{$s.".$f"} = $pl;
            }
#            print "Sample column $s $f is $pl\n" if $pl; 
            $y++;
        }
    }

    my @row = map { $hashline{$_} } @columns;
    s/\n//g for @row;

    print $fh join("\t", @row)."\n";

    $z++;
}

sub get_agg_columns {
    my($vcf) = @_;

    my (@samples) = $vcf->get_samples();

    my $origcols = $vcf->{columns};

    die unless $origcols;

    my @infos = keys %{$vcf->{header}->{INFO}};
    @infos = sort(@infos);

    my @format = keys %{$vcf->{header}->{FORMAT}};
    @format = sort(@format);

    my @columns = ();

    push(@columns, @{$origcols});
    push(@columns, @infos);

    foreach my $s (@samples){
        foreach my $f (@format){
            push (@columns, $s.".$f");
        }
        push(@columns, $s.".GenoCall");
    }

    my $href = {};
    $href->{columns} = \@columns;
    $href->{samples} = \@samples;
    $href->{format} = \@format;
    $href->{infos} = \@infos;

    return($href);
}

sub genotype {
    my($vcf, $geno) = @_;

    my @geno = $vcf->split_gt($geno);

    if(scalar @geno != 2){
        return "DIP".scalar @geno;
    }
    elsif($geno[0] == 0 && $geno[1] == 0){
        return "REF";
    }
    elsif($geno[0] == 1 && $geno[1] == 0){
        return "HET";
    }
    elsif($geno[0] == 0 && $geno[1] == 1){
        return "HET";
    }
    elsif($geno[0] == 1 && $geno[1] == 1){
        return "ALT";
    }
    else{
        return "U";
    }
}
