package App::QuoteCC::Output::Lua;
BEGIN {
  $App::QuoteCC::Output::Lua::AUTHORITY = 'cpan:AVAR';
}
BEGIN {
  $App::QuoteCC::Output::Lua::VERSION = '0.10';
}

use 5.010;
use strict;
use warnings;
use Moose;
use Template;
use Data::Section qw/ -setup /;
use namespace::clean -except => [ qw/ meta merged_section_data section_data / ];

with qw/ App::QuoteCC::Role::Output /;

has template => (
    isa           => 'Str',
    is            => 'ro',
    lazy_build    => 1,
    documentation => "The Template template to emit",
);

sub _build_template {
    my ($self) = @_;
    my $template = $self->section_data( 'program' );
    return $$template;
}

sub output {
    my ($self) = @_;
    my $handle = $self->file_handle;

    # Get output
    my $out  = $self->_process_template;

    # Spew output
    $self->spew_output($out);

    return;
}

sub _process_template {
    my ($self) = @_;
    my $quotes = $self->quotes;
    my $template = $self->template;
    my $out;

    Template->new->process(
        \$template,
        {
            quotes => $quotes,
            size => scalar(@$quotes),
            escape => sub {
                my $text = shift;
                return "[===[$text]===]";
            },
        },
        \$out
    );

    return $out;
}

__PACKAGE__->meta->make_immutable;

=encoding utf8

=head1 NAME

App::QuoteCC::Output::Lua - Emit quotes in Lua format

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

Copyright 2010 Hinrik E<Ouml>rn SigurE<eth>sson <hinrik.sig@gmail.com>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__
__[ program ]__
#!/usr/bin/env lua

require 'posix'

local quotes = {[%
FOREACH quote IN quotes %]
    [% escape(quote) %],[%
END %]
}

if arg[1] == "--all" then
    print(table.concat(quotes, "\n"))
else
    local pid = posix.getpid("pid")
    local time = os.time();
    math.randomseed(time * pid)
    print(quotes[math.random(#quotes)])
end
