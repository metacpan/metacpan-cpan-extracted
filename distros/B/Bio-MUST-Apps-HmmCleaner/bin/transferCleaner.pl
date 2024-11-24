#!/usr/bin/env perl
# PODNAME: transferCleaner.pl
# ABSTRACT: transfer amino acid LSSs on corresponding nucleotide alignment
# CONTRIBUTOR: Denis BAURAIN <denis.baurain@uliege.be>

use Modern::Perl;
use Getopt::Euclid;

## no critic (RequireLocalizedPunctuationVars)
BEGIN{
    $ENV{Smart_Comments} = $ARGV{-v}
        ? join q{ }, map { '#' x (2 + $_) } 1..$ARGV{-v}
        : q{}
    ;
}
## use critic
use Smart::Comments -ENV;
use Bio::MUST::Core::Utils qw(change_suffix);
use aliased 'Bio::MUST::Apps::HmmCleaner';
use aliased 'Bio::MUST::Core::Ali';
use Path::Class;

### Lauching script...

### INFILE : $ARGV{'<infile>'}

my $ali = Ali->load($ARGV{'<infile>'});

my %log;
my $logfile = file($ARGV{'-log'});
my $fh = $logfile->openr;

my $corg;
my @spans;
while (my $line = <$fh>) {
    chomp $line;
    unless (substr($line,0,1) =~ m/\s/xms) {
        if (defined $corg && @spans > 0) {
            $log{$corg} = [@spans];
            @spans = ();
        }
        $corg = $line;
    } else {
        $line =~ s/\s+//xmsg;
        my ($s,$e) = split "-", $line;
        push @spans, [$s,$e];
    }
}
$log{$corg} = [@spans] if (@spans);

#### %log

for my $seqid (keys %log) {
    my $seq = $ali->get_seq_with_id($seqid);

    for my $span (@{$log{$seqid}}) {
        my $e_nt = (($$span[1]-1)*3)+2;
        my $s_nt = ($$span[0]-1)*3;
        my @indexes = $s_nt..$e_nt;

        for my $pos (@indexes) {
            $seq->edit_seq($pos,1,$ARGV{'-delchar'});
        }
    }
}

$ali->store(change_suffix($ali->file,'_cleaned.ali'));

### End of script...

__END__

=pod

=head1 NAME

transferCleaner.pl - transfer amino acid LSSs on corresponding nucleotide alignment

=head1 VERSION

version 0.243280

=head1 USAGE

transferCleaner.pl <infiles> -log=<log> [-delchar <delchar> -costs <c1> <c2> <c3> <c4> --changeID --noX]

=head1 REQUIRED ARGUMENTS

=over

=item <infile>

list of alignment file to check with HMMCleaner

=for Euclid: infile.type: readable

=item -log=<log>

Log file

=for Euclid: log.type: readable

=back

=head1 OPTIONS

=over

=item -delchar <delchar>

Replacement character for removed residues

=for Euclid: delchar.type: string
    delchar.default: ' '

=item -costs <c1> <c2> <c3> <c4>

Cost parameters that defines the low similarity segments detected by HmmCleaner.
Default values are -0.15, -0.08, 0.15, 0.45
Users can change each value but they have to be in increasing order.
c1 < c2 < 0 < c3 < c4
Predefine value are also available with --large and --specificity options but
user defined costs will be prioritary if present.

=for Euclid: c1.type: number < 0
    c2.type: number < 0
    c3.type: number > 0
    c4.type: number > 0

=item --changeID

Determine if output will have defline with generic suffix (_hmmcleaned)

=item --noX

Consider X characters as gap that will not be taken into account by HmmCleaner.

=item -profile=<profile>

Determine how the profile will be create
local or global (default: global)
local = without the analyzed sequence (new profile each time)
global = all sequences (same profile for each sequence)
First case is more sensitive but need more ressource (hence more time)

=for Euclid: profile.type: /local|global/
    profile.type.error: <profile> must be either "local" or "global"
    profile.default: 'global'

=item --large

Load predifined cost parameters optimized for MSA with at least 50 sequences.
Can be use with --specificity option.
User defined costs will be prioritary if present.

=item --specificity

Load predifined cost parameters optimized to give more weigth on specificity.
Can be use with --large option.
User defined costs will be prioritary if present.

=item --log_only

Only outputs list of segments removed.

=item --ali

Outputs result file(s) in ali MUST format.

=item -v[erbosity]=<level>

Verbosity level for logging to STDERR [default: 0]. Available levels range from
0 to 5.

=for Euclid: level.type: int, level >= 0 && level <= 5
    level.default: 0

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Arnaud Di Franco <arnaud.difranco@gmail.fr>

=head1 CONTRIBUTOR

=for stopwords Denis BAURAIN

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Arnaud Di Franco.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
