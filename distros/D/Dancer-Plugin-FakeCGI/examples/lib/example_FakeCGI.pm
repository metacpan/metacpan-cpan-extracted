package example_FakeCGI;

use Dancer ':syntax';
use Dancer::Plugin::FakeCGI;
use Data::Dumper;
use Test::TinyMocker;

#unless ( Test::TinyMocker->can('mocked') )	{
#	# Test::TinyMocker still not have my patched to do this
#	package Test::TinyMocker;
#	sub mocked($$) { $Test::TinyMocker::mocks->{join("::", @_)} }
#}

our $VERSION = '0.1';

hook 'fake_cgi_before' => sub {
	my $env = shift;
	#print STDERR Dumper($env) . "\n";
};

get '/' => sub {
    template 'index', {}, {layout => undef};
};

get '/left' => sub {
    template 'left';
};

any fake_cgi_bin_url('/test_1') => sub {
    fake_cgi_method("test_CGI", "test");
    fake_cgi_as_string;
};

any fake_cgi_bin_url('test_2') => sub {
    fake_cgi_method("test_CGI_OOP", "test");
    fake_cgi_as_string;
};

any fake_cgi_bin_url('test_3') => sub {
    fake_cgi_file("test_CGI_file.pl");
    fake_cgi_as_string;
};

any fake_cgi_bin_url('test_4') => sub {
    #params->{'location'} = fake_cgi_bin_url('/test_1');
    my $p = params();
	$p->{'location'} = fake_cgi_bin_url('/test_1');
    fake_cgi_file("test_redirect.pl");
    fake_cgi_as_string;
};

any fake_cgi_bin_url('test_5') => sub {
    fake_cgi_file("test_env.pl");
    fake_cgi_as_string;
};

any fake_cgi_bin_url('test_6') => sub {
    fake_cgi_compile({package => "test_CGI_mocked"});
    mock(
        "test_CGI_mocked",
        "test_param",
        sub {
            my $code = mocked("test_CGI_mocked", "test_param");
            &$code();
            print "Testing mocked <br />";
        }
    );
    fake_cgi_method("test_CGI_mocked", "test");
    fake_cgi_as_string;
};

any fake_cgi_bin_url('test_7') => sub {
    fake_cgi_file("test_cookie.pl");
    fake_cgi_as_string;
};

any fake_cgi_bin_url('test_8') => sub {
	my $x = fake_cgi_is_perl ("test.sh", 1);
    return " Tested script test.sh " . ($x ? "is" : "isn't") . " Perl script";
};

any fake_cgi_bin_url('test_9') => sub {
	fake_cgi_file ("test.sh", undef, 1);
    fake_cgi_as_string;
};

any fake_cgi_bin_url('CGI_pm_frameset.pl/*') => sub {
    my ($file) = splat;
    debug "Frame:$file";
    fake_cgi_file('CGI_pm_frameset.pl');
    fake_cgi_as_string;
};

any fake_cgi_bin_url('*.pl') => sub {
    my ($file) = splat;
    debug $file;
    fake_cgi_file($file . ".pl",
        ($file eq "CGI_pm_nph-multipart") ? {timeout => 5} : undef);
    fake_cgi_as_string;
};

true;
