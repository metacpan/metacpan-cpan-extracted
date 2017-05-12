use Data::JavaScript;

$hash = {'string' => 'Joseph',
         'array' => [qw(0 1 2 3 4 5 6 7 8 9 a b c d e f)],
         'capitals' => {'Sverige' => 'Stockholm',
                        'Norge' => 'Oslo',
                        'Danmark' => 'Koebenhavn'},
         'and' => [[0, 0], [0, 1]],
         'or' => [[0, 1], [1, 1]],
         'xor' => [[0, 1], [1, 0]]};
$hash->{'ref'} = $hash;

print scalar(jsdump("facts", $hash, 31.4e-1));
                        
