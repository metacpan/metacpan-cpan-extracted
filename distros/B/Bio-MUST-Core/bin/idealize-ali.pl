#!/usr/bin/env perl
# PODNAME: idealize-ali.pl
# ABSTRACT: Discard (nearly) gap-only sites from ALI files

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(secure_outfile);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::SeqMask';


for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $ali = Ali->load($infile);

    my $mask = SeqMask->ideal_mask($ali, $ARGV_max_res_drop_site);
    $mask = $mask->codon_mask( {
        frame => $ARGV_coding_frame,
          max => $ARGV_codon_max_nt_drop,
    } ) if $ARGV_keep_codons;
    $ali->apply_mask($mask);

    my $outfile = secure_outfile($infile, $ARGV_out_suffix);
    $ali->store($outfile);
}

__END__

=pod

=head1 NAME

idealize-ali.pl - Discard (nearly) gap-only sites from ALI files

=head1 VERSION

version 0.251810

=head1 USAGE

    idealize-ali.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input ALI files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --max[-res-drop-site]=<n>

Number of non-gap character states allowed in a site to be dropped [default:
0]. When specified as a fraction between 0 and 1, it is interpreted as
relative to the number of sequences in the ALI. By default, only shared gaps
are dropped.

=for Euclid: n.type:    number
    n.default: 0

=item --keep-codons

When specified, this option forces the various applied masks to follow the
codon structure [default: no]. This option only makes sense with nt seqs. See
options C<--codon-max> and C<--coding-frame> for more control on this
behavior.

=item --codon-max[-nt-drop]=<n>

Number of non-dropped nt sites allowed in a codon to be dropped [default: 1].
Allowed values are 0, 1 and 2. To be used when the option C<--keep-codons> is
also specified.

=for Euclid: n.type:    integer, 0 <= n && n <= 2
    n.default: 1

=item --coding-frame=<n>

Reading frame to be used when determining the ALI codon structure [default:
+1]. Allowed values are -3 to -1 and +1 to +3. To be used when the option
C<--keep-codons> is also specified.

=for Euclid: n.type:    integer, -3 <= n && n <= 3 && n != 0
    n.default: +1

=item --out[-suffix]=<suffix>

Suffix to append to infile basenames for deriving outfile names [default:
none]. When not specified, outfile names are taken from infiles but original
infiles are preserved by being appended a .bak suffix.

=for Euclid: suffix.type: string

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
