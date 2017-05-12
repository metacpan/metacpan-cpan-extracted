#! perl
use Test::More no_plan;

require_ok 'CGI::Prototype';

my @callbacks = qw(prototype_enter prototype_leave
		   app_enter app_leave
		   control_enter control_leave
		   render_enter render_leave
		   respond_enter respond_leave);

my @TRACE;
my $RESPOND = "My::App::One";
{
  package My::App;
  @ISA = qw(CGI::Prototype);

  sub TRACE {
    push @TRACE, [shift->reflect->package, shift, @_];
  }

  sub dispatch {
    shift->TRACE("dispatch", @_);
    return 'My::App::One';
  }

  sub template {
    \ (shift->reflect->package . ' template');
  }

  for my $m ("display", @callbacks) {
    *{__PACKAGE__ . "::$m"} = sub {
      shift->TRACE($m, @_);
    }
  }
}

{
  package My::App::One;
  @ISA = qw(My::App);

  sub respond {
    shift->TRACE("respond", @_);
    return $RESPOND;
  }
}

{
  package My::App::Two;
  @ISA = qw(My::App);

}

@TRACE =();
My::App->activate;
is_deeply \@TRACE,
  [
   ['My::App', 'prototype_enter'],
   ['My::App', 'app_enter'],
   ['My::App', 'dispatch'],
   ['My::App::One', 'control_enter'],
   ['My::App::One', 'respond_enter'],
   ['My::App::One', 'respond'],
   ['My::App::One', 'respond_leave'],
   ['My::App::One', 'render_enter'],
   ['My::App::One', 'display', 'My::App::One template'],
   ['My::App::One', 'render_leave'],
   ['My::App::One', 'control_leave'],
   ['My::App', 'app_leave'],
   ['My::App', 'prototype_leave'],
  ],
  'correct steps called for same page';

@TRACE = ();
$RESPOND = "My::App::Two";
My::App->activate;
is_deeply \@TRACE,
  [
   ['My::App', 'prototype_enter'],
   ['My::App', 'app_enter'],
   ['My::App', 'dispatch'],
   ['My::App::One', 'control_enter'],
   ['My::App::One', 'respond_enter'],
   ['My::App::One', 'respond'],
   ['My::App::One', 'respond_leave'],
   ['My::App::One', 'control_leave'],
   ['My::App::Two', 'control_enter'],
   ['My::App::Two', 'render_enter'],
   ['My::App::Two', 'display', 'My::App::Two template'],
   ['My::App::Two', 'render_leave'],
   ['My::App::Two', 'control_leave'],
   ['My::App', 'app_leave'],
   ['My::App', 'prototype_leave'],
  ],
  'correct steps called for new page';

# use Data::Dumper;
# print Dumper(\@TRACE);
# diag join "\n", map "[".join(",",@$_)."]", @TRACE;
