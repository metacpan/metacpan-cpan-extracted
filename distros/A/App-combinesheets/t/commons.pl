use warnings;
use strict;

use App::combinesheets;
use IO::CaptureOutput qw(capture);
use FindBin qw( $Bin );
use File::Spec;

#-----------------------------------------------------------------
# Return a fully qualified name of the given file in the test
# directory "t/data" - if such file really exists. With no arguments,
# it returns the path of the test directory itself.
# -----------------------------------------------------------------
sub test_file {
    my $file = File::Spec->catfile ('t', 'data', @_);
    return $file if -e $file;
    $file = File::Spec->catfile ($Bin, 'data', @_);
    return $file if -e $file;
    return File::Spec->catfile (@_);
}

# -----------------------------------------------------------------
# Join and print (STDOUT) what you got.
# -----------------------------------------------------------------
sub msgcmd {
    return shift() . join (" ", @_);
}

# -----------------------------------------------------------------
# The same as msgcmd except it has an expected value in the first
# parameter.
# -----------------------------------------------------------------
sub msgcmd2 {
    my $expected = shift;
    return msgcmd (@_) . ($expected ? "\nGot:\n$expected" : '');
}

# -----------------------------------------------------------------
# Call the main subroutine and return its STDOUT and STDERR. Hack:
# ignore STDERR if it has a very specific string (it is done to avoid
# exit(0) in the tested script.
# -----------------------------------------------------------------
sub my_run {
    local @ARGV = @_;
    my ($stdout, $stderr);
    eval {
        capture { App::combinesheets->run() } \$stdout, \$stderr;
    };
    if ($@) {
        return ($stdout, $stderr) if $@ eq "Okay\n";
        $stderr .= $@ if $@;
    }
    return ($stdout, $stderr);
}

# -----------------------------------------------------------------
sub row_count {
    my $data = shift;
    my @lines = split (m{\n}, $data);
    return undef unless @lines > 0;
    return scalar @lines;
}
sub col_count {
    my $data = shift;
    my @lines = split (m{\n}, $data);
    return undef unless @lines > 0;
    return scalar (my @tmp = split (m{\t}, $lines[0], -1));
}
sub mtx_count {
    my $data = shift;
    my @lines = split (m{\n}, $data);
    my $count = 0;
    foreach my $line (@lines) {
        $count += scalar (my @tmp = split (m{\t}, $line, -1));
    }
    return $count;
}
sub cut_into_table {
    my $data = shift;
    my @lines = split (m{\n}, $data);
    my @result = ();
    foreach my $line (@lines) {
        push (@result, [ split (m{\t}, $line, -1) ]);
    }
    return [ @result ];
}

1;
__END__
