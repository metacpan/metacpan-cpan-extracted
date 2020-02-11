# ************************************************************************* 
# Copyright (c) 2014-2020, SUSE LLC
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

package App::CELL::Util;

use strict;
use warnings;
use 5.012;

use Data::Dumper;
use Date::Format;
use Params::Validate qw( :all );

=head1 NAME

App::CELL::Util - generalized, reuseable functions



=head1 SYNOPSIS

    use App::CELL::Util qw( utc_timestamp is_directory_viable );

    # utc_timestamp
    print "UTC time is " . utc_timestamp() . "\n";

    # is_directory_viable
    my $status = is_directory_viable( $dir_foo );
    print "$dir_foo is a viable directory" if $status->ok;
    if ( $status->not_ok ) {
        my $problem = $status->payload;
        print "$dir_foo is not viable because $problem\n";
    }

=cut


=head1 EXPORTS

This module provides the following public functions:

=over 

=item C<is_directory_viable>

=item C<stringify_args>

=item C<utc_timestamp>

=back

=cut 

use Exporter qw( import );
our @EXPORT_OK = qw( is_directory_viable stringify_args utc_timestamp );



=head1 PACKAGE VARIABLES

=cut

our $not_viable_reason = '';



=head1 FUNCTIONS


=head2 is_directory_viable

Run viability checks on a directory. Takes: full path to directory. Returns
true (directory viable) or false (directory not viable). If the directory
is not viable, it sets the package variable
C<< $App::CELL::Util::not_viable_reason >>.

=cut

sub is_directory_viable {

    my $confdir = shift;
    my $problem = '';

    CRIT_CHECK: {
        if ( not -e $confdir ) {
            $problem = "does not exist";
            last CRIT_CHECK;
        }
        if ( not -d $confdir ) {
            $problem = "exists but not a directory";
            last CRIT_CHECK;
        }
        if ( not -r $confdir or not -x $confdir ) {
            $problem = "directory exists but insufficient permissions";
            last CRIT_CHECK;
        }
    } # CRIT_CHECK

    if ( $problem ) {
        $not_viable_reason = $problem;
        return 0;
    }

    return 1;
}


=head2 stringify_args

Convert args (or any data structure) into a string -- useful for error
reporting.

=cut

sub stringify_args {
    my $args = shift;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Terse = 1;
    my $args_as_string;
    if ( ref $args ) {
        $args_as_string = Dumper( $args );
    } else {
        $args_as_string = $args;
    }
    return $args_as_string;
}


=head2 utc_timestamp

=cut

sub utc_timestamp {
   return uc time2str("%Y-%m-%d %H:%M %Z", time, 'GMT');
}


# END OF App::CELL::Util.pm
1;
