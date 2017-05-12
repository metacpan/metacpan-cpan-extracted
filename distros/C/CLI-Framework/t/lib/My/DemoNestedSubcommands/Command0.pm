package My::DemoNestedSubcommands::Command0;
use base qw( CLI::Framework::Command );

use strict; 
use warnings;

sub usage_text { 'command0: first top-level command' }

sub run { print "running command '" . $_[0]->name . "'"; }

#-------
package My::DemoNestedSubcommands::Command0::Command0_0;
use base qw( My::DemoNestedSubcommands::Command0 );

use strict;
use warnings;

sub usage_text { 'command0_0: first subcommand of first top-level command' }

#-------
package My::DemoNestedSubcommands::Command0::Command0_1;
use base qw( My::DemoNestedSubcommands::Command0 );

use strict;
use warnings;

sub usage_text { 'command0_1: second subcommand of first top-level command' }

#-------

package My::DemoNestedSubcommands::Command0::Command0_1::Command0_1_0;
use base qw( My::DemoNestedSubcommands::Command0::Command0_1 );

use strict;
use warnings;

sub usage_text { 'command0_1_0: first subcommand of second subcommand of
first top-level command (a sub-subcommand)' }

#-------
1;

__END__

=pod

=head1 PURPOSE

Test defining a tree of nested subcommands inline via a single package file.

    command0
        command0_0
        command0_1
            command_0_1_0

=cut
