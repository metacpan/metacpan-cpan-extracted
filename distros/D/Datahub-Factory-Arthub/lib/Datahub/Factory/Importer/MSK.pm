package Datahub::Factory::Importer::MSK;

use strict;
use warnings;

use Catmandu::Importer::OAI;
use Moo;

with 'Datahub::Factory::Importer';

has endpoint           => (is => 'ro', required => 1);
has metadata_prefix    => (is => 'ro', default => sub {
    return 'oai_lido';
});
has handler            => (is => 'ro');
has set                => (is => 'ro');
has from               => (is => 'ro');
has until              => (is => 'ro');
has username           => (is => 'ro');
has password           => (is => 'ro');
#has pid_module         => (is => 'ro', default => 'lwp');
has pid_username       => (is => 'ro');
has pid_password       => (is => 'ro');
has pid_lwp_realm      => (is => 'ro');
has pid_lwp_url        => (is => 'ro');
has pid_rcf_container_name => (is => 'ro');


sub _build_importer {
    my $self = shift;
    my $importer = Catmandu::Importer::OAI->new(
        url            => $self->endpoint,
        handler        => $self->handler,
        metadataPrefix => $self->metadata_prefix,
        from           => $self->from,
        until          => $self->until,
        set            => $self->set,
        username       => $self->username,
        password       => $self->password,
    );
    $self->prepare();
    return $importer;
}

sub prepare {
    my $self = shift;
    $self->logger->info('Creating "pids" temporary table.');
    $self->__pids();
    $self->logger->info('Creating "creators" temporary table.');
    $self->__creators();
    $self->logger->info('Creating "aat" temporary table.');
    $self->__aat();
}

sub __pids {
    my $self = shift;
    my $pid = Datahub::Factory->module('PID')->new(
        pid_module             => 'rcf',
        pid_username           => $self->pid_username,
        pid_password           => $self->pid_password,
        pid_rcf_container_name => $self->pid_rcf_container_name,
        pid_rcf_object         => 'PIDS_MSK_UTF8.csv'
    );
    $pid->temporary_table($pid->path);
}

sub __creators {
    my $self = shift;
    my $pid = Datahub::Factory->module('PID')->new(
        pid_module             => 'rcf',
        pid_username           => $self->pid_username,
        pid_password           => $self->pid_password,
        pid_rcf_container_name => $self->pid_rcf_container_name,
        pid_rcf_object         => 'CREATORS_MSK_UTF8.csv'
    );
    $pid->temporary_table($pid->path);
}

sub __aat {
    my $self = shift;
    my $pid = Datahub::Factory->module('PID')->new(
        pid_module             => 'rcf',
        pid_username           => $self->pid_username,
        pid_password           => $self->pid_password,
        pid_rcf_container_name => $self->pid_rcf_container_name,
        pid_rcf_object         => 'AAT_UTF8.csv'
    );
    $pid->temporary_table($pid->path, 'record - object_name');
}

1;
__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Importer::MSK - Import data from the MSK L<OAI-PMH|https://www.openarchives.org/pmh/> endpoint

=head1 SYNOPSIS

    use Datahub::Factory::Importer::MSK;
    use Data::Dumper qw(Dumper);

    my $oai = Datahub::Factory::Importer::MSK->new(
        url                    => 'https://endpoint.msk.be/oai',
        metadataPrefix         => 'oai_lido',
        set                    => '2011',
        pid_username           => 'datahub',
        pid_password           => 'datahub',
        pid_rcf_container_name => 'datahub',
    );

    $oai->importer->each(sub {
        my $item = shift;
        print Dumper($item);
    });

=head1 DESCRIPTION

Datahub::Factory::Importer::MSK imports data from the MSK OAI-PMH endpoint. By default it uses the C<ListRecords>
verb to return all records using the I<oai_lido> format. It is possible to only return records from a single
I<Set> or those created, modified or deleted between two dates (I<from> and I<until>).

It automatically deals with I<resumptionTokens>, so client code does not have to implement paging.

To support PIDs, it uses Rackspace Cloud Files to fetch PID CSV's and convert them to temporary sqlite tables.

Provide C<pid_username>, C<pid_password> and C<pid_rcf_container_name>.

=head1 PARAMETERS

Only the C<endpoint> parameter is required.

=over

=item C<endpoint>

URL of the OAI endpoint.

=item handler( sub {} | $object | 'NAME' | '+NAME' )
Handler to transform each record from XML DOM (L<XML::LibXML::Element>) into
Perl hash.

Handlers can be provided as function reference, an instance of a Perl
package that implements 'parse', or by a package NAME. Package names should
be prepended by C<+> or prefixed with C<Catmandu::Importer::OAI::Parser>. E.g
C<foobar> will create a C<Catmandu::Importer::OAI::Parser::foobar> instance.
By default the handler L<Catmandu::Importer::OAI::Parser::oai_dc> is used for
metadataPrefix C<oai_dc>,  L<Catmandu::Importer::OAI::Parser::marcxml> for
C<marcxml>, L<Catmandu::Importer::OAI::Parser::mods> for
C<mods>, L<Catmandu::Importer::OAI::Parser::Lido> for
C<Lido> and L<Catmandu::Importer::OAI::Parser::struct> for other formats.
In addition there is L<Catmandu::Importer::OAI::Parser::raw> to return the XML
as it is.

=item C<metadata_prefix>

Any metadata prefix the endpoint supports. Defaults to C<oai_lido>.

=item C<set>

Optionally, a set to get records from.

=item C<from>

Optionally, a I<must_be_older_than> date.

=item C<until>

Optionally, a I<must_be_younger_than> date.

=item C<pid_username>

Provide your Rackspace Cloud Files username.

=item C<pid_password>

Provide your Rackspace Cloud Files api key.

=item C<pid_rcf_container_name>

Provide the container name that holds the PID CSV's.

=back

=head1 ATTRIBUTES

=over

=item C<importer>

A L<Importer|Catmandu::Importer> that can be used in your script.

=back

=head1 AUTHOR

Pieter De Praetere E<lt>pieter at packed.be E<gt>

=head1 COPYRIGHT

Copyright 2017- PACKED vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Datahub::Factory>
L<Catmandu>

=cut
