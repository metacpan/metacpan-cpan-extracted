use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Data::DynamicValidator qw/validator/;

my $data = {
    n1 => 3,
    o2 => 4,
    n4 => 5,
};

my $errors = validator($data)->(
    on      => "/`*[key =~ /^o.+/]`",
    should  => sub { @_ && $_[0] >= 30 },
    because => "...",
)->errors;

is @$errors, 1, "got 1 error as expected";
is $errors->[0]->path, "/o2", "path has been expanded";

done_testing;
