#!/usr/bin/env perl
use warnings;
use strict;
use CommitBit::Test;# tests => 9;

plan skip_all => 'the developers suck';

# Make sure we can load the model
use_ok('CommitBit::Model::Repository');

# Grab a system user
my $system_user = CommitBit::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = CommitBit::Model::Repository->new(current_user => $system_user);
my ($id) = $o->create( name => 'test');

my $p = CommitBit::Model::Project->new(current_user => $system_user);
my ($pid) = $p->create( repository => $o, name => 'test', root_path => 'test' );
ok($pid);

my $Class = 'CommitBit::Action::CreateProjectMember';
require_ok $Class;

# Test a successful invite
{
    Jifty->web->response(Jifty::Response->new);
    Jifty->web->request(Jifty::Request->new);

    my $action = $Class->new(
        arguments => {
            user         => 'foo@bar.com',
            project      => $pid,
            access_level         => 'author',
        }
    );

    ok $action->validate;
    use Data::Dumper;
    $action->run;
    my $result = $action->result;
    ok $result->success;
    like $result->message, qr{^Created};
}

is_deeply([map { $_->email } @{$o->associated_users->items_array_ref}],
	  ['foo@bar.com']);

{
    open my $fh, '<', 'repos-test/test/conf/passwd' or die $!;
    local $/; my $data = <$fh>;
    like($data, qr/foo\@bar\.com/);
}
