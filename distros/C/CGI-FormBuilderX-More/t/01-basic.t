#!perl -T

use Test::More qw/no_plan/;
use Test::Deep;

use CGI;
use CGI::FormBuilderX::More;

my $query = CGI->new({
    a => 1,
    c => [ 1, 2, 3, 4 ],
    d => "apple",
    e => "banana",
    "edit.x" => 0,
    "view" => "View"
});


ok(my $form = CGI::FormBuilderX::More->new(params => $query));

ok($form->missing(qw/b/));
ok(!$form->missing(qw/c/));

ok($form->pressed(qw/+edit/));
ok($form->pressed(qw/+view/));
ok(!$form->pressed(qw/+delete/));

is($form->input(qw/c/), 1);
cmp_deeply([ $form->input(qw/a c/) ], [ 1, 1 ]);
cmp_deeply([ $form->input({ all => 1 }, qw/a c/) ], [ 1, [ 1, 2, 3, 4 ] ]);

cmp_deeply(scalar $form->input_slice(qw/a d/), { qw/a 1 d apple/ });

my %slice = qw/f grape/;
ok(my $slice = $form->input_slice_to(\%slice, qw/a d/));
cmp_deeply(\%slice, { %$slice, qw/f grape/ });
cmp_deeply(\%slice, { qw/a 1 d apple f grape/ });


is($form->input_param(qw/c/), 1);
cmp_deeply([ $form->input_param(qw/a/) ], [ 1 ]);
cmp_deeply([ $form->input_param(qw/c/) ], [ 1, 2, 3, 4 ]);
cmp_deeply([ scalar $form->input_param(qw/c/) ], [ 1 ]);

is($form->input_fetch(qw/c/), 1);
cmp_deeply([ $form->input_fetch(qw/a/) ], [ 1 ]);
cmp_deeply([ $form->input_fetch(qw/c/) ], [ 1, 2, 3, 4 ]);
cmp_deeply([ scalar $form->input_fetch(qw/c/) ], [ 1 ]);

$form->input_store(c => [ 1, 2 ]);
cmp_deeply([ $form->input_fetch(qw/c/) ], [ 1, 2 ]);
cmp_deeply([ $form->input_param(qw/c/) ], [ 1, 2, 3, 4 ]);
$form->input_store(a => 9);
is($form->input_fetch(qw/a/), 9);
is($form->input_param(qw/a/), 1);

cmp_deeply([ $form->errors ], []);

my $prepare;
cmp_deeply($prepare = { $form->prepare }, superhashof({ errors => [] }));
cmp_deeply(scalar $form->prepare, $prepare);
