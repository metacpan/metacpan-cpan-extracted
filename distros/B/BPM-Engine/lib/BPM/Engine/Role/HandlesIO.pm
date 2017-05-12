package BPM::Engine::Role::HandlesIO;
BEGIN {
    $BPM::Engine::Role::HandlesIO::VERSION   = '0.01';
    $BPM::Engine::Role::HandlesIO::AUTHORITY = 'cpan:SITETECH';
    }

use Moose::Role;
use namespace::autoclean;

before '_execute_implementation' => sub {
    my ($self, $activity, $instance) = @_;

    if ($activity->input_sets) {
        my $pi         = $instance->process_instance;
        my $artifacts  = $pi->process->package->artifacts;
        my $attributes = $pi->attributes_rs;

        my @inputs = ();
        foreach my $set (@{ $activity->input_sets }) {
            @inputs = _validate_inputset($pi, $set, $attributes, $artifacts);
            last if scalar @inputs;
            }
        die("Incomplete InputSets") unless scalar @inputs;

        $instance->update({ inputset => [@inputs] });
        }
    else {
        #warn "No InputSets";
        }
    return;
    };

after '_execute_implementation' => sub {
    my ($self, $task, $instance) = @_;
    #XXX task?
    my $activity = $instance->activity;
    if ($activity->output_sets) {
        my $pi         = $instance->process_instance;
        my $artifacts  = $pi->process->package->artifacts;
        my $attributes = $pi->attributes_rs;
        my $result     = $instance->taskresult;

        foreach my $set (@{ $activity->output_sets }) {
            _set_output($pi, $set, $attributes, $artifacts, $result);
            }
        }
    else {
        #warn "No InputSets";
        }
    return;
    };

sub _validate_inputset {
    my ($pi, $ioset, $attributes, $artifacts) = @_;

    my @inputs = ();

    foreach my $input (@{ $ioset->{Input} }, @{ $ioset->{ArtifactInput} }) {
        my ($art) = grep { $input->{ArtifactId} eq $_->{Id} } @{$artifacts};
        die("ArtifactId '" . $input->{ArtifactId} . " not specified")
            unless $art;

        if ($art->{ArtifactType} eq 'DataObject') {
            die "Useless use of empty Artifact" unless $art->{DataObject};
            die "Useless use of empty DataObject"
                unless $art->{DataObject}->{DataField};

            my @fields =
                map { $attributes->find({ name => $_->{Id} })->value }
                @{ $art->{DataObject}->{DataField} };

            if ($art->{'RequiredForStart'}) {
                my @vals = grep {$_} @fields;
                return if (scalar(@vals) != scalar(@fields));
                }

            if (scalar @fields == 1) {
                push(@inputs, $fields[0]);
                }
            elsif (scalar @fields) {
                push(@inputs, [@fields]);
                }
            }
        else {
            die "Invalid ArtifactType " . $art->{ArtifactType};
            }
        }

    foreach my $input (@{ $ioset->{PropertyInput} }) {
        my $attr = $input->{PropertyId};
        push(@inputs, $attributes->find({ name => $attr })->value);
        }

    return (@inputs);
    }

sub _set_output {
    my ($pi, $ioset, $attributes, $artifacts, $result) = @_;

    foreach my $output (@{ $ioset->{Output} }) {
        my ($art) = grep { $output->{ArtifactId} eq $_->{Id} } @{$artifacts};
        die("ArtifactId '" . $output->{ArtifactId} . "' not specified")
            unless $art;

        if ($art->{ArtifactType} eq 'DataObject') {
            die "Useless use of empty Artifact" unless $art->{DataObject};
            die "Useless use of empty DataObject"
                unless $art->{DataObject}->{DataField};

            my @attr =
                map { $attributes->find({ name => $_->{Id} }) }
                @{ $art->{DataObject}->{DataField} };

            foreach my $attr (@attr) {
                my $val = shift @$result or last;
                $attr->update({ value => [$val] });
                }
            }
        else {
            die "Invalid ArtifactType " . $art->{ArtifactType};
            }
        }

    }

no Moose::Role;

1;
__END__

=pod

=encoding utf-8

=head1 NAME

BPM::Engine::Role::HandlesIO - ProcessRunner role for processing Input/OutputSets

=head1 DESCRIPTION

This ProcessRunner role, when an 'Implementation' Activity is executed,
sets the 'inputset' attribute of the activity instance to the artifact- and
property values specified in the &lt;InputSets&gt; XML element, and
updates process variables from specification in the &lt;OutputSets&gt; XML
element.

Example InputSets XPDL:

    <InputSets>
        <InputSet>
            <Input ArtifactId="art1"/>
            <Input ArtifactId="8bd1c307-a3a7-4343-ba79-fefe79b8cc1c"/>
            <ArtifactInput ArtifactId="art1" RequiredForStart="false"/>
            <ArtifactInput ArtifactId="art1" RequiredForStart="true"/>
            <ArtifactInput ArtifactId="art1"/>
            <PropertyInput PropertyId="common"/>
            <PropertyInput PropertyId="pcommon"/>
        </InputSet>
    </InputSets>

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos C<< <sitetech@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
