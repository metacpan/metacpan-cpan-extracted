package ClarID::Tools::Validator;
use strict;
use warnings;
use utf8;
use JSON::Validator;
use JSON::Validator::Schema;
use Term::ANSIColor qw(:constants);
use Exporter 'import';
our @EXPORT_OK = qw(validate_codebook _self_validate);

sub validate_codebook {
  my ($data, $schema, $debug) = @_;

  ClarID::Tools::Validator::_self_validate($schema) if $debug;

  my $jv = JSON::Validator->new;
  $jv->schema($schema);

  my @errors = $jv->validate($data);
  if (@errors) {
    _say_errors(\@errors);
    die "Codebook validation failed\n";
  }

  # Additional stub_code uniqueness validation (for all relevant entities/categories)
_validate_unique_stub_codes($data, 'biosample', $_)
  for qw(project species tissue sample_type assay timepoint);

_validate_unique_stub_codes($data, 'subject', $_)
  for qw(study type sex age_group);

  return 1;
}

sub _validate_unique_stub_codes {
  my ($data, $entity, $category) = @_;

  my $defs = $data->{entities}{$entity}{$category}
    or die "Missing category '$category' in entity '$entity'";

  my %seen;
  for my $key (keys %$defs) {
    my $def = $defs->{$key};
    next unless defined $def->{stub_code};
    my $sc = $def->{stub_code};

    if (exists $seen{$sc}) {
      die sprintf(
        "Duplicate stub_code '%s' in category '%s' (entity: '%s') for keys '%s' and '%s'\n",
        $sc, $category, $entity, $key, $seen{$sc}
      );
    }
    $seen{$sc} = $key;
  }
}

sub _self_validate {
  my ($schema) = @_;
  my $validator = JSON::Validator::Schema->new($schema);
  die "Invalid JSON Schema\nSee https://json-schema.org/" if $validator->is_invalid;
  print "Codebook Schema is OK\n";
}

sub _say_errors {
  my ($errors) = @_;
  print BOLD RED (join "\n", @$errors) , RESET "\n";
}

1;
