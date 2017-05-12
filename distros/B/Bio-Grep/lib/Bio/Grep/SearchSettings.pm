#############################################################################
#   $Author: markus $
#     $Date: 2009-11-12 17:13:23 +0100 (Thu, 12 Nov 2009) $
# $Revision: 1844 $
#############################################################################

package Bio::Grep::SearchSettings;

use strict;
use warnings;

use Data::Dumper;
use Scalar::Util qw(reftype);

use version; our $VERSION = qv('0.10.6');

use Class::MethodMaker [
    new    => 'new2',
    scalar => [
        qw /mismatches insertions deletions editdistance query query_length
            _real_query gumismatches upstream downstream maxhits no_alignments
            datapath database online tmppath execpath reverse_complement direct_and_rev_com
            sort complete query_file showdesc qspeedup hxdrop exdrop/
    ],
    array => [qw /filters/],
];

sub new {
    my $self = shift->new2;

    # initialize standard settings
    $self->_init();
    return $self;
}

sub _init {
    my ($self) = @_;
    $self->mismatches(0);
    $self->insertions(0);
    $self->deletions(0);
    $self->editdistance_reset;
    $self->gumismatches(1);
    $self->no_alignments(0);
    $self->upstream(0);
    $self->downstream(0);
    $self->reverse_complement(0);
    $self->direct_and_rev_com(0);
    $self->query_reset;
    $self->query_file_reset;
    $self->online_reset;
    $self->sort_reset;
    $self->complete_reset;
    $self->query_length_reset;
    $self->maxhits_reset;
    $self->showdesc_reset;
    $self->qspeedup_reset;
    return;
}

sub set_attributes {
    my ( $self, $arg_ref ) = @_;

    # set default values first
    $self->_init();
    for my $key ( keys %{$arg_ref} ) {
        my $rt = reftype $arg_ref->{$key};
        if ( defined $rt ) {
            if ( $rt eq 'ARRAY' ) {
                $self->$key( @{ $arg_ref->{$key} } );
            }
            else {
                $self->$key( $arg_ref->{$key} );
            }
        }
        else {
            $self->$key( $arg_ref->{$key} );
        }
    }
    return;
}

sub to_string {
    my $self = shift;
    return Data::Dumper->Dump( [$self] );
}
1;    # Magic true value required at end of module
__END__

=head1 NAME

Bio::Grep::SearchSettings - Data structure for all search settings 

=head1 SYNOPSIS

 use Bio::Grep;

 # configure our search back-end, in this case VMATCH
 my $sbe = Bio::Grep->new('Vmatch');
 
 # tell the back-end the location of the executables
 # (only required if they are not in path)
 $sbe->settings->execpath('/usr/local/virtual.distrib');

 # maybe an alternative path for temporary files
 $sbe->settings->tmppath($tmp_path);

 # some query options
 $sbe->settings->mismatches(4);
 $sbe->settings->datapath($path_to_data_directory);
 $sbe->settings->database("ATH1.cdna");
 
 # retrieve upstream and downstream regions
 # see perldoc Bio::Grep::SearchResult
 # how to get them out of the search results
 $sbe->settings->upstream(3);
 $sbe->settings->downstream(3);
 
 # search for the reverse complement 
 $sbe->settings->query("UGAACAGAAAGCUCAUGAGCC");
 $sbe->settings->reverse_complement(1);

 # Alternatively, you can specify the options in the search call:
 $sbe->search({
    query => $query,
    reverse_complement => 1,
 });

 # Bio::Seq objects are also allowed
 $sbe->search({
    query => Bio::Seq->new( -id   => 1,
                            -desc => 'My Query',
                            -seq  => $query,
                            ),
 });

=head1 DESCRIPTION

B<Bio::Grep::SearchSettings> is the data structure for all search settings.
Not all back-ends will support every option.

=head1 METHODS

=head2 CONSTRUCTOR

=over 

=item C<new()>

This function constructs an C<Bio::Grep::SearchSettings> object. The
back-end adds an object of this module into C<$sbe-E<gt>settings>, so you
should never have to call this constructor directly. If you want to reset all
settings to their default values, call

  $sbe->settings->set_attributes({});

See set_attributes().

=back

=head2 PACKAGE METHODS

=over

=item C<set_attributes($hash_ref)>

Sets all settings in the hash reference:

  set_attributes( { query => $query, reverse_complement => 1 } );

This function resets everything except the paths and the database to default
values.

=item C<to_string()> 

This function returns a string representation of this object

=back

=head2 ACCESSORS/MUTATORS

Following the Bioperl guidelines, accessors are also mutators:

  $sbe->settings->query('CCCCC');
  print $sbe->settings->query; # prints CCCCC

=over

=item C<query()>

Get/Set the query, a string or a L<Bio::Seq> object. Queries are DNA, RNA, Protein or regular
expressions but not all back-ends support all three query types.

Maybe this will change in future versions to allow multiple queries.

   # a string ...
   $sbe->settings->query('tgacagaagagagtgagcac');


   # ... or a Bio::Seq object
   my $seq = Bio::Seq->new(-id   => 1,
                           -desc => 'Query',
                           -sec  => 'tgacagaagagagtgagcac'
                          );

   $sbe->settings->query($seq);
                          

=item C<query_file()>

Get/set C<query_file>. The back-ends can create a query file based on the search
settings ($sbe->query()) or you can define one with $sbe->query_file.

    $sbe->settings->query_file('oligos.fasta');

Note that all settings that affect the creation of a query file (like reverse_
complement) may be ignored (depends on your back-end).

Currently only available in the Vmatch and GUUGle back-end.

=item C<reverse_complement()>

Get/set C<reverse_complement>.

   #  search for the reverse complement
   $sbe->settings->reverse_complement(1)
   
   #  don't search for the reverse complement (default)
   $sbe->settings->reverse_complement(0)

=item C<direct_and_rev_com()>

Get/set C<direct_and_rev_com>. Searches for direct matches and the reverse
complement. 

Currently only available in Vmatch (-d AND -p flag), GUUGle (query file with two queries), and RE (regex
C<$query|$rev_com_query>).

=item C<mismatches()>

Get/Set allowed mismatches

   $sbe->settings->mismatches(5)

Not available in the GUUGle back-end.

=item C<editdistance()>

Get/Set allowed edit distance. 

Only available in the Vmatch and Agrep back-end.

=item C<deletions()>

Get/Set allowed number of deletions. Not supported by any back-end.

=item C<insertions()>

Get/Set allowed number of insertions. Not supported by any back-end.

=item C<upstream()>

Get/set C<upstream>. This is the number of bases upstream the match.
 
   $sbe->settings->upstream( 10 );

Not available in the Agrep back-end.

=item C<downstream()>

Get/set C<downstream>. This is the number of bases downstream the match.
   
   $sbe->settings->downstream( 10 );

Not available in the Agrep back-end.

=item C<filters()>

Get/set the filters. This is an array of modules based on L<Bio::Grep::Filter::FilterI>.

   # display only possible targets of the miRNA query   
   my $filter1 = Bio::Grep::Filter::MIRNAFilter->new();
   
   # and display every gene id only once
   my $filter2 = Bio::Grep::Filter::FilterRemoveDuplicates->new();

   $sbe->settings->filters( ( $filter1, $filter2 ) );

Not available in the Agrep back-end.

=item C<datapath()>

Get/set the datapath. This is the path to the databases for the back-end.
Default is current directory ('./').

=item C<database()>

Get/set the database. This is the name of the database in $self->datapath

=item C<tmppath()>

Get/set the tmppath. This is a path were the back-end can store temporary files.

=item C<execpath()>

Get/set the execpath. This is a path to the back-end executable. If you don't
set it, make sure that the required executables are in path.

=item C<no_alignments()>

Get/set the no_alignments. Some back-ends like Agrep don't output alignments. 
The EMBOSS Smith-Waterman implementation will automatically generate
alignments for a search result. For performance reasons, you can turn turn
this feature off:

  # if things need to be fast, turn alignments off
  $sbe->settings->no_alignments(1);

Not available (meaning not necessary) in the Vmatch and GUUGle back-end.

=item C<online()>

Get/set C<online>. Vmatch back-end allows searching without using the index. When
you allow many mismatches, this could be faster. 

Only available in the Vmatch back-end.

=item C<sort()>

Get set sort mode. You can get an hash with all available sort modes (including
a description from the back-end:

  my %sort_modes = $sbe->available_sort_modes();

=item C<maxhits()>

Get/set C<maxhits>. Tells the back-end that it should output only the best or
first (see back-end documentation) I<n> hits.

Not available in the C<Agrep> back-end.

=item C<gumismatches()>

Get/set C<gumismatches>. Tells the back-end how it should count GU mismatches.
Valid values in C<GUUGle> are 0, in all other back-ends 1 (default).

Only available in the C<GUUGle> back-end.

=item C<query_length()>

Get/Set the query length. Initialized with length of the query string. If
this member variable is smaller then the query string, then the back-end will
search for all substrings of that size. 

Only available in the C<Vmatch> and C<GUUGle> back-end.

=back

=head3 Vmatch only

=over

=item C<complete()>

Get/set complete. Specify that query sequences must match completely.

    $sbe->settings->complete(1);

=item C<hxdrop()>

Specifies the xdrop value for hamming distance extension.

=item C<exdrop()>

Specifies the xdrop value for edit distance extension.

=item C<showdesc()>

Get/Set showdesc. This Vmatch command line option makes the Vmatch parser
fetch the $sbe->result->sequence data directly out of the Vmatch output
instead of calling C<vseqsubselect>. Because of that, it is much faster with
many search results. You can't use this option if you want to retrieve up- or
downstream regions or if you are interested in the Vmatch internal sequence
id.

    # get the first 10 characters of the sequence description
    # (sequence id + annotation)
    $sbe->settings->showdesc(10);
    
=item C<qspeedup()>

Get/Set qspeedup. Specify speedup level when matching queries
(0: fast, 2: faster; default is 2). Beware of time/space trade-off.
             
=back

NOTE: You can use the hash C<features> from the back-end to check if some
feature is available or not. See L<Bio::Grep::Backend::BackendI>
for details.

=head1 SEE ALSO

L<Bio::Grep::Filter::FilterI>
L<Bio::Grep::SearchResult>
L<Bio::Grep::Backend::BackendI>

=head1 AUTHOR

Markus Riester, E<lt>mriester@gmx.deE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2009 by M. Riester. 

Based on Weigel::Search v0.13, Copyright (C) 2005-2006 by Max Planck 
Institute for Developmental Biology, Tuebingen.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
