#----------------------------------------------------------------------------+
#
#  Apache2::WebApp::Helper::Kickstart - Command-line helper script
#
#  DESCRIPTION
#  Start-up an Apache process to test your application.
#
#  AUTHOR
#  Marc S. Brooks <mbrooks@cpan.org>
#
#  This module is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#----------------------------------------------------------------------------+

package Apache2::WebApp::Helper::Kickstart;

use strict;
use warnings;
use base 'Apache2::WebApp::Helper';
use Getopt::Long qw( :config pass_through );

our $VERSION = 0.04;

#~~~~~~~~~~~~~~~~~~~~~~~~~~[  OBJECT METHODS  ]~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#

#----------------------------------------------------------------------------+
# process()
#
# Based on command-line arguments, launch the project under Apache.

sub process {
    my $self = shift;

    my %opts;

    GetOptions (
        \%opts,
        'doc_root=s',
        'httpd_bin=s',
        'httpd_conf=s',
        'stop',
        'debug',
        'help',
        'verbose',
      );

    if ( $opts{help}     ||
        !$opts{doc_root} ) {

        print "\033[33mMissing or invalid options\033[0m\n\n";

        $self->help;
    }

    my $doc_root = $opts{doc_root};
    my $bin      = $opts{httpd_bin}  ||= '/usr/sbin/httpd';
    my $conf     = $opts{httpd_conf} ||= '/etc/httpd/conf/httpd.conf';
    my $debug    = $opts{debug};

    $self->error("\033[31m--doc_root selected is not valid\033[0m")
      unless (-d $doc_root);

    $self->error("\033[31m--httpd_bin selected is not valid\033[0m")
      unless (-f $bin && $bin =~ /\/httpd$/);

    sleep 1;

    if (-f "$doc_root/tmp/httpd.pid") {

        my $pid = `cat $doc_root/tmp/httpd.pid`;

        next unless ($pid =~ /\d+/);

        print "Stopping Apache:   \t\t\t\t\t   [ \033[32m OK \033[0m ]\n";

        kill('TERM', $pid)
          or print "Found httpd.pid but the Apache process does not exist.\n";

        unlink("$doc_root/tmp/httpd.pid")
          or $self->error("Cannot remove file: $!");
    }

    sleep 2;

    unless ( $opts{stop} ) {

        print "Starting Apache:   \t\t\t\t\t   [ \033[32m OK \033[0m ]\n";

        my $dflags = ($debug) ? '-e debug -X' : '';

        system(qq{ $bin -f $conf -c "Include $doc_root/conf/httpd.conf" $dflags })
          == 0
          or $self->error('Unable to start Apache process');
    }

    exit 0;
}

#----------------------------------------------------------------------------+
# help()
#
# Command-line argument help menu.

sub help {
    my $self = shift;

    print <<ERR_OUT;
Usage: webapp-kickstart [OPTION...]

WebApp::Helper::Kickstart - Start-up an Apache process to test your application.

 Options:

      --doc_root            Absolute path to your project

      --httpd_bin           Absolute path to the Apache binary (default: /usr/sbin/httpd)
      --httpd_conf          Absolute path to the Apache config (default: /etc/httpd/conf/httpd.conf)

      --stop                Terminate the Apache process

      --debug               Run httpd in debug mode.  Only one worker process will be started.

      --verbose             Print messages to STDOUT

Report bugs to <mbrooks\@cpan.org>
ERR_OUT

    exit;
}

1;

__END__

=head1 NAME

Apache2::WebApp::Helper::Kickstart - Command-line helper script

=head1 SYNOPSIS

  use Apache2::WebApp::Helper::Kickstart;

  my $obj = Apache2::WebApp::Helper::Kickstart->new;

  $obj->process;

=head1 DESCRIPTION

Start-up an Apache process to test your application.

=head1 COMMAND-LINE

  Usage: webapp-kickstart [OPTION...]

  WebApp::Helper::Kickstart - Start-up an Apache process to test your application

     Options:

         --doc_root            Absolute path to your project

         --httpd_bin           Absolute path to the Apache binary (default: /usr/sbin/httpd)
         --httpd_conf          Absolute path to the Apache config (default: /etc/httpd/conf/httpd.conf)

         --stop                Terminate the Apache process

         --debug               Run httpd in debug mode.  Only one worker process will be started.

         --verbose             Print messages to STDOUT

=head1 SEE ALSO

L<Apache2::WebApp>, L<Apache2::WebApp::Helper>, L<Getopt::Long>

=head1 AUTHOR

Marc S. Brooks, E<lt>mbrooks@cpan.orgE<gt> L<http://mbrooks.info>

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut
