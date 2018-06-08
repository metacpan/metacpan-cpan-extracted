use strict;
use warnings;
## This BEGIN block is a minimal fatpack entry
## see perldoc App::FatPacker and perldoc -f require
BEGIN {
my %fatpacked;

$fatpacked{"Help/Class.pm"} = '#line '.(1+__LINE__).' "'.__FILE__."\"\n".<<'HELP_CLASS';
  package Help::Class;
  1;
  __END__
  =head1 SYNOPSIS

  How to run your script.

  =cut

HELP_CLASS
s/^  //mg for values %fatpacked;
my $class = 'FatPacked::'.(0+\%fatpacked);
no strict 'refs';
*{"${class}::files"} = sub { keys %{$_[0]} };
*{"${class}::INC"} = sub {
  if (my $fat = $_[0]{$_[1]}) {
    open my $fh, '<', \$fat
      or die "FatPacker error loading $_[1] (could be a perl installation issue?)";
    return $fh;
  }
  return;
};
unshift @INC, bless \%fatpacked, $class;
} ## END of FatPacked code

use lib '.';
use t::Helper;

my $app = eval 'use Applify; app {0};' or die $@;
my $script = $app->_script;

$script->option(str => foo_bar => 'Foo can something');
$script->option(str => foo_2   => 'foo_2 can something else', 42);
$script->option(str => foo_3   => 'foo_3 can also something', 123, required => 1);

my $application_class = $script->_generate_application_class(sub { });
like $application_class, qr{^Applify::__ANON__2__::}, 'generated application class';
can_ok $application_class, qw(new run _script foo_bar foo_2 foo_3);

is_deeply [$script->_default_options], [qw(help)], 'default options';
is + (run_method($script, 'print_help'))[0], <<'HERE', 'print_help()';
Usage:
   --foo-bar  Foo can something
   --foo-2    foo_2 can something else
 * --foo-3    foo_3 can also something

   --help     Print this help text

HERE

eval { $script->documentation(undef) };
like $@, qr{Usage: documentation }, 'need to give documentation(...) a true value';
is $script->documentation('Applify'), $script, 'documentation(...) return $self on set';
is $script->documentation, 'Applify', 'documentation() return what was set';

$script->documentation(__FILE__)->version('1.23');
is_deeply [$script->_default_options], [qw(help man version)], 'default options after documentation() and version()';
is + (run_method($script, 'print_help'))[0], <<'HERE', 'print_help()';

dummy synopsis...

Usage:
   --foo-bar  Foo can something
   --foo-2    foo_2 can something else
 * --foo-3    foo_3 can also something

   --help     Print this help text
   --man      Display manual for this application
   --version  Print application name and version

HERE


$script->documentation("Help::Class");

is + (run_method($script, 'print_help'))[0], <<'HERE', 'print_help() with fatpacked code';

How to run your script.

Usage:
   --foo-bar  Foo can something
   --foo-2    foo_2 can something else
 * --foo-3    foo_3 can also something

   --help     Print this help text
   --man      Display manual for this application
   --version  Print application name and version

HERE

done_testing;

__END__
=head1 SYNOPSIS

dummy synopsis...

=cut
