use Test2::V0 -no_srand => 1;
use Capture::Tiny qw( capture );

ok 1;

my ($stdout, $stderr ) = capture {
  local $ENV{PATH} = $ENV{PATH};
  eval '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) . q{
    use Alien::nasm
  };
};

note "[stdout]\n$stdout" if $stdout;
note "[stderr]\n$stderr" if $stderr;

done_testing;
