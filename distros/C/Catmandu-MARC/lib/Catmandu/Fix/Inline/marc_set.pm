package Catmandu::Fix::Inline::marc_set;

use Catmandu::MARC;
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(marc_set);
%EXPORT_TAGS = (all => [qw(marc_set)]);

our $VERSION = '1.13';

sub marc_set {
    my ($data,$marc_path,$value) = @_;
    return Catmandu::MARC->instance->marc_set($data,$marc_path,$value);
}

=head1 NAME

Catmandu::Fix::Inline::marc_set - A marc_set-er for Perl scripts (DEPRECATED)

=head1 SYNOPSIS

 use Catmandu::Fix::Inline::marc_set qw(:all);

 # Set to literal value
 my $data  = marc_set($data,'245[1]a', 'value');

 # Set to a copy of a deeply nested JSON path
 my $data  = marc_set($data,'245[1]a', '$.my.deep.field');

 =head1 DEPRECATED

 This module is deprecated. Use the inline functionality of L<Catmandu::Fix::marc_set> instead.

 =head1 SEE ALSO

 L<Catmandu::Fix::marc_set>

=cut

1;
