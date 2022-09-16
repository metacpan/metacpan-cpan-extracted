package App::MonM::Notifier::Monotifier;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Monotifier - extension for the monm notifications

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    # monotifier
    # monotifier show
    # monotifier show <ID>
    # monotifier remove <ID>
    # monotifier clean
    # monotifier truncate

=head1 DESCRIPTION

This is an extension for the monm notifications over different
communication channels

B<Note!> Before using the third-party database, please create the monotifier table

DDL example for MySQL:

    CREATE TABLE IF NOT EXISTS monotifier (
        `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
        `to` CHAR(255), -- Recipient name
        `channel` CHAR(255), -- Recipient channel
        `subject` TEXT, -- Message subject
        `message` TEXT, -- Message content (BASE64)
        `attributes` TEXT, -- Message attributes (JSON)
        `published` BIGINT(20), -- The publication time (unixtime)
        `scheduled` BIGINT(20), -- The scheduled time (unixtime)
        `expired` BIGINT(20), -- The expiration time (unixtime)
        `sent` BIGINT(20), -- The send time
        `attempt` INTEGER DEFAULT 0, -- Count of failed attempts
        `status` CHAR(32), -- Status of transaction
        `errcode` INT(11), -- Error code
        `errmsg` TEXT -- Error message
    );

Configuration example for MySQL:

    UseMonotifier yes
    <MoNotifier>
        DSN "DBI:mysql:database=monotifier;host=mysql.example.com"
        User username
        Password password
        Set RaiseError          0
        Set PrintError          0
        Set mysql_enable_utf8   1

        # Expires and timeout values
        Timeout 60
        MaxTime 300
        Expires 1M
    </MoNotifier>

=head1 INTERNAL METHODS

=over 4

=item B<again>

The CTK method for classes extension. For internal use only!

See L<CTK/again>

=item B<raise>

    return $app->raise("Red message");

Sends message to STDERR and returns 0

=item B<store>

    my $store = $app->store();

Returns store object

=back

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<App::MonM>

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<App::MonM>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.00';

use feature qw/say/;

use Encode;
use Encode::Locale;

use File::stat qw//;
use Text::SimpleTable;

use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use CTK::Util qw/dtf tz_diff variant_stf/;

use App::MonM::Const;
use App::MonM::Util qw/
        blue green red yellow cyan magenta gray
        yep nope skip wow
        getExpireOffset getTimeOffset explain explain
    /;

use App::MonM::Notifier::Store;

use parent qw/CTK::App/;

use constant {
    NODE_NAME       => 'notifier',
    NODE_NAME_ALIAS => 'monotifier',
    ROWS_LIMIT      => 1000,
    DATE_FORMAT     => '%YYYY-%MM-%DD %hh:%mm:%ss',
    TABLE_INFO  => [(
        [12,    'NAME'],
        [68,    'VALUE'],
    )],
};

sub again {
    my $self = shift;
       $self->SUPER::again(); # CTK::App again first!!

    # Store
    my $store_conf = hash($self->conf(NODE_NAME) || $self->conf(NODE_NAME_ALIAS));
    $store_conf->{expires} = getExpireOffset(lvalue($store_conf, "expires") || lvalue($store_conf, "expire") || 0);
    $store_conf->{maxtime} = getExpireOffset(lvalue($store_conf, "maxtime") || 0);
    my $store = App::MonM::Notifier::Store->new(%$store_conf);
    $self->{store} = $store;
    #print App::MonM::Util::explain($store);

    return $self; # CTK requires!
}
sub store {
    my $self = shift;
    return $self->{store};
}
sub raise {
    my $self = shift;
    say STDERR red(@_);
    return 0;
}

__PACKAGE__->register_handler(
    handler     => "info",
    description => "Show statistic information",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    my $store = $self->store;

    # General info
    printf("Hostname            : %s\n", HOSTNAME);
    printf("Monotifier version  : %s\n", $self->VERSION);
    printf("Monotifier enabled  : %s\n", lvalue($self->config("usemonotifier")) ? green("Yes") : magenta("No"));
    printf("Date                : %s\n", _fdate());
    printf("Data dir            : %s\n", $self->datadir);
    printf("Config file         : %s\n", $self->configfile);
    printf("Config status       : %s\n", $self->conf("loadstatus") ? green("OK") : magenta("ERROR: not loaded"));
    $self->raise($self->configobj->error) if !$self->configobj->status and length($self->configobj->error);
    #$self->debug(explain($self->config)) if $self->conf("loadstatus") && $self->verbosemode;

    # DB status
    printf("DB DSN              : %s\n", $store->dsn);
    printf("DB status           : %s\n", $store->error ? red("ERROR") : green("OK"));
    my $db_is_ok = $store->error ? 0 : 1;
    if ($db_is_ok && $store->{file} && -e $store->{file}) {
        my $s = File::stat::stat($store->{file})->size;
        printf("DB file             : %s\n", $store->{file});
        printf("DB size             : %s\n", sprintf("%s (%d bytes)", _fbytes($s), $s));
        printf("DB modified         : %s\n", _fdate(File::stat::stat($store->{file})->mtime || 0));
    }
    $self->raise($store->error) unless $db_is_ok;

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "show",
    description => "Show table data",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    my $id = shift(@arguments) || 0;
    my $store = $self->store;
    return $self->raise($store->error) if $store->error;

    # Show message
    if ($id) {
        my %info = $store->getById($id);
        return $self->raise($store->error) if $store->error;
        return skip("No data") unless $info{id};

        # Table
        my $tbl_hdrs = TABLE_INFO;
           $tbl_hdrs->[1][0] = (SCREENWIDTH() - 19);
        my $tbl = Text::SimpleTable->new(@$tbl_hdrs);

        # Stash
        my $exp = $info{expired} || 0;
        $tbl->row("Id", $id);
        $tbl->row("To", $info{to} // '');
        $tbl->row("Channel", $info{channel} // '');
        $tbl->row("Subject", encode( locale => $info{subject} // '' ));
        $tbl->row("Status", $info{status} // '');
        $tbl->row("Published", $info{published} ? dtf(DATE_FORMAT, $info{published}) : '');
        $tbl->row("Scheduled", $info{scheduled} ? dtf(DATE_FORMAT, $info{scheduled}) : '');
        $tbl->row("Expired", dtf(DATE_FORMAT, $exp)) if $exp;
        $tbl->row("Sent", dtf(DATE_FORMAT, $info{sent})) if $info{sent};
        $tbl->row("Attempt", $info{attempt}) if $info{attempt};
        $tbl->row("Errcode", $info{errcode} // 0);
        $tbl->row("Errmsg", encode( locale => $info{errmsg} // '' ));
        $tbl->hr;
        $tbl->row("SUMMARY", ($exp < time) ? "EXPIRED" : $info{status} // '');
        say $tbl->draw();

        # Show attributes (dump)
        if ($self->verbosemode) {
            say "Attributes of channel:";
            print(explain($info{attributes}));
            print "\n";

            # Show message
            printf("%s BEGIN MESSAGE ~~~\n", "~" x (SCREENWIDTH()-18));
            say encode( locale => $info{message} // '' );
            printf("%s END MESSAGE ~~~\n", "~" x (SCREENWIDTH()-16));
        }
    } else {
        my @table = $store->getAll(ROWS_LIMIT);
        return $self->raise($store->error) if $store->error;

        # Check data
        my $n = scalar(@table) || 0;
        if ($n) {
            printf("Number of records: %d\n", $n);
        } else {
            return skip("No data");
        }

        # Table
        # `id`,`to`,`channel`,`subject`,`message`,`attributes`,`published`,     0-6
        # `scheduled`,`expired`,`sent`,`attempt`,`status`,`errcode`,`errmsg`    7-13
        my $tbl_hdrs = [(
            [5,     'ID'],
            [20,    'TO'],
            [20,    'CHANNEL'],
            [32,    'SUBJECT'],
            [8,     'STATUS'],
            [3,     'ERR'],
        )];
        my $tbl = Text::SimpleTable->new(@$tbl_hdrs);
        my @errors;
        foreach my $rec (sort {$a->[0] <=> $b->[0]} @table) {
            $tbl->row(
                $rec->[0] // 0, # id
                variant_stf($rec->[1] // '', 20), # to
                variant_stf($rec->[2] // '', 20), # channel
                variant_stf(encode( locale => $rec->[3] // '' ), 32), # subject
                $rec->[11] // '', # status
                $rec->[12] // 0, # errcode
            );
            push @errors, $rec->[13] if $rec->[12];
        }
        say $tbl->draw();
        if ($self->verbosemode && @errors) {
            foreach my $err (@errors) {
                say magenta($err);
            }
        }
    }

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "remove",
    description => "Remove message by id",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    my $store = $self->store;
    return $self->raise($store->error) if $store->error;
    my $id = shift(@arguments) || 0;
    return $self->raise("Incorrect id") unless $id;

    # Remove message by id
    return $self->raise($store->error) unless $store->delById($id);

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "clean",
    description => "Remove incorrect messages",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    my $store = $self->store;
    return $self->raise($store->error) if $store->error;

    return $self->raise($store->error) unless $store->cleanup();

    return 1;
});

__PACKAGE__->register_handler(
    handler     => "truncate",
    description => "Remove all messages (purge)",
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    my $store = $self->store;
    return $self->raise($store->error) if $store->error;

    # Remove messages
    return $self->raise($store->error) unless $store->purge();

    return 1;
});

# Private methods
sub _fbytes {
    my $n = int(shift);
    if ($n >= 1024 ** 3) {
        return sprintf "%.3g GB", $n / (1024 ** 3);
    } elsif ($n >= 1024 ** 2) {
        return sprintf "%.3g MB", $n / (1024.0 * 1024);
    } elsif ($n >= 1024) {
        return sprintf "%.3g KB", $n / 1024.0;
    } else {
        return "$n B";
    }
}
sub _fdate {
    my $d = shift || time;
    my $g = shift || 0;
    return "unknown" unless $d;
    return dtf(DATETIME_GMT_FORMAT, $d, 1) if $g;
    return dtf(DATETIME_FORMAT . " " . tz_diff(), $d);
}

1;

__END__
