package App::MigrateToTest2V0::CLI;
use strict;
use warnings;
use App::MigrateToTest2V0;
use Carp qw(croak);
use PPI;

sub process {
    my ($class, @argv) = @_;

    for my $filename (@argv) {
        croak "$filename not found" unless -e $filename;

        my $doc = PPI::Document->new($filename);
        my $migrated_doc = App::MigrateToTest2V0->apply($doc);
        $migrated_doc->save($migrated_doc->filename);
    }
}

1;
