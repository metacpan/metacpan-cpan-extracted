#!perl -T

use Test::More qw/no_plan/;
use Test::Deep;

use CGI;
use CGI::FormBuilderX::More;

use strict;
use warnings;

my $query = CGI->new({
    a => 1,
    c => [ 1, 2, 3, 4 ],
    "edit.x" => 0,
    "view" => "View"
});

ok(my $form = CGI::FormBuilderX::More->new(params => $query, more => 1));

sub validate {
    my $form = shift;
    my $error = shift;

    ok(tied %_, 'tied %_');
    ok($_{a}, '$_{a}');
    ok(exists $_{a}, 'exists $_{a}');
    ok(!exists $_{b}, 'exists $_{b}');

    $error->("b is missing!") unless exists $_{b};
}

sub _set {
    my $form = shift;
    my $error = shift;

    ok(tied %_, 'tied %_');
    $_{b} = 3;

    $error->("b is missing!") unless exists $_{b};
}

ok(!$form->validate(\&validate), '!$form->validate(\&validate)');
ok($form->errors);
ok(1 == @{ $form->errors });
my $prepare = $form->prepare;
ok($prepare->{errors});
ok(1 == @{ $prepare->{errors} });
ok($form->validate(\&_set), '!$form->validate(\&_set)');

ok($form = CGI::FormBuilderX::More->new(params => $query, validate => \&validate));
ok($form->{_CGI_FBX_M_validate});
ok(!$form->validate(\&validate), '!$form->validate(\&validate)');
