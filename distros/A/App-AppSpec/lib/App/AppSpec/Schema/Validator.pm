use strict;
use warnings;
package App::AppSpec::Schema::Validator;

our $VERSION = '0.002'; # VERSION

use App::Spec;
use File::Share qw/ dist_file /;
use YAML::XS;
use Moo;

sub validate_spec_file {
    my ($self, $file) = @_;
    my $spec = YAML::XS::LoadFile($file);
    return $self->validate_spec($spec);
}

sub validate_spec {
    my ($self, $spec) = @_;
    eval { require JSON::Validator }
        or die "JSON::Validator is needed for validating a spec file";
    my $file = dist_file("App-Spec", "schema.yaml");
    my $schema = YAML::XS::LoadFile($file);
    my $json_validator = JSON::Validator->new;
    $json_validator->schema($schema);
    my @errors = $json_validator->validate($spec);
    return @errors;
}

sub format_errors {
    my ($self, $errors) = @_;
    my $output = '';
    for my $error (@$errors) {
        $output .= "Path: " . $error->path . "\n";
        $output .= "    Message: " . $error->message . "\n";
    }
    return $output;
}

1;
