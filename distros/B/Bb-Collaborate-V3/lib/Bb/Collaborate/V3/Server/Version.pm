package Bb::Collaborate::V3::Server::Version;
use warnings; use strict;

use Mouse;

extends 'Elive::DAO::Singleton','Bb::Collaborate::V3';

use Scalar::Util;

=head1 NAME

Bb::Collaborate::V3::Server::Version - Server Version entity class

=cut

=head1 DESCRIPTION

This class provides Collaborate server version information 

=cut

__PACKAGE__->entity_name('ServerVersion');

=head1 PROPERTIES

=head2 versionId (Int)

The version number as a 4 digit integer, e.g. C<1002>.

=cut

has 'versionId' => (is => 'rw', isa => 'Int');

=head2 versionName (Str)

The version in XX.X.X format, e.g. C<10.0.2>.

=cut

has 'versionName' => (is => 'rw', isa => 'Str');

=head2 versionMaxTalkersLimit (Int)

The maximum number of talkers that the version can support.

=cut

has 'versionMaxTalkersLimit' => (is => 'rw', isa => 'Int');

=head2 versionMaxFilmersLimit (Int)

The maximum number of cameras that the version can support.

=cut

has 'versionMaxFilmersLimit' => (is => 'rw', isa => 'Int');

=head1 METHODS

=cut

=head2 get

    my $server_version = Bb::Collaborate::V3::Server::Version->get;
    print "Collaborate version is: ".$server_version->versionName."\n";

Returns the server version information for the current connection.

=cut

=head2 list

    my @server_versions = Bb::Collaborate::V3::Server::Version->list;

The C<list> method can be used for sites with multiple session servers.

=cut

sub _fetch {
    my ($class, $key, %opt) = @_;

    #
    # Let the connection resolve which command to use
    #

    $opt{command} ||=
	['GetServerVersions', 'ListServerVersions'];

    return $class->SUPER::_fetch($key, %opt);
}

1;
