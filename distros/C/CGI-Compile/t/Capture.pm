package t::Capture;
use base qw(Exporter);
our @EXPORT = qw(capture_out);

sub capture_out {
    no warnings 'uninitialized';
    my $code = shift;

    my $stdout;
    open my $oldout, ">&STDOUT";
    close STDOUT;
    open STDOUT, ">", \$stdout or die $!;
    select STDOUT; $| = 1;

    $code->();

    open STDOUT, ">&", $oldout;

    return $stdout;
}

1;
