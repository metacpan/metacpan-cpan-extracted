## no critic (Modules::ProhibitExcessMainComplexity)
use strict;
use warnings;

use Cwd qw( abs_path );
use Test::More;

BEGIN {
    plan skip_all =>
        'Must set DATETIME_FORMAT_STRPTIME_TEST_DEPS to true in order to run these tests'
        unless $ENV{DATETIME_FORMAT_STRPTIME_TEST_DEPS};
}

use Test::DependentModules qw( test_all_dependents );

## no critic (Variables::RequireLocalizedPunctuationVars)
$ENV{PERL_TEST_DM_LOG_DIR} = abs_path('.');
## use critic

test_all_dependents(
    'DateTime::Format::Strptime',
    {
        filter => sub {

            return 0 if $_[0] =~ /^Mac-/;
            return 0 if $_[0] eq 'App-dateseq';
            return 0 if $_[0] eq 'App-financeta';

            # Failing deps
            return 0 if $_[0] eq 'App-Twimap';

            # Fails regardless of Strptime
            return 0 if $_[0] eq 'Business-RO-CNP';

            # Fails regardless of Strptime
            return 0 if $_[0] eq 'Catmandu-Fix-Date';

            # Requires Coro
            return 0 if $_[0] eq 'Cikl';

            # Fails regardless of Strptime
            return 0 if $_[0] eq 'Data-Apache-mod_status';

            # Requires a module which doesn't exist on CPAN
            return 0 if $_[0] eq 'DPKG-Log';

            # Fails regardless of Strptime
            return 0 if $_[0] eq 'Finance-TW-TAIFEX';

            # Requires gtk
            return 0 if $_[0] eq 'Gtk2-Ex-DbLinker';

            # Fails regardless of Strptime
            return 0 if $_[0] eq 'HTML-FormatData';

            # Fails regardless of Strptime
            return 0 if $_[0] eq 'HTML-Tested';

            # Fails regardless of Strptime
            return 0 if $_[0] eq 'meon-Web';

            # prompts for keys to use in testing
            return 0 if $_[0] eq 'Net-Amazon-AWIS';

            # Fails regardless of Strptime
            return 0 if $_[0] eq 'Net-DRI';

            # Fails regardless of Strptime
            return 0 if $_[0] eq 'Net-Plurk';

            # Requires Coro
            return 0 if $_[0] eq 'Net-IMAP-Server';

            # Fails regardless of Strptime
            return 0 if $_[0] eq 'OpenERP-OOM';

            # hangs installing prereqs (probably SOAP::Lite)
            return 0 if $_[0] eq 'Plagger';

            # Fails regardless of Strptime
            return 0 if $_[0] eq 'SmokeRunner-Multi';

            # Fails on installing some prereqs
            return 0 if $_[0] eq 'OpenResty';

            # Fails regardless of Strptime
            return 0 if $_[0] eq 'Smolder';

            # Is either hanging or installing all of CPAN
            return 0 if $_[0] eq 'Strehler';

            # Fails regardless of Strptime
            return 0 if $_[0] eq 'Video-PlaybackMachine';

            # Fails regardless of Strptime
            return 0 if $_[0] eq 'WebService-IMDB';

            # Fails regardless of Strptime
            return 0 if $_[0] eq 'W3C-SOAP';

            # Fails regardless of Strptime
            return 0 if $_[0] eq 'WWW-DataWiki';

            # Requires Wx
            return 0 if $_[0] eq 'Wx-Perl-DbLinker';

            # Fails on installing some prereqs
            return 0 if $_[0] eq 'XAS';

            return 1;
        },
    },
);

done_testing();
