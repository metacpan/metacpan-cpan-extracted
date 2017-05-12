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


# $METHOD lock
sub _method_lock {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'lock', $th->{_REST} ];
}

# $METHOD lock eid $EID
sub _method_lock_eid {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $eid = $th->{_NUM};

    return [ $method, "lock/eid/$eid", $th->{_REST} ];
}

# $METHOD lock eid $EID $TSRANGE
sub _method_lock_eid_tsrange {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $eid = $th->{_NUM};
    my $tsr = $th->{_TSRANGE};

    return [ $method, "lock/eid/$eid/$tsr", $th->{_REST} ];
}

# $METHOD lock lid $LID
sub _method_lock_lid {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $lid = $th->{_NUM};

    return [ $method, "lock/lid/$lid", $th->{_REST} ];
}

# $METHOD lock new
sub _method_lock_new {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, 'lock/new', $th->{_REST} ];
}

# $METHOD lock nick $NICK
sub _method_lock_nick {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};

    return [ $method, "lock/nick/$nick", $th->{_REST} ];
}

# $METHOD lock nick $NICK $TSRANGE
sub _method_lock_nick_tsrange {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};
    my $tsr = $th->{_TSRANGE};

    return [ $method, "lock/nick/$nick/$tsr", $th->{_REST} ];
}

# $METHOD lock self $SELF
sub _method_lock_self {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "lock/self", $th->{_REST} ];
}

# $METHOD lock self $SELF $TSRANGE
sub _method_lock_self_tsrange {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $tsr = $th->{_TSRANGE};

    return [ $method, "lock/self/$tsr", $th->{_REST} ];
}

1;
