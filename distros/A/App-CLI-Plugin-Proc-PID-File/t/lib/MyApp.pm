package MyApp;

use strict;
use File::Spec;
use base qw(App::CLI::Extension);
use constant alias => (
                 objcan     => "LogObjCan",
                 logmessage    => "LogMessage",
                 stringfystack => "StringfyStack",
             );

$ENV{APPCLI_NON_EXIT} = 1;
__PACKAGE__->config(proc_pid_file => { dir => File::Spec->tmpdir, name => "prove" });
__PACKAGE__->load_plugins(qw(
                 Proc::PID::File
            ));

1;
