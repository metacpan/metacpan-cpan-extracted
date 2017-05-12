#!/bin/bin/perl
#
# Copyright (C) 2013 by Lieven Hollevoet

# This test runs basic module tests

use strict;
use Test::More;

BEGIN { use_ok 'App::CPRReporter'; }
BEGIN { use_ok 'Test::Exception'; }
BEGIN { use_ok 'Test::Warn'; }
require Test::Exception;
require Test::Warn;

# Check we get an error message on missing input parameters
my $reporter;

can_ok ('App::CPRReporter', qw(employees certificates run));

throws_ok { $reporter = App::CPRReporter->new() } qr/Attribute .+ is required/, "Checking missing parameters";
throws_ok { $reporter = App::CPRReporter->new(employees => 't/stim/missing_file.xlsx', certificates => 't/stim/missing_file.xml', course => 't/stim/missing_file.xlsx') } qr/File does not exist.+/, "Checking missing xml file";

# Check we get the expected carps when we create the app on the stimulus test data
#warnings_like { $reporter = App::CPRReporter->new(employees => 't/stim/employees.xlsx', certificates => 't/stim/certificates.xml', course => 't/stim/course.xlsx') }
#                { carped => qr/Oops: employee 'MAJOR LAZER' not found/},
#                "On test data we should carp some warnings";

$reporter = App::CPRReporter->new(employees => 't/stim/employees.xlsx', certificates => 't/stim/certificates.xml', course => 't/stim/course.xlsx');
is $reporter->{_not_in_hr}->{theory}->[0], 'MAJOR LAZER', "Found course of person not in employee database";

ok $reporter, 'object created';
ok $reporter->isa('App::CPRReporter'), 'and it is the right class';

# Check that only for users who followed a course the the course field exists
ok exists($reporter->{_employees}->{'CESAR ZJUUL'}->{course}), "Course field exists for user with data";
ok !exists($reporter->{_employees}->{'USER ONE'}->{course}), "Course field does not exist for users wihtout data";

$reporter->run();

done_testing();