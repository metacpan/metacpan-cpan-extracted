use Test::More qw[no_plan];
use strict;
$^W = 1;

BEGIN {
    use_ok 'base', 'Class::DBI';
    use_ok 'Class::DBI::AsXML';
    use_ok 'XML::Simple';
    
    {
      package Silly::Little::Guy;
      sub new { bless {}, shift }
      sub as_string { "Hi there" }
      sub to_xml { "<xml><hi>there</hi></xml>\n" }
    }
}

can_ok __PACKAGE__, 'to_xml';

__PACKAGE__->connection('dbi:Testing:foo.db', '', '');
__PACKAGE__->table('testing_table');
__PACKAGE__->columns(Primary => q[id]);
__PACKAGE__->columns(Essential => qw[e_one e_two]);
__PACKAGE__->columns(Others    => qw[o_one o_two]);

my $one_object = __PACKAGE__->create({
    e_one => 1,
    e_two => 2,
    o_one => XML::Simple->new,
    o_two => __PACKAGE__->create({
                 e_one => 'one',
                 e_two => 'two',
                 o_one => Silly::Little::Guy->new,
                 o_two => 'nothing special',
             }),
});

isa_ok $one_object, __PACKAGE__;
my $one_xml = $one_object->to_xml;
my $two_xml = $one_object->o_two->to_xml;

ok length($one_xml), 'got first object as xml';
ok length($two_xml), 'got second object as xml';

my $one_hash = XMLin $one_xml;
my $two_hash = XMLin $two_xml, KeepRoot => 1;

is keys(%{$one_hash}), 3, 'only three elements were dumped';
is keys(%{$two_hash}), 1, 'only one element at top level';
is +(keys(%{$two_hash}))[0], __PACKAGE__->moniker, 'default top-level is moniker';
is keys(%{$two_hash->{__PACKAGE__->moniker}}), 3, 'only three elements were dumped';

my $all_columns = $one_object->to_xml(
    columns => {
        ref($one_object) => [$one_object->columns],
    },
);
my $all_columns_hash = XMLin $all_columns;
is keys(%{$all_columns_hash}), 5, 'all five elements were dumped';
is $all_columns_hash->{o_two}, 1, 'stringified object';
like $all_columns_hash->{o_one}, qr/XML::Simple=/, 'stringified non-stringifiable object to memory location';

my $deep = $one_object->to_xml(
    columns => {
        ref($one_object) => [$one_object->columns],
    },
    depth => 1
);
my $deep_hash = XMLin $deep;

is ref($deep_hash->{o_two}), 'HASH', 'went down one';
isnt ref($deep_hash->{o_two}->{o_one}), 'HASH', 'did not go down two';
is $deep_hash->{o_two}->{id}, 1, 'proper object in slot';
is $deep_hash->{o_two}->{o_one}, 'Hi there', 'stringify worked';

my $real_deep = $one_object->to_xml(
    columns => {
        ref($one_object) => [$one_object->columns],
    },
    depth => 10
);
my $real_deep_hash = XMLin $real_deep;

is ref($real_deep_hash->{o_two}->{o_one}), 'HASH', 'went deep enough';
is $real_deep_hash->{o_two}->{o_one}->{hi}, 'there', 'xml was parsed';

my $new_root = $one_object->to_xml(xml => {RootName => 'silly'});
is +(keys(%{XMLin($new_root, KeepRoot => 1)}))[0], 'silly', 'changed root';

{
    package Silly::Gnome;
    use base qw[Class::DBI];
    use Class::DBI::AsXML;
    
    __PACKAGE__->connection('dbi:Testing:foo.db', '', '');
    __PACKAGE__->table('testing_table_gnome');
    __PACKAGE__->columns(Primary => q[id]);
    __PACKAGE__->columns(Essential => qw[name]);
    __PACKAGE__->columns(Others    => qw[type]);
    
    __PACKAGE__->to_xml_columns(['type']);

    my @objects;
    sub create {
        my ($self, $args) = @_;
        push @objects, $args;
        my $object = $objects[-1];
        $object->{id} = @objects;
        bless $object, $self;
        return $object;
    }
    
    sub get {
        my ($self, @keys) = @_;
        return @{$self}{@keys};
    }
}

my $three = __PACKAGE__->create({
    e_one => 1,
    e_two => Silly::Gnome->create({
                name => 'bear',
                type => 'grouchy',
             }),
});

my $three_xml = $three->to_xml(
    columns => {
        'Silly::Gnome' => [ Silly::Gnome->columns ],
    },
    depth => 1,
);

my $three_hash = XMLin $three_xml;

is ref($three_hash->{e_two}), 'HASH', 'did descend';
ok exists($three_hash->{e_two}->{type}), 'did follow columns instructions';
is $three_hash->{e_two}->{type}, 'grouchy', 'type set properly';

is @{Silly::Gnome->to_xml_columns}, 1, 'one column set for default';
is @{main->to_xml_columns}, 0, 'none for main';

my $bear_xml = $three->e_two->to_xml;
my $bear_hash = XMLin $bear_xml;
is +(keys(%{$bear_hash})), 1, 'only one thing returned';
is +(keys(%{$bear_hash}))[0], 'type', 'only one thing returned: type';

my $new_from_xml = __PACKAGE__->create_from_xml(<<__XML__);
<main>
  <e_one>First Element</e_one>
  <e_two>Second Element</e_two>
</main>
__XML__

isa_ok $new_from_xml, __PACKAGE__;
is $new_from_xml->e_one, 'First Element', 'first element correct';

my @objects;
sub create {
    my ($self, $args) = @_;
    push @objects, $args;
    my $object = $objects[-1];
    $object->{id} = @objects;
    bless $object, $self;
    return $object;
}

sub get {
    my ($self, @keys) = @_;
    return @{$self}{@keys};
}
