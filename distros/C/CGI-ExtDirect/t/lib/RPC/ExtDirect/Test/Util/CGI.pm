package RPC::ExtDirect::Test::Util::CGI;

use strict;
use warnings;
no  warnings 'uninitialized';

use Test::More;

use CGI::Test ();       # No need to import ok() from CGI::Test
use CGI::Test::Input::URL ();
use CGI::Test::Input::Multipart ();

use RPC::ExtDirect::Test::Util;

use base 'Exporter';

our @EXPORT = qw/
    run_tests
/;

our @EXPORT_OK = qw/
    raw_post
    form_post
    form_upload
/;

use constant WINDOWS => eval { $^O =~ /Win32|cygwin/ };

### EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Run the test battery from the passed definitions
#

sub run_tests {
    my ($tests, @run_only) = @_;
    
    my $cmp_pkg   = 'RPC::ExtDirect::Test::Util';
    my $num_tests = @run_only || @$tests;
    
    plan tests => 5 * $num_tests;

    TEST:
    for my $test ( @$tests ) {
        my $name   = $test->{name};
        my $config = $test->{config} || {};
        my $input  = $test->{input};
        my $output = $test->{output};
        
        next TEST if @run_only && !grep { lc $name eq lc $_ } @run_only;
        
        my $ct = CGI::Test->new(
            -base_url => 'http://localhost/cgi-bin',
            -cgi_dir  => 't/cgi-bin',
            %$config,
        );
    
        # CGI tests have the config hardcoded in the scripts
        my $url           = $ct->base_uri
                          . $input->{cgi_url}
                          . ( WINDOWS ? '.bat' : '' );
        my $method        = $input->{method};
        my $input_content = $input->{cgi_content} || $input->{content};
        
        my $req = prepare_input 'CGI', $input_content;
        my $page = $ct->$method($url, $req);

        if ( ok $page, "$name not empty" ) {
            my $want_status = $output->{status};
            my $have_status = $page->is_ok() ? 200 : $page->error_code();

            is $have_status, $want_status, "$name: HTTP status";

            my $want_type = $output->{content_type};
            my $have_type = $page->content_type();
            
            like $have_type, $want_type, "$name: content type";

            my $want_len = defined $output->{cgi_content_length}
                         ? $output->{cgi_content_length}
                         : $output->{content_length};
            my $have_len = $page->content_length();

            is $have_len, $want_len, "$name: content length";
            
            my $cmp_fn = $output->{comparator};
            my $want   = $output->{cgi_content} || $output->{content};
            my $have   = $page->raw_content();
            
            $cmp_pkg->$cmp_fn($have, $want, "$name: content")
                or diag explain "Page: ", $page;

            $page->delete();
        };
    };
}

### NON EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Return a new CGI::Test::Input object for a raw POST call
#

sub raw_post {
    # This can be called either as a class method, or a plain sub
    shift if $_[0] eq __PACKAGE__;
    
    my ($url, $input) = @_;

    my $cgi_input = CGI::Test::Input::URL->new();
    $cgi_input->set_raw_data($input);
    $cgi_input->set_mime_type('application/json');

    return $cgi_input;
}

### NON EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Return a new CGI::Test::Input oject for a form call
#

sub form_post {
    # This can be called either as a class method, or a plain sub
    shift if $_[0] eq __PACKAGE__;

    my ($url, %fields) = @_;

    my $cgi_input = CGI::Test::Input::URL->new();
    for my $field ( keys %fields ) {
        my $value = $fields{ $field };
        $cgi_input->add_field($field, $value);
    };

    return $cgi_input;
}

### NON EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Return a new CGI::Test::Input object for a form call
# with file uploads
#

sub form_upload {
    # This can be called either as a class method, or a plain sub
    shift if $_[0] eq __PACKAGE__;

    my ($url, $files, %fields) = @_;

    my $cgi_input = CGI::Test::Input::Multipart->new();

    for my $field ( keys %fields ) {
        my $value = $fields{ $field };
        $cgi_input->add_field($field, $value);
    };

    for my $file ( @$files ) {
        $cgi_input->add_file_now("upload", "t/data/cgi-data/$file");
    };

    return $cgi_input;
}


1;
