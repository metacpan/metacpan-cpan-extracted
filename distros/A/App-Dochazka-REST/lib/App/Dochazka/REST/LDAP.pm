# *************************************************************************
# Copyright (c) 2014-2017, SUSE LLC
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
# LDAP module
#

package App::Dochazka::REST::LDAP;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log $site );
use Params::Validate qw( :all );



=head1 NAME

App::Dochazka::REST::LDAP - LDAP module (for authentication)



=head1 DESCRIPTION

Container for LDAP-related stuff.

=cut



=head1 EXPORTS

=cut

use Exporter qw( import );
our @EXPORT_OK = qw(
    autocreate_employee
    ldap_exists
    ldap_auth
    ldap_search
);



=head1 METHODS


=head2 ldap_exists

Takes a nick. Returns true or false. Determines if the nick exists in the LDAP database.
Any errors in communication with the LDAP server are written to the log.

=cut

# $ldap and $dn are used by both 'ldap_exists' and 'ldap_search'
my ( $ldap, $dn );

sub ldap_exists {
    my ( $nick ) = validate_pos( @_, { type => SCALAR } );

    return 0 unless $site->DOCHAZKA_LDAP;

    require Net::LDAP; 

    my $server = $site->DOCHAZKA_LDAP_SERVER;
    $ldap = Net::LDAP->new( $server );
    $log->error("$@") unless $ldap;
    return 0 unless $ldap;

    $log->info( "Connected to LDAP server $server to look up $nick" );
    
    if ( ldap_search( $ldap, $nick, 'uid' ) ) {
        $log->info( "Found employee $nick in LDAP (DN $dn)" );
        return 1;
    }
    return 0;
}


=head2 ldap_search

Given Net::LDAP handle, LDAP field, and nick, search for the nick in
the given field (e.g. 'uid', 'cn' etc.). Returns value of LDAP property
specified in $prop.

=cut

sub ldap_search {
    my ( $ldap, $nick, $prop ) = @_;
    $nick = $nick || '';
    my $base = $site->DOCHAZKA_LDAP_BASE || '';
    my $field = $site->DOCHAZKA_LDAP_MAPPING->{nick} || '';
    my $filter = $site->DOCHAZKA_LDAP_FILTER || '';
    my $prop_value;

    require Net::LDAP::Filter;

    $filter = Net::LDAP::Filter->new( "(&" .
                                           $filter .
                                           "($field=$nick)" .
                                           ")"
                                    );

    my ($mesg, $entry, $count);

    $log->info( "Running LDAP search with filter " . $filter->as_string );

    $mesg = $ldap->search(
                           base => "$base",
                           scope => "sub",
                           filter => $filter
                         );

    # code == 0 is success, code >= 1 is failure
    die $mesg->error unless $mesg->code == 0;

    $count = 0;
    for $entry ($mesg->entries) {
        $count += 1;
        if ($count == 1) {
            $dn = $entry->dn();
            $prop_value = $entry->get_value( $prop );
            last;
        }
    }
    return $prop_value if $count > 0;
    return;
}


=head2 ldap_auth

Takes a nick and a password. Returns true or false. Determines if the password matches
the one stored in the LDAP database.

=cut

sub ldap_auth {
    no strict 'subs';
    my ( $nick, $password ) = @_;
    return 0 unless $nick;
    $password = $password || '';

    return 0 unless $site->DOCHAZKA_LDAP;

    require Net::LDAP;
    require Net::LDAP::Filter;

    my $mesg = $ldap->bind( "$dn",
                           password => "$password",
                       );
    if ( $mesg->code == 0 ) {
        $ldap->unbind;
        $log->info("Access granted to $nick");
        return 1;
    }
    $log->info("Access denied to $nick because LDAP server returned code " . $mesg->code);
    return 0;
}

1;
