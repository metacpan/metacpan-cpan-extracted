=head1 NAME

Bio::DB::GFF::Aggregator::gene -- Sequence Ontology Geene

=head1 SYNOPSIS

  use Bio::DB::GFF;

  # Open the sequence database
  my $db      = Bio::DB::GFF->new( -adaptor => 'dbi:mysql',
                                   -dsn     => 'dbi:mysql:elegans42',
				   -aggregator => ['gene'],
				 );

 ------------------------------------------------------------------------
 Aggregator method: gene
 Main method:       mRNA
 Sub methods:       CDS exon five_prime_UTR three_prime_UTR transcription_start_site polyA_site
 ------------------------------------------------------------------------

=head1 DESCRIPTION

Bio::DB::GFF::Aggregator::gene is identical to so_transcript, but is
used in those cases where you would like the name of the aggregated
feature to be "gene" rather than "processed_transcript". It aggregates
raw "exon," "CDS", "five_prime_UTR", "three_prime_UTR",
"transcription_start_site" and "polyA_site" features into "mRNA"
features.  The UTRs may also be named "untranslated_region,"
"five_prime_untranslated_region," "three_prime_untranslated_region,",
"5'-UTR," and other synonyms.

=cut

package Bio::DB::GFF::Aggregator::gene;
$Bio::DB::GFF::Aggregator::gene::VERSION = '1.7.4';
use strict;

use base qw(Bio::DB::GFF::Aggregator);

=head2 method

 Title   : method
 Usage   : $aggregator->method
 Function: return the method for the composite object
 Returns : the string "gene"
 Args    : none
 Status  : Public

=cut

sub method { 'gene' }

=head2 part_names

 Title   : part_names
 Usage   : $aggregator->part_names
 Function: return the methods for the sub-parts
 Returns : the list CDS 5'-UTR 3'-UTR transcription_start_site polyA_site
 Args    : none
 Status  : Public

=cut

sub part_names {
  return qw(CDS transcription_start_site
	    polyA_site UTR five_prime_untranslated_region
	    three_prime_untranslated_region
	   five_prime_UTR three_prime_UTR exon);
}

=head2 main_name

 Title   : main_name
 Usage   : $aggregator->main_name
 Function: return the method for the main component
 Returns : the string "mRNA"
 Args    : none
 Status  : Public

=cut

sub main_name {
  return 'mRNA';
}

1;
__END__

=head1 BUGS

None reported.


=head1 SEE ALSO

L<Bio::DB::GFF>, L<Bio::DB::GFF::Aggregator>

=head1 AUTHOR

Lincoln Stein E<lt>lstein@cshl.orgE<gt>.

Copyright (c) 2008 Cold Spring Harbor Laboratory.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

