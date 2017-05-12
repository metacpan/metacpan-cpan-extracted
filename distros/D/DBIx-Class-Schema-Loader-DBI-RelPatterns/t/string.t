use strict;
use warnings;
use Test::More;
use lib qw(t/lib);
use dbixcsl_relpat_common qw/make_schema/;

my %options;

if ($DBIx::Class::Schema::Loader::VERSION < 0.07011) {
    # older versions do not handle this madness well
    my %duplicates;
    %options = (
        inflect_singular => sub {
            $_[0] . ($_[0] eq 'barid' ? ++$duplicates{$_[0]} : '');
        },
        inflect_plural => sub {
            $_[0] . ($_[0] eq 'foos' ? ++$duplicates{$_[0]} : '');
        },
    );
}

make_schema(%options,
    loader_class => 1,
    check_statinfo => 1,
    rel_name_map => sub { $_[0]->{name} },
    rel_constraint => [
        # adjust the default sch
        'db1..' => 'db1..',
        # there is nothing in schema db1
        'barid' => 'Bars.',
        # composite
        '..foosint' => '.foos.fooint',
        # restore the default sch
        '..' => '..',
        # composite
        'foosreal' => 'foos.fooreal',
        # not self-referential
        'quuxid' => 'quuxs.id',
        # very self-referential
        'quuxs.id' => 'quuxs.id',
        # self-referential
        'quuxs.id' => 'quuxs.quuxid',
        # col not specified
        'quuxs.' => 'Bars.barid',
        # to avoid "unknown data type" issue with older Loader
        {} => {type=>'similar'},
        # tab not specified
        'quuxs.barID' => 'barid',
        # foos.barid is not indexed but both tab and col are specified
        'quuxs.barID' => 'foos.barid',
        # foos.barid is not indexed but both tab and col are specified
        'foos.barid' => 'Bars.',
        # foos.barid references multiple columns
        'foos.barid' => 'quuxs.barID',
    ],
    rel_exclude => [
        # foreign key, cannot be excluded
        'quuxref' => 'quuxs.quuxid',
        # there is nothing in schema db1
        'foosreal' => 'db1.foos.fooreal',
    ],
    test_rels => [
        'foos.barid' => 'Bars.barid',
        'foos.barid' => 'quuxs.barID',
        '?foos.quuxid' => 'quuxs.id',
        'Bars.quuxref' => 'quuxs.quuxid',
        '?Bars.foosint,foosreal' => 'foos.fooint,fooreal',
        'quuxs.id' => 'quuxs.quuxid',
        'quuxs.barID' => 'foos.barid',
    ],
);

done_testing();
