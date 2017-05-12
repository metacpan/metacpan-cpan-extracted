package App::VirtPerl::Setup;
$App::VirtPerl::Setup::VERSION = '0.1';
use strict;
use Config;
use lib ();


my @original_inc;
BEGIN { @original_inc = @INC };

sub import {
	return unless $ENV{PERL_VIRTPERL_ROOT} && $ENV{PERL_VIRTPERL_CURRENT_ENV};
	
	my $current = "$ENV{PERL_VIRTPERL_ROOT}/$ENV{PERL_VIRTPERL_CURRENT_ENV}/lib/perl5";
	
	if ($current !~ m:^([\w/.-]+)$:) {  # XXX got to figure this out 100% before release.
		return;
	}
	
	$current = $1;
	
	if (-e $current) {
		@INC = grep {
				   !m/^$Config{sitelibexp}/o
				&& !m/^$Config{vendorlibexp}/o
				&& !m/^$Config{updateslib}/o
				&& !m/^$Config{extraslib}/o
			} @INC;
	
		lib->import($current);
	}
}

sub unimport {
		@INC = @original_inc;
}

1;
__END__