package Catmandu::Fix::lido_actor;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;
use Catmandu::Fix::LIDO::Term qw(emit_term);
use Catmandu::Fix::LIDO::ID qw(emit_base_id);
use Catmandu::Fix::LIDO::Nameset qw(emit_nameset);
use Catmandu::Fix::LIDO::Value qw(emit_base_value emit_simple_value);

use strict;

our $VERSION = '0.09';

with 'Catmandu::Fix::Base';

has path            => (fix_arg => 1);
has id              => (fix_arg => 1);
has name            => (fix_arg => 1);
has name_lang       => (fix_opt => 1);
has name_pref       => (fix_opt => 1);
has id_label        => (fix_opt => 1);
has id_source       => (fix_opt => 1);
has id_type         => (fix_opt => 1);
has nationality     => (fix_opt => 1); # Path
has birthdate       => (fix_opt => 1);
has deathdate       => (fix_opt => 1);
has role            => (fix_opt => 1);
has role_id         => (fix_opt => 1);
has role_id_type    => (fix_opt => 1);
has role_id_source  => (fix_opt => 1);
has qualifier       => (fix_opt => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $perl = '';
    my $new_path = $fixer->split_path($self->path);

    my $paths = {};
    $paths->{'id'} = ['actor', 'actorID'];
    $paths->{'name'} = ['actor', 'nameActorSet', '$append'];
    $paths->{'nationality'} = ['actor', 'nationalityActor'];
    $paths->{'dates'} = ['actor', 'vitalDatesActor'];
    $paths->{'role'} = ['roleActor'];
    $paths->{'attribution'} = ['attributionQualifierActor'];

    push @$new_path, 'actorInRole';

    $perl .= $fixer->emit_create_path(
        $fixer->var,
        $new_path,
                sub {
                    my $r_root = shift;
                    my $r_code = '';

                    ##
                    # actorID
                    # $fixer, $root, $path, $id, $source, $label, $type
                    if (defined($self->id)) {
                        $r_code .= emit_base_id($fixer, $r_root, join('.', @{$paths->{'id'}}), $self->id, $self->id_source, $self->id_label, $self->id_type);
                    }

                    ##
                    # nameActorSet
                    # $fixer, $root, $path, $appellation_value, $appellation_value_lang, $appellation_value_type,
                    # $appellation_value_pref, $source_appellation, $source_appellation_lang
                    if (defined($self->name)) {
                        $r_code .= emit_nameset($fixer, $r_root, join('.', @{$paths->{'name'}}), $self->name, $self->name_lang, undef, $self->name_pref);
                    }

                    ##
                    # nationalityActor
                    # $fixer, $root, $path, $term, $conceptid, $lang, $pref, $source, $type
                    if (defined($self->nationality)) {
                        $r_code .= emit_term($fixer, $r_root, join('.', @{$paths->{'nationality'}}), $self->nationality);
                    }

                    ##
                    # vitalDatesActor
                    $r_code .= $fixer->emit_create_path(
                        $r_root,
                        $paths->{'dates'},
                        sub {
                            my $d_root = shift;
                            my $d_code = '';

                            ##
                            # earliestDate
                            if (defined($self->birthdate)) {
                                $d_code .= emit_simple_value($fixer, $d_root, 'earliestDate', $self->birthdate);
                            }

                            ##
                            # latestDate
                            if (defined($self->deathdate)) {
                                $d_code .= emit_simple_value($fixer, $d_root, 'latestDate', $self->deathdate);
                            }

                            return $d_code;
                        }
                    );

                    ##
                    # roleActor
                    if (defined($self->role)) {
                        $r_code .= emit_term($fixer, $r_root, join('.', @{$paths->{'role'}}), $self->role, $self->role_id, undef, undef, $self->role_id_source, $self->role_id_type);
                    }

                    ##
                    # attributionQualifierActor
                    # $fixer, $root, $path, $value, $lang, $pref, $label, $type
                    if (defined($self->qualifier)) {
                        $r_code .= emit_base_value($fixer, $r_root, join('.', @{$paths->{'attribution'}}), $self->qualifier);
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

Catmandu::Fix::lido_actor - create a LIDO actorInRole node at a specified path

=head1 SYNOPSIS

    lido_actor(
        path,
        id,
        name,
        -name_lang:      name.lang,
        -name_pref:      name.pref,
        -id_label:       actorID.label,
        -id_source:      actorID.source,
        -id_type:        actorID.type,
        -nationality:    nationalityActor,
        -birthdate:      vitalDatesActor.earliestDate,
        -deathdate:      vitalDatesActor.latestDate,
        -role:           roleActor.term,
        -role_id:        roleActor.conceptID,
        -role_id_type:   roleActor.conceptID.type,
        -role_id_source: roleActor.conceptID.source,
        -qualifier:      attributionQualifierActor
    )

=head1 DESCRIPTION

C<lido_actor()> will create an actorInRole node in the path specified by the C<path> parameter.

=head2 PARAMETERS

=head3 Required parameters

It requires the parameters C<path>, C<id> and C<name> to be present as paths.

=over

=item C<path>

=item C<id>

=item C<name>

=back

=head3 Optional parameters

The following parameters are optional, but must be paths:

=over

=item C<nationality>

=item C<birthdate>

=item C<deathdate>

=item C<role>

=item C<role_id>

=item C<qualifier>

=back

All other optional parameters are strings:

=over

=item C<id_label>

=item C<id_source>

=item C<id_type> (Required if id is set.)

=item C<role_id_type>

=item C<role_id_source>

=back

=head2 MULTIPLE INSTANCES

Multiple instances can be created by appending C<$append> to the path. This will create a new C<actorInRole> tag for every instance. While it is possible to create a single C<actorInRole> for multiple actors, this is not permitted by the LIDO standard.

=head1 EXAMPLE

=head2 Fix

    lido_actor(
        descriptiveMetadata.eventWrap.eventSet.$last.event.eventActor,
        recordList.record.creator.id,
        recordList.record.creator.name,
        -id_label: 'priref',
        -id_type: 'local',
        -id_source: 'Adlib'
        -nationality: recordList.record.creator.nationality,
        -birthdate: recordList.record.creator.date_of_birth,
        -deathdate: recordList.record.creator.date_of_death,
        -role: recordList.record.role.name,
        -role_id: recordList.record.role.id,
        -role_id_type: 'global',
        -role_id_source: 'AAT',
        -qualifier: recordList.record.role.name
    )

=head2 Result

    <lido:descriptiveMetadata>
        <lido:eventWrap>
            <lido:eventSet>
                <lido:event>
                    <lido:eventActor>
                        <lido:actorInRole>
                            <lido:actor>
                                <lido:actorID lido:label="priref" lido:type="local" lido:source="Adlib">123</lido:actorID>
                                <lido:nameActorSet>
                                    <lido:appellationValue>Jonghe, Jan Baptiste De</lido:appellationValue>
                                </lido:nameActorSet>
                                <lido:nationalityActor>
                                    <lido:term>Belgisch</lido:term>
                                </lido:nationalityActor>
                                <lido:vitalDatesActor>
                                    <lido:earliestDate>1750</lido:earliestDate>
                                    <lido:latestDate>1821</lido:latestDate>
                                </lido:vitalDatesActor>
                            </lido:actor>
                            <lido:roleActor>
                                <lido:conceptID lido:type="global" lido:source="AAT">123</lido:conceptID>
                                <lido:term>Creator</lido:term>
                            </lido:roleActor>
                            <lido:attributionQualifierActor>Created</lido:attributionQualifierActor>
                        </lido:actorInRole>
                    </lido:eventActor>
                </lido:event>
            </lido:eventSet>
        </lido:eventWrap>
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