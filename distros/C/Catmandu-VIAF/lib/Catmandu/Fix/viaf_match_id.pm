package Catmandu::Fix::viaf_match_id;

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

    my $id = $fixer->generate_var();
    my $viaf = $fixer->generate_var();

    $perl .= "my ${id};";
    $perl .= declare_source($fixer, $self->path, $id);

    $perl .= "my ${viaf} = Catmandu::VIAF::API->new(term => ${id}, lang => '".$self->lang."');";

    $perl .= $fixer->emit_create_path(
        $fixer->var,
        $fixer->split_path($self->path),
        sub {
            my $root = shift;
            my $code = '';

            $code .= "${root} = ${viaf}->id();";

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

Catmandu::Fix::viaf_match_id - Fetch the RDF representation of a person based on his/her VIAF ID.

=head1 SYNOPSIS

  viaf_match_id(path)

=head1 DESCRIPTION

Perform a direct match between a VIAF ID and a I<mainHeadingEl> and the
I<local.personalNames> of a I<Person> in VIAF.

=head2 PARAMETERS

=head3 Required parameters

=over

=item C<path>

Path to the VIAF ID.

=back

=head1 AUTHOR

Matthias Vandermaesne <lt>matthias dot vandermaesen at vlaamsekunstcollectie dot be E<gt>

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

