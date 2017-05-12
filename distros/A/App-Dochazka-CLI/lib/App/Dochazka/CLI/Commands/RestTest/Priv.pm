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

# $METHOD priv
sub _method_priv {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "priv", $th->{_REST} ];
}

# $METHOD priv eid $NUM
sub _method_priv_eid_num {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $eid = $th->{_NUM};

    return [ $method, "priv/eid/$eid", $th->{_REST} ];
}

# $METHOD priv eid $NUM $TIMESTAMP
sub _method_priv_eid_num_timestamp {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $eid = $th->{_NUM};
    my $timestamp = $th->{_TIMESTAMP};

    return [ $method, "priv/eid/$eid/$timestamp", $th->{_REST} ];
}

# $METHOD priv history eid $NUM
sub _method_priv_history_eid_num {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $eid = $th->{_NUM};

    return [ $method, "priv/history/eid/$eid", $th->{_REST} ];
}

# $METHOD priv history eid $NUM $TSRANGE
sub _method_priv_history_eid_num_tsrange {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $eid = $th->{_NUM};
    my $tsr = $th->{_TSRANGE};

    return [ $method, "priv/history/eid/$eid/$tsr", $th->{_REST} ];
}

# $METHOD priv history nick $TERM
sub _method_priv_history_nick_term {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};

    return [ $method, "priv/history/nick/$nick", $th->{_REST} ];
}

# $METHOD priv history nick $TERM $TSRANGE
sub _method_priv_history_nick_term_tsrange {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};
    my $tsr = $th->{_TSRANGE};

    return [ $method, "priv/history/nick/$nick/$tsr", $th->{_REST} ];
}

# $METHOD priv history phid $NUM
sub _method_priv_history_phid_num {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $phid = $th->{_NUM};

    return [ $method, "priv/history/phid/$phid", $th->{_REST} ];
}

# $METHOD priv history self
sub _method_priv_history_self {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "priv/history/self", $th->{_REST} ];
}

# $METHOD priv history self $TSRANGE
sub _method_priv_history_self_tsrange {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $tsr = $th->{_TSRANGE};

    return [ $method, "priv/history/self/$tsr", $th->{_REST} ];
}

# $METHOD priv nick $TERM
sub _method_priv_nick_term {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};

    return [ $method, "priv/nick/$nick", $th->{_REST} ];
}

# $METHOD priv nick $TERM $TIMESTAMP
sub _method_priv_nick_term_timestamp {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};
    my $timestamp = $th->{_TIMESTAMP};

    return [ $method, "priv/nick/$nick/$timestamp", $th->{_REST} ];
}

# $METHOD priv self
sub _method_priv_self {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "priv/self", $th->{_REST} ];
}

# $METHOD priv self $TIMESTAMP
sub _method_priv_self_timestamp {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $timestamp = $th->{_TIMESTAMP};

    return [ $method, "priv/self/$timestamp", $th->{_REST} ];
}

1;
