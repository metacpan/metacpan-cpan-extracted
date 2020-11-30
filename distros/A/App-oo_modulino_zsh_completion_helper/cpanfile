requires 'perl', '5.010';

requires 'MOP4Import::Declare', '>= 0.052';

requires 'Module::Runtime';

on 'configure' => sub {
    requires 'Module::Build';
    requires 'Module::CPANfile';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'File::AddInc';
};

