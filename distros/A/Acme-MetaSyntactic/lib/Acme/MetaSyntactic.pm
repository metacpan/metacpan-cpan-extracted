package Acme::MetaSyntactic;
$Acme::MetaSyntactic::VERSION = '1.015';
use strict;
use warnings;
use Carp;
use File::Basename;
use File::Spec;
use File::Glob;

# some class data
our $Theme = 'foo'; # default theme
our %META;

# private class method
sub _find_themes {
    my ( $class, @dirs ) = @_;
    return
        map  @$_,
        grep { $_->[0] !~ /^[A-Z]/ }    # remove the non-theme subclasses
        map  { [ ( fileparse( $_, qr/\.pm$/ ) )[0] => $_ ] }
        map  { File::Glob::bsd_glob( File::Spec->catfile( $_, qw( Acme MetaSyntactic *.pm ) ) ) } @dirs;
}

# fetch the list of standard themes
$META{$_} = 0 for keys %{ { __PACKAGE__->_find_themes(@INC) } };

# the functions actually hide an instance
my $meta = Acme::MetaSyntactic->new( $Theme );

# END OF INITIALISATION

# support for use Acme::MetaSyntactic 'foo'
# that automatically loads the required classes
sub import {
    my $class = shift;

    my @themes = ( grep { $_ eq ':all' } @_ )
      ? ( 'foo', grep { !/^(?:foo|:all)$/ } keys %META ) # 'foo' is still first
      : @_;

    $Theme = $themes[0] if @themes;
    $meta = Acme::MetaSyntactic->new( $Theme );

    # export the metaname() function
    no strict 'refs';
    my $callpkg = caller;
    *{"$callpkg\::metaname"} = \&metaname;    # standard theme

    # load the classes in @themes
    for my $theme( @themes ) {
        eval "require Acme::MetaSyntactic::$theme; import Acme::MetaSyntactic::$theme;";
        croak $@ if $@;
        *{"$callpkg\::meta$theme"} = sub { $meta->name( $theme, @_ ) };
    }
}

sub new {
    my ( $class, @args ) = ( @_ );
    my $theme;
    $theme = shift @args if @args % 2;
    $theme = $Theme unless $theme; # same default everywhere

    # defer croaking until name() is actually called
    bless { theme => $theme, args => { @args }, meta => {} }, $class;
}

# CLASS METHODS
sub add_theme {
    my $class  = shift;
    my %themes = @_;

    for my $theme ( keys %themes ) {
        croak "The theme $theme already exists!" if exists $META{$theme};
        my @badnames = grep { !/^[a-z_]\w*$/i } @{$themes{$theme}};
        croak "Invalid names (@badnames) for theme $theme"
          if @badnames;

        my $code = << "EOC";
package Acme::MetaSyntactic::$theme;
use strict;
use Acme::MetaSyntactic::List;
our \@ISA = qw( Acme::MetaSyntactic::List );
our \@List = qw( @{$themes{$theme}} );
1;
EOC
        eval $code;
        $META{$theme} = 1; # loaded

        # export the metatheme() function
        no strict 'refs';
        my $callpkg = caller;
        *{"$callpkg\::meta$theme"} = sub { $meta->name( $theme, @_ ) };
    }
}

# load the content of __DATA__ into a structure
# this class method is used by the other Acme::MetaSyntactic classes
sub load_data {
    my ($class, $theme ) = @_;
    my $data = {};

    my $fh;
    { no strict 'refs'; $fh = *{"$theme\::DATA"}{IO}; }

    my $item;
    my @items;
    $$item = "";

    {
        local $_;
        while (<$fh>) {
            /^#\s*(\w+.*)$/ && do {
                push @items, $item;
                $item = $data;
                my $last;
                my @keys = split m!\s+|\s*/\s*!, $1;
                $last = $item, $item = $item->{$_} ||= {} for @keys;
                $item = \( $last->{ $keys[-1] } = "" );
                next;
            };
            s/#.*//;    # remove end-of-line comments
            $$item .= $_;
        }
    }

    # avoid leaving all the DATA handles open
    close $fh;

    # clean up the items
    for( @items, $item ) {
        $$_ =~ s/\A\s*//;
        $$_ =~ s/\s*\z//;
        $$_ =~ s/\s+/ /g;
    }
    return $data;
}

# main function
sub metaname { $meta->name( @_ ) };

# corresponding method
sub name {
    my $self = shift;
    my ( $theme, $count );

    if (@_) {
        ( $theme, $count ) = @_;
        ( $theme, $count ) = ( $self->{theme}, $theme )
          if $theme =~ /^(?:0|[1-9]\d*)$/;
    }
    else {
        ( $theme, $count ) = ( $self->{theme}, 1 );
    }

    if( ! exists $self->{meta}{$theme} ) {
        my ( $Theme, $category ) = split /\//, $theme, 2;
        if( ! $META{$Theme} ) {
            eval "require Acme::MetaSyntactic::$Theme;";
            croak "Metasyntactic list $Theme does not exist!" if $@;
            $META{$theme} = 1; # loaded
        }
        $self->{meta}{$theme}
            = "Acme::MetaSyntactic::$Theme"->new( %{ $self->{args} },
            ( category => $category )x!! $category );
    }

    $self->{meta}{$theme}->name( $count );
}

# other methods
sub themes { wantarray ? ( sort keys %META ) : scalar keys %META }
sub has_theme { $_[1] ? exists $META{$_[1]} : 0 }

1;

__END__

=encoding iso-8859-1

=head1 NAME

Acme::MetaSyntactic - Themed metasyntactic variables names

=head1 SYNOPSIS

    use Acme::MetaSyntactic; # loads the default theme
    print metaname();

    # this sets the default theme and loads Acme::MetaSyntactic::shadok
    my $meta = Acme::MetaSyntactic->new( 'shadok' );

    print $meta->name();          # return a single name
    my @names = $meta->name( 4 ); # return 4 distinct names (if possible)

    # you can temporarily switch theme
    # (though it shifts your metasyntactical paradigm in other directions)
    my $foo = $meta->name( 'foo' );       # return 1 name from theme foo
    my @foo = $meta->name( toto => 2 );   # return 2 names from theme toto

    # but why would you need an instance variable?
    use Acme::MetaSyntactic qw( batman robin );

    # the first loaded theme is the default (here batman)
    print metaname;
    my @names = metaname( 4 );

    print join ',', metabatman(3), metarobin;

    # the convenience functions are only exported
    # - via the Acme::MetaSyntactic import list
    # - when an individual theme is used
    print join $/, metabatman( 5 );

    use Acme::MetaSyntactic::donmartin;
    print join $/, metadonmartin( 7 );

    # but a one-liner is even better
    perl -MAcme::MetaSyntactic=batman -le 'print metaname'

    # the meta(1) command-line tool can be helpful too
    meta batman

=head1 DESCRIPTION

When writing code examples, it's always easy at the beginning:

    my $foo = "bar";
    $foo .= "baz";   # barbaz

But one gets quickly stuck with the same old boring examples.
Does it have to be this way? I say "No".

Here is C<Acme::MetaSyntactic>, designed to fulfill your metasyntactic needs.
Never again will you scratch your head in search of a good variable name!

=head1 METHODS (& FUNCTIONS)

C<Acme::MetaSyntactic> has an object-oriented interface, but can also
export a few functions (see L<EXPORTS>).

=head2 Methods

If you choose to use the OO interface, the following methods are
available:

=over 4

=item new( $theme )

Create a new instance of C<Acme::MetaSyntactic> with the theme C<$theme>.
If C<$theme> is omitted, the default theme is C<foo>.

=item name( [ $theme, ] $count )

Return C<$count> items from theme C<$theme>. If no theme is given,
the theme is the one passed to the constructor.

If C<$count> is omitted, it defaults to C<1>.

If C<$count> is C<0>, the whole list is returned (this may vary depending
on the "behaviour" of the theme) in list context, and the size of the
list in scalar context.

=back

There are also some class methods:

=over 4

=item themes( )

Return the sorted list of all available themes.

=item has_theme( $theme )

Return true if the theme C<$theme> exists.

=item add_theme( theme => [ @items ], ... )

This class method adds a new theme to the list. It also creates and
exports all the convenience functions (C<metaI<theme>()>) needed.

Note that this method can only create themes that implement the
C<Acme::MetaSyntactic::List> behaviour.

=item load_data( $data )

This method is used by the "behaviour" classes (such as
C<Acme::MetaSyntactic::List>) to read the content of the C<DATA>
filehandle and fetch the theme data.

The format is very simple. If the C<DATA> filehandle contains the
following data:

    # names
    bam zowie plonk
    powie kapow # comment
    # multi level
      abc    def
    # empty
    # multi lingual
    fr de

C<load_data()> will return the following data structure (the string
is trimmed, newlines and duplicate whitespace characters are squashed,
and end-of-line comments are removed):

    {
        names => "bam zowie plonk powie kapow",
        multi => {
            level   => "abc def",
            lingual => "fr de",
        },
        empty => ""
    }

For example, C<Acme::MetaSyntactic::List> uses the single parameter C<names>
to fetch the lists of names for creating its subclasses.

The C<init()> method in all "behaviour" classes will also accept an optional
C<$data> hashref and if it provided, will use it instead of reading the
C<__DATA__> section of the module. The actual structure of the hashref
depends on the C<Acme::MetaSyntactic::> class.

=back

Convenience methods also exists for all the themes. The methods are named
after the theme. They are exported only when the theme is actually used
or when it appear in the C<Acme::MetaSyntactic> import list. The first
imported theme is the default, used by the C<metaname()> function.

=head1 EXPORTS

Depending on how C<Acme::MetaSyntactic> is used, several functions can
be exported. All of them behave like the following:

=over 4

=item metaname( [ $theme, ] $count )

Return C<$count> items from theme C<$theme>. If no theme is given,
the theme is "default" theme. See below how to change what the default is.

=back

=head2 Use cases

=over 4

=item C<use Acme::MetaSyntactic;>

This exports the C<metaname()> function only.

=item C<use Acme::MetaSyntactic 'theme';>

This exports the C<metaname()> function and the C<metaI<theme>()>
function. C<metaname()> default to the theme I<theme>.

=item C<use Acme::MetaSyntactic qw(theme1 theme2);>

This exports the C<metaname()>, C<metaI<theme1>()>, C<metaI<theme2>()>
functions. C<metaname()> default to the first theme of the list (I<theme1>).

=item C<use Acme::MetaSyntactic ':all';>

This exports the C<metaname()> function and the meta* functions for
B<all> themes. C<metaname()> default to the standard default theme (C<foo>).

=item C<use Acme::MetaSyntactic::theme;>

This exports the C<metaI<theme>()> function only. The C<metaname()>
function is not exported.

=back

=head1 THEMES

The list of available themes can be obtained with the following one-liner:

    $ perl -MAcme::MetaSyntactic -le 'print for Acme::MetaSyntactic->themes'

The themes are all the C<Acme::MetaSyntactic::I<theme>> classes, with
I<theme> starting with a lowercase letter.

The items that make up Acme::MetaSyntactic themes are finite lists of
valid Perl identifiers (not the UTF-8 kind).

=head2 Theme behaviours

C<Acme::MetaSyntactic> provides theme authors with the capability of creating
theme "behaviours". Behaviours are implemented as classes from which the
individual themes inherit.

The behaviours are all the C<Acme::MetaSyntactic::I<type>> classes, with
I<type> starting with an uppercase letter.

Here are the available behaviours:

=over 4

=item C<Acme::MetaSyntactic::List>

The theme is a simple collection of names. An object instance will
return names at random from the list, and not repeat any until the list
is exhausted.

=item C<Acme::MetaSyntactic::Locale>

The theme is made of several collections of names, each associated with
a "language". The language is either passed as a constructor parameter,
extracted from the environment or a default is selected.

=item C<Acme::MetaSyntactic::MultiList>

The theme is made of several collections of names, each associated with
a "category". Categories can include sub-categories, etc, I<ad infinitum>
(or when disk space or memory is exhausted, whichever happens first).
The category is either passed as a constructor parameter or the default
value is selected.

=item C<Acme::MetaSyntactic::Alias>

The theme is simply an alias of another theme. All items are identical,
as the original behaviour. The only difference is the theme name.

=back

Over time, new theme "behaviours" will be added.

=head1 SEE ALSO

L<Acme::MetaSyntactic::Themes>, L<meta>, L<metafy>.

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-metasyntactic@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

If you think this modules lacks a particular set of metasyntactic
variables, please send me a list, as well as a generation algorithm
(either one of the built-ins (C<Acme::MetaSyntactic::List>,
C<Acme::MetaSyntactic::Locale>), or a new one of your invention).

=head1 ACKNOWLEDGEMENTS

Individual contributors are listed in the individual theme files.
Look at the included F<CONTRIBUTORS> file for the list of all
contributors (43 in this version).

However, this module could not have been possible without:

=over 4

=item *

Some sillyness

See L<http://use.perl.org/~BooK/journal/22301>,
the follow-up L<http://use.perl.org/~BooK/journal/22710>,
and the announce L<http://use.perl.org/~BooK/journal/22732>.

=item *

The Batman serial from the 60s (it was shown in France in the 80s).

my wife loves it, I name most of my machines after the bat fight sound
effects (C<zowie>, C<klonk>, C<zlonk>), and I even own a CD of the serial's
theme music and the DVD of the movie (featuring the batboat and the batcopter!).

=item *

Rafael Garcia-Suarez,

who apparently plans to use it. Especially now that it's usable in
one-liners.

=item *

Vahe Sarkissian,

who was the first to suggest an additional list (the sound effects from
Don Martin's comic-books) and provided a link to a comprehensive list.

=item *

Sébastien Aperghis-Tramoni,

who actually uses it, to do what he thinks is the only logical thing
to do with C<Acme::MetaSyntactic>: an IRC bot! See L<Bot::MetaSyntactic>.

    #perlfr Sat Mar  5 01:15 CET 2005
    <Maddingue> BooK: bon, l'API de AMS, tu l'as changé alors ?
    <BooK> je sais pas
    <Maddingue> comment on fait pour invoquer ton merder
    <BooK> ca se mélange dans ma tete
    <BooK> je peux te montrer des use case
    <Maddingue> je veux juste savoir si tu vas changer la commande meta
    <Maddingue> BooK: parce que j'ai fais la seule chose qui me semblait
                logique de faire avec ton module
    <BooK> un robot irc

=item *

Jérôme Fenal,

who wrote L<Acme::MetaSyntactic::RefactorCode>, which helps
C<Acme::MetaSyntactic> fulfill its role: rename your boring variables
with silly names.

=item *

Abigail,

who provided by himself more than 35 themes (I stopped counting after that).
I probably won't be able to include them all before version 1.00.

=back

=head1 COPYRIGHT

Copyright 2005-2017 Philippe 'BooK' Bruhat, All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

