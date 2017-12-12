package Catmandu::Fix::lido_baseid;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;
use Catmandu::Fix::LIDO::Utility qw(walk);
use Catmandu::Fix::LIDO::ID qw(emit_base_id);

use strict;

our $VERSION = '0.10';

#https://librecatproject.wordpress.com/2014/03/26/create-a-fixer-part-2/

with 'Catmandu::Fix::Base';

has path     => (fix_arg => 1);
has id_value => (fix_arg => 1);
has type 	 => (fix_opt => 1);
has source   => (fix_opt => 1);
has label    => (fix_opt => 1);
has pref	 => (fix_opt => 1);

sub emit {
	my ($self, $fixer) = @_;
	my $perl = '';

	$perl .= emit_base_id($fixer, $fixer->var, $self->path, $self->id_value, $self->source, $self->label, $self->type, $self->pref);

	$perl;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::lido_baseid - Create a basic id component in a C<path>

=head1 SYNOPSIS

	lido_baseid(
		path,
		id_value,
		-type:   ID.type,
		-source: ID.source,
		-label:  ID.label
	)

=head1 DESCRIPTION

This component will assist in the creation of generic LIDO ID nodes, of the form C<<lido:ID attributes>value</lido:ID>>.

The nodes will be created in the path provided by C<path>.

=head2 PARAMETERS

=head3 Required parameters

The parameters C<path> and C<id_value> are mandatory paths.

=over

=item C<path>

=item C<id_value>

=back

=head3 Optional parameters

All optional parametes are strings.

=over

=item C<type>

=item C<source>

=item C<label>

=back

=head1 EXAMPLE

=head2 Fix

	lido_baseid(
		lidoRecID,
		recordList.record.object_number,
		-source: 'Museum voor Schone Kunsten Gent',
		-type:   'global',
		-label:  'dataPID'
	)

=head2 Result

	<lido:lidoRecID lido:type="global" lido:source="Museum voor Schone Kunsten Gent" lido:label="dataPID">1812-A</lido:lidoRecID>

=head2 MULTIPLE INSTANCES

Repeated invocations of the fix with the same path will result in a new ID node at the specified path. No nodes will be overwritten.

=head1 SEE ALSO

L<Catmandu::LIDO> and L<Catmandu>

=head1 AUTHORS

=over

=item Pieter De Praetere, C<< pieter at packed.be >>

=back

=head1 CONTRIBUTORS

=over

=item Pieter De Praetere, C<< pieter at packed.be >>

=item Matthias Vandermaesen, C<< matthias.vandermaesen at vlaamsekunstcollectie.be >>

=back

=head1 COPYRIGHT AND LICENSE

The Perl software is copyright (c) 2016 by PACKED vzw and VKC vzw.
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=encoding utf8

=cut