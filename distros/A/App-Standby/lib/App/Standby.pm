package App::Standby;
$App::Standby::VERSION = '0.04';
BEGIN {
  $App::Standby::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Managing on-call rotation and notification queues

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

use Log::Tree;

# extends ...
# has ...
has 'dbh' => (
    'is'    => 'rw',
    'isa'   => 'App::Standby::DB',
    'required' => 1,
);

has 'logger' => (
    'is'    => 'rw',
    'isa'   => 'Log::Tree',
    'lazy'  => 1,
    'builder' => '_init_logger',
);

# with ...
# initializers ...
sub _init_logger {
    my $self = shift;

    my $Logger = Log::Tree::->new('standby-mgm');

    return $Logger;
}

# your code here ...
sub _config_values {
    my $self = shift;
    my $key = shift;
    my $group_id = shift;

    my @args = ();
    my $sql = 'SELECT `value` FROM config WHERE `key` = ?';
    push(@args,$key);
    if($group_id) {
        $sql .= ' AND group_id = ?';
        push(@args,$group_id);
    }
    my $sth = $self->dbh()->prepare($sql);
    $sth->execute(@args);

    my @values = ();

    while(my $value = $sth->fetchrow_array()) {
        push(@values,$value);
    }

    $sth->finish();

    return \@values;
}

sub _load_class {
    my $self = shift;
    my $classname  = shift;

    # String eval is bad. Always. Except for require ;)
    ## no critic (ProhibitStringyEval)
    my $ok = eval "require $classname;";
    ## use critic
    if ($@) {
        return $@;
    } else {
        return $classname;
    }
}


sub get_groups {
    my $self = shift;

    my $sql = 'SELECT id,name FROM groups';
    my $sth = $self->dbh()->prepare($sql);

    my %grps = ();
    $sth->execute();
    while(my ($id,$name) = $sth->fetchrow_array()) {
        $grps{$id} = $name;
    }

    $sth->finish();

    return \%grps;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::Standby - Managing on-call rotation and notification queues

=head1 DESCRIPTION

This distribution provides a small Plack webapp which helps with managing on-call rotations
and notification queues. It allows you to manage several different queues from
on place. It is easily extendible by plugins which can talk to virtually API
endpoint to update a queue or a contact.

Most organizations have at least one big monitoring system (like Nagios or Zabbix) and
at least one external service level monitoring and other means of notification,
If you don't want to pass around a shared on-call mobile you have to remember to update all
those services when the one on duty changes. This app will help you with that.

It allows you to manage several groups with their own queues and update each
groups external services with just one click.

=head1 METHODS

=head2 get_groups

Returns a list of all groups.

=head1 NAME

App::Standby - Managing on-call rotation and notification queues

=head1 SETUP

This app can be run as CGI or from within an PSGI runtime like Starman.

It needs not runtime configuration unless you want to change the path to the SQLite
database file.

You need to bootstrap the app by creating the first group like this:

    standby-mgm.pl bootstrap -nRoadies -kbase

This will create the group named "Roadies" with the key "base". The key is a simple
shared key necessary to change any value for this group in the webinterface. This
is the most basic form of authorization, but has proven sufficient so far. Patches
for more extensive forms of authentication are welcome.

WARNING: Make sure the database file is owned by the user service the webinterface
and also accessible by the user execution your cronjobs, e.g. www-data.

    chown -R www-data:www-data /var/lib/standby-mgm/

=head1 CONFIGURATION

This section provides an example of a complete configuration using dummy values for names,
phone numbers, URLs and the like.

=head2 SERVICES

In order for this app to do anything there must be two things in the database: users and services.
This section will show you how to create the later.

First select services and open up the new service dialog. Enter a short name for this service.
Remember it must be all lowercase alphanumerics since it's going to be used as a prefix for the
configuration values later. The description can be anything. Select the appropriate class and
enter the group password you've dedfined when bootstrapping the service.

Choose class HTTP for a simple endpoint which just gets the whole ordered user list as a JSON
string. Chosse MS for a Monitoring::Spooler endpoint and Pingdom if you have an Pingdom account.

Add as many services as necessary.

Next select config from the menu and add new config items. For each service at least one. The
HTTP service need an endpoint, so if the HTTP service was called simple then the config item
for the endpoint must be called simple_endpoint and contain something like http://simple.domain/api/.

For any pingdom service there must be at least four config items. The necessary items are apikey,
username, password and contact_id. The last one may be given multiple times to update
multiple Pingdom contacts in one account. If your service is called pingdom the keys would be
called pingdom_apikey, pingdom_username, pingdom_password and pingdom_contact_id.

The MS service class needs an endpoint and a group id (name_group_id) which is used
to update the appropriate group in the MS DB. If you call your MS service "ms" then the necessary
keys would be called "ms_endpoint" with a value of e.g. "http://localhost/ms/?rm=update_queue" and
"ms_group_id" with a value of e.g. "1".

Have a look at the CPAN distribution Monitoring::Spooler for more documentation on MS.

=head2 CONTACTS

To be able to notify someone you must add some contacts. Since the whole point of this app
is to help with managing changing on call rotations you should create more than one contact.

Create at least two contacts. The name may be anything but you should know who it is refering to.
The cellphone number should be in normalized international format (+<countryprefix><areaprefix>
<extension>). Again, enter the group key to authenticate yourself.

After creation contacts are disabled and won't participate in any rotation, so be sure to enable
some users (usually all).

Some services may need additional configuration per users, so you can store additional config
under each user.

Now you need to change the notification order at least once to make sure all remote services
are updated. This happens only when the order is changed.

=head1 PLUGINS

Have a look at the examples directory for some example plugins.

=head1 DEBUGGING

If anything goes wrong have a look at the logfile. Depending on your configuration its either at
/var/log/standby-mgm.log or /tmp/standby-mgm.log.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
