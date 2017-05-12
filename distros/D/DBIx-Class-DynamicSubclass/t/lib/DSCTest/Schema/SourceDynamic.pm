package # hide from PAUSE
    DSCTest::Schema::SourceDynamic;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/DynamicSubclass Core/);
__PACKAGE__->table('test2');
__PACKAGE__->add_columns(
    id   => {
        data_type   => 'int',
        is_nullable => 0,
    },
    type => {
        data_type   => 'smallint',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->typecast_column('type');

use DSCTest::Schema::SourceDynamic::Type1;
use DSCTest::Schema::SourceDynamic::Type2;
sub classify {
    my $self = shift;
    my $type = $self->type;
    if (!$type) {
        bless $self, __PACKAGE__;
    }
    elsif ($type == 1) {
        bless $self, 'DSCTest::Schema::SourceDynamic::Type1',
    }
    else {
        bless $self, 'DSCTest::Schema::SourceDynamic::Type2',
    }
}

1;
