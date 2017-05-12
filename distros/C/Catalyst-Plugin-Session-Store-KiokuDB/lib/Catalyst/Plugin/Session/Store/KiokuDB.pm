package Catalyst::Plugin::Session::Store::KiokuDB;

use strict;
use warnings;
use base qw/Catalyst::Plugin::Session::Store/;
use NEXT;
use KiokuDB;
use KiokuDB::Backend::BDB::GIN;

our $VERSION = '0.02';

sub new { return bless {}, shift; }

sub setup_session {
    my $c = shift;

    $c->NEXT::setup_session(@_);
    
    my $confSess = $c->config->{session};
    if ($confSess->{kiokuObject}) {
        $confSess->{kioku} = $confSess->{kiokuObject};
    }
    elsif ($confSess->{kiokuDir}) {
        $confSess->{kioku} = KiokuDB->new(
                backend => KiokuDB::Backend::BDB::GIN->new(manager => { home => $confSess->{kiokuDir}, create  => 1 }),
        );
    }
    elsif ($confSess->{kiokuModel}) {
        # This is a NOP - handled in get_kioku() below
    }
    else {
        Catalyst::Exception->throw( 
            message => "KiokuDB requires at least 'kiokuObject', 'kiokuDir' or 'kiokuModel' (in conjunction with Catalyst::Model::KiokuDB) to be set."
        );
    }

}

sub get_kioku {
    my ($c) = @_;
   
    return $c->config->{session}->{kioku} ||
        $c->model($c->config->{session}->{kiokuModel});
}
   
sub get_session_data {
    my ($c, $key) = @_;
    
    my $kioku = get_kioku($c);    
    my ($type, $id) = split ':', $key;
    
    my $obj = $kioku->lookup($id) || return;
    return $obj->expires if $type eq 'expires';
    return $obj->data;
}

sub store_session_data {
    my ($c, $key, $data) = @_;
    
    my $kioku = get_kioku($c);
    my ($type, $id) = split ':', $key;
    
    if (my $obj = $kioku->lookup($id)) {
        if ($type eq 'expires') {
            $obj->expires($data);
        }
        else {
            $obj->flash(($type eq 'flash') ? 1 : 0);
            $obj->data($data);
        }
        $kioku->store($obj); # no id means update
    }
    else {
        my $obj = Catalyst::Plugin::Session::Store::KiokuDB::Session->new(
            id      => $id,
            flash   => ($type eq 'flash') ? 1 : 0,
            expires => ($type eq 'expires') ? $data : undef,
            data    => ($type eq 'expires') ? {} : $data,
        );
        $kioku->store($id => $obj); # id means insert
    }
    return;
}

sub delete_session_data {
    my ($c, $key) = @_;
    
    my $kioku = get_kioku($c);    
    my ($type, $id) = split ':', $key;

    return if $type eq 'expires';

    $kioku->delete($id);

    return;
}

# not supported yet
sub delete_expired_sessions {}


package Catalyst::Plugin::Session::Store::KiokuDB::Session;
use Moose;

has 'id' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has 'expires' => (
    is  => 'rw',
    isa => 'Int',
);

has 'flash' => (
    is  => 'rw',
    isa => 'Bool',
);

has 'data' => (
    is  => 'rw',
);

1;
=pod

=head1 NAME

Catalyst::Plugin::Session::Store::KiokuDB - Store sessions using KiokuDB

=head1 SYNOPSIS

    # In Catalyst
    use Catalyst qw/
                    Session
                    Session::State::Whatever
                    Session::Store::KiokuDB
                    /;
    
    # Configure it
    MyApp->config->{session}->{kiokuDir} = '/path/to/storage/dir';
    # or
    MyApp->config->{session}->{kiokuObject} = KiokuDB->new(...);

    # then use it as you would any session plugin

=head1 DESCRIPTION

This session storage module will store data using L<KiokuDB>. Aside from that
it does pretty much the very same things other session modules do.

=head1 CONFIGURATION

Under the C<session> key in your configuration parameters, you can use 
C<kiokuDir> which points to a directory in which KiokuDB will store its
data, C<kiokuObject> which allows you to reuse an existing KiokuDB instance
or C<kiokuModel> which points the name of a C<Catalyst> model that must be
of class L<Catalyst::Model::KiokuDB> (typically just 'kiokudb').

=head1 METHODS

These are the classic store methods from L<Catalyst::Plugin::Session::Store>.

=head2 get_session_data

=head2 store_session_data

=head2 delete_session_data

=head2 delete_expired_sessions

This one is currently a no-op.

=head2 setup_session

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Session>, L<Catalyst::Model::KiokuDB>,
L<KiokuX::Model>

=head1 MODULE HOME PAGE

L<http://github.com/mzedeler/Catalyst-Plugin-Session-Store-KiokuDB>.

If you find a bug, please fork the master branch from Github, write a test
case and push it to GitHub. After this, open an issue using Githubs issue
tracker.

=head1 MAINTAINER

Michael Zedeler, <michael@zedeler.dk>.

=head1 ORIGINAL AUTHOR

Robin Berjon, <robin@berjon.com>, L<http://robineko.com/>.

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
