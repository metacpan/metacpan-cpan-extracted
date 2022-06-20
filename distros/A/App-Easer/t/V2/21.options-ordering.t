use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;

my $file_prefix = __FILE__ =~ s{\.t\z}{}rmxs;
my $json_config = "$file_prefix.json";

my $app = {
   aliases     => ['parent'],
   help        => 'example command',
   options     => [
      {
         getopt => 'config=s',
         help => 'path to configuration file',
      },
      map {;
         {
            getopt      => "$_=s",
            environment => 1,
            default     => $_,
            transmit    => 1, #  let children support this option too
         };
      } qw< one two three four five >,
   ],
   default_child => '-self',
   execute => \&parent_execute,
   children        => [
      {
         aliases     => ['child'],
         help        => 'sub-command bar',
         options     => [
            '+parent',
            {
               getopt => 'six=s',
               environment => 1,
               default => 'six',
            },
         ],
         execute => \&child_execute,
      }
   ],
   sources =>
      [
         qw< +CmdLine +Environment +Parent=70 +Default=100 >, # defaults 
         '+JsonFileFromConfig=40',
      ],
};

# All tests should now apply to both the parent and the child
for my $who (qw< parent child >) {
   my %conf = map { $_ => $_ } qw< one two three four five >;
   my (@args, %env);

   if ($who eq 'child') { # add stuff for child command
      @args = 'child';
      $conf{six} = 'six';
   }

   subtest "$who, all defaults, baseline" => sub {
      test_run($app, \@args, \%env, $who)
         ->no_exceptions
         ->result_is(ucfirst $who)
         ->conf_is(\%conf)
         ->args_are([])
         ->stdout_like(qr{$who on out})
         ->stderr_like(qr{$who on err});
   };

   push @args, '--one', $conf{one} = 'cmdline-one';
   subtest "$who, cmdline on ONE", => sub {
      test_run($app, \@args, \%env, $who)->no_exceptions->conf_is(\%conf);
   };

   $env{ONE} = 'whatever, this does not go'; # cmdline overrides this
   $env{TWO} = $conf{two} = 'environment-two'; # this goes over default
   subtest "$who, cmdline on ONE, environment on ONE and TWO" => sub {
      test_run($app, \@args, \%env, $who)->no_exceptions->conf_is(\%conf);
   };

   # will read from JSON file and stuff will be added. one and two are
   # left unchanged because it's how precedence works
   %conf = (
      one => 'cmdline-one',                # cmdline wins over all
      two => 'environment-two',            # then environment
      three => 'jsonconf-three',           # then config file
      four => 'four',                      # then default
      five => 'five',                      # ditto
      six => 'jsonconf-six',               # additional stuff from file
      additional => 'jsonconf-additional', # cmdline
      config => $json_config,
   );

   # **NOTE** the "--config" option is **not** transmitted and must appear
   # at the beginning of @args (at least for the child command)
   unshift @args, '--config', $json_config;
   subtest "$who, cmdline<ONE>, env<ONE,TWO>, json<ONE,TWO,THREE>" => sub {
      test_run($app, \@args, \%env, $who)->no_exceptions->conf_is(\%conf);
   };
}

subtest 'child wins over stuff from parent' => sub {
   my @args = (
      qw< --one parent-one --four parent-four >,
      '--config' => $json_config,
      qw< child --one child-one --five child-five --six child-six >
   );
   my %env = ( TWO => 'environment-two', FIVE => 'environment-five' );
   my %conf = (
      one => 'child-one',                  # child cmdline wins over all
      two => 'environment-two',            # then environment
      three => 'jsonconf-three',           # then config file
      four => 'parent-four',               # then parent
      five => 'child-five',                # child cmdline again
      six => 'child-six',                  # child cmdline again
      additional => 'jsonconf-additional', # cmdline
      config => $json_config,
   );
   test_run($app, \@args, \%env, 'child')->no_exceptions->conf_is(\%conf);
};

# subvert precedence in the child, make the parent win over all
subtest 'child getting stuff from parent' => sub {
   my @args = (
      qw< --one parent-one --four parent-four >,
      '--config' => $json_config,
      qw< child --one child-one --five child-five >
   );
   my %env = ( TWO => 'environment-two', FIVE => 'environment-five' );
   my %conf = (
      one => 'parent-one',                 # parent cmdline wins here
      two => 'environment-two',            # then environment
      three => 'jsonconf-three',           # then config file
      four => 'parent-four',               # then parent
      five => 'environment-five',          # parent env wins here
      six => 'jsonconf-six',               # parent file wins here
      additional => 'jsonconf-additional', # cmdline
      config => $json_config,
   );
   $app->{children}[0]{sources} = [qw< +Parent +CmdLine +Environment +Default >];
   test_run($app, \@args, \%env, 'child')->no_exceptions->conf_is(\%conf);
   delete $app->{children}[0]{sources};
};

# subvert precedence, make environment win over command-line
subtest 'parent, Environment over CmdLine' => sub {

   # input arguments for the test run
   my @args = qw< --one cmdline-one --four cmdline-four >;

   # input environment for the test run
   my %env = (
      ONE => 'environment-one',
      TWO => 'environment-two',
      FIVE => 'environment-five',
   );

   # expected output parsed configuration after the test run
   my %conf = (
      one => 'environment-one',
      two => 'environment-two',
      three => 'three',           # default
      four => 'cmdline-four',
      five => 'environment-five',
   );

   # temporarily override the list of sources and their precedences
   my $save_sources = $app->{sources};
   $app->{sources} = [qw< +CmdLine +Environment=5 +Default=100 >];

   # run the test
   test_run($app, \@args, \%env, 'parent')
      ->no_exceptions
      ->conf_is(\%conf);

   # restore original sources
   $app->{sources} = $save_sources;
};

done_testing();

sub parent_execute ($self) {
   LocalTester::command_execute($self);
   print {*STDOUT} 'parent on out';
   print {*STDERR} 'parent on err';
   return 'Parent';
}

sub child_execute ($self) {
   LocalTester::command_execute($self);
   print {*STDOUT} 'child on out';
   print {*STDERR} 'child on err';
   return 'Child';
}
