#!/usr/bin/env perl
############################################################
#
#   $Id: Build.PL 1076 2007-12-14 17:40:38Z nicolaw $
#   DistBuild.PL - CPAN Distribution Build Script for Subversion & CVS
#
#   Copyright 2006 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################
# vim:ts=4:sw=4:tw=78

use strict;
use Module::Build;
use vars qw($build);

eval {require Apache::TestMB; };
die qq{Apache::TestMB is requested for testing} if $@;

my $module = 'Apache2::AutoIndex::XSLT';
#$build = Module::Build->new(
$build = Apache::TestMB->new(
		module_name        => $module,
		license            => 'open_source',
		create_makefile_pl => 'passthrough',
		create_readme      => 1,
		create_packlist    => 1,
		sign               => 0,

		requires => {
			'File::Spec'           => 0,
			'Fcntl'                => 0,
			'XML::Quote'           => 0,
			'URI::Escape'          => 0,
			'Apache2::ServerRec'   => 0,
			'Apache2::RequestRec'  => 0,
			'Apache2::RequestUtil' => 0,
			'Apache2::Const'       => 0,
			'Apache2::Log'         => 0,
			'Apache2::Module'      => 0,
			'Apache2::CmdParms'    => 0,
			'Apache2::ServerUtil'  => 0,
			'Apache2::Util'        => 0,
			'Apache2::URI'         => 0,
			'Apache2::Access'      => 0,
		},

		build_requires => {
			'Test'                 => 0,
			'Test::More'           => 0,
			'Test::Pod'            => 0,
			'Test::Pod::Coverage'  => 0,
			'XML::Validate'        => 0,
			'Apache::Test'         => 0,
			'Apache::TestUtil'     => 0,
			'Apache::TestRequest'  => 0,
		},
	);

$build->create_build_script;


# Send perl and module version information home if we've been given
# permission to do so by a human being - default to not send for automated
# testing environments, of if the user does not respond within 20 seconds.

my $url = $ENV{AUTOMATED_TESTING} ? undef : may_send_version_information();
if ($url) {
	my @resp = ();
	eval {
		local $SIG{ALRM} = sub { die; };
		alarm 10;
		my $ua = LWP::UserAgent->new(
				agent => 'Build.PL $Revision: 815 $',
				timeout => 9,
				max_size => 500,
			);
		$ua->env_proxy;
		my $response = $ua->get($url);
		if ($response->is_success()) {
			for (split(/\s*\n+\s*/, $response->content())) {
				push @resp, $_ if $_;
			}
		}
		alarm 0;
	};
	print substr($resp[0],0,79) || "Thank you for sending this information.";
	print "\n\n";
}

sub may_send_version_information {
	eval {
		require Config;
		require LWP::UserAgent;
	};
	return undef if $@;

	my $str = sprintf('%s?%s=%s&%s=%s&%s=%s&%s=%s&%s=%s&%s=%s',
			'http://perlgirl.org.uk/lib/usage.cgi',
			'name',     $module,
			'version',  $build->dist_version(),
			'osname',   $Config::Config{osname},
			'archname', $Config::Config{archname},
			'osver',    $^O,
			'perlver',  $]
		);

	print "\nThank you for downloading ".$build->dist_name()."\n\n";
	print "I would like to find out how many people are using this software,\n";
	print "and on what operating systems and Perl versions. If you have an\n";
	print "internet connection, may I transmit the following information:\n\n";
	print "$str\n\n";

	my $send = 0;
	eval {
		local $SIG{ALRM} = sub { die; };
		alarm 20;
		$send = $build->y_n('Send this anonymous information?','n');
		alarm 0;
	};

	return defined $send && !ref($send) && "$send" eq "1" ? $str : undef;
}

1;

