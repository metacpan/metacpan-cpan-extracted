use strict;
use warnings;

use Test::More;

use Class::Anonymous;
use Class::Anonymous::Utils ':all';

my $class0 = class {
  method doit => sub { $_[1] .= 'base'; @_ };
};

subtest 'base class' => sub {
  my $inst = $class0->new;
  my @input = qw/in1 in2/;
  my @got  = $inst->doit(@input);
  is_deeply \@got,   [$inst, qw/in1base in2/], 'list context return';
  is_deeply \@input, [qw/in1base in2/], 'inputs mutated';

  @input = qw/a b/;
  my $got = $inst->doit(@input);
  is $got, 3, 'scalar context return';

  $inst->doit;
};

my $bwant;
my $class_before = extend $class0 => via {
  before doit => sub { $bwant = wantarray; $_[1] .= 'before' };
};

subtest 'before method' => sub {
  my $inst = $class_before->new;
  my @input = qw/in1 in2/;
  my @got  = $inst->doit(@input);
  is_deeply \@got,   [$inst, qw/in1beforebase in2/], 'list context return';
  is_deeply \@input, [qw/in1beforebase in2/], 'inputs mutated';
  ok $bwant, 'list context wantarray';

  @input = qw/a b/;
  my $got = $inst->doit(@input);
  is $got, 3, 'scalar context return';
  ok defined($bwant), 'scalar context wantarray defined';
  ok ! $bwant, 'scalar context wantarray false';

  $inst->doit;
  ok ! defined($bwant), 'void context wantarray not defined';
};

my $awant;
my $class_after = extend $class0 => via {
  after doit => sub { $awant = wantarray; $_[1] .= 'after' };
};

subtest 'after method' => sub {
  my $inst = $class_after->new;
  my @input = qw/in1 in2/;
  my @got  = $inst->doit(@input);
  is_deeply \@got,   [$inst, qw/in1base in2/], 'list context return';
  is_deeply \@input, [qw/in1baseafter in2/], 'inputs mutated';
  ok $awant, 'list context wantarray';

  @input = qw/a b/;
  my $got = $inst->doit(@input);
  is $got, 3, 'scalar context return';
  ok defined($awant), 'scalar context wantarray defined';
  ok ! $awant, 'scalar context wantarray false';

  $inst->doit;
  ok ! defined($awant), 'void context wantarray not defined';
};

my $class_around = extend $class0 => via {
  around doit => sub {
    my ($orig, $self, @in) = @_;
    $in[0]  .= 'before';
    my @out  = $self->$orig(@in);
    $out[1] .= 'after';
    return @out;
  }
};

subtest 'around method' => sub {
  my $inst = $class_around->new;
  my @input = qw/in1 in2/;
  my @got  = $inst->doit(@input);
  is_deeply \@got,   [$inst, qw/in1beforebaseafter in2/], 'list context return';
  is_deeply \@input, [qw/in1 in2/], 'inputs not mutated';
};

done_testing;

