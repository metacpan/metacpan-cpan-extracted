# $Id: Makefile.PL 52 2007-11-04 16:55:12Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot.googlecode.com/svn/trunk/Makefile.PL $
# $Revision: 52 $
# $Date: 2007-11-04 17:55:12 +0100 (Sun, 04 Nov 2007) $
use strict;
use warnings;
require 5.00600;

use English qw(-no_match_vars);

use inc::Module::Install;

my $THIS_VERSION = '0.0.1';

name                'Acme-Locals';
author              'Ask Solem <asksh@cpan.org>';
version             $THIS_VERSION;
license             'bsd';
all_from            'lib/Acme/Locals.pm';

requires            'version'          => 0;
requires            'PadWalker'        => 0;
requires            'Params::Util'     => 0;

build_requires      'Test::Simple'     => 0.42;
build_requires      'Scalar::Util'     => 1.14;

perl_version        5.006_000;

no_index            directory => 'examples';

no_index            directory => 'devel';

distribution_type   'module';

        


#meta_spec 'homepage'    => 'http://search.cpan.org/dist/Class-Dot';
#meta_spec 'bugtracker'
#    => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Class-Dot';

package ExtUtils::MakeMaker::_version;
    use strict;
    use warnings;
    
    use Carp;
    use English qw(-no_match_vars);

    eval 'use version qw(qv)';

package main;

    auto_install;
    sign();
    WriteAll;


