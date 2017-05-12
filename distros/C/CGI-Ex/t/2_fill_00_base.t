# -*-perl-*-

=head1 NAME

2_fill_00_base.t - Test CGI::Ex::Fill's base ability.

=cut

use strict;
use Test::More tests => 6;

use_ok qw(CGI::Ex::Fill);

###----------------------------------------------------------------###

   my $form = {foo => "FOO", bar => "BAR", baz => "BAZ"};

   my $html = '
       <input type=text name=foo>
       <input type=text name=foo>
       <input type=text name=bar value="">
       <input type=text name=baz value="Something else">
       <input type=text name=hem value="Another thing">
       <input type=text name=haw>
   ';

   CGI::Ex::Fill::form_fill(\$html, $form);

   ok(
   $html eq   '
       <input type=text name=foo value="FOO">
       <input type=text name=foo value="FOO">
       <input type=text name=bar value="BAR">
       <input type=text name=baz value="BAZ">
       <input type=text name=hem value="Another thing">
       <input type=text name=haw value="">
   ', "perldoc example 1 passed");

   #print $html;

###----------------------------------------------------------------###

   $form = {foo => ['aaaa', 'bbbb', 'cccc']};

   $html = '
       <input type=text name=foo>
       <input type=text name=foo>
       <input type=text name=foo>
       <input type=text name=foo>
       <input type=text name=foo>
   ';

   form_fill(\$html, $form);

   ok(
   $html eq  '
       <input type=text name=foo value="aaaa">
       <input type=text name=foo value="bbbb">
       <input type=text name=foo value="cccc">
       <input type=text name=foo value="">
       <input type=text name=foo value="">
   ', "Perldoc example 2 passed");

   #print $html;

###----------------------------------------------------------------###

   $form = {foo => 'FOO', bar => ['aaaa', 'bbbb', 'cccc'], baz => 'on'};

   $html = '
       <input type=checkbox name=foo value="123">
       <input type=checkbox name=foo value="FOO">
       <input type=checkbox name=bar value="aaaa">
       <input type=checkbox name=bar value="cccc">
       <input type=checkbox name=bar value="dddd" checked="checked">
       <input type=checkbox name=baz>
   ';

   form_fill(\$html, $form);

   ok(
   $html eq  '
       <input type=checkbox name=foo value="123">
       <input type=checkbox name=foo value="FOO" checked="checked">
       <input type=checkbox name=bar value="aaaa" checked="checked">
       <input type=checkbox name=bar value="cccc" checked="checked">
       <input type=checkbox name=bar value="dddd">
       <input type=checkbox name=baz checked="checked">
   ', "Perldoc example 3 passed");

   #print $html;

###----------------------------------------------------------------###

   $form = {foo => 'FOO', bar => ['aaaa', 'bbbb', 'cccc']};

   $html = '
       <select name=foo><option>FOO<option>123<br>

       <select name=bar>
         <option>aaaa</option>
         <option value="cccc">cccc</option>
         <option value="dddd" selected="selected">dddd</option>
       </select>
   ';

   form_fill(\$html, $form);

   ok(
   $html eq  '
       <select name=foo><option selected="selected">FOO<option>123<br>

       <select name=bar>
         <option selected="selected">aaaa</option>
         <option value="cccc" selected="selected">cccc</option>
         <option value="dddd">dddd</option>
       </select>
   ', "Perldoc example 4 passed");

#   print $html;

###----------------------------------------------------------------###

   $form = {foo => 'FOO', bar => ['aaaa', 'bbbb']};

   $html = '
       <textarea name=foo></textarea>
       <textarea name=foo></textarea>

       <textarea name=bar>
       <textarea name=bar></textarea><br>
       <textarea name=bar>dddd</textarea><br>
       <textarea name=bar><br><br>
   ';

   form_fill(\$html, $form);

   ok(
   $html eq  '
       <textarea name=foo>FOO</textarea>
       <textarea name=foo>FOO</textarea>

       <textarea name=bar>aaaa<textarea name=bar>bbbb</textarea><br>
       <textarea name=bar></textarea><br>
       <textarea name=bar>', "Perldoc example 5 passed");

#   print $html;

###----------------------------------------------------------------###
