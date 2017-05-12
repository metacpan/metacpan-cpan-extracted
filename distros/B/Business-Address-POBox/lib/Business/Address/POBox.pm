use 5.008;
use strict;
use warnings;

package Business::Address::POBox;
BEGIN {
  $Business::Address::POBox::VERSION = '1.101230';
}

# ABSTRACT: Check whether an address looks like a P.O.Box
use String::BlackWhiteList;
use parent qw(Class::Accessor::Complex Class::Accessor::Constructor);
__PACKAGE__->mk_constructor->mk_object_accessors(
    'String::BlackWhiteList' => 'matcher')
  ->mk_array_accessors(qw(blacklist whitelist));
use constant DEFAULTS => (
    blacklist => [
        '\b(BOX|POB|POST(BOX|SCHACHTEL|FACH|LAGERND|BUS)?|POBOX)\b',
        '\b(P\.?\s*O\.?(\s*B(\.|OX))?)\b',
        '(^|\b)P\.?F\.?(-|\s+)\d',
    ],
    whitelist => [
        'Pf(-|\s+)\D',
'\b((Alte|An\s+der(\s+alten)?)\s+Post|Post(-|\s+)(Road|Rd|Street|St|Avenue|Av|Alley|Drive|Grove|Walk|Parkway|Row|Lane|Bridge|Boulevard|Square|Garden|Strasse|Gasse|Allee|Platz))\b',
    ],
);

sub init {
    my $self = shift;
    $self->update;
}

sub update {
    my $self = shift;
    for ($self->matcher) {
        $_->blacklist($self->blacklist);
        $_->whitelist($self->whitelist);
        $_->update;
    }
}

sub is_pobox {
    my ($self, $text) = @_;
    return 0 if $self->matcher->valid($text);
    my $black_re = $self->matcher->black_re;
    # The documentation below explains this mess.
    $text =~ s/$black_re//gi;
    $text =~ s/[^\sa-z]//gi;
    $text =~ s/^\s+|\s+$//g;
    for my $word (split /\s+/, $text) {
        return 0 if length($word) > 1;
    }
    return 1;
}

sub is_pobox_relaxed {
    my ($self, $text) = @_;
    !$self->matcher->valid_relaxed($text);
}
1;


__END__
=pod

=head1 NAME

Business::Address::POBox - Check whether an address looks like a P.O.Box

=head1 VERSION

version 1.101230

=head1 SYNOPSIS

    use Business::Address::POBox;

    my $address = 'Universitaetsstrasse 7, PF 34';
    if (Business::Address::POBox->new->is_pobox($address)) {
        # do something with the address
    }

=head1 DESCRIPTION

This class tries to determine whether or not an string refers to a P.O. box.
This is sometimes relevant if your business process, for legal reasons, needs
a real address and not a P.O. box. Actually, it needs to be a deliverable
address. So a real address that happens to have a P.O. box is ok too.

It has predefined blacklists and whitelists that should catch most English and
German P.O. box addresses, but you can modify these lists with the methods
provided. Note that the entries are literal strings, not regular expressions.

=head1 METHODS

=head2 new

    my $obj = Business::Address::POBox->new;
    my $obj = Business::Address::POBox->new(%args);

Creates and returns a new object. The constructor will accept as arguments a
list of pairs, from component name to initial value. For each pair, the named
component is initialized by calling the method of the same name with the given
value. If called with a single hash reference, it is dereferenced and its
key/value pairs are set as described before.

=head2 init

Just calls C<update()> in case the blacklist and/or whitelist was set during
the C<new()> call.

=head2 update

Call this method when you've changed the C<whitelist()> or the C<blacklist()>
so the matcher knows about the changes.

=head2 is_pobox

This is the central method of this class. It takes a string argument and
checks it against the whitelist and the blacklist.

Returns a true value if the string passes the whitelist or is at least not
caught by the blacklist. If the string is caught by the blacklist, anything
that resembles a P.O. box is removed from the string, then everything except
whitespace and letters is deleted, then the string is trimmed. If any of the
remaining whitespace-separated words in the string has more than one
character, the whole string is still considered ok.

This is convoluted, but we might be testing the string C<Au 7, PF 33>. So
C<PF> would be considered a P.O. box (short for C<Postfach> in German); the
remainder, cleaned of non-letters and non-whitespace, is C<Au>. Since this is
longer than one character, it's the whole address is still ok.

Of course nothing prevents you from using C<Dr. Mabuse, P.O.Box 23> or
something similar nonsensical. Short of checking whether an address actually
exists there's no way of telling whether the remainder is an actual address.

=head2 is_pobox_relaxed

Like C<is_pobox()>, but once a string passes the whitelist, it is not checked
against the blacklist anymore. That is, if a string matches the whitelist, it
is valid. If not, it is checked against the blacklist - if it matches, it is
invalid. If it matches neither whitelist nor blacklist, it is valid.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Business-Address-POBox>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Business-Address-POBox/>.

The development version lives at
L<http://github.com/hanekomu/Business-Address-POBox/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

