
package My::User;

use strict;
use warnings 'all';
use base 'My::Model';
use Data::Dumper;

__PACKAGE__->set_up_table('users');


__PACKAGE__->add_trigger( before_update => sub {
  my $s = shift;
});

__PACKAGE__->add_trigger( before_set_user_first_name => sub {
  my ($s, $oldval, $newval) = @_;
});

__PACKAGE__->add_trigger( before_update_user_first_name => sub {
  my ($s, $oldval, $newval) = @_;
});

__PACKAGE__->add_trigger( after_update_user_first_name => sub {
  my ($s, $oldval, $newval) = @_;
});

__PACKAGE__->add_trigger( after_update => sub {
  my $s = shift;
});

__PACKAGE__->add_trigger( before_create => sub {
  my $s = shift;
  $s->user_last_name( uc($s->user_last_name) );
});

__PACKAGE__->add_trigger( after_create => sub {
  my $s = shift;
  $s->user_last_name( ucfirst($s->user_last_name) );
  $s->update;
});

__PACKAGE__->add_trigger( before_delete => sub {
  my $s = shift;
});

__PACKAGE__->add_trigger( after_delete => sub {
  my $s = shift;
});

__PACKAGE__->add_trigger( after_delete => sub {
  my $s = shift;
});

1;# return true:


