#!/usr/bin/env perl
# PODNAME: HmmCleaner.pl
# ABSTRACT: Removing low similarity segments from your MSA
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

use Bio::MUST::Apps::HmmCleaner;
use aliased 'Bio::MUST::Apps::HmmCleaner';

### Lauching script...

###### %ARGV

my %costs_values = (
    'default'       => [-0.15, -0.08, 0.15, 0.45],
    'large'         => [-0.175, -0.04, 0.15, 0.4],
    'specificity'   => [-0.125, -0.07, 0.175, 0.4],
    'large_specificity'   => [-0.125, -0.03, 0.15, 0.4],
);

my $costs = $costs_values{'default'};
$costs = $costs_values{'large'} if ($ARGV{'--large'});
$costs = $costs_values{'specificity'} if ($ARGV{'--specificity'});
$costs = $costs_values{'large_specificity'} if ( $ARGV{'--large'} && $ARGV{'--specificity'});
$costs = [$ARGV{'-costs'}{'c1'}, $ARGV{'-costs'}{'c2'}, $ARGV{'-costs'}{'c3'}, $ARGV{'-costs'}{'c4'}] if ($ARGV{'-costs'});

#### $costs

for my $file ( @{$ARGV{'<infiles>'}} ) {
    my $args = {
        ali             => $file,
        ali_model       => $file,
        threshold       => 1,
        changeID        => $ARGV{'--changeID'},
        #~ delchar         => $ARGV{'-delchar'},
        costs           => $costs,
        consider_X      => ($ARGV{'--noX'}) ? 0 : 1,
        perseq_profile  => ($ARGV{'-profile'} eq 'leave-one-out') ? 1 : 0,
        outfile_type    => ($ARGV{'--ali'}) ? 1 : 0,
        debug_mode      => ($ARGV{'-v'}>5) ? 1 : 0,
        symfrac         => $ARGV{'-symfrac'},
    };

    ### Creating object for file : $file
    my $cleaner = HmmCleaner->new($args);

    ($ARGV{'--log_only'}) ? $cleaner->store_log : $cleaner->store_all;

}

### End of script...

__END__

=pod

=head1 NAME

HmmCleaner.pl - Removing low similarity segments from your MSA

=head1 VERSION

version 0.243280

=head1 USAGE

HmmCleaner.pl <infiles> [-costs <c1> <c2> <c3> <c4> --changeID --noX --ali --log-only]

=head1 REQUIRED ARGUMENTS

=over

=item <infiles>

list of alignment file to check with HmmCleaner

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONS

=over

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

Convert X characters to gaps that will not be taken into account by HmmCleaner.

=item -symfrac <symfrac>

Handle the symfrac option of hmmbuild  modifying the required fraction of sequences
to consider a position as a consensus column

=for Euclid: symfrac.type: 0+num, symfrac <=1
    symfrac.default: 0.5
    symfrac.type.error: <symfrac> must be between 0 and 1

=item -profile=<profile>

Determine how the profile will be create
complete or leave-one-out (default: complete)
leave-one-out = without the analyzed sequence (new profile each time)
complete = all sequences (same profile for each sequence)
First case is more sensitive but need more ressources (hence more time)

=for Euclid: profile.type: /complete|leave-one-out/
    profile.type.error: <profile> must be either "leave-one-out" or "complete"
    profile.default: 'complete'

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
