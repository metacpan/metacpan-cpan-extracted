#!/usr/bin/env perl

use Modern::Perl '2011';
use autodie;

use Smart::Comments;

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::SeqId';


die <<'EOT' unless @ARGV == 1;
Usage: $0 <full_ids.idl>
EOT

my $infile = shift;

my @seq_ids;

open my $in, '<', $infile;

while (my $line = <$in>) {
    chomp $line;
    my $seq_id = SeqId->new( full_id => $line );
    push @seq_ids, $seq_id;
}

for my $seq_id (@seq_ids) {

    ### full_id: $seq_id->full_id

    ### 0  full_id                      : $seq_id->full_id
    ### 1  is_foreign                   : $seq_id->is_foreign
    ### 2  is_new                       : $seq_id->is_new
    ### 3  is_genus_only                : $seq_id->is_genus_only
    ### 4  is_doubtful                  : $seq_id->is_doubtful
    ### 5  family                       : $seq_id->family
    ### 6  tag                          : $seq_id->tag

    ### 7  genus                        : $seq_id->genus
    ### 8  species                      : $seq_id->species
    ### 9  strain                       : $seq_id->strain
    ### 10 accession                    : $seq_id->accession
    ### 11 tail                         : $seq_id->tail

    ### 12 taxon_id                     : $seq_id->taxon_id
    ### 13 gca                          : $seq_id->gca
    ### 14 gca_novers                   : $seq_id->gca_novers
    ### 15 gca_vers                     : $seq_id->gca_vers
    ### 16 gca_prefix                   : $seq_id->gca_prefix
    ### 17 gca_number                   : $seq_id->gca_number

    ### 18 gi                           : $seq_id->gi
    ### 19 database                     : $seq_id->database
    ### 20 identifier                   : $seq_id->identifier
    ### 21 contam_org                   : $seq_id->contam_org

    ### 22 org                          : $seq_id->org
    ### 23 abbr_org                     : $seq_id->abbr_org
    ### 24 full_org                     : $seq_id->full_org

    ### 25 full_org( q{ } )             : $seq_id->full_org( q{ } )
    ### 26 family_then_full_org( q{ } ) : $seq_id->family_then_full_org( q{ } )
    ### 27 foreign_id                   : $seq_id->foreign_id
    ### 28 nexus_id                     : $seq_id->nexus_id

    ### 29 all_parts                    : $seq_id->all_parts

    my @methods;
    push @methods, $seq_id->full_id, $seq_id->is_foreign, $seq_id->is_new,
    $seq_id->is_genus_only, $seq_id->is_doubtful, $seq_id->family, $seq_id->tag,
    $seq_id->genus, $seq_id->species, $seq_id->strain, $seq_id->accession,
    $seq_id->tail, $seq_id->taxon_id, $seq_id->gca, $seq_id->gca_novers,
    $seq_id->gca_vers, $seq_id->gca_prefix, $seq_id->gca_number, $seq_id->gi,
    $seq_id->database, $seq_id->identifier, $seq_id->contam_org, $seq_id->org,
    $seq_id->abbr_org, $seq_id->full_org, $seq_id->full_org( q{ } ),
    $seq_id->family_then_full_org( q{ } ), $seq_id->foreign_id;

    my @format_methods;
    @format_methods = map {
        !defined $_ ? 'undef' : !$_
                    ? 0       : $_ =~ m/\'/xms
                    ? "q{$_}" : qq{'$_'}
    } @methods;

    push @format_methods, $seq_id->nexus_id;

    $format_methods[0] = '[ (' . $format_methods[0] . ') x 2';
    $format_methods[28] = 'q{' . $format_methods[28] . '}';
    if ($seq_id->all_parts) {
        push @format_methods, map { qq{'$_'} } $seq_id->all_parts;
    }

    $format_methods[-1] = $format_methods[-1] . ' ],';

    ### @format_methods

    say join ", ", @format_methods[0..6], ' ';
    say join ", ", @format_methods[7..11], ' ';
    say join ", ", @format_methods[12..17], ' ';
    say join ", ", @format_methods[18..21], ' ';
    say join ", ", @format_methods[22..24], ' ';
    say join ", ", $format_methods[25], ' ';
    say join ", ", $format_methods[26], ' ';
    say join ", ", $format_methods[27], ' ';

    if ($seq_id->all_parts) {
        say join ", ", $format_methods[28], ' ';
        say join ", ", @format_methods[29..$#format_methods];
    }
    else {
        say $format_methods[28];
    }
    print "\n";
}
