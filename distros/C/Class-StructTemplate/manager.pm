package manager;

use Class::Persistent::StructTemplate;

@manager::ISA = qw(Class::Persistent::StructTemplate);
attributes("Class::Persistent::Plugin::MySQL",["dbi:mysql:database=try;host=localhost","root","heeik0"],'name','user','passwd');

1;
