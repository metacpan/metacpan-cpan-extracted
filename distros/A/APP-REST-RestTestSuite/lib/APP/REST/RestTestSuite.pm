package APP::REST::RestTestSuite;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use HTTP::Request;
use Time::HiRes qw( time sleep );
use File::Path;
use Cwd;
use LWP::UserAgent;
use APP::REST::ParallelMyUA;


use constant LOG_FILE     => 'rest_client.log';
use constant ERR_LOG_FILE => 'rest_client_error.log';
use constant LINE         => '=' x 50;

$|                    = 1;    #make the pipe hot
$Data::Dumper::Indent = 1;

=head1 NAME

APP::REST::RestTestSuite - Suite for testing restful web services 

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

use APP::REST::RestTestSuite;
my $suite = APP::REST::RestTestSuite->new();

$suite->execute_test_cases( $suite->get_test_cases() );
my ( $cases_in_config, $executed, $skipped, $passed, $failed ) =
  $suite->get_result_summary();

#OR

use APP::REST::RestTestSuite;

# overrides the default config and log file paths
my $suite = APP::REST::RestTestSuite->new(
    REST_CONFIG_FILE => <config file>,
    LOG_FILE_PATH    => <path>,
);

$suite->execute_test_cases( $suite->get_test_cases() );
my ( $cases_in_config, $executed, $skipped, $passed, $failed ) =
  $suite->get_result_summary();

 
=head1 DESCRIPTION

APP::REST::RestTestSuite object is instantiated with the data in config file. 
Default config file format is defined in __DATA__ and that can be overridden
by passing the config file as an argument to the class.
Default LOG file path is the current working directory of the script which 
calls this module

=head1 SUBROUTINES/METHODS

=head2 new

Object Constructor

=cut

sub new {
    my ( $class, %args ) = @_;

    my $self = {};

    bless( $self, $class );

    $self->_init(%args);

    return $self;
}

=head2 get_test_cases


=cut

sub get_test_cases {
    my ( $self, %args ) = @_;

    if ( $self->{test_cases} ) {
        return %{ $self->{test_cases} };
    } else {
        return undef;
    }
}

=head2 get_log_file_handle


=cut

sub get_log_file_handle {
    my ( $self, %args ) = @_;

    return $self->{file}->{log_file_handle};
}

=head2 get_err_log_file_handle


=cut

sub get_err_log_file_handle {
    my ( $self, %args ) = @_;

    return $self->{file}->{err_log_file_handle};
}

=head2 get_config_file_handle


=cut

sub get_config_file_handle {
    my ( $self, %args ) = @_;

    return $self->{file}->{config_file_handle};
}

=head2 get_config_file


=cut

sub get_config_file {
    my ( $self, %args ) = @_;

    return $self->{file}->{config_file};
}

=head2 get_sample_config_file


=cut

sub get_sample_config_file {
    my ( $self, %args ) = @_;

    return $self->{file}->{sample_config_file};
}

=head2 get_result_summary


=cut

sub get_result_summary {
    my ( $self, %args ) = @_;

    return (
        $self->{test_result_log}->{test_cases_in_config},
        $self->{test_result_log}->{test_cases_exececuted},
        $self->{test_result_log}->{test_cases_skipped},
        $self->{test_result_log}->{test_cases_passed},
        $self->{test_result_log}->{test_cases_failed},
    );
}

=head2 validate_test_cases


=cut

sub validate_test_cases {
    my ($self) = shift;

    my $err = undef;

    unless (@_) {
        $err = "There is no test cases defined to execute.\n";
    } elsif ( ( (@_) % 2 ) == 1 ) {
        $err =
            "Test cases are not properly configured in '"
          . $self->get_config_file()
          . "'\nDefine test cases properly.\nPlease see the README file for more info.\n";
    }
    return $err if ($err);

    my %test_cases = @_;

    my @spec = sort qw(
      test_case
      uri
      request_content_type
      request_method
      request_body
      response_status
      execute
      response_content_type
    );

#below two are not mandatory for a test case as of now; if required add them to above array
# response_header
# response_body

    foreach my $count ( sort { $a <=> $b } keys(%test_cases) ) {

        my $tc   = $test_cases{$count};
        my @keys = sort keys %{$tc};

        no warnings;
        $err .= "Test case '$tc->{test_case}' not properly defined\n"
          unless ( _compare_arrays( \@spec, \@keys ) );
    }

    $err .= "Please see the README file to see the correct format.\n" if ($err);

    return $err;

}

=head2 execute_test_cases


=cut

sub execute_test_cases {
    my ($self) = shift;

  #expects an hash with keys as test case number and value as hash ref with test
  #specification; validate that before trying to execute them.
    my $err = $self->validate_test_cases(@_);

    die "ERROR: $err\n" if ($err);

    my %test_cases = @_;

    my $ua = LWP::UserAgent->new;

    $ua->agent("RTAT/$VERSION");
    $ua->timeout(90);    # in seconds
    $ua->default_header('Accept' => '*/*'); # to get cross platform support


    my ( $config, $total, $total_response_time, $skip, $pass, $fail ) = (0) x 6;
    my ( $uri, $method, $req_content_type, $req_body, $status ) = (undef) x 5;
    my ( $request,  $response ) = (undef) x 2;
    my ( $username, $password ) = (undef) x 2;

    $username = $self->{username};
    $password = $self->{password};

    my $fh     = $self->get_log_file_handle();
    my $err_fh = $self->get_err_log_file_handle();

    if ( $self->{html_log_required}
        && ( $self->{html_log_required} =~ /yes/i ) )
    {
        print $fh
          qq|<HTML> <HEAD> <TITLE>LOG for $self->{endpoint}</TITLE> </HEAD>|
          . qq|<BODY><textarea rows="999999" cols="120" style="border:none;">|;
        print $err_fh
qq|<HTML> <HEAD> <TITLE>ERROR LOG for $self->{endpoint}</TITLE> </HEAD>|
          . qq|<BODY><textarea rows="999999" cols="120" style="border:none;">|;
    }

    print STDERR "\nTest Suite executed on $self->{endpoint}\n";
    print $fh "\nTest Suite executed on $self->{endpoint}\n";
    print $err_fh "\nTest Suite executed on $self->{endpoint}\n";

    foreach my $count ( sort { $a <=> $b } keys(%test_cases) ) {

        my $tc = $test_cases{$count};

        $config++;
        print $fh "\n", LINE, "\n";
        if ( $tc->{execute} && ( $tc->{execute} =~ /no/i ) ) {
            print $fh "\nSkipping Test case $count => $tc->{test_case} \n";
            $skip++;
            next;
        }

        $uri              = qq|$self->{rest_uri_base}| . qq|$tc->{uri}|;
        $method           = uc( $tc->{request_method} );
        $req_content_type = $tc->{request_content_type};
        $req_body         = $tc->{request_body} || 0;
        $status           = $tc->{response_status};

        if ( $tc->{request_method} =~ /get/i ) {
            $request = HTTP::Request->new( $method, $uri );
            $request->authorization_basic( $username, $password )
              if ( $username && $password );
        } else {
            $request =
              HTTP::Request->new( $method, $uri, new HTTP::Headers, $req_body );
            $request->authorization_basic( $username, $password )
              if ( $username && $password );
            $request->content_type($req_content_type);
            $request->content_length( length($req_body) );
        }

        print STDERR "Executing Test case $count => $tc->{test_case}";
        print $fh "Executing Test case $count => $tc->{test_case}";

        my $start_time = time;
        $response = $ua->request($request);
        $total++;
        my $exec_time = $self->delta_time( start_time => $start_time );
        $total_response_time += $exec_time;
        $exec_time = sprintf( "%.2f", $exec_time );

        print STDERR " [Completed in $exec_time ms]\n";
        print $fh " [Completed in $exec_time ms]\n";

        $self->_print_logs(
            fh       => $fh,
            uri      => $uri,
            method   => $method,
            req_body => $req_body,
        );
        $self->_print_logs(
            fh        => $fh,
            res       => $response,
            exec_time => $exec_time,
        );

        #Level-1 check => check for response status code
        #Level-2 check => check for expected response content_type
        my $resp_code = $response->code;
        if ( $status =~ m/$resp_code/ ) {
            my $failed = 0;
            if ( defined $tc->{response_content_type} ) {
                my $expected_response_content_type =
                  $tc->{response_content_type};

      #my $respose_content_type           = $response->{_headers}->content_type;
                my $respose_content_type = $response->header('Content-Type');
                unless ( defined $respose_content_type ) {
                    $failed = 1;
                } elsif ( $expected_response_content_type !~
                    m/$respose_content_type/ )
                {
                    $failed = 1;
                    print $err_fh "\n", LINE, "\n";
                    print $err_fh
                      "Executing Test case $count => $tc->{test_case}";
                    print $err_fh
                      "\n*********ATTENTION CONTENT TYPE ERROR ******";
                    print $err_fh
"\n\nExpected content_type is $expected_response_content_type\n";
                    print $err_fh
"content_type recieved in response is $respose_content_type\n";
                    print $err_fh
                      "\n*********ATTENTION CONTENT TYPE ERROR ******";
                    $self->_print_logs(
                        fh       => $err_fh,
                        uri      => $uri,
                        method   => $method,
                        req_body => $req_body,
                    );
                    $self->_print_logs(
                        fh        => $err_fh,
                        res       => $response,
                        exec_time => $exec_time,
                    );
                }
            }
            ($failed) ? $fail++ : $pass++;
        } else {
            $fail++;
            print $err_fh "\n", LINE, "\n";
            print $err_fh "Executing Test case $count => $tc->{test_case}";
            $self->_print_logs(
                fh       => $err_fh,
                uri      => $uri,
                method   => $method,
                req_body => $req_body,
            );
            $self->_print_logs(
                fh        => $err_fh,
                res       => $response,
                exec_time => $exec_time,
            );
        }
    }

    #convert milli seconds to seconds for total_exec_time
    $total_response_time = sprintf( "%.2f", $total_response_time / 1000 );
    my $avg_response_time =
      sprintf( "%.2f", ( $total_response_time * 1000 ) / $total );

    print STDERR "\nComplete test case report is in $self->{file}->{log_file}";
    print STDERR
      "\nFailed test case report is in $self->{file}->{err_log_file}\n\n";

    print STDERR
"Response time of $total web service calls => [$total_response_time seconds]\n";
    print STDERR
"Average response time of a web service => [$avg_response_time milli seconds]\n\n";

    print $fh
"Response time of $total web service calls => [$total_response_time seconds]\n";
    print $fh
"Average response time of a web service => [$avg_response_time milli seconds]\n\n";

    if ( $self->{html_log_required}
        && ( $self->{html_log_required} =~ /yes/i ) )
    {
        print $fh qq|</textarea></BODY></HTML>|;
        print $err_fh qq|</textarea></BODY></HTML>|;
    }

    $self->{test_result_log} = {
        test_cases_in_config  => $config,
        test_cases_exececuted => $total,
        test_cases_skipped    => $skip,
        test_cases_passed     => $pass,
        test_cases_failed     => $fail,
    };

    close($fh);
    close($err_fh);

}

=head2 execute_test_cases_in_parallel


=cut

sub execute_test_cases_in_parallel {
    my ($self) = shift;

#Code expects an hash with keys as test case number and value as hash ref with test
#specification; validate that before trying to execute them.
    my $err = $self->validate_test_cases(@_);

    die "ERROR: $err\n" if ($err);

    my %test_cases = @_;

    # use my customized user agent for parallel invokes
    my $pua = APP::REST::ParallelMyUA->new();

    $pua->agent("RTAT/$VERSION");
    $pua->in_order(1);      # handle requests in order of registration
    $pua->duplicates(0);    # ignore duplicates
    $pua->timeout(60);      # in seconds
    $pua->redirect(1);      # follow redirects
    $pua->default_header('Accept' => '*/*'); # to get cross platform support

    my ( $config, $total, $total_response_time, $skip, $pass, $fail ) = (0) x 6;
    my ( $uri, $method, $req_content_type, $req_body, $status ) = (undef) x 5;
    my ( $request,  $response ) = (undef) x 2;
    my ( $username, $password ) = (undef) x 2;

    $username = $self->{username};
    $password = $self->{password};

    my $fh = $self->get_log_file_handle();

    if ( $self->{html_log_required}
        && ( $self->{html_log_required} =~ /yes/i ) )
    {
        print $fh
          qq|<HTML> <HEAD> <TITLE>LOG for $self->{endpoint}</TITLE> </HEAD>|
          . qq|<BODY><textarea rows="999999" cols="120" style="border:none;">|;
    }

    print STDERR "\nTest Suite executed on $self->{endpoint}\n";
    print $fh "\nTest Suite executed on $self->{endpoint}\n";

    my @reqs;

    foreach my $count ( sort { $a <=> $b } keys(%test_cases) ) {

        my $tc = $test_cases{$count};

        $config++;
        if ( $tc->{execute} =~ /no/i ) {
            print $fh "\nSkipping Test case $count => $tc->{test_case} \n";
            $skip++;
            next;
        }

        $uri = qq|$self->{rest_uri_base}| . qq|$tc->{uri}|;

        #Support only GET methods at present
        if ( $tc->{request_method} =~ /get/i ) {

            # Create HTTP request pool for later execution by parallel useragent
            $method           = uc( $tc->{request_method} );
            $req_content_type = $tc->{request_content_type};
            $req_body         = $tc->{request_body} || 0;
            $status           = $tc->{response_status};

            my $request = HTTP::Request->new( $method, $uri );
            $request->authorization_basic( $username, $password )
              if ( $username && $password );
            push( @reqs, $request );
        }

        $total++;

    }

    print STDERR "\nRequesting [$total] web services together.\n";
    foreach my $req (@reqs) {

        # register all requests and wait for them to finish
        if ( my $res = $pua->register($req) ) {
            print STDERR $res->error_as_HTML;
        }
    }
    print STDERR "Receiving response from web services. Please wait..!\n";

    # will return once all forked web services are either completed or timeout
    my $entries = $pua->wait();

    print STDERR "\n\n";

    foreach ( keys %$entries ) {
        my $response  = $entries->{$_}->response;
        my $tick      = $entries->{$_}->{tick};
        my $exec_time = ( $tick->{end} - $tick->{start} ) * 1000 ;

        $total_response_time += $exec_time;
        $exec_time =  sprintf( "%.2f", $exec_time );

        print STDERR "\n", $response->request->url,
          "\n !  Response Status [", $response->code,
          "]\tResponse Time [$exec_time ms]";
        $self->_print_logs(
            fh       => $fh,
            uri      => $response->request->url,
            method   => $response->request->method,
            req_body => ''
        );
        $self->_print_logs(
            fh        => $fh,
            res       => $response,
            exec_time => $exec_time,
        );

    }

    #convert milli seconds to seconds for total_exec_time
    $total_response_time = sprintf( "%.2f", $total_response_time / 1000 );
    my $avg_response_time =
      sprintf( "%.2f", ( $total_response_time * 1000 ) / $total );

    print STDERR
      "\n\n\nComplete test case report is in $self->{file}->{log_file}";

    print STDERR
"\n\nResponse time of $total web service calls => [$total_response_time seconds]\n";
    print STDERR
"Average response time of a web service => [$avg_response_time milli seconds]\n\n";

    print $fh
"\n\nResponse time of $total web service calls => [$total_response_time seconds]\n";
    print $fh
"Average response time of a web service => [$avg_response_time milli seconds]\n\n";

    if ( $self->{html_log_required}
        && ( $self->{html_log_required} =~ /yes/i ) )
    {
        print $fh qq|</textarea></BODY></HTML>|;
    }

    $self->{test_result_log} = {
        test_cases_in_config  => $config,
        test_cases_exececuted => $total,
        test_cases_skipped    => $skip,
        test_cases_passed     => $pass,
        test_cases_failed     => $fail,
    };

    close($fh);

}

=head2 get_sample_test_suite 


=cut

sub get_sample_test_suite {
    my ( $self, %args ) = @_;

    $self->_init_sample_config_file();

    my $file = $self->{file};
    my $wfh =
      $self->_open_fh( FILE => $file->{sample_config_file}, MODE => 'WRITE' );

    foreach ( @{$file->{config_file_content}}) {
        print $wfh $_;
    }
    close($wfh);
}

=head2 delta_time


=cut

sub delta_time {
    my ( $self, %args ) = @_;

    my $now = time;
    return ( ( $now - $args{start_time} ) * 1000 );    #convert to milli seconds
}

sub _init {
    my ( $self, %args ) = @_;

    $self->_init_config_file_handle(%args);

    # Read the config file based on the type of the input file (xml or text)
    if ( $args{CONFIG_FILE_TYPE} && ( $args{CONFIG_FILE_TYPE} =~ /xml/i ) ) {

        #Implement the xml reading
    } else {
        $self->_init_read_config(%args);
    }

    $self->_init_log_file_handle(%args);

    $self->_init_rest_base_uri(%args);
}

sub _init_config_file_handle {
    my ( $self, %args ) = @_;

    $self->_init_config_files(%args);

    my $file = $self->{file};
    if ( $file->{config_file} ) {
        $file->{config_file_handle} =
          $self->_open_fh( FILE => $file->{config_file}, MODE => 'READ' );
    } else {
        $file->{config_file_handle} = \*APP::REST::RestTestSuite::DATA;
    }

    $self->{file} = $file;
}

sub _init_log_file_handle {
    my ( $self, %args ) = @_;

    $self->_init_log_files(%args)
      ;    #Make compatible with windows and linux logging

    my $file = $self->{file};

    $file->{log_file_handle} =
      $self->_open_fh( FILE => $file->{log_file}, MODE => 'WRITE' );
    $file->{err_log_file_handle} =
      $self->_open_fh( FILE => $file->{err_log_file}, MODE => 'WRITE' );

    $self->{file} = $file;
}

sub _init_read_config {
    my ( $self, %args ) = @_;

    my $fh = $self->get_config_file_handle();

    my @buffer           = ();
    my @start_end_buffer = ();

    my ( $start_case, $end_case, $test_no ) = (undef) x 3;
    my ( $start_common,    $end_common )    = (undef) x 2;
    my ( $start_http_code, $end_http_code ) = (undef) x 2;
    my ( $start_tag, $lines_between, $end_tag ) = (undef) x 3;

    my $separator = ":";    # separator used in config file for key/value pair
    my %start_end_hash;

    my $file = $self->{file};

    while (<$fh>) {

        push (@{$file->{config_file_content}} , $_);
        _trim( chomp($_) );
        next if ( $_ =~ m/^#+$/ || $_ =~ m/^\s*$/ || $_ =~ m/^#\s+/ );
        last if ( $_ =~ m/^#END_OF_CONFIG_FILE\s*$/ );

        ## Process common configuration for all test cases
        if ( $_ =~ m/^#START_COMMON_CONFIG\s*$/ ) {
            $start_common = 1;
            next;
        }
        $end_common = 1 if ( $_ =~ m/^#END_COMMON_CONFIG\s*$/ );
        push( @buffer, $_ ) if ( $start_common && !$end_common );

        if ( $start_common && $end_common ) {
            foreach my $line (@buffer) {
                my @val = split( $separator, $line );
                $self->{ _trim( $val[0] ) } = _trim( $val[1] );
            }

            @buffer       = ();
            $start_common = 0;
            $end_common   = 0;
        } elsif ( !$start_common && $end_common ) {
            die "ERROR in config file format\n";
        }

        ## Process test cases
        if ( $_ =~ m/^#START_TEST_CASE\s*$/ ) {
            $start_case = 1;
            next;
        }
        $end_case = 1 if ( $_ =~ m/^#END_TEST_CASE\s*$/ );

        push( @buffer, $_ ) if ( $start_case && !$end_case );

        ## Process [START] and [END] tag for any keys
        $start_tag = 1 if ( $_ =~ m/^\s*\[START\]\s*$/ );
        $end_tag   = 1 if ( $_ =~ m/^\s*\[END\]\s*$/ );

        if ( $start_tag && !$end_tag ) {
            $lines_between++;
            push( @start_end_buffer, $_ );
        }

        if ( $start_tag && $end_tag ) {

            my $req_body = '';
            $req_body .= _trim($_) foreach (@start_end_buffer);
            $req_body =~ s/\[START\]//g;
            $req_body =~ s/\[END\]//g;

            while ( $lines_between >= 0 ) {
                $lines_between--;
                pop @buffer;
            }

            my $line = pop @buffer;
            $line =~ s/\s+://g;
            $line =~ s/^\s+//g;

            ## create the key with the values given in between [START] and [END] tag
            $start_end_hash{$line} = $req_body;

            @start_end_buffer = ();
            $start_tag        = 0;
            $end_tag          = 0;
            $lines_between    = 0;
        }

        if ( $start_case && $end_case ) {
            $test_no++;
            foreach my $line (@buffer) {
                my @val = split( $separator, $line );
                $self->{test_cases}->{$test_no}->{ _trim( $val[0] ) } =
                  _trim( $val[1] );
            }

         # add all those in between [START] and [END] tage to the respective key
            while ( my ( $key, $value ) = each %start_end_hash ) {
                $self->{test_cases}->{$test_no}->{$key} = $value;
            }

            %start_end_hash = ();
            @buffer         = ();
            $start_case     = 0;
            $end_case       = 0;
        } elsif ( !$start_case && $end_case ) {
            die "ERROR in config file format\n";
        }

        ## Process HTTP status codes
        if ( $_ =~ m/^#START_HTTP_CODE_DEF\s*$/ ) {
            $start_http_code = 1;
            next;
        }
        $end_http_code = 1 if ( $_ =~ m/^#END_HTTP_CODE_DEF\s*$/ );
        push( @buffer, $_ ) if ( $start_http_code && !$end_http_code );

        if ( $start_http_code && $end_http_code ) {
            foreach my $line (@buffer) {
                my @val = split( $separator, $line );
                $self->{http_status_code}->{ _trim( $val[0] ) } =
                  _trim( $val[1] );
            }

            @buffer          = ();
            $start_http_code = 0;
            $end_http_code   = 0;
        } elsif ( !$start_http_code && $end_http_code ) {
            die "ERROR in config file format\n";
        }

    }
    close($fh);
}

sub _init_rest_base_uri {
    my ( $self, %args ) = @_;

    if ( $self->{username} ) {
        print STDERR "username configured: $self->{username}\n";
        print STDERR "Password: ";
        chomp( $self->{password} = <STDIN> );
    }

    if ( $self->{endpoint} && $self->{port} && $self->{base_uri} ) {
        $self->{rest_uri_base} =
            qq|http://$self->{endpoint}|
          . qq|:$self->{port}|
          . qq|$self->{base_uri}|;
        return;    #use the port and uri in config file and return from sub
    } elsif ( $self->{endpoint} && $self->{base_uri} ) {
        $self->{rest_uri_base} =
          qq|http://$self->{endpoint}| . qq|$self->{base_uri}|;
        return;    #use the uri in config file and return from sub
    } elsif ( $self->{endpoint} && $self->{port} ) {
        $self->{rest_uri_base} =
          qq|http://$self->{endpoint}| . qq|:$self->{port}|;
        return;
    } elsif ( $self->{endpoint} ) {
        $self->{rest_uri_base} = qq|http://$self->{endpoint}|;
        return;    #use the endpoint in config file and return from sub
    } else {
        die qq|Endpoint should be configured in the config file\n|;
    }

}

sub _init_config_files {
    my ( $self, %args ) = @_;

    $self->{file}->{config_file} = $args{REST_CONFIG_FILE};
}

sub _init_sample_config_file {
    my ( $self, %args ) = @_;

    my $separator;
    if ( $^O =~ /Win/ ) {
        $separator = '\\';
    } else {
        $separator = '/';
    }

    my $scfg = getcwd() || $ENV{PWD};
    my $scfg_file = $scfg . $separator . 'rest-project-xxxx.txt';

    $self->{file}->{sample_config_file} = $scfg_file;

}

sub _init_log_files {
    my ( $self, %args ) = @_;

    my $separator;
    if ( $^O =~ /Win/ ) {
        $separator = '\\';
    } else {
        $separator = '/';
    }

    my $log_path = $args{LOG_FILE_PATH} || getcwd() || $ENV{PWD};
    my $log_dir = $log_path . $separator . 'LOG';

    eval { mkpath( $log_dir, 0, 0755 ) unless ( -d $log_dir ); };

    if ($@) {
        my $err = $@;
        $err =~ s/line\s+\d+//g;
        die qq|Unable to create LOG directory ERROR: $err\n|;
    }

    my $log_file = join(
        $separator,
        (
            $log_dir,
            (
                $self->{html_log_required}
                  && ( $self->{html_log_required} =~ /yes/i )
              )
            ? LOG_FILE
              . ".html"
            : LOG_FILE
        )
    );
    my $error_log_file = join(
        $separator,
        (
            $log_dir,
            (
                $self->{html_log_required}
                  && ( $self->{html_log_required} =~ /yes/i )
              )
            ? ERR_LOG_FILE
              . ".html"
            : ERR_LOG_FILE
        )
    );
    $self->{file}->{log_file}     = $log_file;
    $self->{file}->{err_log_file} = $error_log_file;
}

sub _open_fh {
    my ( $self, %args ) = @_;

    my ( $fh, $err ) = (undef) x 2;

    my $file = $args{FILE};
    my $mode = $args{MODE};

    if ( $mode =~ m/READ/i ) {
        open( $fh, '<', "$file" ) or ( $err = 'yes' );
    } elsif ( $mode =~ m/WRITE/i ) {
        open( $fh, '>', "$file" ) or ( $err = 'yes' );
    } elsif ( $mode =~ m/APPEND/i ) {
        open( $fh, '>>', "$file" ) or ( $err = 'yes' );
    }

    if ($err) {
        die qq|\nUnable to open file '$file' for $mode\nERROR: $!\n|;
    }

    return $fh;

}

sub _trim($) {

    return unless ( $_[0] );

    my $str = $_[0];
    $str =~ s/^\s+//g;
    $str =~ s/\s+$//g;

    return $str;
}

sub _print_logs {
    my ( $self, %args ) = @_;

    no warnings;

    my $fh       = $args{fh};
    my $res      = $args{res};
    my $uri      = $args{uri};
    my $method   = $args{method};
    my $req_body = $args{req_body};

    my $define =
"Definition of status code not available; Please define in config if this is a custom code";

    unless ( $args{res} ) {
        print $fh "\n";
        print $fh "URI           => $uri\n";
        print $fh "HTTP Method   => $method\n";
        print $fh "Request Body  => \n$req_body\n" if ( $method !~ /get/i );
    } else {

        print $fh "\n";
        print $fh "Response code => ";
        print $fh $res->code;
        print $fh " [ ";
        print $fh ( exists $self->{http_status_code}->{ $res->code } )
          ? $self->{http_status_code}->{ $res->code }
          : $define;
        print $fh " ]\n";
        print $fh "\n\nResponse Content    =>\n";
        print $fh $res->content;
        print $fh "\n\nTest execution time => ";
        print $fh $args{exec_time};
        print $fh " milli seconds";
        print $fh "\n", LINE, "\n";
    }

}

sub _compare_arrays {
    my ( $first, $second ) = @_;
    no warnings;    # silence spurious -w undef complaints
    return 0 unless @$first == @$second;
    for ( my $i = 0 ; $i < @$first ; $i++ ) {
        return 0 if $first->[$i] ne $second->[$i];
    }
    return 1;
}

=head1 AUTHOR

Mithun Radhakrishnan, C<< <rkmithun at cpan.org> >>

=head1 BUGS


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc APP::REST::RestTestSuite


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Mithun Radhakrishnan.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

=head1 REPOSITORY

L<https://github.com/rkmithun/APP-REST-RestTestSuite>

=cut

1;    # End of APP::REST::RestTestSuite

__DATA__

# RestTestSuite supports config file of below format.
# All values in LHS of ':' are case sensitive. 
# Every test case should be within the '#START_TEST_CASE' and '#END_TEST_CASE' block.
# Create application specific config file in below format and pass the 
# full path of file as an argument to the constructor
# for POST and PUT methods you need to supply the request body within
# [START] and [END] tags
#   request_body             :
#   [START] 
#   xml or json or  form based 
#   [END]
################
#Set below values to configure the base URL for all test cases

####################
#START_COMMON_CONFIG
################################################################################
  endpoint                  : www.thomas-bayer.com 
  port                      :
  base_uri                  : /sqlrest 
  html_log_required         : no 
  username                  : 

################################################################################
#END_COMMON_CONFIG
##################

#####################
#START_TEST_CASE
#####################
  test_case                : get_product
  uri                      : /PRODUCT/49
  request_content_type     : application/xml
  request_method           : GET
  request_body             :
  response_status          : 200
  execute                  : yes
  response_content_type    : application/xml 
#####################
#END_TEST_CASE
#####################

###########################
#START_HTTP_CODE_DEF
############################
200 :  operation successful.
201 :  Successful creation of a resource.
202 :  The request was received.
204 :  The request was processed successfully, but no response body is needed.
301 :  Resource has moved.
303 :  Redirection.
304 :  Resource has not been modified.
400 :  Malformed syntax or a bad query.
401 :  Action requires user authentication.
403 :  Authentication failure or invalid Application ID.
404 :  Resource not found.
405 :  Method not allowed on resource.
406 :  Requested representation not available for the resource.
408 :  Request has timed out.
409 :  State of the resource doesn't permit request.
410 :  The URI used to refer to a resource.
411 :  The server needs to know the size of the entity body and it should be specified in the Content Length header.
412 :  Operation not completed because preconditions were not met.
413 :  The representation was too large for the server to handle.
414 :  The URI has more than 2k characters.
415 :  Representation not supported for the resource.
416 :  Requested range not satisfiable.
500 :  Internal server error.
501 :  Requested HTTP operation not supported.
502 :  Backend service failure (data store failure).
505 :  HTTP version not supported.
############################
#END_HTTP_CODE_DEF
############################

####################
#END_OF_CONFIG_FILE
####################

