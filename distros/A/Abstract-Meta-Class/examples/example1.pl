use warnings;
use strict;

package User;


use Digest::SHA1  qw(sha1_hex);

use Abstract::Meta::Class ':all';


has '$.id';

has '$.name';

has '$.password' => (
    on_change => sub {
        my ($self, $attribute, $scope, $value_ref) = @_;
        $$value_ref = sha1_hex($$value_ref);
        $self;
    }
);

has '$.email' => (
    on_change => sub {
        my ($self, $attribute, $scope, $value_ref) = @_;
        die "invalid email format:" . $$value_ref
            unless $$value_ref =~ m/^<?[^@<>]+@[^@.<>]+(?:\.[^@.<>]+)+>?$/;
        $self;
    }
);

has '$.address';
has '%.roles' ;

sub is_valid_password {
    my ($self, $password) = @_;
    !! ($self->password eq sha1_hex($password));
}



##################

my $user = User->new(id => 1, name => 'Scott', email => 'scott@email.com', password => '1234567');

if($user->is_valid_password('1234567')) {
    #do some stuff
}