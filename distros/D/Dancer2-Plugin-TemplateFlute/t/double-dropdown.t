use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Cookies;

{

    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::TemplateFlute;

    any [qw/get post/] => '/' => sub {
        return form_handler('double-1');
    };

    any [qw/get post/] => '/no-keep' => sub {
        return form_handler('double-no-keep');
    };

    sub form_handler {
        my $template = shift;
        my $form     = form('edit');
        my %values   = %{ $form->values };
        $form->fill( \%values );
        template $template,
          {
            roles => [
                { value => '1' },
                { value => '2' },
                { value => '3' },
                { value => '4' },
            ],
            form => $form,
          },
          { layout => undef };

    }
}

my $url  = 'http://localhost';
my $jar  = HTTP::Cookies->new();
my $test = Plack::Test->create( TestApp->to_app );
my $trap = TestApp->dancer_app->logger_engine->trapper;

my $expected = <<'FORM';
<select id="role" name="role">
<option value="">Please select role</option>
<option selected="selected">1</option>
<option>2</option>
<option>3</option>
<option>4</option>
</select>
FORM

$expected =~ s/\n//g;
my $empty_value = q{<option value="">Please select role</option>};
my $selected    = q{<option selected="selected">1</option>};

my $resp = $test->request( POST '/', { role => 1 } );
ok $resp->is_success, "POST '/', { role => 1 } successful"
  or diag explain $trap->read;
$jar->extract_cookies($resp);

like $resp->content, qr/\Q$expected\E/,
  "No duplicated found with template double-1";

like $resp->content, qr/\Q$empty_value\E/,
  "Found the empty value with the template double-1";
like $resp->content, qr/\Q$selected\E/,
  "Found the selected with template double-1";

my $req = POST '/no-keep', { role => 1 };
$jar->add_cookie_header($req);
$resp = $test->request($req);
ok $resp->is_success, "POST '/no-keep', { role => 1 } successful"
  or diag explain $trap->read;

$expected = <<'FORM';
<select id="role" name="role">
<option selected="selected">1</option>
<option>2</option>
<option>3</option>
<option>4</option>
</select>
FORM

$expected =~ s/\n//g;

like $resp->content, qr/\Q$expected\E/,
  "No duplicated found with template double-no-keep";

unlike $resp->content, qr/\Q$empty_value\E/,
  "Found the empty value without keep=empty_value";

like $resp->content, qr/\Q$selected\E/,
  "Found the selected with template double-no-keep";

done_testing;
