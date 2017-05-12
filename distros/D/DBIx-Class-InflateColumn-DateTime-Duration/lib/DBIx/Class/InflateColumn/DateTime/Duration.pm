package DBIx::Class::InflateColumn::DateTime::Duration;

=head1 NAME

DBIx::Class::InflateColumn::DateTime::Duration - Auto create 
DateTime::Duration objects from columns

=head1 SYNOPSIS

Load this component and then declare one or more columns as duration columns.

  package Holiday;
  __PACKAGE__->load_components(qw/InflateColumn::DateTime::Duration Core/);
  __PACKAGE__->add_columns(
      length => {
          datatype      => 'varchar',
          size          => 255,
          is_nullable   => 1,
          is_duration   => 1,
      },
  );

Then you can treat the specified column as a L<DateTime::Duration> object.

  print 'days: ', $holiday->length->delta_days, "\n";
  print 'hours: ', $holiday->length->delta_hours, "\n";

=head1 DESCRIPTION

This module inflates/deflates designated columns into L<DateTime::Duration> objects.

=cut

use strict;
use warnings;

our $VERSION = '0.01002';

use base qw(DBIx::Class);

use Try::Tiny;
use DateTime::Format::Duration::XSD;

=head1 METHODS

=head2 register_column

Chains with the "register_column" in L<DBIx::Class::Row> method, and sets up duration 
columns appropriately. This would not normally be directly called by end users.

=cut

sub register_column {
    my ($self, $column, $info, @rest) = @_;
    $self->next::method($column, $info, @rest);

    return unless defined $info->{is_duration};

    $self->inflate_column(
        $column => {
            inflate => sub {
                my ($value, $obj) = @_;
                my $duration;

                if ($value) {
                    my $parser = DateTime::Format::Duration::XSD->new;

                    try {
                        $duration = $parser->parse_duration($value);
                    }
                    catch {
                        $self->throw_exception('Could not parse duration from ' . $value);
                    }
                }

                return $duration;
            },
            deflate => sub {
                my ($value, $obj) = @_;

                return unless (ref $value eq 'DateTime::Duration');

                my $parser = DateTime::Format::Duration::XSD->new;

                return $parser->format_duration($value);
            },
        }
    );
}

=head1 SEE ALSO

L<DateTime::Duration>,
L<DBIx::Class::InflateColumn>,
L<DBIx::Class>.

=head1 AUTHOR

Pete Smith, E<lt>pete@cubabit.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Pete Smith

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

