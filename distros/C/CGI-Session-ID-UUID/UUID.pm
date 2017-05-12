##
##  CGI::Session::ID::UUID -- UUID based CGI Session Identifiers
##  Copyright (c) 2005 Ralf S. Engelschall <rse@engelschall.com>
##
##  This program is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
##  General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program; if not, write to the Free Software
##  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
##  USA, or contact Ralf S. Engelschall <rse@engelschall.com>.
##
##  UUID.pm: Module Implementation
##

package CGI::Session::ID::UUID;

require 5.006;
use strict;

our $VERSION = '0.02';

#   determine available UUID generator
our $generator;
foreach my $module (qw(OSSP::uuid Data::UUID APR::UUID DCE::UUID UUID)) {
    { no strict; no warnings; local $SIG{__DIE__} = 'IGNORE'; 
      eval "use $module"; }
    if (not $@) {
        $generator = $module;
        last;
    }
}
if (not defined($generator)) {
    die "no UUID generator available " .
        "(requires OSSP::uuid, Data::UUID, APR::UUID, DCE::UUID or UUID)";
}

#   the id generation method
sub generate_id {
    my ($self) = @_;

    my $id;
    if ($generator eq 'OSSP::uuid') {
        #   self-contained OSSP::uuid
        #   (preference; ultra portable; accurate implementation)
        my $uuid = new OSSP::uuid();
        $uuid->make("v1");
        $id = $uuid->export("str");
        undef $uuid;
    }
    elsif ($generator eq 'Data::UUID') {
        #   self-contained Data::UUID
        #   (alternative; less portable; acceptable implementation)
        my $uuid = new Data::UUID();
        $id = $uuid->create_str();
        undef $uuid;
    }
    elsif ($generator eq 'APR::UUID') {
        #   Apache/mod_perl based APR::UUID
        #   (alternative; less portable; acceptable implementation)
        my $uuid = new APR::UUID();
        $id = $uuid->format();
        undef $uuid;
    }
    elsif ($generator eq 'DCE::UUID') {
        #   Solaris/DCE based DCE::UUID
        #   (alternative; not portable; unknown implementation)
        my $uuid = uuid_create();
        $id = "$uuid";
        undef $uuid;
    }
    elsif ($generator eq 'UUID') {
        #   Linux/e2fsprogs based UUID
        #   (alternative; less portable; acceptable implementation)
        my $uuid; UUID::generate($uuid);
        UUID::unparse($uuid, $id);
        undef $uuid;
    }

    return $id;
}

1;

=pod

=head1 NAME

CGI::Session::ID::UUID - UUID based CGI Session Identifiers

=head1 SYNOPSIS

 use CGI::Session;

 $session = new CGI::Session("...;id:UUID", ...);

=head1 DESCRIPTION

CGI::Session::ID::UUID is a CGI::Session driver to generate identifiers
based on DCE 1.1 and ISO/IEC 11578:1996 compliant Universally Unique
Identifiers (UUID). This module requires a reasonable UUID generator.
For this it either requires the preferred OSSP::uuid module or
alternatively the Data::UUID, APR::UUID, DCE::UUID or UUID modules to be
installed.

=head1 AUTHOR

Ralf S. Engelschall <rse@engelschall.com>

=head1 SEE ALSO

L<CGI::Session|CGI::Session>

L<OSSP::uuid|OSSP::uuid> L<http://www.ossp.org/pkg/lib/uuid/> 

L<Data::UUID|Data::UUID> L<http://www.cpan.org/modules/by-module/Data/>

L<APR::UUID|APR::UUID> L<http://www.cpan.org/modules/by-module/Apache/>

L<DCE::UUID|DCE::UUID> L<http://www.cpan.org/modules/by-module/DCE/>

L<UUID|UUID> L<http://www.cpan.org/modules/by-module/UUID/>

=cut

