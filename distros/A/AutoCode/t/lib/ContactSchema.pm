package ContactSchema;
use strict;
use AutoCode::Schema;
our @ISA=qw(AutoCode::Schema);

our $modules= {
    DBObject=>{
#        dbid =>'$I+10',
#        
        adaptor =>'$'
    },
    Person => {
        '@ISA' => 'DBObject',
        first_name => '$!',
        last_name => '$!',
        birthday => '$T2', 
        alias => '@',
        nric => '$NRIC',
        email => '@Email',
    },
    Buddy=>{
        '@ISA'=>'Person',
        home_address => '$',
    },
    NRIC => { # National Registration Identity Card, Singapore-style.
        no => '$',
        issue_date => '$'
    },
    Email => {
        '~required' => ['address'],
        '@ISA' => 'DBObject',
        address => '$V200!',
        purpose => '${office, personal}'
    },
    ContactGroup => { name => '$' },
    '~friends'=>{
        'Person-ContactGroup' => 'rank:I;',
    }
};

our $plurals = {
    alias => 'aliases'
};

sub _initialize {
    my ($self, @args)=@_;
#    $self->throw("ContactSchema accepts no arguments, so far") if @args;
    
    push @args, -modules => $modules;
    push @args, -plurals => $plurals;
    $self->SUPER::_initialize(@args);
} 
1;

__END__

=head1 NAME

ContactSchema - an example to use AutoSQL system

=head1 SYNOPSIS

  use ContactSchema;
  use AutoSQL::ObjectFactory;

  my $factory = AutoSQL::ObjectFactory->new(
    -schema => ContactSchema->new
  );

  my $person = $factory->get_instance('Person', 
    -first_name => 'Juguang',
    -last_name => 'XIAO',
    -emails => []
  );

  print $person->first_name, "\t", $person->last_name, "\n";

=head1 DESCRIPTION

This is an example module to use AutoSQL system.

=head1 HOW TO WRITE SUCH CUSTOMIZED SCHEMA MODULE

For AutoCode system, here is the template to write schema.

1) 'our @ISA=(AutoCode::Schema);'
2) defined 'our $modules' according to AutoCode specification
3) copy the below code

sub _initialize {
    my ($self, @args)=@_;
    push @args, -modules => $modules;
    $self->SUPER::_initialize(@args);
}

4) Note: You do not need to override the constructor.

=head1 AUTHOR

Juguang XIAO <juguang@tll.org.sg>

=cut

