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

# $METHOD schedule
sub _method_schedule {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "schedule", $th->{_REST} ];
}

# $METHOD schedule all
sub _method_schedule_all {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "schedule/all", $th->{_REST} ];
}

# $METHOD schedule all disabled
sub _method_schedule_all_disabled {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "schedule/all/disabled", $th->{_REST} ];
}

# $METHOD schedule eid $NUM
sub _method_schedule_eid_num {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $eid = $th->{_NUM};

    return [ $method, "schedule/eid/$eid", $th->{_REST} ];
}

# $METHOD schedule eid $NUM $TIMESTAMP
sub _method_schedule_eid_num_timestamp {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $eid = $th->{_NUM};
    my $timestamp = $th->{_TIMESTAMP};

    return [ $method, "schedule/eid/$eid/$timestamp", $th->{_REST} ];
}

# $METHOD schedule history eid $NUM
sub _method_schedule_history_eid_num {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $eid = $th->{_NUM};

    return [ $method, "schedule/history/eid/$eid", $th->{_REST} ];
}

# $METHOD schedule history eid $NUM $TSRANGE
sub _method_schedule_history_eid_num_tsrange {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $eid = $th->{_NUM};
    my $tsr = $th->{_TSRANGE};

    return [ $method, "schedule/history/eid/$eid/$tsr", $th->{_REST} ];
}

# $METHOD schedule history nick $TERM
sub _method_schedule_history_nick_term {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};

    return [ $method, "schedule/history/nick/$nick", $th->{_REST} ];
}

# $METHOD schedule history nick $TERM $TSRANGE
sub _method_schedule_history_nick_term_tsrange {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};
    my $tsr = $th->{_TSRANGE};

    return [ $method, "schedule/history/nick/$nick/$tsr", $th->{_REST} ];
}

# $METHOD schedule history self
sub _method_schedule_history_self {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "schedule/history/self", $th->{_REST} ];
}

# $METHOD schedule history self $TSRANGE
sub _method_schedule_history_self_tsrange {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $tsr = $th->{_TSRANGE};

    return [ $method, "schedule/history/self/$tsr", $th->{_REST} ];
}

# $METHOD schedule history shid $NUM
sub _method_schedule_history_shid_num {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $shid = $th->{_NUM};

    return [ $method, "schedule/history/shid/$shid", $th->{_REST} ];
}

# $METHOD schedule nick $TERM
sub _method_schedule_nick_term {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};

    return [ $method, "schedule/nick/$nick", $th->{_REST} ];
}

# $METHOD schedule nick $TERM $TIMESTAMP
sub _method_schedule_nick_term_timestamp {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};
    my $timestamp = $th->{_TIMESTAMP};

    return [ $method, "schedule/nick/$nick/$timestamp", $th->{_REST} ];
}

# $METHOD schedule self
sub _method_schedule_self {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "schedule/self", $th->{_REST} ];
}

# $METHOD schedule self $TIMESTAMP
sub _method_schedule_self_timestamp {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $timestamp = $th->{_TIMESTAMP};

    return [ $method, "schedule/self/$timestamp", $th->{_REST} ];
}

# $METHOD schedule sid $NUMBER
sub _method_schedule_sid_num {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $sid = $th->{_NUM};

    return [ $method, "schedule/sid/$sid", $th->{_REST} ];
}

# $METHOD schedule scode $SCODE
sub _method_schedule_scode_term {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $scode = $th->{_TERM};

    return [ $method, "schedule/scode/$scode", $th->{_REST} ];
}

1;
