use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;

use lib 't/lib';
use DBIx::QuickORM::Test;

# A table with two foreign keys to the same table (message.sender_id and
# message.recipient_id both reference users) makes both relationship accessors
# default to the same name, and the reverse side does too. Autofill must croak
# at schema-build time rather than silently dropping one of them. The
# 'autoname link' and 'autoname link_accessor' hooks are the escape hatches.

# Insert a sender, a recipient, and a message, then check the disambiguated
# accessors resolve in both directions.
sub check_both_directions {
    my $con = shift;

    my $alice = $con->insert(users => {name => 'alice'});
    my $bob   = $con->insert(users => {name => 'bob'});
    my $msg   = $con->insert(message => {
        body         => 'hi',
        sender_id    => $alice->field('user_id'),
        recipient_id => $bob->field('user_id'),
    });

    ref_is($msg->sender,    $alice, "forward accessor 'sender' returns the sender");
    ref_is($msg->recipient, $bob,   "forward accessor 'recipient' returns the recipient");

    is([map { $_->field('body') } $alice->sender_messages->all], ['hi'], "reverse accessor 'sender_messages' finds sent messages");
    is([$bob->sender_messages->all], [], "bob is only a recipient, sent nothing");
}

# The non-conflicting relationships (team -> users single FK, node self-ref)
# must keep their default accessor names: the hooks above only rename the
# message<->users links.
sub check_defaults_preserved {
    my $con = shift;

    my $carol = $con->insert(users => {name => 'carol'});
    my $team  = $con->insert(team  => {name => 'red', owner_id => $carol->field('user_id')});
    ref_is($team->users, $carol, "single FK keeps its default 'users' accessor");

    my $root  = $con->insert(node => {name => 'root'});
    my $child = $con->insert(node => {name => 'child', parent_id => $root->field('node_id')});
    ref_is($child->node, $root, "self-ref forward 'node' accessor returns the parent");
    is([map { $_->field('name') } $root->nodes->all], ['child'], "self-ref reverse 'nodes' accessor returns children");
}

do_for_all_dbs {
    my $db = shift;

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    # 1. Default behavior: the collision croaks, naming the accessor, the row
    #    class, both foreign-key columns, and how to resolve it.
    orm collide_default => sub {
        db 'mydb';
        autofill sub { autorow 'Collide::Default'; };
    };

    my $err = dies { orm('collide_default')->connect };
    ok($err, "connecting with an unresolved accessor collision dies");
    like($err, qr/Cannot generate the '(?:users|messages)' accessor on row class/, "names the conflicting accessor and row class");
    like($err, qr/sender_id/,      "diagnostic mentions the sender_id foreign key");
    like($err, qr/recipient_id/,   "diagnostic mentions the recipient_id foreign key");
    like($err, qr/distinct alias/, "diagnostic suggests distinct aliases");
    like($err, qr/autoname link/,  "diagnostic suggests an autoname hook");

    # 2. Resolve via 'autoname link_accessor': name each accessor distinctly.
    orm by_accessor => sub {
        db 'mydb';
        autofill sub {
            autorow 'Collide::ByAccessor';
            autoname link_accessor => sub {
                my %p    = @_;
                my $link = $p{link};
                my $local = join(',', @{$link->local_columns});
                my $other = join(',', @{$link->other_columns});

                if ($link->other_table eq 'users' && $local =~ m/^(?:sender|recipient)_id$/) {
                    (my $name = $local) =~ s/_id$//;
                    return $name;
                }
                if ($link->other_table eq 'message' && $other =~ m/^(?:sender|recipient)_id$/) {
                    (my $name = $other) =~ s/_id$//;
                    return "${name}_messages";
                }
                return;    # default name for every other link
            };
        };
    };

    ok(my $con = orm('by_accessor')->connect, "connected once collisions are resolved by accessor name");
    check_both_directions($con);
    check_defaults_preserved($con);

    # 3. Resolve via 'autoname link': set distinct aliases (the default accessor
    #    then uses the alias). Same outcome, different hook.
    orm by_alias => sub {
        db 'mydb';
        autofill sub {
            autorow 'Collide::ByAlias';
            autoname link => sub {
                my %p = @_;
                my @cols = (@{$p{in_fields}}, @{$p{fetch_fields}});
                my ($fk) = grep { m/^(?:sender|recipient)_id$/ } @cols;
                return unless $fk;    # default for non message<->users links

                (my $base = $fk) =~ s/_id$//;
                return (grep { $_ eq $fk } @{$p{in_fields}}) ? $base : "${base}_messages";
            };
        };
    };

    ok(my $con2 = orm('by_alias')->connect, "connected once collisions are resolved by alias");
    check_both_directions($con2);
};

done_testing;
