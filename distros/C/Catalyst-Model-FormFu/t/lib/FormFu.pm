package FormFu;

use strict;
use warnings;


use Catalyst::Runtime 5.80;
use FindBin     qw();
use Path::Class qw(file dir);
use parent      qw(Catalyst);
use Catalyst    qw(Static::Simple);

use Books;

our $VERSION = '0.01';

__PACKAGE__->config(

    name => 'FormFu',

    'View::TT' => {
        TEMPLATE_EXTENSION => '.tt',
        INCLUDE_PATH => dir( $FindBin::Bin, qw( .. root tmpl ) ),
        CATALYST_VAR => 'c',
    },

    'Model::Books' => {
        schema_class => 'Books',
        connect_info => sub
        {
            my $schema = Books->connect('dbi:SQLite:dbname=:memory:', undef, undef, { RaiseError => 1 });
            $schema->deploy;
            $schema->populate( 'Genre', [
                [qw( id name fiction )],
                [ 1,  "Children's",              1 ],
                [ 2,  "Fantasy",                 1 ],
                [ 3,  "Horror",                  1 ],
                [ 4,  "Mystery",                 1 ],
                [ 5,  "Romance",                 1 ],
                [ 6,  "Science Fiction",         1 ],
                [ 7,  "Short Fiction",           1 ],
                [ 8,  "Thriller/Suspense",       1 ],
                [ 9,  "Essay",                   0 ],
                [ 10, "Journal",                 0 ],
                [ 11, "History",                 0 ],
                [ 12, "Scientific Paper",        0 ],
                [ 13, "Biography",               0 ],
                [ 14, "Textbook",                0 ],
                [ 15, "Travel Book",             0 ],
                [ 16, "Technical Documentation", 0 ],
            ]);

            return $schema->storage->dbh;
        },
    },

    'Model::FormFu' => {
        model_stash => { schema => 'Books' },
        constructor => { config_file_path => dir( $FindBin::Bin, qw( root forms ) )->stringify },
        forms       => { author => 'author.conf', book => 'book.conf' },
    },

);

__PACKAGE__->setup();

1;
