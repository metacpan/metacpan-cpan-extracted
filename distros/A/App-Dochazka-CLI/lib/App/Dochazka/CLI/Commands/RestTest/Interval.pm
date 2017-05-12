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

# $METHOD interval
sub _method_interval {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "interval", $th->{_REST} ];
}

# $METHOD interval eid $EID $TSRANGE
sub _method_interval_eid {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $eid = $th->{_NUM};

    return [ $method, "interval/eid/$eid", $th->{_REST} ];
}

# $METHOD interval eid $EID $TSRANGE
sub _method_interval_eid_tsrange {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $eid = $th->{_NUM};
    my $tsr = $th->{_TSRANGE};

    return [ $method, "interval/eid/$eid/$tsr", $th->{_REST} ];
}

# $METHOD interval fillup
sub _method_interval_fillup {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "interval/fillup", $th->{_REST} ];
}

# $METHOD interval iid $IID $JSON
sub _method_interval_iid {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $iid = $th->{_NUM};

    return [ $method, "interval/iid/$iid", $th->{_REST} ];
}

# $METHOD interval new
sub _method_interval_new {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "interval/new", $th->{_REST} ];
}

# $METHOD interval nick $NICK
sub _method_interval_nick {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};

    return [ $method, "interval/nick/$nick", $th->{_REST} ];
}

# $METHOD interval nick $NICK $TSRANGE
sub _method_interval_nick_tsrange {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $nick = $th->{_TERM};
    my $tsr = $th->{_TSRANGE};

    return [ $method, "interval/nick/$nick/$tsr", $th->{_REST} ];
}

# $METHOD interval self
sub _method_interval_self {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "interval/self", $th->{_REST} ];
}

# $METHOD interval self $TSRANGE
sub _method_interval_self_tsrange {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $tsr = $th->{_TSRANGE};

    return [ $method, "interval/self/$tsr", $th->{_REST} ];
}

#    # "/interval/summary/?:qualifiers"
#    if ( $token =~ m/^sum/ ) {
#        if ( @tokens ) {
#            die send_req( $method, 'interval/summary/' . join( ' ', @tokens ) );
#        }
#        die send_req( $method, "interval/summary" );
#    }

1;
