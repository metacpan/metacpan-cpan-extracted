use 5.008;
use strict;
use warnings;

package Data::Conveyor::Charset::ViaHash;
BEGIN {
  $Data::Conveyor::Charset::ViaHash::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use charnames ':full';
use parent 'Data::Conveyor::Charset';
__PACKAGE__->mk_constructor(qw(new))->mk_hash_accessors(qw(character_cache))
  ->mk_scalar_accessors(qw(valid_string_re_cache));
sub CHARACTERS { () }

sub get_characters {
    my $self = shift;
    unless ($self->character_cache_keys) {
        my $characters = $self->every_hash('CHARACTERS');

        # Convert the hash values to their actual Unicode character
        # equivalent. For defining a character, we accept Unicode character
        # names (the "..." part of the "\N{...}" notation) or hex code points
        # (indicated by a leading "0x"; useful for characters that don't have
        # a name).
        for (values %$characters) {
            next if utf8::is_utf8($_);    # don't convert the already converted
            if (/^0x(.*)$/) {
                $_ = sprintf '%c' => hex($1);
            } else {
                $_ = sprintf '%c' => charnames::vianame($_);
            }
            utf8::upgrade($_);
        }
        $self->character_cache(%$characters);
    }
    return $self->character_cache;
}

sub get_character_names {
    my $self       = shift;
    my %characters = $self->get_characters;
    my @names      = keys %characters;
    wantarray ? @names : \@names;
}

sub get_character_values {
    my $self       = shift;
    my %characters = $self->get_characters;
    my @values     = values %characters;
    wantarray ? @values : \@values;
}

sub is_valid_string {
    my ($self, $string) = @_;
    unless (defined $self->valid_string_re_cache) {

        # escape critical characters so they're not interpreted as special
        # characters in the regex.
        my $chars = join '',
          map { m{^[\-.+*?()\[\]/\\]$} ? sprintf("\\%s", $_) : $_; }
          $self->get_character_values;
        $self->valid_string_re_cache(qr/^[$chars]+$/);
    }
    $string =~ $self->valid_string_re_cache;
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Charset::ViaHash - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 CHARACTERS

FIXME

=head2 get_character_names

FIXME

=head2 get_character_values

FIXME

=head2 get_characters

FIXME

=head2 is_valid_string

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Conveyor>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Conveyor/>.

The development version lives at L<http://github.com/hanekomu/Data-Conveyor>
and may be cloned from L<git://github.com/hanekomu/Data-Conveyor>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

