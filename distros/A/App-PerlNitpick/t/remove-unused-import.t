#!perl
use Test2::V0;
use App::PerlNitpick::Rule::RemoveUnusedImport;

subtest 'Remove only the imported subroutine' => sub {
    my $code = <<CODE;
use Foobar qw(Foo Baz);
print Foo(42);
print Foobar::Baz(42);
CODE

    my $doc = PPI::Document->new(\$code);
    my $o = App::PerlNitpick::Rule::RemoveUnusedImport->new( document => $doc );
    my $doc2 = $o->rewrite($doc);
    is "$doc2", <<NEWCODE;
use Foobar qw(Foo);
print Foo(42);
print Foobar::Baz(42);
NEWCODE
};

todo 'Remove the `use` statement, if none of those symbols imported in the statement are used.' => sub {
    my $code = <<CODE;
use Foobar qw(Bux Baz);
print 42;
CODE

    my $doc = PPI::Document->new(\$code);
    my $o = App::PerlNitpick::Rule::RemoveUnusedImport->new( document => $doc );
    my $doc2 = $o->rewrite($doc);
    my $code2 = "$doc2";

    is "$doc2", "print 42;"
};

done_testing;
