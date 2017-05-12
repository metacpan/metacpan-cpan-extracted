#!perl
use strict;
use warnings;
use FindBin::libs;

ThisTest->runtests;

package ThisTest;
use base qw/Test::Class/;
use Test::More;

use DBIx::MoCo::Fixture;

sub startup : Test(startup => 1) {
    my $self = shift;
    $self->{fixture} = fixtures(qw/user entry/, { yaml_dir => 't/fixtures' });
    ok $self->{fixture};
}

sub test_user : Tests {
    my $self = shift;
    is Blog::User->retrieve(1)->user_id, $self->{fixture}->{user}->{first}->user_id;
    is Blog::User->retrieve(2)->user_id, $self->{fixture}->{user}->{second}->user_id;
    is Blog::User->count, 2;
}

sub test_entry : Tests {
    my $self = shift;
    is Blog::Entry->count, 1;
    is Blog::Entry->retrieve(1)->title, $self->{fixture}->{entry}->{first}->title;
}
