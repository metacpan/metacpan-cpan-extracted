# $Id: Translate.pm 542 2013-12-12 16:36:34Z oetiker $
package CallBackery::Translate;

use Mojo::Base -base, -signatures;
use Encode;
use CallBackery::Exception qw(mkerror);

use Exporter 'import';
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(trm);


=head1 NAME

CallBackery::Translate - gettext po file translation functionality

=head1 SYNOPSIS

 use CallBackery::Translate qw(mtr);
 my $loc = CallBackery::Translate::new(localeRoot=>$dir);
 $loc->setLocale('de');
 $loc->tra("Hello %1","Tobi");

 trm("Mark but for translation but return original");

=head1 DESCRIPTION

Read translations from gettext po files and translate incoming data.

=cut

has 'localeRoot';

=over

=item C<setLocale>($locale);

Load the translations strings for $locale. First try the full name and then top-up with only the language part.

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

mark for translation but return an array pointer so that the string can be translated
dynamically in the forntend. I<This functionality is not yet fully implemented>.

=cut

# trm("Hello %1",$name);

=head2 trm($str[,@args]);

Make string and prepare for translation in the frontend.

Note there is some major perl magic going on! by blessing the returned array into the current package, we then get to use the overload code on stringification AND Mojo::JSON gets to use the TO_JSON method when converting this into something to be transported to the frontend.

=cut

use overload
    '""' => sub ($self,@args) {
        my $ret = $self->[0];
        $ret =~ s{%(\d+)}{$self->[$1]//''}eg;
        return $ret;
    };

sub trm ($str,@args) {
    # make sure the arguments are stringified
    return bless [$str,map { "$_" } @args];
}

=head2 $str->TO_JSON

Help L<Mojo::JSON> encode us into JSON.

=cut

sub TO_JSON ($self) {
    my $ret = $#$self == 0 ? $self->[0] : [@$self];
    return $ret;
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
