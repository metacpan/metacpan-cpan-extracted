package Catmandu::Fix::aat_search;

use strict;
use warnings;

use Catmandu::Sane;
use Moo;

use Catmandu::Fix::Has;
use Catmandu::Fix::Datahub::Util qw(declare_source);

with 'Catmandu::Fix::Base';

has path    => (fix_arg => 1);
has lang    => (fix_opt => 1, default => sub { 'nl' });

sub emit {
    my ($self, $fixer) = @_;
    my $perl = '';

    $perl .= 'use Catmandu::Store::AAT::API;';
    
    my $term = $fixer->generate_var();
    my $aat = $fixer->generate_var();

    $perl .= "my ${term};";
    $perl .= declare_source($fixer, $self->path, $term);

    $perl .= "my ${aat} = Catmandu::Store::AAT::API->new(term => ${term}, language => '".$self->lang."');";

    $perl .= $fixer->emit_create_path(
        $fixer->var,
        $fixer->split_path($self->path),
        sub {
            my $root = shift;
            my $code = '';

            $code .= "${root} = ${aat}->search();";

            return $code;
        }
    );

    return $perl;
}

1;
__END__

=encoding utf-8

=head1 NAME

Catmandu::Fix::aat_search - Perform a search for a term in the AAT

=head1 SYNOPSIS

  aat_search(
      path,
      -lang: nl
  )

=head1 DESCRIPTION

Perform a search for a term and the L<SPARQL endpoint|http://vocab.getty.edu/sparql> of the AAT.
This fix will attempt to find a I<Subject> that contains a I<prefLabel>, I<altLabel> or a
I<Subject ID> containing the searched for term. More details can be found L<here|http://vocab.getty.edu/doc/#Full_Text_Search>
(C<luc:term> is used).

Returns an array of results containing the following data:

  {
    'id'        => 'The dc:identifier of the Subject',
    'prefLabel' => 'The prefLabel in the provided language',
    'uri'       => 'The URI of the Subject'
  }

=head2 PARAMETERS

=head3 Required parameters

=over

=item C<path>

Path to the term.

=back

=head3 Optional parameters

=over

=item C<lang>

Language of both the I<term> that is matched and the I<prefLabel> that is returned.

=back

=head1 AUTHOR

Pieter De Praetere E<lt>pieter at packed.be E<gt>

=head1 COPYRIGHT

Copyright 2017- PACKED vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catmandu>
L<Catmandu::Store::AAT>
L<Catmandu::Fix::aat_search>

=cut

