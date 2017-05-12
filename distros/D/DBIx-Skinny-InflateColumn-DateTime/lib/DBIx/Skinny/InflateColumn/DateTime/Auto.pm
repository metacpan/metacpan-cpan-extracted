package DBIx::Skinny::InflateColumn::DateTime::Auto;

use strict;
use warnings;

use DateTime;
use DateTime::Format::Strptime;
use DateTime::Format::MySQL;
use DateTime::TimeZone;

sub import {
    my $class = shift;
    my %args = @_;
    my $timezone          = $args{time_zone} || DateTime::TimeZone->new(name => 'local');
    my @rules             = @{ $args{rules} || [qr/^.+_at$/, qr/^.+_on$/] };
    my @auto_insert_rules = @{ $args{auto_insert_rules} || [qr/^created_at$/, qr/^created_on$/, qr/^updated_at$/, qr/^updated_on$/] };
    my @auto_update_rules = @{ $args{auto_update_rules} || [qr/^updated_at$/, qr/^updated_on$/] };

    my $schema = caller;
    for my $rule ( @rules ) {
        $schema->inflate_rules->{ $rule }->{ inflate } = sub {
            my $value = shift or return;
            return $value if ref $value eq 'DateTime';
            my $dt = DateTime::Format::Strptime->new(
                pattern   => '%Y-%m-%d %H:%M:%S',
                time_zone => $timezone,
            )->parse_datetime($value);
            return DateTime->from_object( object => $dt );
        };
        $schema->inflate_rules->{ $rule }->{ deflate } = sub {
            my $value = shift;
            return DateTime::Format::MySQL->format_datetime($value);
        };
    }
    my $schema_info = $schema->schema_info;
    push @{ $schema->common_triggers->{ pre_insert } }, sub {
        my ($self, $args, $table) = @_;
        my $columns = $schema_info->{ $table }->{ columns };
        my $now = DateTime->now(time_zone => $timezone);

    COLUMN_LOOP:
        for my $column ( grep { !$args->{$_} } @{$columns} ) {
        RULE_LOOP:
            for my $rule ( @auto_insert_rules ) {
                if ( $column =~ m/$rule/ ) {
                    $args->{$column} = $now;
                    last RULE_LOOP;
                }
            }
        }
    };
    push @{ $schema->common_triggers->{ pre_update } }, sub {
        my ($self, $args, $table) = @_;
        my $columns = $schema_info->{ $table }->{ columns };
        my $now = DateTime->now(time_zone => $timezone);

    COLUMN_LOOP:
        for my $column ( grep { !$args->{$_} } @{$columns} ) {
        RULE_LOOP:
            for my $rule ( @auto_update_rules ) {
                if ( $column =~ m/$rule/ ) {
                    $args->{$column} = $now;
                    last RULE_LOOP;
                }
            }
        }
    };
}

1;
__END__

=head1 NAME

DBIx::Skinny::InflateColumn::DateTime::Auto - DateTime inflate/deflate and auto insert update time for DBIx::Skinny

=head1 SYNOPSIS

Use this module in your schema.

  package Your::DB::Schema;
  use DBIx::Skinny::Schema;
  use DBIx::Skinny::InflateColumn::DateTime;

  install_table table1 => {
      pk 'id';
      columns qw/id name created_at updated_at/;
  };

  install_table table2 => {
      pk 'id';
      columns qw/id name booked_on created_on updated_on/;
  };

In your app.

  my $row = Your::DB->single('table1', { id => 1 });
  print $row->created_at->ymd;  # created_at is DateTime object

=head1 DESCRIPTION

DBIx::Skinny::InflateColumn::DateTime provides inflate/deflate settings for *_at/*_on columns.

It also set trigger for pre_insert and pre_update.

Its concept refer to DBIx::Class::InflateColumn::DateTime, and some factor from DBIx::Class::InflateColumn::DateTime::Auto (http://blog.hide-k.net/archives/2006/08/dbixclassauto_i.php).

=head1 INFLATE/DEFLATE

This module installs inflate rule for /_(at|on)$/ columns.

That columns will be inflated as DateTime objects.

=head1 OPTIONS

=head2 time_zone

default time_zone is 'local'.

set this option if you decide other time_zone.

Example:

  use DBIx::Skinny::InflateColumn::DateTime (time_zone => DateTime::TimeZone->new(name => 'Asia/Tokyo'));

=head2 rules

default rules is [qr/^.+_at$/, qr/^.+_on$/].

set this option if you decide other rules.

Example:

  use DBIx::Skinny::InflateColumn::DateTime (rules => [qr/^created$/, qr/^updated$/]);


=head2 auto_insert_rules

default rules is [qr/^created_at$/, qr/^created_on$/, qr/^updated_at$/, qr/^updated_on$/].

set this option if you decide other rules.

Example:

  use DBIx::Skinny::InflateColumn::DateTime (auto_insert_rules => [qr/^created$/, qr/^updated$/]);


=head2 auto_update_rules

default rules is [qr/^updated_at$/, qr/^updated_on$/].

set this option if you decide other rules.

Example:

  use DBIx::Skinny::InflateColumn::DateTime (auto_insert_rules => [qr/^updated$/]);

=head1 TRIGGERS

=head2 pre_insert

Set current time stamp if column match auto_insert_rules and exists.

=head2 pre_update

Set current time stamp if column match auto_update_rules and exists.

Row object's columns will be updated as well.

=head1 AUTHOR

Ryo Miyake E<lt>ryo.studiom {at} gmail.comE<gt>

=head1 SEE ALSO

DBIx::Skinny, DBIx::Class::InflateColumn::DateTime

http://blog.hide-k.net/archives/2006/08/dbixclassauto_i.php

=head1 AUTHOR

Ryo Miyake  C<< <ryo.studiom __at__ gmail.com> >>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
