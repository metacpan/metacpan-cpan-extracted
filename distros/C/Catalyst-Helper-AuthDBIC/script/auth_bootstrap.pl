#!/usr/bin/env perl
use warnings;
use strict;
use Catalyst::Helper::AuthDBIC;
use Pod::Usage;

=head1 NAME

auth_bootstrap.pl

=head1 SYNOPSIS

 auth-bootstrap.pl  -credential (http|password)

Boostrap simple database backed authentication for a Catalyst
application.  The store argument is optional and defaults to http
(basic) authentication.  Use of the password option provides some
basic html templates and (buggy - patches welcome) pass through login.

Once you're done running this script, add a user with the
script/myapp_auth_admin.pl command (run myapp_auth_admin.pl -help for
instructions), and then add some code to one of your controllers.  For
example to require application wide authentication add the following
to your Controller::Root :



=cut


use Getopt::Long;

my $credential = '';
my $help = undef;

GetOptions ( "credential=s" => \$credential,
         help => \$help);

pod2usage(1) if ( $help || !$credential );

if  ($credential !~ /^(http|password)$/) {
    die "Valid credentials are 'http' for basic auth or 'password' for web based auth";
}

Catalyst::Helper::AuthDBIC::make_model();
Catalyst::Helper::AuthDBIC::mk_auth_controller() if $credential eq 'password';
Catalyst::Helper::AuthDBIC::add_plugins();
Catalyst::Helper::AuthDBIC::add_config($credential);
Catalyst::Helper::AuthDBIC::write_templates() if $credential eq 'password';
Catalyst::Helper::AuthDBIC::update_makefile();
Catalyst::Helper::AuthDBIC::add_user_helper();
