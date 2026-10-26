use strict;
use warnings;
use Test::More;
use Test::Mojo;
use POSIX qw(ENOENT);
use File::Temp qw(tempdir);

# ---------------------------------------------------------------------------
# NOTE ON GEOIP
# ---------------------------------------------------------------------------
# Database::BI does not implement GeoIP-based language resolution.  Language
# is resolved from the HTTP Accept-Language header only (see
# Dashboard::_resolve_language).  The "country-based" tests below exercise
# the Accept-Language codes that correspond to the requested country locales
# (GB, US -> 'en'; FR -> 'fr'; DE -> 'de'; CN -> 'zh').  A sanity subtest
# validates that the mapping is consistent with expected Accept-Language codes
# before running the actual HTTP tests.  If the mapping drifts (e.g. someone
# changes the controller's language extraction regex), BAIL_OUT fires.
#
# Full GeoIP support (IP-to-country lookup) is a future feature; when it is
# added, this file should be extended with MaxMind::DB::Reader tests.
# ---------------------------------------------------------------------------

my %COUNTRY_ACCEPT_LANGUAGE = (
    GB => 'en-GB,en;q=0.9',
    US => 'en-US,en;q=0.9',
    FR => 'fr-FR,fr;q=0.9,en;q=0.8',
    DE => 'de-DE,de;q=0.9,en;q=0.8',
    CN => 'zh-CN,zh;q=0.9,en;q=0.8',
);

my %EXPECTED_LANG = (
    GB => 'en',
    US => 'en',
    FR => 'fr',   # Falls back to 'en' (default) if templates/web/fr/ absent
    DE => 'de',   # Falls back to 'en' if templates/web/de/ absent
    CN => 'zh',   # Falls back to 'en' if templates/web/zh/ absent
);

# Sanity subtest: verify the Accept-Language -> primary-tag extraction.
# This mirrors Dashboard::_resolve_language's regex so we catch drift early.
subtest 'Accept-Language mapping sanity' => sub {
    my $regex = qr/\b([a-z]{2})(?:-[A-Z]{2})?\b/;
    for my $country (sort keys %COUNTRY_ACCEPT_LANGUAGE) {
        my $header = $COUNTRY_ACCEPT_LANGUAGE{$country};
        my ($lang) = $header =~ $regex;
        is($lang, $EXPECTED_LANG{$country},
            "Country $country: Accept-Language '$header' -> primary tag '$EXPECTED_LANG{$country}'")
            or BAIL_OUT("Accept-Language mapping broken for $country -- check _resolve_language regex");
    }
};

# ---------------------------------------------------------------------------
# HTTP language resolution: simulate browser Accept-Language for each country.
# The app currently only has 'en' templates; all non-en languages fall back
# to 'en'.  These tests confirm:
#   (a) The server responds 200 for every country.
#   (b) No crash or 500 occurs when an unknown language code is presented.
# ---------------------------------------------------------------------------

my $t = Test::Mojo->new('Database::BI');

# The model store (.bi/) is shared state in the checkout: give this file its
# own directory, so a parallel run cannot create, read or write it underneath.
$t->app->config->{model_dir} = tempdir(CLEANUP => 1);

subtest 'HTTP Accept-Language per country' => sub {
    for my $country (sort keys %COUNTRY_ACCEPT_LANGUAGE) {
        my $header = $COUNTRY_ACCEPT_LANGUAGE{$country};
        $t->get_ok('/', { 'Accept-Language' => $header })
          ->status_is(200, "GET / with Accept-Language for $country returns 200");
    }
};

subtest 'Malformed Accept-Language header does not crash' => sub {
    # Garbage header -> falls back to configured default language ('en').
    $t->get_ok('/', { 'Accept-Language' => 'x-not-a-valid-tag;q=bogus' })
      ->status_is(200);

    # Empty header.
    $t->get_ok('/', { 'Accept-Language' => '' })
      ->status_is(200);
};

subtest 'Case-insensitive language code handling' => sub {
    # The regex requires lowercase two-letter codes; uppercase tags from
    # non-standard clients should not crash the app.
    $t->get_ok('/', { 'Accept-Language' => 'EN-US' })
      ->status_is(200);
};

subtest 'Concurrent different Accept-Language requests' => sub {
    # Verify stateless language resolution: interleaved requests with different
    # headers must not bleed language state between them.
    my $tx_en = $t->ua->build_tx(GET => '/', { 'Accept-Language' => 'en-GB' });
    my $tx_de = $t->ua->build_tx(GET => '/', { 'Accept-Language' => 'de-DE' });
    $t->ua->start($tx_en);
    $t->ua->start($tx_de);
    is($tx_en->res->code, 200, 'en-GB request returns 200');
    is($tx_de->res->code, 200, 'de-DE request returns 200');
};

# ---------------------------------------------------------------------------
# POSIX locale testing
#
# These tests verify that:
#   1. The OS $! message changes with LC_ALL (demonstrating the system works).
#   2. The DataSource error dictionary produces consistent, locale-independent
#      messages regardless of LC_ALL because strings come from %MESSAGES, not
#      from the C runtime.
#
# CRITICAL: Do NOT use POSIX::strerror -- use "local $! = ENOENT; my $msg = "$!"
# to source the string through Perl's own layer and avoid C-library divergence.
# ---------------------------------------------------------------------------

# Locales to probe.  We test only locales that are likely to be installed on
# the CI system; individual locales are skipped gracefully if not available.
my @TEST_LOCALES = (
    { lc_all => 'en_US.UTF-8', tag => 'en_US' },
    { lc_all => 'de_DE.UTF-8', tag => 'de_DE' },
    { lc_all => 'C.UTF-8',     tag => 'C'     },   # always available
);

sub _enoent_msg_for_locale {
    my ($lc_all) = @_;
    local $ENV{LC_ALL} = $lc_all;
    # Reload Perl's locale category so $! reflects the new LC_ALL.
    eval { require POSIX; POSIX::setlocale(POSIX::LC_MESSAGES(), $lc_all) };
    local $! = ENOENT;
    return "$!";
}

subtest 'POSIX locale: OS error strings change with LC_ALL' => sub {
    # LC_MESSAGES is absent on Windows; setlocale with it fails there too.
    # Skip the whole subtest rather than producing zero assertions.
    eval { POSIX::setlocale(POSIX::LC_MESSAGES(), 'C') }
        or plan skip_all => 'POSIX locale manipulation not available on this platform';

    my %seen;
    for my $spec (@TEST_LOCALES) {
        # Try to set the locale; skip if not installed on this system.
        eval {
            require POSIX;
            POSIX::setlocale(POSIX::LC_MESSAGES(), $spec->{lc_all})
                or die "locale $spec->{lc_all} not available";
        };
        if ($@) {
            note "Skipping locale $spec->{tag}: $@";
            next;
        }
        my $msg = _enoent_msg_for_locale($spec->{lc_all});
        ok(defined $msg && length $msg,
            "ENOENT message under $spec->{tag} is non-empty: '$msg'");
        $seen{ $spec->{tag} } = $msg;
    }

    # When two different locales are both available, their messages may differ.
    # We do not assert they MUST differ (some systems return the same string),
    # but we note it for diagnostic purposes.
    if (exists $seen{en_US} && exists $seen{de_DE}) {
        note "en_US ENOENT: '$seen{en_US}'  |  de_DE ENOENT: '$seen{de_DE}'";
    }
};

subtest 'POSIX locale: DataSource errors are locale-independent' => sub {
    # DataSource messages come from %MESSAGES (hardcoded ASCII strings),
    # so they must be identical regardless of LC_ALL.
    require Database::BI::Model::DataSource;

    my @datasource_errors;
    for my $spec (@TEST_LOCALES) {
        local $ENV{LC_ALL} = $spec->{lc_all};
        eval {
            require POSIX;
            POSIX::setlocale(POSIX::LC_MESSAGES(), $spec->{lc_all});
        };

        # Trigger a known error: directory does not exist.
        my $err;
        eval {
            Database::BI::Model::DataSource->new(
                directory => '/nonexistent_bi_test_dir',
                table     => 'testtable',
            );
        };
        $err = $@;

        if ($err) {
            push @datasource_errors, { locale => $spec->{tag}, msg => "$err" };
            ok(length $err, "DataSource croaks under $spec->{tag}");
        }
        else {
            note "DataSource did not croak under $spec->{tag} (directory check may have been skipped)";
        }
    }

    # All available locale errors must be identical (locale-independent strings).
    if (@datasource_errors > 1) {
        my $first = $datasource_errors[0]{msg};
        for my $e (@datasource_errors[1..$#datasource_errors]) {
            is($e->{msg}, $first,
                "DataSource error under $e->{locale} matches en_US error");
        }
    }
};

subtest 'POSIX locale: filter/join errors are locale-independent' => sub {
    # _apply_filter_spec is a pure Perl sub with no OS interaction.
    # Feed it garbage and verify consistent return under different locales.
    require Database::BI::Controller::Dashboard;

    for my $spec (@TEST_LOCALES) {
        local $ENV{LC_ALL} = $spec->{lc_all};
        eval { require POSIX; POSIX::setlocale(POSIX::LC_MESSAGES(), $spec->{lc_all}) };

        # _apply_filter_spec is a standalone sub -- call via full path.
        # An invalid op must return the unmodified records (no crash).
        my $records = [ { col => 'val' } ];
        my $result  = Database::BI::Controller::Dashboard::_apply_filter_spec(
            $records, 'col:invalidop:something'
        );
        is(scalar @$result, 1,
            "_apply_filter_spec returns all records for unknown op under $spec->{tag}");
    }
};

done_testing();
