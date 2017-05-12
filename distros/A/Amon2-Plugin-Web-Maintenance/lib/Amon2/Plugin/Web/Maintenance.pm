package Amon2::Plugin::Web::Maintenance;
use 5.008001;
use strict;
use warnings;
use Net::CIDR::Lite;

our $VERSION = "0.01";

sub init {
    my ( $class, $c, $conf ) = @_;

    return unless $c->config->{MAINTENANCE}->{enable};

    $c->add_trigger(
        BEFORE_DISPATCH => sub {
            my ($self) = @_;

            return if &_is_exception($self);

            return $self->res_maintenance
                if $self->can('res_maintenance');

            return $self->create_response(
                503,
                [   'Content-Type'   => 'text/plain',
                    'Content-Length' => 36,
                ],
                ['Service unavailable for maintenance.']
            );
        }
    );
}

sub _is_exception {
    my ($self) = @_;

    my $config = $self->config->{MAINTENANCE};

    if ( exists $config->{except} ) {
        if ( exists $config->{except}->{addr} ) {
            my $remote_addr = $self->request->env->{REMOTE_ADDR};
            return 1
                if &_match_addr( $remote_addr,
                $config->{except}->{addr} );
        }
        if ( exists $config->{except}->{path} ) {
            my $path = $self->request->env->{PATH_INFO};
            return 1
                if &_match_path( $path, $config->{except}->{path} );
        }
        return 0;
    }
}

sub _match_addr {
    my ( $addr, $conditions ) = @_;

    my $cidr4 = Net::CIDR::Lite->new();
    my $cidr6 = Net::CIDR::Lite->new();
    for my $condition (@$conditions) {
        if ( $condition && $condition =~ m!:! ) {
            $cidr6->add_any($condition);
        }
        else {
            $cidr4->add_any($condition);
        }
    }

    if ( $addr =~ m!:! ) {
        return $cidr6->find($addr);
    }
    else {
        return $cidr4->find($addr);
    }
    return 0;
}

sub _match_path {
    my ( $path, $conditions ) = @_;

    for my $condition (@$conditions) {
        if ( ref $condition && ref $condition eq 'Regexp' ) {
            return 1 if $path =~ m!$condition!;
        }
        elsif ( defined $condition ) {
            return 1 if $path eq $condition;
        }
    }
    return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Plugin::Web::Maintenance - Simple maintenance announcement page plugin for Amon2.

=head1 SYNOPSIS

    package MyApp::Web;

    __PACKAGE__->load_plugins('Web::Maintenance');

=head1 DESCRIPTION

Amon2::Plugin::Web::Maintenance is simple maintenance announcement page plugin for Amon2.

=head1 CONFIGURE

You can configure in config file. This plugin use C<< $c->config->{MAINTENANCE} >>.

    +{
        'MAINTENANCE' => +{
            enable => 1,
            except => +{
                addr => ['127.0.0.1'],
                path => ['/info']
            }
        },
    };

If 'enable' is 1, your application response maintenance announcement page always.

You can except some request by using 'expect' value. 'addr' and 'path' express exceptional conditions like L<Plack::Builder::Conditionals>.

=head1 CUSTOM MAINTENANCE PAGE

You can customize the maintenance page. You can define the special named method 'res_maintenance'.

    package MyApp::Web;

    sub res_maintenance {
        my ($c)  =  @_;
        return $c->create_response(
            503,
            [   'Content-Type'   => 'text/plain',
                'Content-Length' => 29,
            ],
            ['Service down for maintenance.']
        );
    }

=head1 LICENSE

Copyright (C) zoncoen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

zoncoen E<lt>zoncoen@gmail.comE<gt>

=cut

