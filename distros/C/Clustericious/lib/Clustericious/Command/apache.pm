package Clustericious::Command::apache;

use strict;
use warnings;
use Clustericious::App;
use base 'Clustericious::Command';
use File::Which qw( which );

# ABSTRACT: Clustericious command to stat Apache
our $VERSION = '1.26'; # VERSION


__PACKAGE__->attr(description => <<EOT);
Start an Apache web server.
EOT

__PACKAGE__->attr(usage => <<EOT);
Usage $0: Apache -f <conf> [...other Apache options]
Starts an Apache webserver.
Options are passed verbatim to the httpd executable.
EOT

sub run {
  my($self, @args) = @_;
  $self->app->init_logging;
  my $command = which('httpd') || die "unable to find apache";
  system $command, @args;
  die "'$command @args' Failed to execute: $!" if $? == -1;
  die "'$command @args' Killed with signal: ", $? & 127 if $? & 127;
  die "'$command @args' Exited with ", $? >> 8 if $? >> 8;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Command::apache - Clustericious command to stat Apache

=head1 VERSION

version 1.26

=head1 DESCRIPTION

Start an Apache web server.  The Apache start and stop commands recognize these options
in their configuration section:

=over 4

=item pid_file

The location to the pid file.  This should usually be the same as the C<PidFile> directive
in your Apache configuration.

=back

=head1 EXAMPLES

These examples are for Apache 2.4.  Getting them to work on Apache
2.2 will require some tweaking.

=head2 mod_proxy with hypnotoad

Create a apache24-proxy.conf:

 ---
 % my $root = dir "@{[ home ]}/var/run";
 % $root->mkpath(0,0700);
 
 url: http://<%= $host %>:<%= $port %>
 start_mode:
   - hypnotoad
   - apache
 
 apache:
   args: -f <%= $root %>/apache.<%= $port %>.conf -E <%= $root %>/apache.<%= $port %>.startup.log
   pid_file: <%= $root %>/apache.<%= $port %>.pid
   autogen:
     filename: <%= $root %>/apache.<%= $port %>.conf
     content: |
       LoadModule unixd_module      modules/mod_unixd.so
       LoadModule headers_module    modules/mod_headers.so
       LoadModule proxy_module      modules/mod_proxy.so
       LoadModule proxy_http_module modules/mod_proxy_http.so
       LoadModule authn_core_module modules/mod_authn_core.so
       LoadModule authz_core_module modules/mod_authz_core.so
       LoadModule authz_host_module modules/mod_authz_host.so
       LoadModule log_config_module modules/mod_log_config.so
       
       Listen <%= $host %>:<%= $port %>
       ServerName <%= $host %>
       PidFile <%= $root %>/apache.<%= $port %>.pid
       
       ErrorLog   <%= $root %>/apache.<%= $port %>.error.log
       LogFormat "%h %l %u %t \"%r\" %>s %b" common
       CustomLog  <%= $root %>/apache.<%= $port %>.access.log common
       
       <Location />
         ProxyPreserveHost On
         ProxyPass         http://localhost:<%= $port %>/
         ProxyPassReverse  http://localhost:<%= $port %>/
         RequestHeader append set X-Forward-Proto
         <RequireAll>
           Require all granted
         </RequireAll>
       </Location>
 
 hypnotoad:
   listen:
     - http://127.0.0.1:<%= $port %>
   pid_file: <%= $root %>/hypnotoad.<%= $port %>.pid

Note that this configuration binds hypnotoad to C<localhost> and
Apache to the IP that you pass in.  Then call from your application's
config file:

 ---
 # If hostname() (should be the same as what the command hostname
 # prints) is not a valid address that you can bind to, or if 
 # your hostname is the IP as localhost, then change the host to
 # a literal IP address
 % extend_config 'apache24-proxy', host => hostname(), port => 3001;

=head2 CGI

CGI is not recommends, for reasons that are hopefully obvious.  It does
allow you to run Clustericious from 

Create a apache24-cgi.conf:

 ---
 % my $root = dir "@{[ home ]}/var/run";
 % $root->mkpath(0,0700);
 
 url: http://<%= $host %>:<%= $port %>
 start_mode: apache
 
 apache:
   args: -f <%= $root %>/apache.<%= $port %>.conf -E <%= $root %>/apache.<%= $port %>.startup.log
   pid_file: <%= $root %>/apache.<%= $port %>.pid
   autogen:
     filename: <%= $root %>/apache.<%= $port %>.conf
     content: |
       LoadModule alias_module      modules/mod_alias.so
       LoadModule cgi_module        modules/mod_cgi.so
       LoadModule unixd_module      modules/mod_unixd.so
       LoadModule authn_core_module modules/mod_authn_core.so
       LoadModule authz_core_module modules/mod_authz_core.so
       LoadModule authz_host_module modules/mod_authz_host.so
       LoadModule env_module        modules/mod_env.so
       LoadModule log_config_module modules/mod_log_config.so
       
       Listen     <%= $host %>:<%= $port %>
       ServerName <%= $host %>
       PidFile    <%= $root %>/apache.<%= $port %>.pid
       
       ErrorLog   <%= $root %>/apache.<%= $port %>.error.log
       LogFormat "%h %l %u %t \"%r\" %>s %b" common
       CustomLog  <%= $root %>/apache.<%= $port %>.access.log common
       
       PassEnv PERL5LIB
       PassEnv HOME
       ScriptAlias / <%= $0 %>/
       
       <Directory <%= $0 %>/ >
         Options +ExecCGI
         SetHandler cgi-script
         <RequireAll>
           Require all granted
         </RequireAll>
       </Directory>
       

Then call from your application's config file:

 ---
 % extend_config 'apache24-cgi', host => 'localhost', port => 3001;

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
