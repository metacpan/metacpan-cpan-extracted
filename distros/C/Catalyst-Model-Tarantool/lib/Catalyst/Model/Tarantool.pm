package Catalyst::Model::Tarantool;

use 5.014002;
use strict;
use warnings;

use base 'Catalyst::Model';

use MRO::Compat;
use mro 'c3';
use DR::Tarantool::SyncClient;
use Catalyst::Exception;
use Data::Dumper;

our $VERSION = '0.02';

__PACKAGE__->mk_accessors( qw/_handler app/ );

sub new {
    my ( $class, $c, $config ) = @_;
    my $self = shift->next::method( @_ );
    $self->{host} ||= $config->{host};
    $self->{port} ||= $config->{port};
    $self->{spaces} ||= $config->{spaces};
    $self->{reconnect_period} ||= $config->{reconnect_period};
    $self->{reconnect_always} ||= $config->{reconnect_always};
    $self->app($c);
    return $self;
}

sub handler{
    my ($self) = @_;
    my $connection = $self->_handler;
    unless ( $connection ) {
        eval {
            my $connection = DR::Tarantool::SyncClient->connect(
                host => $self->{host},
                port => $self->{port},
                spaces => $self->{spaces},
                reconnect_period => 0.5,
                reconnect_always => 1
            );
            
            $self->_handler( $connection );
        };
        if ($@) {
            Catalyst::Exception->throw( qq/Couldn't connect to the Tarantool via DR::Tarantool - "$@"/ );
        }
    }
    return $self->_handler;
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

Catalyst::Model::Tarantool - L<DR::Tarantool> interface

=head1 SYNOPSIS
    
=head4 MyApp.pm

    package MyApp;
    ...
    __PACKAGE__->config(
        'Tarantool' => {
            host => '128.0.0.1',
            port => '33013'
            spaces => {
                0 => {
                    name    => 'spane_name',         # space name
                    default_type => 'STR',           # undescribed fields
                    fields => [
                        qw( field_1 field_2 ),
                        {
                            name => 'firld_3',
                            type => 'NUM'
                        },
                    ],
                    indexes => {
                        0 => 'field_1',
                        1 => [ qw( field_1 field_2 ) ],
                        2 => {
                            name => 'me_idx_1',
                            fields => 'field_1'
                        },
                        3 => {
                            name => 'my_idx_2',
                            fields => [ 'field_1', 'field_3' ]
                        }
                    }
                },
                1 => {
                    ...
                }
            }
        }
    );

=head4 Controller

    package MyApp::Controller::Root
    ...
    sub index :Path :Args(0) {
        my ( $self, $c ) = @_;
        my $tnt = $c->model('TNT')->handler;
        my $tuple = $tnt->select(space_name => $key);
    }

=head1 DESCRIPTION

Tarantool interface for Catalyst based application
L<DR::Tarantool>.

=head1 AUTHOR

Alexey Orlov, E<lt>aorlov@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Alexey Orlov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
