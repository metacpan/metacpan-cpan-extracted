#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "Class::Workflow::Transition";
use ok "Class::Workflow::Transition::Strict";
use ok "Class::Workflow::Transition::Validate";
use ok "Class::Workflow::Transition::Deterministic";

use ok "Class::Workflow::State";
use ok "Class::Workflow::State::AcceptHooks";
use ok "Class::Workflow::State::AutoApply";
use ok "Class::Workflow::State::TransitionSet";
use ok "Class::Workflow::State::TransitionHash";

use ok "Class::Workflow::Instance";

use ok "Class::Workflow::Transition::Validate::Simple";
use ok "Class::Workflow::Transition::Simple";
use ok "Class::Workflow::Instance::Simple";
use ok "Class::Workflow::State::Simple";

use ok "Class::Workflow::Context";

use ok "Class::Workflow";

