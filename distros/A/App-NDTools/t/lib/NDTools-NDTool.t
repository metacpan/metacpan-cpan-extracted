use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Test::File::Contents;
use Test::More tests => 10;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

use_ok('App::NDTools::NDTool');

my ($tool, $got, $exp, $tmp);
my $shared = '../../_data';

$tool = new_ok('App::NDTools::NDTool') || die "Failed to init module";

can_ok($tool, qw(VERSION arg_opts configure defaults dump_opts usage));

$tmp = eval { $tool->load_struct('file-does-not-exists') };
like($@, qr/^Failed to open file/, "Must fail when file doesn't exists");

$tmp = $tool->load_struct("$shared/menu.a.json");

($got) = $tool->grep([[[],{R => [qr/^.i/]},[],{K => ['id']}]], $tmp);
$exp = [
    {
        File => [
            {id => 'file_new'},
            {id => 'file_open'},
            {id => 'file_save'}
        ]
    },
    {
        View => [
            {id => 'view_encoding'},
            {id => 'view_wrapping'}
        ]
    }
];
is_deeply($got, $exp, "Grep match") || diag t_ab_cmp($got, $exp);

$got = $tool->grep([$tmp], [[],{R => [qr/^NotExists/]},[],{K => ['id']}]);
is_deeply($got, 0, "Grep doesn't match") || diag t_ab_cmp($got, $exp);

my ($out, $err);
($out, $err) = capture { $tool->dump_opts() };
file_contents_eq_or_diff('dump-opts.exp', $out, "Check dump-opts method output (STDOUT)");
is($err, '', "STDERR for dump-opts method must be empty");

($out, $err) = capture { $tool->usage() };
is($out, '', "STDOUT for usage method must be empty");
file_contents_eq_or_diff('usage.exp', $err, "Check usage method output (STDERR)");

__END__

=head1 SYNOPSIS

    use parent 'App::NDTools::NDTool';
    ...

=head1 EXAMPLES

    look above
