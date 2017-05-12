package App::QuoteCC::Input::Text;
BEGIN {
  $App::QuoteCC::Input::Text::AUTHORITY = 'cpan:AVAR';
}
BEGIN {
  $App::QuoteCC::Input::Text::VERSION = '0.10';
}

use 5.010;
use strict;
use warnings;
use Moose;
use namespace::clean -except => 'meta';

with qw/ App::QuoteCC::Role::Input /;

sub quotes {
    my ($self) = @_;
    my $handle = $self->file_handle;

    chomp(my @quotes = <$handle>);
    return \@quotes;
}

__PACKAGE__->meta->make_immutable;

=encoding utf8

=head1 NAME

App::QuoteCC::Input::Text - Read newline delimited quotes

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
