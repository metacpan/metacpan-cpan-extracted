package TestApp::Schema;
use strict;

use DBIx::DataModel;

DBIx::DataModel->Schema('TestApp::DM');
TestApp::DM->Table(qw/ TestApp::DM::Employee employee emp_id /);
TestApp::DM->Table(qw/ Department department dpt_id /);

1;
