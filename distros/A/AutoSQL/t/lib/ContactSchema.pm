package ContactSchema;
use strict;
use AutoCode::Root;
use AutoSQL::Schema;
our @ISA=qw(AutoSQL::Schema);

# the type and the package are different.
# the type are the name identifier of the module, but not necessarily the package.
# the package may not be defined in the schema here.
# 
my $modules = {
    'DBObject' => {
        '$tablized' => -1,
#        dbID =>'$i^3u!',
        adaptor =>'$ObjectAdaptor'
    },
    'Person' => {
#        '@ISA' => 'DBObject',
        '$Import_ISA' => 1,
        first_name => '$',
        last_name => '$',
        alias =>'@', # array slot
        nric => '$NRIC', # scalar child
        email => '@Email'    # array child
    },
    'Email' => {
#        '@ISA' => 'DBObject',
        address => '$!',
        purpose => '$',
    },
    NRIC => {
        no => '$',
        issued_date => '$t'
    },
    ContactGroup => { name => '$' }, # !!!! group is the key words of sql!!!
    '~friends' => {
        'Person-ContactGroup' => 'rank:I;',
#        'Movie-Star' => undef
    }
};

our $modules_type_grouped = {
    Location=>{
        '$' => [qw(city state country)]
    }
};

my $module_tables = {
    'Person' => 'person',
    'Email' => 'email'
};

my $plurals = {
    alias => 'aliases'
};

sub _initialize {
    my ($self, @args)=@_;
#    $self->throw("ContactSchema accepts no arguments, so far") if @args;
    
    
    push @args, -modules => $modules;
    push @args, -modules_type_grouped => $modules_type_grouped;
#    push @args, -tables => $tables;
    push @args, -package_prefix => 'JuguangWeb::Contact';
    push @args, -plurals => $plurals;
    $self->SUPER::_initialize(@args);
}
1;
