#
#===============================================================================
#
#         FILE:  00-parts.t
#
#  DESCRIPTION:  Some parts testing
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Andrey Kostenko (), <andrey@kostenko.name>
#      COMPANY:  Rambler Internet Holding
#      VERSION:  1.0
#      CREATED:  03.12.2009 01:24:16 MSK
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 9;

BEGIN {
    use_ok "App::Pm2Port";
}
my $a = App::Pm2Port->new;
is $a->perl_version_parse("5.008008"), "5.8.8";
is $a->perl_version_parse("5.010000"), "5.10.0";
is $a->perl_version_parse("5.010"),    "5.10";
is $a->perl_version_parse("5.10.1"),   "5.10.1";
is $a->perl_version_parse("5.8.1"),    "5.8.1";
is $a->suggest_category('DBIx-Class'), 'databases';
is $a->suggest_category('DBD-Pg'),     'databases';
is_deeply [
    $a->_get_dlist(
        '%%SITE_PERL%%/%%PERL_ARCH%%/auto/Catalyst/Plugin/Static/Simple/.packlist',
        '%%SITE_PERL%%/%%PERL_ARCH%%/auto'
    )
  ],
  [
    '@dirrmtry %%SITE_PERL%%/%%PERL_ARCH%%/auto/Catalyst/Plugin/Static/Simple
',
    '@dirrmtry %%SITE_PERL%%/%%PERL_ARCH%%/auto/Catalyst/Plugin/Static
',
    '@dirrmtry %%SITE_PERL%%/%%PERL_ARCH%%/auto/Catalyst/Plugin
',
    '@dirrmtry %%SITE_PERL%%/%%PERL_ARCH%%/auto/Catalyst
',
  ];
