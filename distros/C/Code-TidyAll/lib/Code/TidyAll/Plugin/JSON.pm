package Code::TidyAll::Plugin::JSON;

use strict;
use warnings;

use JSON::MaybeXS ();
use Specio::Library::Builtins;

use Moo;

our $VERSION = '0.78';

extends 'Code::TidyAll::Plugin';

has ascii => (
    is      => 'ro',
    isa     => t('Bool'),
    default => 0,
);

sub transform_source {
    my $self   = shift;
    my $source = shift;

    my $json = JSON::MaybeXS->new(
        canonical => 1,
        pretty    => 1,
        relaxed   => 1,
        utf8      => 1,
    );

    $json = $json->ascii if $self->ascii;

    return $json->encode( $json->decode($source) );
}

1;

# ABSTRACT: Use the JSON::MaybeXS module to tidy JSON documents with tidyall

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Plugin::JSON - Use the JSON::MaybeXS module to tidy JSON
documents with tidyall

=head1 VERSION

version 0.78

=head1 SYNOPSIS

   In configuration:

   [JSON]
   select = **/*.json
   ascii = 1

=head1 DESCRIPTION

Uses L<JSON::MaybeXS> to format JSON files. Files are put into a canonical
format with the keys of objects sorted.

=head1 CONFIGURATION

This plugin accepts the following configuration options:

=head2 ascii

Escape non-ASCII characters. The output file will be valid ASCII.

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
