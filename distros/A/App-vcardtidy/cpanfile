#!perl

on configure => sub {
    requires 'ExtUtils::MakeMaker::CPANfile' => 0;
    requires 'Path::Tiny'                    => 0;
};

on runtime => sub {
    requires 'OptArgs2'                 => '2.0.0';
    requires 'Path::Tiny'               => 0;
    requires 'Text::vCard::Addressbook' => 0;
};

on develop => sub {
    requires 'App::githook::perltidy' => 0;
};

on test => sub {
    test_requires 'Test2::V0' => 0;
};
