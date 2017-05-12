package Catalyst::Plugin::Session::Store::CouchDB;
use Moose;
use MRO::Compat;
use namespace::autoclean;
use AnyEvent::CouchDB;

our $VERSION = '0.03';

BEGIN {
	extends 'Catalyst::Plugin::Session::Store';
	with 'Catalyst::ClassData';
	with 'MooseX::Emulate::Class::Accessor::Fast';
}

__PACKAGE__->mk_classdata('_cdbc');
__PACKAGE__->mk_classdata('_cdb_session_db');
__PACKAGE__->mk_classdata('_cdb_config');

sub setup_session {
	my ($c) = @_;

    $c->maybe::next::method(@_);

	my $config;
	$config ||= $c->_session_plugin_config if ( $c->can('_session_plugin_config') );
	$config ||= ( $c->config->{'Plugin::Session'} or $c->config->{'session'} ) if ( $c->can('config') );
	$config ||= {};
	$c->_cdb_config($config);

    if ( $c->_cdb_config->{'uri'} and $c->_cdb_config->{'database'} ) {
    	$c->log->warn('Config parameters "uri" and "database" are deprecated, and will be removed in a future release.');
    	$c->_cdb_config->{'couch_uri'} = $c->_cdb_config->{'uri'};
    	$c->_cdb_config->{'couch_database'} = $c->_cdb_config->{'database'};
    }

    my $uri = ( $c->_cdb_config->{'couch_uri'} or 'http://localhost:5984/' );
    my $db = ( $c->_cdb_config->{'couch_database'} or 'app_session' );
    $uri .= '/' unless ( $uri =~ /\/$/ );
    $c->_cdbc( couch($uri) );

	my $success = eval {
		$c->_cdbc->info->recv;
	};
	die 'Cannot connect to CouchDB instance at ' . $uri if ( $@ or not $success );

	my $sdb = $c->_cdbc->db($db);
	my $databases = $c->_cdbc->all_dbs()->recv;
	if ( ( grep { $_ eq $db } @$databases ) == 0 ) {
		$sdb->create->recv;
	}

    $c->_cdb_session_db($sdb);

    return;
}


sub get_session_data {
	my ( $c, $key ) = @_;

	my ( $type, $id ) = split( ':', $key );
	my $session = eval {
		$c->_cdb_session_db->open_doc($id)->recv;
	};
	if ($session) {
		return $session->{ ( $type eq 'expires' ? 'expires' : 'session_data' ) };
	}
	return;
}

sub store_session_data {
	my ( $c, $key, $data ) = @_;

	my ( $type, $id ) = split( ':', $key );
	my $session = eval {
		$c->_cdb_session_db->open_doc($id)->recv;
	};

	$session = { '_id' => $id } unless ($session);

	if ( $type eq 'expires' ) {
		$session->{'expires'} = $data;
	} elsif ( $type eq 'session') {
		$session->{'session_data'} = $data;
	}
	$c->_cdb_session_db->save_doc($session)->recv;
	return 1;
}

sub delete_session_data {
	my ( $c, $key ) = @_;

	my ( $type, $id ) = split( ':', $key );
	if ( $type eq 'session' ) {
		eval {
			my $doc = $c->_cdb_session_db->open_doc($id)->recv;
			$c->_cdb_session_db->remove_doc($doc)->recv;
		};
	}
	return 1;
}

sub delete_expired_sessions {}

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Session::Store::CouchDB - Store sessions using CouchDB

=head1 SYNOPSIS

	In your application class:

	use Catalyst qw/
		Session
		Session::Store::CouchDB
	/;

	In your configuration (given values are default):
 
	<Plugin::Session>
		couch_uri http://localhost:5984
		couch_database app_session
	</Plugin::Session>

=head1 DESCRIPTION

This plugin will store and retrieve your session data using a CouchDB store.

=head1 METHODS

See L<Catalyst::Plugin::Session::Store>.

=over 4

=item get_session_data

=item store_session_data

=item delete_session_data

=item delete_expired_sessions

=back

=head1 AUTHOR

Nicholas Melnick

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013, Nicholas Melnick

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

=cut
