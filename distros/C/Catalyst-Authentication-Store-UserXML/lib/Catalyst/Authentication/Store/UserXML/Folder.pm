package Catalyst::Authentication::Store::UserXML::Folder;

use strict;
use warnings;

our $VERSION = '0.03';

use Moose;
use Catalyst::Authentication::Store::UserXML::User;
use Path::Class 'file';

has 'folder'           => (is=>'rw', isa=>'Path::Class::Dir', required => 1);
has 'user_folder_file' => (is=>'rw', isa=>'Str', predicate => 'has_user_folder_file');

sub find_user {
    my ( $self, $authinfo, $c ) = @_;

    my $username = $authinfo->{username};
    my $file = (
        $self->has_user_folder_file
        ? file($self->folder, $username, $self->user_folder_file)
        : file($self->folder, $username.'.xml')
    );
    unless (-r $file) {
        if (my $fallback = $c->config->{authentication}{userxml}{find_user_fallback}) {
            return $c->$fallback($authinfo);
        }
        return undef;
    }

    my $user = Catalyst::Authentication::Store::UserXML::User->new({
        xml_filename => $file
    });

    die 'username in '.$file.' missmatch'
        if $user->username ne $username;

    return $user;
}

sub user_supports {
    my $self = shift;
    Catalyst::Authentication::Store::UserXML::User->supports(@_);
}

sub from_session {
	my ( $self, $c, $username ) = @_;
	$self->find_user( { username => $username }, $c );
}

1;

