package Bot::BasicBot::Pluggable::Module::Notify;

use warnings;
use strict;

our $VERSION = '1.00';

#----------------------------------------------------------------------------

#############################################################################
# Library Modules                                                           #
#############################################################################

use base qw(Bot::BasicBot::Pluggable::Module);

use DateTime;
use IO::File;
use List::MoreUtils qw( any );
use MIME::Lite;

#############################################################################
# Variables                                                                 #
#############################################################################

my (%settings,%emails);
my $load_time = 0;

my %defaults = (
    smtp    => '',
    replyto => 'no-reply@example.com',
    from    => 'no-reply@example.com',
    active  => 15,
);
 
#----------------------------------------------------------------------------

#############################################################################
# Public Methods                                                            #
#############################################################################

sub init {
    my $self = shift;

    my $file = $self->store->get( 'notify', 'notifications' );
    unless($file) {
        $file = $0;
        $file =~ s/\.pl$/.csv/;
    }

    $self->store->set( 'notify', 'notifications', $file );
}
 
sub help {
    my $active = $settings{active} || $defaults{active};
    return "if you have been away for more than $active minutes, and someone posts a channel message, identifying you, this will email you the message.";
}
 
sub told {
    my ( $self, $mess ) = @_;
    my $body = $mess->{body};

    return 0    unless defined $body;
    return 0    unless($self->_load_notification_file());
    return 0    if($body =~ m!^\s*/?who(is|was)?\s+!); # ignore who requests

    my (@words) = split(/[^@\w\+\-]+/,$body);
    my $data = $self->bot->channel_data( $mess->{channel} );
    my %users = map { $_ => 0 } keys %$data; # get users in channel

    # get identities
    my $pocoirc = $self->bot->pocoirc( $mess->{channel} );
    my @nicks = $pocoirc->nicks();
    my %nicks = map { $_ => $pocoirc->nick_info($_) } @nicks;
    $self->{nicks} = \%nicks;

    my $sender = $self->_match_user($mess->{who}, $self->{nicks}) || '';
    my @recipients = grep { $_ ne $sender } keys %users;

    my $prev = '';
    for my $word (@words) {
        next    if($word =~ /(\-\-|\+\+)$/); # ignore karma messages
        next    if($prev eq 'seen');         # ignore seen messages
        $prev = $word;

        my $nick = '';
        if($word =~ /@?(\w+)/) {
            my $user = $1;
            $nick = $self->_match_user($user, $self->{nicks}) || '';
        }

        next if($nick && $users{$nick}); # don't send repeated mails

        if($word eq '@all') {
            $self->_send_email(1,$mess,@recipients);
            return 1; # we only send 1 email per user
        } elsif($word eq '@here') {
            my @users = []; # filter based on seen in the last hour
            $self->_send_email(2,$mess,@recipients);
            return 1; # we only send 1 email per user
        } elsif($nick && $emails{$nick}) {
            $self->_send_email(1,$mess,$nick);
            $users{$nick} = 1; # we only send 1 email per user
            @recipients = grep { $_ ne $nick } @recipients; # don't send repeated mails
        }
    }
    
    return 1 if(any { $_ == 1 } values %users);
    return 0;
}

#############################################################################
# Private Methods                                                           #
#############################################################################

sub _send_email {
    my ($self,$type,$mess,@users) = @_;

    my $subject = sprintf "IRC: %s sent you a message",
        $mess->{who};
    my $body = sprintf "Hi,\n\n%s sent the following message in channel %s at %s %s:\n\n%s\n\n",
        $mess->{who},
        $mess->{channel},
        DateTime->now->ymd, DateTime->now->hms,
        $mess->{body};

    my $data = $self->bot->channel_data( $mess->{channel} );
    my %channel = map { $_ => 1 } keys %$data; # get users in channel

    for my $user (@users) {
        my $nick = $self->_match_user($user, $self->{nicks});
        next unless($nick);

        # if user is in channel, they must be inactive for at least 15 minues
        # if the user is not in the channel, send them an email, even if they
        # were recently active, as they have likely just left.

        if($channel{$user}) {
            my $seen = $self->store->get( 'Seen', "seen_$user");
            if($seen && $seen->{'time'}) {
                my $time = time - $seen->{'time'};
                next if($time < $settings{active} * 60);
                next if($time > 3600 && $type == 2);
            }
        }

        $self->_sendmail(
            to      => $emails{$nick}{email},
            subject => $subject,
            body    => $body
        );
    }
}

sub _load_notification_file {
    my $self = shift;

    my $fn = $self->store->get( 'notify', 'notifications' ) or return 0;
    return 0 unless(-r $fn); # file must be readable

    my $mod = (stat($fn))[9];
    return 1 if($mod <= $load_time && keys %emails); # don't reload if not modified

    my $fh = IO::File->new($fn,'r') or return 0;
    (%settings,%emails) = ();
    while(<$fh>) {
        s/\s+$//;
        next if(/^#/ || /^$/);
        my ($nick,$ident,$email) = split(/,/,$_,3);
        
        if($nick eq 'CONFIG') {
            $settings{$ident} = $email;
            next;
        }

        $emails{$nick}{email} = $email;
        $emails{$nick}{ident} = $ident if($ident);
    }

    $fh->close;
    $load_time = $mod;

    for my $key (keys %defaults) {
        $settings{$key} ||= $defaults{$key};
    }

    return 0    unless($settings{smtp});
    return 1    if(keys %emails);
    return 0;
}

sub _match_user {
    my ($self,$user,$nicks) = @_;

    # matches a known user
    return $user if($emails{$user});

    # see if idents match
    for my $ident (keys %emails) {
        next    unless($emails{$ident}{ident});

        for my $nick (keys %$nicks) {
            next    unless($user eq $nick);

            return $ident if($nicks->{$nick}->{Real}      =~ /\Q$emails{$ident}{ident}\E/);
            return $ident if($nicks->{$nick}->{User}      =~ /\Q$emails{$ident}{ident}\E/);
            return $ident if($nicks->{$nick}->{Userhost}  =~ /\Q$emails{$ident}{ident}\E/);
        }
    }

    return;
}

sub _sendmail {
    my ($self,%hash) = @_;

    MIME::Lite->send('smtp', $settings{smtp}, Timeout=>60);

    my $mail = MIME::Lite->new(
        'Reply-To'  => $settings{replyto},
        'From'      => $settings{from},

        'Subject'   => $hash{subject},
        'To'        => $hash{to},
        'Data'      => $hash{body}
    );

    eval { $mail->send };
    if($@) {
        print "MailError: eval=[$@]\n";
        return;
    }

    return 1;
}

 
1;
 
__END__

#----------------------------------------------------------------------------

=head1 NAME
 
Bot::BasicBot::Pluggable::Module::Notify - runs a IRC offline notification service
 
=head1 DESCRIPTION

When you have been away from IRC for more than 15 minutes, and someone posts a 
message mentioning you, this module will detect this, and send you a short 
email notification, detailing the sendee, the message, the channel and the time
sent. 

In addition to specific user mentions, the abillity to send to @here (active in
the last hour, but not in the last 15 minutes) or @all (all connected users, 
but not active in the last 15 minutes)

These latter two special cases are shortcuts to enable urgent or group wide 
messages to reach their intended recipients. 

Only users which have email addresses in the notification configuration file 
are alerted.

If a user leaves the channel within the minimum activity period (defaul 15 
minutes), and they are explicitly mentioned in the message, they are also 
notified.

=head1 SYNOPSIS

    my $bot = Bot::BasicBot::Pluggable->new(
        ... # various settings
    }; 

    $bot->store->set( 'notify', 'notifications', '/path/to/my/configuration.csv' },
    $bot->load('Seen');     # must be loaded to use Noify effectively
    $bot->load('Notify');

=head1 METHODS
 
=over 4
 
=item told()
 
Loads the email notification file, if not previously done so, and checks 
whether a channel user, @here or @all has been used. Sends the email to all
appropriately listed email recipients.

Note that a change to the notification file, will force a reload of the file on
the next invocation. As such, note that there may be a delay before you see the
next updated entry actioned.

Please also note that we try to avoid 'seen' and 'karma' requests, but the odd
one may slip through.

returns 1 if any mails were sent, 0 otherwise.

=back
 
=head1 VARS
 
=over 4
 
=item 'notifications'
 
Path to the notification file.
 
The notification file is assumed to be either based on the calling script, or a
designated file. If based on the calling script, if your script was mybot.pl, 
the notification file would default to mybot.csv.

If you wish to designate another filename or path, you may do this via the 
variable storage when the bot is initiated. For example:

    my $bot = Bot::BasicBot::Pluggable->new(
        ... # various settings
    }; 

    $bot->store->set( 'notify', 'notifications', '/path/to/my/configuration.csv' },
 
=back

=head1 CONFIGURATION FILE

The notifications file is a comma separated file, with blank lines and lines 
beginnning with a '#' symbol ignored.

Each line in the file should consist of 3 fields. The first being the 'nick', 
the second being the ident of the account connection, and the third being the 
email address to send mail to.

The connection ident is optional, and only used as a backup check in the event 
that the user may be roaming and their nick may be automatically switched to 
something like '_barbie' instead of 'barbie'. An connection ident is used 
within a regex pattern, but should not be a regex itself. Any regex characters
will be treated as literal string characters.

An example file might look like:

  barbie,missbarbell,barbie@cpan.org
  someone,,someone@example.com

Becareful using the ident, as this may pick up unwanted messages for other 
similarly named users.

In addition to the emails, there are several Email sending configuration lines.
Some optional, others are mandatory. These are designated using the 'CONFIG'
key. These are:

  CONFIG,smtp,smtp.example.com
  CONFIG,replyto,no-reply@example.com
  CONFIG,from,no-reply@example.com

A value for 'smtp' is mandatory, while the others are optional.

=head1 TODO

=over 4

=item * enable / disable notifications

A user should be able to enable or disable notifications for themselves. This 
would require a writeable config file, so that this can be stored permanently.

Should also look at enabling / disabling notifications on a per channel basis.

=item * user attributed email

A user should be able to add themselves to the notification list.

=item * user specified time default

Should be able to allow a user to set their own active wait time.

=back
 
=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2015-2019 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
