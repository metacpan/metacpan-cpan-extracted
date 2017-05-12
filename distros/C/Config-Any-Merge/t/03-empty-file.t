use strict;
use warnings;
use Test::More tests => 1;
use Config::Any::Merge;
use Config::Any::Perl;

my @files = glob 't/conf/empty-file/*';

my $result = Config::Any::Merge->load_files( { files => \@files, use_ext => 0, override => 1, force_plugins => [ 'Config::Any::Perl' ] } );


is_deeply($result->{bar}, 'quux',  'do not wipe config with missing or bad file');

0;
