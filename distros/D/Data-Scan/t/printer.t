#!perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;
BEGIN {
    use_ok('Data::Scan::Printer') || print "Bail out!\n";
}
my $this = bless([ 'var1',
                   '2',
                   {'a' => 'b',
                    'c' => [ 'd', 'e' ],
                    'f' => bless({ 'g' => 'h' }, 'Test::Inner::i'),
                    'j' => {},
                    'k' => [],
                    'l' => \undef,
                    'm' => \\undef,
                    'non-\x{e4}scii' => 'ch\x{e0}racter',
                    'o' => sub { my $code = 'something' },
                    'p' => qr/re"gexp/
                   }
                 ], 'Test');
push(@{$this}, { self => $this, dspp => Data::Scan::Printer->new });
local %Data::Scan::Printer::Option = (
                                      #
                                      # Options here
                                      #
                                      with_deparse => 1
                                     );
dspp($this);
done_testing();

1;
