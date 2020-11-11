use Test::More;
use Compiled::Params::OO qw/all/;
use Types::Standard qw/Object CodeRef Str StrMatch Enum HashRef ArrayRef Optional Int/;

my $validate = cpo(
	new_pdf => {
		name => Str,
		page_size => {
			type => Optional->of(Enum[qw/A1 A2 A3 A4 A5/]), 
			default => sub { 'A4' },
		},
		pages => {
			type => Optional->of(ArrayRef),
			default => sub { [] } 
		},
		num => {
			type =>  Optional->of(Int), 
			default => sub { 0 } 
		},
		page_args => {
			type => Optional->of(HashRef), 
			default => sub { { } } 
		},
		plugins => {
			type => Optional->of(ArrayRef), 
			default => sub { [ ] } 
		}
	},
	end_pdf => [Str, Int]
);

my $args = $validate->new_pdf->(name => 'testing');

my $expected = {
	'~~caller' => 'Compiled::Params::OO::cpo',
	name => 'testing',
	page_size => 'A4',
	pages => [],
	num => 0,
	page_args => {},
	plugins => [],
};

is_deeply($args, $expected);

my $args2 = $validate->new_pdf->(
	name => 'again',
	page_size => 'A5',
	num => 5
);

my $expected = {
	name => 'again',
	page_size => 'A5',
	pages => [],
	num => 5,
	page_args => {},
	plugins => [],
};

is($args2->name, 'again');
is($args2->page_size, 'A5');
is($args2->num, 5);

my @args3 = $validate->end_pdf->('string', 1);

is $args3[0], 'string';

done_testing;
