package Datahub::Factory::Module::PID;

use Datahub::Factory::Sane;

use Datahub::Factory::Module::PID::CloudFiles;
use Datahub::Factory::Module::PID::WebFile;

use File::Basename qw(fileparse);

use Catmandu;
use Moo;

has pid_module         => (is => 'ro', default => 'lwp');
has pid_username       => (is => 'ro');
has pid_password       => (is => 'ro');
has pid_lwp_realm      => (is => 'ro');
has pid_lwp_url        => (is => 'ro');
has pid_rcf_container_name => (is => 'ro');
has pid_rcf_object         => (is => 'ro');

has client       => (is => 'lazy');
has path         => (is => 'lazy');

sub BUILDARGS {
    # Required options are dependent on chosen PID module
    my ($class, %args) = @_;
    my @required;
    if ($args{'pid_module'} eq 'lwp') {
        @required = qw(pid_lwp_url);
    } elsif ($args{'pid_module'} eq 'rcf') {
        @required = qw(pid_username pid_password pid_rcf_container_name pid_rcf_object);
    }
    foreach my $req (@required) {
        if (!defined($args{$req})) {
            Catmandu::BadArg->throw(
                message => sprintf('Missing required argument %s for %s.', $req, $args{'pid_module'})
            );
        }
    }
    return \%args;
}

sub _build_path {
    my $self = shift;
    return $self->client->path;
}

sub _build_client {
    my $self = shift;
    if ($self->pid_module eq 'lwp') {
        return Datahub::Factory::Module::PID::WebFile->new(
            url      => $self->pid_lwp_url,
            username => $self->pid_username,
            password => $self->pid_password,
            realm    => $self->pid_lwp_realm
        );
    } elsif ($self->pid_module eq 'rcf') {
        return Datahub::Factory::Module::PID::CloudFiles->new(
            username       => $self->pid_username,
            api_key        => $self->pid_password,
            container_name => $self->pid_rcf_container_name,
            object         => $self->pid_rcf_object,
        );
    }
}

sub temporary_table {
    my ($self, $csv_location, $id_column) = @_;
    my $store_table = fileparse($csv_location, '.csv');

    my $importer = Catmandu->importer(
        'CSV',
        file => $csv_location
    );
    my $store = Catmandu->store(
        'DBI',
        data_source => sprintf('dbi:SQLite:/tmp/import.%s.sqlite', $store_table),
    );
    $importer->each(sub {
            my $item = shift;
            if (defined ($id_column)) {
                $item->{'_id'} = $item->{$id_column};
            }
            my $bag = $store->bag();
            # first $bag->get($item->{'_id'})
            $bag->add($item);
        });
}

1;

__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Module::PID - Insert PIDS from an external source

=head1 SYNOPSIS

    use Datahub::Factory;

    my $pid = Datahub::Factory->module('PID')->new(
        pid_module         => 'lwp',
        pid_username       => 'datahub',
        pid_password       => 'datahub',
        pid_lwp_realm      => 'thedatahub',
        pid_lwp_url        => 'https://my.endpoint.org/files/'
    );

    $pid->temporary_table($pid->path, 'id');

=head1 DESCRIPTION

The module uses L<Catmandu> to create a SQLite database from a CSV containing an export
of the L<Resolver|https://github.com/PACKED-vzw/resolver> that can be used in Catmandu fixes
to insert PIDS (Persistent Identifiers).

The CSV's can be fetched from a protected Rackspace CloudFiles instance or from a
(supports Basic Authentication) simple web address.

It has absolutely no use outside of the L<Datahub|https://github.com/thedatahub/> use case.

=head1 PARAMETERS

=over

=item C<pid_module>

(default: C<lwp>) select the module to fetch the CSV files: supports a simple web site (C<lwp>),
optionally protected by Basic Authentication; or Rackspace Cloud Files (C<rcf>).

All options that have C<lwp> in their name are used when C<lwp> is selected as I<pid_module>.
Options with C<rcf> are for C<rcf> only. Options with neither are for the entire module.

You only have to provide the I<username>, I<password> and I<realm> for C<lwp> if you are
using Basic Authentication. If not, you can leave them blank.

=item C<pid_lwp_url>

Provide the URL to fetch the file from. Required for C<lwp>.

=item C<pid_username>

If you are using C<rcf> or C<lwp> protected with Basic Authentication, provide the username
here. Is optional for C<lwp> (no authentication is performed if this is empty).

=item C<pid_password>

For C<lwp>, provide the password. For C<rcf>, provide the API key.

=item C<pid_lwp_realm>

Optionally, provide the realm for C<lwp> Basic Authentication.

=item C<pid_rcf_container_name>

If you have selected C<rcf>, provide the container name here.

=item C<pid_rcf_object>

For C<rcf>, enter the name of the object you want to fetch (e.g. the file) here.

=back

=head1 ATTRIBUTES

=over

=item C<path>

Returns the location of the downloaded file (on the local system).

=back

=head1 METHODS

=over

=item C<temporary_table($csv_location, $id_column)>

Create a SQLite database (in C</tmp>) that stores the CSV that is stored in C<$csv_location>.
Create an C<_id> column (as expected by L<Catmandu::Fix::lookup_in_store>) in the database
from the column in the CSV called C<$id_column>.

Returns nothing.

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