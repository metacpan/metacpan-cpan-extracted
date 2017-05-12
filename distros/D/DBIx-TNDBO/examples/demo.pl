#!/usr/bin/perl -Tw

use strict;
use warnings;
use DB qw( :dbname );
use Data::Dumper;

WORD:
for my $data (qw(
    mongoose
    ferret 
    hamster 
    cat 
    dog 
    bird 
    snake 
    lizard 
    monkey 
    elephant
)) {

    my $word_count = DB( { data => $data } );

    next WORD
        if $word_count > 5;

    my $word_dbo = DB();

    $word_dbo->set(
        {   data => $data,
            lang => 'en',
        }
    );
    my $id = $word_dbo->commit();

    print "$data id: $id\n";
}

my $word_itr = DB();

while ( my $word_dbo = $word_itr->next() ) {

    my $data = $word_dbo->get_data();

    my $anagram = join '', sort { -1 + int rand 3 } split //, $data;

    $word_dbo->set( $anagram );
    $word_dbo->commit();

    print "$word_dbo\n";
}

my @word_dbos = DB();

for my $word_dbo (@word_dbos) {

    my $data = $word_dbo->get();

    my $word_count = DB( { data => $data } );

    if ( 2 < $word_count ) {

        $word_dbo->delete();
        $word_dbo->commit();

        print "deleted a $data\n";
    }
    else {

        my %copy = (
            lang    => $word_dbo->get(),
            data    => $word_dbo->get(),
            anagram => $word_dbo->get(),
        );

        my $word_dbo = DB();
        $word_dbo->set( \%copy );
        $word_dbo->commit();
    }
}

__END__
