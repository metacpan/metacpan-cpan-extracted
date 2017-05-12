# Copyright 2001-2006 The Apache Software Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package AxKit2::Test;

use strict;
use warnings;
use Encode;

use IO::Socket;
use LWP::UserAgent;
use File::Spec;
use base 'Test::Builder::Module';

our @EXPORT = qw(start_server stop_server http_get
    content_is content_matches content_doesnt_match
    status_is is_redirect no_redirect header_is
    skip plan);
our $VERSION = 0.01;

# Module to assist with testing

my $ua = LWP::UserAgent->new;
$ua->agent(__PACKAGE__."/".$VERSION);

my $server_port = 54000;

sub get_free_port {
    die "No ports free" if $server_port == 65534;
    
    while (IO::Socket::INET->new(PeerAddr => "localhost:$server_port")) {
        $server_port++;
    }
    if (IO::Socket::INET->new(PeerAddr => "localhost", PeerPort => $server_port+1)) {
        # server port free, console port isn't
        $server_port += 2;
        return get_free_port();
    }
    return $server_port;
}

my $server;

=head2 start_server <config> | <docroot> <plugins> <directives>

This takes either a configuration file excerpt as a string (anything that goes inside a <Server></Server> block),
or the document root, a list of plugins to load and a list of other configuration directives.

=cut

sub start_server {
    my ($docroot, $plugins, $directives) = @_;
    
    my $port = get_free_port();
    
    if (defined $plugins) {
        $directives ||= [];
        $docroot = File::Spec->rel2abs($docroot);
        $server = AxKit2::Test::Server->new($port,"DocumentRoot '$docroot'\n" . 
            join("\n",map { "Plugin $_" } @$plugins) . "\n" . 
            join("\n",@$directives) . "\n");
    } else {
        $server = AxKit2::Test::Server->new($port, $docroot);
    }

    return $server;
}

sub stop_server {
    $server->shutdown();
    undef $server;
}

sub http_get {
    my ($url) = @_;
    $url = "http://localhost:$server_port$url" if $url !~ m/^[a-z0-9]{1,6}:/i;
    my $req = new HTTP::Request(GET => $url);
    return ($req, $ua->request($req));
}

sub plan {
    my $builder = __PACKAGE__->builder;
    return $builder->plan(@_);
}

sub skip {
    my $builder = __PACKAGE__->builder;
    return $builder->skip(@_);
}

sub content_is {
    my ($url, $content, $name, $ignore) = @_;
    my $builder = __PACKAGE__->builder;
    my $res = http_get($url);
    if (!$ignore && !$res->is_success) {
        $builder->ok(0,$name);
        $builder->diag("Request for '${url}' failed with error code ".$res->status_line);
        return 0;
    }
    my $got = $res->content;
    $got =~ s/[\r\n]*$//;
    $content =~ s/[\r\n]*$//;
    $builder->is_eq($got, $content, $name) or $builder->diag("Request URL: ${url}");
}

sub header_is {
    my ($url, $header, $content, $name, $ignore) = @_;
    my $builder = __PACKAGE__->builder;
    my $res = http_get($url);
    if (!$ignore && !$res->is_success) {
        $builder->ok(0,$name);
        $builder->diag("Request for '${url}' failed with error code ".$res->status_line);
        return 0;
    }
    my $got = $res->header($header);
    $builder->is_eq($got, $content, $name) or $builder->diag("Request URL: ${url}");
}

sub content_matches {
    my ($url, $regex, $name, $ignore) = @_;
    my $builder = __PACKAGE__->builder;
    my $res = http_get($url);
    if (!$ignore && !$res->is_success) {
        $builder->ok(0,$name);
        $builder->diag("Request for '${url}' failed with error code ".$res->status_line);
        return 0;
    }
    my $got = decode_utf8($res->content);
    $got =~ s/[\r\n]*$//;
    $regex = qr($regex) unless ref($regex);
    $builder->like($got, $regex, $name) or $builder->diag("Request URL: ${url}");
}

sub content_doesnt_match {
    my ($url, $regex, $name, $ignore) = @_;
    my $builder = __PACKAGE__->builder;
    my $res = http_get($url);
    if (!$ignore && !$res->is_success) {
        $builder->ok(0,$name);
        $builder->diag("Request for '${url}' failed with error code ".$res->status_line);
        return 0;
    }
    my $got = decode_utf8($res->content);
    $got =~ s/[\r\n]*$//;
    $regex = qr($regex) unless ref($regex);
    $builder->unlike($got, $regex, $name) or $builder->diag("Request URL: ${url}");
}

sub is_redirect {
    my ($url, $dest, $name) = @_;
    my $builder = __PACKAGE__->builder;
    $ua->max_redirect(0);
    $dest = "http://localhost:$server_port$dest";
    my $res = http_get($url);
    $ua->max_redirect(7);
    my $got = $res->code;
    my $gotdest = $res->header('Location');
    $builder->ok($res->is_redirect && $dest eq $gotdest, $name) or $builder->diag("Request for '${url}' failed:" .
        ($res->is_redirect? "" : "\n     got status: $got, expected a redirect") . 
        ($dest eq $gotdest? "" : "\n     got destination: $gotdest\nexpected destination: $dest"));
}

sub no_redirect {
    my ($url, $name) = @_;
    my $builder = __PACKAGE__->builder;
    $ua->max_redirect(0);
    #$dest = "http://localhost:$server_port$dest";
    my $res = http_get($url);
    $ua->max_redirect(7);
    my $got = $res->code;
    my $gotdest = $res->header('Location');
    $builder->ok(!$res->is_redirect, $name) or $builder->diag("Request for '${url}' failed:
     got status: $got -> $gotdest, expected non-redirect status");
}

sub status_is {
    my ($url, $status, $name) = @_;
    my $builder = __PACKAGE__->builder;
    my $res = http_get($url);
    my $got = $res->code;
    $builder->is_num($got, $status, $name) or $builder->diag("Request URL: ${url}");
}

package AxKit2::Test::Server;

use File::Temp qw(tempfile);
use AxKit2;

sub new {
    my $class = shift;
    my ($port, $config) = @_;
    
    my ($fh, $filename) = tempfile();
    
    my $self = bless {
        port            => $port,
        console_port    => $port + 1,
        config_file     => $filename,
        }, $class;
    
    $self->setup_config($fh, $config);
    
    pipe(READER, WRITER) || die "cannot create pipe: $!";
    
    my $child = fork;
    die "fork failed" unless defined $child;
    if ($child) {
        $self->{child_pid} = $child;
        close WRITER;
        my $line = <READER>;
        return $self;
    }
    
    # child
    close READER;
    Danga::Socket->AddTimer(0, sub { print WRITER "READY\n"; close(WRITER); });
    AxKit2->run($filename);
    exit;
}

sub setup_config {
    my ($self, $fh, $config) = @_;
    
    my $port = $self->{port};
    my $console = $self->{console_port};
    
    print $fh <<EOT;
Plugin logging/file
LogFile  test.log
LogLevel LOGDEBUG

# setup console
ConsolePort $console
Plugin stats

Plugin  error_xml
ErrorStylesheet demo/error.xsl
StackTrace On

<Server testserver>
    Port $port
    
EOT
    print $fh $config;
    
    print $fh <<EOT;

</Server>
EOT
    
    seek($fh, 0, 0);
}

sub DESTROY {
    my $self = shift;
    
    $self->shutdown;
}

sub shutdown {
    my $self = shift;
    
    return unless $self->{child_pid};
    
    unlink($self->{config_file});
    
    my $conf = IO::Socket::INET->new(
        PeerAddr => "127.0.0.1",
        PeerPort => $self->{console_port},
        ) || die "Cannot connect to console port $self->{console_port} : $!";

    IO::Handle::blocking($conf, 0);
    
    $conf->print("shutdown\n");
    
    my $buf;
    read($conf, $buf, 128 * 1024);
    
    use POSIX ":sys_wait_h";
    my $kid;
    do {
        $kid = waitpid(-1, WNOHANG);
    } until $kid > 0;
    
    delete $self->{child_pid};
}

1;
