use ClearCase::Argv;
ClearCase::Argv->attropts;
ClearCase::Argv->find(@ARGV, '-print')->exec;
