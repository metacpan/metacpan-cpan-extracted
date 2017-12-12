package Catmandu::Fix::lido_term;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;
use Catmandu::Fix::LIDO::Term qw(emit_term);

use strict;

our $VERSION = '0.10';

with 'Catmandu::Fix::Base';

has path      => ( fix_arg => 1);
has term      => ( fix_arg => 1 );
has conceptid => ( fix_opt => 1 );
has lang      => ( fix_opt => 1 );
has pref      => ( fix_opt => 1 );
has source    => ( fix_opt => 1 );
has type      => ( fix_opt => 1 );

sub emit {
    my ( $self, $fixer ) = @_;

 #   print Dumper $fixer;

    my $perl = '';

    $perl .= emit_term($fixer, $fixer->var, $self->path, $self->term, $self->conceptid,
    $self->lang, $self->pref, $self->source, $self->type);

    return $perl;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::lido_term - create a C<term> and C<conceptID> node in a C<path>

=head1 SYNOPSIS

    lido_term(
        path,
        term,
        -conceptid: conceptID,
        -lang:      term.lang,
        -pref:      term.pref,
        -source:    conceptID.source,
        -type:      conceptID.type
    )

=head1 DESCRIPTION

Create a node consisting of a C<term> and a C<conceptID> in a C<path>.

=head2 PARAMETERS

=head3 Required parameters

The parameters C<term> and C<path> are required path parameters.

=over

=item C<term>

=item C<path>

=back

=head3 Optional parameters

C<conceptid> is an optional path parameter.

=over

=item C<conceptid>

=back

All other optional parameters are strings.

=over

=item C<lang>

=item C<pref>

=item C<source>

=item C<type>

=back

=head2 MULTIPLE INSTANCES

Multiple instances can be created in two ways, depending on whether you want to repeat the parent element or not.

If you do not want to repeat the parent element, call the fixn multiple times with the same C<path>. Multiple C<term> and C<conceptID> tags will be created on the same level.

If you do want to repeat the parent element (to keep related C<term> and C<conceptID> together), add an C<$append> to your path.

=head1 EXAMPLE

=head2 Fix

    lido_term(
        category,
        recordList.record.category.value,
        -conceptid: recordList.record.category.id,
        -type: global,
        -source: 'cidoc-crm'
    )

=head2 Result

    <lido:category>
        <lido:conceptID lido:type="global" lido:source="cidoc-crm">123</lido:conceptID>
        <lido:term>Paintings</lido:term>
    </lido:category>

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