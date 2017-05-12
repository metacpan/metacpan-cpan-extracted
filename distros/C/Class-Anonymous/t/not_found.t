use strict;
use warnings;

use Test::More;

use Class::Anonymous;
use Class::Anonymous::Utils ':all';

my $class = class {
  method 'yep' => sub { 1 };
};

my $inst = $class->new;
is $inst->yep, 1, 'method exists';

eval { $inst->nope }; my $line = __LINE__;
my $file = __FILE__;
like $@, qr/at\s+\Q$file/, 'error reported from right file';
like $@, qr/line\s+\Q$line/, 'error reported from right line';

done_testing;

