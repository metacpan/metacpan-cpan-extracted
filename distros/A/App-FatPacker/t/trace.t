use strict;
use warnings FATAL => 'all';
use Test::More qw(no_plan);

test_trace("t/mod/ModuleA.pm" => ("ModuleB.pm", "ModuleC.pm"));
test_trace("t/mod/ModuleB.pm" => ("ModuleC.pm"));
test_trace("t/mod/ModuleC.pm" => ());
test_trace("t/mod/ModuleD.pl" => ("ModuleD.pm"));

# Attempts to conditionally load a module that isn't present
test_trace("t/mod/ModuleCond.pm" => ());

sub test_trace {
  my($file, @loaded) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  unlink "fatpacker.trace";
  system($^X, "-Mblib", '-It/mod', "-MApp::FatPacker::Trace", $file);

  open my $trace, "<", "fatpacker.trace";
  my @traced = sort map { chomp; $_ } <$trace>;
  close $trace;

  is_deeply \@traced, \@loaded, "All expected modules loaded for $file";
  unlink "fatpacker.trace";
}
