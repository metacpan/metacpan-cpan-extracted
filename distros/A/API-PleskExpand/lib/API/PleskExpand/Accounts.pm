#
# DESCRIPTION:
#   Plesk Expand communicate interface. Static methods for managing Plesk user accounts from Plesk Expand.
# AUTHORS:
#   Pavel Odintsov (nrg) <pavel.odintsov@gmail.com>
#
#========================================================================

package API::PleskExpand::Accounts;

use strict;
use warnings;

use API::Plesk::Methods;
use Data::Dumper;

our $VERSION = '1.04';

=head1 NAME

API::PleskExpand::Accounts - extension module for the management Plesk user accounts from Plesk Expand.

=head1 SYNOPSIS

Directly not used, calls via API::PleskExpand.

 use API::PleskExpand;

 some code

=head1 DESCRIPTION

The module provides full support operations with Plesk accounts from Plesk Expand.

=head1 EXPORT

None by default.

=cut

=head1 METHODS

=over 3

=item create()

Params:

  'select'             => 'optimal',
  'template-id'        =>  1,
  'attach_to_template' => 1, # attach account to a certain template
  'general_info'  => {
    login   => 'plesk_login',
    pname   => 'perldonal name',
    passwd  => 'userpasswd',
    status  => 0,                   # active
    cname   => '',                  # company name
    phone   => '',
    fax     => '',
    email   => '',
    address => '',
    city    => '',
    state   => '',                  # state, for USA only
    pcode   => '',
    country => 'RU',
  }

You can let Plesk Expand automatically select a Plesk server based on certain filtering parameters (params for 'select' field):

    'optimal' -- Least Integral Estimate (% used) selects the least loaded server (integrally estimated).
    'min_domains' -- Least Domains (% used) registers a client on the server with the minimum number of domains.
    'max_diskspace' -- Least Disk Space (% used) registers a client on the server with the minimum disk space used.
    '' -- Select manually, Specify the target Plesk server by selecting its name from the list.
 	
When choosing a 'manual' (select => '') option you should set server_id!
For 'optimal', 'min_domains', 'max_diskspace' you can ask additional server group id ('group_id' params) or server keyword ('server_keyword' param);


Return (Data::Dumper output):

  VAR1 = bless( {
    'answer_data'   => [ {
      'server_id'   => '1',
      'status'      => 'ok',
      'expiration'  => '-1',
      'tmpl_id'     => '1',
      'id'          => '15'
    } ], 
    'error_codes' => ''
  }, 'API::Plesk::Response' );

=cut

# Create element
# STATIC
sub create {

    my %params = @_;

    if (ref $params{'general_info'} eq 'HASH') {
        my $template = '';
        
        if ($params{'template-id'}) {
            $template = create_node('tmpl_id', $params{'template-id'}) . 
                ( $params{'attach_to_template'} ? create_node('attach_to_template', '') : '' );
        } else {
            return ''; # template required
        }

        my $select = '';

        if ($params{'select'}) {

            if ( $params{'group_id'} ) {
                $select = create_node( 'server_auto', create_node( $params{'select'}, '') . 
                    create_node( 'group_id', $params{'group_id'} )  
                );
            } elsif ( $params{'server_keyword'} ) {
                $select = create_node( 'server_auto', create_node( $params{'select'}, '')  ). 
                    create_node( 'server_keyword', $params{'server_keyword'} );
            } else {
                 $select = create_node( 'server_auto', create_node( $params{'select'}, '') );
            }
        } else {

            if ( $params{'server_id'} ) {
                $select = create_node( 'server_id', $params{'server_id'} );
            } else {
                return ''; # server_id required!
            }
        }
        
        return create_node( 'add_use_template',
            generate_info_block('gen_info', %{ $params{'general_info'} } ) . '<!-- create_client -->' . $template . $select);

    } else {
        return '';  # not enought data
    }
}


# Parse XML response
# STATIC
sub create_response_parse {
    return abstract_parser('add_use_template', +shift, [ ]);
}


=item modify(%params)

Changes the account params.

Params:
  general_info -- hashref`s with new user details
  id           -- client id 


Return:

  $VAR1 = bless( {
    'answer_data' => [ {
        'server_id'       => '1',
        'status'          => 'ok',
        'tmpl_id'         => '1',
        'id'              => '15',
        'plesk_client_id' => '384',
        'login'           => 'suxdffffxx'
    } ],
        'error_codes' => ''
  }, 'API::Plesk::Response' );


Example (client deactivation):

  print Dumper $client->Accounts->modify(
    id => 10, 
    general_info => { status => 16 }
  );

=cut

# Modify element
# STATIC
sub modify {
    my %params = @_;
    
    if (ref $params{'general_info'} eq 'HASH') {

        my $filter = '';

        if ($params{'id'}) {
            $filter = create_filter(login_field_name => 'id', id => $params{'id'});
        } else {
            return ''; # filter required!
        }
    

        return create_node('set', $filter . '<!-- modify_client -->' . create_node('values',
            generate_info_block('gen_info', %{ $params{'general_info'} } ) ) );

    } else {
        return ''; # general_info field required !
    }

    # выключение клиента
    my $data=<<DOC;
<?xml version="1.0"?>
<packet version="0.0.0.110">
    <set>
        <filter>
            <id>1</id>
        </filter>
        <values>
            <gen_info>
                <status>16</status>
            </gen_info>
        </values>
    </set>
</packet
DOC
    # включаем клиента
    my $data1 = <<DOC;
<?xml version="1.0"?>
<packet version="0.0.0.110">
    <set>
       <filter>
            <id>1</id>
        </filter>
        <values>
            <gen_info>
                <status>0</status>
            </gen_info>
        </values>
    </set>
</packet>
DOC
}


# SET response handler
# STATIC
sub modify_response_parse {
    return abstract_parser('set', +shift, []);
}


=item delete(%params)

Delete accounts.

Params:
  id -- client id in Plesk

Return:

    $VAR1 = bless( {
        'answer_data' => [ {
            'server_id' => '1',
            'status' => 'ok',
            'id' => '15'
        } ],
        'error_codes' => ''
    }, 'API::Plesk::Response' );


Example:
  print Dumper $client->Accounts->delete( id => 11 );

=back

=cut


# Delete element
# STATIC( %args )
sub delete {
    my %params = @_;

    my $filter = '';

    if ($params{'id'}) {
        $filter = create_filter( id => $params{'id'});
    } else {
        return '';  # id required!
    }
    

    return create_node('del', '<!-- del_client -->' . $filter);
}


# DEL response handler
# STATIC
sub delete_response_parse {
    return abstract_parser('del', +shift, [ ]);
}


# Get all element data
# STATIC
sub get {
    my %params = @_;

    unless ($params{all}) {
        return '';
    }

    return create_node( 'get',
        create_node('filter', '') . create_node( 'dataset', create_node('gen_info') )
    ) . '<!-- get_client -->';
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
