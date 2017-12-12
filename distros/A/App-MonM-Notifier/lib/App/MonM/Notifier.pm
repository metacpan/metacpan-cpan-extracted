package App::MonM::Notifier; # $Id: Notifier.pm 48 2017-12-05 11:55:54Z abalama $
use strict;

=head1 NAME

App::MonM::Notifier - a monitoring tool that provides notifications
on different communication channels

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use base qw/App::MonM::Notifier/;

=head1 DESCRIPTION

This module provides main functionality for notification tool

For internal use only

=head2 FUNCTIONS

=over 8

=item B<test>

Test function. Do not use it

=item B<void>

Void function. Do not use it

=item B<init>

Initializing the monotifier

=item B<send>

Send message to local or remote server

=item B<check>

Check message by id on local or remote server

=item B<remove>

Remove message by id on local or remote server

=item B<update>

Update message in local or remote server

=item B<gentoken>

Generate token for client-server interaction

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<LWP>, C<mod_perl2>, L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>, L<CTK>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw/$VERSION/;
$VERSION = '1.01';

use Encode;
use Encode::Locale;

use CTKx;
use CTK qw/:BASE/;
use CTK::Util;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use Sys::Hostname;
use Net::SSLeay;
use IO::File;
use Text::SimpleTable;
use Try::Tiny;
use File::Spec qw//;

use App::MonM::Notifier::Const;
use App::MonM::Notifier::Helper;
use App::MonM::Notifier::Client;
use App::MonM::Notifier::Server;


use constant {
    PROJECT     => 'monotifier',
    PREFIX      => 'monotifier',
    LOCALHOSTIP => '127.0.0.1',
    MODE        => 'local',
    TERMWIDTH   => 80,
    PASS        => "PASS",
    FAIL        => "FAIL",
    SKIP        => "SKIP",
};

sub void {
    debug("VOID CONTEXT");

    #my $c = CTKx->instance->c;
    #$c->log( INFO => " ... Blah-Blah-Blah ... " );

    #my $config = $c->config;
    #debug $c->datadir();

    #print(Dumper($store));

    1;
}
sub test {
    my $c = CTKx->instance->c;
    my %cmd = @_;
    my @arguments = @{$cmd{arguments}};
    my $config = $c->config;
    my $tw = _get_tw();
    my $width;
    my $hr = sub {
        my $w = shift;
        $width = $w if defined $w;
        $width = 20 unless defined $width;
        sprintf("% ".$width."s-+-%s", ("-" x $width), ("-" x ($tw-3-$width)));
    };
    my $row = sub {
        $width = 20 unless defined $width;
        sprintf("% ".$width."s : %s", shift, shift)
    };

    say sprintf("Testing %s %s...", PROJECT, __PACKAGE__->VERSION);

    # PASS, FAIL, SKIP

    # 0. General
    my $ready = $config->{loadstatus} ? 1 : 0;
    say &$hr(20);
    say &$row("Readiness", $ready ? PASS : FAIL);
    say &$row("Config file", $c->cfgfile());
    say &$row("Config directory", $c->confdir());
    unless ($ready) {
        say &$hr();
        return 0; # FAIL
    }
    my $mode = value($config => "mode") || MODE;
    say &$row("Server mode", $mode);
    say &$row("Expires", value($config => "expires") || 'default');
    say &$row("Lifetime", value($config => "lifetime") || 'default');
    say &$row("TimeOut", value($config => "timeout") || 'default');
    my $token = value($config => "token") || '';
    say &$row("Token", length($token) == 64 ? PASS : FAIL);
    say &$hr();
    if (length($token) == 64) {
        say " Token: ", $token;
        say "-" x $tw;
    }
    if (verbosemode) {
        say " Configuration: ";
        require Data::Dumper;
        print Data::Dumper::Dumper($config);
        say "-" x $tw;
    }

    # Skip if general only
    my $general = shift(@arguments) || '';
    if ($general eq 'short') {
        return 1; # SKIP
    }

    # 1. Server/Client checks
    say;
    my ($client, $server);
    if ($mode eq 'remote') {
        say "Client/Server interaction";
        say &$hr();
        my $uri = _mk_uri(value($config => "client/serverurl"));
        my $url = $uri->canonical->as_string;
        say &$row("Server URL", $url);
        say &$row("UserName", value($config => "client/username")) if value($config => "client/username");
        say &$row("Password", value($config => "client/password")) if value($config => "client/password");
        say &$row("Client TimeOut", value($config => "client/timeout") || 'default');
        $client = new App::MonM::Notifier::Client(
            uri         => $uri,
            debug       => 1,
            verbose     => verbosemode,
            timeout     => value($config => "client/timeout"), # default: 180
        );
        say &$row("Connection attempt", $client->check("GET") ? PASS : FAIL);
        unless ($client->status) {
            say &$row("ERROR", encode( locale => $client->error));
            say &$hr();
            say encode( locale => join("\n", @{($client->trace)}));
            say "-" x $tw;
            return 0;
        }
        say &$hr();
    } else {
        say "Server instance";
        say &$hr();
        $server = new App::MonM::Notifier::Server;
        my $store = $server->store;
        my ($type, $dsn, $table, $user, $password);
        if ($store) {
            $type = $store->{type} || 'default';
            $dsn  = $store->{dsn} || 'default';
            $table = $store->{table} || 'default';
            $user = $store->{user};
            $password = uv2null($store->{password});
        } else {
            $type = value($config, "store/type") || 'default';
            $dsn  = value($config, "store/dsn") || 'default';
            $table = value($config, "store/table") || 'default';
            $user = value($config, "store/user");
            $password = uv2null(value($config, "store/password"));
        }
        say &$row("Store type", $type);
        say &$row("Store DSN", $dsn);
        say &$row("Store table", $table);
        if ($user && length($user)) {
            say &$row("User", $user);
            say &$row("Password", $password);
        }
        say &$row("Store status", $store && $store->status ? PASS : FAIL);
        say &$row("Server status", $server->status ? PASS : FAIL);
        unless ($server->status) {
            say &$row("ERROR", encode( locale => $server->error));
            say &$hr();
            return 0;
        }
        say &$hr();
    }

    # 2. User
    say;
    say "Users";
    my $t2 = new Text::SimpleTable(
            [12  => 'User'],
            [12  => 'Channel'],
            [10  => 'Type'],
            [3   => 'Stt'],
            [26  => 'Real To'],
        );
    my $usernode = node($config => "user");
    if ($usernode && is_hash($usernode) && keys %$usernode) {
        my @users = sort {$a cmp $b} keys %$usernode;
        my $ucnt = 0;
        foreach my $un (@users) {
            my $channelnode = node($usernode => $un, "channel");
            if ($channelnode && is_hash($channelnode) && keys %$channelnode) {
                $t2->hr if $ucnt;
                my @channels = sort {$a cmp $b} keys %$channelnode;
                my $unv = $un;
                foreach my $cn (@channels) {
                    $t2->row($unv, $cn,
                            value($channelnode => $cn, "type") || "",
                            value($channelnode => $cn, "enable") ? "ON" : "OFF",
                            value($channelnode => $cn, "to") || "",
                        );
                } continue {
                    $unv = "";
                }
            }
        } continue {
            $ucnt++;
        }
        print $t2->draw;
    } else {
        say "-" x $tw;
        say "Users have not been defined";
        say "-" x $tw;
    }

    # 3. Records
    say;
    say "Last messages";
    my $tm = time();
    my $tm_d = $tm-(24*60*60);
    my $tm_w = $tm-(7*24*60*60);
    my $tm_m = $tm-(30*24*60*60);
    my @hs = (
            [12  => 'ID'],
            [17  => 'PUBDATE (Y/M/D T)'],
            [11  => 'TO'],
            [7   => 'LEVEL'],
            [9   => 'STATUS'],
            [4   => 'ERR'],
        );
    my @hsi; push(@hsi,$_->[0]) for @hs;
    my $t3 = new Text::SimpleTable(@hs);
    my $i = 0;
    my $j = 0;
    my @find;
    if ($mode eq 'remote') {
        my $tmpuri = $client->{uri}->clone;
        foreach my $tv ($tm_d, $tm_w, $tm_m) {
            $client->{uri}->query_form( token => $token, pubdate => "+".$tv);
            my %json = $client->request("GET", sprintf("%s/search", $client->{uri}->path // ""));
            unless ($client->status) {
                say "-" x $tw;
                say "Can't get messages";
                say encode( locale => $client->error );
                say "-" x $tw;
                say encode( locale => join("\n", @{($client->trace)}));
                say "-" x $tw;
                return 0;
            }
            @find = @{($json{messages} || [])};
            last if scalar(@find);
        }
        $client->{uri} = $tmpuri;
    } else {
        my $store = $server->store;
        @find = $store->getall( pubdate => "+".$tm_d );
        @find = $store->getall( pubdate => "+".$tm_w ) unless scalar(@find);
        @find = $store->getall( pubdate => "+".$tm_m ) unless scalar(@find);
    }
    foreach my $rec (sort { $b->[9] <=> $a->[9] } @find) { last if $i >= 10;
        $i++;
        $j++;
        $t3->row(
            $rec->[0] || 0,
            dtf("%YY/%MM/%DD %hh:%mm:%ss", uv2zero($rec->[9])),
            uv2null($rec->[5]),
            getLevelName(uv2zero($rec->[4])),
            uv2null($rec->[11]),
            uv2null($rec->[13]),
        );
        if ($rec->[13]) {
            print $t3->draw;
            say encode(locale => uv2null($rec->[14]));
            $t3 = new Text::SimpleTable(@hsi);
            $j = 0;
        }
    }
    if ($i) {
        print $t3->draw if $j;
    } else {
        say "-" x $tw;
        say "No messages";
        say "-" x $tw;
    }

    1; # PASS
}
sub init {
    my %cmd = @_;
    my @arguments = @{$cmd{arguments}};
    #my $prj = shift(@arguments);
    my $c = CTKx->instance->c;
    my $config = $c->config;

    my ($vol,$dir) = ((splitpath($c->cfgfile()))[0,1]);
    my $cfgdir = File::Spec->canonpath($vol ? catdir($vol,$dir) : $dir);
    my $installsitebin = syscfg("installsitebin") || catdir(prefixdir(),"bin");
    #say(sprintf(">>> %s", $cfgdir));
    #say(sprintf(">>> %s", prefixdir()));

    if ($config->{loadstatus}) {
        _warn("Skip. The monotifier project has already been successfully initialized");
        return 1;
    }
    if ($cfgdir && -e $cfgdir) {
        _warn(sprintf("Skip. Configuration folder \"%s\" already exists", $cfgdir));
        return 1;
    }

    say "Initializing...";
    {
        # Building
        my $h = new App::MonM::Notifier::Helper (
                -conf   => $cfgdir,
                -misc   => File::Spec->rootdir(),
            );
        my $hstatus = $h->build(
                "PROJECT"   => PROJECT,
                SPLITTER    => MSWIN ? "\\" : "/",
                ROOT_DIR    => File::Spec->rootdir(),
                CONF_DIR    => $cfgdir,
                SITE_BIN    => $installsitebin,
                PARAM1 => '111',
                PARAM2 => '222',
            );
        unless ($hstatus) {
            carp("Failed. Can't initialize the monotifier");
            return 1;
        }
        #print(Dumper($h));
    }

    say "Done.";
    1;
}
sub gentoken {
    my %cmd = @_;
    my @arguments = @{$cmd{arguments}};
    my $c = CTKx->instance->c;
    my $config = $c->config;

    my $newkey;
    Net::SSLeay::RAND_bytes($newkey,255);
    my $token = unpack("h*", Net::SSLeay::SHA256($newkey));

    if ($c->options->{notupdate}) {
        say sprintf("\n    Token: %s\n", $token);
        say "Please paste this token to monotifier's configuration file as Token directive";
        return 1;
    }

    my ($vol,$dir) = ((splitpath($c->cfgfile()))[0,1]);
    my $cfgdir = $vol ? catdir($vol,$dir, "extra") : catdir($dir, "extra");
    #say(sprintf(">>> %s", $cfgdir));

    unless ($config->{loadstatus}) {
        _warn("Skip. The monotifier project is not initialized. Please initialize first!");
        return 1;
    }
    unless ($cfgdir && -e $cfgdir) {
        _warn(sprintf("Configuration folder \"%s\" not configured. Please initialize first!", $cfgdir));
        return 1;
    }

    my $tokenfile = catfile($cfgdir, "token.conf");
    my $fh = IO::File->new($tokenfile, "w");
    if (defined $fh) {
        $fh->print("# This file was generated automatically by Monotifier program.\n");
        $fh->print("# Don't edit this file manually, use monotifier utility\n");
        $fh->print("#\n");
        $fh->print("#   monotifier gentoken\n");
        $fh->print("#\n");
        $fh->printf("\nToken\t%s\n\n", $token);
        $fh->close;
    } else {
        carp("Can't save file $tokenfile: $!");
        return 0;
    }

    1;
}
sub send {
    my %cmd = @_;
    my @arguments = @{$cmd{arguments}};
    my $c = CTKx->instance->c;
    my $config = $c->config;
    my $mode = value($config => "mode") || MODE;
    my $token = value($config => "token");
    #debug "Mode: $mode";
    my $id = 0;

    my @opts = (
        ident   => $c->options->{signature},
        level   => getLevelByName($c->options->{level} || "debug"),
        to      => shift(@arguments), # Имя пользователя для кого сообщение
        from    => $c->options->{from}, # Имя пользователя от кого сообщение
        subject => decode( locale => shift(@arguments) ),
        message => decode( locale => shift(@arguments) ),
        pubdate => $c->options->{pubdate}, # Время когда начать попытки отправки. Может быть в будущем
        expires => $c->options->{expires}, # Время когда закончить попытки отправки
    );

    if (lc($mode) eq 'remote') {
        # Create object and check it
        my $client = new App::MonM::Notifier::Client(
            uri         => _mk_uri(value($config => "client/serverurl")),
            debug       => 1,
            verbose     => verbosemode,
            timeout     => value($config => "client/timeout"), # default: 180
        );
        unless ($client->check) {
            _warn($client->error);
            _warn(join("\n", @{($client->trace)}));
            $c->log_error($client->error);
            return 0;
        }
        $id = $client->cleanuptrace->send(
                token => $token,
                @opts
            );
        unless ($client->status) {
            _warn($client->error);
            _warn(join("\n", @{($client->trace)}));
            $c->log_error($client->error);
            return 0;
        }
    } else { # local
        my $server = new App::MonM::Notifier::Server;
        unless ($server->status) {
            _warn($server->error);
            $c->log_error($server->error);
            return 0;
        }
        $id = $server->send(
                ip      => LOCALHOSTIP,
                host    => hostname,
                @opts
            );

        unless ($server->status) {
            _warn($server->error);
            $c->log_error($server->error);
            return 0;
        }
    }

    say sprintf "ID: %d", $id if $id;
    1;
}
sub check { # Проверка записи по ID
    my %cmd = @_;
    my @arguments = @{$cmd{arguments}};
    my $c = CTKx->instance->c;
    my $config = $c->config;
    my $mode = value($config => "mode") || MODE;
    my $token = value($config => "token");
    my $id = shift(@arguments) || 0;
    unless ($id) {
        say "ID incorrect";
        return 0;
    }

    if (lc($mode) eq 'remote') {
        # Create object and check it
        my $client = new App::MonM::Notifier::Client(
            uri         => _mk_uri(value($config => "client/serverurl")),
            debug       => 1,
            verbose     => verbosemode,
            timeout     => value($config => "client/timeout"), # default: 180
        );
        unless ($client->check) {
            _warn($client->error);
            _warn(join("\n", @{($client->trace)}));
            $c->log_error($client->error);
            return 0;
        }
        my $ret = $client->cleanuptrace->info($token, $id);
        unless ($client->status) {
            _warn($client->error);
            _warn(join("\n", @{($client->trace)}));
            $c->log_error($client->error);
            return 0;
        }
        unless ($ret && is_hash($ret) && keys(%$ret)) {
            say(sprintf("STATUS: %s", "NOT FOUND"));
            return 0;
        }

        say(sprintf("ID     : %s", $id));
        say(sprintf("STATUS : %s", $ret->{status} || 'UNKNOWN'));
        say(sprintf("IP     : %s", $ret->{ip} || ''));
        say(sprintf("HOST   : %s", $ret->{host} || ''));
        say(sprintf("CODE   : %s", $ret->{errcode} || '')) if $ret->{errcode};
        say(sprintf("ERROR  : %s", encode(locale => $ret->{errmsg} || ''))) if $ret->{errmsg};
        say(sprintf("COMMENT: %s", encode(locale => $ret->{comment} || ''))) if $ret->{comment};
    } else { # local
        my $server = new App::MonM::Notifier::Server;
        unless ($server->status) {
            _warn($server->error);
            $c->log_error($server->error);
            return 0;
        }
        my %data = $server->check($id);
        unless ($server->status) {
            _warn($server->error);
            $c->log_error($server->error);
            return 0;
        }
        unless (%data && keys(%data)) {
            say(sprintf("STATUS: %s", "NOT FOUND"));
            return 0;
        }

        say(sprintf("ID     : %s", $id));
        say(sprintf("STATUS : %s", $data{status} || 'UNKNOWN'));
        say(sprintf("IP     : %s", $data{ip} || ''));
        say(sprintf("HOST   : %s", $data{host} || ''));
        say(sprintf("CODE   : %s", $data{errcode} || '')) if $data{errcode};
        say(sprintf("ERROR  : %s", encode(locale => $data{errmsg} || ''))) if $data{errmsg};
        say(sprintf("COMMENT: %s", encode(locale => $data{comment} || ''))) if $data{comment};
    }
    1;
}
sub remove {
    my %cmd = @_;
    my @arguments = @{$cmd{arguments}};
    my $c = CTKx->instance->c;
    my $config = $c->config;
    my $mode = value($config => "mode") || MODE;
    my $token = value($config => "token");
    my $id = shift(@arguments) || 0;
    unless ($id) {
        say "ID incorrect";
        return 0;
    }

    if (lc($mode) eq 'remote') {
        # Create object and check it
        my $client = new App::MonM::Notifier::Client(
            uri         => _mk_uri(value($config => "client/serverurl")),
            debug       => 1,
            verbose     => verbosemode,
            timeout     => value($config => "client/timeout"), # default: 180
        );
        unless ($client->check) {
            _warn($client->error);
            _warn(join("\n", @{($client->trace)}));
            $c->log_error($client->error);
            return 0;
        }
        my $ret = $client->cleanuptrace->info($token, $id);
        unless ($client->status) {
            _warn($client->error);
            _warn(join("\n", @{($client->trace)}));
            $c->log_error($client->error);
            return 0;
        }
        unless ($ret && is_hash($ret) && keys(%$ret)) {
            say(sprintf("ID %d NOT FOUND", $id));
            return 0;
        }
        $client->cleanuptrace->remove($token, $id);
        unless ($client->status) {
            _warn($client->error);
            _warn(join("\n", @{($client->trace)}));
            $c->log_error($client->error);
            return 0;
        }
    } else { # local
        my $server = new App::MonM::Notifier::Server;
        unless ($server->status) {
            _warn($server->error);
            $c->log_error($server->error);
            return 0;
        }
        my %data = $server->check($id);
        unless ($server->status) {
            _warn($server->error);
            $c->log_error($server->error);
            return 0;
        }
        unless (%data && keys(%data)) {
            say(sprintf("ID %d NOT FOUND", $id));
            return 0;
        }
        $server->remove($id);
        unless ($server->status) {
            _warn($server->error);
            $c->log_error($server->error);
            return 0;
        }
    }
    1;
}
sub update {
    my %cmd = @_;
    my @arguments = @{$cmd{arguments}};
    my $c = CTKx->instance->c;
    my $config = $c->config;
    my $mode = value($config => "mode") || MODE;
    my $token = value($config => "token");
    my $id = shift(@arguments) || 0;
    unless ($id) {
        say "ID incorrect";
        return 0;
    }

    my @opts = (id => $id);
    push(@opts, ident   => $c->options->{signature}) if $c->options->{signature};
    push(@opts, level   => getLevelByName($c->options->{level})) if $c->options->{level};
    my $to = shift(@arguments);
    push(@opts, to      => $to) if $to;
    push(@opts, from    => $c->options->{from}) if $c->options->{from}; # Имя пользователя от кого сообщение
    my $sbj = shift(@arguments);
    push(@opts, subject => decode( locale => $sbj )) if defined $sbj;
    my $msg = shift(@arguments);
    push(@opts, message => decode( locale => $msg )) if defined $msg;
    push(@opts, pubdate => $c->options->{pubdate}) if defined $c->options->{pubdate};
    push(@opts, expires => $c->options->{expires}) if defined $c->options->{expires};

    if (lc($mode) eq 'remote') {
        # Create object and check it
        my $client = new App::MonM::Notifier::Client(
            uri         => _mk_uri(value($config => "client/serverurl")),
            debug       => 1,
            verbose     => verbosemode,
            timeout     => value($config => "client/timeout"), # default: 180
        );
        unless ($client->check) {
            _warn($client->error);
            _warn(join("\n", @{($client->trace)}));
            $c->log_error($client->error);
            return 0;
        }
        $client->cleanuptrace->update(
                token => $token,
                @opts
            );
        unless ($client->status) {
            _warn($client->error);
            _warn(join("\n", @{($client->trace)}));
            $c->log_error($client->error);
            return 0;
        }
    } else { # local
        my $server = new App::MonM::Notifier::Server;
        unless ($server->status) {
            _warn($server->error);
            $c->log_error($server->error);
            return 0;
        }
        $server->update(
            ip      => LOCALHOSTIP,
            host    => hostname,
            @opts
        );
        unless ($server->status) {
            _warn($server->error);
            $c->log_error($server->error);
            return 0;
        }
    }

    1;
}

sub _get_tw {
    return TERMWIDTH unless -t STDOUT;
    my $w = TERMWIDTH;
    try {
        require Term::ReadKey;
        $w = (Term::ReadKey::GetTerminalSize())[0];
        $w = TERMWIDTH if $w < TERMWIDTH;
    } catch {
        $w = TERMWIDTH;
    };
    return $w;
}
sub _mk_uri { # URI&URL constructor
    my $url = shift;
    return new URI( $url ) if $url;

    my $uri = new URI( "http://localhost" );
    my $server_host = "localhost";
    my $server_port = 80;
    my $server_path = PROJECT;
    my $server_scheme = 'http';
    $uri->scheme($server_scheme);
    $uri->host($server_host);
    $uri->port($server_port) if ($server_port != 80 and $server_port != 443);
    $uri->path($server_path);
    return $uri;
}
sub _warn {
    my $v = shift;
    return unless defined $v;
    printf STDERR "%s\n", encode( locale => $v );
}

1;
__END__
