#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

use Config;

sub search_lib {
    my ($lib) = @_;
    unless ($lib =~ /^-l/) {
        warn "search_lib: illegal arguments, \`$lib\'.\n";
        return undef;
    }
    my $libbase = 'lib' . substr($lib, 2) . $Config{lib_ext};
    my $libbase_so = 'lib' . substr($lib, 2) . "." . $Config{so};
    for my $path (split(' ', $Config{libpth})) {
        if (-f $path . '/' . $libbase) {
            print "$path/$libbase\n";
            print "Found '$path/$libbase'.\n";
            return $lib;
        } elsif (-f $path . '/' . $libbase_so) {
            print "$path/$libbase_so\n";
            print "Found `$_/$libbase_so'.\n";
            return $lib;
        }
    }
    return undef;
}

if (!defined search_lib('-lcrypto')) {
        warn "* libcrypto is not installed or not in the default lib path. Aborting.\n";
        exit;
}

name 'Crypt-OpenSSL-VerifyX509';
license 'perl';
all_from 'VerifyX509.pm';

requires_external_cc();

if (-d "/usr/include/openssl") {
	cc_inc_paths('/usr/include/openssl');
	cc_lib_paths('/usr/lib');
} elsif (-d "/usr/local/include/ssl") {
	cc_inc_paths('/usr/local/include/ssl');
	cc_lib_paths('/usr/local/lib/ssl');
} elsif (-d "/usr/local/ssl/include") {
	cc_inc_paths('/usr/local/ssl/include');
	cc_lib_paths('/usr/local/ssl/lib');
}

cc_lib_links('crypto');
cc_optimize_flags('-O3 -Wall -Werror');

requires 'Crypt::OpenSSL::X509';

author_requires 'Test::NoTabs';
author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.04';

test_requires 'Test::More' => '0.88';

resources
     license     => "http://dev.perl.org/licenses",
     bugtracker  => "http://rt.cpan.org/NoAuth/Bugs.html?Dist=Crypt-OpenSSL-VerifyX509",
     repository  => "http://github.com/chrisa/perl-Crypt-OpenSSL-VerifyX509";

author_tests 't/author';

WriteAll();

