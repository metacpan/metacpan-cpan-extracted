use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'AgentPushKit::Client',
  VERSION_FROM => 'lib/AgentPushKit/Client.pm',
  ABSTRACT => 'Official Perl client for Agent Push Kit',
  AUTHOR => 'Justin Strong <JustinBStrong@users.noreply.github.com>',
  LICENSE => 'mit',
  META_MERGE => { resources => { homepage => 'https://agentpushkit.com', repository => { type => 'git', url => 'https://github.com/JustinBStrong/agent-push-kit-perl.git', web => 'https://github.com/JustinBStrong/agent-push-kit-perl' }, bugtracker => { web => 'https://github.com/JustinBStrong/agent-push-kit-perl/issues' } } },
  PREREQ_PM => { 'Class::Accessor' => 0, 'DateTime' => 0, 'JSON' => 2.00, 'Log::Any' => 0, 'LWP::Protocol::https' => 0, 'LWP::UserAgent' => 0, 'Module::Find' => 0, 'Module::Runtime' => 0, 'Moose::Role' => 0, 'URI::Query' => 0 },
  TEST_REQUIRES => { 'Test::Exception' => 0, 'Test::More' => 0 },
);
