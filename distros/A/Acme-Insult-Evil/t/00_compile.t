use Test2::V0;
use open qw[:std :encoding(UTF-8)];
use experimental 'for_list';
#
use lib '../lib', 'lib';
use Acme::Insult::Evil qw[:all];
#
imported_ok qw[insult];
#
ok +insult(), 'stringify';
#
subtest 'evil insults in different languages' => sub {
    is Acme::Insult::Evil::insult(), hash {
        field active    => number_ge 0;
        field comment   => D();
        field created   => D();            # ISO date
        field createdby => D();            # might be filled
        field insult    => D();
        field language  => string 'en';    # default
        field number    => number_ge 0;
        field shown     => number_ge 0;
    }, 'English is the default';
    for my ( $code, $lang )(
        en => 'English',
        cn => 'Chinese',
        ja => 'Japanese',
        fr => 'French',
        es => 'Spanish',
        hi => 'Hindi',
        tr => 'Turkish'                    # That's enough
    ) {
        is Acme::Insult::Evil::insult( language => $code ), hash {
            field active    => number_ge 0;
            field comment   => D();
            field created   => D();            # ISO date
            field createdby => D();            # might be filled
            field insult    => D();
            field language  => string $code;
            field number    => number_ge 0;
            field shown     => number_ge 0;
        }, sprintf q['%s' [%s]], $code, $lang;
    }
};
#
done_testing;
