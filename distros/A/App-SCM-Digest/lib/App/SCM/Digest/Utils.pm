package App::SCM::Digest::Utils;

use strict;
use warnings;

use File::Temp;

use base qw(Exporter);
our @EXPORT_OK = qw(system_ad system_ad_op slurp);

sub slurp
{
    my ($path) = @_;

    open my $fh, '<', $path;
    my @lines;
    while (my $line = <$fh>) {
        push @lines, $line;
    }
    close $fh;
    return join '', @lines;
}

sub _system_ad
{
    my ($cmd, $ft) = @_;

    my $res = system("$cmd");
    if ($res != 0) {
        my $extra = '';
        if ($ft) {
            my $content = slurp($ft->filename());
            chomp $content;
            $extra = " ($content)";
        }
        die "Command ($cmd) failed: $res$extra";
    }

    return 1;
}

sub system_ad
{
    my ($cmd) = @_;

    my $ft = File::Temp->new();
    my $redirect = '>'.$ft->filename();

    return _system_ad("$cmd $redirect 2>&1", $ft);
}

sub system_ad_op
{
    my ($cmd) = @_;

    return _system_ad("$cmd 2>&1");
}

1;

__END__

=head1 NAME

App::SCM::Digest::Utils

=head1 DESCRIPTION

Utility functions for use with L<App::SCM::Digest> modules.

=head1 PUBLIC FUNCTIONS

=over 4

=item B<system_ad>

Takes a system command as its single argument.  Executes that command,
suppressing C<stdout> and C<stderr>.  Dies if the command returns a
non-zero exit status, and returns a true value otherwise.  (The name
is short for 'system autodie'.)

=item B<system_ad_op>

As per C<system_ad>, except that C<stdout> and C<stderr> are merged,
and not suppressed.  (The name is short for 'system autodie output'.)

=back

=cut
