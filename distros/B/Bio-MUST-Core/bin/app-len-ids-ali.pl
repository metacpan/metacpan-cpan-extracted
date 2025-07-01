#!/usr/bin/env perl
# PODNAME: app-len-ids-ali.pl
# ABSTRACT: Appends seq lengths to ids in ALI files (as SCaFoS)

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(secure_outfile);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::IdMapper';


for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $ali = Ali->load($infile);
    $ali->dont_guess if $ARGV_noguessing;

    # append seq lengths to ids
    my $idm = $ali->len_mapper;
    $ali->restore_ids($idm);

    my $outfile = secure_outfile($infile, $ARGV_out_suffix);
    $ali->store($outfile);
}

__END__

=pod

=head1 NAME

app-len-ids-ali.pl - Appends seq lengths to ids in ALI files (as SCaFoS)

=head1 VERSION

version 0.251810

=head1 USAGE

    app-len-ids-ali.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input ALI files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

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
