package App::Toot;

use strict;
use warnings;

use App::Toot::Config;
use Mastodon::Client;

our $VERSION = '0.04';

sub new {
    my $class = shift;
    my $arg   = shift;

    if ( !defined $arg->{'config'} ) {
        die 'config is required';
    }

    if ( !defined $arg->{'status'} ) {
        die 'status is required';
    }

    my $self = {
        config => App::Toot::Config->load( $arg->{'config'} ),
        status => $arg->{'status'},
    };

    $self->{'client'} = Mastodon::Client->new(
        instance        => $self->{'config'}{'instance'},
        name            => $self->{'config'}{'username'},
        client_id       => $self->{'config'}{'client_id'},
        client_secret   => $self->{'config'}{'client_secret'},
        access_token    => $self->{'config'}{'access_token'},
        coerce_entities => 1,
    );

    return bless $self, $class;
}

sub run {
    my $self = shift;

    return $self->{'client'}->post_status( $self->{'status'} );
}

1;

__END__

=pod

=head1 NAME

App::Toot - post a status to Mastodon

=head1 SYNOPSIS

 use App::Toot;
 my $app = App::Toot->new({ config => 'default', status => 'toot all day' });
 my $ret = $app->run();

=head1 DESCRIPTION

C<App::Toot> is a program to post statues to Mastodon.

For the commandline tool, see the documentation for L<toot> or C<man toot>.

=head1 INSTALLATION

 perl Makefile.PL
 make && make test && make install

=head1 METHODS

=head2 new

Class constructor for the C<App::Toot> object.

Loads and sets the C<config> and C<status> keys into the object.

=head3 ARGUMENTS

The arguments for the C<new> method must be passed as a hashref containing the following keys:

=over

=item config

String value of the config section to load.

Required.

=item status

String value of the status to post.

Required.

=back

=head3 RETURNS

Returns an C<App::Toot> object.

=head2 run

Posts the status to Mastodon.

=head3 ARGUMENTS

None.

=head3 RETURNS

Returns a L<Mastodon::Entity::Status> object.

=head1 CONFIGURATION

For configuration, see the documentation for L<App::Toot::Config> or C<perldoc App::Toot::Config>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023 Blaine Motsinger under the MIT license.

=head1 AUTHOR

Blaine Motsinger C<blaine@renderorange.com>

=cut
