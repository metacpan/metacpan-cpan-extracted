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

my @a_urls = ();
fake_cgi_bin(sub {
	my ($dir, $file, $url, $is_perl) = @_;
	push(@a_urls, $url);
	if ($file =~ /CGI_pm_nph-multipart/)	{
		any $url => sub {
			fake_cgi_file($file, {timeout => 5});
			fake_cgi_as_string;
		};
		return 1;
	} else	{
		return 0;
	}
});

any fake_cgi_bin_url('CGI_pm_frameset.pl/*') => sub {
    my ($file) = splat;
    debug "Frame:$file";
    fake_cgi_file('CGI_pm_frameset.pl');
    fake_cgi_as_string;
};

get '/left' => sub {
   	template 'left', {URLs=>\@a_urls};
};

dance;
