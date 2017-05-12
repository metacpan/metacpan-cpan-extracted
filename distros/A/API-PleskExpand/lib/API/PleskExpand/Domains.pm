#
# DESCRIPTION:
#   Plesk Expand communicate interface. Static methods for managing domain accounts.
# AUTHORS:
#   Pavel Odintsov (nrg) <pavel.odintsov@gmail.com>
#
#========================================================================

package API::PleskExpand::Domains;

use strict;
use warnings;

use API::Plesk::Methods;
use Data::Dumper;

our $VERSION = '1.04';

=head1 NAME

API::PleskExpand::Domains - extension module to support operations with Plesk domains (only create) from Plesk Expand.

=head1 SYNOPSIS

 Directly not used, calls via API::Plesk.

 use API::PleskExpand;
 use API::Plesk::Response;

 Some code

=head1 DESCRIPTION

The method used to add domain hosting account to a certain Plesk account from Plesk Expand.

=head1 METHODS

=over 3

=item create()

Params:

  dname              => 'yandex.ru',   # domain name
  client_id          => 9,             # add domain to client with certain id
  'template-id'      => 1,             # domain template id
  ftp_login          => 'nrgsdasd',    # username for ftp 
  ftp_password       => 'dasdasd',     # password for ftp account
  attach_to_template => 1,             # attach domain to template ? 1 -- yes, 0 -- no

Return:

  $VAR1 = bless( {
    'answer_data' => [ {
        'server_id'     => '1',
        'status'        => 'ok',
        'expiration'    => '-1',
        'tmpl_id'       => '1',
        'client_id'     => '16',
        'id' => '15'
    } ],
        'error_codes' => ''
  }, 'API::Plesk::Response' );


=back

=head1 EXPORT

None.

=cut

# Create element
# STATIC
sub create {

   my %params = @_;

    return '' unless $params{'dname'}        &&
                     #$params{'ip'}           &&
                     $params{'client_id'}    &&
                     $params{'ftp_login'}    &&
                     $params{'ftp_password'} &&
                     $params{'template-id'};

    $params{'attach_to_template'} ||= '';

    my $hosting_block = create_node('hosting',
        generate_info_block(
            'vrt_hst',
            'ftp_login'    => $params{'ftp_login'},
            'ftp_password' => $params{'ftp_password'},
        )
    );
    my $template_block =  create_node('tmpl_id', $params{'template-id'}) .
        ( $params{'attach_to_template'} ? create_node('attach_to_template', '') : '' );

    return create_node( 'add_use_template',
        create_node( 
            'gen_setup',
            create_node( 'name', $params{dname} ) .
            create_node( 'client_id', $params{client_id} ) .
            create_node( 'status', 0)
        ) . $hosting_block . '<!-- create_domain -->' . $template_block        
    );
}


# Parse XML response
# STATIC
sub create_response_parse {
    return abstract_parser('add_use_template', +shift, [ ], 'system_error' );
}


# Modify element
# STATIC
sub modify {
    # stub
}


# SET response handler
# STATIC
sub modify_response_parse {
    # stub
}


# Delete element
# STATIC( %args )
sub delete {
    # stub
}


# DEL response handler
# STATIC
sub delete_response_parse {
    # stub
}


# Get all element data
# STATIC
sub get {
    my %params = @_;

    unless ($params{all}) {
        return '';
    }

    #return '<get><filter></filter><dataset><gen_info/></dataset></get><!-- create_domain -->';

    return create_node( 'get',
        create_node('filter', '') . create_node( 'dataset', create_node('gen_info') )
    ) . '<!-- create_domain -->';
}


# GET response handler 
# STATIC
sub get_response_parse {
    my $answer = abstract_parser('get', +shift, [ ], 'system_error' );

    if (ref $answer eq 'ARRAY') {
        for my $domain (@$answer) {
            $domain->{data} = xml_extract_values($domain->{data} =~ m#<gen_info>(.*?)</gen_info>#);
        }
    } elsif ($answer) {
        $answer->{data} = xml_extract_values($answer->{data} =~ m#<gen_info>(.*?)</gen_info>#);
    }

    return $answer;
}


1;
__END__
=head1 SEE ALSO

Blank.

=head1 AUTHOR

Odintsov Pavel E<lt>nrg[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by NRG

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
