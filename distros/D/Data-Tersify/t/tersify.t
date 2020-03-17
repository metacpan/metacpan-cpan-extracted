#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Data::Dumper;
use Scalar::Util qw(refaddr reftype);
use Test::More;

use Data::Tersify qw(tersify tersify_many);
use TestObject;
use TestObject::Overloaded;
use TestObject::Overloaded::JustImport;
use TestObject::Overloaded::OtherOperator;
use TestObject::WithName;
use TestObject::WithUUID;

local $Data::Dumper::Indent   = 1;
local $Data::Dumper::Sortkeys = 1;
local $Data::Dumper::Terse    = 1;

my $re_refaddr = qr{ \( 0x [0-9a-f]+ \) }x;

subtest 'Basic structures are unchanged' => \&test_basic_structures_unchanged;
subtest 'Plugins'                        => \&test_plugin;
subtest 'We can tersify other objects'   => \&test_tersify_other_objects;
subtest 'We avoid infinite loops'        => \&test_avoid_infinite_loops;
subtest 'But we update references'       => \&test_update_references;
subtest 'Overloaded stringification'     => \&test_stringification;
subtest 'Tersify many values'            => \&test_tersify_many;
subtest 'Cannot tersify weird things'    => \&test_cannot_tersify_weird_things;
subtest 'Can reuse the same RAM address' => \&test_reuse_same_ram_address;

done_testing();

# We don't mess with standard Perl structures: scalars, arrays or hashes.

sub test_basic_structures_unchanged {
    # Basic structures.
    is_deeply(tersify('foo'), 'foo', 'Simple scalars pass through');
    my @array = qw(foo bar baz);
    is_deeply(tersify(\@array), \@array,
        'Simple arrays pass through unchanged');
    my %hash = (foo => 'toto', bar => 'titi', baz => 'tata');
    is_deeply(tersify(\%hash), \%hash,
        'Simple hashes pass through unchanged');

    # It's the same structures we get back.
    is(tersify(\@array), \@array, q{It's the same simple array});
    is(tersify(\%hash), \%hash, q{It's the same simple hash also});

    # Complex structures also go through unchanged.
    my %complex_structure = (
        sins    => [qw(pride greed lust envy gluttony wrath sloth)],
        virtues => [
            qw(prudence justice temperance courage
                faith hope charity)
        ],
        balance => {
            economy => {
                charity => [
                    'RSPB', 'Oxfam', ['Cat home', 'Dog home'],
                    {
                        'Cancer Research'          => '10 GBP per month',
                        'British Heart Foundation' => {
                            donate    => '5 GBP per month',
                            volunteer => ['Mondays', 'Thursdays'],
                        }
                    }
                ],
                greed => 'Those cakes are nice. Or is that gluttony?',
            }
        }
    );
    is_deeply(tersify(\%complex_structure),
        \%complex_structure,
        'A structure with many nested arrayrefs and hashrefs is untouched');
}

# If we have a plugin that knows about a type of object, it will apply at
# all levels apart from the absolute top level.

sub test_plugin {
    my $object = TestObject->new(42);

    # Basic tests
    is(tersify($object), $object,
        'An object passed directly is not tersified');
    my $tersified = tersify({object => $object });
    is_deeply([keys %$tersified], ['object'],
        'Still have just the one key called object');
    is(ref($tersified->{object}),
        'Data::Tersify::Summary',
        'The object value is now our summary object');
    like(
        ${ $tersified->{object} },
        qr/^ TestObject \s $re_refaddr \s ID \s 42 $/x,
        'The object got summarised as a scalar reference'
    );

    # Structures containing tersified objects are returned modified,
    # as are any parent structures. Other structures are unaffected.
    my $emergency_object = TestObject->new(999);
    my $deep_object      = TestObject->new(5683);
    my $original = {
        meh => [
            'mumbo', 'jumbo',
            {
                faff => 'nonsense',
            }
        ],
        emergency      => $emergency_object,
        deep_structure => {
            many => {
                layers => {
                    until => $deep_object,
                }
            }
        }
    };
    $tersified = tersify($original);
    is_deeply(
        $tersified->{meh},
        ['mumbo', 'jumbo', { faff => 'nonsense' }],
        'The data structure with no objects is unaffected'
    );
    is(
        refaddr($tersified->{meh}),
        refaddr($original->{meh}),
        q{In fact it's the same structure}
    );
    isnt(refaddr($tersified), refaddr($original),
        'But the root structure is different');
    like(
        ${$tersified->{emergency}},
        qr{^ TestObject \s $re_refaddr \s ID \s 999 $}x,
        'The emergency test object was summarised'
    );
    like(${$tersified->{deep_structure}{many}{layers}{until}},
        qr{^ TestObject \s $re_refaddr \s ID \s 5683 $}x,
        'The deep test object was summarised');
    isnt(
        refaddr($tersified->{deep_structure}),
        refaddr($original->{deep_structure}),
        'The deep structure is also a new hash'
    );
    isnt(
        refaddr($tersified->{deep_structure}{many}),
        refaddr($original->{deep_structure}{many}),
        'As is many'
    );
    isnt(
        refaddr($tersified->{deep_structure}{many}{layers}),
        refaddr($original->{deep_structure}{many}{layers}),
        'And layers'
    );
    is(ref($original->{emergency}), 'TestObject',
        'We still have the original emergency object');
    is(ref($original->{deep_structure}{many}{layers}{until}), 'TestObject',
        'We also have the deep object');

    # Plugins can say that they handle multiple types of object.
    my $original_multiple = {
        id => 12,
        name => TestObject::WithName->new('Bob'),
        uuid => TestObject::WithUUID->new('1234567890AB-or-something'),
        'is that even a real UUID?' => 'no, who cares?',
    };
    my $tersified_multiple = tersify($original_multiple);
    like(
        ${ $tersified_multiple->{name} },
        qr{^ TestObject::WithName \s $re_refaddr \s Name \s Bob $}x,
        'The named object was summarised'
    );
    like(
        ${ $tersified_multiple->{uuid} },
        qr{^ TestObject::WithUUID \s $re_refaddr \s UUID \s 123456.+ $}x,
        'The object with a UUID was summarised'
    );
    
}

# Our plugins will apply to the guts of blessed objects as well.

sub test_tersify_other_objects {
    # Objects without anything inside them aren't tersified.
    my $simple_object = bless { number => 1, other_number => 'also 1' },
        'Simple';
    my $structure = { simple_object => $simple_object };
    my $tersified = tersify($structure);
    is_deeply($tersified, $structure,
        q{Simple objects aren't affected});

    # But complex objects are tersified.
    my $complex_object
        = bless { id => TestObject->new(42) } => 'Complex::Object';
    $tersified = tersify($complex_object);
    like(
        ${ $tersified->{id} },
        qr{^ TestObject \s $re_refaddr \s ID \s 42 $}x,
        'The ID inside this object was tersified'
    );
    is(
        ref($tersified),
        sprintf('Data::Tersify::Summary::Complex::Object::0x%x',
            refaddr($complex_object)),
        'The original type and the refaddr of the object are mentioned'
    );
}

# We won't try to continuously tersify data structures we've seen before.

sub test_avoid_infinite_loops {
    my %babe;
    $babe{'The babe with the power'} = {
        'What power?' => {
            'The power of voodoo' => {
                'Voodoo?' => {
                    'You do' => {
                        'I do what?' => {
                            'Remind me of the babe' => {
                                'What babe?' => \%babe
                            }
                        }
                    }
                }
            }
        }
    };
    my %dialogue = (
        'You remind me of the babe' => {
            'What babe?' => \%babe,
        }
    );
    my $terse_dialogue = tersify(\%dialogue);
    is_deeply($terse_dialogue, \%dialogue,
        q{We aren't trapped by infinite loops});

    my $parts = bless { dialogue => \%dialogue, babe => \%babe } => 'Parts';
    my $terse_parts = tersify($parts);
    is_deeply($terse_parts, $parts,
        'This applies to blessed objects as well');
}

# If we find a reference to a structure or object that we end up tersifying
# later on, that reference will be updated to point to the tersified
# object.

sub test_update_references {
    # If we have a reference to a blessed object - most notably ourself
    # - we'll replace it with the tersified version.
    my $plugin_affected_object = bless {
        plugin_content => TestObject->new(1337),
        linked_list => {
            before => undef,
            after => undef,
        },
    } => 'WeakRecursion';
    $plugin_affected_object->{linked_list}{self} = $plugin_affected_object;
    my $tersified_object = tersify($plugin_affected_object);
    is_deeply(
        $tersified_object->{linked_list},
        {
            before => undef,
            after  => undef,
            self   => $tersified_object,
        },
        'We update references to tersified objects',
    ) or diag(Dumper($tersified_object));

    # This also affects hashes and arrays that we tersify, and potentially
    # multiple objects.
    my @interesting_things = (
        'a leaf',
        TestObject->new('Unknown ID'),
        'floccinaucinihilipilification'
    );
    push @interesting_things, \@interesting_things;
    my %nature = (
        interesting => \@interesting_things,
        with_name   => TestObject::WithName->new('Actually quite boring'),
        with_uuid   => TestObject::WithUUID->new('Not actually validated'),
    );
    my $complexly_nested_object = bless {
        nature             => \%nature,
        interesting_things => \@interesting_things,
    } => 'ComplexInternals';
    push @interesting_things, $complexly_nested_object;
    $complexly_nested_object->{objects} = bless [
        $complexly_nested_object,
        $interesting_things[1],
        $nature{with_name},
        $nature{with_uuid},
    ] => 'ObjectList';
    my $object_ref = \$complexly_nested_object;
    $complexly_nested_object->{references} = {
        self_ref => $object_ref,
        name     => $nature{with_name},
        uuid     => $nature{with_uuid},
    };
    my $terse_nested_object = tersify($complexly_nested_object);

    # We have the top-level hash keys we expect.
    my $any_failures;
    is_deeply(
        [sort keys %$terse_nested_object],
        ['interesting_things', 'nature', 'objects', 'references'],
        'The guts of our test object look correct'
    ) or $any_failures++;

    # Our interesting things arrayref contains updated references to
    # tersified objects, including the main object, and also itself.
    subtest(
        'Interesting things',
        sub {
            my $terse_interesting_things
                = $terse_nested_object->{interesting_things};
            is($terse_interesting_things->[0], 'a leaf',
                '#0 scalar unchanged')
                or return;
            is(ref($terse_interesting_things->[1]), 'Data::Tersify::Summary',
                '#1 object')
                or return;
            is(
                $terse_interesting_things->[2],
                'floccinaucinihilipilification',
                '#2 scalar unchanged'
            ) or return;
            is(ref($terse_interesting_things->[3]), 'ARRAY',
                '#3 is an arrayref...')
                or return;
            is($terse_interesting_things->[3], $terse_interesting_things,
                '...a reference to the parent arrayref')
                or return;
            is($terse_interesting_things->[4], $terse_nested_object,
                '#4 is the parent object')
                or return;
            return 1;
        }
    ) or $any_failures++;

    # The nature hashref has also been updated.
    subtest(
        'Nature',
        sub {
            my $terse_nature = $terse_nested_object->{nature};
            is(
                $terse_nature->{interesting},
                $terse_nested_object->{interesting_things},
                'interesting is updated to match'
            ) or $any_failures++;
            is(ref($terse_nature->{with_name}),
                'Data::Tersify::Summary', 'with_name is tersified')
                or $any_failures++;
            is(ref($terse_nature->{with_uuid}),
                'Data::Tersify::Summary', 'with_uuid is tersified')
                or $any_failures++;
        }
    );

    # The object list is a blessed object, and has similarly been updated.
    subtest(
        'Object list',
        sub {
            my $terse_object_list = $terse_nested_object->{objects};
            like(
                ref($terse_object_list),
                qr/^ Data::Tersify::Summary::ObjectList:: 0x [0-9a-f]+ $/x,
                'The object list has been reblessed as a summary object...'
            ) or $any_failures++;
            is(reftype($terse_object_list), 'ARRAY', '...which is an array')
                or $any_failures++;
            is_deeply(
                [@$terse_object_list],
                [
                    $terse_nested_object,
                    $terse_nested_object->{interesting_things}[1],
                    $terse_nested_object->{nature}{with_name},
                    $terse_nested_object->{nature}{with_uuid},
                ],
                'The tersified object references were used here'
            ) or $any_failures++;
        }
    );

    # References have similarly been updated, including references to
    # references.
    subtest(
        'References',
        sub {
            my $terse_references = $terse_nested_object->{references};
            is(
                $terse_references->{name},
                $terse_nested_object->{nature}{with_name},
                'The terse name object reference was updated'
            ) or $any_failures++;
            is(
                $terse_references->{uuid},
                $terse_nested_object->{nature}{with_uuid},
                'The terse UUID object reference was updated'
            ) or $any_failures++;
            is(${ $terse_references->{self_ref} },
                $terse_nested_object,
                'The reference to our object was updated')
                or $any_failures++;
        }
    );
    diag(Dumper($terse_nested_object)) if $any_failures || 0;
}

# If an object can stringify itself, we use that as its representation.

sub test_stringification {
    # We recognise objects that overload stringification.
    my $overloaded_no_params = TestObject::Overloaded->new;
    my %data = ( overloaded => $overloaded_no_params );
    my $tersified = tersify(\%data);
    like(
        ${ $tersified->{overloaded} },
        qr{^ TestObject::Overloaded \s $re_refaddr \s 
            \QAn object which was passed nothing\E $}x,
        'We recognise objects that support overloading...'
    );
    $data{overloaded} = TestObject::Overloaded->new('a herring');
    $tersified = tersify(\%data);
    like(
        ${ $tersified->{overloaded} },
        qr{^ TestObject::Overloaded \s $re_refaddr \s 
            \QAn object which was passed a herring\E $}x,
        '...no matter their contents'
    );

    # We won't stringify objects that overload other operations.
    $data{overloaded} = TestObject::Overloaded::OtherOperator->new;
    $tersified = tersify(\%data);
    is(refaddr($tersified->{overloaded}), refaddr($data{overloaded}),
        'An object that overloads, but not stringification, is not affected'
    );
    $data{overloaded} = TestObject::Overloaded::JustImport->new;
    $tersified = tersify(\%data);
    is(refaddr($tersified->{overloaded}), refaddr($data{overloaded}),
        'An object that just imports overload is not affected either'
    );
}

# We can tersify many values.
sub test_tersify_many {
    my @non_terse = (
        'Meh', TestObject->new('Wossname'), [qw(toto tata titi)],
        bless {
            other_object => TestObject::WithName->new('Will this do?')
        } => 'TestedElsewhere'
    );
    my @terse = tersify_many(@non_terse);
    is(scalar @terse, 4,
        'You can tersify many values and get that many back');
    is($terse[0], 'Meh', '#0: scalar, unchanged');
    is(ref($terse[1]), 'TestObject', '#1: top-level object unchanged');
    is_deeply($terse[2], [qw(toto tata titi)], '#2: arrayref, unchanged');
    like(
        ref($terse[3]),
        qr{^ Data::Tersify::Summary::TestedElsewhere::0x [0-9a-f]+ $}x,
        '#3: tersified object'
    );
    is(ref($terse[3]{other_object}),
        'Data::Tersify::Summary',
        '#3 tersified object contents are tersified');
}

# We can't tersify weird things like Regexps, though.

sub test_cannot_tersify_weird_things {
    # Regexps: test these in some detail.
    my $regexp = qr/^ Foo /xi;
    is(tersify($regexp), $regexp, q{We won't attempt to tersify regexps});
    my %stuff = (
        regexp      => $regexp,
        test_object => TestObject->new('Wossname'),
    );
    my $terse_stuff = tersify(\%stuff);
    is($terse_stuff->{regexp}, $regexp,
        'Not even as part of a data structure...');
    is(ref($terse_stuff->{test_object}), 'Data::Tersify::Summary',
        '...that we otherwise tersified');

    # Assume that the same sort of thing goes for coderefs etc.
    my $coderef = sub { TestObject->new('This will never get run') };
    is(tersify($coderef), $coderef, 'Coderefs are also unaffected');
}

# Even if Perl reuses the same refaddr for a data structure that we modified
# in previous runs, that doesn't faze us.

sub test_reuse_same_ram_address {
    my $num_counts = 10;
    for my $count (1..$num_counts) {
        my $original = {
            hashref_containing => {
                object => TestObject->new(123),
            }
        };
        my $tersified = tersify($original);
        isnt(
            refaddr($tersified->{hashref_containing}),
            refaddr($original->{hashref_containing}),
            "Count $count of $num_counts: we replace a hashref",
        );
    }    
}


