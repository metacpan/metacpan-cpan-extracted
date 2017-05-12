package Catalyst::Helper::FastCGI::ExternalServer;

use strict;
use warnings;

use Catalyst::Utils;

use Cwd qw/realpath/;
use DateTime;
use File::Spec;
use Getopt::Long;

=head1 NAME

Catalyst::Helper::FastCGI::ExternalServer - FastCGI daemon start/stop script for using FastCgiExternalServer

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

In your helper script

  ./script/myapp_create.pl FastCGI::ExternalServer [options]

=head2 OPTIONS

  Options:

    l=[val] listen=[val] (required)

      Socket path to listen on
      (defaults to standard input)
      can be HOST:PORT, :PORT or a
      filesystem path

    n=[val] nproc=[val] (optional)

      specify number of processes to keep
      to serve requests (defaults to 1, requires -listen)

    p=[val] pidfile=[val] (optional)

      specify filename for pid file
      (requires -listen)
      default is /var/run/myapp.pid

    u=[val] user=[val] (optional)

      specify username of executiong fastcgi
      default is root

    o=[val] logfile=[val] (optional)

      specify logfile path
      default is /dev/null

    M=[val] manager=[val] (optional)

      specify alternate process manager
      (FCGI::ProcManager sub-class)
      or empty string to disable

    e=[key1:val1,key2:val2...] env=[key1:val1,key2:val2...] (optional)

      specify additional environment variables

=head1 DESCRIPTION

This module allows configuration using /etc/sysconfig/myapp.
First make a file called /etc/sysconfig/myapp and then write some variables in it.
The variables that you add to the file will automatically override the environment variables.

=head1 METHODS

=head2 mk_stuff

generate init script

=cut

sub mk_stuff {
    my ( $self, $helper, @args ) = @_;

    my $config = {
        listen    => undef,
        nproc     => 1,
        pidfile   => undef,
        manager   => undef,
        env       => {},
        user      => 'root',
        logfile   => '/dev/null',
        app       => $helper->{app},
        author    => $helper->{author},
        home      => realpath( $helper->{base} ),
        appprefix => Catalyst::Utils::appprefix( $helper->{app} ),
        date      => DateTime->now->ymd,
        version   => __PACKAGE__->VERSION
    };

    $self->_parse_args( $config, @args );

    $config->{script}         = $config->{appprefix} . "_fastcgi_server.sh";
    $config->{fastcgi_script} = $config->{appprefix} . "_fastcgi.pl";

    my $script_file
        = File::Spec->catfile( $helper->{base}, 'script', $config->{script} );

    $helper->render_file( 'script', $script_file, $config );
    chmod 0755, $script_file;
}

sub _parse_args {
    my ( $self, $config, @args ) = @_;

    local @ARGV = ();

    foreach (@args) {
        my ( $key, $value ) = split /=/;
        $key ||= $_;

        push( @ARGV, "--$key" );
        push( @ARGV, $value ) if ( defined $value );
    }

    my $listen = undef;
    my $nproc  = 1;
    my $pidfile
        = File::Spec->catfile( '/var/run', $config->{appprefix} . '.pid' );
    my $manager = undef;
    my $daemon  = undef;
    my $env     = undef;
    my $user    = 'root';
    my $logfile = '/dev/null';

    GetOptions(
        'listen|l=s'  => \$listen,
        'nproc|n=i'   => \$nproc,
        'pidfile|p=s' => \$pidfile,
        'manager|M=s' => \$manager,
        'env|e=s'     => \$env,
        'user|u=s'    => \$user,
        'logfile|o=s' => \$logfile
    );

    $config->{listen}  = realpath($listen)  if ($listen);
    $config->{nproc}   = int $nproc         if ($nproc);
    $config->{pidfile} = realpath($pidfile) if ($pidfile);
    $config->{manager} = $manager           if ($manager);
    $config->{user}    = $user              if ($user);
    $config->{logfile} = realpath($logfile) if ($logfile);
    $config->{env}     = ($env) ? {
        map { split /:/ }
            split /,/ => $env
        }
        : {};

}

=head1 AUTHORS

=over 2

=item Toru Yamaguchi, C<< <zigorou at cpan.org> >>

Making this module.

=item Naoya Sano, C<< <sano at naoya.net> >>

Making init script template for FedoraCore, RedHat.

=item Daniel Burke

Supporting Debian, Ubuntu.

=back

=head1 THANKS

=over 2

=item Songhee Han

English translating.

=item LTjake

Bug reporting.

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-helper-fastcgi-externalserver at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Helper-FastCGI-ExternalServer>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Helper::FastCGI::ExternalServer

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Helper-FastCGI-ExternalServer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Helper-FastCGI-ExternalServer>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Helper-FastCGI-ExternalServer>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Helper-FastCGI-ExternalServer>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Toru Yamaguchi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::Helper::FastCGI::ExternalServer

__DATA__

__script__
#!/bin/bash
#
# [% script %] : [% appprefix %] fastcgi daemon start/stop script
#
# version : [% version %]
#
# chkconfig: 2345 84 16
# description: [% appprefix %] fastcgi daemon start/stop script
# processname: fcgi
# pidfile: [% pidfile %]
#
# [% date %] by [% author %]

# Load in the best success and failure functions we can find
if [ -f /etc/rc.d/init.d/functions ]; then
    . /etc/rc.d/init.d/functions
else
    # Else locally define the functions
    success() {
        echo -e "\n\t\t\t[ OK ]";
        return 0;
    }

    failure() {
        local error_code=$?
        echo -e "\n\t\t\t[ Failure ]";
        return $error_code
    }
fi

RETVAL=0
prog="[% appprefix %]"
[% UNLESS user == "root" %]SU=su
EXECUSER=[% user %][% END %]
EXECDIR=[% home %]
PID=[% pidfile %]
LOGFILE=[% logfile %]
PROCS=[% nproc %]
SOCKET=[% listen %]
[% IF (manager) %]MANAGER=[% manager %][% END %]

# your application environment variables
[% FOREACH item IN env %]export [% item.key %]="[% item.value %]"
[% END -%]

if [ -f "/etc/sysconfig/"$prog ]; then
  . "/etc/sysconfig/"$prog
fi

start() {
  if [ -f $PID ]; then
    echo "already running..."
      return 1
    fi
    # Start daemons.
    echo -n $"Starting [% app %]: "
    touch ${LOGFILE}
    echo -n "["`date +"%Y-%m-%d %H:%M:%S"`"] " >> ${LOGFILE}
    if [ "$USER"x != "$EXECUSER"x ]; then
      [% UNLESS user == "root" %]$SU -c "([% END -%]cd ${EXECDIR};script/[% fastcgi_script %] -n ${PROCS} -l ${SOCKET} -p ${PID} [% IF (manager) %]-m ${MANAGER} [% END %]-d >> ${LOGFILE} 2>&1[% UNLESS user == "root" %])" $EXECUSER [% END %]
    else
      cd ${EXECDIR}
      script/[% fastcgi_script %] -n ${PROCS} -l ${SOCKET} -p ${PID} [% IF (manager) %]-m ${MANAGER} [% END %]-d >> ${LOGFILE} 2>&1
    fi
    RETVAL=$?
    [ $RETVAL -eq 0 ] && success || failure $"$prog start"
    echo
    return $RETVAL
}

stop() {
  # Stop daemons.
  echo -n $"Shutting down [% app %]: "
  echo -n "["`date +"%Y-%m-%d %H:%M:%S"`"] " >> ${LOGFILE}
  /bin/kill `cat $PID 2>/dev/null ` >/dev/null 2>&1 && (success; echo "Stoped" >> ${LOGFILE} ) || (failure $"$prog stop";echo "Stop failed" >> ${LOGFILE} )
  /bin/rm $PID >/dev/null 2>&1
  RETVAL=$?
  echo
  return $RETVAL
}

status() {
  # show status
  if [ -f $PID ]; then
    echo "${prog} (pid `/bin/cat $PID`) is running..."
  else
    echo "${prog} is stopped"
  fi
  return $?
}

restart() {
  stop
  start
}

# See how we were called.
case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  status)
    status
    ;;
  *)
    echo $"Usage: $0 {start|stop|restart|status}"
    exit 1
esac
exit $?
