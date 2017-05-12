package Catmandu::Fix::lido_objectmeasurements;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;
use Catmandu::Fix::LIDO::Utility qw(walk declare_source);
use Catmandu::Fix::LIDO::Value qw(emit_base_value);

use strict;

our $VERSION = '0.09';

#https://librecatproject.wordpress.com/2014/03/26/create-a-fixer-part-2/

with 'Catmandu::Fix::Base';

has extent => (fix_arg => 1); # should this be a path?
has type   => (fix_arg => 1);
has unit   => (fix_arg => 1);
has value  => (fix_arg => 1); # path

sub emit {
    my ($self, $fixer) = @_;
    my $perl = '';

    my $path = ['descriptiveMetadata', 'objectIdentificationWrap', 'objectMeasurementsWrap', 'objectMeasurementsSet', '$append', 'objectMeasurements'];

    $perl .= $fixer->emit_create_path(
        $fixer->var,
        $path,
        sub {
            my $r_root = shift;
            my $r_code = '';
            ##
            # extent
            if (defined($self->extent)) {
                $r_code .= emit_base_value($fixer, $r_root, 'extentMeasurements', $self->extent, undef, undef, undef, undef, 1);
            }

            ##
            # type, unit, value
            $r_code .= $fixer->emit_create_path (
                $r_root,
                ['measurementsSet'],
                sub {
                    my $m_root = shift;
                    my $m_code = '';

                    ##
                    # type
                    if (defined($self->type)) {
                        #$fixer, $root, $path, $value, $lang, $pref, $label, $type, $is_string
                        $m_code .= emit_base_value($fixer, $m_root, 'measurementType', $self->type, undef, undef, undef, undef, 0);
                    }

                    ##
                    # unit
                    if (defined($self->unit)) {
                        $m_code .= emit_base_value($fixer, $m_root, 'measurementUnit', $self->unit, undef, undef, undef, undef, 0);
                    }

                    ##
                    # value
                    if (defined($self->value)) {
                        $m_code .= $fixer->emit_create_path(
                            $m_root,
                            ['measurementValue'],
                            sub {
                                my $v_root = shift;
                                my $v_code = '';

                                my $m_value = $fixer->generate_var();
                                $v_code .= "my ${m_value};";
                                $v_code .= declare_source($fixer, $self->value, $m_value);

                                $v_code .= "${v_root} = ${m_value};";
                                return $v_code;
                            }
                        );
                    }

                    return $m_code;
                }
            );

            return $r_code;
        }
    );

    return $perl;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::lido_objectmeasurements - Create a C<objectMeasurements> node

=head1 SYNOPSIS

    lido_objectmeasurements(
        extent,
        type,
        unit,
        value
    )

=head1 DESCRIPTION

Create a C<objectMeasurements> node, consisting of C<measurementType>, C<measurementUnit>, C<measurementValue> and C<extentMeasurements>.

=head2 PARAMETERS

=head3 Required parameters

All parameters are required.

C<value>, C<type> and C<unit> are path parameters, all other parameters are strings.

=over

=item C<value>

=item C<type>

=item C<unit>

=back

=over

=item C<extent>

=back

=head2 MULTIPLE INSTANCES

Repeated invocations of the fix with the same path will result in a new C<objectMeasurementsSet> at C<descriptiveMetadata.objectIdentificationWrap.objectMeasurementsWrap>. No nodes will be overwritten.

=head1 EXAMPLE

=head2 Fix

    lido_objectmeasurements(
        'Volledig',
        recordList.record.height.type,
        recordList.record.height.unit,
        recordList.record.height
    )

=head2 Result

    <lido:descriptiveMetadata>
        <lido:objectIdentificationWrap>
            <lido:objectMeasurementsWrap>
                <lido:objectMeasurementsSet>
                    <lido:objectMeasurements>
                        <lido:measurementsSet>
                            <lido:measurementType>hoogte</lido:measurementType>
                            <lido:measurementUnit>cm</lido:measurementUnit>
                            <lido:measurementValue>15</lido:measurementValue>
                        </lido:measurementsSet>
                        <lido:extentMeasurements>Volledig</lido:extentMeasurements>
                    </lido:objectMeasurements>
                </lido:objectMeasurementsSet>
            </lido:objectMeasurementsWrap>
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