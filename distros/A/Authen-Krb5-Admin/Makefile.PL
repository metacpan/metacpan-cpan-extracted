# Copyright (c) 2002 Andrew J. Korty
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# $Id: Makefile.PL,v 1.16 2008/02/25 13:43:46 ajk Exp $

use strict;

use ExtUtils::MakeMaker;

# Use the krb5-config tool if available

my $KRB5_CONFTOOL;
print 'checking for krb5-config ... ';
for my $path ( $ENV{KRB5_CONFTOOL}, '/usr/local/bin/krb5-config', '/usr/bin/krb5-config' ) {
  if ( $path && -x $path ) {
    $KRB5_CONFTOOL = $path;
    last;
  }
}
if ($KRB5_CONFTOOL) {
  print "found\n";
} else {
  print "not found, will use fallback methods\n"
}

# location of Kerberos 5 libraries and header files

print 'checking for Kerberos 5 prefix ... ';
my $PREFIX;
if ($KRB5_CONFTOOL) {
  chomp( $PREFIX = `$KRB5_CONFTOOL --prefix` );
} else {
  ($PREFIX) = grep { -r "$_/include/krb5.h" }
              qw(/opt/krb5 /usr/local /usr /usr/kerberos);
}

if ($PREFIX) {
    print "$PREFIX\n";
} else {
    print "Cannot find Kerberos 5\n";
    exit 0;
}

my $KRB5_BINDIR = $ENV{KRB5_BINDIR} || "$PREFIX/bin"    ;
my $KRB5_LIBDIR = $ENV{KRB5_LIBDIR} || "$PREFIX/lib"    ;
my $KRB5_INCDIR = $ENV{KRB5_INCDIR} || "$PREFIX/include";

# any extra libraries or include flags

my $KRB5_EXTRALIBS = '';
my $KRB5_EXTRAINCS = "-I$PREFIX/include/et";

# principal used by test suite to authenticate to kadmin server (will
# prompt if undef--you must do your own kinit if you set this)

my $KADM5_PRINCIPAL   = $ENV{PERL_KADM5_PRINCIPAL};
my $default_admin     = "$ENV{USER}/admin";

# principal/policy name used by test suite--will be created, modified,
# deleted, etc.

my $KADM5_TEST_NAME     = $ENV{PERL_KADM5_TEST_NAME  };
my $KADM5_TEST_NAME_2   = $ENV{PERL_KADM5_TEST_NAME_2};
my $default_test_name   = 'perl_test'  ;
my $default_test_name_2 = 'perl_test_2';

##### DO NOT CHANGE ANYTHING BELOW HERE #####

# check for libk5crypto -- only in krb5-1.1 and above

print 'checking for libk5crypto ... ';
my $cryptolib;
if ( -r "$KRB5_LIBDIR/libk5crypto.a" ||
     -r "$KRB5_LIBDIR/libk5crypto.so" ) {
    print "found\n";
    $cryptolib = '-lk5crypto';
} else {
    print "not found (using libcrypto)\n";
    $cryptolib = '-lcrypto';
}

print 'checking for kadm5/admin.h ... ';
my $KRB5_DEFS = '';
if ( -f "$KRB5_INCDIR/kadm5/admin.h" ) {
  print "found\n";
} else {
  print "not found, assuming this is Kerberos 1.6\n";
  $KRB5_DEFS .= ' -DUSE_LOCAL_ADMINH';
}

print 'checking for kdb.h ... ';
if ( -f "$KRB5_INCDIR/kdb.h" ) {
  print "found\n";
  $KRB5_DEFS .= ' -DHAVE_KDB_H';
} else {
  print "not found, assuming this is Kerberos 1.6\n";
}

# get values for test suite

unless ($KADM5_PRINCIPAL) {
    print 'Authenticate as user/instance[@REALM] for testing ',
          "[$default_admin]: ";
    $KADM5_PRINCIPAL = <STDIN>;
    chomp $KADM5_PRINCIPAL;
    $KADM5_PRINCIPAL ||= $default_admin;
}

unless ($KADM5_TEST_NAME) {
    print 'Use user/instance (should NOT exist!) for testing ',
          "[$default_test_name]: ";
    $KADM5_TEST_NAME = <STDIN>;
    chomp $KADM5_TEST_NAME;
    $KADM5_TEST_NAME ||= $default_test_name;
}

unless ($KADM5_TEST_NAME_2) {
    print 'Use user/instance (should NOT exist!) for testing renames ',
          "[$default_test_name_2]: ";
    $KADM5_TEST_NAME_2 = <STDIN>;
    chomp $KADM5_TEST_NAME_2;
    $KADM5_TEST_NAME_2 ||= $default_test_name_2;
}

sub MY::insert_kinit_maybe {
    my ($commands) = @_;
    my $test_cache = $ENV{PERL_KADM5_TEST_CACHE} || '/tmp/perl_test';
    my $new_vars = join ' ', "PERL_KADM5_PRINCIPAL=$KADM5_PRINCIPAL",
                             "PERL_KADM5_TEST_NAME=$KADM5_TEST_NAME",
                             "PERL_KADM5_TEST_NAME_2=$KADM5_TEST_NAME_2",
                             "PERL_KADM5_TEST_CACHE=$test_cache ";
    $commands =~ s/PERL_DL_NONLAZY=1 /$new_vars /;
    return exists $ENV{PERL_KADM5_TEST_CACHE}
         ? $commands
         : "\t$KRB5_BINDIR/kinit -S kadmin/admin -c $test_cache -l 50m "
           . "$KADM5_PRINCIPAL\n$commands"
         ;
}

sub MY::test_via_harness {
    package MY;
    return insert_kinit_maybe shift->SUPER::test_via_harness(@_);
}

sub MY::test_via_script {
    package MY;
    return insert_kinit_maybe shift->SUPER::test_via_script(@_);
}

WriteMakefile(
    DEFINE       => "$KRB5_DEFS",
    INC          => "-I$KRB5_INCDIR $KRB5_EXTRAINCS",
    LIBS         => ["-L$KRB5_LIBDIR -lkadm5clnt -lcom_err",
                     $KRB5_EXTRALIBS],
    NAME         => 'Authen::Krb5::Admin',
    NO_META      => 1,
    PREREQ_PM    => {'Authen::Krb5' => 1.2},
    VERSION_FROM => 'Admin.pm',
);
