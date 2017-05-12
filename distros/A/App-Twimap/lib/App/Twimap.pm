package App::Twimap;
use Moose;
use Algorithm::TokenBucket;
use App::Twimap::Tweet;
use Email::MIME;
use Email::MIME::Creator;
use Encode;
use List::Util qw(max);
use LWP::UserAgent;
use Web::oEmbed::Common;
use Time::HiRes;
use TryCatch;
use URI::WithBase;
has 'mail_imapclient' =>
    ( is => 'ro', isa => 'Mail::IMAPClient', required => 1 );
has 'net_twitter' => ( is => 'ro', isa => 'Net::Twitter', required => 1 );
has 'mailbox'     => ( is => 'ro', isa => 'Str',          required => 1 );
our $VERSION = '0.03';

sub imap_tids {
    my $self    = shift;
    my $imap    = $self->mail_imapclient;
    my $mailbox = $self->mailbox;

    warn "Fetching message_ids...";

    $self->select_mailbox;

    my $message_ids
        = $imap->fetch_hash('BODY.PEEK[HEADER.FIELDS (Message-Id)]')
        or die "Fetch hash $mailbox error: ", $imap->LastError;

    my %tids;

    foreach my $uid ( keys %$message_ids ) {
        my $message_id
            = $message_ids->{$uid}->{'BODY[HEADER.FIELDS (MESSAGE-ID)]'};
        my ($tid) = $message_id =~ /Message-Id: <(\d+)\@twitter>/;
        next unless $tid;
        $tids{$tid} = 1;
    }
    return \%tids;
}

sub sync_home_timeline {
    my $self    = shift;
    my $twitter = $self->net_twitter;
    my $tids    = $self->imap_tids;

    my $bucket = new Algorithm::TokenBucket 15 / (15 * 60), 1;

    my $since_id = max( keys %$tids );
    my $max_id   = 0;
    while (1) {
        warn
            "Fetching home timeline since id $since_id and max_id $max_id...";
        my $new_tweets = 0;
        my $conf       = {
            count            => 200,
            include_entities => 1,
        };
        $conf->{since_id} = $since_id if $since_id;
        $conf->{max_id}   = $max_id   if $max_id;
        my $tweets = $twitter->home_timeline($conf);

        foreach my $data (@$tweets) {
            my $tweet = App::Twimap::Tweet->new( data => $data );
            my $tid = $tweet->id;

            $max_id = $tid unless $max_id;
            $max_id = $tid if $tid < $max_id;

            next if $tids->{$tid};
            $new_tweets++;

            my $email = $tweet->to_email;
            $self->append_email($email);
            $tids->{$tid} = 1;
        }
        last unless $new_tweets;
        warn "sleeping...";
        Time::HiRes::sleep $bucket->until(1);
        $bucket->count(1);
    }
}

sub sync_replies {
    my $self    = shift;
    my $twitter = $self->net_twitter;
    my $imap    = $self->mail_imapclient;
    my $mailbox = $self->mailbox;
    my $tids    = $self->imap_tids;

    warn "Fetching in_reply_tos...";

    $self->select_mailbox;

    my @todo;
    my $replies = $imap->fetch_hash('BODY.PEEK[HEADER.FIELDS (IN-REPLY-TO)]')
        or die "Fetch hash $mailbox error: ", $imap->LastError;
    foreach my $uid ( keys %$replies ) {
        my $header = $replies->{$uid}->{'BODY[HEADER.FIELDS (IN-REPLY-TO)]'};
        my ($tid) = $header =~ /In-Reply-To: <(\d+)\@twitter>/;
        next unless $tid;
        push @todo, $tid;
    }

    my $bucket = new Algorithm::TokenBucket 180 / (15 * 60), 1;

    foreach my $tid (@todo) {
        next if $tids->{$tid};
        warn "sleeping...";
        Time::HiRes::sleep $bucket->until(1);
        $bucket->count(1);
        warn "fetching $tid...";
        my $data;
        try {
            $data = $twitter->show_status( $tid, { include_entities => 1 } );
        }
        catch($err) {
            warn $err;
            next;
        };
        my $tweet = App::Twimap::Tweet->new( data => $data );
        push @todo, $tweet->in_reply_to_status_id
            if $tweet->in_reply_to_status_id;
        my $email = $tweet->to_email;
        $self->append_email($email);
        $tids->{$tid} = 1;
    }
}

sub append_email {
    my ( $self, $email ) = @_;
    my $imap    = $self->mail_imapclient;
    my $mailbox = $self->mailbox;

    my $uid
        = $imap->append_string( $mailbox, encode_utf8( $email->as_string ) )
        or die "Could not append_string to $mailbox: ", $imap->LastError;
}

sub select_mailbox {
    my $self    = shift;
    my $imap    = $self->mail_imapclient;
    my $mailbox = $self->mailbox;
    $imap->select($mailbox)
        or die "Select $mailbox error: ", $imap->LastError;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

App::Twimap - Push your Twitter home timeline to an IMAP server

=head1 SYNOPSIS

  $ twimap twimap.conf

=head1 DESCRIPTION

Twitter is an online social networking and microblogging service. The Internet
Message Access Protocol (IMAP) is an Internet standard protocols for e-mail
retrieval from a server. This module stores your Twitter home timeline in a
folder on an IMAP server.

Why would you do this?

=over 4

=item * Offline access to your Twitter home timeline

=item * Your email client can do message threading

=item * Use multiple devices and they sync read messages

=item * URLs are expanded

=item * Images and videos are embedded via oEmbed

=back

To use this application you need to create a Twitter API application on:

  https://dev.twitter.com/apps/new

You need to use the examples/oauth_desktop.pl application distributed
with Net::Twitter to obtain the OAuth tokens. First replace the consumer
tokens with those of your application, then run the application and see
oauth_desktop.dat.

Create a twimap.conf (an example is shipped with this distribution)
with the IMAP server details and Twitter access details.

... and now you can run the application as in the synopsis.

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2011, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
