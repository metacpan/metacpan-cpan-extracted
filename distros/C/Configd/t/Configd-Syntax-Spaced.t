#!/usr/bin/env perl
use 5.034;

use strict;
use warnings FATAL => 'all';
use re '/aa';

=head1 NAME

t/Configd-Syntax-Spaced.t - the three languages that are "directive, whitespace,
value", and which of their directives mean every occurrence

=cut

use Test::More;

use FindBin::libs;

use Configd::Language::opendkim();     ## no critic (ProhibitUnusedImports)
use Configd::Language::opendmarc();    ## no critic (ProhibitUnusedImports)
use Configd::Language::redis();        ## no critic (ProhibitUnusedImports)
use Configd::Language::postfix();      ## no critic (ProhibitUnusedImports)
use Configd::Unit();

sub value_of {
    my ( $directives, $key ) = @_;
    my ($found) = grep { defined $_->{key} && $_->{key} eq $key } @$directives;
    return $found ? $found->{value} : undef;
}

sub lines_for {
    my ( $language, $directives, $key ) = @_;
    return grep { m/\A\Q$key\E\s/ } split( qq{\n}, $language->emit($directives) );
}

subtest 'a directive, some whitespace, and the rest of the line' => sub {

    # opendkim's own file uses tabs as often as spaces, and its values are
    # unquoted -- some one word, some a list.
    my $parsed = 'Configd::Language::opendkim'->new()->parse(<<"CONF");
# a comment

Syslog\t\t\tyes
Canonicalization        relaxed/simple
InternalHosts           127.0.0.1, 192.168.1.0/24
CONF

    is( value_of( $parsed, 'Syslog' ),           'yes',                       'a tab separates as well as a space' );
    is( value_of( $parsed, 'Canonicalization' ), 'relaxed/simple',            'a one word value' );
    is( value_of( $parsed, 'InternalHosts' ),    '127.0.0.1, 192.168.1.0/24', 'and one that runs to the end of the line' );

    ok( scalar( grep { !defined $_->{key} } @$parsed ), 'comments and blanks come back as themselves' );
};

subtest 'a bare directive means itself' => sub {

    # redis has flags with no argument.  Reading one as a directive with no
    # value is right; dropping it is not.
    my $redis  = 'Configd::Language::redis'->new();
    my $parsed = $redis->parse("daemonize\n");
    is( value_of( $parsed, 'daemonize' ), q{},           'parsed as a directive with an empty value' );
    is( $redis->emit($parsed),            "daemonize\n", 'and written back without a trailing space' );
};

subtest 'opendkim and opendmarc are values, last one wins' => sub {
    foreach my $name (qw{opendkim opendmarc}) {
        my $language = "Configd::Language::$name"->new();

        my $merged = $language->merge(
            $language->parse("UMask 007\n"),
            $language->parse("UMask 000\n"),
        );
        is( value_of( $merged, 'UMask' ), '000', "$name: the later fragment wins" );

        # A value is not a list somebody adds to, so it is not quietly joined.
        ok( !$language->accumulates('UMask'), "$name: a value does not accumulate" );
        ok( !$language->repeats('UMask'),     "$name: nor repeat" );
    }

    # Both files hold a signing key's location and are 0600 because of it.
    foreach my $name (qw{opendkim opendmarc}) {
        my ($file) = "Configd::Language::$name"->files();
        is( $file->{mode}, 0o600, "$name: a file created from nothing is 0600" );
    }
};

subtest 'opendmarc trusts every authserv-id that a fragment names' => sub {

    # Each mail domain on a host names its own trusted ids, and one opendmarc
    # serves them all.  Last one wins would trust only the last domain's.
    my $opendmarc = 'Configd::Language::opendmarc'->new();
    my $merged    = $opendmarc->merge(
        $opendmarc->parse("TrustedAuthservIDs mail.a.test.test, edge.a.test.test\n"),
        $opendmarc->parse("TrustedAuthservIDs mail.b.test.test,edge.a.test.test\n"),
    );

    is(
        value_of( $merged, 'TrustedAuthservIDs' ),
        'mail.a.test.test, edge.a.test.test, mail.b.test.test',
        'every id once, in the order first named'
    );
    is( scalar( lines_for( $opendmarc, $merged, 'TrustedAuthservIDs' ) ), 1, 'on the one line opendmarc reads' );

    # opendmarc writes its own verdicts under one name.
    ok( !$opendmarc->accumulates('AuthservID'), 'AuthservID stays one value' );
};

subtest 'redis says some things more than once and means each of them' => sub {
    my $redis = 'Configd::Language::redis'->new();

    ok( $redis->repeats('save'),       'save repeats' );
    ok( !$redis->repeats('maxmemory'), 'maxmemory does not' );

    my $merged = $redis->merge(
        $redis->parse("save 900 1\nsave 300 10\nmaxmemory 1gb\n"),
        $redis->parse("save 60 10000\nmaxmemory 2gb\n"),
    );

    is( scalar( lines_for( $redis, $merged, 'save' ) ), 3,     'all three snapshot points survive' );
    is( value_of( $merged, 'maxmemory' ),               '2gb', 'and maxmemory is still one value, the later one' );
};

subtest 'the same repeated line twice is one line' => sub {

    # What makes a fragment safe to write without checking whether somebody else
    # already asked for the same thing.
    my $redis  = 'Configd::Language::redis'->new();
    my $merged = $redis->merge(
        $redis->parse("save 900 1\n"),
        $redis->parse("save 900 1\n"),
    );

    is( scalar( lines_for( $redis, $merged, 'save' ) ), 1, 'collapsed rather than said twice' );
};

subtest 'each of them names the unit its drop-in goes on' => sub {

    # The drop-in is what makes the generated file true, so a language naming
    # the wrong unit adopts the file and wraps nothing.
    my %unit_for = (
        opendkim  => 'opendkim.service',
        opendmarc => 'opendmarc.service',
        redis     => 'redis-server.service',
    );

    foreach my $name ( sort keys %unit_for ) {
        my $language = "Configd::Language::$name"->new();

        is_deeply( [ $language->units() ], [ $unit_for{$name} ], "$name: the unit it wraps" );

        # The same one, because none of these is a template that systemctl would
        # refuse to restart.
        is_deeply( [ $language->services() ], [ $unit_for{$name} ], "$name: and the one it restarts" );

        is(
            Configd::Unit->new( language => $language )->dropin_dir( $unit_for{$name} ),
            "/etc/systemd/system/$unit_for{$name}.d",
            "$name: which is where the drop-in goes"
        );
    }
};

{

    package Test::Language::NoReload;
    our @ISA = ('Configd::Language::postfix');
    sub reloads { return 0 }
}

subtest 'a drop-in does not add a reload the daemon cannot do' => sub {

    # Adding ExecReload to a unit whose daemon has no reload makes
    # `systemctl reload` start reporting success while the daemon carries on
    # with the configuration it started with.  postfix can reload; anything that
    # cannot says so and gets ExecStartPre alone.
    my $postfix = 'Configd::Language::postfix'->new();
    ok( $postfix->reloads(), 'postfix reloads' );
    like( Configd::Unit->new( language => $postfix )->render(), qr/^ExecReload=\+/m, 'so it keeps its ExecReload' );

    my $mute = bless {%$postfix}, 'Test::Language::NoReload';
    is( $mute->reloads(), 0, 'one that says it cannot' );
    unlike( Configd::Unit->new( language => $mute )->render(), qr/^ExecReload=/m, 'gets ExecStartPre alone' );
};

done_testing();
