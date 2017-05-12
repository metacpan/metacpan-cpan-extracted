#!perl

# Taken from http://www.chrisdolan.net/talk/index.php/2005/11/14/private-regression-tests/.

use warnings;
use strict;
use File::Find;
use File::Slurp;
use Test::More qw(no_plan);

my $last_version = undef;
find({wanted => \&check_version, no_chdir => 1}, 'blib');
if (! defined $last_version) {
    fail('Failed to find any files with $VERSION');
}

sub check_version {
    # $_ is the full path to the file
    return if (! m{blib/script/}xms && ! m{\.pm \z}xms);

    my $content = read_file($_);

    # only look at perl scripts, not sh scripts
    return if (m{blib/script/}xms && $content !~ m/\A \#![^\r\n]+?perl/xms);

    my @version_lines = $content =~ m/ ( [^\n]* \$VERSION [^\n]* ) /gxms;
    if (@version_lines == 0) {
       fail($_);
    }
    for my $line (@version_lines) {
        if (!defined $last_version) {
            $last_version = shift @version_lines;
            pass($_);
        }
        else {
            is($line, $last_version, $_);
        }
    }
}

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=0 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
