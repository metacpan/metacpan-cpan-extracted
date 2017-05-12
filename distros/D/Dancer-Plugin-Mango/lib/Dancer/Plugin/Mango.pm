# ABSTRACT: MongoDB plugin for the Dancer micro framework
package Dancer::Plugin::Mango;

use strict;
use warnings;
use Dancer::Plugin;
use Mango;
use Scalar::Util 'blessed';
use Dancer qw{:syntax};

my $dancer_version = (exists &dancer_version) ? int(dancer_version()) : 1;
my ($logger);
if ($dancer_version == 1) {
    require Dancer::Config;
    Dancer::Config->import();

    $logger = sub { Dancer::Logger->can($_[0])->($_[1]) };
} else {
    $logger = sub { log @_ };
}

=encoding utf8
=head1 NAME

Dancer::Plugin::Mango - MongoDB connections as provided by Mango.

=head1 STATUS

Tested in a production environment. It's a good idea to read the documentation for
Mango as it's async. Which means you must be ready to handle this. In most of my
code I'm using the loop function to wait for the server response. However, for
inserts, I'm not waiting at all. Handy.

=cut

our $VERSION = 0.41;

my $settings = undef;
my $conn = undef;
my $lasterror = undef;

sub _load_db_settings {
    $settings = plugin_setting;
}

my %handles;
# Hashref used as key for default handle, so we don't have a magic value that
# the user could use for one of their connection names and cause problems
# (Kudos to Igor Bujna for the idea)
my $def_handle = {};

sub moango {

    my ( $self, $arg ) = plugin_args(@_);

    $arg = shift if blessed($arg) and $arg->isa('Dancer::Core::DSL');

    # The key to use to store this handle in %handles.  This will be either the
    # name supplied to database(), the hashref supplied to database() (thus, as
    # long as the same hashref of settings is passed, the same handle will be
    # reused) or $def_handle if database() is called without args:

    _load_db_settings() if ( !$settings);

    my $handle_key;
    my $conn_details; # connection settings to use.
    my $handle;


    # Accept a hashref of settings to use, if desired.  If so, we use this
    # hashref to look for the handle, too, so as long as the same hashref is
    # passed to the database() keyword, we'll reuse the same handle:
    if (ref $arg eq 'HASH') {
        $handle_key = $arg;
        $conn_details = $arg;
    } else {
        $handle_key = defined $arg ? $arg : $def_handle;
        $conn_details = _get_settings($arg);
        if (!$conn_details) {
            $logger->(error => "No DB settings for " . ($arg || "default connection"));
            return;
        }
    }

    # To be fork safe and thread safe, use a combination of the PID and TID (if
    # running with use threads) to make sure no two processes/threads share
    # handles.  Implementation based on DBIx::Connector by David E. Wheeler.
    my $pid_tid = $$;
    $pid_tid .= '_' . threads->tid if $INC{'threads.pm'};

    # OK, see if we have a matching handle
    $handle = $handles{$pid_tid}{$handle_key} || {};

    if ($handle->{dbh}) {
        # If we should never check, go no further:
        if (!$conn_details->{connection_check_threshold}) {
            return $handle->{dbh};
        }

        if ($handle->{dbh}{Active} && $conn_details->{connection_check_threshold} &&
            time - $handle->{last_connection_check}
            < $conn_details->{connection_check_threshold})
        {
            return $handle->{dbh};
        } else {
            if (_check_connection($handle->{dbh})) {
                $handle->{last_connection_check} = time;
                return $handle->{dbh};
            } else {

                $logger->(debug => "Database connection went away, reconnecting");
                execute_hook('database_connection_lost', $handle->{dbh});

                return $handle->{dbh}= _get_connection($conn_details);

            }
        }
    } else {
        # Get a new connection
        if ($handle->{dbh} = _get_connection($conn_details)) {
            $handle->{last_connection_check} = time;
            $handles{$pid_tid}{$handle_key} = $handle;

            if (ref $handle_key && ref $handle_key ne ref $def_handle) {
                # We were given a hashref of connection settings.  Shove a
                # reference to that hashref into the handle, so that the hashref
                # doesn't go out of scope for the life of the handle.
                # Otherwise, that area of memory could be re-used, and, given
                # different DB settings in a hashref that just happens to have
                # the same address, we'll happily hand back the original handle.
                # See http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=665221
                # Thanks to Sam Kington for suggesting this fix :)
                $handle->{_orig_settings_hashref} = $handle_key;
            }
            return $handle->{dbh};
        } else {
            return;
        }
    }
};

## return a connected MongoDB object
## registering both mango and mongo due to a typo that was released
register mango => \&moango;
register mongo => \&moango;

register_hook(qw(mongodb_connected
                 mongodb_connection_lost
                 mongodb_connection_failed
                 mongodb_error));

register_plugin(for_versions => ['1', '2']);

# Given the settings to use, try to get a database connection
sub _get_connection {
    my $settings = shift;

    # Assemble the Connection String:
    my $dsn = 'mongodb://' .
        ( $settings->{host} || 'localhost' ) .
        ( defined $settings->{port} ? ':' . $settings->{port} : () );

    my $dbh = Mango->new($dsn);

    $dbh->default_db($settings->{db_name})
        if defined $settings->{db_name};

    if (defined $settings->{username} && defined $settings->{password}) {
        push @{$settings->{db_credentials}}, [ $settings->{db_name}, $settings->{username}, $settings->{password}];
    }


    if (defined $settings->{db_credentials} and ref $settings->{db_credentials} eq 'ARRAY') {
        $dbh->credentials($settings->{db_credentials});
    }

    if (defined $settings->{ioloop}) {
        my ( $module, $function ) = split(/\-\>/, $settings->{ioloop});
        $dbh->ioloop($module->$function);
    }

    if (defined $settings->{j}) {
        $dbh->j($settings->{j})
    };

    if (defined $settings->{max_bson_size}) {
        $dbh->max_bson_size($settings->{max_bson_size})
    };

    if (defined $settings->{max_connections}) {
        $dbh->max_connections($settings->{max_connections})
    }

    if (defined $settings->{max_write_batch_size}) {
        $dbh->max_write_batch_size($settings->{max_write_batch_size})
    }

    if ( defined $settings->{protocol}) {
        my ( $module, $function ) = split(/\-\>/, $settings->{protocol});
        $dbh->protocol($module->$function);
    }

    if ( defined $settings->{w}) {
        $dbh->w($settings->{w})
    }

    if ( defined $settings->{wtimeout}) {
        $dbh->wtimeout($settings->{wtimeout})
    }

    #$dbh->on( error => \&_mango_error() );
    #$dbh->on( connection => \&_mango_connection() );

    if (!$dbh) {
        $logger->(error => "Database connection failed - " . $lasterror);
        execute_hook('database_connection_failed', $settings);
        return;
    }

    execute_hook('database_connected', $dbh);

    return $dbh;
}

# Check the connection is alive
sub _check_connection {
    my $dbh = shift;
    return unless $dbh;

    my $curs;

    $lasterror = undef;

    eval {
        $curs = $dbh->db($settings->{db_name})->collection('prototype')->find_one();
    };

    if (!defined $lasterror) {
        return 1;
    }

    return;
}

sub _mango_error {
    my ( $mango, $err ) = @_;
    $lasterror = $err;
    return;
}

sub _mango_connection {
    return;
}

sub _get_settings {
    my $name = shift;
    my $return_settings;

    # If no name given, just return the default settings
    if (!defined $name) {
        $return_settings = { %$settings };
        # Yeah, you can have ZERO settings in Mongo.
    } else {
        # If there are no named connections in the config, bail now:
        return unless exists $settings->{connections};

        # OK, find a matching config for this name:
        if (my $named_settings = $settings->{connections}{$name}) {
            # Take a (shallow) copy of the settings, so we don't change them
            $return_settings = { %$named_settings };
        } else {
            # OK, didn't match anything
            $logger->('error',
                      "Asked for a database handle named '$name' but no matching  "
                      ."connection details found in config"
            );
        }
    }

    # If the setting wasn't provided, default to 30 seconds; if a false value is
    # provided, though, leave it alone.  (Older versions just checked for
    # truthiness, so a value of zero would still default to 30 seconds, which
    # isn't ideal.)
    if (!exists $return_settings->{connection_check_threshold}) {
        $return_settings->{connection_check_threshold} = 30;
    }

    return $return_settings;

}
1;

__END__
=pod

=head1 VERSION

version 0.41

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Mango;

    get '/widget/view/:id' => sub {
        my $mg = mango('mongoa');
        my $db = $mg->db('foo');
        my $cl = $db->collection('bar');
        my $curs = $cl->find({ this => param('id') });

        ..
    }

    # or

    get '/widget/view/:id' => sub {
        my $mg = mango('mongoa')->db('foo')->collection('bar')->find({ this => param('id') });

        ..
    }


=head1 DESCRIPTION

Dancer::Plugin::Mango implements the "Mango" driver from the Mojolicious team. It
also uses some of the connection pooling features that the Dancer::Plugin::Database module
implements. For the most part, read the Mango documentation for full implementation.

=head1 CONFIGURATON

Connection details will be taken from your Dancer application config file, and
should be specified as follows:

    plugins:
        Mango:
            host: "myhost"
            port: 27017
            db_name: "mydb"
            username: "myuser"
            password: "mypass"
            w: 1
            wtimeout: 1000
            credentials:
                [ mydb, myuser, mypass]
                [ myotherdb, myotheruser, myotherpass]

or:

    plugin:
        Mango:
            connections:
                foohost:
                    host: "foohost"
                    port: 27017
                    db_name: "mydb"
                barhost:
                    host: "barhost"
                    port: 27017

The attribute names are verbatim to the attribute names in Mango.

=head1 ACKNOWLEDGEMENTS

Thanks to Adam Taylor for the original Dancer::Plugin::Mongo.
Thanks to the Dancer team for creating a product that keeps me gainfully employed.
Thanks to the Mojolicious team for Mango.

This module is HEAVILY reliant on the original Dancer::Plugin::Database code. Most parts in here are unceremoniously copy-pasted from their code. Thanks guys for the work you're doing!

=head1 AUTHOR

Tyler Hardison <tyler@seraph-net.net>

=head1 CONTRIBUTORS

Collin Seaton cseaton <at> cpan <dot> org

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Tyler Hardison.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
