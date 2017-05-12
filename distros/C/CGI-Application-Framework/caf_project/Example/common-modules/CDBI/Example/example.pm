package CDBI::Example::example;

use Class::DBI::Loader;

# ---------------------------------------------------------------------
# In the package name, the last part, "example", refers to the database
# we are working in and the middle part, "Example" the project we are
# working with.  This is just a naming convention, though.
# ---------------------------------------------------------------------

use base qw ( CDBI::Example );

use strict;
use warnings;

# -------------------------------------------------------------------
# Name of the CAP::CC configuration in which the database info can
# be found
#
# (can be overridden by a subclass)
#
# To use the same configuration file and settings as the main application,
# leave this as the default, which is undefined.
# -------------------------------------------------------------------
sub db_config_name {
    undef;
}

# -------------------------------------------------------------------
# Section within the configuration file in which the database info can
# be found
#
# (should be overridden by a subclass)
#
# For instance, if the database options are in the <database> section,
# return the string 'database'
# -------------------------------------------------------------------
sub db_config_section {
    'db_example';
}

# -------------------------------------------------------------------
# We want to set up our tables right at the start of the request
# To do so, we have to instruct the Framework to call our setup_tables sub
# during the init phase.
# -------------------------------------------------------------------

sub import {
    my $caller = caller;
    $caller->new_hook('database_init');
    $caller->add_callback('database_init', \&setup_tables);
}

# -------------------------------------------------------------------
# setup_tables()
# Using the We want to set up our tables right at the start of the request
# To do so, we have to instruct Framework to call our setup_tables
# sub during the init phase.
# -------------------------------------------------------------------
my $Already_Setup_Tables;
sub setup_tables {

    # In a persistent environment, this sub will be called at the
    # beginning of every request.  To avoid repeatedly setting up
    # the tables, we set a flag ($Already_Setup_Tables) after the
    # first time.

    return if $Already_Setup_Tables;

    my $config = CGI::Application::Plugin::Config::Context->get_current_context(__PACKAGE__->db_config_name);
    my $db_config = $config->{__PACKAGE__->db_config_section};

    my $loader = Class::DBI::Loader->new(
        debug         => 0,
        dsn           => $db_config->{'dsn'},
        user          => $db_config->{'username'},
        password      => $db_config->{'password'},
        namespace     => __PACKAGE__,
        relationships => 0,
    );

    # ----------------------------------------------------------------
    # Set up the relationships between tables
    #
    # ----------------------------------------------------------------

    CDBI::Example::example::Users->has_many( albums => 'CDBI::Example::example::UserAlbum');

    CDBI::Example::example::Artist->has_many( albums => 'CDBI::Example::example::Album' );
    CDBI::Example::example::Artist->has_many( songs  => 'CDBI::Example::example::Song'  );

    CDBI::Example::example::Album->has_a( artist_id => 'CDBI::Example::example::Artist' );
    CDBI::Example::example::Album->has_many(
    		      songs => 'CDBI::Example::example::AlbumSong',
    		      { order_by => 'track_num' }
    		      );

    # ---------------------------------------------------------------------------
    # The below are slighly more complex (though still generaly simple) tables
    # that require that we explicitly declare the colums within them. (I.e. they
    # have primary keys that are made up of multiple columns.)
    # ---------------------------------------------------------------------------

    CDBI::Example::example::UserAlbum->has_many(
    		      albums => 'CDBI::Example::example::Album',
    		      );

    CDBI::Example::example::AlbumSong->has_a( song_id => 'CDBI::Example::example::Song' );

    $Already_Setup_Tables = 1;
}


1;


