# BioPerl module for Bio::Community::IO::Driver::biom
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::IO::Driver::biom - Driver to read and write files in the sparse BIOM format

=head1 SYNOPSIS

   # Reading
   my $in = Bio::Community::IO->new(
      -file   => 'biom_communities.txt',
      -format => 'biom'
   );
   my $type = $in->get_matrix_type; # either dense or sparse

   # Writing
   my $out = Bio::Community::IO->new(
      -file        => 'biom_communities.txt',
      -format      => 'biom',
      -matrix_type => 'sparse', # default matrix type
   );

   # See Bio::Community::IO for more information

=head1 DESCRIPTION

This Bio::Community::IO::Driver::biom driver reads and writes files in the BIOM format
version 1.0 described at L<http://biom-format.org/documentation/format_versions/biom-1.0.html>.
Multiple communities and additional metadata can be recorded in a BIOM file.
Here is an example of minimal sparse BIOM file:

  {
      "id":null,
      "format": "Biological Observation Matrix 0.9.1-dev",
      "format_url": "http://biom-format.org",
      "type": "OTU table",
       "generated_by": "QIIME revision 1.4.0-dev",
      "date": "2011-12-19T19:00:00",
      "rows":[
              {"id":"GG_OTU_1", "metadata":null},
              {"id":"GG_OTU_2", "metadata":null},
              {"id":"GG_OTU_3", "metadata":null},
              {"id":"GG_OTU_4", "metadata":null},
              {"id":"GG_OTU_5", "metadata":null}
          ],
      "columns": [
              {"id":"Sample1", "metadata":null},
              {"id":"Sample2", "metadata":null},
              {"id":"Sample3", "metadata":null},
              {"id":"Sample4", "metadata":null},
              {"id":"Sample5", "metadata":null},
              {"id":"Sample6", "metadata":null}
          ],
      "matrix_type": "sparse",
      "matrix_element_type": "int",
      "shape": [5, 6],
      "data":[[0,2,1],
              [1,0,5],
              [1,1,1],
              [1,3,2],
              [1,4,3],
              [1,5,1],
              [2,2,1],
              [2,3,4],
              [2,4,2],
              [3,0,2],
              [3,1,1],
              [3,2,1],
              [3,5,1],
              [4,1,1],
              [4,2,1]
             ]
  }

Columns (i.e. communities) can be expressed in a richer way, e.g.:

  {"id":"Sample1", "metadata":{
                           "BarcodeSequence":"CGCTTATCGAGA",
                           "LinkerPrimerSequence":"CATGCTGCCTCCCGTAGGAGT",
                           "BODY_SITE":"gut",
                           "Description":"human gut"}},

The 'id' can be recovered from the name() method of the resulting Bio::Community.
Metadata fields are not recorded at this time, but will be in a future release.

Rows (i.e. community members) can also be expressed in a richer form:

  {"id":"GG_OTU_1", "metadata":{"taxonomy":["k__Bacteria", "p__Proteobacteria", "c__Gammaproteobacteria", "o__Enterobacteriales", "f__Enterobacteriaceae", "g__Escherichia", "s__"]}},

For each Bio::Community::Member generated, the id() method contains the 'id' and
desc() holds a concatenated version of the 'taxonomy' field. Note that you can
omit members entirely from a biom file and simply have community names and
metadata.

The 'comment' field of biom files is not recorded and simply ignored.

=head1 CONSTRUCTOR

See L<Bio::Community::IO>.

=head1 AUTHOR

Florent Angly L<florent.angly@gmail.com>

=head1 SUPPORT AND BUGS

User feedback is an integral part of the evolution of this and other Bioperl
modules. Please direct usage questions or support issues to the mailing list, 
L<bioperl-l@bioperl.org>, rather than to the module maintainer directly. Many
experienced and reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem with code and
data examples if at all possible.

If you have found a bug, please report it on the BioPerl bug tracking system
to help us keep track the bugs and their resolution:
L<https://redmine.open-bio.org/projects/bioperl/>

=head1 COPYRIGHT

Copyright 2011-2014 by Florent Angly <florent.angly@gmail.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut


package Bio::Community::IO::Driver::biom;

use Moose;
use Method::Signatures;
use namespace::autoclean;
use Bio::Community::Member;
use Bio::Community::TaxonomyUtils;
use JSON::XS qw( decode_json encode_json );
use DateTime;

use constant BIOM_NAME        => 'Biological Observation Matrix 1.0';
use constant BIOM_URL         => 'http://biom-format.org/documentation/format_versions/biom-1.0.html';
use constant BIOM_MATRIX_TYPE => 'sparse'; # sparse or dense
use constant BIOM_TYPE        => 'OTU table';
# "XYZ table" where XYZ is Pathway, Gene, Function, Ortholog, Metabolite or Taxon

extends 'Bio::Community::IO';
with 'Bio::Community::Role::IO';


our $multiple_communities   =  1;      # format supports several communities per file
our $explicit_ids           =  1;      # IDs are explicitly recorded
our $default_sort_members   =  0;      # unsorted
our $default_abundance_type = 'count'; # absolute count (positive integer)
our $default_missing_string =  0;      # empty members get a '0'


has 'matrix_type' => (
   is => 'rw',
   isa => 'Maybe[BiomMatrixType]',
   required => 0,
   init_arg => '-matrix_type',
   default => undef,
   lazy => 1,
   reader => 'get_matrix_type',
   writer => 'set_matrix_type',
   predicate => '_has_matrix_type',
);


has 'matrix_element_type' => (
   is => 'rw',
   #isa => 'Str', # either int, float or unicode
   required => 0,
   init_arg => undef,
   default => undef,
   lazy => 1,
   reader => '_get_matrix_element_type',
   writer => '_set_matrix_element_type',
);


has '_json' => (
   is => 'rw',
   #isa => 'JSON::XS',
   required => 0,
   init_arg => undef,
   default => undef,
   lazy => 1,
   predicate => '_has_json',
   reader => '_get_json',
   writer => '_set_json',
);


has '_max_line' => (
   is => 'rw',
   #isa => 'StrictlyPositiveInt',
   required => 0,
   init_arg => undef,
   lazy => 1,
   default => 0,
   reader => '_get_max_line',
   writer => '_set_max_line',
);


has '_max_col' => (
   is => 'rw',
   #isa => 'StrictlyPositiveInt',
   required => 0,
   init_arg => undef,
   lazy => 1,
   default => 0,
   reader => '_get_max_col',
   writer => '_set_max_col',
);


has '_line' => (
   is => 'rw',
   isa => 'PositiveInt',
   required => 0,
   init_arg => undef,
   default => 0,
   lazy => 1,
   reader => '_get_line',
   writer => '_set_line',
);


has '_col' => (
   is => 'rw',
   isa => 'PositiveInt',
   required => 0,
   init_arg => undef,
   default => 0,
   lazy => 1,
   reader => '_get_col',
   writer => '_set_col',
);


has '_members' => (
   is => 'rw',
   isa => 'HashRef', # HashRef{id} = Bio::Community::Member
   required => 0,
   init_arg => undef,
   default => sub { [] },
   lazy => 1,
   predicate => '_has_members',
   reader => '_get_members',
   writer => '_set_members',
);


has '_sorted_members' => (
   is => 'rw',
   isa => 'HashRef', # HashRef{species}{sample} = count
   required => 0,
   init_arg => undef,
   default => sub { {} },
   lazy => 1,
   reader => '_get_sorted_members',
   writer => '_set_sorted_members',
);


has '_id2line' => (
   is => 'rw',
   isa => 'HashRef', # HashRef[String] but keep it lean
   required => 0,
   init_arg => undef,
   default => sub { {} },
   lazy => 1,
);


method _next_community_init () {
   # Get community name and set column number
   my $col = $self->_get_col + 1;
   my $name;
   if ($self->_get_col <= $self->_get_max_col) {
      $name = $self->_get_json->{'columns'}->[$col-1]->{'id'};
   }
   $self->_set_col( $col );
   return $name;
}


method _parse_json () {
   # Retrieve all text content
   my $str = '';
   while (my $line = $self->_readline(-raw => 1)) {
      $str .= $line;
   }

   # Parse JSON string
   my $parser = JSON::XS->new();
   my $json;
   eval { $json = $parser->decode($str) };
   if ($@) {
      $self->throw("Biom file is not properly JSON-formatted: $@");
   }
   $self->_validate_biom($json);
   $self->_set_json($json);

   # Retrieve and store some information
   my ($max_line, $max_col) = @{$json->{'shape'}};
   $self->_set_max_line( $max_line );
   $self->_set_max_col( $max_col );
   $self->set_matrix_type($json->{'matrix_type'});
   $self->_set_matrix_element_type($json->{'matrix_element_type'});

   return $json;
}


method _validate_biom ($biom) {
   # Check that the biom content has all the mandatory fields. Also do some
   # basic validation to ensure that parsing will be successful. It is not a
   # comprehensive validation of the file format!

   my $msg = 'Biom file is invalid:';

   my @mandatory = qw( id format format_url type generated_by date rows columns
      matrix_type matrix_element_type shape data );
   for my $field (@mandatory) {
      if (not exists $biom->{$field}) {
         $self->throw("$msg missing mandatory '$field' field");
      }
   }

   for my $field (qw(rows columns)) {
      for my $subfield (qw(id metadata)) {
         for my $entry (@{$biom->{$field}}) {
            if (not exists $entry->{$subfield}) {
               $self->throw("$msg missing mandatory '$subfield' subfield of '$field' field");
            }
         }
      }
   }

   my $shape_rows = $biom->{'shape'}->[0];
   my $rows = scalar @{$biom->{'rows'}};
   if ($shape_rows != $rows) {
      $self->throw("$msg inconsistent number of rows between 'rows' ($rows) and 'shape' ($shape_rows)");
   }

   my $shape_cols = $biom->{'shape'}->[1];
   my $cols = scalar @{$biom->{'columns'}};
   if ($shape_cols != $cols) {
      $self->throw("$msg inconsistent number of columns between 'columns' ($cols) and 'shape' ($shape_cols)");
   }

   ### Validate that 'data' has the right shape?

   return 1;
}


method _generate_members () {
   my %members = ();
   for my $row (1 .. $self->_get_max_line) {
      my $json = $self->_get_json->{'rows'}->[$row-1];
      my $id = $json->{'id'};
      my $member = Bio::Community::Member->new( -id => $id );
      my $metadata = $json->{'metadata'};
      if (exists $metadata->{'taxonomy'}) {
         my $taxo_desc;
         if (ref($metadata->{'taxonomy'}) eq 'SCALAR') {
            $taxo_desc = $metadata->{'taxonomy'};
         } elsif (ref($metadata->{'taxonomy'}) eq 'ARRAY') {
            $taxo_desc = get_lineage_string($metadata->{'taxonomy'}, ' ');
         }
         $member->desc( $taxo_desc );
         $self->_attach_taxon($member, $taxo_desc, 1);
      }
      #if (exists $members{$id}) {
      #   $self->warn("Member with ID $id is present multiple times... ".
      #      "Continuing despite the perils!");
      #}
      $self->_attach_weights($member);
      $members{$id} = $member;
   }

   $self->_set_members(\%members);
   return 1;
}


method _sort_members_by_community {
   # Sort members by community to facilitate parsing
   my %sorted_members;
   my $json   = $self->_get_json;
   my $matrix = $json->{'data'};
   my $rows   = $json->{'rows'};
   for my $i (0 .. scalar @$matrix - 1) {
      my ($row, $sample, $count) = @{$matrix->[$i]};
      if ($count > 0) {
         my $species = $rows->[$row]->{'id'};
         $sorted_members{$sample}{$species} += $count; # merge duplicates
      }
   }
   $self->_set_sorted_members(\%sorted_members);
   return 1;
}


method next_member () {
   my ($id, $member, $count);
   my $col     = $self->_get_col;
   my $members = $self->_get_members;
   my $json    = $self->_get_json;
   if (defined $json->{'matrix_type'}) {
      if ($json->{'matrix_type'} eq 'sparse') { # sparse matrix format

         my $sorted_members = $self->_get_sorted_members;
         my @ids = keys %{$sorted_members->{$col-1}};
         if (scalar @ids > 0) {
            $id = shift @ids;
            $count = delete $sorted_members->{$col-1}->{$id};
            $self->_set_sorted_members($sorted_members);
         }

      } else { # dense matrix format

         my $rows   = $json->{'rows'};
         my $matrix = $json->{'data'};
         my $line   = $self->_get_line;
         while ( ++$line ) {
            # Get the abundance of the member (undef if out-of-bounds)
            $count = $matrix->[$line-1]->[$col-1];
            if (defined $count) {
               if ($count > 0) {
                  $id = $rows->[$line-1]->{'id'};
                  $self->_set_line($line);
                  last;
               }
            } else {
               # No more members for this community
               $self->_set_line(0);
               last;
            }
         }
      }
   }
   if (defined $id) {
      $member = $members->{$id};
   }
   return $member, $count;
}


method _next_community_finish () {
   return 1;
}


method _next_metacommunity_init () {
   $self->_parse_json(); # Parse the JSON string
   $self->_generate_members(); # Generate all Bio::Community::Members
   # Sort members when reading sparse matrix
   # (if there are no species in the biom file yet, matrix type is not defined)
   my $matrix_type = $self->get_matrix_type;
   if ( (defined $matrix_type) && ($matrix_type eq 'sparse') ) {
      $self->_sort_members_by_community();
   }
   my $name = $self->_get_json->{'id'};
   return $name;
}


method _next_metacommunity_finish () {
   return 1;
}


method _write_community_init (Bio::Community $community) {
   # Write community information
   my $json = $self->_get_json;
   push @{$json->{'columns'}}, { 'id' => $community->name, 'metadata' => undef };
   $self->_set_json($json);
   $self->_set_col( $self->_get_col + 1);
   return 1;
}


method _write_headers ($name) {
   my $json = {};
   # Write some generic information
   $json->{'id'}           = $name;
   $json->{'format'}       = BIOM_NAME;
   $json->{'format_url'}   = BIOM_URL;
   $json->{'type'}         = BIOM_TYPE;
   $json->{'generated_by'} = 'Bio::Community version '.$Bio::Community::VERSION;
   $json->{'date'}         = DateTime->now->datetime; # ISO 8601, e.g. 2011-12-19T19:00:00
   $json->{'matrix_type'}  = $self->get_matrix_type;
   # Also create a couple of mandatory fields (but leave them empty)
   $json->{'rows'}         = undef;
   $json->{'columns'}      = undef;
   $json->{'data'}         = undef;
   $self->_set_json($json);
   return 1;
}


method write_member (Bio::Community::Member $member, Count $count) {
   my $json = $self->_get_json;
   my $id = $member->id;

   # Check if count is integer or float
   if (not defined $self->_get_matrix_element_type) {
      # assume integer until proven otherwise
      $self->_set_matrix_element_type('int'); 
   }
   if ($self->_get_matrix_element_type eq 'int') {
      if ($count =~ /\D/) {
         # Count has at least one non-digit character
         $self->_set_matrix_element_type('float');
      }
   }

   # Update 'rows' records if needed
   my $line = $self->_id2line->{$id};
   if (not defined $line) {
      # This member has not been written previously for another community
      $line = $self->_get_line + 1;
      my $member_rec = { 'id' => $id, 'metadata' => undef };
      my $desc = $member->desc;
      if (not $desc eq '') {
         my $taxonomy = Bio::Community::TaxonomyUtils::split_lineage_string($desc, 0);
         $member_rec->{'metadata'}->{'taxonomy'} = $taxonomy;
      }
      push @{$json->{'rows'}}, $member_rec;
      $self->_id2line->{$id} = $line;
      $self->_set_line( $line );
   }

   # Update 'data' records: use +0 to make counts be used as numbers (not strings)
   my $col = $self->_get_col;
   if ($self->get_matrix_type eq 'sparse') {
      push @{$json->{'data'}}, [$line-1, $col-1, $count+0];
   } else {
      $json->{'data'}->[$line-1]->[$col-1] = $count+0;
   }
   $self->_set_json($json);

   return 1;
}


method _write_community_finish (Bio::Community $community) {
   return 1;
}


method _write_metacommunity_init (Bio::Community::Meta $meta) {
   # Set default matrix type to sparse
   if (not $self->_has_matrix_type) {
      $self->set_matrix_type('sparse');
   }
   # Write some generic header information
   my $name;
   if (defined $meta) {
      $name = $meta->name;
   }
   $self->_write_headers($name);
   return 1;
}


method _write_metacommunity_finish (Bio::Community::Meta $meta) {
   # Write JSON to file
   my $rows = $self->_get_line;
   my $cols = $self->_get_col;
   if ($rows == 0) {
      $self->_set_matrix_element_type( undef );
      $self->set_matrix_type( undef );
   }
   my $json = $self->_get_json;
   $json->{'shape'} = [$rows+0, $cols+0];
   $json->{'matrix_element_type'} = $self->_get_matrix_element_type;
   $json->{'matrix_type'} = $self->get_matrix_type;
   if ((defined $self->get_matrix_type) && ($self->get_matrix_type eq 'dense')) {
      $self->_fill_missing();
   }
   my $writer = JSON::XS->new->pretty;
   my $str = $writer->encode($json);
   $self->_print($str);
   return 1;
}


method _fill_missing () { 
   my $json = $self->_get_json;
   my $data = $json->{'data'};
   my $max_col = $self->_get_col - 1;
   for my $row (0 .. scalar @$data - 1) {
      my $row_data = $data->[$row];
      for my $col (0 .. $max_col) {
         if (not defined $row_data->[$col]) {
            $row_data->[$col] = $default_missing_string;
         }
      }
   }
   $self->_set_json($json);
   return 1;
}



__PACKAGE__->meta->make_immutable;

1;
