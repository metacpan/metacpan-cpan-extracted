package Apache::AuthChecker;

use Cwd;
use Config;
use Symbol;


# Apache 1.x
eval {
    require Apache;
    require mod_perl;
};
if ($@) {
    #mod_perl2, earlier
    eval {
	require Apache2;
        require mod_perl;
    };
    if ($@) {
        #mod_perl2, latest
    	eval {
        	require mod_perl2;
    	};
	if ($@) {
        	die "Can't find mod_perl installed: $@\n";
	}
    }
}


my $mp_ver = 1;
if ($mod_perl::VERSION >= 1.99) { 
    $mp_ver = 2;
}

my $more_inc = '';

my %common_opts = (
    'NAME'              => 'Apache::AuthChecker',
    'VERSION_FROM'      => 'AuthChecker.pm',
    'PREREQ_PM'         => { IPC::Shareable => 0.60 },
    'DEFINE'            => ''
);

if ($mp_ver == 1) {
    require ExtUtils::MakeMaker;
    require Apache::ExtUtils;
    require Apache::src;

    @directives = (
        {
        name => 'PerlAuthCheckerMaxUsers',
        errmsg => 'number of records to store in shared memory',
        args_how => 'TAKE1',
        req_override => 'RSRC_CONF'
        },
        {
        name => 'PerlSecondsToExpire',
        errmsg => 'seconds to remember IP address and AUTH attempts',
        args_how => 'TAKE1',
        req_override => 'RSRC_CONF'
        },
    );

    Apache::ExtUtils::command_table(\@directives);

    ExtUtils::MakeMaker::WriteMakefile(
        'LIBS'		=> [''],
        'INC'		=> Apache::src->new->inc,
        %common_opts
    );

} else {

eval {
    require ModPerl::MM
};
if ($@) {
    eval {
        require Apache2::ModPerl::MM
    };
    if ($@) {
        die "Can't find ModPerl::MM installed: $@\n";
    }
}

    $extra_inc = ModPerl::MM::get_def_opt('INC')."/modules/perl";

    if ($mod_perl::VERSION >= 2.000002) {
         $extra_inc .= " -I".ModPerl::MM::build_config('apr_includedir');
    }

    ModPerl::MM::WriteMakefile(
        %common_opts,
	INC => ModPerl::MM::get_def_opt('INC')." ". $extra_inc
    );
}


__END__


