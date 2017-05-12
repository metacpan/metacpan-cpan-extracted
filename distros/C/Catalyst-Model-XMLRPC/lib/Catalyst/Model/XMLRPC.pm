package Catalyst::Model::XMLRPC;
use base qw/Catalyst::Model/;
use strict;
use warnings;

use Carp;
use NEXT;
use RPC::XML;
use RPC::XML::Client;

our $VERSION = '0.04';
our $AUTOLOAD;


sub new {
    my ($class, $c, $config) = @_;

    my $self = $class->NEXT::new($c, $config);
    $self->config($config);

    return $self;
}


sub _client {
    my $self = shift;
    my %config = %{ $self->config };

    my $location = $config{location};
    croak "Must provide an location" unless $location;
    delete $config{location};

    unless (exists $config{error_handler}) {
        $config{error_handler} = sub { croak $_[0] };
    }
    unless (exists $config{fault_handler}) {
        $config{fault_handler} = sub { croak $_[0] };
    }

    my $client = RPC::XML::Client->new($location, %config);
    croak "Can't create RPC::XML::Client object"
        unless UNIVERSAL::isa($client, 'RPC::XML::Client');

    return $client;
}


sub AUTOLOAD {
    my ($self, @args) = @_;
    
    return if $AUTOLOAD =~ /::DESTROY$/;

    (my $op = $AUTOLOAD) =~ s/^.*:://;

    my $client = $self->_client;
    
    my $msg = $client->$op(@args);

    return $msg;
}


1;

__END__

=head1 NAME

Catalyst::Model::XMLRPC - XMLRPC model class for Catalyst

=head1 SYNOPSIS

 # Model
 __PACKAGE__->config(
    location => 'http://webservice.example.com:9000',
 );

 # Controller
 sub default : Private {
    my ($self, $c) = @_;

    my $res;
    
    eval {
        $res = $c->model('RemoteService')->send_request('system.listMethods');
        $c->stash->{value} = $res->value;
    };
    if ($@) {
        # Something went wrong...
    }
    
    ...
};


=head1 DESCRIPTION

This model class uses L<RPC::XML::Client> to invoke remote procedure calls
using XML-RPC.

=head1 CONFIGURATION

You can pass the same configuration fields as when you call
L<RPC::XML::Client>, the only special thing is that the URI is provided via
the B<location> field.

=head1 METHODS

=head2 General

Take a look at L<RPC::XML::Client> to see the method you can call.

=head2 new

Called from Catalyst.

=head1 NOTES

By default, there is an B<error_handler> and a B<fault_handler> provided
for the L<RPC::XML::Client> object that call L<Carp::croak>.
You can override it if you want via the config call.

=head1 DIAGNOSTICS

=head2 Must provide an location

You'll get this error, if you haven't provided a location. See Config.

=head2 Can't create RPC::XML::Client object

Something went wrong while trying to create an L<RPC::XML::Client> object. See
documentation of this module for further references.

=head1 SEE ALSO

=over 1

=item * L<RPC::XML::Client>

=item * L<RPC::XML>

=item * L<Catalyst::Model>

=back

=head1 ACKNOWLEDGEMENTS

=over 1

=item * Daniel Westermann-Clark's module, L<Catalyst::Model::LDAP>, it was my reference.

=item * Lee Aylward, for reporting the issue regarding v.0.03.

=back

=head1 AUTHOR

Florian Merges, E<lt>fmerges@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
