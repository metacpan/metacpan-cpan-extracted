#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec::Functions;
use lib 'lib';
use Config::JFDI;
use Test::More;
use Data::Dumper;
use Getopt::Long;
use App::Mimosa::Schema::BCS;

=head1 NAME

script/mimosa_deploy.pl - Deploy a Mimosa database

=head1 SYNOPSIS

To deploy a Mimosa database:

    perl script/mimosa_deploy.pl

This will use the default config file "app_mimosa.conf" and by default,
use a SQLite database called ./mimosa.db .

=head1 DESCRIPTION

If you want to use a custom "foo.conf" config file:

    perl script/mimosa_deploy.pl --conf foo.conf

To deploy into an already-existing Chado database:

    perl script/mimosa_deploy.pl --chado 1

This means that only Mimosa-related tables will be created and deployed to. This
specifically does not create/deploy Chado tables, since they should already
exist.

If you run either of:

    perl script/mimosa_deploy.pl
    perl script/mimosa_deploy.pl --chado 0

then all Mimosa and Chado tables that are needed will be created and deployed to.

To deploy an empty schema with no data:

    perl script/mimosa_deploy.pl --empty 1

And of course, these options can be used together:

    perl script/mimosa_deploy.pl --conf foo.conf --chado 1


=head1 SEE ALSO

L<App::Mimosa>

=head1 AUTHOR

Jonathan "Duke" Leto <jonathan@leto.net>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# default to app_mimosa.conf and not deploying to chado
my $conf  = '';
my $chado = 0;
my $empty = 0;

my $result = GetOptions(
                "conf=s", \$conf,
                "chado=i", \$chado,
                "empty=i", \$empty,
            );
my $config_file = Config::JFDI->new(file => $conf || "app_mimosa.conf");
my $config = $config_file->get;

my $schema = App::Mimosa::Schema::BCS->connect( $config->{'Model::BCS'}{connect_info}->{dsn} );

if ($chado) {
    diag "Deploying Mimosa Schema into a Chado schema";
    $schema->deploy({
             sources => [
                'Mimosa::Job',
                'Mimosa::SequenceSet',
                'Mimosa::SequenceSetOrganism',
                ]})
} else {
    diag "Deploying fresh Mimosa Schema";
    $schema->deploy;
}

exit 0 if $empty;

diag "Populating default Mimosa Schema";
$schema->populate('Mimosa::SequenceSet', [
    [qw/shortname title description alphabet source_spec lookup_spec info_url update_interval is_public/],
    # we make this non-public to test our sequence set filtering
    ['acidiphilium_cryptum_protein.seq', 'A. cryptum hypothetical protein', 'A. cryptum hypothetical protein in CP000694', 'protein', 'ftp://ftp.ncbi.nlm.nih.gov/genbank/genomes/Bacteria/Acidiphilium_cryptum_JF-5_uid15753/CP000694.faa', '', ,'', 10, 0    ],
    ['acaryochloris_marina_CP000846.seq', 'Acaryochloris marina hypothetical proteins', 'Acaryochloris marina hypothetical proteins in CP000846', 'protein', 'ftp://ftp.ncbi.nlm.nih.gov/genbank/genomes/Bacteria/Acaryochloris_marina_MBIC11017_uid12997/CP000846.faa', '', ,'', 30, 1    ],
    ['solanum_peruvianum_mRNA.seq', 'Solanum peruvianum SGN mRNA sequences', 'mRNA sequences for S. peruvianum', 'nucleotide', '', '', ,'', 30, 1    ],
    ['prunus_necrotus_genomic_rna.seq', 'Prunus necrotic ringspot virus coat', 'Necrotic ringspot virus CP gene for coat protein, isolate SK25, genomic RNA', 'nucleotide', 'http://www.ncbi.nlm.nih.gov/nuccore/FR773524.2?report=fasta&log$=seqview&format=text', '', ,'', 30, 1    ],
]);

$schema->populate('Mimosa::SequenceSetOrganism', [
    [qw/organism_id mimosa_sequence_set_id/],
    [1, 1],
    [2, 2],
    [3, 3],
    [4, 4],
]);

$schema->populate('Organism', [
    [qw/organism_id genus species common_name/],
    [1, "Acidiphilium", "Acidiphilium cryptum", ""],
    [2, "Acaryochloris", "Acaryochloris marina", ""],
    [3, "Solanum", "Solanum peruvianum", "Wild tomato"],
    [4, "Prunus", "Prunus necrotus", "Necrotic ringspot virus"],
]);
