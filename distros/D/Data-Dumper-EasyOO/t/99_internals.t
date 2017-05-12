#!perl
use strict;

# various tests to get better testcover-age
# some of these tests dont reflect real use-cases

use Test::More (tests => 7);
#require "t/Testdata.pm";

use_ok qw(Data::Dumper::EasyOO);

my $ddez = Data::Dumper::EasyOO->new();
isa_ok ($ddez, 'Data::Dumper::EasyOO', "object");


# test inner Data::Dumper object handle
my $ddo = $ddez->_ez_ddo();
isa_ok ($ddo, 'Data::Dumper', "inner object");

# dont try this at home.
# its not a test, just a Devel::Cover exersize
(undef) = Data::Dumper::EasyOO::__DONT_TOUCH_THIS($ddo, undef);

# test noreset functionality
{
    # set noreset, to preserve the next print values
    $ddez->Set(_ezdd_noreset => 1);
    $ddez->Set(sortkeys => 1);		# sort to simplify test

    is($ddez->(alpha=>'ALPHA'), qq{\$alpha = 'ALPHA';\n}, "basic dump");
    
    # icky - accomodate DD's variable re-referencing.
    is($ddez->(baz=>'baz'), 
       qq{\$alpha = \${\\\$alpha};\n\$baz = 'baz';\n}, "remembered previous vals");
}


# a 'this-never-happens' call to new
$ddez = Data::Dumper::EasyOO::new(0);

# but resulting object still works. yay.
is($ddez->(foo=>'bar'), qq{\$foo = 'bar';\n}, "basic dump");
is($ddez->(bar=>'baz'), qq{\$bar = 'baz';\n}, "basic dump");


__END__

