use strict;
use warnings;
use Test::More;
use Test::Exception;
use BusyBird::Input::Feed;


my @ALL_METHODS = qw(parse parse_string parse_file parse_url parse_uri);

my @testcases = (
    {label => "undef", methods => \@ALL_METHODS,
     args => [undef]},
    {label => "empty string", methods => \@ALL_METHODS,
     args => [""]},
    {label => "non-existent filename", methods => \@ALL_METHODS,
     args => ["this_should_not_exist.txt"]}
);

my $input = BusyBird::Input::Feed->new(use_favicon => 0);

foreach my $case (@testcases) {
    foreach my $method (@{$case->{methods}}) {
        my $label = "$case->{label}, $method";
        dies_ok { $input->$method(@{$case->{args}}) } "$label: dies OK";
        note("Error msg: $@");
    }
}

done_testing;

