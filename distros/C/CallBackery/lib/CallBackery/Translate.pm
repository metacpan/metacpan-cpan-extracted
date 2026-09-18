# $Id: Translate.pm 542 2013-12-12 16:36:34Z oetiker $
package CallBackery::Translate;

use Mojo::Base -base, -signatures;
use Encode;
use CallBackery::Exception qw(mkerror);

use Exporter 'import';
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(trm trmJoin);


=head1 NAME

CallBackery::Translate - gettext po file translation functionality

=head1 SYNOPSIS

 use CallBackery::Translate qw(mtr);
 my $loc = CallBackery::Translate->new(localeRoot=>$dir);
 $loc->setLocale('de');
 $loc->tra("Hello %1","Tobi");

 trm("Mark but for translation but return original");

=head1 DESCRIPTION

Read translations from gettext po files and translate incoming data.

=cut

has 'localeRoot';

=over

=item C<setLocale>($locale);

Load the translations strings for $locale. First try the full name and
then top-up with only the language part.

=cut

my %lx;

sub setLocale {
    my $self = shift;
    my $locale = shift;
    if ($lx{$locale}){
        $self->{_lx} = $lx{$locale};
        return;
    }
    my $lang = $locale;
    $lang =~ s/_.+//;
    for my $file ($lang,$locale){
        my $mode = 'id';
        if (open my $fh, '< :encoding(utf8)', $self->localeRoot.'/'.$file.'.po'){
            my $key;
            my %var;
            while (<$fh>){
                chomp;
                /^msg(id|str)\s+"(.*)"/ && do {
                    $var{$1} = $2;
                    $key = $1;
                    next;
                };
                /^"(.*)"/ && do {
                    $var{$key} .= $1;
                    next;
                };
                /^\s*$/ && $var{id} && do {
                    $lx{$locale}{$var{id}} = $var{str};
                    next;
                }
            }
            $lx{$locale}{$var{id}} = $var{str} if $var{id} and $var{str};
        }
    }
    $self->{_lx} = $lx{$locale};
}

=item C<tra>(str[,arg,arg,...])

Translate string into the curent language.

=cut

sub tra {
    my $self = shift;
    my $str = shift;
    my @args = @_;
    my $lx = $self->{_lx} // {};
    $str = $lx->{$str} if $lx->{$str};
    my $id = 1;
    for my $a (@args){
        $str =~ s/%$id/$a/g;
        $id++;
    }
    return $str;
}

=item C<trm>(str[,arg,arg,...])

mark for translation but return an array pointer so that the string
can be translated dynamically in the frontend.

=cut

# trm("Hello %1",$name);

=head2 trm($str[,@args]);

Make string and prepare for translation in the frontend.

Note there is some major perl magic going on! by blessing the returned
array into the current package, we then get to use the overload code
on stringification AND Mojo::JSON gets to use the TO_JSON method when
converting this into something to be transported to the frontend.

An argument may be a C<trm()> of its own, and then it keeps its own msgid
all the way to the frontend instead of being rendered here. Use that for a
message with an optional part in it -- a warning appended to a confirmation,
say -- rather than building the text with C<.=>, which runs the
stringification overload and leaves nothing to translate:

    my $msg = trm("Settings saved.");
    $msg = trm("%1\n\n%2",$msg,$warning) if $warning;

Anything else is stringified as it is passed, so an argument that carries
text a user should read in their own language has to be a C<trm()>.

=cut

use overload
    '""' => sub ($self,@args) {
        # Render the arguments BEFORE substituting them. An argument that is
        # itself a trm() runs this very overload, and its own s/// resets $1
        # while the outer s///eg is still walking its string -- which left a
        # bare "%1" standing in the result and warned about a non-numeric
        # array index. Touching nothing but a plain array in the replacement
        # keeps the two substitutions out of each other's way.
        my @part = map { defined $_ ? "$_" : '' } @$self;
        my $ret = $part[0];
        $ret =~ s{%(\d+)}{$part[$1]//''}eg;
        return $ret;
    },
    'eq' => sub ($self,$other,$swap) {
        return "$self" eq "$other";
    };

sub trm ($str,@args) {
    # make sure the arguments are stringified, warn if undefined
    return bless [$str,map {
        if (not defined $_) {
            my ($package, $filename, $line) = caller;
            warn "Undefined argument for str='$str' from $package line $line";
        }
        # An argument that is itself a trm() stays an object, so that it
        # reaches the frontend as a msgid of its own and gets translated
        # there. Stringifying it here -- which is what "$_" below does to
        # everything else -- ran the overload, substituted the arguments and
        # froze the text in the language of the source code. That is how a
        # message assembled from pieces, which is every message with an
        # optional part in it, lost its translation.
        ref $_ eq __PACKAGE__ ? $_ : "$_"
    } @args];
}

=head2 trmJoin($sep,@parts);

Join a list of C<trm()> objects into one translatable message.

For a message whose number of parts is only known at run time -- a list of
warnings, a set of flags on a table row -- where no single msgid can be
written because nobody knows how many placeholders it needs. C<join()> is
what one reaches for, and it stringifies every part and destroys their
translations.

The msgid this builds holds no words, only placeholders and the separator,
so there is nothing in it for a translator to act on; the text stays in the
parts, each with its own msgid. Keep C<$sep> free of C<%>, which would be
read as a placeholder.

An empty list gives the empty message, and a single part is returned as it
is rather than wrapped in a pointless C<"%1">.

=cut

sub trmJoin ($sep,@parts) {
    @parts = grep { defined and "$_" ne '' } @parts;
    return trm('') unless @parts;
    return $parts[0] if @parts == 1 and ref $parts[0] eq __PACKAGE__;
    return trm(join($sep, map { '%'.($_+1) } 0..$#parts), @parts);
}

=head2 $str->TO_JSON

Help L<Mojo::JSON> encode us into JSON.

An ARRAY, always, even when there are no arguments to substitute. The array
IS the marker: it is how the frontend tells a string that wants translating
from one that is data. Collapsing the no-argument case to a bare string --
which is what this used to do -- made the most common kind of translatable
text indistinguishable from a hostname or an error message from some other
system, so anything that was not a form label silently stayed in English.

Every consumer in the frontend runs its strings through C<xtr()>, which takes
both shapes; the places that did not were the bug.

An argument that is a C<trm()> of its own becomes a nested array, which
C<xtr()> resolves before it substitutes. That is how a message built from a
fixed part and a couple of optional ones stays translatable in all of its
pieces, without a msgid per combination.

=cut

sub TO_JSON ($self) {
    return [map { ref $_ eq __PACKAGE__ ? $_->TO_JSON : $_ } @$self];
}

1;


__END__

=back

=head1 COPYRIGHT

Copyright (c) 2010 by OETIKER+PARTNER AG. All rights reserved.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2010-12-22 to 1.0 first version

=cut

# Emacs Configuration
#
# Local Variables:
# mode: cperl
# eval: (cperl-set-style "PerlStyle")
# mode: flyspell
# mode: flyspell-prog
# End:
#
# vi: sw=4 et
