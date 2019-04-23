package App::PerlShell::Plugin::ShellCommands;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;
use Pod::Usage;
use Pod::Find qw( pod_where );

our $caller = caller;

my $App_PerlShell_Plugin_ShellCommands = "
package $caller;

our \$AUTOLOAD;

sub AUTOLOAD {
    my \$program = \$AUTOLOAD;
    my \$retType = wantarray;

    \$program =~ s/^.*:://;
    my \@rets = `\$program \@_`;

    if ( not defined \$retType ) {
        print \@rets;
        return;
    } elsif ( \$retType ) {
        return \@rets;
    } else {
        return \\\@rets;
    }
}

sub DESTROY { return }

1;
";

eval $App_PerlShell_Plugin_ShellCommands;

use Exporter;

our @EXPORT = qw(
    ShellCommands
);

our @ISA = qw ( Exporter );

sub ShellCommands {
    pod2usage(
        -verbose => 2,
        -exitval => "NOEXIT",
        -input   => pod_where( {-inc => 1}, __PACKAGE__ )
    );
}

1;

__END__

########################################################
# Start POD
########################################################

=head1 NAME

App::PerlShell::Plugin::ShellCommands - Perl Shell Commands from OS Shell

=head1 SYNOPSIS

 plsh> use App::PerlShell::Plugin::ShellCommands;
 plsh> cat('filename.txt');
 
 plsh> @lines = cat('filename.txt');
 plsh> print @lines;

=head1 DESCRIPTION

B<App::PerlShell::Plugin::ShellCommands> provides an extension to 
B<App::PerlShell> to run commands from the operating system shell 
in the App::PerlShell.  Somewhat equivalent to:

 plsh> system "cat filename.txt"

Note:  Parenthesis ()s must be used around arguments to shell commands 
as shown with C<cat> in the SYNOPSIS.

=head1 COMMANDS

=head2 ShellCommands - provide help

Provides help.

=head1 SEE ALSO

L<App::PerlShell>

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (c) 2016 Michael Vincent

L<http://www.VinsWorld.com>

All rights reserved

=cut
