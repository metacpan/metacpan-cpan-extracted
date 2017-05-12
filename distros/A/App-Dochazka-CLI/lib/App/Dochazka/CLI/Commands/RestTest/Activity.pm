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


# $METHOD activity
sub _method_activity {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "activity", $th->{_REST} ];
}

# $METHOD activity aid $JSON
sub _method_activity_aid {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "activity/aid", $th->{_JSON} ];
}

# $METHOD activity aid $AID [$JSON]
sub _method_activity_aid_num {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $num = $th->{_NUM};

    return [ $method, "activity/aid/$num", $th->{_REST} ];
}

# $METHOD activity all
sub _method_activity_all {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "activity/all", $th->{_REST} ];
}

# $METHOD activity all disabled
sub _method_activity_all_disabled {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "activity/all/disabled", $th->{_REST} ];
}

# $METHOD activity code $JSON
sub _method_activity_code {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];

    return [ $method, "activity/code", $th->{_JSON} ];
}

# $METHOD activity code $CODE [$JSON]
sub _method_activity_code_term {
    my ( $ts, $th ) = @_;
    my $method = $ts->[0];
    my $code = $th->{_TERM};

    return [ $method, "activity/code/$code", $th->{_REST} ];
}

1;
