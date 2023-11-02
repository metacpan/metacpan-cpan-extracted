use v5.38;
use feature 'class';
no warnings 'experimental::class';

use Pod::Usage ();
use Pod::Find  ();

class CPANSEC::Admin::Command::Help {
    method name { 'help' }

    method command ($manager, $cmd_name = undef, @args) {
        my %params;
        if ($cmd_name) {
            my %dispatcher = $manager->dispatcher;
            if (exists $dispatcher{$cmd_name}) {
                if (my $loc = Pod::Find::pod_where({-inc => 1}, ref $dispatcher{$cmd_name})) {
                    $params{'-input'} = $loc;
                    %params = (
                        -sections => 'USAGE|SYNOPSIS|DESCRIPTION|ARGUMENTS',
                        -verbose  => 99,
                        -input    => $loc,
                    );
                }
                else {
                    $params{'-message'} = "no documentation found for command '$cmd_name'.\n";
                }
            }
            else {
                $params{'-message'} = "command '$cmd_name' not found.\n";
            }
        }
        $params{'-input'} = Pod::Find::pod_where({-inc => 1}, $0) unless $params{'-input'};
        Pod::Usage::pod2usage(%params);
    }
}

__END__

=head1 NAME

CPANSEC::Admin::Command::Help - Display help information about cpansec-admin

=head1 SYNOPSIS

    cpansec-admin help [<command>]

=head1 DESCRIPTION

This command displays help information about cpansec-admin.

Without any command given, shows basic usage and a list of the most commonly
used cpansec-admin commands on the standard output.

If you pass a command as argument, it will show dedicated help about that
particular command.