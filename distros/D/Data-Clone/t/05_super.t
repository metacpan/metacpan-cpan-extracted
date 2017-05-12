#!perl -w

use strict;
use warnings FATAL => 'all';

use Test::More;

use Data::Clone;

use Scalar::Util qw(isweak weaken);
use Data::Dumper;
$Data::Dumper::Indent   = 0;
$Data::Dumper::Sortkeys = 1;

my $c_clone_called;
{
    package A;
    use Data::Clone; # make clonable

    sub new {
        my($class, @args) = @_;
        return bless {@args}, $class;
    }

    package B;
    our @ISA = qw(A);

    package C;
    our @ISA = qw(B);

    sub clone {
        my($self) = @_;

        my $cloned = $self->SUPER::clone();
        $cloned->{'c_clone'} = 1;

        $c_clone_called++;
        return $cloned;
    }

    package D;
    our @ISA = qw(C);

    package E;
    our @ISA = qw(D);
}

my $b = B->new(foo => 10);
my $c = C->new(bar => 20);

for(1 .. 2){
    note($_);

    is Dumper($b->clone), Dumper(bless { foo => 10 }, 'B'), 'inherited clone method';
    is Dumper(clone($b)), Dumper(bless { foo => 10 }, 'B'), 'inherited clone method via clone() function';

    $c_clone_called = 0;

    is Dumper($c->clone), Dumper(bless { bar => 20, c_clone => 1 }, 'C'), 'work with SUPER::clone()';
    is $c_clone_called, 1;

    $c_clone_called = 0;
    is Dumper(clone($c)), Dumper(bless { bar => 20, c_clone => 1 }, 'C'), 'work with SUPER::clone()';
    is $c_clone_called, 1;

    is Dumper($c), Dumper(bless { bar => 20 }, 'C');


    for my $class(qw(C D E)){
        note("for $class");

        my @h = ( $class->new(a => 1), $class->new(a => 2), $class->new(a => 3) );
        $c_clone_called = 0;
        is Dumper(clone(\@h)),
           Dumper([ ( $class->new(a => 1, c_clone => 1),
                      $class->new(a => 2, c_clone => 1),
                      $class->new(a => 3, c_clone => 1) ) ]);
        is $c_clone_called, 3;

        my $o = $class->new( c => [$class->new(foo => 42)], c2 => [$class->new(foo => 52)], );
        $c_clone_called = 0;

        is Dumper(clone($o)),
           Dumper($class->new( c  => [$class->new(foo => 42, c_clone => 1)],
                          c2 => [$class->new(foo => 52, c_clone => 1)], c_clone => 1));
        is $c_clone_called, 3;
    }
}

done_testing;
