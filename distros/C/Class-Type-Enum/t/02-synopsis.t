use warnings;
use strict;
use Test::More;

BEGIN {
  eval "require Moo; require Type::Tiny;";
  plan skip_all => "Synopsis test requires Moo and Type::Tiny" if $@;
};

{
  package Toast::Status;
  use Class::Type::Enum values => ['bread', 'toasting', 'toast', 'burnt'];
}
 
{
  package Toast;
  # Don't let this show up as a dependency:
  BEGIN { 
    Moo->import();
  }
 
  has status => (
    is       => 'rw',
    required => 1,
    isa      => Toast::Status->type_constraint,
    coerce   => 1,
    handles => [ Toast::Status->list_is_methods ],
  );
}
 
my @toast = map { Toast->new(status => $_) } qw( toast burnt bread bread toasting toast );
 
my @trashcan = grep { $_->is_burnt } @toast;
my @plate    = grep { $_->is_toast } @toast;
 
my $ready_status   = Toast::Status->new('toast');
my @eventual_toast = grep { $_->status < $ready_status } @toast;
my @eventual_toast_cmp = grep { $_->status lt 'toast' } @toast;

is( scalar(@trashcan), 1, "Found one burnt toast" );
is( scalar(@plate),    2, "Found two actual toast" );
is( scalar(@eventual_toast),     3, "And three on the way" );
is( scalar(@eventual_toast_cmp), 3, "Even with string compare" );

eval { Toast->new(status => 'ack') };
ok( index($@, 'Value [ack] is not valid') > 0, 'Type constraint works' );

done_testing;
