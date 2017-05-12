package Catalyst::Model::EVDB;

use strict;
use warnings;
use base qw/Catalyst::Model EVDB::API/;
use NEXT;

our $VERSION = '0.08';

=head1 NAME

Catalyst::Model::EVDB - EVDB model class for Catalyst

=head1 SYNOPSIS

    # Use the Catalyst helper
    script/myapp_create.pl model EVDB EVDB xxxxxxxxxxxxxxxx

    # lib/MyApp/Model/EVDB.pm
    package MyApp::Model::EVDB;

    use base qw/Catalyst::Model::EVDB/;

    __PACKAGE__->config(
        app_key => 'xxxxxxxxxxxxxxxx',
    );

    1;

    # In a controller action
    my %args = (
        location => 'Gainesville, FL',
        keywords => 'tag:music',
    );

    my $evdb    = $c->model('EVDB');
    my $results = $evdb->call('events/search', \%args)
        or die 'Error searching for events: ' . $evdb->errstr;

=head1 DESCRIPTION

This is the L<EVDB::API> model class for L<Catalyst>.  L<EVDB::API> is
a Perl interface to EVDB, the Events and Venues Database.

Please note that EVDB API methods require an application key.

For more information on EVDB, or to obtain an application key, see
L<http://api.evdb.com/>.

=head1 METHODS

=head2 new

Create a new EVDB model component, using C<app_key> as specified in
your configuration.

=cut

sub new {
    my ($class, $c, $config) = @_;

    # From Catalyst::Model::Gedcom
    my $self = $class->EVDB::API::new(%{ $class->NEXT::new($c, $config) });
    $self->config($config);

    return $self;
}

=head2 errstr

Return the EVDB API error message.

=cut

sub errstr {
    my ($self) = @_;

    return $EVDB::API::errstr;
}

=head2 login

Login using the specified username and password.  For example:

    # In a controller action (don't forget validation!)
    my $username = $c->req->param('username');
    my $password = $c->req->param('password');

    my $evdb = $c->model('EVDB');
    $evdb->login(username => $username, password => $password)
        or die 'Error logging in: ' . $evdb->errstr;

Alternatively, you can set a username and password in the
configuration for your model class.  They will be used when this
method is called without arguments.  For example:

    # In your model class
    __PACKAGE__->config(
        app_key  => 'xxxxxxxxxxxxxxxx',
        username => 'danieltwc',
        password => 'secret',
    );

    # In a controller action
    my $evdb = $c->model('EVDB');
    $evdb->login or die 'Error logging in: ' . $evdb->errstr;

    # Call an EVDB method which requires authentication
    my %args = (
        title      => 'Lamb',
        start_time => '2006-03-18T21:00:00',
        tags       => 'music',
        venue_id   => 'V0-001-000160549-4',
    );

    my $response = $evdb->call('events/new', \%args);

This method also supports passwords which have already been hashed
using MD5.  Use the C<password_md5> key instead of C<password> when
calling the method or in your configuration.

=cut

sub login {
    my ($self, %args) = @_;

    $args{user}         ||= $args{username} || $self->config->{username} || $self->config->{user};
    $args{password}     ||= $self->config->{password};
    $args{password_md5} ||= $self->config->{password_md5};

    return $self->NEXT::login(%args);
}

=head1 SEE ALSO

=over 4

=item * L<Catalyst::Helper::Model::EVDB>

=item * L<Catalyst>

=item * L<EVDB::API>

=back

=head1 AUTHOR

Daniel Westermann-Clark E<lt>danieltwc@cpan.orgE<gt>

=head1 ACKNOWLEDGMENTS

=over 4

=item * Brian Cassidy, for clever C<new> code

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
