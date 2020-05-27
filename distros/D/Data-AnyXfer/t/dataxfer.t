package Data::AnyXfer::Test;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

extends 'Data::AnyXfer';


has 'in' => (
    is  => 'ro',
    isa => ArrayRef,
);

has 'index' => (
    is       => 'rw',
    isa      => Int,
    default  => 0,
    init_arg => undef,
);

has 'out' => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

around 'fetch_next' => sub {
    my ( $orig, $self ) = @_;
    $self->$orig or return;
    $self->index( my $index = $self->index + 1 );
    return $self->in->[ $index - 1 ];
};

around 'transform' => sub {
    my ( $orig, $self, $res ) = @_;
    return { value => uc($res), index => $self->index };
};

with 'Data::AnyXfer::Role::Count';

around 'store' => sub {
    my ( $orig, $self, $rec ) = @_;
    $self->$orig or return;
    push @{$self->out}, $rec;
};

around 'run' => sub {
    my ( $orig, $self ) = @_;
    $self->$orig ? $self->index - 1 : 0;
};

1;

package main;

use Data::AnyXfer::Test::Kit;

my @out;
my $import = Data::AnyXfer::Test->new( in => [qw/ a b c /], );

isa_ok( $import, 'Data::AnyXfer' );
is $import->run, 3, 'run';
is $import->transfer_count, 3, 'transfer_count';

explain $import->out;

is_deeply $import->out,
    [
    {   'index' => 1,
        'value' => 'A'
    },
    {   'index' => 2,
        'value' => 'B'
    },
    {   'index' => 3,
        'value' => 'C'
    }
    ],
    'expected output';

done_testing;
