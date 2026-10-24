#!/usr/bin/env perl
use 5.034;

use strict;
use warnings FATAL => 'all';
use re '/aa';

=head1 NAME

t/Configd-Language-postfix.t - reading main.cf and master.cf, and what happens
when two fragments have something to say about the same parameter

=cut

use Test::More;
use Test::Fatal qw{exception};

use FindBin::libs;

use Configd::Language::postfix();    ## no critic (ProhibitUnusedImports)

my $postfix = 'Configd::Language::postfix'->new();

sub value_of {
    my ( $directives, $key ) = @_;
    my ($found) = grep { defined $_->{key} && $_->{key} eq $key } @$directives;
    return $found ? $found->{value} : undef;
}

subtest 'main.cf is parameters, comments and continuations' => sub {
    my $parsed = $postfix->parse(<<'CF');
# A comment

myhostname = mail.example.com
mydestination = example.com, localhost
smtpd_recipient_restrictions =
    permit_mynetworks
    reject_unauth_destination
CF

    is( value_of( $parsed, 'myhostname' ), 'mail.example.com', 'a parameter' );

    # Postfix continues a value onto any following line that starts with
    # whitespace.  Treating those as parameters of their own would lose them.
    is(
        value_of( $parsed, 'smtpd_recipient_restrictions' ),
        'permit_mynetworks reject_unauth_destination',
        'a value continued over two lines is one value'
    );

    my @comments = grep { !defined $_->{key} } @$parsed;
    ok( scalar @comments, 'comments and blank lines survive parsing' );
};

subtest 'a parameter said twice is the later one' => sub {
    my $merged = $postfix->merge(
        $postfix->parse("myhostname = first.example.com\n"),
        $postfix->parse("myhostname = second.example.com\n"),
    );

    is( value_of( $merged, 'myhostname' ), 'second.example.com', 'the later fragment wins' );
};

subtest 'two domains on one mail server both stay local' => sub {

    # The case the whole distribution exists for.  postconf -e sets
    # mydestination, so provisioning the second domain onto a server that
    # already hosts the first replaces it -- and mail for the first domain
    # quietly stops being delivered locally.
    my $merged = $postfix->merge(
        $postfix->parse("mydestination = \$myhostname, localhost\n"),
        $postfix->parse("mydestination = first.example.com\nvirtual_mailbox_domains = first.example.com\n"),
        $postfix->parse("mydestination = second.example.com\nvirtual_mailbox_domains = second.example.com\n"),
    );

    my $destination = value_of( $merged, 'mydestination' );
    like( $destination, qr/\Qfirst.example.com\E/,  'the first domain is still there' );
    like( $destination, qr/\Qsecond.example.com\E/, 'and so is the second' );
    like( $destination, qr/\$myhostname/,           'and what was in main.cf to begin with' );

    is(
        value_of( $merged, 'virtual_mailbox_domains' ),
        'first.example.com, second.example.com',
        'the same for the other lists, joined the way postfix reads them'
    );
};

subtest 'a value that already ends in a separator does not get two' => sub {

    # postfix's own main.cf writes mydestination over several lines and the last
    # one keeps its trailing comma.  Joining onto that gives ",," -- which
    # postfix reads without complaint, so nothing would ever tell you.
    my $merged = $postfix->merge(
        $postfix->parse("mydestination = \$myhostname, localhost, www.example.com,\n"),
        $postfix->parse("mydestination = second.example.com\n"),
    );

    my $destination = value_of( $merged, 'mydestination' );
    unlike( $destination, qr/,\s*,/, 'no doubled separator' );
    is(
        $destination,
        '$myhostname, localhost, www.example.com, second.example.com',
        'just the one between each pair'
    );
};

subtest 'restriction lists are not joined, on purpose' => sub {

    # They are lists, but ordered ones where the order is the meaning.  Joining
    # two end to end gives something that parses and that neither fragment
    # asked for -- a permit_ ahead of a check that was meant to run first is an
    # open relay.
    ok( !$postfix->accumulates('smtpd_recipient_restrictions'), 'not accumulated' );
    ok( $postfix->accumulates('mydestination'),                 'unlike the lists that are just sets' );

    my $merged = $postfix->merge(
        $postfix->parse("smtpd_recipient_restrictions = reject_unauth_destination\n"),
        $postfix->parse("smtpd_recipient_restrictions = permit_mynetworks\n"),
    );

    is(
        value_of( $merged, 'smtpd_recipient_restrictions' ),
        'permit_mynetworks',
        'the later fragment replaces rather than appending'
    );
};

subtest 'what goes in comes back out' => sub {
    my $original = <<'CF';
# Managed by nobody in particular

myhostname = mail.example.com
mydestination = example.com, localhost
CF

    my $round_tripped = $postfix->emit( $postfix->parse($original) );
    is( $round_tripped, $original, 'main.cf survives a parse and an emit unchanged' );
};

subtest 'master.cf is a table, keyed by service and type together' => sub {
    my $parsed = $postfix->parse(<<'CF');
# service type  private unpriv  chroot  wakeup  maxproc command
smtp      inet  n       -       y       -       -       smtpd
smtp      unix  -       -       y       -       -       smtp
submission inet n       -       y       -       -       smtpd
  -o syslog_name=postfix/submission
CF

    my %keys = map { $_->{key} => $_ } grep { defined $_->{key} } @$parsed;

    # smtp has both an inet entry and a unix one and they are different
    # services; keying on the name alone would merge them into one.
    ok( $keys{'smtp/inet'}, 'smtp inet is one service' );
    ok( $keys{'smtp/unix'}, 'and smtp unix is another' );

    is_deeply(
        $keys{'submission/inet'}{continuation},
        ['  -o syslog_name=postfix/submission'],
        'the -o overrides stay with the service they belong to'
    );
};

subtest 'a service configured twice is the later one' => sub {
    my $merged = $postfix->merge(
        $postfix->parse("smtp      inet  n       -       y       -       -       smtpd\n"),
        $postfix->parse("smtp      inet  n       -       y       -       1       smtpd\n"),
    );

    my ($smtp) = grep { defined $_->{key} && $_->{key} eq 'smtp/inet' } @$merged;
    is( $smtp->{columns}[6],                           '1', 'the later entry replaces the earlier one' );
    is( scalar( grep { defined $_->{key} } @$merged ), 1,   'rather than both being written' );
};

subtest 'which file a fragment is gets worked out from the fragment' => sub {

    # A filename would do it, except that fragments get named for the domain
    # that dropped them in rather than for the file they add to.
    ok( !$postfix->_is_master("mydestination = example.com\n"), 'a parameter is main.cf' );
    ok( $postfix->_is_master("smtp inet n - y - - smtpd\n"),    'a service row is master.cf' );
    ok( !$postfix->_is_master("# just a comment\n"),            'and nothing at all is main.cf' );
};

subtest 'a line that is neither is refused rather than dropped' => sub {

    # Silently skipping it would generate a main.cf missing a setting somebody
    # wrote, and they would have no way of telling.
    like(
        exception { $postfix->parse("this is not a setting\n") },
        qr/Cannot parse postfix main\.cf line/,
        'main.cf'
    );

    like(
        exception { $postfix->parse("smtp inet n - y\n") },
        qr/wanted 8 columns, got 5/,
        'and a short master.cf row says how short'
    );
};

subtest 'the map parameters two domains each name a table for' => sub {

    # smtpd_sender_login_maps most of all: reject_authenticated_sender_login_mismatch
    # reads it, so a host where it does not accumulate names one domain's table
    # and refuses every other domain's users when they try to send.
    foreach my $key (
        qw{
        virtual_mailbox_maps virtual_alias_maps transport_maps
        sender_dependent_relayhost_maps smtpd_sender_login_maps
        smtp_sasl_password_maps smtp_tls_policy_maps
        }
    ) {
        ok( $postfix->accumulates($key), "$key accumulates" );

        my $merged = $postfix->merge(
            $postfix->parse("$key = hash:/etc/postfix/domains/first.example.com/t\n"),
            $postfix->parse("$key = hash:/etc/postfix/domains/second.example.com/t\n"),
        );
        is(
            value_of( $merged, $key ),
            'hash:/etc/postfix/domains/first.example.com/t, hash:/etc/postfix/domains/second.example.com/t',
            "and two domains' tables both survive $key"
        );
    }

    # The restriction lists still must not, whatever else does.
    ok( !$postfix->accumulates('smtpd_recipient_restrictions'), 'a restriction list still does not' );
};

subtest 'an item that the list already holds is not added again' => sub {

    # A fragment that repeats what the package said, such as inet_interfaces =
    # all, means the same thing, and joining the two strings gives "all, all",
    # which postfix refuses to start with.
    my $merged = $postfix->merge(
        $postfix->parse("mydestination = \$myhostname, mail.example.com, , localhost\n"),
        $postfix->parse("mydestination = \$myhostname, localhost, second.example.com\n"),
    );
    is(
        value_of( $merged, 'mydestination' ),
        '$myhostname, mail.example.com, localhost, second.example.com',
        'each item once, in the order it was first named'
    );

    $merged = $postfix->merge(
        $postfix->parse("virtual_alias_maps = hash:/etc/postfix/a\n"),
        $postfix->parse("virtual_alias_maps = hash:/etc/postfix/b hash:/etc/postfix/a\n"),
    );
    is( value_of( $merged, 'virtual_alias_maps' ), 'hash:/etc/postfix/a, hash:/etc/postfix/b', 'whitespace separates items as a comma does' );

    $merged = $postfix->merge(
        $postfix->parse("smtpd_milters = inline:{ a=b, c=d }\n"),
        $postfix->parse("smtpd_milters = inline:{ a=b, c=d }, local:opendkim.sock\n"),
    );
    is( value_of( $merged, 'smtpd_milters' ), 'inline:{ a=b, c=d }, local:opendkim.sock', 'a separator inside braces does not split, because postfix reads them as one item' );
};

subtest 'inet_interfaces is all when any fragment says all' => sub {

    # postfix refuses all beside an address, and all listens on every address
    # anyway.
    my %cases = (
        'all and all'            => [ 'all',       'all',       'all' ],
        'all and an address'     => [ 'all',       '127.0.0.1', 'all' ],
        'an address and all'     => [ '127.0.0.1', 'all',       'all' ],
        'two addresses and none' => [ '127.0.0.1', '[::1]',     '127.0.0.1, [::1]' ],
    );
    foreach my $case ( sort keys %cases ) {
        my ( $first, $second, $want ) = @{ $cases{$case} };
        my $merged = $postfix->merge( $postfix->parse("inet_interfaces = $first\n"), $postfix->parse("inet_interfaces = $second\n") );
        is( value_of( $merged, 'inet_interfaces' ), $want, $case );
    }

    my $merged = $postfix->merge( $postfix->parse("mydestination = all\n"), $postfix->parse("mydestination = localhost\n") );
    is( value_of( $merged, 'mydestination' ), 'all, localhost', 'and all means nothing special in another list' );
};

subtest 'an empty accumulating value resets what came before it' => sub {

    # The case: a guest whose hostname is the domain it hosts.  The package's
    # own main.cf then names that domain in mydestination, it has to be a
    # virtual mailbox domain instead, and postfix will not have it in both --
    # so a fragment has to be able to take something out, not only add.
    my $merged = $postfix->merge(
        $postfix->parse("mydestination = \$myhostname, mail.example.com, localhost.example.com, localhost\n"),
        $postfix->parse("mydestination =\nmydestination = \$myhostname, localhost\n"),
    );
    is(
        value_of( $merged, 'mydestination' ), '$myhostname, localhost',
        'the reset drops it and what follows starts from nothing'
    );

    # And a later fragment still adds to what the reset left, so a reset is not
    # a way of claiming the parameter for good.
    $merged = $postfix->merge(
        $postfix->parse("mydestination = old.example.com\n"),
        $postfix->parse("mydestination =\nmydestination = localhost\n"),
        $postfix->parse("mydestination = extra.example.com\n"),
    );
    is(
        value_of( $merged, 'mydestination' ), 'localhost, extra.example.com',
        'a fragment after the reset accumulates onto it'
    );

    # Only where the parameter accumulates: everywhere else an empty value is a
    # value, and setting something to nothing is a thing people mean.
    $merged = $postfix->merge(
        $postfix->parse("relayhost = [smtp.example.com]\n"),
        $postfix->parse("relayhost =\n"),
    );
    is( value_of( $merged, 'relayhost' ), '', 'an ordinary parameter set to empty is just empty' );
};

done_testing();
