package Class::Mock::Common;

use strict;
use warnings;

our $VERSION='1.3002';

sub _get_tests_from_file {
    my $filename = shift;
    local $/ = undef;
    open(my $fh, '<', $filename) || die("Can't open $filename: $!\n");
    my $content = <$fh>;
    close($fh);
    my $tests = do {
        no strict;
        eval($content);
    };
    die("File $filename isn't valid perl\n") if($@);
    die("File $filename didn't evaluate to an arrayref\n")
        unless(ref($tests) eq 'ARRAY');
    return @{$tests};
}

1;
