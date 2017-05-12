# test helpers for Apache2::Filter::CSS::LESS
package My::TestHelper;

use 5.008;
use strict;
use warnings;
use base 'Exporter';
use Test::Builder;
use FileHandle;

our @EXPORT_OK = qw(cmp_file_ok read_file);

my $Test = Test::Builder->new;

# compare string to a file's contents
sub cmp_file_ok($$;$) {
    my ($got, $file, $desc) = @_;

    unless (-e $file and -r $file) {
        $Test->ok(0, $desc);
        $Test->diag("$file not found or not readable");
        return 0;
    }

    my $ok = 0;

    my $expected = read_file($file);
    unless (defined $expected) {
        $Test->ok($ok = 0, $desc);
        $Test->diag("failed to open $file: $!");
    }
    else {
        # ignore whitespace differences
        $expected =~ s/[\r\n\s\t]//g;
        $got      =~ s/[\r\n\s\t]//g;

        return $Test->is_eq($got, $expected);
    }

    return $ok;
}

sub read_file($) {
    my $file = shift;

    local $/ = undef;

    my $fh = FileHandle->new("<$file") or return;

    my $data = <$fh>;

    return $data;
}

1;
