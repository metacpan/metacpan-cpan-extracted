# $Id: /mirror/coderepos/lang/perl/Class-DBI-Plugin-DateTime/trunk/lib/Class/DBI/Plugin/DateTime/MySQL.pm 101061 2009-02-20T09:44:03.572989Z daisuke  $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Class::DBI::Plugin::DateTime::MySQL;
use strict;
use base qw(Class::DBI::Plugin::DateTime::Base);
use DateTime::Format::MySQL;

BEGIN
{
    my @types = qw(datetime date timestamp);
    foreach my $type (@types) {
        # DT::F::MySQL doesn't have a format_timestamp method, so change
        # the deflator method accordingly
        my($inflator, $deflator);
        if ($type eq 'timestamp') {
            $inflator = 'timestamp';
            $deflator = 'datetime';
        } else {
            $inflator = $type;
            $deflator = $type;
        }

        eval sprintf(<<'        EOM', $type, $inflator, $deflator);
            sub has_%s
            {
                my $class  = shift;
                my $column = shift;

                my $inflate = sub { DateTime::Format::MySQL->parse_%s(shift) };
                my $deflate = sub { DateTime::Format::MySQL->format_%s(shift) };
                __PACKAGE__->_setup_column($class, $column, $inflate, $deflate);
            }
        EOM
    }

    {
        my @methods = map { ("has_$_") } @types;
        *_export_methods = sub { @methods };
    }
}

1;

__END__

=head1 NAME

Class::DBI::Plugin::DateTime::MySQL - Use DateTime With MySQL

=head1 SYNOPSIS

  package MyCDBI;
  use base qw(Class::DBI);
  use Class::DBI::Plugin::DateTime::MySQL;

  __PACKAGE__->set_db(...);
  __PACKAGE__->table(...);
  __PACKAGE__->has_timestamp('a_timestamp');
  __PACKAGE__->has_date('a_date');
  __PACKAGE__->has_time('a_time');

=head1 DESCRIPTION

Class::DBI::Plugin::DateTime::MySQL provides methods to work with DateTime
objects in a Class::DBI + MySQL environment.

=head1 METHODS

=head2 has_timestamp

=head2 has_datetime

=head2 has_date

=head1 SEE ALSO

L<DateTime|DateTime> L<DateTime::Format::MySQL|DateTime::Format::MySQL> L<Class::DBI>

=head1 AUTHOR

Copyright (c) 2005 Daisuke Maki E<lt>dmaki@cpan.orgE<gt>. All rights reserved.

Development funded by Brazil Ltd E<lt>http://b.razil.jpE<gt>

=cut

