#
# DESCRIPTION:
#   Plesk Expand communicate interface. Main class.
# AUTHORS:
#   Pavel Odintsov (nrg) <pavel.odintsov@gmail.com>
#
#========================================================================
package API::PleskExpand;

use strict;
use warnings;
use lib qw(../..);

use API::Plesk;
use base 'API::Plesk';

use Data::Dumper;
use Carp;

our $VERSION = '1.07';

=head1 NAME

API::PleskExpand - OOP interface to the Plesk Expand XML API (http://www.parallels.com/en/products/plesk/expand/).

=head1 SYNOPSIS

    use API::PleskExpand;
    use API::Plesk::Response;

    my $expand_client = API::PleskExpand->new(%params);
    my $res = $expand_client->Func_Module->operation_type(%params);

    if ($res->is_success) {
        $res->get_data; # return arr ref of answer blocks
    }

=head1 DESCRIPTION

At present the module provides interaction with Plesk Expand 2.2.4 (API 2.2.4.1). Complete support of operations with Accounts, partial support of work with domains. Support of addition of domains to user Accounts.

API::PleskExpand module gives the convenient interface for addition of new functions. Extensions represent modules in a folder Plesk with definitions of demanded functions. Each demanded operation is described by two functions: op and op_response_parse. The first sub generates XML query to Plesk, the second is responsible for parse XML answer and its representation in Perl Native Structures. As a template for a writing of own expansions is better to use API/PleskExpand/Accounts.pm. In module API::Plesk::Methods we can find service functions for a writing our extensions.

For example, here the set of subs in the Accounts module is those.

  create  / create_response_parse
  modify  / modify_response_parse
  delete  / delete_response_parse
  get     / get_response_parse

=head1 EXPORT

Nothing.

=head1 METHODS

=over 3

=item new(%params)

Create new class instance.

Required params:
  api_version -- default: 2.2.4.1
  username -- Expand user name (root as default).
  password -- Expand password.
  url -- full url to Expand XML RPC gate (https://ip.ad.dr.ess::8442/webgate.php').

=cut



sub new {
    (undef) = shift @_;
    my $self = __PACKAGE__->SUPER::new(@_);
    $self->{package_name} = __PACKAGE__;

    unless ($self->{api_version}) {
        $self->{api_version} = '2.2.4.1';
    }

    return $self;
}


=item AUTOLOADed methods

All other methods are loaded by Autoload from corresponding modules. 
Execute some operations (see API::PleskExpand::* modules documentation).

Example:

  my $res = $expand_client->Func_Module->operation_type(%params); 
  # Func_Module -- module in API/PleskExpand folder
  # operation_type -- sub which defined in Func_Module.
  # params hash used as @_ for operation_type sub.

=back

=cut



# OVERRIDE, INSTANCE(xml_request)
sub _execute_query {
    my ($self, $xml_request) = @_;

    # packet version override for 
    my $packet_version =  $self->{'api_version'};

    return unless $xml_request;
    my $xml_packet_struct = <<"    DOC";
<?xml version="1.0" encoding="UTF-8"?>
<packet version="$packet_version"> 
    $xml_request
</packet>
    DOC

    my $operator = '';
    
    if ($xml_request =~ m/create_client/is or
        $xml_request =~ m/del_client/is    or
        $xml_request =~ m/modify_client/is or 
        $xml_request =~ m/get_client/is
    ) {
        $operator = 'exp_plesk_client';
    } elsif ($xml_request =~ m/create_domain/is) {
        $operator = 'exp_plesk_domain';
    }

    my $headers = {
        ':HTTP_AUTH_LOGIN'  => $self->{'username'},
        ':HTTP_AUTH_PASSWD' => $self->{'password'},
        ':HTTP_AUTH_OP'     => $operator
    };

    return $headers if $self->{'dump_headers'};

    return API::Plesk::xml_http_req(
        $self->{'url'},
        $xml_packet_struct,
        headers => $headers 
    );
}

1;
__END__
=head1 SEE ALSO
 
Plesk Expand XML RPC API  http://www.parallels.com/en/products/plesk/expand/

=head1 AUTHOR

Odintsov Pavel E<lt>nrg[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by NRG

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
