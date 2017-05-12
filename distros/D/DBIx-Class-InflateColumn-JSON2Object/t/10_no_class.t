#!/usr/bin/perl
use Test::More;
use lib 't';
use utf8;
use Encode;
binmode( STDERR, ":utf8" );
binmode( STDOUT, ":utf8" );
use testlib::TestDB qw($dbh $schema);

my $id;

subtest 'insert hashref' => sub {
    my $data = {
        foo=>'bär',
        universe=>42,
        bool=>\1,
    };
    my $row = $schema->resultset('Test')->create({no_class=>$data});
    $id = $row->id;

    my ($via_dbi) = $dbh->selectrow_array("select no_class from test where id = ?",undef, $id);

    like($via_dbi,qr/"foo":"bär"/,'raw json string');
    like($via_dbi,qr/"universe":42/,'raw json int');
    like($via_dbi,qr/"bool":true/,'raw json bool');
};

subtest 'fetch JSON as hashref' => sub {
    my $row = $schema->resultset('Test')->find($id);
    is($row->no_class->{foo},'bär','hashref string');
    is($row->no_class->{universe},42,'hashref int');
    is($row->no_class->{bool},1,'hashref bool');
};

subtest 'fetch and update' => sub {
    my $row = $schema->resultset('Test')->find($id);
    my $data = $row->no_class;
    $data->{foo} = 'baz';
    $data->{more} = [qw(values and stuff)];
    $row->update({no_class=>$data});

    my $fresh = $schema->resultset('Test')->find($id);
    is($fresh->no_class->{foo},'baz','new string');
    is($fresh->no_class->{more}[2],'stuff','added arrayref');
};

done_testing();
