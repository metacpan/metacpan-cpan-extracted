use Test::More tests => 16;

BEGIN { require_ok ( 'ASNMTAP::Asnmtap::Applications::CGI' ) };

BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::CGI' ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::CGI', qw(:ALL) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::CGI', qw(:APPLICATIONS) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::CGI', qw(:COMMANDS) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::CGI', qw(:_HIDDEN) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::CGI', qw(:CGI) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::CGI', qw(:MEMBER) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::CGI', qw(:MODERATOR) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::CGI', qw(:ADMIN) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::CGI', qw(:SADMIN) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::CGI', qw(:DBPERFPARSE) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::CGI', qw(:DBREADONLY) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::CGI', qw(:DBREADWRITE) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::CGI', qw(:DBTABLES) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::CGI', qw(:REPORTS) ) };

# TODO: {
#   my $objectCGI = ASNMTAP::Asnmtap::Applications::CGI->new (
#     _programName        => 'CGI.t',
#     _programDescription => 'Test ASNMTAP::Asnmtap::Applications::CGI',
#     _programVersion     => '3.002.003',
#     _debug              => 0);
# 
#   isa_ok( $objectCGI, 'ASNMTAP::Asnmtap::Applications::CGI' );
#   can_ok( $objectCGI, qw(programName programDescription programVersion getOptionsArgv getOptionsValue debug dumpData printRevision printRevision printUsage printHelp) );
# }
