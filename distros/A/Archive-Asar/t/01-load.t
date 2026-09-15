use Test2::V0;
use Archive::Asar;

my $sample1 = pack 'H*', <<~'_END_' =~ s/\s+//gr;
    0400000054010000500100004c0100007b2266696c6573223a7b2241223a7b22666
    96c6573223a7b227265616c2e747874223a7b2273697a65223a31392c226f666673
    6574223a2230222c22696e74656772697479223a7b22616c676f726974686d223a2
    2534841323536222c2268617368223a223965663236303930346333386130313733
    3133376261356439653935643137333962386463616332303538343766323032663
    663666634313861393839626265222c22626c6f636b53697a65223a343139343330
    342c22626c6f636b73223a5b2239656632363039303463333861303137333133376
    2613564396539356431373339623864636163323035383437663230326636636666
    34313861393839626265225d7d7d7d7d2c2243757272656e74223a7b226c696e6b2
    23a2241227d2c227265616c2e747874223a7b226c696e6b223a2243757272656e74
    2f7265616c2e747874227d7d7d4920414d205245414c205458542046494c450a
    _END_

my $arx = Archive::Asar->new_from_string($sample1);

is $arx->get_entry([]), { type => 'directory', entries => [qw<A Current real.txt>] };
is $arx->get_entry(''), { type => 'directory', entries => [qw<A Current real.txt>] };

is $arx->get_entry('Current'), { type => 'link', target => 'A' };

is $arx->get_entry('real.txt'), { type => 'link', target => 'Current/real.txt' };

is $arx->get_entry('A/real.txt'), {
    type      => 'file',
    contents  => "I AM REAL TXT FILE\n",
    integrity => {
        algorithm => 'SHA256',
        hash      => '9ef260904c38a0173137ba5d9e95d1739b8dcac205847f202f6cff418a989bbe',
        blockSize => 0x400000,
        blocks    => ['9ef260904c38a0173137ba5d9e95d1739b8dcac205847f202f6cff418a989bbe'],
    },
};
is $arx->get_entry([qw<A real.txt>]), {
    type      => 'file',
    contents  => "I AM REAL TXT FILE\n",
    integrity => {
        algorithm => 'SHA256',
        hash      => '9ef260904c38a0173137ba5d9e95d1739b8dcac205847f202f6cff418a989bbe',
        blockSize => 0x400000,
        blocks    => ['9ef260904c38a0173137ba5d9e95d1739b8dcac205847f202f6cff418a989bbe'],
    },
};

done_testing;
