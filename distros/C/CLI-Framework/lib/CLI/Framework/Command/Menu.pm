package CLI::Framework::Command::Menu;
use base qw( CLI::Framework::Command::Meta );

use strict;
use warnings;

our $VERSION = 0.01;

#-------

sub usage_text { 
    q{
    menu: menu of available commands
    }
}

sub run {
    my ($self, $opts, @args) = @_;

    return $self->menu_txt();
}

sub menu_txt {
    my ($self) = @_;

    my $app = $self->get_app();

    # Build a numbered list of visible commands...
    my @cmd = $app->get_interactive_commands();

    my $txt;
    my %new_aliases = $app->command_alias();
    for my $i (0..$#cmd) {
        my $alias = $i+1;
        $txt .= $alias . ') ' . $cmd[$i] . "\n";
        $new_aliases{$alias} = $cmd[$i];
    }
    # Add numerical aliases corresponding to menu options to the original
    # command aliases defined by the application...
    {
        no strict 'refs'; no warnings;
        *{ (ref $app).'::command_alias' } = sub { %new_aliases };
        return "\n".$txt;
    }
}

sub line_count {
    my ($self) = @_;

    my $menu = $self->menu_txt();
    my $line_count = 0;
    $line_count++ while $menu =~ /\n/g;
    return $line_count;
}

#-------
1;

__END__

=pod

=head1 NAME

CLI::Framework::Command::Menu - CLIF built-in command to show a command menu
including the commands that are available to the running application

=head1 SEE ALSO

L<run_interactive|CLI::Framework::Application/run_interactive( [%param] )>

L<CLI::Framework::Command::Console>

L<CLI::Framework::Command>

=cut
