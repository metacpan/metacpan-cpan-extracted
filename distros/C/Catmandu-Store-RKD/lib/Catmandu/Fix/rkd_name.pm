package Catmandu::Fix::rkd_name;

use strict;

use Catmandu::Sane;
use Moo;

use Catmandu::Fix::Has;
use Catmandu::Fix::Datahub::Util qw(declare_source);

with 'Catmandu::Fix::Base';

has path     => (fix_arg => 1);

sub emit {
    my ($self, $fixer) = @_;
    my $perl = '';

    $perl .= 'use Catmandu::Store::RKD::API::Name;';

    my $name = $fixer->generate_var();
    my $rkd = $fixer->generate_var();

    $perl .= "my ${name};";
    $perl .= declare_source($fixer, $self->path, $name);

    $perl .= "my ${rkd} = Catmandu::Store::RKD::API::Name->new(name_to_search => ${name});";

    $perl .= $fixer->emit_create_path(
        $fixer->var,
        $fixer->split_path($self->path),
        sub {
            my $root = shift;
            my $code = '';
            $code .= "${root} = ${rkd}->results;";

            return $code;
        }
    );

    return $perl;
}

1;
__END__

=head1 NAME

Catmandu::Fix::rkd_name - Retrieve items from the RKD by name

=head1 SYNOPSIS

A fix to retrieve a RKD record based on an artist name.

=head1 DESCRIPTION

The fix takes a name (first name, last name or a combination) and performs a lookup to the RKD artists database. It 
returns an array of results. Every result is of the form:

    {
        'title'       => 'Name of the person',
        'description' => 'Short description, as provided by RKD',
        'artist_link' => 'Link to the artist using the artist id',
        'guid'        => 'Permalink to the record'
    }

For some names, it can/will return multiple possibilities. You must determine yourself which one is the 'correct' one.

=head1 SEE ALSO

L<Catmandu>
L<Catmandu::Store::RKD>

=head1 AUTHORS

Pieter De Praetere, C<< pieter at packed.be >>

=head1 CONTRIBUTORS

Pieter De Praetere, C<< pieter at packed.be >>

=head1 COPYRIGHT AND LICENSE

This package is copyright (c) 2016 by PACKED vzw.
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut