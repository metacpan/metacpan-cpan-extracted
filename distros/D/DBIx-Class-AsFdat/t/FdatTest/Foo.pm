package FdatTest::Foo;
use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/AsFdat Core/);
__PACKAGE__->table('foo');
__PACKAGE__->add_columns(qw/ id body date/);
__PACKAGE__->set_primary_key('id');

use DateTime;
__PACKAGE__->inflate_column('date', {
    inflate => sub {
        my ($value, $obj) = @_;
        my $dt = $obj->result_source->storage->datetime_parser->parse_date($value);
        return $dt ? DateTime->from_object(object => $dt) : undef;
    },
    deflate => sub {
        my ($value, $obj) = @_;
        $obj->result_source->storage->datetime_parser->format_date($value);
    },
});

1;

