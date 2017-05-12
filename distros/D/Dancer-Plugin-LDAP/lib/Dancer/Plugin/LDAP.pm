package Dancer::Plugin::LDAP;

use 5.006;
use strict;
use warnings;

use Dancer::Plugin;
use Net::LDAP;
use Dancer::Plugin::LDAP::Handle;

=head1 NAME

Dancer::Plugin::LDAP - LDAP plugin for Dancer micro framework

=head1 VERSION

Version 0.0050

=cut

our $VERSION = '0.0050';


=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::LDAP;

    # Calling the ldap keyword returns you a LDAP handle
    $ldap = ldap;

    # Use convenience methods for retrieving, updating and deleting LDAP entries
    $account = ldap->quick_select({dn => 'uid=racke@linuxia.de,dc=linuxia,dc=de'});

    ldap->quick_update('uid=racke@linuxia.de,dc=linuxia,dc=de', {l => 'Vienna'});

    ldap->quick_delete('uid=racke@linuxia.de,dc=linuxia,dc=de');

=head1 DESCRIPTION

Provides an easy way to obtain a connected LDAP handle by simply calling
the ldap keyword within your L<Dancer> application.

Returns a L<Dancer::Plugin::LDAP::Handle> object, which is a subclass of
a L<Net::LDAP> handle object, so it does everything you'd expect
to do with Net::LDAP, but also adds a few convenience methods.  See the documentation
for L<Dancer::Plugin::LDAP::Handle> for full details of those.

This plugin is compatible to Dancer 1 and Dancer 2.

=head2 TEXT SEARCHES

Need to run a text search across your LDAP directory? This plugin provides
a quick way to do that:

    for (qw/uid sn givenName c l/) {
	$search{$_} = [substr => $args{search}];
    }

    @entries = ldap->quick_select({-or => \%search});

=head2 UTF-8

Attribute values returned by the L<Dancer::Plugin::LDAP::Handle/quick_select> method are
automatically converted to UTF-8 strings.

=head1 CONFIGURATION

    plugins:
        LDAP:
            uri: 'ldap://127.0.0.1:389/'
            base: 'dc=linuxia,dc=de'
            bind: cn=admin,dc=linuxia,dc=de
            password: nevairbe

=cut

my $settings = undef;
my %handles;
my $def_handle = {};

register ldap => sub {
	my ($self, $arg) = plugin_args;

	_load_ldap_settings() unless $settings;
	
	# The key to use to store this handle in %handles.  This will be either the
    # name supplied to database(), the hashref supplied to database() (thus, as
    # long as the same hashref of settings is passed, the same handle will be
    # reused) or $def_handle if database() is called without args:
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
            Dancer::Logger::error(
                "No LDAP settings for " . ($arg || "default connection")
            );
            return;
        }
    }

#	Dancer::Logger::debug("Details: ", $conn_details);

    # To be fork safe and thread safe, use a combination of the PID and TID (if
    # running with use threads) to make sure no two processes/threads share
    # handles.  Implementation based on DBIx::Connector by David E. Wheeler.
    my $pid_tid = $$;
    $pid_tid .= '_' . threads->tid if $INC{'threads.pm'};

    # OK, see if we have a matching handle
    $handle = $handles{$pid_tid}{$handle_key} || {};

    if ($handle->{dbh}) {
        if ($conn_details->{connection_check_threshold} &&
            time - $handle->{last_connection_check}
            < $conn_details->{connection_check_threshold}) 
        {
            return $handle->{dbh};
        } else {
            if (_check_connection($handle->{dbh})) {
                $handle->{last_connection_check} = time;
                return $handle->{dbh};
            } else {
                Dancer::Logger::debug(
                    "Database connection went away, reconnecting"
                );
                if ($handle->{dbh}) { $handle->{dbh}->disconnect; }
                return $handle->{dbh}= _get_connection($conn_details);

            }
        }
    } else {
        # Get a new connection
        if ($handle->{dbh} = _get_connection($conn_details)) {
            $handle->{last_connection_check} = time;
            $handles{$pid_tid}{$handle_key} = $handle;
#			Dancer::Logger::debug("Handle: ", $handle);
            return $handle->{dbh};
        } else {
            return;
        }
    }
};

register_plugin for_versions => [ 1, 2 ];

# Try to establish a LDAP connection based on the given settings
sub _get_connection {
	my $settings = shift;
	my ($ldap, $ldret);

	unless ($ldap = Net::LDAP->new($settings->{uri})) {
		Dancer::Logger::error("LDAP connection to $settings->{uri} failed: " . $@);
		return;
	}

	$ldret = $ldap->bind($settings->{bind},
						 password => $settings->{password});

	if ($ldret->code) {
		Dancer::Logger::error('LDAP bind failed (' . $ldret->code . '): '
							  . $ldret->error);
		return;
	}
	
	# pass reference to the settings
	$ldap->{dancer_settings} = $settings;
	
	return bless $ldap, 'Dancer::Plugin::LDAP::Handle';
}

# Check whether the connection is alive
sub _check_connection {
    my $ldap = shift;
    return unless $ldap;
    return unless $ldap->socket;
	return 1;
}

sub _get_settings {
    my $name = shift;
    my $return_settings;

    # If no name given, just return the default settings
    if (!defined $name) {
        $return_settings = { %$settings };
    } else {
        # If there are no named connections in the config, bail now:
        return unless exists $settings->{connections};


        # OK, find a matching config for this name:
        if (my $settings = $settings->{connections}{$name}) {
            $return_settings = { %$settings };
        } else {
            # OK, didn't match anything
            Dancer::Logger::error(
                "Asked for a database handle named '$name' but no matching  "
               ."connection details found in config"
            );
        }
    }

    # We should have soemthing to return now; make sure we have a
    # connection_check_threshold, then return what we found.  In previous
    # versions the documentation contained a typo mentioning
    # connectivity-check-threshold, so support that as an alias.
    if (exists $return_settings->{'connectivity-check-threshold'}
        && !exists $return_settings->{connection_check_threshold})
    {
        $return_settings->{connection_check_threshold}
            = delete $return_settings->{'connectivity-check-threshold'};
    }

    $return_settings->{connection_check_threshold} ||= 30;
    return $return_settings;

}

sub _load_ldap_settings { $settings = plugin_setting; }

=head1 AUTHOR

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

=head1 CONTRIBUTING

This module is developed on Github at:

L<https://github.com/racke/Dancer-Plugin-LDAP>

Feel free to fork the repo and submit pull requests!  Also, it makes sense to 
L<watch the repo|https://github.com/racke/Dancer-Plugin-LDAP/toggle_watch> 
on GitHub for updates.

Feedback and bug reports are always appreciated.  Even a quick mail to let me
know the module is useful to you would be very nice - it's nice to know if code
is being actively used.

=head1 ACKNOWLEDGEMENTS

David Precious for providing the great L<Dancer::Plugin::Database>, which
helped me a lot in terms of ideas and code to write this plugin.

Marco Pessotto for fixing update of attributes with empty value.

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-ldap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-LDAP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::LDAP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-LDAP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-LDAP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-LDAP>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-LDAP/>

=back

You can find the author on IRC in the channel C<#dancer> on <irc.perl.org>.

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2013 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Dancer>

L<Net::LDAP>

=cut

1; # End of Dancer::Plugin::LDAP
