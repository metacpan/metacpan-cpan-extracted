package App::Mimosa::Test;
use strict;
use warnings;
use autodie qw/:all/;
use IPC::Cmd qw/can_run/;
use Test::More;
use File::Spec::Functions;
use App::Mimosa::Util qw/clean_up_indices/;

use base 'Exporter';
our @EXPORT = (
    # re-export subs from Catalyst::Test
    qw(
          action_notfound
          action_ok
          action_redirect
          content_like
          contenttype_is
          ctx_request
          get
          request
          app
    ),
  );

BEGIN {
    use Cwd;
    sub clean {
        map { clean_up_indices(getcwd, $_) } (glob(catfile(qw/t data *.seq/)));
    }
    clean();
}

END {
    clean();
}


# set things up for in-process testing only
BEGIN {
    delete $ENV{CATALYST_SERVER};
    delete $ENV{APP_MIMOSA_SERVER};

    # if it set before loading this module, the test file specified a non-default config file,
    # so we only set this if it is undefined
    $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} ||= 'testing';

}

BEGIN {
    unless (can_run('fastacmd')) {
        BAIL_OUT('fastacmd not available');
    }
}

# load the app, grab the context object so we can use it for configuration
use Catalyst::Test 'App::Mimosa';
my ( undef, $c ) = ctx_request('/nonexistent_url_for_t_lib_app_mimosa_test');
sub app { $c }

END {
    my $dsn = app->config->{"Model::BCS"}->{connect_info}->{dsn};
    my (undef,$test_db)   = split /=/, $dsn;
    # diag "unlink $test_db";
    { no autodie; unlink $test_db }
}

1;
