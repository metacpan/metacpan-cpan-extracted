package MyTest11;
use strict;
use warnings;

use DBIx::ObjectMapper;
use DBIx::ObjectMapper::Engine::DBI;

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    username => '',
    password => '',
    on_connect_do => [
        q{CREATE TABLE artist( id integer primary key, name text )},
        q{CREATE TABLE cd( id integer primary key, title text, artist_id integer)},
        q{CREATE TABLE track( id integer primary key, cd_id integer not null, track_no int, title text)},
        q{CREATE TABLE linernote ( id integer primary key, note text )},
    ],
});

my $mapper = DBIx::ObjectMapper->new( engine => $engine );

my $artist = $mapper->metadata->table( artist => 'autoload' );
my $cd = $mapper->metadata->table(
    cd => 'autoload',
    {
        foreign_key => {
            table => 'artist',
            keys => ['artist_id'],
            refs => ['id'],
        }
    }
);
my $track = $mapper->metadata->table(
    track => 'autoload',
    {
        foreign_key => {
            table => 'cd',
            keys => ['cd_id'],
            refs => ['id'],
        }
    }
);

my $linernote = $mapper->metadata->table( linernote => 'autoload' );

sub mapping {
    my $artist_mapper = $mapper->maps(
        $artist => 'MyTest11::Artist',
        constructor => { auto => 1 },
        accessors   => { auto => 1 },
    );

    my $cd_mapper = $mapper->maps(
        $cd => 'MyTest11::Cd',
        constructor => { auto => 1 },
        accessors   => { auto => 1 },
    );

    my $track_mapper = $mapper->maps(
        $track => 'MyTest11::Track',
        constructor => { auto => 1 },
        accessors   => { auto => 1 },
    );

    my $linernote_mapper = $mapper->maps(
        $linernote => 'MyTest11::Linernote',
        constructor => { auto => 1 },
        accessors   => { auto => 1 },
    );
}

sub mapping_with_foreign_key {
    my $artist_mapper = $mapper->maps(
        $artist => 'MyTest11::Artist',
        constructor => { auto => 1 },
        accessors   => { auto => 1 },
        attributes  => {
            properties => {
                cds => +{
                    isa => $mapper->relation(
                        has_many => 'MyTest11::Cd',
                        { cascade  => 'all' },
                    ),
                }
            }
        }
    );

    my $cd_mapper = $mapper->maps(
        $cd => 'MyTest11::Cd',
        constructor => { auto => 1 },
        accessors   => { auto => 1 },
        attributes  => {
            properties => {
                artist => +{
                    isa => $mapper->relation( belongs_to => 'MyTest11::Artist' )
                },
                tracks => +{
                    isa => $mapper->relation(
                        has_many => 'MyTest11::Track',
                        { cascade  => 'all' },
                    ),
                },
                linernote => +{
                    isa =>
                        $mapper->relation(
                            has_one => 'MyTest11::Linernote',
                            { cascade  => 'all' },
                        ),
                }
            }
        }
    );

    my $track_mapper = $mapper->maps(
        $track => 'MyTest11::Track',
        constructor => { auto => 1 },
        accessors   => { auto => 1 },
        attributes  => {
            properties => {
                cd => {
                    isa => $mapper->relation( belongs_to => 'MyTest11::Cd' ),
                }
            }
        }
    );

    my $linernote_mapper = $mapper->maps(
        $linernote => 'MyTest11::Linernote',
        constructor => { auto => 1 },
        accessors   => { auto => 1 },
        attributes => {
            properties => {
                cd => {
                    isa => $mapper->relation( has_one => 'MyTest11::Cd' ),
                }
            }
        }
    );
}

sub engine { $engine }

sub mapper { $mapper }

sub setup_default_data {
    my $self = shift;
    my $artist_ins = $artist->insert->values( name => 'Led Zeppelin' )->execute(['id']);
    my $artist_id = $artist_ins->{id};

    my $cds = [
        {
        'Led Zeppelin' => [
            'GOOD TIMES BAD TIMES',
            'BABE I\'M GONNA LEAVE YOU',
            'YOU SHOOK ME',
            'DAZED AND CONFUSED',
            'YOUR TIME IS GONNA COME',
            'BLACK MOUNTAIN SIDE',
            'COMMUNICATION BREAKDOWN',
            'I CAN\'T QUIT YOU BABY',
            'HOW MANY MORE TIMES'
        ],
        },{
        'Led Zeppelin II' => [
            'WHOLE LOTTA LOVE',
            'WHAT IS AND WHAT SHOULD NEVER BE',
            'LEMON SONG,THE',
            'THANK YOU',
            'HEARTBREAKER',
            'LIVING LOVING MAID(SHE\'S JUST A WOMAN)',
            'RAMBLE ON',
            'MOBY DICK',
            'BRING IT ON HOME'
        ],
        },{
        'Led Zeppelin III' => [
            'IMMIGRANT SONG',
            'FRIENDS',
            'CELEBRATION DAY',
            'SINCE I\'VE BEEN LOVING YOU',
            'OUT ON THE TILES',
            'GALLOWS POLE',
            'TANGERINE',
            'THAT\'S THE WAY',
            'BRON-Y-AUR STOMP',
            'HATS OFF TO (ROY) HARPER'
        ],
        },{
        'Led Zeppelin IV' => [
            'BLACK DOG',
            'ROCK AND ROLL',
            'BATTLE OF EVERMORE,THE',
            'STAIRWAY TO HEAVEN',
            'MISTY MOUNTAIN HOP',
            'FOUR STICKS',
            'GOING TO CALIFORNIA',
            'WHEN THE LEVEE BREAKS'
        ],
        },{
        'Houses Of The Holy' => [
            'SONG REMAINS THE SAME,THE',
            'RAIN SONG,THE',
            'OVER THE HILLS AND FAR AWAY',
            'CRUNGE,THE',
            'DANCING DAYS',
            'D\'YER MAK\'ER',
            'NO QUARTER',
            'OCEAN,THE'
        ],
        },{
        'Physical Graffiti' => [
            'CUSTARD PIE',
            'ROVER,THE',
            'IN MY TIME OF DYING',
            'HOUSES OF THE HOLY',
            'TRAMPLED UNDER FOOT',
            'KASHMIR',
            'IN THE LIGHT',
            'BRON-YR-AUR',
            'DOWN BY THE SEASIDE',
            'THEN YEARS GONE',
            'NIGHT FLIGHT',
            'WANTON SONG,THE',
            'BOOGIE WITH STU',
            'BLACK COUNTRY WOMAN',
            'SICK AGAIN'
        ],
        },{
        'Presence' => [
            'ACHILLES LAST STAND',
            'FOR YOUR LIFE',
            'ROYAL ORLEANS',
            'NOBODY\'S FAULT BUT MINE',
            'CANDY STORE ROCK',
            'HOTS ON FOR NOWHERE',
            'TEA FOR ONE'
        ],
        },{
        'The Song Remains The Same' => [
            'ROCK AND ROLL',
            'CELEBRATION DAY',
            'BLACK DOG(INCLUDING BRING IT ON HOME)',
            'OVER THE HILLS AND FAR AWAY',
            'MISTY MOUNTAIN HOP',
            'SINCE I\'VE BEEN LOVING YOU',
            'NO QUARTER',
            'SONG REMAINS THE SAME,THE',
            'RAIN SONG',
            'OCEAN,THE',
            'DAZED AND CONFUSED',
            'STAIRWAY TO HEAVEN',
            'MOBY DICK',
            'HEARTBREAKER',
            'WHOLE LOTTA LOVE'
        ],
        },{
        'In Through The Out Door' => [
            'IN THE EVENING',
            'SOUTH BOUND SAUREZ',
            'FOOL IN THE RAIN',
            'HOT DOG',
            'CAROUSELAMBRA',
            'ALL MY LOVE',
            'I\'M GONNA CRAWL'
        ],
        },{
        'Coda' => [
            'WE\'RE GONNA GROOVE',
            'POOR TOM',
            'I CAN\'T QUIT YOU BABY',
            'WALTER\'S WALK',
            'OZONE BABY',
            'DARLENE',
            'BONZO\'S MONTREUX',
            'WEARING AND TEARING',
            'BABY COME ON HOME',
            'TRAVELLING RIVERSIDE BLUES',
            'WHITE SUMMER/BLACK MOUNTAIN SIDE',
            'HEY HEY WHAT CAN I DO'
        ]
        }
    ];

    for ( @$cds ) {
        my ($title, $tracks) = each %$_;

        my $cd_ins = $cd->insert->values(
            title     => $title,
            artist_id => $artist_id
        )->execute(['id']);

        my $cd_id = $cd_ins->{id};

        $linernote->insert->values(
            {
                id => $cd_id,
                note => $title . ' note',
            }
        )->execute();

        my $no = 1;
        for (@$tracks) {
            $track->insert->values(
                cd_id    => $cd_id,
                track_no => $no++,
                title    => $_,
            )->execute;
        }
    }

};



1;

