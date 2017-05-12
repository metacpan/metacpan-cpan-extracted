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
#

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL );
use Web::MREST::CLI;




=head1 NAME

App::Dochazka::CLI::Commands::Top - Dispatch targets for top-level commands




=head1 FUNCTIONS

=cut

# just the bare $METHOD
sub _method {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    return [ $method, "", $th->{_REST} ];
}

# $METHOD BUGREPORT
sub _method_bugreport {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'bugreport', $th->{_REST} ];
}

# $METHOD CONFIGINFO
sub _method_configinfo {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'configinfo', $th->{_REST} ];
}

# $METHOD COOKIEJAR
sub _method_cookiejar {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    my $cookie_jar = Web::MREST::CLI::cookie_jar() || "No cookies in jar";

    return $CELL->status_ok( 'COOKIE_JAR', payload => $cookie_jar );
}

# $METHOD DBSTATUS
sub _method_dbstatus {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'dbstatus', $th->{_REST} ];
}

# $METHOD DOCU
sub _method_docu {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'docu', $th->{_REST} ];
}

# $METHOD DOCU POD
sub _method_docu_pod {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'docu/pod', $th->{_REST} ];
}

# $METHOD DOCU POD _DOCU
sub _method_docu_pod_docu {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'docu/pod', $th->{_DOCU} ];
}

# $METHOD DOCU HTML
sub _method_docu_html {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'docu/html', $th->{_REST} ];
}

# $METHOD DOCU HTML $DOCU
sub _method_docu_html_docu {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'docu/html', $th->{_DOCU} ];
}

# $METHOD DOCU TEXT
sub _method_docu_text {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'docu/text', $th->{_REST} ];
}

# $METHOD DOCU TEXT $DOCU
sub _method_docu_text_docu {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'docu/text', $th->{_DOCU} ];
}

# $METHOD ECHO
sub _method_echo {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'echo', $th->{_REST} ];
} 

# $METHOD FORBIDDEN
sub _method_forbidden {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'forbidden', $th->{_REST} ];
}

# $METHOD HOLIDAY _TSRANGE
sub _method_holiday_tsrange {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $tsrange = $th->{_TSRANGE};

    return [ $method, "holiday/$tsrange", $th->{_REST} ];
}

# $METHOD NOOP
sub _method_noop {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'noop', $th->{_REST} ];
}

# $METHOD PARAM
sub _method_param {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'param', $th->{_REST} ];
}

# $METHOD PARAM CORE
sub _method_param_core {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "param/core", $th->{_REST} ];
}

# $METHOD PARAM META
sub _method_param_meta {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $term = $th->{_TERM};

    return [ $method, "param/meta", $th->{_REST} ];
}

# $METHOD PARAM SITE
sub _method_param_site {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $term = $th->{_TERM};

    return [ $method, "param/site", $th->{_REST} ];
}

# $METHOD PARAM CORE
sub _method_param_core_term {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $term = $th->{_TERM};

    return [ $method, "param/core/$term", $th->{_REST} ];
}

# $METHOD PARAM META
sub _method_param_meta_term {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $term = $th->{_TERM};

    return [ $method, "param/meta/$term", $th->{_REST} ];
}

# $METHOD PARAM SITE
sub _method_param_site_term {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $term = $th->{_TERM};

    return [ $method, "param/site/$term", $th->{_REST} ];
}

# $METHOD SESSION
sub _method_session {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'session', $th->{_REST} ];
}

# $METHOD VERSION
sub _method_version {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'version', $th->{_REST} ];
}

# $METHOD WHOAMI
sub _method_whoami {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'whoami', $th->{_REST} ];
}

1;
