use Test::More;
use DOCSIS::ConfigFile qw( encode_docsis );

eval { encode_docsis {DownstreamFrequency => 88000000} };
is + ($@ || ''), '', 'valid';

eval { encode_docsis {DownstreamFrequency => 860000000} };
is + ($@ || ''), '', 'valid';

eval { encode_docsis {DownstreamFrequency => 88000000 - 1} };
like $@, qr{DownstreamFrequency holds a too low value}, 'too low';

eval { encode_docsis {DownstreamFrequency => 860000000 + 1} };
like $@, qr{DownstreamFrequency holds a too high value}, 'too high';

done_testing;
