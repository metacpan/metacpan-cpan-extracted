package My::DemoNestedSubcommands::Command1;
use base qw( CLI::Framework::Command );

use strict; 
use warnings;

sub usage_text { 'command1: second top-level command' }

sub run { print "running command '" . $_[0]->name . "'"; }

#-------
1;

__END__

=pod

=head1 PURPOSE

Test defining a tree of nested subcommands using classes that each have their
own package file:

    command1
        command1_0
        command1_1
            command_1_1_0

=cut
