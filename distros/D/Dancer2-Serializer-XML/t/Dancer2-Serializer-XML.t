use strict;
use warnings;
use Test::More tests => 5;
use Plack::Test;
use HTTP::Request::Common;
use utf8;
use Encode;
use Module::Runtime 'use_module';
use Dancer2::Serializer::XML;

my $serializer = Dancer2::Serializer::XML->new();

# Test 1: check stuff gets deserialised
my $ref = $serializer->deserialize('<data><foo>one</foo><bar>two</bar></data>');
is_deeply(
	$ref,
	{
		bar => 'two',
		foo => 'one'
    },
	"Strings get deserialized");

# Test 2: check stuff gets serialised
my $string = $serializer->serialize({foo => 'one', bar => 'two'});
is($string, '<opt bar="two" foo="one" />
', "Strings get serialized");

# Test 3: check UTf-8 is handled
{
    package UTF8App;
    use Dancer2;

    set serializer => 'XML';
    set logger     => 'Console';

    put '/from_params' => sub {
        my %p = params();
        return [ map +( $_ => $p{$_} ), sort keys %p ];
    };
}
my $app = UTF8App->to_app;
note "Verify Serializers decode into characters"; {
    my $utf8 = '∮ E⋅da = Q,  n → ∞, ∑ f(i) = ∏ g(i)';

    test_psgi $app, sub
    {
        my $cb = shift;

		my $body = $serializer->serialize({utf8 => $utf8});

		my $r = $cb->(
			PUT '/from_params',
				'Content-Type' => $serializer->content_type,
				Content        => $body,
		);
		
		my $content = Encode::decode( 'UTF-8', $r->content );

		like($content, qr{\Q$utf8\E}, "utf-8 string returns the same using the serializer");
    };
}

# Test 4: check settings take effect
my $test_xml_options = { 'serialize' => { RootName => 'test',
										KeyAttr => []
										},
						'deserialize' => { ForceContent => 1,
										KeyAttr => [],
										ForceArray => 1,
										KeepRoot => 1
										}
						};
{
    package NonDefaultApp;
    use Dancer2;

    set serializer => 'XML';
    set logger     => 'Console';

    put '/from_body' => sub {
	my $self = shift;
	$self->{'serializer_engine'}->{'xml_options'} = $test_xml_options;
        return request->data();	# Right back at you
    };
}
$app = NonDefaultApp->to_app;
note "Settings take effect"; {
    test_psgi $app, sub
    {
        my $cb = shift;
        $serializer->xml_options($test_xml_options);
		my $body = $serializer->serialize({foo => 'one', bar => 'two'});
		my $r = $cb->(
			PUT '/from_body',
				'Content-Type' => $serializer->content_type,
				Content        => $body,
		);
		#diag("Body: ". $body);
		is($r->content, '<test bar="two" foo="one" />
', "serializers take note of settings");
    };
}

# Test 5: check content type is right
is(
    $serializer->content_type,
    'application/xml',
    'content-type is set correctly',
);
