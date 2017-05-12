# $Id: /mirror/coderepos/lang/perl/Class-DBI-Plugin-DateTime/trunk/lib/Class/DBI/Plugin/DateTime/Pg.pm 101061 2009-02-20T09:44:03.572989Z daisuke  $
#
# Copyright (c) 2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Class::DBI::Plugin::DateTime::Pg;
use strict;
use base qw(Class::DBI::Plugin::DateTime::Base);
use DateTime::Format::Pg;

BEGIN
{
    # Look ma, I can auto-generate all these :)
    my @types = qw(datetime timestamp timestamptz time timetz date duration);
    foreach my $type (@types) {
        my @args = ($type) x 3;
        push @args, $type eq 'duration' ? ", 'DateTime::Duration'" : '';
        eval sprintf(<<'        EOM', @args);
            sub has_%s
            {
                my $class  = shift;
                my $column = shift;
                my $opts   = shift || {};

                my @args   = exists $opts->{constructor_args} ?
                    @{$opts->{constructor_args}} : ();

                my $fmt     = DateTime::Format::Pg->new(@args);
                my $inflate = sub { $fmt->parse_%s(shift) };
                my $deflate = sub { $fmt->format_%s(shift) };
                __PACKAGE__->_setup_column($class, $column, $inflate, $deflate%s);
            }
        EOM
    }

    {
        no strict 'refs';
        *has_interval = \&has_duration;

        my @methods = map { ("has_$_") } @types;
        *_export_methods = sub { @methods };
    }
}

1;

__END__

=head1 NAME

Class::DBI::Plugin::DateTime::Pg - Use DateTime With PostgreSQL

=head1 SYNOPSIS

  package MyCDBI;
  use base qw(Class::DBI);
  use Class::DBI::Plugin::DateTime::Pg;

  __PACKAGE__->set_db(...);
  __PACKAGE__->table(...);
  __PACKAGE__->has_timestamp('a_timestamp');
  __PACKAGE__->has_date('a_date');
  __PACKAGE__->has_time('a_time');

=head1 DESCRIPTION

Class::DBI::Plugin::DateTime::Pg provides methods to work with DateTime
objects in a Class::DBI + PostgreSQL environment.

=head1 METHODS

All methods take the target column name. You may optionally specify a hashref
as the second argument. For this module, you may specify the following:

=over 4

=item constructor_args

An arrayref of arguments to be passed to the DateTime::Format::Pg object
that is used to parse/format the field.

=back

=head2 has_timestamp

=head2 has_datetime

=head2 has_date

=head2 has_time

=head2 has_timestamptz

=head2 has_timetz

=head2 has_interval

=head2 has_duration

=head1 SEE ALSO

L<DateTime|DateTime> L<DateTime::Format::Pg|DateTime::Format::Pg> L<Class::DBI>

=head1 AUTHOR

Copyright (c) 2005 Daisuke Maki E<lt>dmaki@cpan.orgE<gt>. All rights reserved.

Development funded by Brazil Ltd E<lt>http://b.razil.jpE<gt>

=cut
