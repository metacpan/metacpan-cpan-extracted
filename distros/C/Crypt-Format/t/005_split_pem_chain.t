use Test::More;
use Test::FailWarnings;

use Crypt::Format;

plan tests => 5;

my $pem1 = "-----BEGIN SOMETHING-----\n123123123\n-----END SOMETHING-----";
my $pem2 = "-----BEGIN SOMETHING-----\n234234234\n-----END SOMETHING-----";

my @split = Crypt::Format::split_pem_chain("$pem1\x0a$pem2");

is_deeply(
    \@split,
    [ $pem1, $pem2 ],
    'split w/ LF as separator',
);

#----------------------------------------------------------------------

@split = Crypt::Format::split_pem_chain("$pem1\x0d$pem2");

is_deeply(
    \@split,
    [ $pem1, $pem2 ],
    'split w/ CR as separator',
);

#----------------------------------------------------------------------

@split = Crypt::Format::split_pem_chain("$pem1\x0a\x0d$pem2");

is_deeply(
    \@split,
    [ $pem1, $pem2 ],
    'split w/ CRLF as separator',
);

#----------------------------------------------------------------------

@split = Crypt::Format::split_pem_chain($pem1);

is_deeply(
    \@split,
    [ $pem1 ],
    'split w/ single PEM',
);

#----------------------------------------------------------------------

@split = Crypt::Format::split_pem_chain("$pem1\x0a\x0d$pem2\x0a$pem1");

is_deeply(
    \@split,
    [ $pem1, $pem2, $pem1 ],
    'split w/ mixed separators',
);
