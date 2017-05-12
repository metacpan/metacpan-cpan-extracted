use strict;
use warnings;
use Test::More 0.88;
use File::Spec::Functions qw( catfile ); # core
use Test::Warnings ':all', ':no_end_test';

use App::Software::License;

my $holder = 'A.Holder';
my $year = (localtime)[5] + 1900;

my $configfile = catfile(File::HomeDir->my_home, '.software_license.conf');
if (-e $configfile) {
    diag 'found a config file: ', $configfile, ':';
    local $/;
    open my $fh, '<', $configfile or die "cannot open $configfile: $!";
    diag <$fh>;
}


sub test_opts {
    my ($argv, $re, $desc) = @_;
    local @ARGV = @$argv;
    like(
        App::Software::License->new_with_options->_software_license->notice,
        $re,
        $desc,
    );
}

my @warnings =
grep { !/Specified configfile '.*' does not exist, is empty, or is not readable/s }
warnings {

test_opts(
    [qw( --holder A.Holder --license=BSD )],
    qr/^\QThis software is Copyright (c) $year by $holder.\E.*BSD/ms,
    'basic args',
);
test_opts(
    [qw( --holder=A.Holder BSD )],
    qr/^\QThis software is Copyright (c) $year by $holder.\E.*BSD/ms,
    'license as last (non-option) argument',
);
test_opts(
    [qw( --holder A.Holder BSD )],
    qr/^\QThis software is Copyright (c) $year by $holder.\E.*BSD/ms,
    'license as last (non-option) argument II',
);
test_opts(
    [qw( --year=2000 --holder=A.Holder BSD )],
    qr/^\QThis software is Copyright (c) 2000 by $holder.\E.*BSD/ms,
    'specify year',
);
test_opts(
    [qw( --configfile t/etc/software_license.json )],
    qr/^\QThis software is copyright (c) $year by $holder.\E.*Perl/ms,
    'config file but using default license',
);
test_opts(
    [qw( --configfile t/etc/software_license.json BSD )],
    qr/^\QThis software is Copyright (c) $year by $holder.\E.*BSD/ms,
    'config file with license as last (non-option) argument',
);

};

warn @warnings if @warnings;

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
