package Catmandu::Fix::viaf_match;

use strict;
use warnings;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;

use Catmandu::Util qw(:is);
use Catmandu::Fix::Datahub::Util qw(declare_source);

has path          => (fix_arg => 1);
has lang          => (fix_opt => 1, default => sub {'nl-NL'});
has fallback_lang => (fix_opt => 1, default => sub {'en-US'});

sub emit {
    my ($self, $fixer) = @_;
    my $perl = '';

    $perl .= 'use Catmandu::VIAF::API;';

    my $name = $fixer->generate_var();
    my $viaf = $fixer->generate_var();

    $perl .= "my ${name};";
    $perl .= declare_source($fixer, $self->path, $name);

    $perl .= "my ${viaf} = Catmandu::VIAF::API->new(term => ${name}, lang => '".$self->lang."');";

    $perl .= $fixer->emit_create_path(
        $fixer->var,
        $fixer->split_path($self->path),
        sub {
            my $root = shift;
            my $code = '';

            $code .= "${root} = ${viaf}->match();";

            return $code;
        }
    );

    return $perl;
}

1;
__END__

=encoding utf-8

=head1 NAME

=for html <a href="https://travis-ci.org/thedatahub/Catmandu-VIAF"><img src="https://travis-ci.org/thedatahub/Catmandu-VIAF.svg?branch=master"></a>

Catmandu::Fix::viaf_match - Perform a direct match between a name and a mainHeadingEl from VIAF

=head1 SYNOPSIS

  viaf_match(authorName, -lang:'nl-NL', -fallback_lang:'en-US')


=head1 DESCRIPTION

Perform a direct match between a name and a I<mainHeadingEl> and the
I<local.personalNames> of a I<Person> in VIAF. The fix will return
the I<prefLabel> in the provided C<lang>, or C<fallback_lang> if one
in C<lang> does not exist. If C<fallback_lang> also doesn't exist, the
I<prefLabel> will be empty.

Returns the following data:

  {
    'dcterms:identifier' => 'The identifier',
    'guid'               => 'The VIAF URL',
    'schema:birthDate'   => 'Birth date, if provided',
    'schema:deathDate'   => 'Death date, if provided',
    'schema:description' => 'Description, if provided',
    'skos:prefLabel'     => 'prefLabel, in lang or fallback_lang'
  }

=head2 PARAMETERS

=head3 Required parameters

=over

=item C<path>

Path to the name.

=back

=head3 Optional parameters

=over

=item C<lang>

Language of the returned C<skos:prefLabel>. Falls back to
C<fallback_lang> if none was found. Use L<IETF language tags|https://en.wikipedia.org/wiki/IETF_language_tag>.

=item C<fallback_lang>

Fallback language.

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
L<Catmandu::VIAF>
L<Catmandu::Store::VIAF>
L<Catmandu::Fix::viaf_search>

=cut
