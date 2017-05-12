use utf8;
use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::WWW::Mechanize::PSGI';

use Encode;
use Plack::Middleware::Lint;
use Text::Xslate;

my $conf = +{ # app config {{{
    validator => +{
        messages => +{
            message_test => +{
                pass => +{
                    NOT_BLANK => 'パスワードを指定してください。',
                    ASCII => 'パスワードに不正な文字列があります。',
                    LENGTH => 'パスワードの長さは 16 文字以内にしてください。',
                },
                mail1 => +{
                    NOT_BLANK => 'メールアドレスを指定してください。',
                    ASCII => 'メールアドレスに不正な文字列があります。',
                },
                mail2 => +{
                    NOT_BLANK => 'メールアドレスを指定してください。',
                    ASCII => 'メールアドレスに不正な文字列があります。',
                },
                mails => +{
                    DUPLICATION => 'メールアドレスが一致しません。',
                },
            },
        },
        message_format => 'error: %s',
        message_decode_from => 'UTF-8',
    },
};
#}}}

# test app setting
{ #{{{
    package MyApp;
    use parent qw!Amon2!;

    sub load_config { $conf }

    package MyApp::Web;
    use parent -norequire, qw!MyApp!;
    use parent qw!Amon2::Web!;
    __PACKAGE__->load_plugins('Web::FormValidator::Simple');

    #{{{
    my $xslate = Text::Xslate->new(
        syntax => 'TTerse',
        function => +{c => sub {__PACKAGE__->context}},
        path => +{
            index => <<TT,
<!doctype html>
this is index.
TT
            error => <<TT,
<!doctype html>
[%- IF c().form().has_error %]
<ul>
    [%- FOREACH key IN c().form().error -%]
        [%- FOREACH type IN c().form().error(key) %]
    <li>invalid: [% key %] - [% type %]
        [%- END -%]
    [%- END %]
</ul>
    [%- IF action -%]
<ul>
        [%- FOREACH msg IN c().form().messages(action) %]
    <li>[% msg %]
        [%- END %]
</ul>
    [%- END -%]
[%- END %]
TT
        },
    );
    sub create_view { return $xslate }
    #}}}

    sub dispatch { my $c = shift; #{{{
        my $pi = $c->req->path_info;
        if ($pi eq '/simple_validation') {
            $c->form([
                user => ['NOT_BLANK', 'ASCII'],
                pass => ['NOT_BLANK'],
            ]);

        } elsif ($pi eq '/complex_validation1') {
            $c->form([
                pass => ['NOT_BLANK', 'ASCII', [LENGTH => 1, 16]],
                mail1 => ['NOT_BLANK', 'ASCII'],
                mail2 => ['NOT_BLANK', 'ASCII'],
                +{mails => ['mail1', 'mail2']} => 'DUPLICATION',
            ]);

        } elsif ($pi eq '/complex_validation2') {
            $c->form([
                year => ['NOT_BLANK', 'UINT'],
                month => ['NOT_BLANK', 'UINT'],
                day => ['NOT_BLANK', 'UINT'],
                +{date => ['year', 'month', 'day']} => 'DATE',
            ]);
        }

        if ($c->form->has_error) {
            my $action = $c->req->param('action') || '';
            return $c->render('error', +{action => $action});
        }
        return $c->render('index');
    } #}}}
} #}}}

my $app = MyApp::Web->to_app();
my $m = Test::WWW::Mechanize::PSGI->new(app => $app);

{ # no validation {{{
    $m->get_ok('/');
    is n($m->content) => n(<<HTML);
<!doctype html>
this is index.
HTML
}  #}}}

{ # simple validation {{{
    my $str = query_string(
        user => 'あいうえお',
        pass => '',
    );
    $m->get_ok("/simple_validation?$str");
    is n($m->content) => n(<<HTML);
<!doctype html>
<ul>
    <li>invalid: user - ASCII
    <li>invalid: pass - NOT_BLANK
</ul>
HTML
} #}}}

{ # complex validation 1 {{{
    my $str = query_string(
        mail1 => 'aaa@example.com',
        mail2 => 'bbb@example.com',
        pass => '01234567890123456789',
    );

    $m->get_ok("/complex_validation1?$str");
    is n($m->content) => n(<<HTML);
<!doctype html>
<ul>
    <li>invalid: pass - LENGTH
    <li>invalid: mails - DUPLICATION
</ul>
HTML
} #}}}

SKIP: { # complex validation 2 - needs Date::Calc {{{
    eval { require Date::Calc; };
    skip 'Date::Calc not installed', 2 if $@;

    my $str = query_string(
        year => 2012,
        month => 9,
        day => -10,
    );

    $m->get_ok("/complex_validation2?$str");
    is n($m->content) => n(<<HTML);
<!doctype html>
<ul>
    <li>invalid: day - UINT
    <li>invalid: date - DATE
</ul>
HTML
} #}}}

{ # messages {{{
    my $str = query_string(
        mail1 => '',
        mail2 => 'あいうえお@どこか.com',
        pass => 'あいうえおあいうえおあいうえおあいうえお',
        action => 'message_test',
    );

    $m->get_ok("/complex_validation1?$str");
    is n($m->content) => n(<<HTML);
<!doctype html>
<ul>
    <li>invalid: pass - ASCII
    <li>invalid: pass - LENGTH
    <li>invalid: mail1 - NOT_BLANK
    <li>invalid: mail2 - ASCII
    <li>invalid: mails - DUPLICATION
</ul><ul>
    <li>error: パスワードに不正な文字列があります。
    <li>error: パスワードの長さは 16 文字以内にしてください。
    <li>error: メールアドレスを指定してください。
    <li>error: メールアドレスに不正な文字列があります。
    <li>error: メールアドレスが一致しません。
</ul>
HTML
} #}}}

done_testing;

# helper functions {{{
sub n {
    local $_ = shift;
    s/\n$//;
    $_;
}

sub query_string {
    my %param = ref $_[0] ? %{$_[0]} : @_;
    my $str = '';
    while (my ($k, $v) = each %param) {
        $v = encode(utf8 => $v);
        $v =~ s/([^a-zA-Z0-9_.!~*'()-])/'%' . unpack('H2', $1)/eg;
        $str .= "&$k=$v";
    }
    $str =~ s/^&//;

    return $str;
}
#}}}
