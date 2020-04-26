package Code::TidyAll::Config::INI::Reader;

use strict;
use warnings;

use base qw(Config::INI::Reader);

our $VERSION = '0.78';

my %multi_value = map { $_ => 1 } qw( ignore inc ok_exit_codes select shebang );

sub set_value {
    my ( $self, $name, $value ) = @_;

    if ( $multi_value{$name} ) {
        $value =~ s/^\s+|\s+$//g;
        push @{ $self->{data}{ $self->current_section }{$name} }, split /\s+/, $value;
        return;
    }

    die qq{cannot list multiple config values for '$name'}
        if exists $self->{data}{ $self->current_section }{$name};

    $self->{data}{ $self->current_section }{$name} = $value;
}

1;

# ABSTRACT: A L<Config::INI::Reader> subclass which can handle a key appearing more than once

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Config::INI::Reader - A L<Config::INI::Reader> subclass which
can handle a key appearing more than once

=head1 VERSION

version 0.78

=head1 SUPPORT

Bugs may be submitted at
L<https://github.com/houseabsolute/perl-code-tidyall/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Code-TidyAll can be found at
L<https://github.com/houseabsolute/perl-code-tidyall>.

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2020 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

The full text of the license can be found in the F<LICENSE> file included with
this distribution.

=cut
