package Apache2::Controller::Test::OpenIDServer;

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw(
    HTTP::Server::Simple::CGI
);

use Net::OpenID::Server;

# try overriding signal handlers
$HTTP::Server::Simple::SIG{ALRM} = sub { 
    my @args = @_;
  # warn "# received timeout alarm, temminating $$\n";
  # warn "# args are (".join(',',@args).")\n";
  # warn "# (caller is ".caller().")\n";
  # die "# terminating on alarm\n";
    exit(0);
};

$HTTP::Server::Simple::SIG{INT} = sub { 
    warn "# caught interrupt, exiting $$ cleanly\n";
    exit(0);
};

use Apache::TestServer;
use Apache::TestRequest;
use Apache2::Controller::Test::Funk qw( diag );
use Apache2::Controller::Test::UnitConf;


use Log::Log4perl qw(:easy);
Log::Log4perl->init(\$L4P_UNIT_CONF);

use YAML::Syck;

# we overload new() so we can auto-detect an available port
sub new {
    my ($class) = @_;

    my $tries = 20;

    my $a2c_test_url = Apache::TestRequest::module2url('');
    diag("a2c_test_url is '$a2c_test_url'");
    my ($port) = $a2c_test_url =~ m{ \A http?://\D*?:(\d+) }mxs;

    my $increment = 0;

    $port += (int(rand(10)) + 1)
        until Apache::TestServer->port_available($port) || !--$tries;

    diag("openid server port is '$port'");
    
    my $server = HTTP::Server::Simple::CGI->new($port);
    bless $server, $class;

    return $server;
}

# we overload run so we can set the appropriate alarm to die
sub run {
    my ($self, @args) = @_;
  # warn "# setting alarm in pid $$ for 45 seconds...\n";
  # warn "# caller is ".caller()."\n";
    alarm(45);
  # warn "# calling super run\n";
    return $self->HTTP::Server::Simple::run(@args);
}

# overload print_banner so it doesn't do anything
sub print_banner {
}

sub handle_request {
    my ($self, $cgi) = @_;
    $self->{cgi} = $cgi;

    my $path = $cgi->path_info();
    DEBUG "handling request for path '$path'";
    return $self->working()  if $path eq '/working';
    return $self->user_url() if $path eq '/a2ctest';

    my $port = $self->port;
    DEBUG "openid server port is '$port'";

    my $nos = Net::OpenID::Server->new(
        get_args        => $cgi,
        post_args       => $cgi,
        get_user        => sub { nos_get_user($cgi, @_)     },
        is_identity     => sub { nos_is_identity($cgi, @_)  },
        is_trusted      => sub { nos_is_trusted($cgi, @_)   },
        setup_url       => "http://localhost:$port/pass-identity",
        server_secret   => q{These blast points, too precise for Sandpeople},
    );

    my ($type, $data);
    eval { ($type, $data) = $nos->handle_page() };
    return $self->die_error($EVAL_ERROR) if $EVAL_ERROR;
    DEBUG "NOS RESULTS: type '$type', data:\n".Dump($data);

    if ($type eq 'redirect') {
        DEBUG "got type redirect, redirecting back to url:\n$data";
        print "HTTP/1.0 302 Found\r\n",
            $cgi->redirect(-uri => $data);
    }
    elsif ($type eq 'setup') {
        $self->die_error("setup unimplemented");
    }
    else {
        print "HTTP/1.0 200 OK\r\n",
        $cgi->header($type),
        $data;
    }
}

sub die_error {
    my ($self, $error_string) = @_;
    DEBUG "dying with error string: '$error_string'";
    my $cgi = $self->{cgi};
    print "HTTP/1.0 500 Internal Server Error\r\n",
        $cgi->header,
        $error_string;
}

sub user_url {
    my ($self) = @_;
    DEBUG "Trying to print the right content for user_url";
    my $cgi = $self->{cgi};
    my $port = $self->port;
    print "HTTP/1.0 200 OK\r\n",
        $cgi->header,
        <<END_HTML;
<html>
<head>
<link rel="openid.server" href="http://localhost:$port/server">
</head>
<body>
horta
</body>
</html>
END_HTML
}

# test if the server is working by printing a string
sub working {
    my ($self) = @_;
    my $cgi = $self->{cgi};
    print "HTTP/1.0 200 OK\r\n",
        $cgi->header,
        "WORKING";
    return;
}

sub nos_get_user {
  # my @args = @_;
  # DEBUG "args:\n".Dump(\@args);
  # die("nos_get_user unimplemented\n");
    my ($cgi) = @_;
    my $identity = $cgi->param('openid.identity');
    my ($username) = $identity =~ m{ ([^\/]+) \s* \z }mxs;
    DEBUG "detected username '$username'";
    return $username;
}

sub nos_is_identity {
    my ($cgi, $username, $url) = @_;
    return $url =~ m{ \A .* / \Q$username\E \z }mxs ? 1 : 0;
}

sub nos_is_trusted {
    my ($cgi, $username, $trust_root, $is_identity) = @_;
    DEBUG "args:\n".Dump(\@_);
    return if !defined $username;
    return if !$is_identity;
    return 1 if $trust_root =~ m{ \A (http://localhost:) (\d+) \z }mxs;
    DEBUG "not trusted ($username, $trust_root, $is_identity)";
    return;
}

1;
