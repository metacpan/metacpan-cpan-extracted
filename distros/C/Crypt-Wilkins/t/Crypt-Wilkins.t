

use Test::More tests => 3;
BEGIN { use_ok('Crypt::Wilkins') };

#########################

my $wc = Crypt::Wilkins->new( tagbegin => '<em>',
                              tagend => '</em>', );

my $substrate = 
'Her lover one day takes O for a walk in a section of the city where they never go - the Montsouris Park. After they have taken a stroll in the park, and have sat together side by side on the edge of a lawn, they notice, at one corner of the park, at an intersection where there are never any taxis, a car which, because of its meter, resembles a taxi."Get in," he says.';

my $plaintext = "The Ambassador's life is in danger. Meet me at Roissy";
my $binary = $wc->binencode($plaintext);
ok($binary eq '10100010000010100001011010001000001100111001100001001000111110010100110110001001001100010101001100110100101110001000000101110001110010110010110110110100101001011010001101001010000110100100100111101001100111001111001', 'binary encoding correct');

my $ciphertext = $wc->embed($plaintext,$substrate);

ok($ciphertext eq '<em>H</em>e<em>r</em> lov<em>e</em>r one d<em>a</em>y <em>t</em>akes <em>O</em> f<em>o</em><em>r</em> a <em>w</em>alk <em>i</em>n a sec<em>t</em><em>i</em>on <em>o</em><em>f</em> <em>t</em>he <em>c</em><em>i</em>ty wh<em>e</em>re <em>t</em>hey <em>n</em><em>e</em><em>v</em><em>e</em><em>r</em> go - <em>t</em>h<em>e</em> Mo<em>n</em><em>t</em>s<em>o</em><em>u</em>ris <em>P</em>ar<em>k</em>. Af<em>t</em><em>e</em>r th<em>e</em>y <em>h</em>a<em>v</em>e t<em>a</em><em>k</em>en <em>a</em> <em>s</em>t<em>r</em>ol<em>l</em> i<em>n</em> <em>t</em><em>h</em>e pa<em>r</em>k, and ha<em>v</em>e <em>s</em><em>a</em><em>t</em> tog<em>e</em><em>t</em><em>h</em>er <em>s</em>i<em>d</em><em>e</em> by <em>s</em>i<em>d</em><em>e</em> o<em>n</em> <em>t</em>h<em>e</em> <em>e</em>d<em>g</em>e o<em>f</em> a <em>l</em>aw<em>n</em>, t<em>h</em><em>e</em>y <em>n</em>oti<em>c</em><em>e</em>, a<em>t</em> on<em>e</em> c<em>o</em>rner <em>o</em><em>f</em> t<em>h</em>e p<em>a</em>rk, <em>a</em>t a<em>n</em> <em>i</em><em>n</em><em>t</em>e<em>r</em>se<em>c</em><em>t</em>io<em>n</em> <em>w</em><em>h</em>er<em>e</em> <em>t</em><em>h</em><em>e</em>re <em>a</em>re never any taxis, a car which, because of its meter, resembles a taxi."Get in," he says.', 'embed succeeded');



