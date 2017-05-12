#!perl
use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 4;

my $class = 'App::Addex::Output::ToFile';
use_ok($class);

eval { $class->new; };
like($@, qr/no filename/, 'filename is a required arg');

# Is this test portable? -- rjbs, 2007-05-11
eval { $class->new({ filename => '/' }); };
like($@, qr/couldn't open/, 'filename is a required arg');

# WARNING!  This test relies on the object guts. -- rjbs, 2007-05-11
{
  local $SIG{__WARN__} = sub { }; # avoid 'print on closed fh' warning
  my $self = $class->new({ filename => \(my $buffer) });
  close $self->{fh};
  eval { $self->output("line") };
  like($@, qr/couldn't write/, 'exception raised if output fails');
}
