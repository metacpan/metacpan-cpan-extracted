#!/usr/bin/env perl
# PODNAME: clust2mapper.pl
# ABSTRACT: Build id mapper from UCLUST/CD-HIT clusters for tree formatting

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments;

use Bio::FastParsers;

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix);


my %class_for = (
    'cd-hit' => 'Bio::FastParsers::CdHit',
    'uclust' => 'Bio::FastParsers::Uclust',
);
my $class = $class_for{ lc $ARGV_engine };

for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $report = $class->new( file => $infile );
    my $mapper = $report->clust_mapper($ARGV_separator);

    my $outfile = change_suffix($infile, '.idm');
	$mapper->store($outfile);
}

__END__

=pod

=head1 NAME

clust2mapper.pl - Build id mapper from UCLUST/CD-HIT clusters for tree formatting

=head1 VERSION

version 0.181180

=head1 USAGE

    clust2mapper.pl <infiles> --engine=<pgm> [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

Path to input UCLUST/CD-HIT cluster files [repeatable argument].

=for Euclid: infiles.type: readable
    repeatable

=item --engine=<pgm>

Engine used to generate the clusters. The following programs are
available: cd-hit and uclust.

=for Euclid: pgm.type:       /cd-hit|uclust/
    pgm.type.error: <pgm> must be one of cd-hit or uclust (not pgm)

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --sep[arator]=<str>

Separator used to join members ids for each cluster [default: '/'].

=for Euclid: str.type:    string
    str.default: '/'

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
