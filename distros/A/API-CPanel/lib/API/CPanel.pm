package API::CPanel;

use strict;
use warnings;
use lib qw(../..);

use Exporter::Lite;
use LWP::UserAgent;
#use XML::LibXML;
use XML::Simple;
use Data::Dumper;
use MIME::Base64;
# Main packages
use API::CPanel::Ip;
use API::CPanel::User;
use API::CPanel::Misc;
use API::CPanel::Package;
use API::CPanel::Domain;
use API::CPanel::Mysql;


our @EXPORT      = qw/get_auth_hash refs is_success query_abstract is_ok get_error/;
our @EXPORT_OK   = qw//;
our $VERSION     = 0.09;
our $DEBUG       = '';
our $FAKE_ANSWER = '';

=head1 NAME

API::CPanel - interface to the CPanel Hosting Panel API ( http://cpanel.net )

=head1 SYNOPSIS

 use API::CPanel;
 
 my $connection_params = {
    auth_user   => 'username',
    auth_passwd => 'qwerty',
    host        => '11.22.33.44',
 };

 ### Get all panel IP
 my $ip_list = API::CPanel::ip::list( $connection_params );

 unless ($ip_list && ref $ip_list eq 'ARRAY' && scalar @$ip_list) {
    die 'Cannot get ip list from CPanel';
 }

 my $ip  = $ip_list->[0];
 my $dname  = 'perlaround.ru';
 my $user_name = 'user1';

 my $client_creation_result = API::CPanel::user::create( {
    %{ $connection_params },
    username  => $user_name,
    password  => 'user_password',
    domain    => $dname,
 });

 # Switch off account:
 my $suspend_result = API::CPanel::user::disable( {
    %{ $connection_params },
    user => $user_name,
 } );

 unless ( $suspend_result ) {
    die "Cannot  suspend account";
 }



 # Switch on account
 my $resume_result = API::CPanel::user::enable( {
    %{ $connection_params },
    user => $user_name,
 } );

 unless ( $resume_result ) {
    die "Cannot resumeaccount";
 }



 # Delete account
 my $delete_result = API::CPanel::user::delete( {
    %{ $connection_params },
    user => $user_name,
 } );

 unless ( $delete_result ) {
    die "Cannot delete account";
 }


=cut

# Last raw answer from server
our $last_answer = '';

# Public!
sub is_ok {
    my $answer = shift;

    return 1 if $answer && ( ref $answer eq 'HASH' || ref $answer eq 'ARRAY' );
}


sub get_error {
    my $answer = shift;

    return '' if is_success( $answer ); # ok == no error

    return Dumper( $answer->{statusmsg } );
}

# Get data from @_
sub get_params {
    my @params = @_;

    if (scalar @params == 1 && ref $params[0] eq 'HASH' ) {
        return { %{ $params[0] } };
    } else {
        return { @params };
    }
}

# Make query string
# STATIC(HASHREF: params)
sub mk_query_string {
    my $params = shift;

    return '' unless $params &&
        ref $params eq 'HASH' && %$params ;

    my $result = join '&', map { "$_=$params->{$_}" } sort keys %$params;
    warn $result if $DEBUG;

    return $result;
}

# Kill slashes at start / end string
# STATIC(STRING:input_string)
sub kill_start_end_slashes {
    my $str = shift;

    for ($str) {
        s/^\/+//sgi;
        s/\/+$//sgi;
    }
    
    return $str;
}

# Make full query string (with host, path and protocol)
# STATIC(HASHREF: params)
# params:
# host*
# path
# allow_http
# param1
# param2
# ...
sub mk_full_query_string {
    my $params = shift;

    return '' unless
        $params               &&
        ref $params eq 'HASH' &&
        %$params              &&
        $params->{host}       &&
        $params->{func};

    my $host       = delete $params->{host};
    my $path       = delete $params->{path}        || '';
    my $allow_http = delete $params->{allow_http}  || '';
    my $func       = delete $params->{func};

    unless ($path) {
        $path = 'xml-api';
    }

    $path = kill_start_end_slashes( $path );
    $host = kill_start_end_slashes( $host );
    $func = kill_start_end_slashes( $func );

    my $query_path = ( $allow_http ? 'http' : 'https' ) . "://$host:2087/$path/$func";

    return %$params ? $query_path . '?' . mk_query_string( $params ) : $query_path;
}


# Make request to server and get answer
# STATIC (STRING: query_string)
sub mk_query_to_server {
    my $auth_hash    = shift;
    my $query_string = shift;

    return '' unless ( $query_string && $auth_hash );
    warn "Auth hash: $auth_hash\nQuery string: $query_string\n" if $DEBUG;

    my $ua = LWP::UserAgent->new;
    my $request = HTTP::Request->new( GET => $query_string );
    $request->header( Authorization => $auth_hash );
    my $response = $ua->request( $request );

    my $content = $response->content;
    if ($response->header('content-type') eq 'text/xml') {
        warn $content if $DEBUG;
        return $content;
    } else {
        return '';
    }
}

# Parse answer
# STATIC(HASHREF: params)
# params:
#  STRING: answer
#  HASHREF: xml_parser_params)
sub parse_answer {
    my %params = @_;

    my $answer_string =
        $params{answer};
    my $parser_params =
        $params{parser_params} || { };

    return '' unless $answer_string;

    my $deparsed = XMLin( $answer_string, %$parser_params );
    warn Dumper $deparsed if $DEBUG;
    
    return $deparsed ? $deparsed : '';
}

# Get + deparse
# STATIC(STRING: query_string)
sub process_query {
    my %params = @_;

    my $auth_hash         = $params{auth_hash};
    my $query_string      = $params{query_string};
    my $xml_parser_params = $params{parser_params} || '';
    my $fake_answer       = $API::CPanel::FAKE_ANSWER || '';

    return '' unless $query_string;

    my $answer = $fake_answer ? $fake_answer : mk_query_to_server( $auth_hash, $query_string );
    warn $answer if $answer && $DEBUG;

    return $answer ?
        parse_answer(
            answer        => $answer,
            parser_params => $xml_parser_params
        ) : '';
}

# Filter hash
# STATIC(HASHREF: hash, ARRREF: allowed_keys)
# RETURN: hashref only with allowed keys
sub filter_hash {
    my ($hash, $allowed_keys) = @_;

    return unless ref $hash eq 'HASH' &&
        ref $allowed_keys eq 'ARRAY';
    
    my $new_hash = { };

    foreach my $allowed_key (@$allowed_keys) {
        if (exists $hash->{$allowed_key}) {
            $new_hash->{$allowed_key} = $hash->{$allowed_key};
        }
        elsif (exists $hash->{lc $allowed_key}) {
            $new_hash->{$allowed_key} = $hash->{lc $allowed_key};
        };
    }

    return $new_hash;
}

# Get access key, time to live -- 30 minutes
# STATIC(HASHREF: params_hash)
# params_hash:
# - all elements from mk_full_query_string +
# - auth_user*
# - auth_passwd*
sub get_auth_hash {
    my %params_raw = @_;

    warn 'get_auth_hash params: ' . Dumper(\%params_raw)  if $DEBUG;

    my $params = filter_hash(
        \%params_raw,
        [ 'auth_user', 'auth_passwd' ]
    );

    # Check this sub params
    unless ($params->{auth_user} && $params->{auth_passwd}) {
        return '';
    }

    return "Basic " . MIME::Base64::encode( $params->{auth_user} . ":" . $params->{auth_passwd} );
}

# Wrapper for "ref" on undef value, without warnings :)
# Possible very stupid sub :)
# STATIC(REF: our_ref)
sub refs {
    my $ref = shift;

    return '' unless $ref;

    return ref $ref;
}

# INTERNAL!!! Check server answer result
# STATIC(data_block)
sub is_success {
    my $data_block = shift;
    my $want_hash  = shift;

    if ( $data_block &&
         ref $data_block eq 'HASH' &&
         (( $data_block->{status} &&
           $data_block->{status} eq '1' ) ||
         ( $data_block->{result} &&
           $data_block->{result} eq '1' ))
       ) {
        return 1;
    } else {
        return $want_hash ? {} : '';
    }
}

# all params derived from get_auth_hash
sub query_abstract {
    my %params = @_;

    my $params_raw  = $params{params};
    my $func_name   = $params{func};
    my $container   = $params{container};

    my $fields      = $params{allowed_fields} || '';

    my $allowed_fields;
    warn 'query_abstract ' . Dumper( \%params ) if $DEBUG;

    return '' unless $params_raw && $func_name;

    $fields = "host path allow_http auth_user auth_passwd container $fields";
    @$allowed_fields = split(' ', $fields);

    my $xml_parser_params = $params{parser_params};

    my $auth_hash = get_auth_hash( %$params_raw );
    warn "Auth_hash: $auth_hash\n" if $DEBUG;

    if ( $auth_hash ) {
        my $params = filter_hash( $params_raw, $allowed_fields );

        my $query_string = mk_full_query_string( {
            func => $func_name,
            %$params,
        } );

        warn Dumper $query_string if $DEBUG;

        my $server_answer =  process_query(
            auth_hash     => $auth_hash,
            query_string  => $query_string,
            parser_params => $xml_parser_params,
        );
        warn Dumper $server_answer if $DEBUG;

	if ( $server_answer &&
	     $container &&
	     is_ok( $server_answer->{$container} )
	     ) {
	    $API::CPanel::last_answer = $server_answer->{$container};
	    return $server_answer->{$container};
	}
	elsif ( $server_answer &&
	        is_ok( $server_answer ) &&
	        ! $container ) {
	    $API::CPanel::last_answer = $server_answer;
	    return $server_answer;
	}
        else {
            $API::CPanel::last_answer = $server_answer;
	    warn "wrong server answer" if $DEBUG;
	    return '';
        };
    } else {
        $API::CPanel::last_answer = 'auth_hash not found';
        warn "auth_hash not found" if $DEBUG;
        return '';
    }
}

# Abstract sub for action methods
sub action_abstract {
    my %params = @_;

    my $result = query_abstract(
	params         => $params{params},
	func           => $params{func},
	container      => $params{container},
	allowed_fields => $params{allowed_fields},
    );

    return $params{want_hash} && is_success( $result, $params{want_hash} ) ? $result : is_success( $result );
}

# Abstract sub for fetch arrays
sub fetch_array_abstract {
    my %params = @_;

    my $result_field = $params{result_field} || '';
    my $result_list = [ ];
    my $result = query_abstract(
	params         => $params{params},
	func           => $params{func},
	container      => $params{container},
	allowed_fields => $params{allowed_fields},
    );
    return $result_list  unless $result;
    $result = [ $result ] if ref $result ne 'ARRAY';

    foreach my $elem ( @{ $result } ) {
	push @$result_list, $result_field ? $elem->{$result_field} : $elem;
    };

    return $result_list;
}

# Abstract sub for fetch hash
sub fetch_hash_abstract {
    my %params = @_;

    my $result = query_abstract(
	params         => $params{params},
	func           => $params{func},
	container      => $params{container},
	allowed_fields => $params{allowed_fields},
    );

    my $result_hash = {};
    return $result_hash unless $params{key_field};
    my $key_field   = $params{key_field};
    foreach my $each ( @$result ) { 
        $result_hash->{$each->{$key_field}} = $each;
    }

    return $result_hash;
}

1;
