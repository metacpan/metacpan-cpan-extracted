package Catalyst::Plugin::Session::Store::BerkeleyDB;
use strict;
use warnings;

use MRO::Compat;
use BerkeleyDB;
use BerkeleyDB::Manager;
use Storable qw(nfreeze thaw);
use Scalar::Util qw(blessed);
use Catalyst::Utils;
use Carp qw(confess);

use namespace::clean;

our $VERSION = '0.04';

use base 'Class::Data::Inheritable', 'Catalyst::Plugin::Session::Store';

my $_manager = '_session_store_manager';
my $_db = '_session_store_database';

__PACKAGE__->mk_classdata($_manager);
__PACKAGE__->mk_classdata($_db);

sub setup_session {
    my $app = shift;

    my $manager = delete $app->_session_plugin_config->{manager} || +{
        home => Path::Class::Dir->new(
            Catalyst::Utils::class2tempdir($app), 'sessions',
        ),
        create => 1,
    };

    my $db = delete $app->_session_plugin_config->{database} || 'catalyst_sessions';

    if(!blessed $manager){
        $manager = BerkeleyDB::Manager->new( $manager );
    }

    if(!blessed $db){
        $db = $manager->open_db( $db );
    }

    $app->$_manager($manager);
    $app->$_db($db);

    return $app->maybe::next::method(@_);
}

sub _data_is_raw {
    my ($c, $id, $data) = @_;
    return 1 if $id =~ /^expires:/;
    return 0;
}

sub get_session_data {
    my ($c, $id) = @_;

    my $data;
    $c->$_manager->txn_do(sub {
        my $status = $c->$_db->db_get($id, $data);

        confess "BerkeleyDB error while fetching data: $BerkeleyDB::Error ($status)"
          if $status && $status != DB_NOTFOUND;
    });

    if($data) {
        if($c->_data_is_raw($id)){
            return $data;
        }
        return thaw($data);
    }
    return {};
}

sub store_session_data {
    my ($c, $id, $data) = @_;
    my $frozen = $c->_data_is_raw($id) ? $data : nfreeze($data);
    $c->$_manager->txn_do(sub {
        $c->$_db->db_put($id, $frozen);
    });
}

sub delete_session_data {
    my ($c, $id) = @_;
    $c->$_manager->txn_do(sub {
        $c->$_db->db_del($id);
    });
}

sub delete_expired_sessions {
    my($c, $id) = @_;
    my $manager = $c->$_manager;
    my $db = $c->$_db;

    $manager->txn_do(sub {
        my ($key, $value) = ("", "");

        # find out what we need to delete
        my %to_delete;
        my $all = $db->db_cursor;
        while( 0 == $all->c_get( $key, $value, DB_NEXT ) ){
            if($key =~ /^expires:(.+)$/){
                $to_delete{$1} = 1 if time > $value;
            }
        }

        # then delete all of those
        $all = $db->db_cursor;
        while( 0 == $all->c_get( $key, $value, DB_NEXT ) ){
            my ($name, $id) = split /:/, $key;
            $all->c_del() and warn "bye, $key" if $to_delete{$id};
        };
    });
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Session::Store::BerkeleyDB - store sessions in a berkeleydb

=head1 SYNOPSIS

    package YourApp;
    use Catalyst qw/Session Session::State::Cookie Session::Store::BerkeleyDB/;

=head1 DESCRIPTION

This module will store Catalyst sessions in a Berkeley database
managed by C<BerkeleyDB::Manager>.  Unlike other storage mechanisms,
sessions are never lost before their expiration time.

To cleanup old sessions, you might want to make sure
C<< $c->delete_expired_sessions >> is run periodically.

=head1 CONFIGURATION

You can configure this module in a number of ways.  By default, the
module will create a Berkeley database called "catalyst_sessions" in a
directory called "sessions" in your app's temp directory.

You can customize this, though, by setting the values of the "manager"
and "database" keys in C<< $c->config->{'Plugin::Session'} >>.

The C<manager> key can be either an instance of C<BerkeleyDB::Manager>, or
it can be a hash to pass to the constructor of C<BerkeleyDB::Manager>.  (Or
it can be empty, and we will use sane defaults.)

The C<database> key can be the result of C<< $manager->open_db( ... )
>>, or it can be a string naming the database.  By default, we use
"catalyst_sessions".

Any other keys in the hash will be ignored by this module, but might
be relevant to other session plugins.

=head1 CONTRIBUTING

Patches welcome!

You can get a copy of the repository by running:

  $ git clone git://git.jrock.us/Catalyst-Plugin-Session-Store-BerkeleyDB

and you can view the repository in your web browser at:

L<http://git.jrock.us/?p=Catalyst-Plugin-Session-Store-BerkeleyDB.git;a=summary>

=head1 SEE ALSO

L<BerkeleyDB>

L<BerkeleyDB::Manager>

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2008 Infinity Interactive.  This module is free
software, you may distribute it under the same terms as Perl itself.

