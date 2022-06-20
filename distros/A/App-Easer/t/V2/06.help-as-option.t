use v5.24;
use experimental 'signatures';
use Test::More;
use Test::Output;
use Test::Exception;

use App::Easer V2 => 'run';

sub execute ($cmd) {
   return $cmd->run_help if $cmd->config('help');

   if ($cmd->config('wrapped-help')) {
      say 'BEGIN WRAPPING';
      print $cmd->full_help_text;
      say 'END WRAPPING';
      return 0;
   }

   say 'normal call <', join('> <', $cmd->residual_args), '>';
   return 0;
} ## end sub execute

my $app = {
   help        => 'example command',
   description => 'An example command',
   options     => [
      {
         getopt => 'help|h!',
         help   => 'get some help about the command',
      },
      {
         getopt => 'wrapped-help|w!',
         help   => 'get some help, wrapped somehow',
      },
   ],
   execute         => \&execute,
};

stdout_like { run($app, $0 => 'help') } qr{(?mxs:
   \A normal \s call \s <help>
)}, 'normal call, simple "help" not treated as a sub-command';

stdout_like { run($app, $0 => 'commands') } qr{(?mxs:
   \A normal \s call \s <commands>
)}, 'normal call, simple "commands" not treated as a sub-command';

stdout_like { run($app, $0 => 'tree') } qr{(?mxs:
   \A normal \s call \s <tree>
)}, 'normal call, simple "tree" not treated as a sub-command';

stdout_like { run($app, $0 => '--help') } qr{(?mxs:
   help .*?
   commands .*?
)}, 'option --help turned into full help on command';

stdout_like { run($app, $0 => '--wrapped') } qr{(?mxs:
   BEGIN .*?
   help .*?
   commands .*?
   END .*?
)}, 'option --wrapped turned into wrapped full help on command';

done_testing();
