package Apache::Log::Spread;

use ExtUtils::MakeMaker;

my $failed = 0;
eval "require Apache::ExtUtils";
if ($@) {
    warn "You need Apache::ExtUtils (mod_perl) to run this program: $@\n";
    $failed = 1;
}

eval {
    require Apache::src;
};
if ($@) {
    warn "You need Apache::src (mod_perl) to run this program: $@\n";
    $failed = 1;
} 
if($failed) {
    exit;
}

my @directives = (
        {       name             => 'MLS_LogFormat',
                errmsg           => 'A format string and a identifier',
                args_how         => 'TAKE2',
                req_override => 'RSRC_CONF'
        },
        {
                name             => 'MLS_Log',
                errmsg           => 'file|pipe|spread format [env]',
                args_how         => 'TAKE23',
                req_override => 'RSRC_CONF'
        },
        {
                name             => 'SpreadDaemon',
                errmsg           => 'port[@host]',
                args_how         => 'TAKE1',
                req_override => 'RSRC_CONF'
        }, );
          
Apache::ExtUtils::command_table(\@directives);

WriteMakefile(
    'NAME'		=> 'Apache::Log::Spread',
    'VERSION_FROM'	=> 'Spread.pm', 
    'PREREQ_PM'		=> {Spread => 0, 'Apache::ExtUtils' => 0, 'Apache::Util' => 0, 'Apache::ModuleConfig' => 0, 'Apache::Constants' => 0, 'DynaLoader' => 0,},
    'INC'   => Apache::src->new->inc,     
);
__END__
