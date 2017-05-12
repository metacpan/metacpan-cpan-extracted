package App::QuoteCC::Role::Output;
BEGIN {
  $App::QuoteCC::Role::Output::AUTHORITY = 'cpan:AVAR';
}
BEGIN {
  $App::QuoteCC::Role::Output::VERSION = '0.10';
}

use 5.010;
use strict;
use warnings;
use Moose::Role;
use namespace::clean -except => 'meta';

has file => (
    isa           => 'Str',
    is            => 'ro',
    documentation => 'The output file to compile to. - for STDOUT',
);

has quotes => (
    isa           => 'ArrayRef[Str]',
    is            => 'ro',
    documentation => 'The quotes to compile to',
);

sub file_handle {
    my ($self) = @_;
    my $file   = $self->file;

    given ($file) {
        when ('-') {
            binmode STDOUT, ":encoding(UTF-8)";
            return *STDOUT;
        }
        default {
            open my $fh, '>:encoding(UTF-8)', $file;
            return $fh;
        }
    }
}

requires 'output';

sub spew_output {
    my ($self, $out) = @_;

    given ($self->file) {
        when ('-') {
            binmode STDOUT;
            print $out;
        }
        default {
            open my $fh, ">", $_;
            binmode $fh;
            print $fh $out;
        }
    }

    return;
}

1;

=encoding utf8

=head1 NAME

App::QuoteCC::Role::Output - A role representing a L<App::QuoteCC> output format

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason.

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

