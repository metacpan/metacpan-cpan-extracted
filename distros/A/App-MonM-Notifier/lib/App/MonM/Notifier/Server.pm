package App::MonM::Notifier::Server; # $Id: Server.pm 41 2017-11-30 11:26:30Z abalama $
use strict;

=head1 NAME

App::MonM::Notifier::Server - monotifier server class

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Notifier::Server;

    my $server = new App::MonM::Notifier::Server;

=head1 DESCRIPTION

This module provides server methods.

For internal use only

=head2 METHODS

=over 8

=item B<new>

Constructor

=item B<status>

    if ($server->status) {
        # OK
    } else {
        # ERROR
    }

Returns object's status. 1 - OK, 0 - ERROR

    my $status = $server->status( 1 );

Sets new status and returns it

=item B<error>

    my $error = $server->error;

Returns error string

    my $status = $server->error( "error text" );

Sets error string also sets status to false (if error string is not null)
or to true (if error string is null) and returns this status

=item B<store>

    my $store = $server->store;

Returns current store object

=item B<send>

    $id = $server->send( @opts );

This method creates new record in store and returns ID

=item B<check>

    my $data = $client->check( $id );

This method get record from store

=item B<data>

    my $data = $server->data;

Get/Set data struct

=item B<get>

    my $value = $server->get( "name" );

Returns data value by name

=item B<set>

    $server->set( "name", "value" );

Set value to data structure by name

=item B<register_handler>

    $server->register_handler(
            handler => "index",
            method  => "GET",
            path    => "/",
            query   => undef,
            code    => \&_index_handler,
        ) or die("Can't register handler");

Register handler

=item B<run_handler>

    $server->run_handler(
            $r->method,
            $r->uri,
            $q->param("object"),
            $q
        ) or die($server->error);

=item B<remove>

    my $status = $client->remove( $id );

Removes message by ID and returns status. 0 - Error; 1 - Ok

=item B<update>

    $status = $server->update( @opts );

This method update existing record in store and returns status

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM::Notifier>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use CTK::Util;

use App::MonM::Notifier::Store;

use constant {
    METHODS => {
            GET => 1,
            POST => 1,
            PUT => 1,
            DELETE => 1,
        },
};

use vars qw/$VERSION/;
$VERSION = '1.00';

sub new {
    my $class = shift;
    my %opts = @_;
    my %props = (
            error   => '',
            status  => 1,
            store   => undef,
            location=> $opts{location} || "",
            data    => {},
            handlers=> {
                    GET     => {},
                    POST    => {},
                    PUT     => {},
                    DELETE  => {},
                },
        );

    # Store
    my $store = new App::MonM::Notifier::Store;
    if ($store->status) {
        $props{store} = $store;
    } else {
        $props{error} = sprintf("Can't create store instance: %s", $store->error);
    }

    $props{status} = 0 if $props{error};
    return bless { %props }, $class;
}
sub status {
    my $self = shift;
    my $value = shift;
    return fv2zero($self->{status}) unless defined($value);
    $self->{status} = $value ? 1 : 0;
    return $self->{status};
}
sub error {
    my $self = shift;
    my $value = shift;
    return uv2null($self->{error}) unless defined($value);
    $self->{error} = $value;
    $self->status($value ne "" ? 0 : 1);
    return $self->status;
}
sub store {
    my $self = shift;
    $self->{store};
}
sub data {
    my $self = shift;
    my $struct = shift;
    return $self->{data} unless defined($struct);
    $self->{data} = $struct;
    return 1;
}
sub get {
    my $self = shift;
    my $name = shift;
    return undef unless defined $name;
    my $data = $self->data;
    return undef unless defined $data->{$name};
    return $data->{$name};
}
sub set {
    my $self = shift;
    my $name = shift;
    my $value = shift;
    return 0 unless defined $name;
    my $data = $self->data;
    $data->{$name} = $value;
    return 1;
}
sub register_handler {
    my $self = shift;
    my %info = @_;
    my $handlers = $self->{handlers};
    my $location = $self->{location};

    # Method & Path & Query
    my $meth = $info{method} || "GET";
    $meth = "GET" unless grep {$_ eq $meth} keys %{(METHODS())};
    my $path = $location.($info{path} || "/"); # Root
    $path =~ s/\/+$//;
    $path ||= "/";
    my $query = $info{query} || "default";
    my $name = $info{handler} || "noname";
    my $code = $info{code} || sub {return 1};
    my $description = $info{description} || "";

    if ($handlers->{$meth}{$path} && $handlers->{$meth}{$path}{$query}) {
        my $tname = $handlers->{$meth}{$path}{$query}{name} || 'noname';
        return $self->error(sprintf("Handler %s already exists with another name"), $name)
            if $tname ne $name;
    }

    $handlers->{$meth}{$path}{$query} = {
            name => $name,
            code => $code,
            description => $description,
        };

    return 1;
}
sub run_handler {
    my $self = shift;
    my $meth = shift || '';
    $meth = "GET" if $meth eq 'HEAD';
    return $self->error("This method not allowed") unless grep {$_ eq $meth} keys %{(METHODS())};
    my $path = shift || "/"; $path =~ s/\/+$//; $path ||= "/";
    my $query = shift || "default";
    my $handlers = $self->{handlers};

    # Lookup handler
    my $name = $handlers->{$meth}{$path}{$query}{name};
    #my $name = value($handlers, $meth, $path, $query, "name");
    #return sprintf("%s,%s,%s,%s",$meth, $path, $query, $handlers->{$meth}{$path}{$query}{name});
    #return [
    #        $meth, $path, $query,
    #        $handlers,
    #        hash(hash($handlers, $meth), $path),
    #        value(hash(hash(hash($handlers, $meth), $path), $query), "name"),
    #    ];

    return $self->error("Handler not found") unless $name;
    my $code = $handlers->{$meth}{$path}{$query}{code};
    return $self->error("Handler incorrect. Code not defined") unless $code && ref($code) eq 'CODE';
    return &$code($self, $name, @_);
}
sub send {
    my $self = shift;
    my %in = @_;
    my $store = $self->store;
    return $self->error("Can't use undefined store object") unless $store && $store->ping;

    my $newid = $store->add(%in);
    unless ($store->status) {
        return $self->error(sprintf("Can't add message: %s", $store->error));
    }

    return $newid;
}
sub check {
    my $self = shift;
    my $id = shift || 0;
    my $store = $self->store;
    return $self->error("Can't use undefined store object") unless $store && $store->ping;

    my %data = $store->get($id);
    unless ($store->status) {
        return $self->error(sprintf("Can't get record: %s", $store->error));
    }

    return %data;
}
sub remove {
    my $self = shift;
    my $id = shift || 0;
    my $store = $self->store;
    return $self->error("Can't use undefined store object") unless $store && $store->ping;

    my $status = $store->del($id);
    unless ($store->status) {
        return $self->error(sprintf("Can't remove record: %s", $store->error));
    }

    return $status;
}
sub update {
    my $self = shift;
    my %in = @_;
    delete($in{token}) if exists($in{token});

    my $store = $self->store;
    return $self->error("Can't use undefined store object") unless $store && $store->ping;

    my $status = $store->set(%in);
    unless ($store->status) {
        return $self->error(sprintf("Can't update record: %s", $store->error));
    }

    return $status;
}

1;
__END__
