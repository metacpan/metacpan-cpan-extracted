package App::MCP::CLI::Command::call;

use strict;
use warnings;
use version;

our $VERSION   = qv('v0.0.1');
our $AUTHORITY = 'cpan:MANWAR';

use App::MCP::CLI -command;

use JSON::MaybeXS;
use App::MCP::CLI::Client qw(content_text);
use App::MCP::CLI::Config qw(load_config resolve_server_cmd);

=encoding utf8

=head1 NAME

App::MCP::CLI::Command::call - Invoke a specific tool on an MCP server

=head1 VERSION

This module is distributed as part of L<App::MCP::CLI> v0.0.1.

=head1 SYNOPSIS

    # Invoke a tool with inline key=value arguments
    mcpcli call add_numbers --server perl-math-server a=10 b=5

    # Invoke a tool and be prompted for each argument
    mcpcli call add_numbers --server perl-math-server

    # Against a script, a raw command, or an SSE URL
    mcpcli call add_numbers --server ./stdio_server.pl a=3 b=4
    mcpcli call get_mock_weather --server http://localhost:8080/sse location=London

=head1 DESCRIPTION

C<App::MCP::CLI::Command::call> implements the C<call> sub-command of the
C<mcpcli> application.  It connects to an MCP server over stdio or HTTP/SSE
(through L<App::MCP::CLI::Client>), performs the handshake, and dispatches a
C<tools/call> request.

=head2 Argument handling

Arguments are supplied on the command line as C<key=value> pairs after the
tool name. Anything that is not a C<key=value> pair is a usage error.

    mcpcli call mytool param1=hello param2=42

The command asks the server for the tool's input schema and uses it to give
each value the right JSON type:

=over 4

=item * C<string> properties are always sent as strings, so C<007> stays
C<"007"> and C<1.0> stays C<"1.0">.

=item * C<integer> and C<number> properties are sent as numbers when the
value looks numeric.

=item * C<boolean> properties accept C<true/false>, C<yes/no> and C<1/0>.

=item * C<array> and C<object> properties are parsed as JSON.

=item * Properties without a declared type (or tools whose schema is not
available) fall back to a conservative rule: plain decimal numbers without
leading zeros become JSON numbers, everything else stays a string.

=back

Required properties that were not supplied cause an error before anything is
sent to the server.

When no arguments are given at all, the command enters an B<interactive
prompt mode>: it presents each property of the tool's schema in the terminal
(prompts go to STDERR), labelling required fields in red when STDERR is a
terminal. Entering an empty value for a required field aborts with an error.

=head2 Output

Only the tool's result is written to STDOUT, so it can be piped. Text blocks
are printed as-is. Other block types are not dropped: images and audio become
a one-line placeholder with their MIME type and size, resources are printed
(or described), and C<structuredContent> is pretty-printed when there is no
other content. Progress messages and errors go to STDERR.

=head2 Exit status

=over 4

=item C<0> - the tool ran and reported success.

=item C<1> - connection or configuration failure, timeout, unknown tool,
missing argument, a JSON-RPC error from the server, or a tool result with
C<isError: true> (its text is printed to STDERR).

=back

=head1 USAGE

    mcpcli call <tool_name> [key=value ...] [--server <name|path|url|command>]
                [--config <file>] [--timeout <seconds>]

=head1 OPTIONS

=over 4

=item C<--server|-s> I<name>

Server name from the config file, a C<.pl> script, a URL, or a command. May be
omitted when the config file defines exactly one server.

=item C<--config|-c> I<path>

Path to the JSON configuration file. See L<App::MCP::CLI::Config>.

=item C<--timeout|-t> I<seconds>

How long to wait for each server reply (default 30; C<0> waits forever).

=back

=head1 INTERNAL METHODS

=head2 opt_spec

Defines the command-line option specification passed to L<Getopt::Long::Descriptive>
via L<App::Cmd>.

=cut

sub opt_spec {
    return (
        [ 'server|s=s',  'server name, script path, URL or command'            ],
        [ 'config|c=s',  'path to config JSON file'                            ],
        [ 'timeout|t=i', 'seconds to wait for the server (0 = forever)',
                         { default => 30 }                                      ],
    );
}

=head2 description

Returns a one-line human-readable description of the command, used in the
top-level C<mcpcli help> listing.

=cut

sub description { 'Call/execute a specific tool on the server'  }

=head2 usage_desc

Returns the usage string shown by C<mcpcli help call>.

=cut

sub usage_desc  { '%c call <tool_name> [key=value key2=value2]' }

=head2 validate_args

Validates that a tool name was supplied and that every further argument is a
C<key=value> pair; calls C<usage_error> otherwise.

=cut

sub validate_args {
    my ($self, $opt, $args) = @_;

    $self->usage_error("You must specify a tool name to call.")
        if !@$args;

    my (undef, @pairs) = @$args;
    foreach my $arg (@pairs) {
        $self->usage_error("Invalid argument '$arg': expected key=value.")
            if $arg !~ /^[^=]+=/;
    }
}

=head2 execute( $opt, $args )

Main entry point invoked by L<App::Cmd>.  Connects to the configured MCP
server, performs the protocol handshake, collects tool arguments (inline or
interactively), submits the C<tools/call> request, and prints the response.

=cut

sub execute {
    my ($self, $opt, $args) = @_;

    my ($tool_name, @pairs) = @$args;
    my %raw = map { /^([^=]+)=(.*)$/s ? ($1 => $2) : () } @pairs;

    my $status = eval { $self->_run($opt, $tool_name, \%raw, scalar @pairs) };
    if (my $err = $@) {
        $err .= "\n" unless $err =~ /\n\z/;
        print STDERR "Error: $err";
        exit 1;
    }

    exit $status if $status;
}

sub _label {
    my ($text, $code) = @_;
    return -t STDERR ? "\e[${code}m$text\e[0m" : $text;
}

sub _run {
    my ($self, $opt, $tool_name, $raw, $npairs) = @_;

    my $config_data       = load_config($opt->config);
    my ($cmd, $url, $env) = resolve_server_cmd($config_data, $opt->server);

    my $client = App::MCP::CLI::Client->new(
        cmd => $cmd, url => $url, env => $env, timeout => $opt->timeout,
    );
    $client->connect;

    my $status = eval { $self->_call($client, $tool_name, $raw, $npairs) };
    my $err    = $@;
    $client->close;
    die $err if $err;

    return $status;
}

sub _call {
    my ($self, $client, $tool_name, $raw, $npairs) = @_;

    # Servers that do not implement tools/list can still be called directly.
    my $tools = eval { $client->list_tools } || [];
    my ($tool) = grep { ($_->{name} // '') eq $tool_name } @$tools;

    if (@$tools && !$tool) {
        print STDERR "Error: Tool '$tool_name' not found on server. Available: "
                   . join(', ', map { $_->{name} // () } @$tools) . "\n";
        return 1;
    }

    my $schema   = $tool ? ($tool->{inputSchema} || {}) : {};
    my $props    = ref $schema->{properties} eq 'HASH'  ? $schema->{properties} : {};
    my %required = map { $_ => 1 }
                   @{ ref $schema->{required} eq 'ARRAY' ? $schema->{required} : [] };

    my %tool_args;

    if ($npairs) {
        $tool_args{$_} = _coerce_value($raw->{$_}, $props->{$_}) for keys %$raw;

        my @missing = grep { !exists $tool_args{$_} } sort keys %required;
        if (@missing) {
            print STDERR "Error: Missing required argument(s): " . join(', ', @missing) . "\n";
            return 1;
        }
    }
    elsif (keys %$props) {
        print STDERR "\nEntering interactive prompt for '$tool_name':\n";
        foreach my $key (sort keys %$props) {
            my $prop = $props->{$key};
            my $desc = $prop->{description} // 'No description';
            my $type = $prop->{type} // 'string';
            $type    = join('|', @$type) if ref $type eq 'ARRAY';
            my $req  = $required{$key} ? _label('(required)', '1;31') : '(optional)';

            print STDERR "=> $key $req [$type - $desc]: ";

            my $input = <STDIN>;
            defined($input) ? chomp($input) : ($input = '');

            if ($input eq '' && $required{$key}) {
                print STDERR _label("Error: $key is required!", '1;31') . "\n";
                return 1;
            }

            $tool_args{$key} = _coerce_value($input, $prop) if $input ne '';
        }
        print STDERR "\n";
    }

    print STDERR "[-] Calling tool '$tool_name'...\n";
    my $res = $client->call_tool($tool_name, \%tool_args);

    if (my $e = $res->{error}) {
        my $code = defined $e->{code} ? " (code $e->{code})" : '';
        print STDERR _label('Error:', '1;31') . " " . ($e->{message} // 'unknown error') . "$code\n";
        return 1;
    }

    my $result = $res->{result} || {};
    my $text   = content_text($result);

    if ($result->{isError}) {
        print STDERR _label('Error:', '1;31') . " "
                   . (length $text ? $text : 'the tool reported an error') . "\n";
        return 1;
    }

    print "$text\n" if length $text;
    return 0;
}

=head2 _coerce_value( $value, $property_schema )

Plain function (not a method). Converts the command-line string C<$value> to
the JSON type declared by C<$property_schema> (the property's entry in the
tool's C<inputSchema>, may be C<undef>). See L</Argument handling> for the
rules. Values that do not fit the declared type are passed through unchanged
so that the server can report a precise validation error.

=cut

sub _coerce_value {
    my ($val, $prop) = @_;

    my $type = ref $prop eq 'HASH' ? $prop->{type} : undef;
    $type = (grep { defined && $_ ne 'null' } @$type)[0] if ref $type eq 'ARRAY';
    $type //= '';

    # Numbers with more than 15 digits would lose precision as a Perl NV.
    my $safe = sub { length($_[0] =~ s/\D//gr) <= 15 };

    if ($type eq 'string')  { return $val }

    if ($type eq 'integer') {
        return ($val =~ /^-?\d+$/ && $safe->($val)) ? 0 + $val : $val;
    }

    if ($type eq 'number') {
        return ($val =~ /^-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?$/ && $safe->($val)) ? 0 + $val : $val;
    }

    if ($type eq 'boolean') {
        return JSON::MaybeXS::true()  if $val =~ /^(?:true|yes|1)$/i;
        return JSON::MaybeXS::false() if $val =~ /^(?:false|no|0)$/i;
        return $val;
    }

    if ($type eq 'array' || $type eq 'object') {
        my $data = eval { JSON::MaybeXS->new(utf8 => 0, allow_nonref => 1)->decode($val) };
        return ref $data ? $data : $val;
    }

    # Unknown type: only plain decimals without leading zeros are numbers.
    return 0 + $val if $val =~ /^-?(?:0|[1-9]\d*)(?:\.\d+)?$/ && $safe->($val);
    return $val;
}

=head1 SEE ALSO

=over 4

=item * L<App::MCP::CLI>

=item * L<App::MCP::CLI::Command::list>

=item * L<App::MCP::CLI::Command::interactive>

=back

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/App-MCP-CLI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/App-MCP-CLI/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::MCP::CLI

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/App-MCP-CLI/issues>

=item * Search MetaCPAN

L<http://metacpan.org/dist/App-MCP-CLI>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of App::MCP::CLI::Command::call
