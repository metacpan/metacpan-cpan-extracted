use strict;
use warnings;
package App::AppSpec::Schema::Validator;

our $VERSION = '0.003'; # VERSION

use App::Spec;
use File::Share qw/ dist_file /;
use YAML::PP;
use Moo;

sub validate_spec_file {
    my ($self, $file) = @_;
    my $yp = YAML::PP->new( boolean => 'JSON::PP', schema => [qw/ JSON /] );
    my $spec = $yp->load_file($file);
    return $self->validate_spec($spec);
}

sub validate_spec {
    my ($self, $spec) = @_;
    eval { require JSON::Validator }
        or die "JSON::Validator is needed for validating a spec file";
    my $schema_file = dist_file("App-Spec", "schema.yaml");
    my $json_validator = JSON::Validator->new;
    my $yp = YAML::PP->new( boolean => 'JSON::PP', schema => [qw/ JSON /] );
    my $schema = $yp->load_file($schema_file);
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
