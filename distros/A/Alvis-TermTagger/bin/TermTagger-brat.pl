#!/usr/bin/perl

#######################################################################
#
# Last Update: 16/09/2015 (mm/dd/yyyy date format)
# 
# Copyright (C) 2002 Thierry Hamon
#
# Written by thierry.hamon@limsi.fr
#
# Author : Thierry Hamon
# Email : thierry.hamon@limsi.fr
# URL : https://perso.limsi.fr/hamon/
#
########################################################################

=head1 NAME

TermTagger-brat.pl -- A Perl script for tagging text with terms (Brat format output)

=head1 SYNOPSIS

TermTagger.pl [options] corpus termlist selected_term_list lemmatised_corpus

=head1 OPTIONS

=over 4

=item    B<--help>            brief help message

=back

=head1 DESCRIPTION

This script tags a corpus with terms and provide a output compatible with Brat (<http://brat.nlplab.org/>). Corpus (C<corpus>) is a file
with one sentence per line. Term list (C<termlist>) is a file
containing one term per line. For each term, additionnal information
(as canonical form) can be given after a column. Each line of the
output file (C<selected_term_list>) contains the sentence number, the
term, additional information, all separated by a tabulation character.

==hea1 EXAMPLES

Tag the textual corpus in C<corpus-test.txt> with terms in the file
C<termlist-test.lst> and record the results in the file
C<corpus-test.ann>) according to the Brat input format:

TermTagger-brat.pl corpus-test.txt termlist-test.lst corpus-test.ann


=head1 SEE ALSO

Alvis web site: http://www.alvis.info

Brat: http://brat.nlplab.org/

=head1 AUTHORS

Thierry Hamon <thierry.hamon@limsi.fr>

=head1 LICENSE

Copyright (C) 2006 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

use strict;
use warnings;

use Alvis::TermTagger;

use Getopt::Long;
use Pod::Usage;

# Process Option

my $man = 0;
my $help = 0;

GetOptions('help|?' => \$help) or pod2usage(2);
pod2usage(1) if $help;
# pod2usage(-exitstatus => 0, -verbose => 2) if $man; 
# , man => \$man

Alvis::TermTagger::termtagging_brat($ARGV[0], $ARGV[1], $ARGV[2], $ARGV[3]);



