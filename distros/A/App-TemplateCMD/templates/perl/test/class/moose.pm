[% IF not vars %][% vars = [ 'search' ] %][% END -%]
[% IF not module -%]
    [%- IF out.match('^t/lib') -%]
        [%- out = out.replace('t/lib/', '') -%]
        [%- out = out.replace('[.]pm', '') -%]
        [%- out = out.replace('/', '::', 1) -%]
        [%- module = out -%]
    [%- END -%]
[% END -%]
[% IF not module %][% module = 'Module::Name' %][% END -%]
[% IF not version %][% version = '0.0.1' %][% END -%]
package [% module %];

use Test::Class::Moose;

sub test_startup {
   my $test = shift;
   $test->next::method;

   # more startup

}

sub test_shutdown {
   my $test = shift;

   # more teardown

   $test->next::method;
}

sub test_setup {
   my $test = shift;
   $test->next::method;

   # more setup

}

sub test_teardown {
   my $test = shift;

   # more teardown

   $test->next::method;
}

sub test_something :Tests(1) {
   my $test = shift;

}

1;
