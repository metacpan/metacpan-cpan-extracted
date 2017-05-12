use strict;
use Test::More;
use File::Spec::Functions;
use File::Glob;

my $dir;
BEGIN { $dir = catdir qw( t lib ); }
use lib $dir;

my @list_cases      = File::Glob::bsd_glob catfile(qw(t usecase_list*));
my @locale_fr_cases = File::Glob::bsd_glob catfile(qw(t usecase_locale_fr*));
my @locale_en_cases = File::Glob::bsd_glob catfile(qw(t usecase_locale_en*));
my @alias_cases     = File::Glob::bsd_glob catfile(qw(t usecase_alias*));

plan tests => 2
    * ( @list_cases + @locale_fr_cases + @locale_en_cases + @alias_cases );

LIST: {
    use Acme::MetaSyntactic::test_ams_list;
    my %items = map { $_ => 1 } @Acme::MetaSyntactic::test_ams_list::List;

    for (@list_cases) {
        my $result = `$^X "-I$dir" -Mstrict -w $_`;
        is( $? >> 8, 0, "$_ ran successfully" );
        ok( exists $items{$result},
            "'$result' is an item from the test_ams_list theme" );
    }
}

LOCALE: {
    use Acme::MetaSyntactic 'test_ams_locale';
    my %items_en = map { $_ => 1 } @{$Acme::MetaSyntactic::test_ams_locale::Locale{en}};
    my %items_fr = map { $_ => 1 } @{$Acme::MetaSyntactic::test_ams_locale::Locale{fr}};

    for (@locale_fr_cases) {
        my $result = `$^X "-I$dir" -MNoLang -Mstrict -w $_`;
        is( $? >> 8, 0, "$_ ran successfully" );
        ok( exists $items_fr{$result},
            "'$result' is an item from the test_ams_locale/fr theme" );
    }

    for (@locale_en_cases) {
        my $result = `$^X "-I$dir" -MNoLang -Mstrict -w $_`;
        is( $? >> 8, 0, "$_ ran successfully" );
        ok( exists $items_en{$result},
            "'$result' is an item from the test_ams_locale/en theme" );
    }
}

ALIAS: {
    use Acme::MetaSyntactic::test_ams_alias;
    my %items = map { $_ => 1 } Acme::MetaSyntactic::test_ams_alias->new( category => ':all' )->name( 0 );

    for (@alias_cases) {
        my $result = `$^X "-I$dir" -Mstrict -w $_`;
        is( $? >> 8, 0, "$_ ran successfully" );
        ok( exists $items{$result},
            "'$result' is an item from the test_ams_alias theme" );
    }
}
