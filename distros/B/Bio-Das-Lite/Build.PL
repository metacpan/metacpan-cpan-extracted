#########
# Author:        rmp
# Last Modified: $Date: 2010-11-02 09:54:35 +0000 (Tue, 02 Nov 2010) $
# Id:            $Id: Build.PL 47 2010-11-02 09:54:35Z andyjenkinson $
# Source:        $Source$
# $HeadURL: https://bio-das-lite.svn.sourceforge.net/svnroot/bio-das-lite/trunk/Build.PL $
#
use strict;
use warnings;
use Module::Build;
use lib qw(lib);

my $builder = Module::Build->new(
				 module_name         => 'Bio::Das::Lite',
				 dist_author         => 'Roger Pettett <rmp@psyphi.net>',
				 dist_abstract       => q[Bio::Das::Lite is an implementation of the BioDas protocol, http://biodas.org/],
				 license             => 'perl',
				 requires            => {
							 'WWW::Curl'         => '4.07',
							 'HTTP::Response'    => '1.49',
							 'English'           => '1.01',
							 'Carp'              => '1.02',
							 'Readonly'          => '1.03',
							},
				 recommends          => {
							},
				 build_requires      => {
							 'Test::More'              => '0.8',
							},
				 build_recommends    => {
							 'Test::Distribution'      => '2.00',
							 'Test::Perl::Critic'      => '1.01',
							},
				 sign                => 1,
				);

$builder->create_build_script();

print q(
******************************************************************************
** Some of the tests for this module need internet access                   **
** Also remember to set your http_proxy environment variable if you need to **
******************************************************************************
);
