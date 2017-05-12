package Audio::XMMSClient::XMLRPC;

use strict;
use warnings;
use RPC::XML::Server;
use Audio::XMMSClient;
use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors(qw(
            name
            no_http
            no_default
            no_default
            path
            host
            port
            queue
            timeout
            _server
            _xmms
));

=head1 NAME

Audio::XMMSClient::XMLRPC - XMLRPC interface to xmms2

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Audio::XMMSClient::XMLRPC;

    my $rpc = Audio::XMMSClient::XMLRPC->new();
    $rpc->loop;

=head1 FUNCTIONS

=head2 new

    my $rpc = Audio::XMMSClient::XMLRPC->new( \%options );

Creates a new Audio::XMMSClient::XMLRPC instance with the given C<%options>.
Valid options are:

=over

=item B<no_httpd>

If passed with a "true" value, prevents the creation and storage of the
HTTP::Daemon object. This allows for deployment of a server object in other
environments. Note that if this is set, the loop method described below will
silently attempt to use the L<Net::Server> module.

=item B<no_default>

If passed with a "true" value, prevents the loading of the default methods
provided with the L<RPC::XML> distribution. The methods themselves are described
below (see "The Default Methods Provided").

=item B<path>

=item B<port>

=item B<queue>

=item B<timeout>

These four are specific to the HTTP-based nature of the server.  The B<path>
argument sets the additional URI path information that clients would use to
contact the server.  Internally, it is not used except in outgoing status and
introspection reports. The B<host>, B<port> and B<queue> arguments are passed
to the L<HTTP::Daemon> constructor if they are passed. They set the hostname,
TCP/IP port, and socket listening queue, respectively. They may also be used if
the server object tries to use L<Net::Server> as an alternative server core.

=back

=cut

sub new {
    my $base = shift;

    my $self = $base->SUPER::new(@_);

    (my $default_name = __PACKAGE__) =~ s/::/-/g;
    $self->name( $default_name ) unless defined $self->name;
    $self->port( 9000 ) unless defined $self->port;

    my $xmms = Audio::XMMSClient->new( $self->name );
    $xmms->connect or die $xmms->get_last_error;

    $self->_xmms( $xmms );

    my $server = RPC::XML::Server->new(
            (no_http     => $self->no_http)    x! ! $self->no_http,
            (no_default  => $self->no_default) x! ! $self->no_default,
            (path        => $self->path)       x! ! $self->path,
            (port        => $self->port)       x! ! $self->port,
            (queue       => $self->queue)      x! ! $self->queue,
            (timeout     => $self->timeout)    x! ! $self->timeout,
    );

    $self->_server( $server );
    $self->_add_methods;

    return $self;
}

{
    my $method_help = {
        quit                                        => 'Tell the server to quit.',
        plugin_list                                 => 'Get a list of loaded plugins from the server.',
        main_stats                                  => 'Get a list of statistics from the server.',
        playlist_shuffle                            => 'Shuffles the current playlist.',
        playlist_add                                => 'Add the url to the playlist.',
        playlist_add_args                           => 'Add the url to the playlist with arguments.',
        playlist_add_id                             => 'Add a medialib id to the playlist.',
        playlist_add_encoded                        => 'Add the url to the playlist.',
        playlist_remove                             => 'Remove an entry from the playlist.',
        playlist_clear                              => 'Clears the current playlist.',
        playlist_list                               => 'List current playlist.',
        playlist_sort                               => 'Sorts the playlist according to the property.',
        playlist_set_next                           => 'Set next entry in the playlist.',
        playlist_set_next_rel                       => 'Same as xmms.playlist.set_next but relative to the current postion.',
        playlist_move                               => 'Move a playlist entry to a new position (absolute move).',
        playlist_current_pos                        => 'Retrive the current position in the playlist.',
        playlist_insert                             => 'Insert entry at given position in playlist.',
        playlist_insert_args                        => 'Insert entry at given position in playlist wit args.',
        playlist_insert_encoded                     => 'Insert entry at given position in playlist.',
        playlist_insert_id                          => 'Insert a medialib id at given position in playlist.',
        playlist_radd                               => 'Adds a directory recursivly to the playlist.',
        playlist_radd_encoded                       => 'Adds a directory recursivly to the playlist.',
        playback_stop                               => 'Stops the current playback.',
        playback_tickle                             => 'Stop decoding of current song.',
        playback_start                              => 'Starts playback if server is idle.',
        playback_pause                              => 'Pause the current playback, will tell the output to not read nor write.',
        playback_current_id                         => 'Make server emit the current id.',
        playback_seek_ms                            => 'Seek to a absolute time in the current playback.',
        playback_seek_ms_rel                        => 'Seek to a time relative to the current position in the current playback.',
        playback_seek_samples                       => 'Seek to a absoulte number of samples in the current playback.',
        playback_seek_samples_rel                   => 'Seek to a number of samples relative to the current position in the current playback.',
        playback_playtime                           => 'Request the playback_playtime signal.',
        playback_status                             => 'Make server emit the playback status.',
        playback_volume_set                         => 'Set the volume on a given channel.',
        playback_volume_get                         => 'Get the current volume.',
        configval_set                               => 'Sets a configvalue in the server.',
        configval_list                              => 'Lists all configuration values.',
        configval_get                               => 'Retrives a list of configvalues in server.',
        configval_register                          => 'Registers a config property in the server.',
        userconfdir_get                             => 'Get the absolute path to the user config dir.',
        medialib_select                             => 'Make a SQL query to the server medialib.',
        medialib_playlist_save_current              => 'Save the current playlist to a serverside playlist.',
        medialib_playlist_load                      => 'Load a playlist from the medialib to the current active playlist.',
        medialib_add_entry                          => 'Add a URL to the medialib.',
        medialib_add_entry_args                     => 'Add a URL with arguments to the medialib.',
        medialib_add_entry_encoded                  => 'Add a URL to the medialib.',
        medialib_get_info                           => 'Retrieve information about a entry from the medialib.',
        medialib_add_to_playlist                    => 'Queries the medialib for files and adds the matching ones to the current playlist.',
        medialib_playlists_list                     => 'Returns a list of all available playlists.',
        medialib_playlist_list                      => 'This will make the server list the given playlist.',
        medialib_playlist_import                    => 'Import a playlist from a playlist file.',
        medialib_playlist_export                    => 'Export a serverside playlist to a format that could be read from another mediaplayer',
        medialib_playlist_remove                    => 'Remove a playlist from the medialib, keeping the songs of course.',
        medialib_path_import                        => 'Import a all files recursivly from the directory passed as argument.',
        medialib_path_import_encoded                => 'Import a all files recursivly from the directory passed as argument which must already be url encoded.',
        medialib_rehash                             => 'Rehash the medialib, this will check data in the medialib still is the same as the data in files.',
        medialib_get_id                             => 'Search for a entry (URL) in the medialib db and return its ID number.',
        medialib_remove_entry                       => 'Remove a entry from the medialib.',
        medialib_entry_property_set_int             => 'Associate a int value with a medialib entry.',
        medialib_entry_property_set_int_with_source => 'Set a custom int field in the medialib associated with a entry, the same as xmms.medialib.entry_property.set_int but with specifing your own source.',
        medialib_entry_property_set_str             => 'Associate a value with a medialib entry.',
        medialib_entry_property_set_str_with_source => 'Set a custom field in the medialib associated with a entry, the same as xmms.medialib.entry_property.set_str but with specifing your own source.',
        medialib_entry_property_remove              => 'Remove a custom field in the medialib associated with an entry.',
        medialib_entry_property_remove_with_source  => 'Remove a custom field in the medialib associated with an entry. Identical to xmms.medialib.entry_property.remove except with specifying your own source.',
        xform_media_browse                          => 'Browse available media in a path.',
        xform_media_browse_encoded                  => 'Browse available media in a (already encoded) path.',
        bindata_add                                 => 'Add some binary data to be stored in the server. Returns a string which uniquely identifies the data.',
        bindata_retrieve                            => 'Retrieve some binary data identified by a given hash.',
        bindata_remove                              => 'Remove some binary data identified by a given hash.',
    };

    sub _rpc_procedure {
        my ($self, $method, $opts) = @_;

        return RPC::XML::Procedure->new({
                help => $method_help->{$method},
                %{$opts},
                name => 'xmms.'. $opts->{name},
                code => $opts->{code}
                    ? sub { $opts->{code}->($self, @_) }
                    : sub { $self->_rpc_generic_wrapper($method, @_) },
        });
    }
}

sub _methods {
    my $methods = {
            quit => {
                name        => 'quit',
                version     => '0.01',
                signature   => [ 'boolean' ],
            },
            plugin_list => {
                name        => 'plugin_list',
                version     => '0.01',
                signature   => [ 'array' ],
            },
            main_stats => {
                name        => 'main_stats',
                version     => '0.01',
                signature   => [ 'struct' ],
            },
            playlist_shuffle => {
                name        => 'playlist.shuffle',
                version     => '0.01',
                signature   => [ 'boolean' ],
            },
            playlist_add => {
                name        => 'playlist.add',
                version     => '0.01',
                signature   => [ 'boolean string' ],
            },
            playlist_add_args => {
                name        => 'playlist.add_args',
                version     => '0.01',
                signature   => [ 'boolean string struct' ],
            },
            playlist_add_id => {
                name        => 'playlist.add_id',
                version     => '0.01',
                signature   => [ 'boolean int' ],
            },
            playlist_add_encoded => {
                name        => 'playlist.add_encoded',
                version     => '0.01',
                signature   => [ 'boolean string' ],
            },
            playlist_remove => {
                name        => 'playlist.remove',
                version     => '0.01',
                signature   => [ 'boolean int' ],
            },
            playlist_clear => {
                name        => 'playlist.clear',
                version     => '0.01',
                signature   => [ 'boolean' ],
            },
            playlist_list => {
                name        => 'playlist.list',
                version     => '0.01',
                signature   => [ 'array' ],
            },
            playlist_sort => {
                name        => 'playlist.sort',
                version     => '0.01',
                signature   => [ 'boolean string' ],
            },
            playlist_set_next => {
                name        => 'playlist.set_next',
                version     => '0.01',
                signature   => [ 'boolean int' ],
            },
            playlist_set_next_rel => {
                name        => 'playlist.set_next_rel',
                version     => '0.01',
                signature   => [ 'boolean int' ],
            },
            playlist_move => {
                name        => 'playlist.move',
                version     => '0.01',
                signature   => [ 'boolean int int' ],
            },
            playlist_current_pos => {
                name        => 'playlist.current_pos',
                version     => '0.01',
                signature   => [ 'int' ],
            },
            playlist_insert => {
                name        => 'playlist.insert',
                version     => '0.01',
                signature   => [ 'boolean int string' ],
            },
            playlist_insert_args => {
                name        => 'playlist.insert_args',
                version     => '0.01',
                signature   => [ 'boolean int string struct' ],
            },
            playlist_insert_encoded => {
                name        => 'playlist.insert_encoded',
                version     => '0.01',
                signature   => [ 'boolean int string' ],
            },
            playlist_insert_id => {
                name        => 'playlist.insert_id',
                version     => '0.01',
                signature   => [ 'boolean int int' ],
            },
            playlist_radd => {
                name        => 'playlist.radd',
                version     => '0.01',
                signature   => [ 'boolean string' ],
            },
            playlist_radd_encoded => {
                name        => 'playlist.radd_encoded',
                version     => '0.01',
                signature   => [ 'boolean string' ],
            },
            playback_stop => {
                name        => 'playback.stop',
                version     => '0.01',
                signature   => [ 'boolean' ],
            },
            playback_tickle => {
                name        => 'playback.tickle',
                version     => '0.01',
                signature   => [ 'boolean' ],
            },
            playback_start => {
                name        => 'playback.start',
                version     => '0.01',
                signature   => [ 'boolean' ],
            },
            playback_pause => {
                name        => 'playback.pause',
                version     => '0.01',
                signature   => [ 'boolean' ],
            },
            playback_current_id => {
                name        => 'playback.current_id',
                version     => '0.01',
                signature   => [ 'int' ],
            },
            playback_seek_ms => {
                name        => 'playback.seek_ms',
                version     => '0.01',
                signature   => [ 'boolean int' ],
            },
            playback_seek_ms_rel => {
                name        => 'playback.seek_ms_re',
                version     => '0.01',
                signature   => [ 'boolean int' ],
            },
            playback_seek_samples => {
                name        => 'playback.seek_samples',
                version     => '0.01',
                signature   => [ 'boolean int' ],
            },
            playback_seek_samples_rel => {
                name        => 'playback.seek_samples_rel',
                version     => '0.01',
                signature   => [ 'boolean int' ],
            },
            playback_playtime => {
                name        => 'playback.playtime',
                version     => '0.01',
                signature   => [ 'int' ],
            },
            playback_status => {
                name        => 'playback.status',
                version     => '0.01',
                signature   => [ 'int' ], #FIXME: string? Fix perl bindings as well
            },
            playback_volume_set => {
                name        => 'playback.volume_set',
                version     => '0.01',
                signature   => [ 'boolean string int' ],
            },
            playback_volume_get => {
                name        => 'playback.volume_get',
                version     => '0.01',
                signature   => [ 'struct' ],
            },
            configval_set => {
                name        => 'configval.set',
                version     => '0.01',
                signature   => [ 'boolean string string' ],
            },
            configval_list => {
                name        => 'configval.list',
                version     => '0.01',
                signature   => [ 'array' ],
            },
            configval_get => {
                name        => 'configval.get',
                version     => '0.01',
                signature   => [ 'string string' ],
            },
            configval_register => {
                name        => 'configval.register',
                version     => '0.01',
                signature   => [ 'boolean string string' ],
            },
            userconfdir_get => {
                name        => 'userconfdir_get',
                version     => '0.01',
                signature   => [ 'string' ],
                code        => \&_rpc_userconfdir_get,
            },
            medialib_select => {
                name        => 'medialib.select',
                version     => '0.01',
                signature   => [ 'array string' ],
            },
            medialib_playlist_save_current => {
                name        => 'medialib.playlist.save_current',
                version     => '0.01',
                signature   => [ 'boolean string' ],
            },
            medialib_playlist_load => {
                name        => 'medialib.playlist.load',
                version     => '0.01',
                signature   => [ 'boolean string' ],
            },
            medialib_add_entry => {
                name        => 'medialib.add_entry',
                version     => '0.01',
                signature   => [ 'int string' ],
            },
            medialib_add_entry_args => {
                name        => 'medialib.add_entry_args',
                version     => '0.01',
                signature   => [ 'int string struct' ],
            },
            medialib_add_entry_encoded => {
                name        => 'medialib.add_entry_encoded',
                version     => '0.01',
                signature   => [ 'int string' ],
            },
            medialib_get_info => {
                name        => 'medialib.get_info',
                version     => '0.01',
                signature   => [ 'struct int' ],
            },
            medialib_add_to_playlist => {
                name        => 'medialib.add_to_playlist',
                version     => '0.01',
                signature   => [ 'boolean string' ],
            },
            medialib_playlists_list => {
                name        => 'medialib.playlists_list',
                version     => '0.01',
                signature   => [ 'array' ],
            },
            medialib_playlist_list => {
                name        => 'medialib.playlist.list',
                version     => '0.01',
                signature   => [ 'array string' ],
            },
            medialib_playlist_import => {
                name        => 'medialib.playlist.import',
                version     => '0.01',
                signature   => [ 'boolean string string' ],
            },
            medialib_playlist_export => {
                name        => 'medialib.playlist.export',
                version     => '0.01',
                signature   => [ 'boolean string string' ],
            },
            medialib_playlist_remove => {
                name        => 'medialib.playlist.remove',
                version     => '0.01',
                signature   => [ 'boolean string' ],
            },
            medialib_path_import => {
                name        => 'medialib.path_import',
                version     => '0.01',
                signature   => [ 'boolean string' ],
            },
            medialib_path_import_encoded => {
                name        => 'medialib.path_import_encoded',
                version     => '0.01',
                signature   => [ 'boolean string' ],
            },
            medialib_rehash => {
                name        => 'medialib.rehash',
                version     => '0.01',
                signature   => [ 'boolean int' ],
            },
            medialib_get_id => {
                name        => 'medialib.get_id',
                version     => '0.01',
                signature   => [ 'int string' ],
            },
            medialib_remove_entry => {
                name        => 'medialib.remove_entry',
                version     => '0.01',
                signature   => [ 'boolean int' ],
            },
            medialib_entry_property_set_int => {
                name        => 'medialib.entry_property.set_int',
                version     => '0.01',
                signature   => [ 'boolean int string int' ],
            },
            medialib_entry_property_set_int_with_source => {
                name        => 'medialib.entry_property.set_int_with_source',
                version     => '0.01',
                signature   => [ 'boolean int string string int' ],
            },
            medialib_entry_property_set_str => {
                name        => 'medialib.entry_property.set_str',
                version     => '0.01',
                signature   => [ 'boolean int string string' ],
            },
            medialib_entry_property_set_str_with_source => {
                name        => 'medialib.entry_property.set_str_with_source',
                version     => '0.01',
                signature   => [ 'boolean int string string string' ],
            },
            medialib_entry_property_remove => {
                name        => 'medialib.entry_property.remove',
                version     => '0.01',
                signature   => [ 'boolean int string' ],
            },
            medialib_entry_property_remove_with_source => {
                name        => 'medialib.entry_property.remove_with_source',
                version     => '0.01',
                signature   => [ 'boolean int string string' ],
            },
            xform_media_browse => {
                name        => 'xform.media_browse',
                version     => '0.01',
                signature   => [ 'array string' ],
            },
            xform_media_browse_encoded => {
                name        => 'xform.media_browse_encoded',
                version     => '0.01',
                signature   => [ 'array string' ],
            },
            bindata_add => {
                name        => 'bindata.add',
                version     => '0.01',
                signature   => [ 'string string' ],
            },
            bindata_retrieve => {
                name        => 'bindata.retrieve',
                version     => '0.01',
                signature   => [ 'string string' ],
            },
            bindata_remove => {
                name        => 'bindata.remove',
                version     => '0.01',
                signature   => [ 'boolean string' ],
            },
    };

    return $methods;
}

sub _add_methods {
    my ($self) = @_;

    my $srv     = $self->_server;
    my $methods = $self->_methods;

    for my $method (keys %{ $methods }) {
        $srv->add_method( $self->_rpc_procedure( $method => $methods->{$method} ) );
    }
}

sub _rpc_generic_wrapper {
    my ($self, $method, @opts) = @_;

    @opts = map {
        ref && ref eq 'HASH'
            ? %{$_}
            : $_
    } @opts;

    my $res;
    eval {
        $res = $self->_xmms->$method( @opts );
    };

    if ($@) {
        return RPC::XML::fault->new( 500, $@ );
    }

    $res->wait;
    return $res->value;
}

sub _rpc_userconfdir_get {
    my ($self) = @_;

    return $self->_xmms->userconfdir_get;
}

=head2 loop

    $server->loop;

Enters the connection-accept loop, which generally does not return.

=cut

sub loop {
    my ($self) = @_;

    $self->_server->server_loop;
}

=head1 METHODS

=head2 The xmms.* Methods

=over

=item B<playback_seek_ms>

    boolean playback_seek_ms (int)

Seek to a absolute time in the current playback.

=item B<medialib_playlist_remove>

    boolean medialib_playlist_remove (string)

Remove a playlist from the medialib, keeping the songs of course.

=item B<medialib_entry_property_remove>

    boolean medialib_entry_property_remove (int, string)

Remove a custom field in the medialib associated with an entry.

=item B<playlist_set_next>

    boolean playlist_set_next (int)

Set next entry in the playlist.

=item B<medialib_add_entry_args>

    int medialib_add_entry_args (string, struct)

Add a URL with arguments to the medialib.

=item B<playlist_insert_args>

    boolean playlist_insert_args (int, string, struct)

Insert entry at given position in playlist wit args.

=item B<medialib_entry_property_set_int_with_source>

    boolean medialib_entry_property_set_int_with_source (int, string, string, int)

Set a custom int field in the medialib associated with a entry, the same as xmms.medialib.entry_property.set_int but with specifing your own source.

=item B<configval_set>

    boolean configval_set (string, string)

Sets a configvalue in the server.

=item B<medialib_path_import_encoded>

    boolean medialib_path_import_encoded (string)

Import a all files recursivly from the directory passed as argument which must already be url encoded.

=item B<configval_list>

    array configval_list ()

Lists all configuration values.

=item B<medialib_add_entry_encoded>

    int medialib_add_entry_encoded (string)

Add a URL to the medialib.

=item B<playback_seek_samples_rel>

    boolean playback_seek_samples_rel (int)

Seek to a number of samples relative to the current position in the current playback.

=item B<playback_pause>

    boolean playback_pause ()

Pause the current playback, will tell the output to not read nor write.

=item B<main_stats>

    struct main_stats ()

Get a list of statistics from the server.

=item B<medialib_entry_property_set_str_with_source>

    boolean medialib_entry_property_set_str_with_source (int, string, string, string)

Set a custom field in the medialib associated with a entry, the same as xmms.medialib.entry_property.set_str but with specifing your own source.

=item B<medialib_playlist_export>

    boolean medialib_playlist_export (string, string)

Export a serverside playlist to a format that could be read from another mediaplayer

=item B<bindata_retrieve>

    string bindata_retrieve (string)

Retrieve some binary data identified by a given hash.

=item B<medialib_select>

    array medialib_select (string)

Make a SQL query to the server medialib.

=item B<playlist_remove>

    boolean playlist_remove (int)

Remove an entry from the playlist.

=item B<playlist_insert_id>

    boolean playlist_insert_id (int, int)

Insert a medialib id at given position in playlist.

=item B<medialib_entry_property_set_str>

    boolean medialib_entry_property_set_str (int, string, string)

Associate a value with a medialib entry.

=item B<playback_start>

    boolean playback_start ()

Starts playback if server is idle.

=item B<playback_seek_samples>

    boolean playback_seek_samples (int)

Seek to a absoulte number of samples in the current playback.

=item B<playlist_sort>

    boolean playlist_sort (string)

Sorts the playlist according to the property.

=item B<playback_seek_ms_rel>

    boolean playback_seek_ms_rel (int)

Seek to a time relative to the current position in the current playback.

=item B<playback_status>

    int playback_status ()

Make server emit the playback status.

=item B<playlist_current_pos>

    int playlist_current_pos ()

Retrive the current position in the playlist.

=item B<medialib_get_id>

    int medialib_get_id (string)

Search for a entry (URL) in the medialib db and return its ID number.

=item B<medialib_get_info>

    struct medialib_get_info (int)

Retrieve information about a entry from the medialib.

=item B<xform_media_browse>

    array xform_media_browse (string)

Browse available media in a path.

=item B<playback_tickle>

    boolean playback_tickle ()

Stop decoding of current song.

=item B<xform_media_browse_encoded>

    array xform_media_browse_encoded (string)

Browse available media in a (already encoded) path.

=item B<playlist_insert_encoded>

    boolean playlist_insert_encoded (int, string)

Insert entry at given position in playlist.

=item B<plugin_list>

    array plugin_list ()

Get a list of loaded plugins from the server.

=item B<playlist_add_id>

    boolean playlist_add_id (int)

Add a medialib id to the playlist.

=item B<playback_volume_get>

    struct playback_volume_get ()

Get the current volume.

=item B<playlist_add>

    boolean playlist_add (string)

Add the url to the playlist.

=item B<playback_volume_set>

    boolean playback_volume_set (string, int)

Set the volume on a given channel.

=item B<medialib_playlist_save_current>

    boolean medialib_playlist_save_current (string)

Save the current playlist to a serverside playlist.

=item B<medialib_playlist_import>

    boolean medialib_playlist_import (string, string)

Import a playlist from a playlist file.

=item B<playlist_clear>

    boolean playlist_clear ()

Clears the current playlist.

=item B<playlist_radd>

    boolean playlist_radd (string)

Adds a directory recursivly to the playlist.

=item B<medialib_remove_entry>

    boolean medialib_remove_entry (int)

Remove a entry from the medialib.

=item B<medialib_rehash>

    boolean medialib_rehash (int)

Rehash the medialib, this will check data in the medialib still is the same as the data in files.

=item B<playlist_set_next_rel>

    boolean playlist_set_next_rel (int)

Same as xmms.playlist.set_next but relative to the current postion.

=item B<configval_register>

    boolean configval_register (string, string)

Registers a config property in the server.

=item B<medialib_add_to_playlist>

    boolean medialib_add_to_playlist (string)

Queries the medialib for files and adds the matching ones to the current playlist.

=item B<playlist_add_args>

    boolean playlist_add_args (string, struct)

Add the url to the playlist with arguments.

=item B<playlist_shuffle>

    boolean playlist_shuffle ()

Shuffles the current playlist.

=item B<medialib_playlist_load>

    boolean medialib_playlist_load (string)

Load a playlist from the medialib to the current active playlist.

=item B<bindata_remove>

    boolean bindata_remove (string)

Remove some binary data identified by a given hash.

=item B<medialib_entry_property_remove_with_source>

    boolean medialib_entry_property_remove_with_source (int, string, string)

Remove a custom field in the medialib associated with an entry. Identical to xmms.medialib.entry_property.remove except with specifying your own source.

=item B<playlist_insert>

    boolean playlist_insert (int, string)

Insert entry at given position in playlist.

=item B<medialib_path_import>

    boolean medialib_path_import (string)

Import a all files recursivly from the directory passed as argument.

=item B<playlist_radd_encoded>

    boolean playlist_radd_encoded (string)

Adds a directory recursivly to the playlist.

=item B<playlist_list>

    array playlist_list ()

List current playlist.

=item B<medialib_add_entry>

    int medialib_add_entry (string)

Add a URL to the medialib.

=item B<configval_get>

    string configval_get (string)

Retrives a list of configvalues in server.

=item B<bindata_add>

    string bindata_add (string)

Add some binary data to be stored in the server. Returns a string which uniquely identifies the data.

=item B<userconfdir_get>

    string userconfdir_get ()

Get the absolute path to the user config dir.

=item B<quit>

    boolean quit ()

Tell the server to quit.

=item B<playlist_add_encoded>

    boolean playlist_add_encoded (string)

Add the url to the playlist.

=item B<playback_playtime>

    int playback_playtime ()

Request the playback_playtime signal.

=item B<medialib_playlists_list>

    array medialib_playlists_list ()

Returns a list of all available playlists.

=item B<medialib_entry_property_set_int>

    boolean medialib_entry_property_set_int (int, string, int)

Associate a int value with a medialib entry.

=item B<playback_stop>

    boolean playback_stop ()

Stops the current playback.

=item B<medialib_playlist_list>

    array medialib_playlist_list (string)

This will make the server list the given playlist.

=item B<playlist_move>

    boolean playlist_move (int, int)

Move a playlist entry to a new position (absolute move).

=item B<playback_current_id>

    int playback_current_id ()

Make server emit the current id.

=back

=head2 The Default Methods Provided

The following methods are provided with this package, and are the ones
installed on newly-created server objects unless told not to. These are
identified by their published names, as they are compiled internally as
anonymous subroutines and thus cannot be called directly:

=over

=item B<system.identity>

returns a B<string> value identifying the server name, version, and possibly a
capability level. takes no arguments.

=item B<system.introspection>

returns a series of B<struct> objects that give overview documentation of one
or more of the published methods. it may be called with a B<string>
identifying a single routine, in which case the return value is a
B<struct>. it may be called with an B<array> of B<string> values, in which
case an B<array> of B<struct> values, one per element in, is returned. lastly,
it may be called with no input parameters, in which case all published
routines are documented.  note that routines may be configured to be hidden
from such introspection queries.

=item B<system.listmethods>

returns a list of the published methods or a subset of them as an B<array> of
B<string> values. if called with no parameters, returns all (non-hidden)
method names. if called with a single B<string> pattern, returns only those
names that contain the string as a substring of their name (case-sensitive,
and this is i<not> a regular expression evaluation).

=item B<system.methodhelp>

takes either a single method name as a B<string>, or a series of them as an
B<array> of B<string>. the return value is the help text for the method, as
either a B<string> or B<array> of B<string> value. if the method(s) have no
help text, the string will be null.

=item B<system.methodsignature>

as above, but returns the signatures that the method accepts, as B<array> of
B<string> representations. if only one method is requests via a B<string>
parameter, then the return value is the corresponding array. if the parameter
in is an B<array>, then the returned value will be an B<array> of B<array> of
B<string>.

=item B<system.multicall>

this is a simple implementation of composite function calls in a single
request. it takes an B<array> of B<struct> values. each B<struct> has at least
a c<methodname> member, which provides the name of the method to call. if
there is also a c<params> member, it refers to an B<array> of the parameters
that should be passed to the call.

=item B<system.status>

takes no arguments and returns a B<struct> containing a number of system
status values including (but not limited to) the current time on the server,
the time the server was started (both of these are returned in both iso 8601
and unix-style integer formats), number of requests dispatched, and some
identifying information (hostname, port, etc.).

=back

=head1 AUTHOR

Florian Ragwitz, C<< <rafl at debian.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-audio-xmmsclient-xmlrpc at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Audio-XMMSClient-XMLRPC>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Audio::XMMSClient::XMLRPC

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Audio-XMMSClient-XMLRPC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Audio-XMMSClient-XMLRPC>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Audio-XMMSClient-XMLRPC>

=item * Search CPAN

L<http://search.cpan.org/dist/Audio-XMMSClient-XMLRPC>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Florian Ragwitz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Audio::XMMSClient::XMLRPC
