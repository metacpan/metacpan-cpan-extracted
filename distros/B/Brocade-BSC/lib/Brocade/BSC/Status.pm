# Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from this
# software without specific prior written permission.
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
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
# THE POSSIBILITY OF SUCH DAMAGE.

=head1 NAME

Brocade::BSC::Status

=head1 DESCRIPTION

Object representing status of an API call.

=cut

package Brocade::BSC::Status;

use strict;
use warnings;

use Readonly;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    $BSC_OK
    $BSC_CONN_ERROR
    $BSC_DATA_NOT_FOUND
    $BSC_BAD_REQUEST
    $BSC_UNAUTHORIZED_ACCESS
    $BSC_INTERNAL_ERROR
    $BSC_NODE_CONNECTED
    $BSC_NODE_DISCONNECTED
    $BSC_NODE_NOT_FOUND
    $BSC_NODE_CONFIGURED
    $BSC_HTTP_ERROR
    $BSC_MALFORMED_DATA
    $BSC_UNKNOWN
);
our %EXPORT_TAGS = (constants => [@EXPORT_OK]);

Readonly our $BSC_OK                  =>  0;
Readonly our $BSC_CONN_ERROR          =>  1;
Readonly our $BSC_DATA_NOT_FOUND      =>  2;
Readonly our $BSC_BAD_REQUEST         =>  3;
Readonly our $BSC_UNAUTHORIZED_ACCESS =>  4;
Readonly our $BSC_INTERNAL_ERROR      =>  5;
Readonly our $BSC_NODE_CONNECTED      =>  6;
Readonly our $BSC_NODE_DISCONNECTED   =>  7;
Readonly our $BSC_NODE_NOT_FOUND      =>  8;
Readonly our $BSC_NODE_CONFIGURED     =>  9;
Readonly our $BSC_HTTP_ERROR          => 10;
Readonly our $BSC_MALFORMED_DATA      => 11;
Readonly our $BSC_UNKNOWN             => 12;

Readonly my $BSC_FIRST => $BSC_OK;
Readonly my $BSC_LAST  => $BSC_UNKNOWN;

Readonly my @errmsg => (
    "Success",                        # _OK
    "Server connection error",        # _CONN_ERROR
    "Requested data not found",       # _DATA_NOT_FOUND
    "Bad or invalid data in request", # _BAD_REQUEST
    "Server unauthorized access",     # _UNAUTHORIZED_ACCESS
    "Internal server error",          # _INTERNAL_ERROR
    "Node is connected",              # _NODE_CONNECTED
    "Node is disconnected",           # _NODE_DISCONNECTED
    "Node not found",                 # _NODE_NOT_FOUND
    "Node is configured",             # _NODE_CONFIGURED
    "HTTP error",                     # _HTTP_ERROR
    "Malformed data",                 # _MALFORMED_DATA
    "Unknown error"                   # _UNKNOWN (default)
);

=head1 METHODS

=cut

# Constructor ==========================================================
#
=over 4

=item B<new>

Creates a new I<Brocade::BSC::Status> object.

=cut
#
# Parameters: may be called with $BSC_XXX constant to initialize code
#
sub new {
    my $class = shift;
    my $self = {
        code      => $BSC_UNKNOWN,
        http_code => 0,
        http_msg  => undef
    };
    @_ and $self->{code} = $_[0];
    bless ($self, $class);
}

# Method ===============================================================
#             status accessors
# Parameters: none
# Returns   : boolean: is the current status OK (configured, connected)?
#
=item B<ok>

  # Returns   : true iff the current status is OK.

=cut
sub ok {
    my $self = shift;
    return ($BSC_OK == $self->{code});
}
=item B<no_data>

  # Returns   : true if requested data was not found.

=cut
sub no_data {
    my $self = shift;
    return ($BSC_DATA_NOT_FOUND == $self->{code});
}
=item B<connected>

  # Returns   : true if last API call indicates node connected to controller.

=cut
sub connected {
    my $self = shift;
    return ($BSC_NODE_CONNECTED == $self->{code});
}
=item B<disconnected>

  # Returns   : true if last API call indicates node is not connected.

=cut
sub disconnected {
    my $self = shift;
    return ($BSC_NODE_DISCONNECTED == $self->{code});
}
=item B<not_found>

  # Returns   : true if last API call indicates node is unknown to controller.

=cut
sub not_found {
    my $self = shift;
    return ($BSC_NODE_NOT_FOUND == $self->{code});
}
=item B<configured>

  # Returns   : true if last API call indicates node is configured.

=cut
sub configured {
    my $self = shift;
    return ($BSC_NODE_CONFIGURED == $self->{code});
}

# Method ===============================================================
#             code
# Parameters: integer code for set
#             none for get
# Returns   : status code
#
sub code {
    my ($self, $code) = @_;
    $self->{code} = (2 == @_) ? $code : $self->{code};
}

# Method ===============================================================
#             http_err
# Parameters: HTTP::Response object
# Returns   : ignore; updates BVCStatus object with values from http response
#
sub http_err {
    my ($self, $http_resp) = @_;
    (2 == @_) or die "missing required argument \$http_resp\n";
    $self->{code}      = $BSC_HTTP_ERROR;
    $self->{http_code} = $http_resp->code;
    $self->{http_msg}  = $http_resp->message;
}

# Method ===============================================================
#
=item B<msg>

  # Returns   : status string for current status

=cut
sub msg {
    my $self = shift;
    my $http_err = "";

    if ($self->{http_code} and defined $self->{http_msg}) {
        $http_err = " $self->{http_code} - '$self->{http_msg}'";
    }
    ($self->{code} >= $BSC_FIRST and $self->{code} <= $BSC_LAST)
        and return $errmsg[$self->{code}] . $http_err
        or  return "Undefined status code $self->{code}";
}


# Module ===============================================================
1;

=back

=head1 COPYRIGHT

Copyright (c) 2015,  BROCADE COMMUNICATIONS SYSTEMS, INC

All rights reserved.
