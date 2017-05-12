use strict;
use warnings;
use Test::More tests => 1;
use File::Share qw/ dist_file /;
use App::AppSpec;
use App::AppSpec::Schema::Validator;
my $validator = App::AppSpec::Schema::Validator->new;
my $specfile = dist_file("App-AppSpec", "appspec-spec.yaml");

for my $file ($specfile) {
    my @errors = $validator->validate_spec_file($file);
    is(scalar @errors, 0, "spec $file is valid");
    if (@errors) {
        diag $validator->format_errors(\@errors);
    }
}

