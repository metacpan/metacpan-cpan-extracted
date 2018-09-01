package Test::Schema::Result::A;

use base qw/DBIx::Class::Core/;

__PACKAGE__->load_components(qw/ Helper::Row::Enumeration /);

__PACKAGE__->table('a');

__PACKAGE__->add_columns(

    id => {
        data_type => 'integer',
    },

    foo => {
        data_type => 'enum',
        extra     => {
            list => [qw/ good bad ugly /],
        },
    },

    bar => {
        data_type => 'enum',
        extra     => {
            list   => [qw/ good bad ugly /],
            handles => {
                good_bar => 'good',
                coyote   => 'ugly',
            },
        },
    },

    baz => {
        data_type => 'enum',
        extra     => {
            list   => [qw/ good bad ugly /],
            handles => sub {
                my ($value, $col, $class) = @_;

                my %trans = ( good => 'bien', bad => 'mal' );
                my $word  = $trans{$value} or return undef;

                return "${col}_est_${word}";
            },
        },
    },

);

__PACKAGE__->add_column(

    bop => {
        data_type => 'enum',
        is_nullable => 1,
        extra     => {
            list   => [qw/ success fail /],
        },
    },

);

__PACKAGE__->set_primary_key('id');

1;
