#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Data::Dataset::Classic::Titanic';

my $file = Data::Dataset::Classic::Titanic::as_file();
ok -e $file, 'file exists';

my @data = Data::Dataset::Classic::Titanic::headers();
ok @data, 'headers data';
is_deeply \@data, [qw(
    PassengerId Survived Pclass Name Sex Age SibSp Parch Ticket Fare Cabin Embarked
)], 'headers';

@data = Data::Dataset::Classic::Titanic::as_list();
ok @data, 'as_list data';
is $data[0][3], 'Braund, Mr. Owen Harris', 'row';

my %data = Data::Dataset::Classic::Titanic::as_hash();
ok keys(%data), 'as_hash data';
is $data{Name}[0], 'Braund, Mr. Owen Harris', 'datum';

done_testing();
