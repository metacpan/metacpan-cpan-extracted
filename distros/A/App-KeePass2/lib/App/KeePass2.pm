#
# This file is part of App-KeePass2
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package App::KeePass2;

# ABSTRACT: KeePass2 commandline tools

use strict;
use warnings;

our $VERSION = '0.04';    # VERSION
use utf8::all;
use Moo;
with 'App::KeePass2::Icons';
use MooX::Options;
use File::KeePass;
use IO::Prompt;
use Carp;
use Data::Printer;
use feature 'say';

option 'file' => (
    doc      => 'Your keepass2 file',
    is       => 'ro',
    short    => 'f',
    required => 1,
    format   => 's',
);

option 'create' => (
    doc   => 'Create a keepass2 file',
    is    => 'ro',
    short => 'c',
);

option 'dump_groups' => (
    doc   => 'Dump the groups',
    is    => 'ro',
    short => 'd',
);

has _fkp => (
    is      => 'ro',
    default => sub {
        File::KeePass->new;
    }
);

option 'list_groups' => (
    doc   => 'List the groups',
    is    => 'ro',
    short => 'l',
);

sub run {
    my ($self) = @_;
    $self->_create,      return if ( $self->create );
    $self->_list_groups, return if ( $self->list_groups );
    $self->_dump_groups, return if ( $self->dump_groups );
    return;
}

sub _get_master_key {
    my ($self) = @_;
    return "" . prompt( "Master Password : ", -e => "*", -tty );
}

sub _get_confirm_key {
    my ($self) = @_;
    return "" . prompt( "Confirm Password : ", -e => "*", -tty );
}

sub _create {
    my ($self) = @_;
    croak "The file already exists !" if -f $self->file;
    $self->_fkp->clear;
    my $root = $self->_fkp->add_group(
        {   title => 'My Passwords',
            icon  => $self->get_icon_id_from_key('key')
        }
    );
    my $gid = $root->{'id'};
    $self->_fkp->add_group(
        {   title => 'Internet',
            group => $gid,
            icon  => $self->get_icon_id_from_key('internet')
        }
    );
    $self->_fkp->add_group(
        {   title => 'Private',
            group => $gid,
            icon  => $self->get_icon_id_from_key('key5')
        }
    );
    $self->_fkp->add_group(
        {   title => 'Bank',
            group => $gid,
            icon  => $self->get_icon_id_from_key('dollar')
        }
    );
    $self->_fkp->unlock if $self->_fkp->is_locked;
    my $master  = $self->_get_master_key;
    my $confirm = $self->_get_confirm_key;
    croak "Your master password is different from the confirm password !"
        if $master ne $confirm;
    $self->_fkp->save_db( $self->file, $master );
    return;
}

sub _dump_groups {
    my ($self) = @_;
    $self->_fkp->load_db( $self->file, $self->_get_master_key );
    p( $self->_fkp->groups );
    return;
}

sub _list_groups {
    my ($self) = @_;
    $self->_fkp->load_db( $self->file, $self->_get_master_key );
    $self->_display_groups( $self->_fkp->groups, 0 );
}

sub _display_groups {
    my ( $self, $groups, $level ) = @_;
    for my $group (@$groups) {
        my $key  = $self->get_icon_key_from_id( $group->{icon} );
        my $icon = $self->get_icon_char_from_key($key);
        say sprintf( "%s%-3s%s", "    " x $level, $icon, $group->{title} );
        $self->_display_groups( $group->{groups}, $level + 1 );
    }
}
1;

__END__

=pod

=head1 NAME

App::KeePass2 - KeePass2 commandline tools

=head1 VERSION

version 0.04

=head1 ATTRIBUTES

=head2 file

The password file

=head2 create

Create the keepass2 file

=head2 dump_groups

Dump the content of the groups

=head2 list_groups

List the groups with icon

=head1 METHODS

=head2 run

Start the cli app

  use App::KeePass2;
  my $keepass = App::KeePass2->new_with_options;
  $keepass->run;

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://tasks.celogeek.com/projects/app-keepass2/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
