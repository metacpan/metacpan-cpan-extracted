package Catmandu::Fix::Inline::marc_remove;

use Catmandu::MARC;
require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(marc_remove);
%EXPORT_TAGS = (all => [qw(marc_remove)]);

our $VERSION = '1.231';

sub marc_remove {
    my ($data,$marc_path) = @_;
    return Catmandu::MARC->instance->marc_remove($data,$marc_path);
}

=head1 NAME

Catmandu::Fix::Inline::marc_remove - remove marc fields (DEPRECATED)

=head1 SYNOPSIS

 use Catmandu::Fix::Inline::marc_remove qw(:all);

 my $data  = marc_remove($data,'CAT');

=head1 DEPRECATED

This module is deprecated. Use the inline functionality of L<Catmandu::Fix::marc_remove> instead.

=head1 SEE ALSO

L<Catmandu::Fix::marc_remove>

=cut

1;
