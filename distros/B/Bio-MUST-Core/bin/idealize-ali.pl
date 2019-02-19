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


for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $ali = Ali->load($infile);
    $ali->idealize($ARGV_max_res_drop_site);
    my $outfile = secure_outfile($infile, $ARGV_out_suffix);
    $ali->store($outfile);
}

__END__

=pod

=head1 NAME

idealize-ali.pl - Discard (nearly) gap-only sites from ALI files

=head1 VERSION

version 0.190500

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
