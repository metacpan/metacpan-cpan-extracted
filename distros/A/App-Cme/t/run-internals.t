use strict;
use warnings;

use App::Cme::Command::run;
use Test::More;
use Test::Differences;
use Config::Model;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;

use lib 't/lib';

subtest "parse_script" => sub {
    my $content = <<'EOS';
app:  popcon
---var
$var{change_it} = qq{
s/^(a)a+/ # comment
\$1.\\"$args{fooname}\\" x2
/xe}
---
load: ! MY_HOSTID=~"$change_it"
doc: doc a
doc: doc b
EOS

    my %user_args = (fooname => 'foo');

    my $data = App::Cme::Command::run::parse_script('test', $content, \%user_args);

    is($data->{load}[0], '! MY_HOSTID=~" s/^(a)a+/  $1.\"foo\" x2 /xe"', "test parsed script");
    eq_or_diff($data->{doc}, ['doc a','doc b'], "test doc extraction");
};

subtest "process_script_vars" => sub {
    my $data = {
        app => 'dpkg-copyright',
        doc => [ 'test $foo $bar'],
        load => [ 'load $foo $bar'],
        commit_msg => 'commit $foo $bar',
        default => {},
    };
    $ENV{bar}='BAR';
    App::Cme::Command::run::process_script_vars({ foo=> 'FOO' }, $data);

    is($data->{doc}[0],'test FOO BAR',"doc var replacement" );
    is($data->{load}[0],'load FOO BAR',"load var replacement" );
    is($data->{commit_msg},'commit FOO BAR',"commit msg var replacement" );
};

my ($model, $trace) = init_test();
my $wr_root = setup_test_dir();

subtest "process commit message" => sub {
    my $model = Config::Model->new();
    my $inst = $model->instance(
        root_class_name => "CmeAppTest",
        root_dir        => $wr_root,
        instance_name => "msg_test",
    );
    ok(1, "created instance");

    $inst->load("a_string=bar");
    my $root = $inst->config_root;

    # check that more than one substitution is done
    my $msg = 'commit {{ a_string }} for $foo $foo';

    my $new = App::Cme::Command::run::process_commit_message(undef, $root, { foo=> 'FOO' }, $msg);

    my $expect = 'commit bar for FOO FOO';
    is($new, $expect, "check commit message");
};

done_testing;
