package Catmandu::Fix::lido_basenameset;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;
use Catmandu::Fix::LIDO::Utility qw(walk);
use Catmandu::Fix::LIDO::Nameset qw(emit_nameset);

use strict;

our $VERSION = '0.09';


with 'Catmandu::Fix::Base';

has path        => (fix_arg => 1);
has value       => (fix_arg => 1);
has value_pref  => (fix_opt => 1);
has value_lang  => (fix_opt => 1);
has source      => (fix_opt => 1);
has source_lang => (fix_opt => 1);

sub emit {
    my ($self, $fixer) = @_;

    my $perl = '';

#$fixer, $path, $appellation_value, $appellation_value_lang,
#$appellation_value_type, $appellation_value_pref, $source_appellation, $source_appellation_lang
#$parent_type
    $perl .= emit_nameset($fixer, $fixer->var, $self->path, $self->value, $self->value_lang, undef, $self->value_pref,
    $self->source, $self->source_lang);

    return $perl;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::lido_basenameset - Create a basic nameset in a C<path>

=head1 SYNOPSIS

    lido_basenameset (
        path,
        value,
        -value_pref:  appellationValue.pref,
        -value_lang:  appellationValue.lang,
        -source:      sourceAppellation,
        -source_lang: sourceAppellation.lang
    )

=head1 DESCRIPTION

C<lido_basenameset> creates a basic LIDO node that contains both C<appellationValue> and C<sourceAppellation> at a specified C<path>.

=head2 PARAMETERS

=head3 Required parameters

C<path> and C<value> are required parameters that must be a path.

=over

=item C<path>

=item C<value> (appellationValue)

=back

=head3 Optional parameters

C<source> must be a path, all the other parameters are strings.

=over

=item C<source> (sourceAppellation)

=back

=over

=item C<value_pref>

=item C<value_lang>

=item C<source_lang>

=back

=head2 MULTIPLE INSTANCES

Multiple instances can be created in two ways, depending on whether you want to repeat the parent element or not.

If you do not want to repeat the parent element, call the function multiple times with the same C<path>. Multiple C<appellationValue> and C<sourceAppellation> tags will be created on the same level.

If you do want to repeat the parent element (to keep related C<appellationValue> and C<sourceAppellation> together), add an C<$append> to your path for all calls.

=head1 EXAMPLE

=head2 Fix

    lido_basenameset(
        descriptiveMetadata.objectIdentificationWrap.titleWrap.titleSet,
        recordList.record.title.value,
        -value_lang:  nl,
        -value_pref:  preferred,
        -source:      recordList.record.title.source,
        -source_lang: nl
    )

=head2 Result

    <lido:descriptiveMetadata>
        <lido:objectIdentificationWrap>
            <lido:titleWrap>
                <lido:titleSet>
                    <lido:appellationValue lido:pref="preferred" xml:lang="nl">Naderend onweer</lido:appellationValue>
                    <lido:sourceAppellation xml:lang="nl">MSK Gent</lido:sourceAppellation>
                </lido:titleSet>
            </lido:titleWrap>
        </lido:objectIdentificationWrap>
    </lido:descriptiveMetadata>

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