#!/usr/bin/env perl
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';
use App::Easer qw< run d >;

my $APPNAME = 'galook';

my $application = {
   factory       => {prefixes => {'#' => 'MyApp#'}},
   configuration => {

      # the name of the application, set it above in $APPNAME
      name               => $APPNAME,

      # figure out names of environment variables automatically
      'auto-environment' => 1,

      # sub-commands without children are leaves (no sub help/commands)
      # 'auto-leaves'    => 1,

      # help goes to standard error by default, override to stdout
      # 'help-on-stderr' => 0,

      # Where to get the specifications for commands
      # specfetch => '+SpecFromHash',         # default
      # specfetch => '+SpecFromHashOrModule', # possible alternative
   },
   commands => {
      MAIN => {
         help        => 'An application to do X',
         description => 'An application to do X, easily',

         # allow for configuration files
         sources            => '+SourcesWithFiles',
         # 'config-files' => ["/etc/$APPNAME.json"],
         options     => [
            {
               getopt      => 'config|c=s',
               help        => 'path to the configuration file',
               environment => 1,
               # default     => "$ENV{HOME}/.$APPNAME.json",
            },
         ],

         children => [qw< foo bar >],
      },
      foo => {
         help        => 'An example sub-command',
         description => 'An example sub-command, more details',
         options     => [
            {
               getopt      => 'baz|b=s',
               help        => '',
               environment => 1,
               # default     => '',
            },
         ],
         execute => '#foo',
      },
      bar => {
         help        => 'Another example sub-command',
         description => 'Another example sub-command, more details',
         options     => [
            {
               getopt      => 'galook|g=s',
               help        => '',
               environment => 1,
               # default     => '',
            },
         ],
         execute => '#bar',
      },
   }
};
exit run($application, [@ARGV]);

package MyApp;

# implementation of sub-command foo
sub foo ($general, $config, $args) {
    # $general is a hash reference to the overall application
    # $config  is a hash reference with options
    # $args    is an array reference with "residual" cmd line arguments
    for my $key (sort { $a cmp $b } keys $config->%*) {
        say "$key: $config->{$key}";
    }
    say "($args->@*)";
    return;
}

# implementation of sub-command bar
sub bar ($general, $config, $args) {
    say defined($config->{galook}) ? $config->{galook} : '*undef*';
    return;
}
