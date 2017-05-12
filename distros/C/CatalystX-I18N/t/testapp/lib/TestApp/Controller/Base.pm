package TestApp::Controller::Base;

use strict;
use warnings;

use parent qw/Catalyst::Controller/;

our @LIST = qw(Ägypten Äquatorialguinea Äthiopien Afghanistan Albanien Algerien Andorra Bahamas Zypern);

sub test1 : Local Args(0) {
    my ($self,$c) = @_;
    
    # Clear session from last test-run
    delete $c->session->{i18n_locale};
    
    my $default_locale = $c->locale;
    $c->locale('de_CH');
    
    $c->detach('TestApp::View::Test',[
        {
            default_locale  => $default_locale,
            locale          => $c->locale,
        }
    ]);
}

sub test2 : Local Args(0) {
    my ($self,$c) = @_;
    
    $c->detach('TestApp::View::Test',[
        {
            session     => $c->get_locale_from_session() || undef,
            user        => $c->get_locale_from_user() || undef,
            browser     => $c->get_locale_from_browser() || undef,
        }
    ]);
}

sub test3 : Local Args(0) {
    my ($self,$c) = @_;
    
    my $locale = $c->get_locale();
    $c->set_locale('de_AT');
    my $request = $c->request;
    
    $c->detach('TestApp::View::Test',[
        {
            get_locale      => 'de_CH',
            locale          => 'de_AT',
            locale_from_c   => $c->locale,
            territory       => $c->territory,
            language        => $c->language,
            datetime        => {
                date            => $c->i18n_datetime_now->dmy,
                locale          => $c->i18n_datetime_now->locale->name,
                time            => $c->i18n_datetime_now->hms,
                timezone        => $c->i18n_datetime_timezone->name,
            },
            request         => {
                accept_language     => $request->accept_language,
                browser_language    => $request->browser_language,
                browser_territory   => $request->browser_territory,
                client_country      => $request->client_country,
                browser_detect      => ref($request->browser_detect),
            },
            number_format   => $c->i18n_numberformat->format_price(27.03),
        }
    ]);
}

sub test4 : Local Args(1) {
    my ($self,$c,$locale) = @_;
    
    $c->locale($locale);
    
    $c->detach('TestApp::View::Test',[
        {
            locale          => $c->locale,
            translation     => {
                (map 
                    { $_ => $c->maketext('string'.$_,$_) } (1..6),
                ),
            }
        }
    ]);
}

sub test5 : Local Args(0) {
    my ($self,$c) = @_;
    
    my $response = {};
    my $locale_config = $c->config->{I18N}{locales};
    while (my ($locale,$config) = each %$locale_config) {
        next
            if $config->{inactive} == 1;
        $c->locale($locale);
        $response->{$locale} = {
            timezone    => $c->i18n_datetime_timezone->name,
        };
    }
    
    
    $c->detach('TestApp::View::Test',[
        $response
    ]);
}

sub test6 : Local Args(0) {
    my ($self,$c) = @_;
    
    delete $c->session->{i18n_locale};
    
    $c->detach('TestApp::View::Test',[
        {
            locale  => $c->locale,
        }
    ]);
}

sub test7 : Local Args(0) {
    my ($self,$c) = @_;
    $c->locale('de_AT');
    $c->stash->{sortlist} = \@LIST;
    $c->detach('TestApp::View::TT');
}

sub test8 : Local Args(0) {
    my ($self,$c) = @_;
    $c->locale('de_AT');
    
    $c->detach('TestApp::View::Test',[
        {
            sort_perl   => join(',',sort @LIST),
            sort_collate=> join(',',$c->i18n_sort(@LIST)),
        }
    
    ]);
}

sub test9 : Local Args(1) {
    my ($self,$c,$locale) = @_;
    
    $c->locale($locale);
    
    $c->detach('TestApp::View::Test',[
        {
            locale          => $c->locale,
            translation     => {
                (map 
                    { $_ => $c->localize('string'.$_,$_) } (1..6),
                ),
            }
        }
    ]);
}


1;

