# Copyright (c) 2015 Jerry Lundström <lundstrom.jerry@gmail.com>
# Copyright (c) 2015 .SE (The Internet Infrastructure Foundation)
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
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

use 5.008000;
use Config;
use ExtUtils::MakeMaker;

# have_inc() EV's Makefile.PL by Marc Lehmann <schmorp@schmorp.de>
sub have_inc($) {
   scalar grep -r "$_/$_[0]", $Config{usrinc}, split / /, $Config{incpth}
}

my @LIBS;
my @DEFINES;
my %DL_FUNCS = (
    'Crypt__PKCS11' => [ 'boot_Crypt__PKCS11' ]
);

foreach my $module (qw(CK_AES CK_KIP CK_KEY CK_ECMQV CK_ECDH2 CK_SSL3
    CK_VERSION CK_WTLS CK_DES CK_RC2 CK_TLS CK_RC5 CK_OTP CK_SKIPJACK CK_X9
    CK_CMS CK_CAMELLIA CK_PKCS5 CK_KEA CK_ARIA CK_ECDH1 CK_PBE CK_MECHANISM
    CK_RSA STRUCT_XS))
{
    $DL_FUNCS{'Crypt__PKCS11__'.$module} = [ 'boot_Crypt__PKCS11__'.$module ];
}

if (have_inc('dlfcn.h')) {
    push(@LIBS, '-ldl');
    push(@DEFINES, '-DHAVE_DLFCN_H=1');
}

if ($ENV{TEST_DEVEL_COVER}) {
    push(@DEFINES, '-DTEST_DEVEL_COVER=1');
}

WriteMakefile(
    NAME              => 'Crypt::PKCS11',
    VERSION_FROM      => 'lib/Crypt/PKCS11.pm', # finds $VERSION
    BUILD_REQUIRES    => {
        'common::sense' => '3.00',
    },
    PREREQ_PM         => {
        'common::sense' => '3.00',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'lib/Crypt/PKCS11.pm', # retrieve abstract from module
       AUTHOR         => 'Jerry Lundström <lundstrom.jerry@gmail.com>') : ()),
    LIBS              => \@LIBS, # e.g., '-lm'
    DEFINE            => join(' ', @DEFINES), # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    OBJECT            => '$(O_FILES)', # link all the C files too
    TYPEMAPS          => [ 'typemap', 'typemap.struct' ],
    DL_FUNCS          => \%DL_FUNCS,
);
