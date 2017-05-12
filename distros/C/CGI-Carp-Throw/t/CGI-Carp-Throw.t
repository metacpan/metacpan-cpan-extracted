# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CGI-Carp-Throw.t'
# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use lib 't';
use RunThrowCGI;

use Test::More tests => 39;

#####################################################################
# Start of tests.
#####################################################################

BEGIN { use_ok('CGI::Carp::Throw') };

ok($RunThrowCGI::perl_path, "Found path to perl");

my $cgi_run = RunThrowCGI->new;

#####################################################################
$cgi_run->run_throw_cgi('throw_to_browser.cgi');
$cgi_run->ok_has_trace;
$cgi_run->ok_has_no_vis_trace;
ok( $cgi_run->wo_trace_comment =~ /\bquick\b.*\beasy\b/s,
    'No trace section has expected message ' . $cgi_run->script
);

#####################################################################
$cgi_run->run_throw_cgi('throw_to_browser_cl.cgi');
ok( $cgi_run->output_page !~ /\bat\b.*line\s+\d+/,
   'no trace message' . $cgi_run->script
);
ok( $cgi_run->wo_trace_comment =~ /\bquick\b.*\beasy\b/s,
    'No trace section has expected message ' . $cgi_run->script
);


#####################################################################
$cgi_run->run_throw_cgi('throw_to_browser_from_sub.cgi');
$cgi_run->ok_has_trace;
$cgi_run->ok_has_no_vis_trace;
ok( $cgi_run->wo_trace_comment =~ /\bquick\b.*\beasy\b/s,
    'No trace section has expected message ' . $cgi_run->script
);
ok( $cgi_run->trace_comment =~ /main::look_for_sub_in_trace\(/s,
    'trace includes calling sub ' . $cgi_run->script
);

#####################################################################
$cgi_run->run_throw_cgi('no_err.cgi');
ok( (not $cgi_run->has_trace) ,
    'no reason for error trace ' . $cgi_run->script
);
$cgi_run->ok_has_no_vis_trace;
ok( $cgi_run->output_page =~ /some\s+page/si ,
    'no reason for error trace ' . $cgi_run->script
);

#####################################################################
$cgi_run->run_throw_cgi('carp_to_browser.cgi');
ok( (not $cgi_run->has_trace) ,
    'Error tracing not handled by Throw module ' . $cgi_run->script
);
ok( (not $cgi_run->has_no_vis_trace) ,
    'Expecting tracing from CGI::Carp ' . $cgi_run->script
);
ok( $cgi_run->wo_trace_comment =~ /\bcroak\b.*\bat\b.*.*\bcarp_to_browser\b/s,
    'Verify correct message ' . $cgi_run->script
);

#####################################################################
$cgi_run->run_throw_cgi('carp_to_browser.cgi die=die');
ok( (not $cgi_run->has_trace) ,
    'Error tracing not handled by Throw module ' . $cgi_run->script
);
ok( (not $cgi_run->has_no_vis_trace) ,
    'Expecting tracing from CGI::Carp ' . $cgi_run->script
);
ok( $cgi_run->wo_trace_comment =~ /\bdie\b.*\bat\b.*.*\bcarp_to_browser\b/s,
    'Verify correct message ' . $cgi_run->script
);

#####################################################################
$cgi_run->run_throw_cgi('carp_to_browser.cgi die=spaz');
ok( (not $cgi_run->has_trace) ,
    'Error tracing not handled by Throw module ' . $cgi_run->script
);
ok( (not $cgi_run->has_no_vis_trace) ,
    'Expecting tracing from CGI::Carp ' . $cgi_run->script
);
ok( $cgi_run->wo_trace_comment =~ /\bspaz\b.*\bat\b.*.*\bcarp_to_browser\b/s,
    'Verify correct message ' . $cgi_run->script
);



#####################################################################
SKIP :{
    eval {require HTML::Template};
    skip('Tests require HTML::Template', 3) if ($@);
    $cgi_run->run_throw_cgi('../examples/example2.cgi');
    $cgi_run->ok_has_trace;
    $cgi_run->ok_has_no_vis_trace;
    ok( $cgi_run->wo_trace_comment =~ /style="color: red/s,
        'Included styling from template ' . $cgi_run->script
    );
};

#####################################################################
$cgi_run->run_throw_cgi_w_err('just_cluck.cgi');
ok( (not $cgi_run->has_trace) ,
    'no reason for error trace ' . $cgi_run->script
);
$cgi_run->ok_has_no_vis_trace;
ok( $cgi_run->output_page =~ /some\s+page/si ,
    'no reason for error trace ' . $cgi_run->script
);
ok( $cgi_run->err_output =~ /\bsomething_for_cluck_to_trace\b/si ,
    'Found cluck warning in stderr ' . $cgi_run->script
);

#####################################################################
$cgi_run->run_throw_cgi_w_err('carp_wo_browser.cgi');
ok( (not $cgi_run->has_trace) ,
    'Error tracing not handled by Throw module ' . $cgi_run->script
);
ok( $cgi_run->has_no_vis_trace,
    'No tracing to browser from CGI::Carp ' . $cgi_run->script
);
ok( $cgi_run->err_output =~ /\bcroak\b.*\bat\b.*.*\bcarp_wo_browser\b/s,
    'Verify correct log message ' . $cgi_run->script
);

#####################################################################
$cgi_run->run_throw_cgi_w_err('carp_wo_browser.cgi die=die');
ok( (not $cgi_run->has_trace) ,
    'Error tracing not handled by Throw module ' . $cgi_run->script
);
ok( $cgi_run->has_no_vis_trace,
    'No tracing to browser from CGI::Carp ' . $cgi_run->script
);
ok( $cgi_run->err_output =~ /\bdie\b.*\bat\b.*.*\bcarp_wo_browser\b/s,
    'Verify correct log message ' . $cgi_run->script
);

#####################################################################
$cgi_run->run_throw_cgi('carp_wo_browser.cgi die=throw');
$cgi_run->ok_has_trace;
$cgi_run->ok_has_no_vis_trace;
ok( $cgi_run->wo_trace_comment =~ /just a browser message/s,
    'No trace section has expected message ' . $cgi_run->script
);
