=head1 NAME

Catmandu::Fix::Inline::marc_map - A marc_map-er for Perl scripts (DEPRECATED)

=head1 SYNOPSIS

 use Catmandu::Fix::Inline::marc_map qw(:all);

 my $title   = marc_map($data,'245a');
 my @authors = marc_map($data,'100ab');

 # Get all 245 in an array
 @arr = marc_map($data,'245');

 # Or as a string
 $str = marc_map($data,'245');

 # str joined by a semi-colon
 $f245 = marc_map($data, '245', -join , ';');

 # Get the 245-$a$b$c subfields ordered as given in the record
 $str = marc_map($data,'245abc');

 # Get the 245-$c$b$a subfields orders as given in the mapping
 $str = marc_map($data,'245cba', -pluck => 1);

 # Get the 008 characters 35-35
 $str = marc_map($data,'008_/35-35');

 # Get all 100 subfields except the digits
 $str = marc_map($data,'100^0123456789');

 # If the 260c exist set the output to 'OK' (else undef)
 $ok  = marc_map($data,'260c',-value => 'OK');

 # The $data should be a Catmandu-style MARC hash
 { record => [
    ['field', 'ind1' , 'ind2' , 'subfieldcode or underscore' , 'data' , 'subfield' , 'data' , ...] ,
     ...
 ]};

 # Example
 $data = { record => [
    ['001' , ' ', ' ' , '_' , 'myrecord-001' ] ,
    ['020' , ' ', ' ' , 'a' , '978-1449303587' ] ,
    ['245' , ' ', ' ' , 'a' , 'Learning Per' , 'c', '/ by Randal L. Schwartz'],
 ]};

=head1 DEPRECATED

This module is deprecated. Use the inline functionality of L<Catmandu::Fix::marc_map> instead.

=head1 SEE ALSO

L<Catmandu::Fix::Inline::marc_map>

=cut

package Catmandu::Fix::Inline::marc_map;

use Catmandu::MARC;
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(marc_map);
%EXPORT_TAGS = (all => [qw(marc_map)]);

our $VERSION = '1.281';

sub marc_map {
    my ($data,$marc_path,%opts) = @_;
    # Set default to nested_arrays for backwards compatibility
    $opts{'-join'}  = ''        unless exists $opts{'-join'};
    $opts{'-split'} = 0         unless exists $opts{'-split'};
    $opts{'-pluck'} = 0         unless exists $opts{'-pluck'};
    $opts{'-nested_arrays'} = 1 unless exists $opts{'-nested_arrays'};
    $opts{'-no-implicit-split'} = 1;
    $opts{'-force_array'} = 1 if (wantarray);

    my $vals = Catmandu::MARC->instance->marc_map(
                $data,
                $marc_path,
                \%opts);

    $vals = $vals->[0] if $opts{'-split'};

    if (wantarray) {
        defined($vals) && ref($vals) eq 'ARRAY' ? @$vals : ($vals);
    }
    else {
        $vals;
    }
}

1;
