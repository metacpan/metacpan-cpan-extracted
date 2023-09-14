#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw( no_plan );

use App::Oozie::Action::Deploy;
use App::Oozie::Action::Rerun;
use App::Oozie::Action::Run;
use App::Oozie::Action::UpdateCoord;
use App::Oozie::Compare::LocalToHDFS;
use App::Oozie::Constants;
use App::Oozie::Date;
use App::Oozie::Deploy::Template;
use App::Oozie::Deploy::Validate::DAG::Vertex;
use App::Oozie::Deploy::Validate::DAG::Workflow;
use App::Oozie::Deploy::Validate::Meta;
use App::Oozie::Deploy::Validate::Oozie;
use App::Oozie::Deploy::Validate::Spec::Bundle;
use App::Oozie::Deploy::Validate::Spec::Coordinator;
use App::Oozie::Deploy::Validate::Spec::Workflow;
use App::Oozie::Deploy::Validate::Spec;
use App::Oozie::Deploy;
use App::Oozie::Rerun;
use App::Oozie::Role::Fields::Common;
use App::Oozie::Role::Fields::Generic;
use App::Oozie::Role::Fields::Objects;
use App::Oozie::Role::Fields::Path;
use App::Oozie::Role::Git;
use App::Oozie::Role::Log;
use App::Oozie::Role::Meta;
use App::Oozie::Role::NameNode;
use App::Oozie::Run;
use App::Oozie::Serializer::Dummy;
use App::Oozie::Serializer::YAML;
use App::Oozie::Serializer;
use App::Oozie::Types::Common;
use App::Oozie::Types::DateTime;
use App::Oozie::Types::States;
use App::Oozie::Types::Workflow;
use App::Oozie::Update::Coordinator;
use App::Oozie::Util::Log4perl;
use App::Oozie::Util::Misc;
use App::Oozie::Util::Plugin;
use App::Oozie::XML;
use App::Oozie;

ok(1, 'Use ok');
