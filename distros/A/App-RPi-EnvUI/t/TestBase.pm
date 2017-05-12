package TestBase;
use warnings;
use strict;

use Exporter qw(import);
our @EXPORT = qw(
    set_testing
    unset_testing
    db_create
    db_remove
    config
    unconfig
);

use File::Copy;

my $config = 'src/envui-dist.json';

sub db_create {
    copy 'src/envui-dist.db', 't/envui.db' or die $!;
}
sub db_remove {
    unlink 't/envui.db' or die $!;
}
sub set_testing {
    open my $fh, '>', 't/testing.lck' or die $!;
    print $fh 1;
    close $fh;
}
sub unset_testing {
    unlink 't/testing.lck' or die if -e 't/testing.lck';
}
sub config {
    copy $config, 't/envui.json' or die;
}
sub unconfig {
    unlink "t/envui.json" or die $! if -e "t/envui.json";
}

1;
__END__

=head1 NAME TestBase - Utility class for unit testing

=head1 DESCRIPTION

This class is only used for unit testing L<App::RPi::EnvUI>.
