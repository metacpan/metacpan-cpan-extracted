use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use File::Spec;
use Catmandu;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::I18N';
    use_ok $pkg;
}
require_ok $pkg;

{
    Catmandu->load(File::Spec->catdir("t","catmandu-config"));

    my $config = {
        nl => [ CatmanduConfig => ["locale.nl"] ],
        en => [ CatmanduConfig => ["locale.en"] ],
        #this is necessary for the placeholders to work!
        _style => "gettext"
    };

    my $i = $pkg->new( config => $config );

    is( $i->t( "nl", "mail_subject" ), "Overzicht van uw huidige ontleningen" );
    is( $i->t( "en", "mail_subject" ), "Summary of your current loans at the library" );

    is( $i->t( "nl", "mail_greeting", "Nicolas" ), "Geachte Nicolas" );
    is( $i->t( "en", "mail_greeting", "Nicolas" ), "Dear Nicolas" );

    is( $i->t( "nl", "mail_body", 1 ), "1 boek is nu te laat" );
    is( $i->t( "nl", "mail_body", 2 ), "2 boeken zijn nu te laat" );
    is( $i->t( "nl", "mail_body", 0 ), "0 boeken zijn nu te laat" );

    is( $i->t( "en", "mail_body", 1 ), "1 book is overdue now" );
    is( $i->t( "en", "mail_body", 2 ), "2 books are overdue now" );
    is( $i->t( "en", "mail_body", 0 ), "0 books are overdue now" );

}

done_testing 12;
