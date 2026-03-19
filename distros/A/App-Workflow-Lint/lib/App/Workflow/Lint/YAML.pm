package App::Workflow::Lint::YAML;

use strict;
use warnings;
use YAML::PP;

=head1 NAME

App::Workflow::Lint::YAML - YAML loader for GitHub Actions workflows

=head1 SYNOPSIS

  use App::Workflow::Lint::YAML;

  my ($data, $positions) =
      App::Workflow::Lint::YAML->load_yaml($yaml_text);

=head1 DESCRIPTION

C<App::Workflow::Lint::YAML> provides a lightweight YAML loader used by
the workflow linter. It loads YAML using L<YAML::PP> and returns the
parsed data structure.

Earlier versions attempted to extract line numbers from the YAML parser,
but this is no longer supported. The C<$positions> hashref is returned
for API compatibility and is always empty.

=head1 METHODS

=head2 load_yaml

  my ($data, $positions) = App::Workflow::Lint::YAML->load_yaml($yaml_text);

Parses the YAML string and returns the resulting Perl data structure.
The second return value is an empty hashref reserved for future use.

=cut

# ----------------------------------------------------------------------
# load_yaml
#
# Loads a GitHub Actions workflow YAML file/string and returns:
#   - $data : the parsed Perl structure
#   - {}    : an empty position map (line numbers removed)
#
# This keeps the API stable for callers that expect two return values,
# but no longer attempts to compute line numbers.
# ----------------------------------------------------------------------

sub load_yaml {
    my ($class, $yaml_text) = @_;

    my $ypp = YAML::PP->new;
    my $data = $ypp->load_string($yaml_text);

    # No line numbers available → return empty map
    my %positions;

    return ($data, \%positions);
}

1;
