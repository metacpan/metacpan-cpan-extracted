use Dancer2;
use Dancer2::Plugin::HTTP::ContentNegotiation;

=pod
 
curl -v http://0:3000/
 
# fails with a 406
curl -v http://0:3000/ -H 'Accept: image/jpeg'
 
=cut

get '/' => sub {
    http_choose (
        'application/json' => sub {to_json({ message => 'Hello World' })},
        {default => undef} # 406, Not Accaptable
    )
};

dance;