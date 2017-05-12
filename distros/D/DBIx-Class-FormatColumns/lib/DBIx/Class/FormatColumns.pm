package DBIx::Class::FormatColumns;

use strict;
use warnings;
use vars qw/$VERSION/;
$VERSION = '0.02';

use base qw/DBIx::Class/;

use DateTime::Format::DBI;
use HTML::Entities;

__PACKAGE__->mk_classdata( format_datatype_columns_only => 0 );

=head1 NAME

DBIx::Class::FormatColumns - Creates format accessors for you

=head1 SYNOPSIS

    package Artist;
    __PACKAGE__->load_components(qw/FormatColumns Core/);

    __PACKAGE__->add_columns(
      message => {},
      date_start => { accessor => 'start_date', data_type => 'datetime' }
    );
    __PACKAGE__->format_columns;

    # accessing the data

    print $rc->message_format_ashtml, "\n";
    print $rc->date_start_format_full_datetime, "\n";
    print $rc->start_date_format_long_date, "\n";


=head1 DESCRIPTION

This modul creates format accessors for you.
It tries to be smart and uses the I<data_type> property of the column
to know which kind of format accessors it should create.

=head2 DateTime, Date formats

If you did not use L<DBIx::Class::InflateColumns> to I<inflate> your datetime/date column,
it uses L<DateTime::Format::DBI> to convert the value to an L<DateTime> object.

=head3 format_full_date

Calls DateTime->locale->full_date_format to retrieve the format string to put it into
a DateTime->strftime call.

=head3 format_long_date

Calls DateTime->locale->long_date_format to retrieve the format string to put it into
a DateTime->strftime call.

=head3 format_medium_date

Calls DateTime->locale->medium_date_format to retrieve the format string to put it into
a DateTime->strftime call.

=head3 format_short_date

Calls DateTime->locale->short_date_format to retrieve the format string to put it into
a DateTime->strftime call.

=head3 format_full_time

Calls DateTime->locale->full_time_format to retrieve the format string to put it into
a DateTime->strftime call.

=head3 format_long_time

Calls DateTime->locale->long_time_format to retrieve the format string to put it into
a DateTime->strftime call.

=head3 format_medium_time

Calls DateTime->locale->medium_time_format to retrieve the format string to put it into
a DateTime->strftime call.

=head3 format_short_time

Calls DateTime->locale->short_time_format to retrieve the format string to put it into
a DateTime->strftime call.

=head3 format_full_datetime

Calls DateTime->locale->full_datetime_format to retrieve the format string to put it into
a DateTime->strftime call.

=head3 format_long_datetime

Calls DateTime->locale->long_datetime_format to retrieve the format string to put it into
a DateTime->strftime call.

=head3 format_medium_datetime

Calls DateTime->locale->medium_datetime_format to retrieve the format string to put it into
a DateTime->strftime call.

=head3 format_short_datetime

Calls DateTime->locale->short_datetime_format to retrieve the format string to put it into
a DateTime->strftime call.

=head2 Data formats

=head3 format_ashtml

Uses L<HTML::Entities> to encode all entities. But it also replaces all linebreaks with I< <br /> >.


=head1 METHODS

=head2 format_columns( [ @columns ] )

Creates format accessors for every column in I<@columns>.
Uses __PACKAGE__->columns if I<@columns> is empty;

=cut

sub format_columns {
    my ($self, @columns) = @_;

    @columns = $self->columns
      unless scalar(@columns) > 0;

    foreach my $col (@columns) {
        my $ci = $self->column_info( $col );
        
        my $type = exists $ci->{data_type}
          ? lc $ci->{data_type}
          : '';
          
        next if $self->format_datatype_columns_only
          && $type eq '';
                
        my @names = ( $col );
        push @names, $ci->{accessor}
          if exists $ci->{accessor}
          && $ci->{accessor} ne $col;        

        foreach my $name (@names) {
            no strict 'refs';

            if( $type =~ m!^date! ) {

                my @methods = qw/
                  full_date_format long_date_format medium_date_format short_date_format
                  full_time_format long_time_format medium_time_format short_time_format
                  full_datetime_format long_datetime_format medium_datetime_format short_datetime_format
                /;

                foreach my $method (@methods) {

                    $method =~ m!^(.*)_format$!;
                    *{"${self}::$name\_format_$1"} = sub {
                        my $self = shift;
                        my $dt = $self->$col;
                        unless ( ref($dt) =~ m!DateTime! ) {
                            my $parser = DateTime::Format::DBI->new( $self->result_source->storage->dbh );
                            $dt = $parser->parse_datetime( $dt );
                        }
                        return $dt->strftime( $dt->locale->$method );
                    };
                }
            }
            else {

                *{"${self}::$name\_format_ashtml"} = sub {
                    my $self = shift;
                    my $data = $self->$col;

                    $data = encode_entities($data);
                    $data =~ s!\r?\n\r?!<br />\n!g;

                    return $data;
                };
            }
        }
    }
}

=head2 format_datatype_columns_only( $boolean )

If set to a true value, format_columns will only format columns
that have a I<data_type> configured. The default value is 0.

=head1 AUTHOR

Sascha Kiefer <esskar@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;




