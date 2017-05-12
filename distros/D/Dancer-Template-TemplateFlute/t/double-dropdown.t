#! perl

use strict;
use warnings;

use File::Spec;
use Data::Dumper;

use Dancer qw/:syntax/;
use Dancer::Plugin::Form;

set template => 'template_flute';
set views => 't/views';
set log => 'debug';

any [qw/get post/] => '/' => sub {
    return form_handler('double-1');
};

any [qw/get post/] => '/no-keep' => sub {
    return form_handler('double-no-keep');
};

sub form_handler {
    my $template = shift;
    my $form = form('edit');
    my %values = %{$form->values};
    $form->fill(\%values);
    template $template, {
                          roles => [
                                    { value => '1' },
                                    { value => '2' },
                                    { value => '3' },
                                    { value => '4' },
                                   ],
                          form => $form,
                         }, { layout => undef };
    
}

use Test::More tests => 6, import => ['!pass'];

use Dancer::Test;

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
my $selected = q{<option selected="selected">1</option>};

my $resp = dancer_response POST => '/';
# mah, we have to post twice. Looks like it has to warm up...

$resp = dancer_response POST => '/', { body => { role => 1 } };

response_content_like($resp, qr/\Q$expected\E/,
                      "No duplicated found with template double-1");

response_content_like($resp, qr/\Q$empty_value\E/,
                      "Found the empty value with the template double-1");
response_content_like($resp, qr/\Q$selected\E/,
                      "Found the selected with template double-1");



$resp = dancer_response POST => '/no-keep', { body => { role => 1 } };

$expected = <<'FORM';
<select id="role" name="role">
<option selected="selected">1</option>
<option>2</option>
<option>3</option>
<option>4</option>
</select>
FORM

$expected =~ s/\n//g;



response_content_like($resp, qr/\Q$expected\E/,
                      "No duplicated found with template double-no-keep");

response_content_unlike($resp, qr/\Q$empty_value\E/,
                        "Found the empty value without keep=empty_value");

response_content_like($resp, qr/\Q$selected\E/,
                      "Found the selected with template double-no-keep");
