use strict;
use warnings;

use Test::More;

use lib 't/lib';

{
  package FAsm;
  use Moose;
  extends 'Config::MVP::Assembler';

  has notes => (
    is  => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
  );

  has '+section_class'  => (default => 'FAsm::Sec');
}

{
  package FAsm::Sec;
  use Moose;
  extends 'Config::MVP::Section';

  my $i = 0;

  after finalize => sub {
    my ($self) = @_;
    push @{ $self->sequence->assembler->notes }, [ $self->name, $i++ ];
  };
}

my $asm = FAsm->new;

# I wish I had an existing simple way to say "just a name, no package" here.
# -- rjbs, 2010-05-11
$asm->begin_section(strict => 'S1');
$asm->add_value(foo => 10);

is_deeply($asm->notes, [], "no notes to start with");

$asm->change_section(strict => 'S2');

is_deeply($asm->notes, [ [ S1 => 0 ] ], "finalize one section, get notes!");

$asm->end_section;

$asm->change_section(strict => 'S3');

is_deeply(
  $asm->notes,
  [
    [ S1 => 0 ],
    [ S2 => 1 ],
  ],
  "ending section is as good as changing",
);

$asm->change_section(strict => 'S4');

$asm->finalize;

is_deeply(
  $asm->notes,
  [
    [ S1 => 0 ],
    [ S2 => 1 ],
    [ S3 => 2 ],
    [ S4 => 3 ],
  ],
  "finalize the assembler after more sections, more notes!"
);

done_testing;
