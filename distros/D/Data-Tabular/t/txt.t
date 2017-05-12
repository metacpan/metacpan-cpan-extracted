use strict;

use Test::More tests => 1;

use Data::Tabular;

my $table;
$table = Data::Tabular->new(
    headers => ['one', 'two'],
    data    => [
         ['a', 'b'],
         ['c', 'd']
    ],
    extra_headers => [ 'three', 'four' ],
    extra => {
        'four' => sub {
	    my $self = shift;
	    $self->get('one') . $self->get('two');
        },
        'three' => sub {
	    my $self = shift;
	    join(' ', $self->get('one', 'two'));
        },
    },
    group_by => {
	groups => [
	    {
		pre => sub { my $self = shift; ($self->header(text => "First"), $self->titles() ) },
		post => sub { my $self = shift; $self->header(text => "Last"); },
	    },
	],
    },
    output => {
	headers => [ 'four', 'three', 'one', 'two' ],
	columns => {
	   four => {
	      title => "Four",
	   },
	   three => {
	      title => "Three",
	   },
	   one => {
	      title => "One (1)",
	   },
	   two => {
	      title => "Two (2)",
	   },
	},
    },
);

our $new = $table->txt . '';
our $old = <<EOP;

First
Four  Three One (1) Two (2)
ab    a b   a       b      
cd    c d   c       d      
Last 
EOP

is($new, $old, 'output');

