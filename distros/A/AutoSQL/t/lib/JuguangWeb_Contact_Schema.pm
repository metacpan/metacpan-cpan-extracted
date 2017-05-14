package JuguangWeb_Contact_Schema;
use strict;
use AutoCode::Root;
use AutoSQL::Schema;
our @ISA=qw(AutoSQL::Schema);

# the primary key is fixed in format of '${tablename}_id"
my $tables = {
    
    person => {
        first_name => 'VARCHAR(255)',
        last_name => 'VARCHAR(255)'
    },
    email =>  {
        address => 'VARCHAR(255)',
        purpose => "ENUM('office', 'personal')",
        person => '!'
    }
};

# the type and the package are different.
# the type are the name identifier of the module, but not necessarily the package.
# the package may not be defined in the schema here.
# 
my $modules = {
    'DBObject' => {
        dbid =>'$',
        adaptor =>'$'
    },
    'Person' => {
        '@ISA' => 'DBObject',
        'first_name' => '$',
        'last_name' => '$',
        'emails' => '@'
    },
    'Email' => {
        '~required' => ['address'],
        '@ISA' => 'DBObject',
        'address' => '$',
        'purpose' => '$',
    },
};

my $module_tables = {
    'Person' => 'person',
    'Email' => 'email'
};

sub _initialize {
    my ($self, @args)=@_;
#    $self->throw("ContactSchema accepts no arguments, so far") if @args;
    
    
    push @args, -modules => $modules;
    push @args, -tables => $tables;
    push @args, -package_prefix => 'Contact';
    $self->SUPER::_initialize(@args);
}
1;
