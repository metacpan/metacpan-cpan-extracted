package My::DemoNestedSubcommands::Command1::Command1_1::Command1_1_0;
use base qw( My::DemoNestedSubcommands::Command1::Command1_1 );

use strict; 
use warnings;

sub usage_text { 'command1_1_0: first subcommand of second subcommand of
second top-level command (a sub-subcommand)' }

sub run { print "running command '" . $_[0]->name . "'"; }

#-------
1;

__END__

=pod

=head1 PURPOSE

=cut
