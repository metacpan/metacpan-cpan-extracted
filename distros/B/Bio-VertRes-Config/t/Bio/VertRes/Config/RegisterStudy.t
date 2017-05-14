#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;
use File::Slurp;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::RegisterStudy');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

ok(
    (
        my $obj = Bio::VertRes::Config::RegisterStudy->new(
            database            => 'my_database',
            study_name          => 'First Study',
            config_base => $destination_directory
        )
    ),
    'initialise study file which doesnt have any preexisting studies'
);
is($obj->study_file_name, $destination_directory.'/my_database/my_database.ilm.studies', 'Study name file constucted correctly');
ok(($obj->register_study_name), 'register the study name');
ok((-e $destination_directory.'/my_database/my_database.ilm.studies'), 'study names file exists');
my $text = read_file( $destination_directory.'/my_database/my_database.ilm.studies' );
chomp($text);
is($text, "First Study", 'Study is in file');

ok(
    (
        $obj = Bio::VertRes::Config::RegisterStudy->new(
            database            => 'my_database',
            study_name          => 'Another Study',
            config_base => $destination_directory
        )
    ),
    'initialise adding another study'
);
ok(($obj->register_study_name), 'register the study name');
ok((-e $destination_directory.'/my_database/my_database.ilm.studies'), 'study names file exists');
$text = read_file( $destination_directory.'/my_database/my_database.ilm.studies' );
chomp($text);
is($text, "First Study
Another Study", 'Study appended to the end of the file');

ok(
    (
        $obj = Bio::VertRes::Config::RegisterStudy->new(
            database            => 'my_database',
            study_name          => 'First Study',
            config_base => $destination_directory
        )
    ),
    'initialise adding the first study again'
);
ok(($obj->register_study_name), 'register the study name again');
ok((-e $destination_directory.'/my_database/my_database.ilm.studies'), 'study names file exists');
$text = read_file( $destination_directory.'/my_database/my_database.ilm.studies' );
chomp($text);
is($text, "First Study
Another Study", 'Study name is not added if it already exists');

done_testing();
