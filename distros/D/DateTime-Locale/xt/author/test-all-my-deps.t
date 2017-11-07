use strict;
use warnings;

use Cwd qw( abs_path );
use Test::More;

BEGIN {
    plan skip_all =>
        'Must set DATETIME_LOCALE_TEST_DEPS to true in order to run these tests'
        unless $ENV{DATETIME_LOCALE_TEST_DEPS};
}

use Test::DependentModules qw( test_all_dependents );

## no critic (Variables::RequireLocalizedPunctuationVars)
$ENV{PERL_TEST_DM_LOG_DIR} = abs_path('.');
## use critic

test_all_dependents(
    'DateTime::Locale',
    {
        filter => sub {

            # Fails tests for reasons unrelated to DateTime-Locale
            return 0 if $_[0] eq 'CatalystX-I18N';

            # Seems to hang when running under this harness for some reason
            return 0 if $_[0] eq 'HTML-FormFu';

            # Fails tests for reasons unrelated to DateTime-Locale
            return 0 if $_[0] =~ /Jifty/;

            # Is having issues with installing its Pg schema
            return 0 if $_[0] =~ /Silki/;

            # hangs installing prereqs (probably SOAP::Lite for both)
            return 0 if $_[0] =~ /Plagger/;
            return 0 if $_[0] =~ /WSRF-Lite/;
            return 1;
        },
    },
);

done_testing();
