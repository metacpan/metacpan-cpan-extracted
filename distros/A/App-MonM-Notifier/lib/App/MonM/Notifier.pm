package App::MonM::Notifier; # $Id: Notifier.pm 66 2019-07-16 04:27:38Z abalama $
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Notifier - extension for the monm notifications

=head1 VERSION

Version 1.03

=head1 SYNOPSIS

    # monotifier < /path/to/message/file.txt
    # monotifier show
    # monotifier show <ID>
    # monotifier remove <ID>
    # monotifier clean
    # monotifier truncate

=head1 DESCRIPTION

This is an extension for the monm notifications over different
communication channels

=head1 CONFIGURATION

  <Notifier>

    #
    # !!! WARNING !!!
    #
    # Before using the third-party database, please create the monotifier table
    #

    #-- For SQLite DB
    #CREATE TABLE IF NOT EXISTS `monotifier` (
    #  `id` int(11) NOT NULL COMMENT 'ID',
    #  `to` char(255) DEFAULT NULL COMMENT 'Recipient name',
    #  `channel` char(255) DEFAULT NULL COMMENT 'Recipient channel',
    #  `subject` text COMMENT 'Message subject',
    #  `message` text COMMENT 'Message content',
    #  `pubdate` int(11) DEFAULT NULL COMMENT 'Date (unixtime) of the publication',
    #  `expires` int(11) DEFAULT NULL COMMENT 'Date (unixtime) of the expire',
    #  `status` char(32) DEFAULT NULL COMMENT 'Status of transaction',
    #  `comment` char(255) DEFAULT NULL COMMENT 'Comment',
    #  `errcode` int(11) DEFAULT NULL COMMENT 'Error code',
    #  `errmsg` text COMMENT 'Error message',
    #  PRIMARY KEY (`id`),
    #  KEY `I_ID` (`id`)
    #) ENGINE=MyISAM DEFAULT CHARSET=utf8

    # SQLite example:
    #<DBI>
    #    DSN "dbi:SQLite:dbname=/tmp/monm/monotifier.db"
    #    Set RaiseError     0
    #    Set PrintError     0
    #    Set sqlite_unicode 1
    #</DBI>

    # MySQL example:
    #<DBI>
    #    DSN "DBI:mysql:database=monotifier;host=mysql.example.com"
    #    User username
    #    Password password
    #    Set RaiseError          0
    #    Set PrintError          0
    #    Set mysql_enable_utf8   1
    #</DBI>

    # Expires and timeout values
    Expires +1M
    Timeout 300

  </Notifier>

  # User configuration
  <User "foo">
    Period  7:00-23:00

    <Channel MyEmail>
        Type    Email
        To      test@example.com
    </Channel>

    <Channel MySMS>
        Type    Command
        Period  8:00-22:00
        To      +1 123 458 7789
        Command monotifiersms.pl
    </Channel>
  </User>

=head2 EXAMPLE

  <User "test">
    # Global period (default for all channels)
    Period  7:00-21:00

    # Email via SMTP
    <Channel MyEmail>
        Type    Email

        # Real To and From
        To      test@example.com
        From    root@example.com

        # Options
        #Encoding base64

        # Headers
        <Headers>
            X-Foo foo
            X-Bar bar
        </Headers>

        # SMTP options
        # If there are requirements to the register of parameter
        # names, use the Set directive, for example:
        # By default will use <SendMail> section of general config file
        Set host 192.168.0.1
        #Set port 25
        #Set sasl_username TeStUser
        #Set sasl_password MyPassword

        # Local period (default for this channel only)
        Period  7:30-16:30

        # Calendar settings for this channel
        # Sun Mon Tue Wed Thu Fri Sat
        #  ... or:
        # Sunday Monday Tuesday Wednesday Thursday Friday Saturday
        Sun - # disable!
        Mon 7:35-17:45
        Tue 15-19
        Wed -
        Thu 16-18:01
        Fri 18:01-19
        Sat -

    </Channel>

    # Simple Email example
    <Channel TinyEmail>
        # Using <SendMail> section
        Type    Email
        To      test@example.com
    </Channel>

    # Save to file by mask
    <Channel MyFile>
        Type    File

        # Real To and From
        To      testuser
        From    root

        # Options
        #Encoding base64

        # Headers
        <Headers>
            X-Mailer foo
        </Headers>

        #Dir      /path/to/messages/dir
        #File     [TO]_[DATETIME]_[ID].[EXT]

        Period  10:00-23:00
        #Thu     7:45-14:25
        #Sun -
        #Fri     0:0-1:0

    </Channel>

    # Send serialized message to STDIN of external program
    <Channel MyCommand>
        Type    Command

        # Real To and From
        To      testuser
        From    root

        # Options
        #Encoding base64

        <Headers>
            X-Foo foo
            X-Bar bar
        </Headers>

        Command "grep MIME > t.msg"

        Period  00:00-23:59

    </Channel>

  </User>

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>, L<App::MonM>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.03';

use feature qw/say/;

use Encode;
use Encode::Locale;
use Carp;

use Text::SimpleTable;

use App::MonM::Const;
use App::MonM::Util qw/ explain /;

use App::MonM::Notifier::Const;
use App::MonM::Notifier::Agent;

use base qw/ CTK::App /;

use constant {
    ROWS_LIMIT => 1000,
    TABLE_INFO  => [(
        [12, 'NAME'],
        [68, 'VALUE'],
    )],
    TABLE_ALL => [(
        [5, 'ID'],
        [20, 'TO'],
        [20, 'CHANNEL'],
        [32, 'SUBJECT'],
        [8, 'STATUS'],
        [3, 'ERR'],
    )],
};

__PACKAGE__->register_handler(
    handler     => "create",
    description => "Create message",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    my $toa = $self->option("username");
    my $sbj = decode( locale => $self->option("subject") ) // '';
    my $msg = (-t STDIN) ? '' : decode( locale => scalar(do { local $/; <STDIN> }) ) // '';
    unless (length($msg)) {
        $self->error("No message");
        return 0;
    }

    # Create agent instance
    my $agent = new App::MonM::Notifier::Agent(
        config => $self->configobj, # Config object
        users  => $toa, # undef or []
    );
    unless ($agent->status) {
        $self->error($agent->error);
        return 0;
    }

    # Create message
    $agent->create(
        #to => "test", # For example!
        subject => $sbj,
        message => $msg,
    ) or do {
        $self->error($agent->error);
        return 0;
    };

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "send",
    description => "Send created messages",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;

    # Create agent instance
    my $agent = new App::MonM::Notifier::Agent(
        config => $self->configobj, # Config object
        users  => $self->option("username"),
    );
    unless ($agent->status) {
        $self->error($agent->error);
        return 0;
    }

    # Send messages
    $agent->trysend() or do {
        $self->error($agent->error);
        return 0;
    };

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "remove",
    description => "Remove message by id",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    my $id = shift(@arguments) || 0;
    unless ($id) {
        $self->error("Incorrect id");
        return 0;
    }

    # Create agent instance
    my $agent = new App::MonM::Notifier::Agent(
        config => $self->configobj, # Config object
    );
    unless ($agent->status) {
        $self->error($agent->error);
        return 0;
    }

    # Remove messages
    my $store = $agent->store;
    $store->del($id) or do {
        $self->error($store->error);
        return 0;
    };

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "show",
    description => "Show messages",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    my $id = shift(@arguments) || 0;

    # Create agent instance
    my $agent = new App::MonM::Notifier::Agent(
        config => $self->configobj, # Config object
    );
    unless ($agent->status) {
        $self->error($agent->error);
        return 0;
    }

    # Get store
    my $store = $agent->store;

    # Show message
    if ($id) {
        my %info = $store->get($id);
        unless ($store->status) {
            $self->error($store->error);
            return 0;
        };
        unless ($info{id}) {
            $self->error("Data not found");
            return 0;
        };

        my $tbl_hdrs = TABLE_INFO;
           $tbl_hdrs->[1][0] = (SCREENWIDTH() - 20);
        my $tbl = Text::SimpleTable->new(@$tbl_hdrs);
        my $exp = $info{expires} || 0;
        $tbl->row("ID", $id);
        $tbl->row("TO", $info{to} // '');
        $tbl->row("CHANNEL", $info{channel} // '');
        $tbl->row("SUBJECT", encode( locale => $info{subject} // '' ));
        $tbl->row("PUBDATE", $info{pubdate} ? scalar(localtime($info{pubdate})) : '');
        $tbl->row("EXPIRES", $info{expires} ? scalar(localtime($info{expires})) : '');
        $tbl->row("STATUS", $info{status} // '');
        $tbl->row("COMMENT", encode( locale => $info{comment} // '' ));
        $tbl->row("ERRCODE", $info{errcode} // 0);
        $tbl->row("ERRMSG", encode( locale => $info{errmsg} // '' ));
        $tbl->hr;
        $tbl->row("SUMMARY", ($exp < time) ? JOB_EXPIRED : $info{status} // '');
        say $tbl->draw();
        say encode( locale => $info{message} // '' ) if $self->verbosemode;
        return 1;
    } else {
        my @table = $store->getall(ROWS_LIMIT);
        unless ($store->status) {
            $self->error($store->error);
            return 0;
        };
        unless (@table) {
            $self->error("Data not found");
            return 0;
        };
        if ($self->testmode) {
            print(explain(\@table));
            return 1;
        }
        my $tbl_hdrs = TABLE_ALL;
        my $tbl = Text::SimpleTable->new(@$tbl_hdrs);
        my @errors;
        foreach my $rec (sort {$a->[0] <=> $b->[0]} @table) {
            $tbl->row(
                $rec->[0] // 0, # ID
                $rec->[1] // '', # TO
                $rec->[2] // '', # CHANNEL
                encode( locale => $rec->[3] // '' ), # SUBJECT
                $rec->[6] // '', # STATUS
                $rec->[8] // 0, # ERRCODE
            );
            push @errors, $rec->[9] if $rec->[8];
        }
        say $tbl->draw();
        if ($self->verbosemode && @errors) {
            say(sprintf("\n%s BEGIN ERROR STACK -----", "-" x (SCREENWIDTH() - 24)));
            print(join("\n\n", @errors));
            say(sprintf("%s END ERROR STACK -----", "-" x (SCREENWIDTH() - 22)));
        }
    }

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "clean",
    description => "Remove incorrect messages",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;

    # Create agent instance
    my $agent = new App::MonM::Notifier::Agent(
        config => $self->configobj, # Config object
    );
    unless ($agent->status) {
        $self->error($agent->error);
        return 0;
    }

    # Remove messages
    my $store = $agent->store;
    $store->clean() or do {
        $self->error($store->error);
        return 0;
    };

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "truncate",
    description => "Remove all messages",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;

    # Create agent instance
    my $agent = new App::MonM::Notifier::Agent(
        config => $self->configobj, # Config object
    );
    unless ($agent->status) {
        $self->error($agent->error);
        return 0;
    }

    # Remove messages
    my $store = $agent->store;
    $store->truncate() or do {
        $self->error($store->error);
        return 0;
    };

    return 1;
});

1;

__END__
