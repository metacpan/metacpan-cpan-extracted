use strict;
use warnings;

use Test::More;
use DBIx::Class::UnicornLogger::FromProfile;

subtest plain => sub {
   my $ul = DBIx::Class::UnicornLogger::FromProfile->new(
      unicorn_profile => 'plain',
   );

   is($ul->_multiline_format, undef, 'multiline_format gets correctly set');
   is($ul->_clear_line_str, "DONE\n", 'clear_line gets correctly set');
   is($ul->_executing_str, "EXECUTING...", 'executing gets correctly set');
};

subtest via_env => sub {
   local $ENV{DBIC_UNICORN_PROFILE} = 'plain';
   my $ul = DBIx::Class::UnicornLogger::FromProfile->new(
      unicorn_profile => 'nightmare_mode',
   );

   is($ul->_multiline_format, undef, 'multiline_format gets correctly set');
   is($ul->_clear_line_str, "DONE\n", 'clear_line gets correctly set');
   is($ul->_executing_str, "EXECUTING...", 'executing gets correctly set');
};

done_testing();
