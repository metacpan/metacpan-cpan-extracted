# vim: ts=4:sw=4:et:ai:sts=4
#
# KGB - an IRC bot helping collaboration
# Copyright © 2008 Martín Ferrari
# Copyright © 2009,2010,2012 Damyan Ivanov
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51
# Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
package App::KGB::Client::ServerRef;

use strict;
use warnings;
our $VERSION = 1.28;
use feature 'switch';
use Encode;
use Storable ();

=head1 NAME

App::KGB::Client::ServerRef - server instance in KGB client

=head1 SYNOPSIS

    use App::KGB::Client::ServerRef;
    my $s = App::KGB::Client::ServerRef->new(
        {   uri      => "http://some.server:port/",
            password => 's3cr1t',
            timeout  => 5
        }
    );

    $s->send_changes( $client, $protocol_ver, $commit, $branch, $module, { extra => stuff } );

    $s->relay_message( $client, $message, [ { opts } ] );

=head1 DESCRIPTION

B<App::KGB::Client::ServerRef> is used in L<App::KGB::Client> to refer to
remote KGB server instances. It encapsulates sending requests to the remote
server, maintaining protocol encapsulation and authentication.

=head1 CONSTRUCTOR

=over

=item new

The usual constructor. Accepts a hashref of initialiers.

=back

=head1 FIELDS

=over

=item B<uri> (B<mandatory>)

The URI of the remote KGB server. Something like C<http://some.host:port/>.

=item B<proxy>

This is the SOAP proxy used to communicate with the server. If omitted,
defaults to the value of B<uri> field, with C<?session=KGB> appended.

=item B<password> (B<mandatory>)

Password, to be used for authentication to the remote KGB server.

=item B<timeout>

Specifies the timeout for the SOAP transaction in seconds. Defaults to 15
seconds.

=item B<verbose>

Be verbose about communicating with KGB server.

=back

=head1 METHODS

=over

=item B<send_changes> (I<message parameters>)

Transmits the change set and all data about it along with the necessary
authentication hash. If an error occurs, an exception is thrown.

Message parameters are passed as arguments in the following order:

=over

=item Client instance (L<App::KGB::Client>)

=item Protocol version (or 'auto')

=item Commit (an instance of L<App::KGB::Commit>)

=item Branch

=item Module

=item Extra

This is a hash reference with additional parameters.

=back

=item B<relay_message>(I<client>, I<message> [, I<options hash> ])

Sends a message to the server for relaying.

=item send_changes_v2($info)
=item send_changes_v3($info)
=item send_changes_v4($info)

Methods implementing different protocol versions

=item send_changes_soap($message)

Helper method sending commit information via SOAP. Dies on any error or SOAP
FAULT.

=item send_changes_json($message)

Helper method sending commit information via JSON-RPC. Dies on errors.

=back

=cut

require v5.10.0;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors( qw( uri proxy password timeout verbose ) );

use utf8;
use Carp qw(confess);
use Digest::SHA qw(sha1_hex);
use YAML ();

sub new {
    my $self = shift->SUPER::new( @_ );

    defined( $self->uri )
        or confess "'uri' is mandatory";
    defined( $self->proxy )
        or $self->proxy( $self->uri . '?session=KGB' );
    defined( $self->password )
        or confess "'password' is mandatory";

    return $self;
}

sub send_changes {
    my ( $self, $client, $protocol_ver, $commit, $branch, $module, $extra )
        = @_;

    # Detect utf8 strings and set the utf8 flag, or try to convert from latin1
    my $repo_id = $client->repo_id;
    my $commit_id = $commit->id;
    my $commit_author = $commit->author;
    my $commit_log = $commit->log;
    my @commit_changes = $commit->changes ? @{ $commit->changes } : ();
    my $password = $self->password;

    my $slc = $client->single_line_commits;
    if ( $slc eq 'forced' ) {
        $commit_log =~ s/\n.*//s;
    }
    elsif ( $slc eq 'auto' ) {
        $commit_log =~ s/^[^\n]+\K\n\n.*//s;
    }

    foreach ( $repo_id, $commit_id, @commit_changes, $commit_log,
        $commit_author, $branch, $module, $password ) {
        next unless ( defined );
        next if ( utf8::is_utf8($_) );
        my $t = $_;
        if ( utf8::decode($t) ) {
            # valid utf8 char seq
            utf8::decode($_);
        } else {
            # try with legacy encoding
            utf8::upgrade($_);
        }
    }

    my $info = {
        repo_id    => $repo_id,
        rev_prefix => $client->rev_prefix,
        commit_id  => $commit_id,
        changes    => [ map ( "$_", @commit_changes ) ],
        commit_log => $commit_log,
        author     => $commit_author,
        branch     => $branch,
        module     => $module,
        extra      => $extra,
    };

    my $meth;
    if ( $protocol_ver eq 'auto' ) {
        $meth = 'send_changes_json';
    }
    else {
        $meth = "send_changes_v$protocol_ver";
        die "Unsupported protocol version requested ($protocol_ver)\n"
            unless $self->can($meth);
    }

    if ( $self->verbose ) {
        print "About to contact ", $self->proxy, "\n";
        print "Commit: ", YAML::Dump($info), "\n";
    }

    $self->$meth($info);
}

sub relay_message {
    my ( $self, $client, $message, $opts ) = @_;

    $self->send_changes_json( $client->repo_id,
        { method => 'relay_message', params => [$message, $opts] } );
}

sub send_changes_soap {
    my ( $self, $message ) = @_;

    require SOAP::Lite;

    my $s = SOAP::Lite->new( uri => $self->uri, proxy => $self->proxy );
    $s->transport->proxy->timeout( $self->timeout // 15 );

    my $res = $s->commit($message);

    # SOAP error?
    if ( $res->fault ) {
        die 'SOAP FAULT while talking to '
            . $self->uri . "\n"
            . 'FAULT MESSAGE: ', $res->fault->{faultstring}, "\n"
            . (
            $res->fault->{detail}
            ? 'FAULT DETAILS: ' . $res->fault->{detail}
            : ''
            );
    }
}

sub send_changes_json {
    my ( $self, $repo_id, $message ) = @_;

    require JSON::XS;
    require JSON::RPC::Client::Any;
    my $rpc = JSON::RPC::Client::Any->new();

    $rpc->ua->timeout($self->timeout // 15);
    $message->{id} = 1;
    $message->{version} = '1.1';
    my $json = eval { JSON::XS::encode_json($message); };
    unless ($json) {
        my $dump;
        if ( require Devel::PartialDump ) {
            $dump = Devel::PartialDump->new->dump($message);
        }
        elsif ( require Data::Dumper ) {
            $dump = Data::Dumper::Dump($message);
        }
        else {
            $dump = '(Neither Devel::PartialDump nor Data::Dumper available)';
        }

        confess "Unable to encode message structure as JSON\n" . $dump . "\n"
            . $@;
    }

    my $hash = sha1_hex( $self->password, $repo_id, $json );

    $rpc->ua->default_header( 'X-KGB-Auth', $hash );
    $rpc->ua->default_header( 'X-KGB-Project', $repo_id );

    my $res = $rpc->call( $self->uri . '/json-rpc', $message );

    die "Transport error: " . $rpc->status_line . "\n" unless $res;
    die "Server returned error: " . $res->error_message . "\n"
        if $res->is_error;
}

sub send_changes_v2 {
    my ( $self, $info ) = @_;

    my $message = join( "",
        $info->{repo_id},
        $info->{commit_id} // (),
        map( "$_", @{ $info->{changes} } ),
        $info->{commit_log},
        $info->{author} // (),
        $info->{branch} // (),
        $info->{module} // (),
        $self->password );
    utf8::encode($message);
    my $checksum = sha1_hex($message);
    # SOAP::Transport::HTTP tries to convert all characters to byte sequences,
    # but fails. See around line 204
    my @message = (
        2,
        (   map {
                SOAP::Data->type(
                    string => Encode::encode( 'UTF-8', $_ ) )
            } ( $info->{repo_id}, $checksum, $info->{rev_prefix}, $info->{commit_id} )
        ),
        [ map { SOAP::Data->type( string => "$_" ) } @{ $info->{changes} } ],
        (   map {
                SOAP::Data->type(
                    string => Encode::encode( 'UTF-8', $_ ) )
            } ( $info->{commit_log}, $info->{author}, $info->{branch}, $info->{module} )
        ),
    );

    $self->send_changes_soap( \@message );
}

sub send_changes_v3 {
    my ( $self, $info ) = @_;

    my $serialized = Storable::nfreeze($info);

    my @message = (
        3, $info->{repo_id}, $serialized,
        sha1_hex( $info->{repo_id}, $serialized, $self->password )
    );

    $self->send_changes_soap(\@message );
}

sub send_changes_v4 {
    my ( $self, $info ) = @_;

    $self->send_changes_json( $info->{repo_id},
        { method => 'commit_v4', params => [$info] } );
}

1;
