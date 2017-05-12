# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
our @files;
BEGIN {
    @files = glob "t/*.sm";
    plan tests => 1 + @files; 
};
use Chemistry::Smiles;
ok(1); # If we made it this far, we're ok.

my $parser = new Chemistry::Smiles(
    add_atom => sub {
        my $c=shift; 
        local $"=',';
        $c->{out} .= "ATOM$c->{i}(@_)\n"; 
        $c->{i}++;
    },
    add_bond => sub {
        my $c=shift; 
        local $"=',';
        $c->{out} .= "BOND(@_)\n";
    }
);

for $fname (@files) {
    open F, $fname or die;
    my $content;
    my $c = {i=>0, out=>"$s\n"};
    { local undef $/; $content = <F>; }
    my ($s) = $content =~ /(.*)$/m;
    my $c = {i=>1, out=>"$s\n"};
    eval {$parser->parse($s, $c);};
    ok($c->{out}, $content);
}

