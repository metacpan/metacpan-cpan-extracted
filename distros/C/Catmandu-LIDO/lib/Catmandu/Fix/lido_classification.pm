package Catmandu::Fix::lido_classification;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;
use Catmandu::Fix::LIDO::Utility qw(walk declare_source);

use Catmandu::Fix::LIDO::Term qw(emit_term);

use strict;

our $VERSION = '0.10';

#https://librecatproject.wordpress.com/2014/03/26/create-a-fixer-part-2/

with 'Catmandu::Fix::Base';

has object_work_type        => (fix_arg => 1);
has classification          => (fix_arg => 1);
has object_work_type_id     => (fix_opt => 1);
has object_work_type_lang   => (fix_opt => 1);
has object_work_type_type   => (fix_opt => 1);
has object_work_type_source => (fix_opt => 1);
has object_work_type_pref   => (fix_opt => 1);
has classification_id       => (fix_opt => 1);
has classification_lang     => (fix_opt => 1);
has classification_type     => (fix_opt => 1);
has classification_source   => (fix_opt => 1);
has classification_pref     => (fix_opt => 1);


sub emit {
    my ($self, $fixer) = @_;

    my $path = ['descriptiveMetadata', 'objectClassificationWrap'];
    my $perl = '';

    $perl .= $fixer->emit_create_path(
        $fixer->var,
        $path,
        sub {
            my $r_root = shift;
            my $r_code = '';

            ##
            # classification
            if (defined($self->classification)) {
                $r_code .= emit_term($fixer, $r_root, 'classificationWrap.classification.$append',
                            $self->classification, $self->classification_id, $self->classification_lang, $self->classification_pref,
                            $self->classification_source, $self->classification_type);
            }

            ##
            # objectWorkType
            if (defined($self->object_work_type)) {
                $r_code .= emit_term($fixer, $r_root, 'objectWorkTypeWrap.objectWorkType.$append',
                            $self->object_work_type, $self->object_work_type_id, $self->object_work_type_lang, $self->object_work_type_pref,
                            $self->object_work_type_source, $self->object_work_type_type);
            }

            return $r_code;
        }
    );

    return $perl;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::lido_classification - create an C<objectClassificationWrap>.

=head1 SYNOPSIS

    lido_classification(
        object_work_type,
        classification,
        -object_work_type_id:       objectWorkType.conceptID,
        -object_work_type_lang:     objectWorkType.term.lang,
        -object_work_type_type:     objectWorkType.conceptID.type,
        -object_work_type_source:   objectWorkType.conceptID.source,
        -object_work_type_pref:     objectWorkType.conceptID.pref & objectWorkType.term.pref,
        -classification_id:         classification.conceptID,
        -classification_lang:       classification.term.lang,
        -classification_type:       classification.conceptID.type,
        -classification_source:     classification.conceptID.source,
        -classification_pref:       classification.conceptID.pref & classification.term.pref
    )

=head1 DESCRIPTION

C<lido_classification> will create a C<objectClassificationWrap> containing both the C<classificationWrap.classification> and the C<objectWorkTypeWrap.objectWorkType>.

=head2 PARAMETERS

=head3 Required parameters

C<object_work_type> and C<classification> are required path parameters.

=over

=item C<object_work_type>

=item C<classification>

=back

=head3 Optional parameters

C<object_work_type_id> and C<classification_id> are optional path parameters. All other parameters are strings.

=over

=item C<object_work_type_id>

=item C<classification_id>

=back

=over

=item C<object_work_type_lang>

=item C<object_work_type_type>

=item C<object_work_type_source>

=item C<object_work_type_pref>

=item C<classification_lang>

=item C<classification_type>

=item C<classification_source>

=item C<classification_pref>

=back

=head1 EXAMPLE

=head2 Fix

    lido_classification (
        recordList.record.object_name.value,
        recordList.record.object_cat.value,
        -object_work_type_id:     recordList.record.object_name.id,
        -object_work_type_lang:   nl,
        -object_work_type_type:   local,
        -object_work_type_source: Adlib,
        -object_work_type_pref:   preferred,
        -classification_id:       recordList.record.object_cat.id,
        -classification_lang:     nl,
        -classification_type:     local,
        -classification_source:   Adlib,
        -classification_pref:     preferred
    )

=head2 Result

    <lido:descriptiveMetadata>
        <lido:objectClassificationWrap>
            <lido:objectWorkTypeWrap>
                <lido:objectWorkType>
                    <lido:conceptID lido:type="local" lido:source="Adlib" lido:pref="preferred">123</lido:conceptID>
                    <lido:term xml:lang="nl">olieverfschilderij</lido:term>
                </lido:objectWorkType>
            </lido:objectWorkTypeWrap>
            <lido:classificationWrap>
                <lido:classification>
                    <lido:conceptID lido:pref="preferred" lido:type="local" lido:source="Adlib">123</lido:conceptID>
                    <lido:term lido:pref="preferred" xml:lang="nl">Schilderijen</lido:term>
                </lido:classification>
            </lido:classificationWrap>
        </lido:objectClassificationWrap>
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