package Catmandu::Fix::Inline::marc_add;

use Catmandu::MARC;
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(marc_add);
%EXPORT_TAGS = (all => [qw(marc_add)]);

our $VERSION = '1.161';

sub marc_add {
    my ($data,$marc_path,@subfields) = @_;
    return Catmandu::MARC->instance->marc_add($data, $marc_path, @subfields);
}

=head1 NAME

Catmandu::Fix::Inline::marc_add- A marc_add-er for Perl scripts (DEPRECATED)

=head1 SYNOPSIS

 use Catmandu::Fix::Inline::marc_add qw(:all);

 # Set to a literal value
 my $data  = marc_add($data, '245',  a => 'value');

 # Set to a copy of a deeply nested JSON path
 my $data  = marc_add($data, '245',  a => '$.my.deep.field');

=head1 DEPRECATED

This module is deprecated. Use the inline functionality of L<Catmandu::Fix::marc_add> instead.

=head1 SEE ALSO

L<Catmandu::Fix::marc_add>

=cut

1;
