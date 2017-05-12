#!/usr/bin/env perl -w

use strict;
use Test;

BEGIN { plan tests => 6 }

use Data::Define qw/ define_html brockets /;

Data::Define->set_undef_value('empty');
Data::Define->set_undef_value_html('empty html');

ok(define(undef), 'empty');
ok(define_html(undef), 'empty html');

Data::Define->set_undef_value('empty1');
Data::Define->set_undef_value_html('empty html1');

ok(define(undef), 'empty1');
ok(define_html(undef), 'empty html1');

Data::Define->set_undef_value(undef);
Data::Define->set_undef_value_html(undef);

ok(define(undef), '<undef>');
ok(define_html(undef), '&lt;undef&gt;');

exit;
