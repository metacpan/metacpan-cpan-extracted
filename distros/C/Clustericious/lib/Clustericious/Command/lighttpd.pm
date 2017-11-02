package Clustericious::Command::lighttpd;

use strict;
use warnings;
use Clustericious::Log;
use Clustericious::App;
use Clustericious::Config;
use base 'Clustericious::Command';
use File::Which qw( which );

# ABSTRACT: Clustericious command to stat lighttpd
our $VERSION = '1.27'; # VERSION


__PACKAGE__->attr(description => <<EOT);
Start a lighttpd web server.
EOT

__PACKAGE__->attr(usage => <<EOT);
Usage $0: lighttpd -f <config file> [...other lighttpd options]
Starts a lighttpd webserver.
Options are passed verbatim to the lighttpd executable.
EOT

sub run {
  my($self, @args) = @_;
  my $app_name = $ENV{MOJO_APP};

  my $lighttpd = which('lighttpd') or LOGDIE "could not find lighttpd in $ENV{PATH}";
  DEBUG "starting $lighttpd @args";
  system $lighttpd, @args;
  die "'$lighttpd @args' Failed to execute: $!" if $? == -1;
  die "'$lighttpd @args' Killed with signal: ", $? & 127 if $? & 127;
  die "'$lighttpd @args' Exited with ", $? >> 8 if $? >> 8;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Command::lighttpd - Clustericious command to stat lighttpd

=head1 VERSION

version 1.27

=head1 SYNOPSIS

 % yourapp start

=head1 DESCRIPTION

Start a lighttpd web server. The lighttpd start and stop commands recognize these options
in their configuration section:

=over 4

=item pid_file

The location to the pid file.  This should usually be the same as the C<PidFile> directive
in your lighttpd configuration.

=back

=head1 EXAMPLES

=head2 FCGI

See caveats below

 ---
 % my $root = dir "@{[ home ]}/var/run";
 % $root->mkpath(0,0700);
 % $root->subdir('document-root')->mkpath(0700);
 
 url: http://<%= $host %>:<%= $port %>
 start_mode: lighttpd
 
 lighttpd:
   args: -f <%= $root %>/lighttpd.<%= $port %>.conf
   pid_file: <%= $root %>/lighttpd.<%= $port %>.pid
   autogen:
     filename: <%= $root %>/lighttpd.<%= $port %>.conf
     content: |
       server.bind          = "<%= $host %>"
       server.port          = <%= $port %>
       server.document-root = "<%= $root %>/document-root"
       server.pid-file      = "<%= $root %>/lighttpd.<%= $port %>.pid"
       
       server.modules += ( "mod_fastcgi" )
       
       fastcgi.server = ("/" => ((
         "bin-path"            => "<%= $0 %> fastcgi",
         "check-local"         => "disable",
         "fix-root-scriptname" => "enable",
         "socket"              => "<%= $root %>/lighttpd.<%= $port %>.sock"
         ))
       )

=head1 CAVEATS

I was unable to get lighttpd to kill the FCGI processes and there are reports
(see L<http://redmine.lighttpd.net/issues/2137>) of the PID file it generates
disappearing.  Because of the former limitation, the lighttpd tests for
Clustericious are skipped by default (though they can be used by developers
willing to manually kill the FCGI processes).

Pull requests to Clustericious and / or documentation clarification would be
greatly appreciated if someone manages to get it to work better!

=head1 SEE ALSO

L<Clustericious>

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
