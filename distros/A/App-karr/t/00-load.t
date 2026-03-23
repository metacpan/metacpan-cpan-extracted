use strict;
use warnings;
use Test::More;

my @modules = qw(
  App::karr
  App::karr::Task
  App::karr::Config
  App::karr::BoardStore
  App::karr::Role::BoardAccess
  App::karr::Role::Output
  App::karr::Cmd::Init
  App::karr::Cmd::Create
  App::karr::Cmd::List
  App::karr::Cmd::Show
  App::karr::Cmd::Move
  App::karr::Cmd::Edit
  App::karr::Cmd::Delete
  App::karr::Cmd::Board
  App::karr::Cmd::Pick
  App::karr::Cmd::Archive
  App::karr::Cmd::Handoff
  App::karr::Cmd::Destroy
  App::karr::Cmd::AgentName
  App::karr::Cmd::Config
  App::karr::Cmd::Context
  App::karr::Cmd::Backup
  App::karr::Cmd::Restore
  App::karr::Cmd::Skill
  App::karr::Cmd::Log
  App::karr::Cmd::SetRefs
  App::karr::Cmd::GetRefs
);

for my $mod (@modules) {
  use_ok($mod);
}

done_testing;
