# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 2020-2022 Best Practical Solutions, LLC
#                                          <sales@bestpractical.com>
#
# (Except where explicitly superseded by other copyright notices)
#
#
# LICENSE:
#
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
#
#
# CONTRIBUTION SUBMISSION POLICY:
#
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to Best Practical Solutions, LLC.)
#
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# Request Tracker, to Best Practical Solutions, LLC, you confirm that
# you are the copyright holder for those contributions and you grant
# Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
#
# END BPS TAGGED BLOCK }}}

package App::wsgetmail;

use Moo;

our $VERSION = '0.05';

=head1 NAME

App::wsgetmail - Fetch mail from the cloud using webservices

=head1 VERSION

0.05

=head1 SYNOPSIS

If you just want to run wsgetmail on the command line, the L<wsgetmail>
documentation page provides full documentation for how to configure and run
it, including how to configure the app in your cloud environment. Run:

    wsgetmail [options] --config=wsgetmail.json

where C<wsgetmail.json> looks like:

    {
    "client_id": "abcd1234-xxxx-xxxx-xxxx-1234abcdef99",
    "tenant_id": "abcd1234-xxxx-xxxx-xxxx-123abcde1234",
    "secret": "abcde1fghij2klmno3pqrst4uvwxy5~0",
    "global_access": 1,
    "username": "rt-comment@example.com",
    "folder": "Inbox",
    "command": "/opt/rt5/bin/rt-mailgate",
    "command_args": "--url=http://rt.example.com/ --queue=General --action=comment",
    "action_on_fetched": "mark_as_read"
    }

Using App::wsgetmail as a library looks like:

    my $getmail = App::wsgetmail->new({config => {
      # The config hashref takes all the same keys and values as the
      # command line tool configuration JSON.
    }});
    while (my $message = $getmail->get_next_message()) {
        $getmail->process_message($message)
          or warn "could not process $message->id";
    }

=head1 DESCRIPTION

wsgetmail retrieves mail from a folder available through a web services API
and delivers it to another system. Currently, it only knows how to retrieve
mail from the Microsoft Graph API, and deliver it by running another command
on the local system. It may grow to support other systems in the future.

=head1 INSTALLATION

    perl Makefile.PL
    make PERL_CANARY_STABILITY_NOPROMPT=1
    make test
    sudo make install

=cut

use Clone 'clone';
use Module::Load;
use App::wsgetmail::MDA;

=head1 ATTRIBUTES

=head2 config

A hash ref that is passed to construct the C<mda> and C<client> (see below).

=cut

has config => (
    is => 'ro',
    required => 1
);

=head2 mda

An instance of L<App::wsgetmail::MDA> created from our C<config> object.

=cut

has mda => (
    is => 'rw',
    lazy => 1,
    handles => [ qw(forward) ],
    builder => '_build_mda'
);

=head2 client_class

The name of the App::wsgetmail package used to construct the
C<client>. Default C<MS365>.

=cut

has client_class => (
    is => 'ro',
    default => sub { 'MS365' }
);

=head2 client

An instance of the C<client_class> created from our C<config> object.

=cut

has client => (
    is => 'ro',
    lazy => 1,
    handles => [ qw( get_next_message
                     get_message_mime_content
                     mark_message_as_read
                     delete_message) ],
    builder => '_build_client'
);


has _post_fetch_action => (
    is => 'ro',
    lazy => 1,
    builder => '_build__post_fetch_action'
);


sub _build__post_fetch_action {
    my $self = shift;
    my $fetched_action_method;
    my $action = $self->config->{action_on_fetched};
    return undef unless (defined $action);
    if (lc($action) eq 'mark_as_read') {
        $fetched_action_method = 'mark_message_as_read';
    } elsif ( lc($action) eq "delete" ) {
        $fetched_action_method = 'delete_message';
    } else {
        $fetched_action_method = undef;
        warn "no recognised action for fetched mail, mailbox not updated";
    }
    return $fetched_action_method;
}

=head1 METHODS

=head2 process_message($message)

Given a Message object, retrieves the full message content, delivers it
using the C<mda>, and then executes the configured post-fetch
action. Returns a boolean indicating success.

=cut

sub process_message {
    my ($self, $message) = @_;
    my $client = $self->client;
    my $filename = $client->get_message_mime_content($message->id);
    unless ($filename) {
        warn "failed to get mime content for message ". $message->id;
        return 0;
    }
    my $ok = $self->forward($message, $filename);
    if ($ok) {
        $ok = $self->post_fetch_action($message);
    }
    if ($self->config->{dump_messages}) {
        warn "dumped message in file $filename" if ($self->config->{debug});
    }
    else {
        unlink $filename or warn "couldn't delete message file $filename : $!";
    }
    return $ok;
}

=head2 post_fetch_action($message)

Given a Message object, executes the configured post-fetch action. Returns a
boolean indicating success.

=cut

sub post_fetch_action {
    my ($self, $message) = @_;
    my $method = $self->_post_fetch_action;
    my $ok = 1;
    # check for dry-run option
    if ($self->config->{dry_run}) {
        warn "dry run so not running $method action on fetched mail";
        return 1;
    }
    if ($method) {
        $ok = $self->$method($message->id);
    }
    return $ok;
}

###

sub _build_client {
    my $self = shift;
    my $classname = 'App::wsgetmail::' . $self->client_class;
    load $classname;
    my $config = clone $self->config;
    $config->{post_fetch_action} = $self->_post_fetch_action;
    return $classname->new($config);
}


sub _build_mda {
    my $self = shift;
    my $config = clone $self->config;
    if ( defined $self->config->{username}) {
        $config->{recipient} //= $self->config->{username};
    }
    return App::wsgetmail::MDA->new($config);
}

=head1 SEE ALSO

=over 4

=item * L<wsgetmail>

=item * L<App::wsgetmail::MDA>

=item * L<App::wsgetmail::MS365>

=item * L<App::wsgetmail::MS365::Message>

=back

=head1 AUTHOR

Best Practical Solutions, LLC <modules@bestpractical.com>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2015-2020 by Best Practical Solutions, LLC.

This is free software, licensed under:

The GNU General Public License, Version 2, June 1991

=cut

1;
