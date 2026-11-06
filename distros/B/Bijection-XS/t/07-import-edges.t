use Test::More;
use Bijection::XS ();

# What import does with what is not a tag name: an empty name, undef and a
# reference go to Ex::Op as they are and are refused there, and a function
# name still imports when the tags hash is gone.

for my $odd (['the empty string', ''], ['undef', undef], ['a scalar reference', \'x'], ['a hash reference', {}]) {
    my $ok = eval { package Odd; Bijection::XS->import($odd->[1]); 1 };
    ok(!$ok, "$odd->[0] is passed on");
    like($@, qr/is not exported by the Bijection::XS module/, 'and refused as a name');
}
{
    no strict 'refs';
    my %saved = %{'Bijection::XS::EXPORT_TAGS'};
    delete $Bijection::XS::{EXPORT_TAGS};
    my $ok = eval { package NoTags; Bijection::XS->import('biject'); 1 };
    ok($ok && defined &NoTags::biject, 'with no tags hash a function name still imports');
    %{'Bijection::XS::EXPORT_TAGS'} = %saved;
    $ok = eval { package TagsBack; Bijection::XS->import('main'); 1 };
    ok($ok && defined &TagsBack::biject, 'and a tag name again once the hash is back');
}

done_testing;
