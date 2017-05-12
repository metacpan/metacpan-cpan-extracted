# segfault bug in perls < 5.8.9 (a perl bug)
# patches welcome
# see http://github.com/tsee/Class-XSAccessor/commit/8fe9c128027cc49c8e2d89c442c77285598b12d3

use strict;
use warnings;

use Class::XSAccessor;
use Test::More tests => 14;

my $shim_calls;

sub install_accessor_with_shim {
  my ($class, $name, $field) = @_;

  $field = $name if not defined $field;

  Class::XSAccessor->import ({
    class => $class,
    getters => { $name => $field },
    replace => 1,
  });

  my $xs_cref = $class->can ($name);

  no strict 'refs';
  no warnings 'redefine';

  *{"${class}::${name}"} = sub {
    $shim_calls++;
    goto $xs_cref;
  };
}

TODO: {
    todo_skip 'bug in perls < 5.8.9', 14, $] < 5.008009;

    for my $name (qw/bar baz/) {
      for my $pass (1..2) {

        $shim_calls = 0;

        install_accessor_with_shim ('Foo', $name);
        my $obj = bless ({ $name => 'a'}, 'Foo');

        is ($shim_calls, 0, "Reset number of calls ($name pass $pass)" );
        is ($obj->$name, 'a', "Accessor read works ($name pass $pass)" );
        is ($shim_calls, 1, "Shim called ($name pass $pass)" );

        eval { $obj->$name ('ack!') };
        ok ($@ =~ /Usage\: $name\(self\)/, "Exception from R/O accessor thrown ($name pass $pass)" );
        is ($shim_calls, 2, "Shim called anyway ($name pass $pass)" );

        eval { $obj->$name ('ick!') };
        ok ($@ =~ /Usage\: $name\(self\)/, "Exception from R/O accessor thrown once again ($name pass $pass)" );
        is ($shim_calls, 3, "Shim called again ($name pass $pass)" );
      }
    }
}
