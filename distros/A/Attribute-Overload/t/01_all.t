use warnings;
use strict;
use Attribute::Overload;
use Test::More tests => 3;

package MyOverload;

sub new {
    my ($class, $value) = @_;
    bless \$value => $class;
}

sub add : Overload(+) {
    my ($self, $value) = @_;
    $$self += 2 * $value;
    return $self;
}

sub cmpnum : Overload(==) {
    my $self = shift;
    $$self;
}

# double each digit
sub to_print : Overload("") {
    join '' => map { "$_$_" } split // => ${ $_[0] };
}

package main;
my $o = MyOverload->new(57);
ok($o == 57, 'passing value to constructor');
$o += 23;    # adds 46 to give 103
ok($o == 103, 'after addition');

# stringify prints each digit twice, i.e. '110033'
ok("$o" eq '110033', 'stringification');
