package Apache::MultiAuth;

# ----------------------------------------------------------------------
# Apache::MultiAuth
# ----------------------------------------------------------------------
# Stathy G. Touloumis
# Marcel M. Weber
# Darren Chamberlain
#
# Version 0.01 / 13.02.2002 / Marcel M. Weber
# Version 0.04 / 16.02.2002 / Darren Chamberlain
# Version 0.05 / 18.02.2002 / Marcel M. Weber
# Version 0.06 / 04.03.2002 / Darren Chamberlain
# ----------------------------------------------------------------------

use strict;
use vars qw($VERSION $DUMP_AUTH_MODULES);

use Apache::Constants qw(:common);
use Apache::ModuleConfig ();

use File::Spec ();
use DynaLoader ();

$VERSION = 0.06;
$DUMP_AUTH_MODULES = 0 unless defined $DUMP_AUTH_MODULES;

use base qw(DynaLoader);

if ($ENV{MOD_PERL}) {
    no strict;
    __PACKAGE__->bootstrap($VERSION);
}

sub handler {
    my $r = shift;

    my($res, $sent_pw) = $r->get_basic_auth_pw;
    return $res if $res != OK;

    #
    # Retrieve the list of auth modules from the module configuration
    #
    my @auth_modules;
    if (my $cfg = Apache::ModuleConfig->get($r)) {
        @auth_modules = @{$cfg->{AuthModules}} if $cfg->{AuthModules};
        
        if ($DUMP_AUTH_MODULES) {
            local $" = "', '";
            $r->warn("Registered AuthModules: '@auth_modules'");
        }
    }

    #
    # Iterate through them, short-circuiting when one returns OK
    #
    for my $am (@auth_modules) {
        load($am);

        if ($@) {
            $r->log_error("Error loading module '$am': $@");
            next;
        }

        my $handler = $am->can('handler') or next;
        if ($handler->($r) == OK) {
            $r->warn("$am returned OK");
            $r->notes("AuthenticatedBy", $am);
            return OK
        }

        $r->log_reason("$am did not return OK");
    }

    $r->note_basic_auth_failure;
    return AUTH_REQUIRED;
}

sub AuthModule($$@) {
    my ($cfg, $parms, $module) = @_;
    my $auth_modules = $cfg->{AuthModules} ||= [];
    push @{$auth_modules}, $module;
}

sub DumpAuthModules($$$) {
    my ($cfg, $parms, $dump) = @_;
    $DUMP_AUTH_MODULES = $dump;
}

sub DIR_MERGE {
    warn "\n\nCalled DIR_MERGE!";
    my ($parent, $current) = @_;
    my %uniq;
    my @auth_modules = grep { ++$uniq{$_} == 1 }
                        (@{$parent->{AuthModules}},
                         @{$current->{AuthModules}});
    my $new = { AuthModules => \@auth_modules };
    return bless $new, ref $parent;
}

sub load {
    my $module = shift;

    $module = File::Spec->catfile(split /::/, $module);
    $module .= '.pm';

    eval { require $module; };

    return $@ ? 1 : 0;
}

1;

__END__

=head1 NAME

Apache::MultiAuth - Choose from a number of authentication modules at runtime

=head1 SYNOPSIS

Put lines like this in your httpd.conf. In this example authorization is requested
for accessing the directory /test. First the credentials (username, password) are 
checked against the module Apache::AuthSybase and then against the module 
Apache::AuthenSmb. If any of them succeeds, access to /test is granted. 

  # in httpd.conf
  # Important : if not set apachectl configtest will complain about syntax errors
 
  PerlModule  Apache::MultiAuth

  <Location /test>
    AuthName Test 
    AuthType Basic

    # PerlSetVars for various Apache::Auth* modules
    # These here are example values for Apache::AuthenSmb
    PerlSetVar myPDC SAMBA
    PerlSetVar myDOMAIN ARBEITSGRUPPE

    # Define order and class of Auth modules to try
    AuthModule Apache::AuthSybase Apache::AuthenSmb

    PerlAuthenHandler Apache::MultiAuth
    require valid-user
  </Location>

=head1 DESCRIPTION

Apache::MultiAuth allows you to specify multiple authentication
modules, to be tried in order.  If any module in the list returns OK,
then the user is considered authenticated; if none return OK, then the
MultiAuth module returns AUTH_REQUIRED and the user is reprompted for 
credentials. This, depending on the browser, results in a 401 authorization
required message.

This is useful for cases where, for example, you have several
authentication schemes:  for example, NIS, SMB, and htpasswd, and some
of your users are only registered in some of the auth databases.
Using Apache::MultiAuth, they can be queried in order until the right
one is found.

In the event that one of these modules returns OK, a note named
"AuthenticatedBy" will be set, which contains the name of the module
that returned OK, like so:

    $r->notes("AuthenticatedBy" => "Module::Name");

This can be retrieved by any handler that runs after the authentication
phase, and can be very useful in logging:

    CustomLog "%h %l %u %t \"%r\" %>s %b %{AuthenticatedBy}n" common_auth

The last field in the common_auth log format will be the name of the module 
that handled the authentication.

=head1 CONFIGURATION DIRECTIVES

Apache::MultiAuth allows you to name a number of authentication
modules, using the AuthModule directive.  These modules are queried,
in the order they are provided, until one of them returns OK.
Apache::MultiAuth then condiders authentication to be successful, and
processing continues. If none of the provided authentication modules 
returns OK, Apache::MultiAuth passes AUTH_REQUIRED to apache, which
results in a 401 Authorization required error.

=head1 AUTHORS

    Stathy G. Touloumis
    Marcel M. Weber
    Darren Chamberlain
