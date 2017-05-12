package My::DemoNestedSubcommands;
use base qw( CLI::Framework );

use strict;
use warnings;

sub usage_text {
    q{
    Demo app to test nested subcommands...
    }
}

sub command_map {
    tree            => 'CLI::Framework::Command::Tree',
    list            => 'CLI::Framework::Command::List',
    command0        => 'My::DemoNestedSubcommands::Command0',
    command0_0      => 'My::DemoNestedSubcommands::Command0::Command0_0',
    command0_1      => 'My::DemoNestedSubcommands::Command0::Command0_1',
    command0_1_0    => 'My::DemoNestedSubcommands::Command0::Command0_1::Command0_1_0',
    command1        => 'My::DemoNestedSubcommands::Command1',
    command1_0      => 'My::DemoNestedSubcommands::Command1::Command1_0',
    command1_1      => 'My::DemoNestedSubcommands::Command1::Command1_1',
    command1_1_0    => 'My::DemoNestedSubcommands::Command1::Command1_1::Command1_1_0',
}

#-------
1;

__END__

=pod

=head1 PURPOSE

=cut
