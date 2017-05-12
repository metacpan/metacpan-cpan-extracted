use strict;
use warnings;
use AnyEvent::WebService::ImKayac;
use Test::More;

{
    eval { AnyEvent::WebService::ImKayac->new };
    ok($@, "require user and type");

    eval { anyevent::webservice::imkayac->new( user => "hoge" ) };
    ok($@, "require user and type");

    eval { anyevent::webservice::imkayac->new( type => "none" ) };
    ok($@, "require user and type");
}

{
    my $im = eval { AnyEvent::WebService::ImKayac->new( user => "hoge", type => "none") };
    isa_ok($im, "AnyEvent::WebService::ImKayac", "if type is none, not required other parameter.");
}

{
    eval { AnyEvent::WebService::ImKayac->new( user => "hoge", type => "password") };
    ok($@, "if type is password, require password parameter ");

    my $im = eval { AnyEvent::WebService::ImKayac->new( user => "hoge", type => "password", password => "hoge") };
    isa_ok($im, "AnyEvent::WebService::ImKayac", "if type is password, require password parameter ");
}

{
    eval { AnyEvent::WebService::ImKayac->new( user => "hoge", type => "secret") };
    ok($@, "if type is secret, require secret_key parameter ");

    my $im = eval { AnyEvent::WebService::ImKayac->new( user => "hoge", type => "secret", secret_key => "hoge") };
    isa_ok($im, "AnyEvent::WebService::ImKayac", "if type is secret, require secret_key parameter ");
}

done_testing;

