package Data::Freezer::Steak ;

use base qw/Class::AutoAccess/ ;

sub new{
    my ($class ) = @_ ;
    
    my $self = {
	'cooked' => 0 ,
	'protein' => 0 ,
	'madcow' => 0
    };
    
    return bless $self, $class;
}

1;
