# ************************************************************************* 
# Copyright (c) 2014-2016, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

# -----------------------------------
# Dochazka-CLI
# -----------------------------------
# CLI_Config.pm
#
# Main configuration file
# -----------------------------------

# DOCHAZKA_REST_LOGIN_NICK
#     nick to use when we authenticate ourselves to the App::Dochazka::REST server
#     when this is set to '' or undef, App::Dochazka::CLI will prompt for it
set( 'DOCHAZKA_REST_LOGIN_NICK', undef );

# DOCHAZKA_REST_LOGIN_NICK
#     password to use when we authenticate ourselves to the App::Dochazka::REST server
#     when this is set to '' or undef, App::Dochazka::CLI will prompt for a password
#     WARNING: PUTTING YOUR PASSWORD HERE MAY BE CONVENIENT, BUT IS PROBABLY UNSAFE
set( 'DOCHAZKA_REST_LOGIN_PASSWORD', undef );

# MREST_CLI_COOKIE_JAR
#     default location of the cookie jar
set( 'MREST_CLI_COOKIE_JAR', "$ENV{HOME}/.cookies.txt" );

# DOCHAZKA_CLI_LOG_FILE
#     default location of the log file
set( 'DOCHAZKA_CLI_LOG_FILE', "$ENV{HOME}/.dochazka-cli.log" );

# MREST_CLI_SUPPRESSED_HEADERS
#     list of headers to be suppressed in the output
set ('MREST_CLI_SUPPRESSED_HEADERS', [ qw( 
    accept content-type content-length cache-control pragma expires
    server Client-Response-Num Client-Peer Client-Date Set-Cookie Date
    Vary Client-SSL-Cert-Subject Client-SSL-Cipher
    Client-SSL-Socket-Class Client-SSL-Cert-Issuer Connection
    Strict-Transport-Security
) ] );


# -----------------------------------
# DO NOT EDIT ANYTHING BELOW THIS LINE
# -----------------------------------
use strict;
use warnings;

1;
