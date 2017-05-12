use strict;
use warnings;
use Test::More;
use Data::TreeValidator::Sugar qw( leaf branch );
use Data::TreeValidator::Constraints qw( required );
use Data::TreeValidator::Transformations qw( boolean );

my $validator = branch {
    username    => leaf( constraints => [ required ] ),
    password    => leaf( constraints => [ required ] ),
    remember_me => leaf( transformations => [ boolean ] )
};

ok($validator->process({
    username => 'acid2',
    password => 'muffins',
})->valid);

ok($validator->process({
    username    => 'acid2',
    password    => 'muffins',
    remember_me => 1
})->valid);

is_deeply($validator->process({
    username    => 'acid2',
    password    => 'muffins',
    remember_me => 'nonsense',
})->clean, {
    username    => 'acid2',
    password    => 'muffins',
    remember_me => 1
});

done_testing;

