use strict;
use warnings;
use Test::Exception;
use Test::More;

use Catmandu::Importer::MARC;
use Catmandu::Validator::MARC;
use Catmandu qw(importer);

require_ok( 'Catmandu::Validator::MARC' );
can_ok('Catmandu::Validator::MARC', ('validate_data'));
# load default MARC schema
my $validator = Catmandu::Validator::MARC->new();

my $importer = Catmandu::Importer::MARC->new(
    file => 't/camel.mrc',
    type => "ISO"
);

my @errors;
$importer->each( sub {
    my $record = shift;
    unless($validator->validate($record)){
        push @errors, $_ for @{$validator->last_errors()};
    }
});

is (@errors, 1, 'got one error');
is ($errors[0]->{tag}, 100, 'error in field 100');

done_testing;