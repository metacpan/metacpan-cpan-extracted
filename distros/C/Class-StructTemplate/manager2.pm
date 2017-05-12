package manager2;

use Class::Persistent::StructTemplate;

@manager2::ISA = qw(Class::Persistent::StructTemplate);
attributes("Class::Persistent::Plugin::MySQL",["dbi:mysql:database=try;host=localhost","root","heeik0"],'name','user','passwd');

1;
