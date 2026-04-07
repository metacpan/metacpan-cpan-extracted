#!/usr/bin/env perl -T

# BBS Universal Generalized Test

use strict;
use Test::More tests => 14;
use Term::ANSIColor;

BEGIN {
	use_ok('BBS::Universal');
}

diag("\n\r" . colored(['bright_yellow'], "\e[4m                                    "));
diag("\r" . colored(['bright_yellow'], '▏') . colored(['cyan on_black'], q{ _______        _   _              }) . colored(['yellow'], '◣'));
diag("\r" . colored(['bright_yellow'], '▏') . colored(['cyan on_black'], q{|__   __|      | | (_)             }) . colored(['yellow'], '█'));
diag("\r" . colored(['bright_yellow'], '▏') . colored(['cyan on_black'], q{   | | ___  ___| |_ _ _ __   __ _  }) . colored(['yellow'], '█'));
diag("\r" . colored(['bright_yellow'], '▏') . colored(['cyan on_black'], q{   | |/ _ \/ __| __| | '_ \ / _` | }) . colored(['yellow'], '█'));
diag("\r" . colored(['bright_yellow'], '▏') . colored(['cyan on_black'], q{   | |  __/\__ \ |_| | | | | (_| | }) . colored(['yellow'], '█'));
diag("\r" . colored(['bright_yellow'], '▏') . colored(['cyan on_black'], q{   |_|\___||___/\__|_|_| |_|\__, | }) . colored(['yellow'], '█'));
diag("\r" . colored(['bright_yellow'], '▏') . colored(['cyan on_black'], q{                             __/ | }) . colored(['yellow'], '█'));
diag("\r" . colored(['bright_yellow'], '▏') . colored(['cyan on_black'], q{  BBS::Universal            |___/  }) . colored(['yellow'], '█'));
diag("\r" . colored(['bright_yellow'], '▏                                   ') . colored(['yellow'], '█'));
diag("\r" . colored(['bright_yellow'],        '◥████████████████████████████████████'));
diag("\r  \r");

my $green = colored(['bright_green'], ' ok');
my $red   = colored(['red'],          ' not ok');

my $tree = {
    'BBS::Universal'               => $BBS::Universal::VERSION,
    'BBS::Universal::ASCII'        => $BBS::Universal::ASCII_VERSION,
    'BBS::Universal::ATASCII'      => $BBS::Universal::ATASCII_VERSION,
    'BBS::Universal::ANSI'         => $BBS::Universal::ANSI_VERSION,
    'BBS::Universal::PETSCII'      => $BBS::Universal::PETSCII_VERSION,
    'BBS::Universal::BBS_List'     => $BBS::Universal::BBS_LIST_VERSION,
    'BBS::Universal::CPU'          => $BBS::Universal::CPU_VERSION,
    'BBS::Universal::Messages'     => $BBS::Universal::MESSAGES_VERSION,
	'BBS::Universal::News'         => $BBS::Universal::NEWS_VERSION,
    'BBS::Universal::SysOp'        => $BBS::Universal::SYSOP_VERSION,
    'BBS::Universal::FileTransfer' => $BBS::Universal::FILETRANSFER_VERSION,
    'BBS::Universal::Users'        => $BBS::Universal::USERS_VERSION,
    'BBS::Universal::DB'           => $BBS::Universal::DB_VERSION,
};

foreach my $name (sort(keys %{$tree})) {
	my $string = '';
	ok((defined($tree->{$name}) && $tree->{$name} > 0), $name);
    if (defined($tree->{$name}) && $tree->{$name} > 0) {
        $string .= "\r" . colored(['bright_white'], sprintf('%-30s', $name)) . colored(['bright_yellow'], $tree->{$name}) . $green . "\n";
    } else {
        $string .= "\r" . colored(['bright_white'], sprintf('%-30s', $name)) . 'undef' . $red . "\n";
    }
	diag($string);
}

diag("\r  ");
exit(0);
