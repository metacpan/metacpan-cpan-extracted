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

# $METHOD employee
sub _method_employee {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "employee", $th->{_REST} ];
}

# $METHOD employee count
sub _method_employee_count {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "employee/count", $th->{_REST} ];
}

# $METHOD employee count priv
sub _method_employee_count_priv {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "employee/count/priv", $th->{_REST} ];
}

# $METHOD employee search
sub _method_employee_search {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "employee/search", $th->{_REST} ];
}

# $METHOD employee search nick _TERM
sub _method_employee_search_nick {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};

    return [ $method, "employee/search/nick/$nick", $th->{_REST} ];
}

# $METHOD employee self
sub _method_employee_self {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "employee/self", $th->{_REST} ];
}

# $METHOD employee self full
sub _method_employee_self_full {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "employee/self/full", $th->{_REST} ];
}

# $METHOD employee eid
sub _method_employee_eid {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "employee/eid", '' ];
}

# $METHOD employee eid $JSON
sub _method_employee_eid_json {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "employee/eid", $th->{_JSON} ];
}

# $METHOD employee eid $EID
sub _method_employee_eid_num {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $eid = $th->{_NUM};

    return [ $method, "employee/eid/$eid", '' ];
}

# $METHOD employee eid $EID $JSON
sub _method_employee_eid_num_json {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $eid = $th->{_NUM};
    my $json = $th->{_JSON};

    return [ $method, "employee/eid/$eid", $json ];
}

# $METHOD employee eid $EID team
sub _method_employee_eid_num_team {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $eid = $th->{_NUM};

    return [ $method, "employee/eid/$eid/team", '' ];
}

# $METHOD employee list
sub _method_employee_list {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "employee/list", '' ];
}

# $METHOD employee list $PRIV
sub _method_employee_list_priv {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $priv = $th->{_TERM};

    return [ $method, "employee/list/$priv", '' ];
}

# $METHOD employee nick
sub _method_employee_nick {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "employee/nick", '' ];
}

# $METHOD employee nick $JSON
sub _method_employee_nick_json {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "employee/nick", $th->{_JSON} ];
}

# $METHOD employee nick $NICK
sub _method_employee_nick_term {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};

    return [ $method, "employee/nick/$nick", '' ];
}

# $METHOD employee nick $NICK ldap
sub _method_employee_nick_term_ldap {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};

    return [ $method, "employee/nick/$nick/ldap", '' ];
}

# $METHOD employee nick $nick $JSON
sub _method_employee_nick_term_json {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};
    my $json = $th->{_JSON};

    return [ $method, "employee/nick/$nick", $json ];
}

# $METHOD employee nick $nick team
sub _method_employee_nick_term_team {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};

    return [ $method, "employee/nick/$nick/team", '' ];
}

# $METHOD employee search nick $KEY
#sub _method_employee_search_nick_key {
#}

# $METHOD employee team
sub _method_employee_team {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "employee/team", '' ];
}

1;
