package Data::Freezer::FreezingBag ;

use base qw/Class::AutoAccess/;

our $VERSION = '0.01';

sub new{
    my ($class) = @_ ;
    my $self = {
	'freezeDate' => time , # Object creation
	'content' => undef ,
	'note' => ''
    };
    return bless $self, $class ;
}

1;
