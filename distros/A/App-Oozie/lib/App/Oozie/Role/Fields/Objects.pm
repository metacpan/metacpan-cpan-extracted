package App::Oozie::Role::Fields::Objects;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Constants qw(
    DEFAULT_TZ
    DEFAULT_WEBHDFS_PORT
);
use App::Oozie::Date;
use App::Oozie::Types::DateTime qw( IsTZ );
use DateTime;
use Moo::Role;
use MooX::Options;
use Net::Hadoop::Oozie;
use Net::Hadoop::WebHDFS::LWP;
use Types::Standard qw( InstanceOf );

option resource_manager => (
    is     => 'rw',
    format => 's',
);

option timezone => (
    is       => 'rw',
    isa      => IsTZ,
    format   => 's',
    default  => sub { DEFAULT_TZ },
    doc      => 'The time zone to be used when generating dates. Defaults to ' . DEFAULT_TZ,
);

option webhdfs_hostname => (
    is     => 'rw',
    format => 's',
);

option webhdfs_port => (
    is      => 'rw',
    format  => 'i',
    default => sub { DEFAULT_WEBHDFS_PORT },
);

option use_ssl => (
    is      => 'rw',
    format  => 'i',
    default => sub { 0 },
);

has hdfs => (
    is      => 'rw',
    isa     => InstanceOf['Net::Hadoop::WebHDFS'],
    lazy    => 1,
    default => sub {
        my $self = shift;
        my %opt  = (
            ( $self->webhdfs_hostname ? (
            host        => $self->webhdfs_hostname,
            ) : ()),
            port        => $self->webhdfs_port,
            username    => $self->effective_username,
            httpfs_mode => 1,
            ( $self->use_ssl ? (
                use_ssl => 1,
            ) : () ),
        );
        Net::Hadoop::WebHDFS::LWP->new( %opt );
    },
);

has date => (
    is      => 'ro',
    isa     => InstanceOf['App::Oozie::Date'],
    default => sub {
        my $self = shift;
        App::Oozie::Date->new( timezone => $self->timezone ),
    },
    lazy    => 1,
);

has oozie => (
    is      => 'rw',
    isa     => InstanceOf['Net::Hadoop::Oozie'],
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @opt;
        if ( $self->can('oozie_uri') && $self->oozie_uri ) {
            push @opt, oozie_uri => $self->oozie_uri;
        }
        Net::Hadoop::Oozie->new( @opt );
    },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Role::Fields::Objects

=head1 VERSION

version 0.017

=head1 SYNOPSIS

    use Moo::Role;
    use MooX::Options;
    with 'App::Oozie::Role::Fields::Objects';

=head1 DESCRIPTION

This is a Role to be consumed by Oozie tooling classes and
defines various fields.

=head1 NAME

App::Oozie::Role::Fields::Objects - Overridable objects for internal programs/libs.

=head1 Accessors

=head2 Overridable from cli

=head3 resource_manager

=head3 timezone

=head3 use_ssl

=head3 webhdfs_hostname

=head3 webhdfs_port

=head2 Overridable from sub-classes

=head3 date

=head3 hdfs

=head3 oozie

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
