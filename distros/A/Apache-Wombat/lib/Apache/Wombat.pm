# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Apache::Wombat;

=pod

=head1 NAME

Apache::Wombat - embed Wombat within an Apache/mod_perl server

=head1 SYNOPSIS

  # the following, or something equivalent, goes in httpd.conf or a
  # PerlRequire'd script. any of the standard configuration techniques
  # for mod_perl are acceptable.

  # create an Apache::Wombat instance, telling it where to find its
  # home directory and deployment descriptor
  <Perl>
  unless ($Apache::Server::Starting) {
     require Apache::Wombat;
     my $home = '/usr/local/apache';
     my $config = '/usr/local/apache/conf/server.xml';
     $Apache::Wombat = Apache::Wombat->new($home, $config);
  }
  </Perl>

  # configure Apache to use Wombat for servlets only, and the default
  # handler for all static content, and to deny access to
  # webapp-private resources.
  Alias /wombat-examples /usr/local/apache/webapps/examples
  <Location /wombat-examples>
    Options Indexes
    AllowOverride None
    Order allow,deny
    Allow from all
  </Location>
  <Location /wombat-examples/servlet>
    SetHandler perl-script
    PerlHandler $Apache::Wombat->handler
    <IfDefine SSL>
      SSLOptions +StdEnvVars
    </IfDefine>
  </Location>
  IndexIgnore WEB-INF META-INF
  <LocationMatch (WEB|META)-INF>
    deny from all
  </LocationMatch>

=head1 DESCRIPTION

This class embeds a Wombat servlet engine within an Apache/mod_perl
server and enables it to act as an Apache request handler during the
content handling phase.

Typically an instance of B<Apache::Wombat> is created at server
startup time and configured as a method handler for requests that
should be served by Wombat.

In order to use this class, mod_perl must be built with
C<PERL_METHOD_HANDLERS> enabled.

=cut

use fields qw(connector server sslConnector);
use strict;
use warnings;

use Apache ();
use Wombat '0.7.1';
use Wombat::Server ();

our $VERSION = '0.5.1';

=pod

=head1 CONSTRUCTOR

=over

=item new($home, $configFile)

Create and return an instance.

A couple of assumptions are made with regard to the Wombat server's
configuration:

=over

=item 1

Exactly one Service is configured, with exactly one Engine and one or
more Hosts beneath it. If more than one service is configured, only
the first will be used. If the Service or Engine are not configured,
the constructor will die.

=item 2

At most one standard Connector (B<Apache::Wombat::Connector>) and one
secure Connector are configured. Any further Connectors will be
ignored.

=back

Assuming everything goes OK, for each child process, C<await()> will
be called on the child's copy of the server during the child init
phase, and C<stop()> will be called on it during the child exit
phase. Note that active sessions are not expired when httpd is
shutdown (due to some kind of mod_perl bug with registering a server
cleanup handler). This is B<NOT> a session persistence mechanism and
should not be relied upon as such.

B<Parameters:>

=over

=item $home

the path to Wombat's home directory, either absolute or relative
to the Apache ServerRoot (defaults to the ServerRoot)

=item $configFile

the path to Wombat's server deployment descriptor, C<server.xml>,
either absolute or relative to the home directory (defaults to
C<$home/conf/server.xml>)

=back

Dies if a configuration problem is encountered or if the server cannot
be started.

=back

=cut

sub new {
    my $self = shift;
    my $home = shift;
    my $configFile = shift;

    $self = fields::new($self) unless ref $self;

    $self->{server} = Wombat::Server->new();
    $self->{connector} = undef;
    $self->{sslConnector} = undef;

    $home ||= Apache->server_root_relative();

    $self->{server}->setHome($home);
    $self->{server}->setConfigFile($configFile) if $configFile;

    # start the server
    eval {
        $self->{server}->start();

        # assume 1 service, which is dum if no engine and multiple hosts
        # are configured
        my ($service) = $self->{server}->getServices();
        die "no service configured!\n" unless $service;

        # assume at most one standard connector and one secure
        # connector, which is totally fine
        for my $connector ($service->getConnectors()) {
            if (! $self->{connector} && ! $connector->getSecure()) {
                $self->{connector} = $connector;
            }

            if (! $self->{sslConnector} && $connector->getSecure()) {
                $self->{sslConnector} = $connector;
            }

            last if $self->{connector} && $self->{sslConnector};
        }
        die "no connectors configured!\n" unless
            $self->{connector} || $self->{sslConnector};
    };
    if ($@) {
        die "problem starting service: $@\n";
    }

    Apache->push_handlers(PerlChildInitHandler =>
                          sub {
                              my $r = shift;
                              $self->{server}->await();
                          });

#    Apache->server->register_cleanup(sub {
#                                         $self->{server}->stop() }
#                                    );

    Apache->push_handlers(PerlChildExitHandler =>
                          sub {
                              my $r = shift;
                              $self->{server}->stop();
                          });

    return $self;
}

=pod

=head1 PUBLIC METHODS

=over

=item handler($r)

Delegate request processing to the Wombat server. If C<$ENV{HTTPS}> is
set, the request is handed to the configured secure Connector;
otherwise, the configured standard Connector gets the request.

Make sure your SSL module sets C<$ENV{HTTPS}>! With mod_ssl, you can
do this with C<SSLOptions +StdEnvVars>.

B<Parameters:>

=over

=item $r

the B<Apache> request object

=back

=cut

sub handler ($$) {
    my $self = shift;
    my $r = shift;

    return $ENV{HTTPS} ?
        $self->{sslConnector}->process($r) :
            $self->{connector}->process($r);
}

1;
__END__

=pod

=back

=head1 SEE ALSO

L<mod_perl>,
L<Apache>,
L<Wombat::Server>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
