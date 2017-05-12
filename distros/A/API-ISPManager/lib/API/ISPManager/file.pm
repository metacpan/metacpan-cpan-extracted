package API::ISPManager::file;

use strict;
use warnings;

use API::ISPManager;
use WWW::Mechanize;
use HTTP::Cookies;
use Data::Dumper;

# NB! plid везде без лидирующего /, т.е. www/..., а не /www/...

# List of files and directories
# IN: plid - parent directory (optional, equal to docroot when empty)
# IN: elid - directory for listing
sub list {
    my $params = shift;

    return API::ISPManager::query_abstract(
        params => $params,
        func   => 'file',
        allowed_fields => [  qw( host path allow_http elid plid ) ],
    );
}

# Create file or directory
# IN: filetype (0 - file, 1 - directory, zip ......)
# IN: plid - parent directory (optional, equal to docroot when empty)
# IN: name - parent directory for created file
sub create {
    my $params = shift;

    my $result = API::ISPManager::query_abstract(
        params => { %$params, sok => 'yes' },
        func   => 'file.new',
        elid   => '',
        allowed_fields => [  qw( host path allow_http sok filetype name elid plid ) ],
    );

    $API::ISPManager::last_answer = $result;

    if ($result && $result->{ok}) {
        return 1;
    } else {
        return '';
    }
}

# Delete file or directory
# IN: plid - parent directory (optional, equal to docroot when empty)
# IN: elid - parent directory for created file
sub delete {
    my $params = shift;

    my $result = API::ISPManager::query_abstract(
        params => $params,
        func   => 'file.delete', 
        allowed_fields => [  qw( host path allow_http elid plid ) ],
    );

    $API::ISPManager::last_answer = $result;

    if ($result && $result->{ok}) {
        return 1;
    } else {
        return '';
    }
}

# Copy file or directory
# IN: plid - destination
# IN: elid - file/direcory to be copied
sub copy {
    my $params = shift;
    $params->{elid} = '//c/' . $params->{elid};
    my $result = API::ISPManager::query_abstract(
        params => $params,
        func   => 'file.paste', 
        allowed_fields => [  qw( host path allow_http elid plid ) ],
    );

    $API::ISPManager::last_answer = $result;

    if ($result && $result->{ok}) {
        return 1;
    } else {
        return '';
    }
}

# Move file or directory
# IN: plid - destination
# IN: elid - file/direcory to be moved
sub move {
    my $params = shift;
    $params->{elid} = '//x/' . $params->{elid};
    my $result = API::ISPManager::query_abstract(
        params => $params,
        func   => 'file.paste', 
        allowed_fields => [  qw( host path allow_http elid plid ) ],
    );

    $API::ISPManager::last_answer = $result;

    if ($result && $result->{ok}) {
        return 1;
    } else {
        return '';
    }
}

# Move file or directory
# IN: plid - parent directory
# IN: elid - archive to be extracted
sub extract {
    my $params = shift;

    my $result = API::ISPManager::query_abstract(
        params => $params,
        func   => 'file.extract', 
        allowed_fields => [  qw( host path allow_http elid plid ) ],
    );

    $API::ISPManager::last_answer = $result;

    if ($result && $result->{ok}) {
        return 1;
    } else {
        return '';
    }
}

# Edit file or directory
sub edit {
    my $params = shift;

    my $result = API::ISPManager::query_abstract(
        params => { %$params, sok => 'yes' },
        func   => 'file.attr', 
        allowed_fields => [  qw( host path allow_http elid plid sok name uid gid recursive mode pur puw pux pgr pgx por pox) ],
    );

    $API::ISPManager::last_answer = $result;

    if ($result && $result->{ok}) {
        return 1;
    } else {
        return '';
    }
}

# Upload file
sub upload {
    my $params = shift;
    
    my $allowed_fields = [  qw( host path allow_http plid ) ];
    my $func_name = 'file.upload';
    
    my $auth_id = API::ISPManager::get_auth_id( %$params );
    if ($auth_id) {
        
        my $params_raw = API::ISPManager::filter_hash( $params, $allowed_fields );       
        
        my $ua = LWP::UserAgent->new;
        $ua->agent("Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)");
        my $url = 'https://server8.hosting.reg.ru/mancgi/upload';

        my $query_string = API::ISPManager::mk_full_query_string( {
            ( auth => $auth_id ), 
            func => $func_name,
            %$params_raw,
        } );  
               
        my $response = $ua->post(
            'https://' . $params->{host} . '/mancgi/upload',
			Content_Type => 'form-data',
			Content => [                
                filename => [$params->{file}],
                sok => 'ok',
                auth => $auth_id,    
                plid => $params->{plid},                               
            ]
        );

        
        if ($response->is_success) {
            return 1;
        }
        else {
            return '';
        }
    }
    else {
        return '';
    }
}

1;
