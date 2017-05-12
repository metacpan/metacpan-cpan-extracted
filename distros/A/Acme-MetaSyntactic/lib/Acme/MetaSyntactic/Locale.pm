package Acme::MetaSyntactic::Locale;
use strict;
use warnings;
use Acme::MetaSyntactic (); # do not export metaname and friends
use Acme::MetaSyntactic::MultiList;
use List::Util qw( shuffle );
use Carp;

our @ISA = qw( Acme::MetaSyntactic::MultiList );
our $VERSION = '1.000';

sub init {
    # alias the older package variable %Locale to %MultiList
    no strict 'refs';
    *{"$_[0]::Locale"}    = \%{"$_[0]::MultiList"};
    ${"$_[0]::Separator"} = '_';

    # call the parent class init code
    goto &Acme::MetaSyntactic::MultiList::init;
}

sub new {
    my $class = shift;

    no strict 'refs';
    my $self = bless { @_, cache => [] }, $class;

    # compute some defaults
    if( ! exists $self->{category} ) {
        $self->{category} =
            exists $self->{lang}
            ? $self->{lang}
            : $ENV{LANGUAGE} || $ENV{LANG} || '';
        if( !$self->{category} && $^O eq 'MSWin32' ) {
            eval { require Win32::Locale; };
            $self->{category} = Win32::Locale::get_language() unless $@;
        }
    }

    my $cat = $self->{category};

    # support for territories
    if ( $cat && $cat ne ':all' ) {
        ($cat) = $cat =~ /^([-A-Za-z_]+)/;
        $cat = lc( $cat || '' );
        1 while $cat
            && !exists ${"$class\::MultiList"}{$cat}
            && $cat =~ s/_?[^_]*$//;
    }

    # fall back to last resort
    $self->{category} = $cat || ${"$class\::Default"};
    $self->_compute_base();
    return $self;
}

*lang      = \&Acme::MetaSyntactic::MultiList::category;
*languages = \&Acme::MetaSyntactic::MultiList::categories;

1;

__END__

=head1 NAME

Acme::MetaSyntactic::Locale - Base class for multilingual themes

=head1 SYNOPSIS

    package Acme::MetaSyntactic::digits;
    use Acme::MetaSyntactic::Locale;
    our @ISA = ( Acme::MetaSyntactic::Locale );
    __PACKAGE__->init();
    1;

    =head1 NAME
    
    Acme::MetaSyntactic::digits - The numbers theme
    
    =head1 DESCRIPTION
    
    You can count on this module. Almost.

    =cut
    
    __DATA__
    # default
    en
    # names en
    zero one two three four five six seven eight nine
    # names fr
    zero un deux trois quatre cinq six sept huit neuf
    # names it
    zero uno due tre quattro cinque sei sette otto nove
    # names yi
    nul eyn tsvey dray fir finf zeks zibn akht nayn

=head1 DESCRIPTION

C<Acme::MetaSyntactic::Locale> is the base class for all themes that are
meant to return a random excerpt from a predefined list I<that depends
on the language>.

The language is selected at construction time from:

=over 4

=item 1.

the given C<lang> or C<category> parameter,

=item 2.

the current locale, as given by the environment variables C<LANGUAGE>,
C<LANG> or (under Win32) Win32::Locale.

=item 3.

the default language for the selected theme.

=back

The language codes should conform to the RFC 3066 and ISO 639 standard.

=head1 METHODS

Acme::MetaSyntactic::Locale offers several methods, so that the subclasses
are easy to write (see full example in L<SYNOPSIS>):

=over 4

=item new( lang => $lang )

=item new( category => $lang )

The constructor of a single instance. An instance will not repeat items
until the list is exhausted.

The C<lang> or C<category> parameter(both are synonymous) should be
expressed as a locale category. If none of those parameters is given
Acme::MetaSyntactic::Locale will try to find the user locale (with the
help of environment variables C<LANGUAGE>, C<LANG> and the module
C<Win32::Locale>).

POSIX locales are defined as C<language[_territory][.codeset][@modifier]>.
If the specific territory is not supported, C<Acme::MetaSyntactic::Locale>
will use the language, and if the language isn't supported either,
the default is used.

=item init()

init() must be called when the subclass is loaded, so as to read the
__DATA__ section and fully initialise it.

=item name( $count )

Return $count names (default: C<1>).

Using C<0> will return the whole list in list context, and the size of the
list in scalar context (according to the C<lang> parameter passed to the
constructor).

=item lang()

=item category()

Return the selected language for this instance.

=item languages()

=item categories()

Return the languages supported by the theme.

=item theme()

Return the theme name.

=back

=head1 SEE ALSO

I<Codes for the Representation of Names of Languages>, at
L<http://www.loc.gov/standards/iso639-2/langcodes.html>.

RFC 3066, I<Tags for the Identification of Languages>, at
L<http://www.ietf.org/rfc/rfc3066.txt>.

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::MultiList>.

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2005-2006 Philippe 'BooK' Bruhat, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

