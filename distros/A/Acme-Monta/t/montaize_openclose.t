# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Acme-Monta.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Acme::Monta') };

my $monta = Acme::Monta->new(open_font => '#f00', open_back => '#00f', close_font => '#0f0', close_back => '#0f0');
my $data = 'this is <monta>secret words</monta>.';
ok($monta->montaize($data) eq 'this is <span style="cursor:pointer;color:#0f0;background-color:#0f0;background-image:;" onClick="this.style.color = \'#f00\';this.style.backgroundColor = \'#00f\';this.style.backgroundImage = \'\';this.style.cursor = \'\';">secret words</span>.');
