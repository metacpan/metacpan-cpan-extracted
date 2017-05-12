#!/usr/bin/perl

=head1 NAME

pureproxy - a Pure Perl HTTP proxy server

=cut

no warnings;

our $VERSION = '0.0100';

BEGIN {
    *warnings::import = sub { };
}

use constant SERVER => $ENV{PUREPROXY_SERVER} || $^O =~ /MSWin32|cygwin/ ? 'Thrall' : 'Starlight';

BEGIN {
    delete $ENV{http_proxy};
    delete $ENV{https_proxy};
}

use Plack::Builder;
use Plack::App::Proxy;

my $app = builder {
    enable 'Proxy::Connect::IO';
    enable 'Proxy::Requests';
    Plack::App::Proxy->new(backend => 'HTTP::Tiny')->to_app;
};

use Plack;
use Plack::Runner;

my $runner = Plack::Runner->new(
    server     => SERVER,
    env        => 'proxy',
    loader     => 'Delayed',
    version_cb => \&version,
);

sub _version () {
    my $server = $runner->{server};
    my $server_version = eval { Plack::Util::load_class($server); $server->VERSION }
                      || eval { Plack::Util::load_class("Plack::Handler::$server"); "Plack::Handler::$server"->VERSION }
                      || 0;
    return "PureProxy/$VERSION $server/$server_version Plack/" . Plack->VERSION . " Perl/$] ($^O)";
}

sub version {
    my ($class) = @_;
    print _version(), "\n";
}

$runner->parse_options(@ARGV);

if ($runner->{help}) {
    require Pod::Usage;
    Pod::Usage::pod2usage(-verbose => 1, -input => \*DATA);
}

my %options = @{$runner->{options}};

if ($options{traffic_log}) {
    $body_eol = $options{traffic_log_body_eol};
    if ($options{traffic_log} ne '1') {
        open my $logfh, ">>", $options{traffic_log}
            or die "open($options{traffic_log}): $!";
        $logfh->autoflush(1);
        $app = builder { enable 'TrafficLog', logger => sub { $logfh->print( @_ ) }, body_eol => $body_eol, with_body => !! $body_eol; $app; };
    } else {
        $app = builder { enable 'TrafficLog', body_eol => $body_eol, with_body => !! $body_eol; $app; };
    }
}

if (not defined $runner->{access_log} or $runner->{access_log} eq '1') {
    $runner->{access_log} = undef;
    $app = builder { enable 'AccessLog'; $app; };
}

push @{$runner->{options}}, 'server_software', _version();

$runner->run($app);

__DATA__

=head1 SYNOPSIS

  pureproxy --host=0.0.0.0 --port=5000 --workers=10 --server Starlight

  pureproxy --traffic-log=traffic.log --traffic-log-body-eol='|'

  pureproxy --access-log=access.log

  pureproxy --other-plackup-options

  pureproxy -v

  http_proxy=http://localhost:5000/ lwp-request http://www.perl.org/

  https_proxy=http://localhost:5000/ lwp-request https://metacpan.org/

=head1 DESCRIPTION

This is pure-Perl HTTP proxy server which can be run on almost every Perl
installation.

It supports SSL and TLS if L<IO::Socket::SSL> is installed and IPv6 if
L<IO::Socket::IP> is installed.

It can be fat-packed and then run with any system with standard Perl
interpreter without installing other packages. See F<examples> directory
for fat-packed version of PureProxy script.

=cut

__END__

=head1 ENVIRONMENT

=head2 PUREPROXY_SERVER

Changes the default PSGI server. This is L<Thrall> for C<MSWin32> and C<cygwin>
and L<Starlight> otherwise.

=head1 INSTALLATION

=head2 With cpanm(1)

  $ cpanm App::PureProxy

=head2 Directly

  $ lwp-request http://git.io/jEE6 | sh

or

  $ curl -kL http://git.io/jEE6 | sh

or

  $ wget --quiet -O- http://git.io/jEE6 | sh

=head1 SEE ALSO

L<http://github.com/dex4er/PureProxy>.

=head1 BUGS

This tool has unstable features and can change in future.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2014-2015 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
