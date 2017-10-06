use Test::More;

{
	package Have::Fun;

	use Moo;
	use Coerce::Types::Standard qw/HTML/;
	use MooX::LazierAttributes;

	attributes (
		[qw/enc_entity/] => [HTML->by('encode_entity'), { coe }],
		[qw/dec_entity/] => [HTML->by('decode_entity'), { coe }],
	);
}

use Have::Fun;
my $thing = Have::Fun->new( 
	enc_entity => q|<div>'okay&"!</div>|, 
	dec_entity => q|&lt;div&gt;&apos;okay&amp;&quot;!&lt;/div&gt;|,
);

is($thing->enc_entity, q|&lt;div&gt;&apos;okay&amp;&quot;!&lt;/div&gt;|);
is($thing->dec_entity, q|<div>'okay&"!</div>|);

done_testing();
