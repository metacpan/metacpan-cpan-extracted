use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use File::Spec;
use Catmandu;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::i18n';
    use_ok $pkg;
}
require_ok $pkg;

{
    Catmandu->config({
        i18n => {
            nl => [ Gettext => File::Spec->catfile("t","po","nl.po") ],
            en => [ Gettext => File::Spec->catfile("t","po","en.po") ]
        }
    });

    my $fix_nl;
    my $fix_en;

    dies_ok(sub {

        $fix_nl = $pkg->new( "p", config => "i18n" );

    },"param 'lang' is required");

    dies_ok(sub {

        $fix_nl = $pkg->new( "p", lang => "nl" );

    },"param 'config' is required");

    lives_ok(sub {

        $fix_nl = $pkg->new( "p", config => "i18n", lang => "nl", args => "args" );

    },"i18n for lang 'nl' created");

    lives_ok(sub {

        $fix_en = $pkg->new( "p", config => "i18n", lang => "en", args => "args" );

    },"i18n for lang 'en' created");

    is_deeply( $fix_nl->fix({ p => "mail_subject" }), { p => "Overzicht van uw huidige ontleningen" }, "simple lookup 1" );
    is_deeply( $fix_en->fix({ p => "mail_subject" }), { p => "Summary of your current loans at the library" }, "simple lookup 2" );

    is_deeply( $fix_nl->fix({ p => "mail_greeting", args => ["Nicolas"] }), { p => "Geachte Nicolas", args => ["Nicolas"] }, "lookup with arguments 1" );
    is_deeply( $fix_en->fix({ p => "mail_greeting", args => ["Nicolas"] }), { p => "Dear Nicolas", args => ["Nicolas"] }, "lookup with arguments 2" );

    is_deeply( $fix_nl->fix({ p => "mail_body", args => [1] }), { p => "1 boek is nu te laat", args => [1] }, "lookup with quant 1" );
    is_deeply( $fix_nl->fix({ p => "mail_body", args => [2] }), { p => "2 boeken zijn nu te laat", args => [2] }, "lookup with quant 2" );
    is_deeply( $fix_nl->fix({ p => "mail_body", args => [0] }), { p => "0 boeken zijn nu te laat", args => [0] }, "lookup with quant 3" );

    is_deeply( $fix_en->fix({ p => "mail_body", args => [1] }), { p => "1 book is overdue now", args => [1] }, "lookup with quant 4" );
    is_deeply( $fix_en->fix({ p => "mail_body", args => [2] }), { p => "2 books are overdue now", args => [2] }, "lookup with quant 5" );
    is_deeply( $fix_en->fix({ p => "mail_body", args => [0] }), { p => "0 books are overdue now", args => [0] }, "lookup with quant 6" );

}

done_testing 16;
