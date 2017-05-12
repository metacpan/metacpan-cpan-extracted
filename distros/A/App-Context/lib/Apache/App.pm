
#############################################################################
## $Id: App.pm 3666 2006-03-11 20:34:10Z spadkins $
#############################################################################
## Note: Much of this code is borrowed from Apache::DBI
##       In doing so, I have made a half-hearted attempt to make this mod_perl 1.X compatible.
##       However, I have never run it on mod_perl 1.X, only on mod_perl 2.X.
##       When someone debugs this on mod_perl 1.X, please let me know what you had to do to make it work.
#############################################################################

package Apache::App;
$VERSION = (q$Revision: 3666 $ =~ /(\d[\d\.]*)/)[0];
use strict;

use constant MP2 => (exists $ENV{MOD_PERL_API_VERSION} &&
                            $ENV{MOD_PERL_API_VERSION} == 2) ? 1 : 0;

BEGIN {
    if (MP2) {
        require mod_perl2;
        require Apache2::Module;
        require Apache2::RequestUtil;
        require Apache2::ServerUtil;
        require Apache2::Const;
        require Apache::DBI;

        my $s = Apache2::ServerUtil->server;
        $s->push_handlers(PerlChildInitHandler => \&child_init_handler);
        $s->push_handlers(PerlChildExitHandler => \&child_exit_handler);
        $s->push_handlers(PerlCleanupHandler   => \&request_cleanup_handler);
    }
    elsif (defined $modperl::VERSION && $modperl::VERSION > 1 && $modperl::VERSION < 1.99) {
        require Apache;
        require Apache::DBI;

        Carp::carp("Apache.pm was not loaded\n")
              and return unless $INC{'Apache.pm'};
        if (Apache->can('push_handlers')) {
            Apache->push_handlers(PerlChildInitHandler => \&child_init_handler);
            Apache->push_handlers(PerlChildExitHandler => \&child_exit_handler);
            Apache->push_handlers(PerlCleanupHandler   => \&request_cleanup_handler);
        }
    }
}

use Carp ();
use App;

my (@service_on_init);             # services to be initialized when a new httpd child is created
my %env = %ENV;
my ($context);

#############################################################################
# This is supposed to be called in a startup script.
# stores the data_source of all connections, which are supposed to be created
# upon server startup, and creates a PerlChildInitHandler, which initiates
# the connections.  Provide a handler which creates all connections during
# server startup
#############################################################################

sub init_service_on_child_init {
    my (@args) = @_;
    shift(@args);                    # get rid of class name
    push(@service_on_init, [@args]);
}

######################################################################################
# PerlChildInitHandler : runs during child server startup.
######################################################################################
# Note: this handler runs in every child server, but not in the main server.
######################################################################################

sub child_init_handler {
    my ($child_pool, $s) = @_;
    warn("$$ Apache::App child_init\n");

    #my $context = App->context();
    #if (@service_on_init) {
    #    for my $service_init_args (@service_on_init) {
    #        $context->service(@$service_init_args);
    #    }
    #}

    return 1; # (MP2 ? Apache2::Const::OK : Apache::OK);
}

######################################################################################
# PerlChildExitHandler : runs during child server shutdown.
######################################################################################

sub child_exit_handler {
    my ($child_pool, $s) = @_;
    warn("$$ Apache::App child_exit\n");
    return 1; # (MP2 ? Apache2::Const::OK : Apache::OK);
}

######################################################################################
# PerlCleanupHandler : runs after the response has been sent to the client
######################################################################################

sub request_cleanup_handler {
    warn("$$ Apache::App request_cleanup\n");
#    my $Idx = shift;
#
#    my $prefix = "$$ Apache::DBI            ";
#    debug(2, "$prefix PerlCleanupHandler");
#
#    my $dbh = $Connected{$Idx};
#    if ($Rollback{$Idx}
#        and $dbh 
#        and $dbh->{Active}
#        and !$dbh->{AutoCommit}
#        and eval {$dbh->rollback}) {
#        debug (2, "$prefix PerlCleanupHandler rollback for '$Idx'");
#    }
#
#    delete $Rollback{$Idx};
#
    1;
}

######################################################################################
# Response Handler
######################################################################################

sub handler {
    my $r = shift;

    if ($ENV{PATH_INFO} eq "/_info") {
        &info($r);
        return;
    }

    my ($msg, $response);

    # INITIALIZE THE CONTEXT THE FIRST TIME THIS APACHE CHILD PROCESS
    # RECEIVES A REQUEST (should I do this sooner? at child init?)
    # (so that the first request does not need to bear the extra burden)

    # Also, the App class would cache the $context for me
    # if I didn't want to cache it myself. But then I would have to 
    # prepare the %options every request. hmmm...
    # I don't suppose the $r->dir_config() call is expensive.

    if (!defined $context) {
        my %options = %{$r->dir_config()};
        $options{context_class} = "App::Context::ModPerl" if (!defined $options{context_class});
        eval {
            $context = App->context(\%options);
        };
        $msg = $@ if ($@);
    }

    if ($ENV{PATH_INFO} eq "/_context") {
        my $header = <<EOF;
Content-type: text/plain

App::Context::ModPerl - Context

EOF
        $r->print($header);
        $r->print($context->dump());
        return;
    }
    elsif ($ENV{PATH_INFO} eq "/_session") {
        my $header = <<EOF;
Content-type: text/plain

App::Context::ModPerl - Session

EOF
        $r->print($header);
        $r->print($context->{session}->dump());
        return;
    }
    elsif ($ENV{PATH_INFO} eq "/_conf") {
        my $header = <<EOF;
Content-type: text/plain

App::Context::ModPerl - Conf

EOF
        $r->print($header);
        $r->print($context->{conf}->dump());
        return;
    }
    elsif ($ENV{PATH_INFO} eq "/_options") {
        my $header = <<EOF;
Content-type: text/plain

App::Context::ModPerl - Options

EOF
        $r->print($header);
        my $options = $context->{options} || {};
        foreach my $key (sort keys %$options) {
            $r->print("$key = $options->{$key}\n");
        }
        return;
    }

    # this should always be true
    if (defined $context) {
        # the response will be emitted from within dispatch_events()
        $context->dispatch_events();
    }
    else {
        # we had an error (maybe App-Context not installed? Perl @INC not set?)
        $response = <<EOF;
Content-type: text/plain

Unable to create an App::Context.
$msg

EOF
        $r->print($response);
    }
}

######################################################################################
# Special URL-driven Responses
######################################################################################

sub info {
    my $r = shift;
    my $header = <<EOF;
Content-type: text/plain

Welcome to Apache::App

EOF
    $r->print($header);
    print $r->as_string();
    $r->print("\n");
    $r->print("ENVIRONMENT VARIABLES\n");
    $r->print("\n");
    foreach my $var (sort keys %ENV) {
        $r->print("$var=$ENV{$var}\n");
    }
    $r->print("\n");
    $r->print("ENVIRONMENT VARIABLES (at startup)\n");
    $r->print("\n");
    foreach my $var (sort keys %env) {
        $r->print("$var=$env{$var}\n");
    }
    $r->print("\n");
    $r->print("DIRECTORY CONFIG\n");
    $r->print("\n");
    my %options = %{$r->dir_config()};
    foreach my $var (sort keys %options) {
        $r->print("$var=$options{$var}\n");
    }
}

# prepare menu item for Apache::Status
#sub status_function {
#    my($r, $q) = @_;
#
#    my(@s) = qw(<TABLE><TR><TD>Datasource</TD><TD>Username</TD></TR>);
#    for (1 .. 5) {
#        push @s, '<TR><TD>',
#            join('</TD><TD>',
#                 ($_, "tbd"), "</TD></TR>\n";
#    }
#    push @s, '</TABLE>';
#
#    \@s;
#}

#if (MP2) {
#    if (Apache2::Module::loaded('Apache2::Status')) {
#	    Apache2::Status->menu_item(
#                                   'DBI' => 'DBI connections',
#                                    \&status_function
#                                  );
#    }
#}
#else {
#   if ($INC{'Apache.pm'}                       # is Apache.pm loaded?
#       and Apache->can('module')               # really?
#       and Apache->module('Apache::Status')) { # Apache::Status too?
#       Apache::Status->menu_item(
#                                'DBI' => 'DBI connections',
#                                \&status_function
#                                );
#   }
#}

1;

