package App::Greple::xlate::llm::gpt5;

our $VERSION = "2.03";

=encoding utf-8

=head1 NAME

App::Greple::xlate::llm::gpt5 - GPT-5.6 Terra translation engine (llm backend) for greple xlate module

=head1 SYNOPSIS

    greple -Mxlate --xlate-engine=gpt5 --xlate=ja file.txt

=head1 DESCRIPTION

This module provides GPT-5.6 Terra translation support for the
App::Greple::xlate module, calling the model through the C<llm>
command line tool (L<https://llm.datasette.io/>) instead of the
older C<gpty> command.  The engine name, translation prompt, and
cache files (C<*.xlate-gpt5-*.json>) are fully compatible with the
gpty backend engine L<App::Greple::xlate::gpty::gpt5>.

The C<llm> command must be installed and must know the C<gpt-5.6-terra>
model (check with C<llm models | grep gpt-5.6-terra>).  If the call fails, this module
inspects the environment and reports what is missing.

This engine is context-aware: when re-translating changed blocks it
receives the surrounding source text, neighboring translation pairs,
and the previous version of the changed text, controlled by the
B<--xlate-context-window> option of L<App::Greple::xlate>.

=head1 CONFIGURATION

This engine uses the following defaults:

=over 4

=item * B<model>: gpt-5.6-terra

=item * B<reasoning_effort>: low (lowest effort supported by llm for GPT-5.6 Terra)

=item * B<verbosity>: low

=item * B<max_length>: 3000 characters per batch

=back

No C<temperature> option is sent: reasoning models reject non-default
temperatures, and C<llm> only sends the option when specified.

No C<max_tokens> option is sent either.  Omitting the cap leaves the
translation output naturally bounded by the input size and avoids
endpoint-specific output-token option differences.

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

=item * B<--xlate-setopt backend=gpty> - Force the old gpty backend
engine for comparison

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

=item * L<App::Greple::xlate::gpty::gpt5>

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
    model   => 'gpt-5.6-terra',
    options => [ [ reasoning_effort => 'low' ],
                 [ verbosity        => 'low' ] ],
);

1;

__DATA__

# set in &initialize()
# option default -Mxlate --xlate-engine=gpt5
