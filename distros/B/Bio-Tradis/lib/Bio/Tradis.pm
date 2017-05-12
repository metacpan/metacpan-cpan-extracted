use strict;
use warnings;
package Bio::Tradis;
$Bio::Tradis::VERSION = '1.3.3';
# ABSTRACT: Bio-Tradis contains a set of tools to analyse the output from TraDIS analyses. For more information on the TraDIS method, see http://genome.cshlp.org/content/19/12/2308

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Tradis - Bio-Tradis contains a set of tools to analyse the output from TraDIS analyses. For more information on the TraDIS method, see http://genome.cshlp.org/content/19/12/2308

=head1 VERSION

version 1.3.3

=head1 SYNOPSIS

Bio-Tradis provides functionality to:

=over

=item * detect TraDIS tags in a BAM file - L<Bio::Tradis::DetectTags>

=item * add the tags to the reads - L<Bio::Tradis::AddTagsToSeq>

=item * filter reads in a FastQ file containing a user defined tag - L<Bio::Tradis::FilterTags>

=item * remove tags - L<Bio::Tradis::RemoveTags>

=item * map to a reference genome - L<Bio::Tradis::Map>

=item * create an insertion site plot file - L<Bio::Tradis::TradisPlot>

=back

Most of these functions are available as standalone scripts or as perl modules.

=head1 AUTHOR

Carla Cummins <path-help@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
