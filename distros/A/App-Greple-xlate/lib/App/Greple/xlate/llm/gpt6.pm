package App::Greple::xlate::llm::gpt6;

our $VERSION = "2.03";

=encoding utf-8

=head1 NAME

App::Greple::xlate::llm::gpt6 - GPT-6 Astra translation engine (llm backend) for greple xlate module

=head1 SYNOPSIS

    greple -Mxlate --xlate-engine=gpt6 --xlate=ja file.txt

=head1 DESCRIPTION

This module provides GPT-6 Astra translation support for the
App::Greple::xlate module, calling the model through the C<llm>
command line tool (L<https://llm.datasette.io/>).  Select it with
C<xlate -e gpt6 -t JA file.txt>.  Its cache files use the separate
C<*.xlate-gpt6-*.json> namespace.

The C<llm> command must be installed and must know the C<gpt-6-astra>
model (check with C<llm models | grep gpt-6-astra>).  If the call fails, this module
inspects the environment and reports what is missing.

This engine is context-aware: when re-translating changed blocks it
receives the surrounding source text, neighboring translation pairs,
and the previous version of the changed text, controlled by the
B<--xlate-context-window> option of L<App::Greple::xlate>.

=head1 CONFIGURATION

This engine uses the following defaults:

=over 4

=item * B<model>: gpt-6-astra

=item * B<reasoning_effort>: low (lowest effort supported by llm for GPT-6 Astra)

=item * B<max_length>: 3000 characters per batch

=back

No C<temperature> option is sent: GPT-6 Astra does not support this
parameter, and C<llm> only sends it when specified.

No C<max_tokens> option is sent either.  Omitting the cap leaves the
translation output naturally bounded by the input size and avoids
endpoint-specific output-token option differences.

No C<verbosity> option is sent.  The shared prompt requires a JSON
array with no commentary; omitting this option also supports custom
Responses models registered with C<llm 0.33>.

=head1 MODEL REGISTRATION

If C<llm models> does not list C<gpt-6-astra>, add the following entry
to C<extra-openai-models.yaml> in the C<llm> user directory (the directory
containing the path printed by C<llm logs path>).  Preserve any existing entries.

    - model_id: gpt-6-astra
      model_name: gpt-6-astra
      responses: true
      reasoning: true
      supports_schema: true

Check registration with C<llm models -m gpt-6-astra --options>.
Model registration does not grant API access; the API key must have
access to GPT-6 Astra.

=head1 ENVIRONMENT VARIABLES

=over 4

=item * B<OPENAI_API_KEY> - OpenAI API key, read by the C<llm> command.
Alternatively use C<llm keys set openai>.

=back

=head1 RELATED OPTIONS

=over 4

=item * B<--xlate-maxlen>=I<chars> - Maximum characters sent per request
(defaults to this engine's value of 3000 when unset)

=item * B<--xlate-maxline>=I<n> - Maximum lines sent per request
(default 0 = unlimited); useful as a safety valve if a large batch
causes a response element-count mismatch

=item * B<--xlate-debug> - Dump the C<llm> command and parameters

=back

=head1 DEPENDENCIES

=over 4

=item * L<App::Greple::xlate>

=item * C<llm> command (L<https://llm.datasette.io/>)

=item * L<Command::Run>, L<JSON>

=back

=head1 SEE ALSO

=over 4

=item * L<App::Greple::xlate>

=item * L<App::Greple::xlate::llm>

=item * L<App::Greple::xlate::llm::gpt5>

=item * L<https://developers.openai.com/api/docs/models/gpt-6-astra>

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use strict;
use warnings;
use utf8;

use App::Greple::xlate::llm;

App::Greple::xlate::llm::register_engine(__PACKAGE__,
    model   => 'gpt-6-astra',
    options => [ [ reasoning_effort => 'low' ] ],
);

1;

__DATA__

# set in &initialize()
# option default -Mxlate --xlate-engine=gpt6
