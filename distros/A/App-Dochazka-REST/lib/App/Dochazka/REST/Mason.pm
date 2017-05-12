# ************************************************************************* 
# Copyright (c) 2014-2015, SUSE LLC
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

# ------------------------
# store and dispense Mason interpreter singleton
# ------------------------

package App::Dochazka::REST::Mason;

use strict;
use warnings;

use App::CELL qw( $CELL $log $site );
use Mason;
use Params::Validate qw( :all );
use Try::Tiny;



=head1 NAME

App::Dochazka::REST::Mason - Mason interpreter singleton



=head1 SYNOPSIS

    use App::Dochazka::REST::Mason qw( $interp );



=head1 DESCRIPTION

Mason interpreter singleton.

=cut



=head1 EXPORTS

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( $comp_root $interp );



=head1 PACKAGE VARIABLES

This module stores and initializes the L<Mason> interpreter singleton object.

=cut

our ( $comp_root, $interp );



=head1 FUNCTIONS


=head2 init_singleton

Initialize the C<$interp> singleton. Takes a C<comp_root> and a
C<data_dir> which are expected to exist and be owned by the effective user.

Idempotent.

FIXME: Add parameters to the Mason->new() call as needed.

=cut

sub init_singleton {
    my @ARGS = @_;
    my %ARGS;
    my $status = $CELL->status_ok;
    try {
        %ARGS = validate(
            @ARGS, {
                comp_root => { type => SCALAR },
                data_dir => { type => SCALAR },
            }
        );
        die "Mason comp_root $ARGS{comp_root} has a problem" unless
            (
                -r $ARGS{comp_root} and
                -w $ARGS{comp_root} and
                -x $ARGS{comp_root}
            );
        die "Mason comp_root $ARGS{data_dir} has a problem" unless
            (
                -r $ARGS{comp_root} and
                -w $ARGS{comp_root} and
                -x $ARGS{comp_root}
            );
        $interp = Mason->new(
            comp_root => $ARGS{comp_root},
            data_dir  => $ARGS{data_dir},
            class_header => q(
                use App::CELL qw( $CELL $log $meta $site );
            ),
        );
        $comp_root = $ARGS{comp_root};
    } catch {
        $status = $CELL->status_crit( 'DOCHAZKA_MASON_INIT_FAIL', args => [ $_ ] );
    };
    return $status;
}

1;
