package Data::Freezer::Tomato ;

use base qw/Class::AutoAccess/ ;

sub new{
    my ($class) = @_ ;
    
    my $self = {
	'weight' => 0 ,
	'shape'  => 0 ,
	'sugar'  => 0 ,
	'red'    => 0 
	};
    return bless $self , $class ;
}


1;
