# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

use Test::More tests => 1;

use Class::Colon Person => [ qw(first middle last dob=Date=build) ];

#________ Test OO file reading _____
my $read_people = Person->READ_FILE('t/sample.dat');

my $real_people = [
bless( {
        'dob' => bless( { 'DATA' => '05/03/1968' }, 'Date' ),
        'middle' => 'David',
        'first' => 'Phil',
        'last' => 'Crow'
        }, 'Person' ),
bless( {
        'dob' => bless( { 'DATA' => '04/23/1976' }, 'Date' ),
        'middle' => 'Diane',
        'first' => 'Lisa',
        'last' => 'Crow'
        }, 'Person' )
];

is_deeply($read_people, $real_people, "oo file read");

package Date;

sub build {
    my $class  = shift;
    my $string = shift;
    my $self   = { DATA => $string };
    return bless $self, $class;
}
