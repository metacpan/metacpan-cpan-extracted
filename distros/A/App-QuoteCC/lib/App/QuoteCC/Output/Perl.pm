package App::QuoteCC::Output::Perl;
BEGIN {
  $App::QuoteCC::Output::Perl::AUTHORITY = 'cpan:AVAR';
}
BEGIN {
  $App::QuoteCC::Output::Perl::VERSION = '0.10';
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
            repeat => sub {
                my ($s, $c) = @_;
                $c += 4;
                return scalar $s x $c;
            },
        },
        \$out
    );

    return $out;
}

__PACKAGE__->meta->make_immutable;

=encoding utf8

=head1 NAME

App::QuoteCC::Output::Perl - Emit quotes in Perl format

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__
__[ program ]__
#!/usr/bin/env perl

if (@ARGV && $ARGV[0] eq '--all') {
    print for @QUOTES;
} else {
    print $QUOTES[rand @QUOTES];
}

BEGIN { our @QUOTES = ([% FOREACH quote IN quotes %]<<'----[% loop.count %]----8========D',[% END %]); }
[% FOREACH quote IN quotes %][% quote %]
----[% loop.count %]----8========D[% UNLESS loop.last %]
[% END %][% END %]
