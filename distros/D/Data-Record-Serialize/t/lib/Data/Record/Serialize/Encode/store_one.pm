package Data::Record::Serialize::Encode::store_one;

use Moo::Role;

use Types::Standard qw[ ArrayRef ];

has '+_need_types' => ( is => 'rwp', default => 1 );
has '+_use_integer' => ( is => 'rwp', default => 1 );

has output => ( is => 'rwp',
                init_arg => undef,
              );

sub print {
    my $self = shift;
    $self->_set_output( @_ );
}

*say = \&print;

sub encode { shift; @_; };

sub close {  }

with 'Data::Record::Serialize::Role::Sink';
with 'Data::Record::Serialize::Role::Encode';

1;
