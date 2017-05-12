package App::QuoteCC::Output::C;
BEGIN {
  $App::QuoteCC::Output::C::AUTHORITY = 'cpan:AVAR';
}
BEGIN {
  $App::QuoteCC::Output::C::VERSION = '0.10';
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
                $text =~ s/"/\\"/g;
                my $was = $text;
                $text =~ s/\\(\$)/\\\\$1/g;
                given ($text) {
                    when (/\n/) {
                        return join(qq[\\n"\n], map { qq["$_] } split /\n/, $text). q["];
                    }
                    default {
                        return qq["$text"];
                    }
                }
            },
        },
        \$out
    );

    return $out;
}

__PACKAGE__->meta->make_immutable;

=encoding utf8

=head1 NAME

App::QuoteCC::Output::C - Emit quotes in C format

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__
__[ program ]__
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/time.h>

const char* const quotes[[% size %]] = {
[% FOREACH quote IN quotes
%]    [% escape(quote) %],
[% END
%]};

/* returns random integer between min and max, inclusive */
const int rand_range(const int min, const int max)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    const long int n = tv.tv_usec * getpid();
    srand(n);

    return (rand() % (max + 1 - min) + min);
}

const int main(const int argc, const char **argv)
{
    int i;
    const char* const all = "--all";
    const size_t all_length = strlen(all);

    if (argc == 2 &&
        strlen(argv[1]) == all_length &&
        !strncmp(argv[1], all, all_length)) {
        for (i = 0; i < [% size %]; i++) {
            puts(quotes[i]);
        }
    } else {
        const int quote = rand_range(0, [% size %]);
        puts(quotes[quote]);
    }

    return EXIT_SUCCESS;
}
