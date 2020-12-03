#!/usr/bin/env perl

use strict;
use warnings;

BEGIN { unshift @INC, '.' }

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
    my @paths = split(' ', $Config{libpth});
    push @paths, $ENV{PERL_LIBPATH} if exists $ENV{PERL_LIBPATH};
    for my $path (@paths) {
        if (-f $path . '/' . $libbase) {
            print "$path/$libbase\n";
            print "Found '$path/$libbase'.\n";
            return $lib;
        } elsif (-f $path . '/' . $libbase_so) {
            print "$path/$libbase_so\n";
            print "Found `$path/$libbase_so'.\n";
            return $lib;
        }
    }
    return undef;
}

if (!defined search_lib('-lcrypto')) {
        warn "* libcrypto is not installed or not in the default lib path. Aborting.\n";
        exit;
}

name 'Crypt-OpenSSL-Verify';
license 'perl';
all_from 'Verify.pm';

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
cc_optimize_flags('-O3 -Wall -Werror -DOPENSSL_API_COMPAT=0x10100000L');

requires 'Crypt::OpenSSL::X509' => '1.807';

author_requires 'Test::NoTabs';
author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.04';

test_requires 'Test::More' => '0.88';
test_requires 'File::Slurp';
test_requires 'Test::Exception';

resources
     license     => "http://dev.perl.org/licenses",
     bugtracker  => "https://github.com/perl-Net-SAML2/perl-Crypt-OpenSSL-Verify/issues",
     repository  => "https://github.com/perl-Net-SAML2/perl-Crypt-OpenSSL-Verify";

author_tests 't/author';

WriteAll();

