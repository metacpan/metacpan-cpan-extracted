package LocalTester;
use v5.24;
use experimental 'signatures';
use Capture::Tiny 'capture';
use App::Easer V1 => 'run';
use Test::More;
use Exporter 'import';

our @EXPORT = ('test_run');

sub test_run ($app, $args, $env, $command = 'MAIN') {
   my ($stdout, $stderr, @result, $clean_run, $exception);
   my $self = bless {}, __PACKAGE__;
   local *LocalTester::command_execute = sub ($cmd, $main, $conf, $args) {
      return unless $cmd eq ($command // '');
      $self->{conf} = $conf;
      $self->{args} = $args;
   };
   eval {
      local @ENV{keys $env->%*};
      while (my ($k, $v) = each $env->%*) {
         if (defined $v) { $ENV{$k} = $v }
         else { delete $ENV{$k} }
      }
      $self->@{qw< stdout stderr result >} = capture {
         scalar run($app, $args)
      };
      1;
   } or do { $self->{exception} = $@ };
   return $self;
} ## end sub test_run

sub stdout_like ($self, $regex, $name = 'stdout') {
   like $self->{stdout} // '', $regex, $name;
   return $self;
}

sub diag_stdout ($self) {
   diag $self->{stdout};
   return $self;
}

sub diag_stderr ($self) {
   diag $self->{stderr};
   return $self;
}

sub stderr_like ($self, $regex, $name = 'stderr') {
   like $self->{stderr} // '', $regex, $name;
   return $self;
}

sub conf_is ($self, $expected, $name = 'configuration') {
   is_deeply $self->{conf}, $expected, $name;
   return $self;
}

sub args_are ($self, $expected, $name = 'residual arguments') {
   is_deeply $self->{args}, $expected, $name;
   return $self;
}

sub result_is ($self, $expected, $name = undef) {
   $name //= "result is '$expected'";
   is $self->{result}, $expected, $name;
   return $self;
}

sub no_exceptions ($self, $name = 'no exceptions raised') {
   ok !exists($self->{exception}), $name
      or diag $self->{exception};
   return $self;
}

sub exception_like ($self, $regex, $name = 'exception') {
   like $self->{exception} // '', $regex, $name;
   return $self;
}

1;
