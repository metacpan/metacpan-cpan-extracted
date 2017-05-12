use strict;
use warnings;

use lib 'lib';

# ---- EXECUTION ----
# Here, we set the default command to the only command in our simple
# application.  If this is not done, 'help' will be the default.
my $app = Converted::Script->new();
$app->set_default_command( 'legacy-script' );
$app->run();

###################################

# ---- APPLICATION ----
package Converted::Script;
use base qw( CLI::Framework );

use strict;
use warnings;

sub usage_text {
    qq{
    $0 [--verbose|v] [--help|h]: work all manner of mischief devised by long-departed miscreants
    }
}

sub option_spec {
    [ 'help|h'      => 'show help' ],
    [ 'verbose|v'   => 'be verbose' ],
}

sub command_map {
    'legacy-script' => 'Converted::Script::Command::LegacyScript',
}

# ---- COMMAND ----
package Converted::Script::Command::LegacyScript;
use base qw( CLI::Framework::Command );

use strict;
use warnings;

sub run {
    # Now that the extraneous details have been separated into their own
    # subroutines, run() contains just the "real" program logic.
    my ($self, $opts, @args) = @_;

    return 'running '.__PACKAGE__.
    "... (<useful things happen here -- use your imagination>)\n";
}

__END__

=pod

=head1 PURPOSE

Demonstration of a very simple CLIF application.

=cut
