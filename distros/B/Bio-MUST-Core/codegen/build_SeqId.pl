#!/usr/bin/env perl

use Modern::Perl '2011';
use autodie;

use Template;
use Path::Class qw(file);

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::SeqId';


my %is_hyphenated;
my %is_underscored;

my $infile = file('test/taxdump', 'names.dmp');
open my $in, '<', $infile;

LINE:
while (my $line = <$in>) {
    chomp $line;

    my @fields = split /\s*\|\s*/xms, $line;
    next LINE unless $fields[3] =~ m/scientific \s name/xms;

    my ($genus, $species, $strain) = SeqId->parse_ncbi_name($fields[1]);
    if ($genus) {
        $is_hyphenated{$genus}    = 1 if $genus   =~ m/\-/xms;
    }
    if ($species) {
        $is_underscored{$species} = 1 if $species =~ m/_/xms;
    }
}

# compute template and output paths for TT
my $template = file('codegen/templates', 'SeqId.tt')->stringify;
my $outfile  = file('lib/Bio/MUST/Core', 'SeqId.pm')->stringify;

my $vars = {
    is_hyphenated  => \%is_hyphenated,
    is_underscored => \%is_underscored,
};

my $tt = Template->new( { RELATIVE => 1 } );

$tt->process($template, $vars, $outfile)
    or die 'Cannot build: ' . $outfile . ": $!";
