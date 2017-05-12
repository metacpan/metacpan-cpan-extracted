require ClearCase::Argv;
# Argv->dbglevel(1);
ClearCase::Argv->ipc(2) unless exists $ARGV[0]
  and $ARGV[0] =~ /^(setview|(find)?merge)$/;
$ClearCase::Wrapper::MGi::lockbl = 1;
$ENV{FORCELOCK} = 'ClearCase::ForceLock';
# $ENV{CLEARCASE_TAB_SIZE} = 2;
# $ENV{CCMGI_ANNF} = '%Sd %25.-25Vn %-9.9u,|,%Sd %25.-25Vn %-9.9u';
# $ENV{CCMGI_ANNL} = 49;
# $ENV{FSCBROKER} = '/usr/bin/FSCbrokerSuDo';
