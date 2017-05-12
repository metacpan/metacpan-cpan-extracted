package My::DemoNestedSubcommands::Command1::Command1_0;
use base qw( My::DemoNestedSubcommands::Command1 );

use strict; 
use warnings;

sub usage_text { 'first subcommand of second top-level command' }

sub run { print "running command '" . $_[0]->name . "'"; }

#-------
1;

__END__

=pod

=head1 PURPOSE

=cut
