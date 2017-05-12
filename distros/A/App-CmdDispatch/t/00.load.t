use Test::More tests => 4;

BEGIN
{
    use_ok( 'App::CmdDispatch' );
}

note( "Testing App::CmdDispatch $App::CmdDispatch::VERSION" );

can_ok( 'App::CmdDispatch',     qw/new get_config run help hint command_hint shell/ );
can_ok( 'App::CmdDispatch::IO', qw/new print readline prompt/ );
can_ok( 'App::CmdDispatch::Table',
    qw/new run has_aliases get_alias get_command alias_list command_list/ );
