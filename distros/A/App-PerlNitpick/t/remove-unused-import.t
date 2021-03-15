#!perl
use Test2::V0;

use App::PerlNitpick::Rule::RemoveUnusedImport;

subtest 'Remove only the imported subroutine' => sub {

    my $code = <<CODE;
use Foobar qw(Foo Baz);
print Foo(42);
CODE

    my $doc = PPI::Document->new(\$code);
    my $o = App::PerlNitpick::Rule::RemoveUnusedImport->new( document => $doc );
    my $doc2 = $o->rewrite($doc);
    my $code2 = "$doc2";

    ok $code2 !~ m/Baz/s;
};

todo 'Remove the entire `use` statement' => sub {

    my $code = <<CODE;
use Foobar qw(Baz);
print 42;
CODE

    my $doc = PPI::Document->new(\$code);
    my $o = App::PerlNitpick::Rule::RemoveUnusedImport->new( document => $doc );
    my $doc2 = $o->rewrite($doc);
    my $code2 = "$doc2";

    ok $code2 !~ m/Baz/s;
    ok $code2 !~ m/use Foobar/s;
};

subtest 'Remove only the entire `use` statement' => sub {

    my $code = <<CODE;
use Foobar qw(Baz);
print Foobar::Baz(42);
CODE

    my $doc = PPI::Document->new(\$code);
    my $o = App::PerlNitpick::Rule::RemoveUnusedImport->new( document => $doc );
    my $doc2 = $o->rewrite($doc);
    my $code2 = "$doc2";

    is $code2, <<NEWCODE;
use Foobar qw();
print Foobar::Baz(42);
NEWCODE

};


done_testing;
