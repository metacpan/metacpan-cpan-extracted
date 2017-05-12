package DBIx::Class::InflateColumn::TimeMoment;

# ABSTRACT: Auto-create TimeMoment objects from date and datetime columns.

use 5.008;    # enforce minimum perl version of 5.8
use strict;
use warnings;

our $VERSION = '0.050'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY


use base qw/DBIx::Class/;
use Try::Tiny;
use namespace::clean;

__PACKAGE__->load_components(qw/InflateColumn/);


sub register_column {
    my ( $self, $column, $info, @rest ) = @_;

    $self->next::method( $column, $info, @rest );

    my $requested_type;
    for (qw/datetime timestamp date/) {
        my $key = "inflate_${_}";
        if ( exists $info->{$key} ) {

            # this bailout is intentional
            return unless $info->{$key};

            $requested_type = $_;
            last;
        }
    }

    return if ( !$requested_type and !$info->{data_type} );

    my $data_type = lc( $info->{data_type} || '' );

    return unless ( ( $data_type eq 'datetime' ) or ( $data_type eq 'timestamp' ) or ( $data_type eq 'date' ) );

    # shallow copy to avoid unfounded(?) Devel::Cycle complaints
    my $infcopy = {%$info};

    $self->inflate_column(
        $column => {
            inflate => sub {
                my ( $value, $obj ) = @_;

                # propagate for error reporting
                $infcopy->{__dbic_colname} = $column;

                my $dt = $obj->_inflate_to_timemoment( $value, $infcopy );

                return ( defined $dt )
                    ? $obj->_post_inflate_timemoment( $dt, $infcopy )
                    : undef;
            },
            deflate => sub {
                my ( $value, $obj ) = @_;

                $value = $obj->_pre_deflate_timemoment( $value, $infcopy );
                $obj->_deflate_from_timemoment( $value, $infcopy );
            },
        }
    );
}

sub _inflate_to_timemoment {
    my ( $self, $value, $info ) = @_;

    # Any value should include a timezone element
    # Should a value not include any timezone element, we add a Z to force
    # the timestamp into GMT.  This will not fix any other syntax issues,
    # but does allow, eg PostgreSQL timestamps to be inflated correctly
    # MATCHES: Z or +/- 2 digit timestamp or 4 digit timestamp or UTC/GMT
    $value .= 'Z'
        unless ( $value =~ /(?: Z | (?: [+-] \d{2} (?: :? \d{2} )? ) | UTC | GMT )$/x );

    return try {
        Time::Moment->from_string( $value, lenient => 1 );
    }
    catch {
        $self->throw_exception("Error while inflating '$value' for $info->{__dbic_colname} on ${self}: $_")
            unless $info->{datetime_undef_if_invalid};
        undef;    # rv
    };
}

sub _deflate_from_timemoment {
    my ( $self, $value ) = @_;
    return $value->to_string;
}

sub _post_inflate_timemoment {
    my ( $self, $dt ) = @_;

    return $dt;
}

sub _pre_deflate_timemoment {
    my ( $self, $dt ) = @_;

    return $dt;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::InflateColumn::TimeMoment - Auto-create TimeMoment objects from date and datetime columns.

=head1 VERSION

version 0.050

=for test_synopsis 1;
__END__

=for stopwords DBIC

=head1 SYNOPSIS

Load this component and then declare one or more columns to be of the datetime,
timestamp or date datatype.

  package Event;
  use base 'DBIx::Class::Core';

  __PACKAGE__->load_components(qw/InflateColumn::TimeMoment/);
  __PACKAGE__->add_columns(
    starts_when => { data_type => 'datetime' }
    create_date => { data_type => 'date' }
  );

Then you can treat the specified column as a L<TimeMoment> object.

If you want to inflate no matter what data_type your column is, use
inflate_datetime or inflate_date:

  __PACKAGE__->add_columns(
    starts_when => { data_type => 'varchar', inflate_datetime => 1 }
  );

  __PACKAGE__->add_columns(
    starts_when => { data_type => 'varchar', inflate_date => 1 }
  );

It's also possible to explicitly skip inflation:

  __PACKAGE__->add_columns(
    starts_when => { data_type => 'datetime', inflate_datetime => 0 }
  );

=head1 DESCRIPTION

This module works with Time::Moment IS8601 date formats to inflate/deflate.  A
later version may handle databases in a more forgiving way, but really why not
make them do something sensible.

For more help with using components, see
L<DBIx::Class::Manual::Component/USING>.

=head2 register_column

Chains with the L<DBIx::Class::Row/register_column> method, and sets up
datetime columns appropriately.  This would not normally be directly called by
end users.

In the case of an invalid date, L<Time::Moment> will throw an exception.  To
bypass these exceptions and just have the inflation return undef, use the
C<datetime_undef_if_invalid> option in the column info:

    "broken_date",
    {
        data_type => "datetime",
        default_value => '0000-00-00',
        is_nullable => 1,
        datetime_undef_if_invalid => 1
    }

=for test_synopsis BEGIN { die "SKIP: event has not been declared\n"; }
  print "This event starts the month of ".
    $event->starts_when->strftime('%B');

NOTE: Don't rely on C<InflateColumn::TimeMoment> to parse date strings for you.
The column is set directly for any non-references and
C<InflateColumn::TimeMoment> is completely bypassed.  Instead, use an input
parser to create a TimeMoment object.

=head1 HISTORY

As is obvious from a quick inspection of the code, this module is very heavily
based on and draws code from L<DBIx::Class::InflateColumn::DateTime>, however
it is significantly simplified due to the less well developed timezone handling
and formatter ecosystem.

=head1 SEE ALSO

=over 4

=item More information about the add_columns method, and column metadata,
      can be found in the documentation for L<DBIx::Class::ResultSource>.

=back

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIC resources|DBIx::Class/GETTING
HELP/SUPPORT>.

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2017 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
