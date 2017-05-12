package Apache::AuthenURL::Cache;

use strict;

use mod_perl2;
use Apache2::Log;
use Apache2::Status;
use Apache2::Access;
use Apache2::Const -compile => qw(HTTP_UNAUTHORIZED OK DECLINED DONE);
use Apache2::Module;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use APR::Table;

use Cache::SharedMemoryCache;
use Date::Format;

use vars qw($VERSION);

my $prefix = "Apache::AuthenURL::Cache";
$VERSION = '2.05';

my(%ConfigDefaults) = (
    AuthenCache_Encrypted => 'on',
    AuthenCache_CacheTime => 'never',
    AuthenCache_NoPasswd => 'off',
);


sub handler {
    my($r) = @_;
 
    my($status, $password) = $r->get_basic_auth_pw;

    return Apache2::Const::OK unless $r->is_initial_req;
 
    return $status unless ($status == Apache2::Const::OK);

    my $auth_name = $r->auth_name;

    my $attribute = {};
    while(my($key, $value) = each %ConfigDefaults) {
        $value = $r->dir_config($key) || $value;
        $key =~ s/^AuthenCache_//;
        $attribute->{$key} = lc $value;
    }

    my $cache = new Cache::SharedMemoryCache(
        { namespace => $auth_name },
        default_expires_in => $attribute->{CacheTime},
    );

    my $user = $r->user;
    
    if (my $cached_password = $cache->get($user)) {
        $r->log->debug($prefix, "::handler: using cached password for $user");

        if (length($password) == 0 and $attribute->{NoPasswd} eq 'off') {
            $r->log->debug($prefix, "::handler: no password sent, failing");
            $r->note_basic_auth_failure;
            return Apache2::Const::HTTP_UNAUTHORIZED;
        }
            
        if ($attribute->{Encrypted} eq 'on') {
            $r->log->debug($prefix, "::handler: encrypt password for check");
            my $salt = substr($cached_password, 0, 2);
            $password = crypt($password, $salt);
        }

        if ($password eq $cached_password) {
            $r->log->debug($prefix, "::handler: passwords match");
            return Apache2::Const::OK;
        }
        else {
            $r->note_basic_auth_failure;
            return Apache2::Const::HTTP_UNAUTHORIZED;
        }
    }
    $r->push_handlers(PerlFixupHandler => \&manage_cache);
    return Apache2::Const::DECLINED;
}

sub manage_cache {
    my($r) = @_;

    my($status, $password) = $r->get_basic_auth_pw;

    my $attribute = {};
    while(my($key, $value) = each %ConfigDefaults) {
        $value = $r->dir_config($key) || $value;
        $key =~ s/^AuthenCache_//;
        $attribute->{$key} = $value;
    }

    my $user = $r->user;

    my $auth_name = $r->auth_name;

    if ($attribute->{Encrypted} eq 'on') {
        $r->log->debug($prefix, "::manage_cache: encrypt password for storage");
        my @alphabet = ('a' .. 'z', 'A' .. 'Z', '0' .. '9', '.', '/');
        my $salt = join ('', @alphabet[rand (64), rand (64)]);
        $password = crypt($password, $salt);
    }

    my $cache = new Cache::SharedMemoryCache(
        { namespace => $auth_name },
        default_expires_in => $attribute->{CacheTime},
    );

    $cache->purge;

    $cache->set($user, $password, $attribute->{CacheTime});

    $r->log->debug($prefix, "::manage_cache: storing user:", $user);

    return Apache2::Const::OK;
}

Apache2::Status->menu_item(
    $prefix => "Authentication Cache",
    sub {
        my $caches = new Cache::SharedMemoryCache;
        my(@s) = "<TABLE BORDER=1>";
        foreach my $namespace ($caches->get_namespaces) {
            my $cache = new Cache::SharedMemoryCache({namespace => $namespace});
            push @s, "<TR><TH>$namespace</TH></TR>";
            push @s, "<TR><TD><TABLE BORDER=1>";
            push @s, "<TR><TH>Username</TH><TH>Created At</TH><TH>Expires At</TH></TR>";
            foreach my $username ($cache->get_keys) {
                my $user = $cache->get_object($username);
                my $created_at = ctime $user->get_created_at;
                my $expires_at = ($user->get_expires_at eq "never") ? "NEVER" :
                                 ctime $user->get_expires_at;
                push @s, "<TR><TD>$username</TD><TD>", $created_at,
                         "</TD><TD>", $expires_at, "</TD></TR>";
            }
            push @s, "</TD></TR></TABLE>";
        }
        push @s, "</TABLE>";
        return \@s;
    },
) if Apache2::Module::loaded('Apache2::Status');

1;

__END__

=head1 NAME

Apache::AuthenURL::Cache - Authentication caching used in conjuction
with a primary authentication module (eg Apache::AuthenURL) and
mod_perl2

=head1 SYNOPSIS

 # In your httpd.conf
 PerlModule Apache::AuthenURL::Cache

 # In httpd.conf or .htaccess:
 AuthName Name
 AuthType Basic

 PerlAuthenHandler Apache::AuthenURL::Cache <Primary Authentication Module>
 
 require valid-user

 # Optional parameters
 PerlSetVar AuthenCache_CacheTime     900 # Default: indefinite
 PerlSetVar AuthenCache_Encrypted     Off # Default: On
 PerlSetVar AuthenCache_NoPasswd      Off # Default: Off

=head1 DESCRIPTION

B<Apache::AuthenURL::Cache> implements a caching mechanism in order to
speed up authentication and to reduce the usage of system
resources. It must be used in conjunction with a regular mod_perl2
authentication module.

It was designed with Apache::AuthenURL in mind, but it can be used with
other modules.

The module makes use of mod_perl2 stacked handlers.

=head1 CONFIGURATION OPTIONS

The following variables can be defined within the configuration
of Directory, Location, or Files blocks or within .htaccess
files:

=over

=item B<AuthenCache_CacheTime>

This directive contains the number of seconds before the cache is
expired. Default is an indefinite time limit.

=item B<AuthenCache_Encrypted>
 
If this directive is set to 'Off', passwords are not encrypted.
Default is 'On', ie passwords use standard Unix crypt.
 
=back

=item B<AuthenCache_NoPasswd>
 
If this directive is set to 'On', passwords may be zero length.
Default is 'Off', ie passwords may not be zero length.
 
=back

=head1 PREREQUISITES

mod_perl2, Cache::SharedMemoryCache, Date::Format

=head1 CREDITS

This module is a rewrite for mod_perl2 of Apache::AuthenCache
written by Jason Bodnar and later maintained by Christian Gilmore

=head1 AUTHORS

John Groenveld <groenveld@acm.org>

=head1 COPYRIGHT

Copyright (C) 2004, John Groenveld

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
