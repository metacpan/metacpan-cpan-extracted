package CSAF::Schema;

use 5.010001;
use strict;
use warnings;
use utf8;

use CSAF::Util qw(schema_cache_path);
use JSON::Validator;


our %SCHEMAS = (
    'csaf-2.0'            => 'https://docs.oasis-open.org/csaf/csaf/v2.0/os/schemas/csaf_json_schema.json',
    'strict-csaf-2.0'     => 'https://docs.oasis-open.org/csaf/csaf/v2.0/os/schemas/csaf_json_schema.json?strict',
    'csaf-2.0-provider'   => 'https://docs.oasis-open.org/csaf/csaf/v2.0/os/schemas/provider_json_schema.json',
    'csaf-2.0-aggregator' => 'https://docs.oasis-open.org/csaf/csaf/v2.0/os/schemas/aggregator_json_schema.json',

    'cvss-v3.1' => 'https://www.first.org/cvss/cvss-v3.1.json',
    'cvss-v3.0' => 'https://www.first.org/cvss/cvss-v3.0.json',
    'cvss-v2.0' => 'https://www.first.org/cvss/cvss-v2.0.json',

    'cvss-v3.x' => {
        oneOf => [
            {'$ref' => 'https://www.first.org/cvss/cvss-v3.0.json'},
            {'$ref' => 'https://www.first.org/cvss/cvss-v3.1.json'}
        ]
    }
);

sub validator {

    my ($class, $schema) = @_;

    my $jv = JSON::Validator->new;

    $jv->cache_paths([schema_cache_path]);
    $jv->schema($SCHEMAS{$schema} || $schema);

    return $jv;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Schema - "JSON::Validator" wrapper

=head1 SYNOPSIS

    use CSAF::Schema;

    my $schema = CSAF::Schema->validator('strict-csaf-2.0');
    my @errors = $schema->validate($data);


=head1 DESCRIPTION

L<CSAF::Schema> is a wrapper for L<JSON::Validator>.


=head2 METHODS

=over

=item validator

Load the provided schema (ID, URL or hash) and return L<JSON::Validator> object.

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-CSAF/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-CSAF>

    git clone https://github.com/giterlizzi/perl-CSAF.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
