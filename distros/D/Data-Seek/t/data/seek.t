use Test::More;

my $c = 'Data::Seek';
my @m = qw(new search);

eval "require $c";

ok !$@ or diag $@;

can_ok $c => ('new', @m);
isa_ok $c->new, $c;

my $data = {
    "id"      => 12345,
    "patient" => {
        "name" => {
            "first" => "Bob",
            "last"  => "Bee"
        },
        "birthday" => {
            "month" => 12,
            "day"   => 18,
            "year"  => 1956
        }
    },
    "medications" => [
        {   "aceInhibitors" => [
                {   "name"      => "lisinopril",
                    "strength"  => "10 mg Tab",
                    "dose"      => "1 tab",
                    "route"     => "PO",
                    "sig"       => "daily",
                    "pillCount" => "#90",
                    "refills"   => "Refill 3"
                }
            ],
            "antianginal" => [
                {   "name"      => "nitroglycerin",
                    "strength"  => "0.4 mg Sublingual Tab",
                    "dose"      => "1 tab",
                    "route"     => "SL",
                    "sig"       => "q15min PRN",
                    "pillCount" => "#30",
                    "refills"   => "Refill 1"
                }
            ],
            "anticoagulants" => [
                {   "name"      => "warfarin sodium",
                    "strength"  => "3 mg Tab",
                    "dose"      => "1 tab",
                    "route"     => "PO",
                    "sig"       => "daily",
                    "pillCount" => "#90",
                    "refills"   => "Refill 3"
                }
            ],
            "betaBlocker" => [
                {   "name"      => "metoprolol tartrate",
                    "strength"  => "25 mg Tab",
                    "dose"      => "1 tab",
                    "route"     => "PO",
                    "sig"       => "daily",
                    "pillCount" => "#90",
                    "refills"   => "Refill 3"
                }
            ],
            "diuretic" => [
                {   "name"      => "furosemide",
                    "strength"  => "40 mg Tab",
                    "dose"      => "1 tab",
                    "route"     => "PO",
                    "sig"       => "daily",
                    "pillCount" => "#90",
                    "refills"   => "Refill 3"
                }
            ],
            "mineral" => [
                {   "name"      => "potassium chloride ER",
                    "strength"  => "10 mEq Tab",
                    "dose"      => "1 tab",
                    "route"     => "PO",
                    "sig"       => "daily",
                    "pillCount" => "#90",
                    "refills"   => "Refill 3"
                }
            ]
        }
    ],
    "labs" => [
        {   "name"     => "Arterial Blood Gas",
            "time"     => "Today",
            "location" => "Main Hospital Lab"
        },
        {   "name"     => "BMP",
            "time"     => "Today",
            "location" => "Primary Care Clinic"
        },
        {   "name"     => "BNP",
            "time"     => "3 Weeks",
            "location" => "Primary Care Clinic"
        },
        {   "name"     => "BUN",
            "time"     => "1 Year",
            "location" => "Primary Care Clinic"
        },
        {   "name"     => "Cardiac Enzymes",
            "time"     => "Today",
            "location" => "Primary Care Clinic"
        },
        {   "name"     => "CBC",
            "time"     => "1 Year",
            "location" => "Primary Care Clinic"
        },
        {   "name"     => "Creatinine",
            "time"     => "1 Year",
            "location" => "Main Hospital Lab"
        },
        {   "name"     => "Electrolyte Panel",
            "time"     => "1 Year",
            "location" => "Primary Care Clinic"
        },
        {   "name"     => "Glucose",
            "time"     => "1 Year",
            "location" => "Main Hospital Lab"
        },
        {   "name"     => "PT/INR",
            "time"     => "3 Weeks",
            "location" => "Primary Care Clinic"
        },
        {   "name"     => "PTT",
            "time"     => "3 Weeks",
            "location" => "Coumadin Clinic"
        },
        {   "name"     => "TSH",
            "time"     => "1 Year",
            "location" => "Primary Care Clinic"
        }
    ],
    "imaging" => [
        {   "name"     => "Chest X-Ray",
            "time"     => "Today",
            "location" => "Main Hospital Radiology"
        },
        {   "name"     => "Chest X-Ray",
            "time"     => "Today",
            "location" => "Main Hospital Radiology"
        },
        {   "name"     => "Chest X-Ray",
            "time"     => "Today",
            "location" => "Main Hospital Radiology"
        }
    ]
};

my $seek = Data::Seek->new(data => $data);
my $result = $seek->search('*', 'imaging.@.name');
isa_ok $result, 'Data::Seek::Search::Result';

is_deeply $result->data, {
    id => 12345,
    imaging => [
        { name => "Chest X-Ray" },
        { name => "Chest X-Ray" },
        { name => "Chest X-Ray" },
    ]
};

is_deeply $result->datasets, [
    {
        criterion => '*',
        dataset   => { 'id' => 12345 },
        nodes     => ['id'],
    },
    {
        criterion => 'imaging.@.name',
        dataset   => {
            'imaging:0.name' => 'Chest X-Ray',
            'imaging:1.name' => 'Chest X-Ray',
            'imaging:2.name' => 'Chest X-Ray',
        },
        nodes     => [
            'imaging:0.name',
            'imaging:1.name',
            'imaging:2.name',
        ],
    }
];

is_deeply $result->nodes, [
    'id',
    'imaging:0.name',
    'imaging:1.name',
    'imaging:2.name',
];

is_deeply $result->values, [
    12345,
    'Chest X-Ray',
    'Chest X-Ray',
    'Chest X-Ray',
];

$seek->ignore(1);

is @{$seek->search('id')->values}, 1;
is @{$seek->search('patient')->values}, 0;
is @{$seek->search('patient.name')->values}, 0;
is @{$seek->search('patient.name.first')->values}, 1;
is @{$seek->search('patient.name.last')->values}, 1;
is @{$seek->search('patient.name.*')->values}, 2;
is @{$seek->search('patient.name.**')->values}, 2;
is @{$seek->search('patient.**')->values}, 5;
is @{$seek->search('patient.@')->values}, 0;
is @{$seek->search('patient.@.name')->values}, 0;
is @{$seek->search('patient.@.type')->values}, 0;
is @{$seek->search('medications')->values}, 0;
is @{$seek->search('medications.**')->values}, 0;
is @{$seek->search('medications.@')->values}, 0;
is @{$seek->search('medications.@.*')->values}, 0;
is @{$seek->search('medications.@.**')->values}, 42;
is @{$seek->search('medications**')->values}, 42;
is @{$seek->search('medications:0.**')->values}, 42;
is @{$seek->search('medications:1.**')->values}, 0;
is @{$seek->search('medications:0.@*.**')->values}, 42;
is @{$seek->search('medications:0.@ace*.**')->values}, 7;
is @{$seek->search('medications:0.@beta*.**')->values}, 7;
is @{$seek->search('@medications.@beta*.**')->values}, 7;
is @{$seek->search('labs.name.zeta.foobar')->values}, 0;
is @{$seek->search('labs.name.zeta.@.foobar')->values}, 0;
is @{$seek->search('*:0.**')->values}, 48;
is @{$seek->search('*.@.**')->values}, 87;
is @{$seek->search('**.name')->values}, 21;
is @{$seek->search('**')->values}, 93;

$seek->ignore(0);

# invalid/unknown root
eval {$seek->search('medications')->values};
isa_ok $@, 'Data::Object::Exception'
    or diag $@->message;

eval {$seek->search('patient')->values};
isa_ok $@, 'Data::Object::Exception'
    or diag $@->message;

eval {$seek->search('@.name')->values};
isa_ok $@, 'Data::Object::Exception'
    or diag $@->message;

eval {$seek->search('ids')->values};
isa_ok $@, 'Data::Object::Exception'
    or diag $@->message;

eval {$seek->search('people')->values};
isa_ok $@, 'Data::Object::Exception'
    or diag $@->message;

# invalid/unknown nodes
eval {$seek->search('patient.name')->values};
isa_ok $@, 'Data::Object::Exception'
    or diag $@->message;

eval {$seek->search('labs.@')->values};
isa_ok $@, 'Data::Object::Exception'
    or diag $@->message;

eval {$seek->search('labs:1')->values};
isa_ok $@, 'Data::Object::Exception'
    or diag $@->message;

eval {$seek->search('id.@')->values};
isa_ok $@, 'Data::Object::Exception'
    or diag $@->message;

eval {$seek->search('id.@.foobar')->values};
isa_ok $@, 'Data::Object::Exception'
    or diag $@->message;

eval {$seek->search('id.name')->values};
isa_ok $@, 'Data::Object::Exception'
    or diag $@->message;

ok 1 and done_testing;
