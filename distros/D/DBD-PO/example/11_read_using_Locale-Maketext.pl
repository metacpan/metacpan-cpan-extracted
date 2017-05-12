#!perl
# $Id: 11_read_using_Locale-Maketext.pl 378 2009-05-02 06:29:51Z steffenw $

use strict;
use warnings;

# create a package for a lexicon
# here inplace
BEGIN {
    package Example::L10N;

    use strict;
    use warnings;

    our $VERSION = 0;

    use parent qw(Locale::Maketext); # inheritance
    use Locale::Maketext::Lexicon;

    # for test examples only
    our $PATH;
    our $TABLE_2X;
    () = eval 'use Test::DBD::PO::Defaults qw(\$PATH $TABLE_2X)'; ## no critic (StringyEval InterpolationOfMetachars)

    my $path  = $PATH
                || q{.};
    my $table = $TABLE_2X
                || 'table_de.po'; # for langueage de

    # The lexicon is for langueage xx
    # and has 1 utf-8 po file.
    Locale::Maketext::Lexicon->import({
        de      => [
            Gettext => "$path/$table",
        ],
        _decode => 1, # unicode mode
    });
}

use Carp qw(croak);
use Tie::Sub (); # allow to write a subroutine call as fetch hash

my $language = 'de_DE';
# create a language handle for language xx
my $lh = Example::L10N->get_handle($language)
    or croak 'What language';
$lh->{numf_comma} = $language =~ m{\A de_}xms;
# tie for interpolation in strings
# $__{1}      will be the same like $lh->maketext(1)
# $__{[1]}    will be the same like $lh->maketext(1)
# $__{[1, 2]} will be the same like $lh->maketext(1, 2)
tie my %__, 'Tie::Sub', sub { return $lh->maketext(@_) }; ## no critic (Ties)

# write a long text with all the different translatons
print <<"EOT"; ## no critic (CheckedSyscalls)
$__{'text1 original'}

$__{"text2 original\n2nd line of text2"}

$__{['text3 original [_1]', 'is good']}

$__{['text4 original [quant,_1,o_one,o_more,o_nothing]', 0]}
$__{['text4 original [quant,_1,o_one,o_more,o_nothing]', 1]}
$__{['text4 original [quant,_1,o_one,o_more,o_nothing]', 1.5]}
$__{['text4 original [quant,_1,o_one,o_more,o_nothing]', 2]}
EOT
;