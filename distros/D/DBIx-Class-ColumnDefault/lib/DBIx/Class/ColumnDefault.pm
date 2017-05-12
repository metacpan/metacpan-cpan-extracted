package DBIx::Class::ColumnDefault;
{
  $DBIx::Class::ColumnDefault::VERSION = '0.122200';
}

use strict;
use warnings;

my $fn_now = qr/^(?:
               current(\s+|_)timestamp
             | \Qnow()\E
             | \Q(datetime('now'))\E
             )$/ix;

sub insert {
    my $self    = shift;
    my $colinfo = $self->result_source->columns_info;
    while (my ($column, $info) = each %$colinfo) {
        next if $info->{is_auto_increment} or $self->has_column_loaded($column);
        my $dv = $info->{default_value};
        if (ref($dv) eq 'SCALAR' and $$dv =~ $fn_now) {
            $dv = DateTime->now;
        }
        my $accessor = $info->{accessor} || $column;
        $self->$accessor($dv) if defined $dv;
    }
    $self->next::method(@_);
}

1;

__END__

=head1 NAME

DBIx::Class::ColumnDefault - Automatically set column default values on insert

=head1 VERSION

version 0.122200

=head1 SYNOPSIS

  package My::Schema::SomeTable;

  __PACKAGE__->load_components(qw/ColumnDefault Core/);

  __PACKAGE__->add_columns(
    str => {
      data_type     => 'char',
      default_value => 'aaa',
      is_nullable   => 1,
      size          => 3
    },
    dt => {
      date_type     => 'datetime',
      is_nullable   => 1,
      default_value => \"(datetime('now'))",
    },
  );


=head1 DESCRIPTION

Automatically set fields with default values from schema definition during insert.

If the C<default_value> is a reference to a scalar and matches one of the following, then the value will
be the current datetime

  now()
  current_timestamp
  (datetime('now'))

=head1 AUTHOR

Graham Barr E<lt>gbarr@cpan.orgE<gt>

COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Graham Barr.

This is free software; you can redistribute it and/or modify it under the same terms as the
Perl 5 programming language system itself.

=cut

1;
