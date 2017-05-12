#!perl -w

use strict;

use Benchmark qw(:all);

use Storable ();
use Clone ();
use Data::Clone ();

BEGIN{
    package Object;
    sub new {
        my $class = shift;
        return bless { @_ }, $class;
    }
    package ST;
    use Storable ();
    our @ISA = qw(Object);

    *clone = \&Storable::dclone;
    package C;
    use Clone qw(clone);
    our @ISA = qw(Object);
    package DC;
    use Data::Clone qw(clone);
    our @ISA = qw(Object);
}

my %args = (
    foo => 42,
    inc => { %INC },
);

my $st = ST->new(%args);
my $c  = C->new(%args);
my $dc = DC->new(%args);

print "Object:\n";
cmpthese -1 => {
    'Clone' => sub{
        my $x = $c->clone;
    },
    'Storable' => sub{
        my $x = $st->clone;
    },
    'Data::Clone' => sub{
        my $x = $dc->clone;
    },
};
