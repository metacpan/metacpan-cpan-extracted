#!/usr/bin/perl -w

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

# $Id: 00-loadme.t,v 1.2 2002/10/09 16:36:35 ajk Exp $

# check module signature

use strict;

print "1..1\n";

if (!-s 'SIGNATURE') {
    print "ok 1 # skip No signature file found\n";
}

elsif (!eval { require Module::Signature; 1 }) {
    print "ok 1 # skip ", "Consider installing Module::Signature ",
          "so you can verify the integrity of this distribution.\n";
}

elsif ( !eval { require Socket; Socket::inet_aton('pgp.mit.edu') } ) {
    print "ok 1 # skip ", "Cannot connect to the keyserver\n";
}

else {
    ( Module::Signature::verify() == Module::Signature::SIGNATURE_OK() )
        or print "not ";
    print "ok 1 # Valid signature\n";
}
