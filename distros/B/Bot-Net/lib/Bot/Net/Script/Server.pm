use strict;
use warnings;

package Bot::Net::Script::Server;
use base qw/ App::CLI::Command Class::Accessor::Fast /;

use Bot::Net;
use File::Copy;
use File::Spec;
use FindBin;
use Hash::Merge ();
use UNIVERSAL::require;
use YAML::Syck ();

__PACKAGE__->mk_accessors( qw{
    server_class server_file server_conf server_state

    mixin_classes
    
    clone_class clone_conf
});

=head1 NAME

Bot::Net::Script::Server - Create a new server

=head1 SYNOPSIS

  bin/botnet server --name <server name> [ <options> ]

=head1 DESCRIPTION

This script create the required class and configuration for a new bot server. Bot servers are used to host groups of bots (and possibly humans) where they can interact. This will also help build stubs for tests.

If you only specify the server name, a vanilla server will be created. This server will use L<Bot::Net::Server>, but no other mixins. This is probably not what you want. The options can be used to either clone another server you already have available in your bot net application or add additional mixins.

=head1 OPTIONS

  --name <server name>      - The name of the server class to create
  --mixin <mixin name>      - The name of the server mixin to add to the class. 
                              You may use this option multiple times to add 
                              multiple mixins.
  --clone <server name>     - The name of an existing server to clone from. By 
                              using this option, the new server will inherit
                              from the existing server and receive a copy of 
                              the original server's configuration.

=head1 METHODS

=head2 options

Returns the arguments used by this script. See L<App::CLI::Command>.

=cut

sub options {
    (
        'name=s'   => 'name',
        'mixin=s@' => 'mixins',
        'clone=s'  => 'clone',
    );
}

=head2 run

Create the server class and associated files.

=cut

sub run {
    my ($self, @arg) = @_;

    defined $self->{name}
        or die "No server name given with required --name option.\n";

    $self->server_class( Bot::Net->net_class('Server', $self->{name}) );
    $self->server_file(
        File::Spec->catfile(
            $FindBin::Bin, '..', 'lib',
            split(/::/, $self->server_class)
        ) . '.pm'
    );
    $self->server_conf(
        File::Spec->catfile(
            $FindBin::Bin, '..', 'etc', 'server',
            split(/::/, $self->{name})
        ) . '.yml'
    );
    $self->server_state(
        File::Spec->catfile(
            $FindBin::Bin, '..', 'var', 'server',
            split(/::/, $self->{name})
        ) . '.db'
    );

    my @mixins = @{ $self->{mixins} || [] };
    my @mixin_classes = (
        'Bot::Net::Server',
        map { 'Bot::Net::Mixin::Server::'.$_ } @mixins
    );

    $self->mixin_classes( \@mixin_classes );

    if ($self->{clone}) {
        $self->clone_class( Bot::Net->net_class('Server', $self->{clone}) );

        $self->clone_config(
            File::Spec->catfile(
                $FindBin::Bin, '..', 'etc', 'server',
                split(/::/, $self->{clone})
            ) . '.yml'
        );
    }

    $self->_create_server_module;
    $self->_create_server_config;
    # TODO Add _create_server_test;
    # $self->_create_server_test;
}

sub _create_server_module {
    my $self = shift;

    open my $servermod, '>', $self->server_file
        or die "Cannot write to @{[$self->server_file]}: $!";

    print "Creating ",$self->server_file,"...\n";

    print $servermod <<"END_OF_SERVER_MODULE_START";
use strict;
use warnings;

package @{[$self->server_class]};
END_OF_SERVER_MODULE_START

    if ($self->{clone}) {
        print $servermod <<"END_OF_SERVER_MODULE_CLONE";

use base qw/ @{[$self->clone_class]} /;

END_OF_SERVER_MODULE_CLONE
    }

    else {
        print $servermod <<"END_OF_SERVER_MODULE_NEW";

@{[join "\n", map { 'use '.$_.';' } @{ $self->mixin_classes }]}

END_OF_SERVER_MODULE_NEW
    }

    print $servermod <<"END_OF_SERVER_MODULE_END";
=head1 NAME

@{[$self->server_class]} - A host for semi-autonomous agents

=head1 SYNOPSIS

  bin/botnet run --server $self->{name}

=head1 DESCRIPTION

A host for semi-autonomous agents. This documentation needs replacing.

=cut

1;

END_OF_SERVER_MODULE_END
}

sub _create_server_config {
    my $self = shift;

    if ($self->{clone} and -f $self->clone_conf) {
        print "Copying ",$self->clone_conf," to ",$self->server_conf,"...\n";
        copy($self->clone_conf, $self->server_conf);
    }

    else {
        print "Creating ",$self->server_conf,"...\n";

        my @configs;
        for my $mixin_class (@{ $self->mixin_classes || [] }) {
            $mixin_class->require;
            if (my $method = $mixin_class->can('default_configuration')) {
                push @configs, $method->($mixin_class, $self->server_class);
            }
        }

        my $server_conf = Hash::Merge::merge( @configs );

        YAML::Syck::DumpFile( $self->server_conf, $server_conf );
    }
}

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
