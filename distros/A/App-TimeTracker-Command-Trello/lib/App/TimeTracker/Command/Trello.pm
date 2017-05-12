package App::TimeTracker::Command::Trello;
use strict;
use warnings;
use 5.010;

# ABSTRACT: App::TimeTracker Trello plugin
use App::TimeTracker::Utils qw(error_message warning_message);

our $VERSION = "1.005";

use Moose::Role;
use WWW::Trello::Lite;
use JSON::XS qw(encode_json decode_json);
use Path::Class;

has 'trello' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'Trello card id',
    predicate     => 'has_trello'
);

has 'trello_client' => (
    is         => 'rw',
    isa        => 'Maybe[WWW::Trello::Lite]',
    lazy_build => 1,
    traits     => ['NoGetopt'],
);

has 'trello_card' => (
    is         => 'ro',
    lazy_build => 1,
    traits     => ['NoGetopt'],
    predicate  => 'has_trello_card'
);

sub _build_trello_card {
    my ($self) = @_;

    return unless $self->has_trello;
    return $self->_trello_fetch_card( $self->trello );
}

sub _build_trello_client {
    my $self   = shift;
    my $config = $self->config->{trello};

    unless ( $config->{key} && $config->{token} ) {
        error_message(
            "Please configure Trello in your TimeTracker config or run 'tracker setup_trello'"
        );
        return;
    }
    return WWW::Trello::Lite->new(
        key   => $self->config->{trello}{key},
        token => $self->config->{trello}{token},
    );
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my %args = @_;
    if ( $args{trello} && $args{trello} =~ /^https/ ) {
        $args{trello} =~ m|https://trello.com/c/([^/]+)/?|;
        $args{trello} = $1;
    }
    return $class->$orig(%args);
};

after '_load_attribs_stop' => sub {
    my ( $class, $meta ) = @_;

    $meta->add_attribute(
        'move_to' => {
            isa           => 'Str',
            is            => 'ro',
            documentation => 'Move Card to ...',
        }
    );
};

before [ 'cmd_start', 'cmd_continue', 'cmd_append' ] => sub {
    my $self = shift;
    return unless $self->has_trello;

    my $cardname = 'trello:' . $self->trello;
    $self->insert_tag($cardname);

    my $name;
    my $card = $self->trello_card;
    return unless $card;

    if ( $self->config->{trello}{listname_as_tag} ) {
        $self->_tag_listname($card);
    }

    $name = $self->_trello_just_the_name($card);
    if ( defined $self->description ) {
        $self->description( $self->description . ' ' . $name );
    }
    else {
        $self->description($name);
    }

    if ( $self->meta->does_role('App::TimeTracker::Command::Git') ) {
        my $branch = $self->trello;
        if ($name) {
            $branch = $self->safe_branch_name($name) . '_' . $branch;
        }
        $self->branch( lc($branch) ) unless $self->branch;
    }
};

after [ 'cmd_start', 'cmd_continue', 'cmd_append' ] => sub {
    my $self = shift;
    return unless $self->has_trello_card;

    my $card = $self->trello_card;
    return unless $card;

    if ( my $lists = $self->_trello_fetch_lists ) {
        if ( $lists->{doing} ) {
            if (  !$card->{idList}
                || $card->{idList} ne $lists->{doing}->{id} ) {
                $self->_do_trello(
                    'put',
                    'cards/' . $card->{id} . '/idList',
                    { value => $lists->{doing}->{id} }
                );
            }
        }
    }

    if ( my $member_id = $self->config->{trello}{member_id} ) {
        unless ( grep { $_ eq $member_id } @{ $card->{idMembers} } ) {
            my $members = $card->{idMembers};
            push( @$members, $member_id );
            $self->_do_trello(
                'put',
                'cards/' . $card->{id} . '/idMembers',
                { value => join( ',', @$members ) }
            );
        }
    }
};

after 'cmd_stop' => sub {
    my $self = shift;

    my $task = $self->_previous_task;
    return unless $task;

    my $oldid = $task->trello_card_id;
    return unless $oldid;

    my $task_rounded_minutes = $task->rounded_minutes;

    my $card = $self->_trello_fetch_card($oldid);
    unless ($card) {
        warning_message(
            "Last task did not contain a trello id, not updating time etc.");
        return;
    }

    my $name = $card->{name};
    my %update;

    if (    $self->config->{trello}{update_time_worked}
        and $task_rounded_minutes ) {
        if ( $name =~ /\[w:(\d+)m\]/ ) {
            my $new_worked = $1 + $task_rounded_minutes;
            $name =~ s/\[w:\d+m\]/'[w:'.$new_worked.'m]'/e;
        }
        else {
            $name .= ' [w:' . $task_rounded_minutes . 'm]';
        }
        $update{name} = $name;
    }

    if ( $self->can('move_to') ) {
        if ( my $move_to = $self->move_to ) {
            if ( my $lists = $self->_trello_fetch_lists ) {
                if ( $lists->{$move_to} ) {
                    $update{idList} = $lists->{$move_to}->{id};
                    $update{pos}    = 'top';
                }
                else {
                    warning_message("Could not find list >$move_to<");
                }
            }
            else {
                warning_message("Could not load lists");
            }
        }
    }

    return unless keys %update;

    $self->_do_trello( 'put', 'cards/' . $card->{id}, \%update );
};

sub _load_attribs_setup_trello {
    my ( $class, $meta ) = @_;

    $meta->add_attribute(
        'token_expiry' => {
            isa => 'Str',
            is  => 'ro',
            documentation =>
                'Trello token expiry [1hour, 1day, 30days, never]',
            default => '1day',
        }
    );
}

sub cmd_setup_trello {
    my $self = shift;

    my $conf = $self->config->{trello};
    my %global;
    my %local;
    if ( $conf->{key} ) {
        say "Trello Key is already set.";
    }
    else {
        say
            "Please open this URL in your favourite browser, and paste the Key:\nhttps://trello.com/1/appKey/generate";
        my $key = <STDIN>;
        $key =~ s/\s+//;
        $conf->{key} = $global{key} = $key;
        print "\n";
    }

    if ( $conf->{token} ) {
        my $token_info =
            $self->trello_client->get( 'tokens/' . $conf->{token} )->data;
        if ( $token_info->{dateExpires} ) {
            say "Token valid until: " . $token_info->{dateExpires};
        }
        else {
            say "Token no longer valid";
            delete $conf->{token};
        }
    }
    unless ( $conf->{token} ) {
        my $get_token_url =
              'https://trello.com/1/authorize?key='
            . $conf->{key}
            . '&name=App::TimeTracker&expiration='
            . $self->token_expiry
            . '&response_type=token&scope=read,write';
        say
            "Please open this URL in your favourite browser, click 'Allow', and paste the token:\n$get_token_url";

        my $token = <STDIN>;
        $token =~ s/\s+//;
        $conf->{token} = $global{token} = $token;

        if ( $self->trello_client ) {
            $self->trello_client->token($token);
        }
        else {
            $self->config->{trello} = $conf;
            $self->trello_client( $self->_build_trello_client );
        }
        print "\n";
    }
    $self->config->{trello} = $conf;

    if ( $conf->{member_id} ) {
        say "member_id is already set.";
    }
    else {
        $conf->{member_id} = $global{member_id} =
            $self->_do_trello( 'get', 'members/me' )->{id};
        say "Your member_id is " . $conf->{member_id};
        print "\n";
    }

    if ( $conf->{board_id} ) {
        say "board_id is already set.";
    }
    unless ( $conf->{board_id} ) {
        print "Do you want to set a Board? [y/N] ";
        my $in = <STDIN>;
        $in =~ s/\s+//;
        if ( $in =~ /^y/i ) {
            say "Your Boards:";
            my $boards = $self->_do_trello( 'get',
                'members/' . $conf->{member_id} . '/boards' );
            my $cnt = 1;
            foreach (@$boards) {
                printf( "%i: %s\n", $cnt, $_->{name} );
                $cnt++;
            }
            print "Your selection (number or nothing to skip): ";
            my $in = <STDIN>;
            $in =~ s/\D//;
            if ($in) {
                $conf->{board_id} = $local{board_id} =
                    $boards->[ $in - 1 ]->{id};
            }
        }
    }

    if ( keys %global ) {
        $self->_trello_update_config( \%global,
            $self->config->{_used_config_files}->[-1], 'global' );
    }
    if ( keys %local ) {
        $self->_trello_update_config( \%local,
            $self->config->{_used_config_files}->[0], 'local' );
    }
}

sub _do_trello {
    my ( $self, $method, $endpoint, @args ) = @_;
    my $client = $self->trello_client;
    exit 1 unless $client;

    my $res = $client->$method( $endpoint, @args );
    if ( $res->failed ) {
        error_message(
            "Cannot talk to Trello API: " . $res->error . ' ' . $res->code );
        if ( $res->code == 401 ) {
            say "Maybe running 'tracker setup_trello' will help...";
        }
        exit 1;
    }
    else {
        return $res->data;
    }
}

sub _trello_update_config {
    my ( $self, $update, $file, $type ) = @_;

    print "I will store the following keys\n\t"
        . join( ', ', sort keys %$update )
        . "\nin your $type config file\n$file\n";
    print "(Y|n): ";
    my $in = <STDIN>;
    $in =~ s/\s+//;
    unless ( $in =~ /^n/i ) {
        my $f   = file($file);
        my $old = JSON::XS->new->utf8->relaxed->decode(
            scalar $f->slurp( iomode => '<:encoding(UTF-8)' ) );
        while ( my ( $k, $v ) = each %$update ) {
            $old->{trello}{$k} = $v;
        }
        $f->spew(
            iomode => '>:encoding(UTF-8)',
            JSON::XS->new->utf8->pretty->encode($old)
        );
    }
}

sub _trello_fetch_card {
    my ( $self, $trello_tag ) = @_;

    my %search = (
        query       => $trello_tag,
        card_fields => 'shortLink',
        modelTypes  => 'cards'
    );
    if ( my $board_id = $self->config->{trello}{board_id} ) {
        $search{idBoards} = $board_id;
    }

    my $result = $self->_do_trello( 'get', 'search', \%search );
    my $cards = $result->{cards};
    unless ( @$cards == 1 ) {
        warning_message(
            "Could not identify trello card via '" . $trello_tag . "'" );
        return;
    }
    my $id = $cards->[0]{id};
    my $card = $self->_do_trello( 'get', 'cards/' . $id );
    return $card;
}

sub _trello_fetch_lists {
    my $self     = shift;
    my $board_id = $self->config->{trello}{board_id};
    return unless $board_id;
    my $rv = $self->_do_trello( 'get', 'boards/' . $board_id . '/lists' );

    my %lists;
    my $map = $self->config->{trello}{list_map}
        || {
        'To Do' => 'todo',
        'Doing' => 'doing',
        'Done'  => 'done',
        };
    foreach my $list (@$rv) {
        next unless my $tracker_name = $map->{ $list->{name} };
        $lists{$tracker_name} = $list;
    }
    return \%lists;
}

sub _trello_just_the_name {
    my ( $self, $card ) = @_;
    my $name = $card->{name};
    my $tr   = $self->trello;
    $name =~ s/$tr:\s?//;
    $name =~ s/\[(.*?)\]//g;
    $name =~ s/\s+/_/g;
    $name =~ s/_$//;
    $name =~ s/^_//;
    return $name;
}

sub _tag_listname {
    my ( $self, $card ) = @_;

    my $list_id = $card->{idList};
    return unless $list_id;
    my $rv = $self->_do_trello( 'get', 'lists/' . $list_id . '/name' );
    my $name = $rv->{_value};
    $self->insert_tag($name) if $name;
}

sub App::TimeTracker::Data::Task::trello_card_id {
    my $self = shift;
    foreach my $tag ( @{ $self->tags } ) {
        next unless $tag =~ /^trello:(\w+)/;
        return $1;
    }
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TimeTracker::Command::Trello - App::TimeTracker Trello plugin

=head1 VERSION

version 1.005

=head1 DESCRIPTION

This plugin takes a lot of hassle out of working with Trello
L<http://trello.com/>.

Using the Trello plugin, tracker can fetch the name of a Card and use
it as the task's description; generate a nicely named C<git> branch
(if you're also using the C<Git> plugin); add the user as a member to
the Card; move the card to various lists; and use some hackish
extension to the Card name to store the time-worked in the Card.

=head1 CONFIGURATION

=head2 plugins

Add C<Trello> to the list of plugins.

=head2 trello

add a hash named C<trello>, containing the following keys:

=head3 key [REQUIRED]

Your Trello Developer Key. Get it from
L<https://trello.com/1/appKey/generate> or via C<tracker
setup_trello>.

=head3 token [REQUIRED]

Your access token. Get it from
L<https://trello.com/1/authorize?key=YOUR_DEV_KEY&name=tracker&expiration=1day&response_type=token&scope=read,write>.
You maybe want to set a longer expiration timeframe.

You can also get it via C<tracker setup_trello>.

=head3 board_id [SORT OF REQUIRED]

The C<board_id> of the board you want to use.

Not stictly necessary, as we use ids to identify cards.

If you specify the C<board_id>, C<tracker> will only search in this board.

You can get the C<board_id> by going to "Share, print and export" in
the sidebar menu, click "Export JSON" and then find the C<id> in the
toplevel hash. Or run C<tracker setup_trello>.

=head3 member_id

Your trello C<member_id>.

Needed for adding you to a Card's list of members. Currently a bit
hard to get from trello, so use C<tracker setup_trello>.

=head3 update_time_worked

If set to true, updates the time worked on this task on the Trello Card.

As Trello does not provide time-tracking (yet?), we store the
time-worked in some simple markup in the Card name:

  Callibrate FluxCompensator [w:32m]

C<[w:32m]> means that you worked 32 minutes on the task.

Context: stopish commands

=head3 listname_as_tag

If set to true, will fetch the name of the list the current card
belongs to and store the name as an additional tag.

Context: startish commands

=head1 NEW COMMANDS

=head2 setup_trello

    ~/perl/Your-Project$ tracker setup_trello

This will launch an interactive process that walks you throught the setup.

Depending on your config, you will be pointed to URLs to get your
C<key>, C<token> and C<member_id>. You can also set up a C<board_id>.
The data will be stored in your global / local config.

You will need a web browser to access the URLs on trello.com.

=head3 --token_expiry [1hour, 1day, 30days, never]

Token expiry time when a new token is requested from trello. Defaults
to '1day'.

'never' is the most comfortable option, but of course also the most
insecure.

Please note that you can always invalidate tokens via trello.com (go
to Settings/Applications)

=head1 CHANGES TO OTHER COMMANDS

=head2 start, continue

=head3 --trello

    ~/perl/Your-Project$ tracker start --trello s1d7prUx

    ~/perl/Your-Project$ tracker start --trello https://trello.com/c/s1d7prUx/card-title

If C<--trello> is set and we can find a card with this id:

=over

=item * set or append the Card name in the task description ("Rev up FluxCompensator!!")

=item * add the Card id to the tasks tags ("trello:s1d7prUx")

=item * if C<Git> is also used, determine a save branch name from the Card name, and change into this branch ("rev_up_fluxcompensator_s1d7prUx")

=item * add member to list of members (if C<member_id> is set in config)

=item * move to C<Doing> list (if there is such a list, or another list is defined in C<list_map> in config)

=back

<C--trello> can either be the full URL of the card, or just the card
id. If you don't have access to the URL, click the 'Share and more'
link (rather hard to find in the bottom right corner of a card).

If C<listname_as_tag> is set, will store the name of the card's list as a tag.

=head2 stop

=over

=item * If <update_time_worked> is set in config, adds the time worked on this task to the Card.

=back

=head3 --move_to

If --move_to is specified and a matching list is found in C<list_map> in config, move the Card to this list.

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
