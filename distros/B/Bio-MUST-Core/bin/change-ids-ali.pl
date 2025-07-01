#!/usr/bin/env perl
# PODNAME: change-ids-ali.pl
# ABSTRACT: Abbreviate or restore the org component of full seq ids in ALI files

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix secure_outfile);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::IdMapper';


### Mapping organisms from: $ARGV_org_mapper
my $org_mapper = IdMapper->load($ARGV_org_mapper);

for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $ali = Ali->load($infile);
    $ali->dont_guess if $ARGV_noguessing;

    # build id_mapper and change ids
    my $id_mapper;

    if ($ARGV_mode eq 'long2abbr') {
        $id_mapper = $ali->org_mapper_from_long_ids($org_mapper);
        $ali->shorten_ids($id_mapper);
    }
    else {          # 'abbr2long'
        $id_mapper = $ali->org_mapper_from_abbr_ids($org_mapper);
        $ali->restore_ids($id_mapper);
    }

    my $outfile = secure_outfile($infile, $ARGV_out_suffix);
    $ali->store($outfile);

    # optionally store the id mapper
    if ($ARGV_store_id_mapper) {
        my $idmfile = change_suffix($outfile, '.idm');
        $id_mapper->store($idmfile);
    }
}

__END__

=pod

=head1 NAME

change-ids-ali.pl - Abbreviate or restore the org component of full seq ids in ALI files

=head1 VERSION

version 0.251810

=head1 USAGE

    change-ids-ali.pl <infiles> --org-mapper=<file> --mode=<dir>
        [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input ALI files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=item --org-mapper=<file>

Path to the IDM file listing the long_org => abbr_org pairs.

=for Euclid: file.type: readable

=item --mode=<dir>

Direction of the id changing operation. The following directions are
available: long2abbr and abbr2long.

=for Euclid: dir.type:       string, dir eq 'long2abbr' || dir eq 'abbr2long'
    dir.type.error: <dir> must be one of long2abbr or abbr2long (not dir)

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --out[-suffix]=<suffix>

Suffix to append to infile basenames for deriving outfile names [default:
none]. When not specified, outfile names are taken from infiles but original
infiles are preserved by being appended a .bak suffix.

=for Euclid: suffix.type: string

=item --[no]guessing

[Don't] guess whether sequences are aligned or not [default: yes].

=item --store-id-mapper

Store the IDM file corresponding to each output file [default: no].

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
