#!/usr/bin/env perl
# PODNAME: rest-ids-ali.pl
# ABSTRACT: Change (restore) full seq ids in ALI files

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix secure_outfile);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::IdMapper';


for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $ali = Ali->load($infile);
    $ali->dont_guess if $ARGV_noguessing;

    $infile =~ s/$_//xms for @ARGV_in_strip;
    my $idmfile = change_suffix($infile, '.idm');
    my $idm = IdMapper->load($idmfile);
    ### Restoring seq ids from: $idmfile
    $ali->restore_ids($idm);

    my $outfile = secure_outfile($infile, $ARGV_out_suffix);
    $ali->store($outfile);
}

__END__

=pod

=head1 NAME

rest-ids-ali.pl - Change (restore) full seq ids in ALI files

=head1 VERSION

version 0.251810

=head1 USAGE

    rest-ids-ali.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input ALI files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --in[-strip]=<str>

Substring(s) to strip from infile basenames before attempting to derive other
infile (e.g., IDM files) and outfile names [default: none].

=for Euclid: str.type: string
    repeatable

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
