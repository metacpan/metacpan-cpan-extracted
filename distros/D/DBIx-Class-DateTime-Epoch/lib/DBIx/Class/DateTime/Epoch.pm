package DBIx::Class::DateTime::Epoch;

use strict;
use warnings;

our $VERSION = '0.10';

use base qw( DBIx::Class );

use DateTime;

__PACKAGE__->load_components( qw( InflateColumn::DateTime ) );

# back compat
sub add_columns {
    my( $class, @cols ) = @_;
    my @columns;

    while (my $col = shift @cols) {
        my $info = ref $cols[0] ? shift @cols : {};

        if( my $type = delete $info->{ epoch } ) {
            $info->{ inflate_datetime } = 'epoch';

            if( $type =~ m{^[cm]time$} ) {
                __PACKAGE__->load_components( 'TimeStamp' );
                $info->{ set_on_create } = 1;
                $info->{ set_on_update } = 1 if $type eq 'mtime';
            }
        }

        push @columns, $col => $info;

    }

    $class->next::method( @columns );
}

sub _inflate_to_datetime {
    my( $self, $value, $info, @rest ) = @_;
    return $self->next::method( $value, $info, @rest )
        unless $info->{ data_type } =~ m{int}i || (exists $info->{ inflate_datetime } && $info->{ inflate_datetime } eq 'epoch');

    return DateTime->from_epoch( epoch => $value );
}

sub _deflate_from_datetime {
    my( $self, $value, $info, @rest ) = @_;
    return $self->next::method( $value, $info, @rest )
        unless $info->{ data_type } =~ m{int}i || (exists $info->{ inflate_datetime } && $info->{ inflate_datetime } eq 'epoch');

    return $value->epoch;
}

1;

__END__

=head1 NAME

DBIx::Class::DateTime::Epoch - Automatic inflation/deflation of epoch-based columns to/from DateTime objects

=head1 SYNOPSIS

    package MySchema::Foo;
    
    use base qw( DBIx::Class );
    
    __PACKAGE__->load_components( qw( DateTime::Epoch TimeStamp Core ) );
    __PACKAGE__->add_columns(
        name => {
            data_type => 'varchar',
            size      => 10,
        },
        bar => { # epoch stored as an int
            data_type        => 'bigint',
            inflate_datetime => 1,
        },
        baz => { # epoch stored as a string
            data_type        => 'varchar',
            size             => 50,
            inflate_datetime => 'epoch',
        },
        # working in conjunction with DBIx::Class::TimeStamp
        creation_time => {
            data_type        => 'bigint',
            inflate_datetime => 1,
            set_on_create    => 1,
        },
        modification_time => {
            data_type        => 'bigint',
            inflate_datetime => 1,
            set_on_create    => 1,
            set_on_update    => 1,
        }
    );

=head1 DATETIME::FORMAT DEPENDENCY

There have been no assumptions made as to what RDBMS you will be using. As per 
the note in the L<DBIx::Class::InflateColumn::DateTime documentation|DBIx::Class::InflateColumn::DateTime/DESCRIPTION>, 
you will need to install the DateTime::Format::* module that matches your RDBMS 
of choice.

=head1 DESCRIPTION

This module automatically inflates/deflates DateTime objects from/to epoch
values for the specified columns. This module is essentially an extension to
L<DBIx::Class::InflateColumn::DateTime> so all of the settings, including
C<locale> and C<timezone>, are also valid.

A column will be recognized as an epoch time given one of the following scenarios:

=over 4

=item * C<data_type> is an C<int> of some sort and C<inflate_datetime> is also set to a true value

=item * C<data_type> is some other value (e.g. C<varchar>) and C<inflate_datetime> is explicitly set to C<epoch>.

=back

L<DBIx::Class::TimeStamp> can also be used in conjunction with this module to support
epoch-based columns that are automatically set on creation of a row and updated subsequent
modifications.

=head1 METHODS

=head2 add_columns( )

Provides backwards compatibility with the older DateTime::Epoch API.

=head2 _inflate_to_datetime( )

Overrides column inflation to use C<Datetime-E<gt>from_epoch>.

=head2 _deflate_from_datetime( )

Overrides column deflation to call C<epoch()> on the column value.

=head1 SEE ALSO

=over 4

=item * L<DBIx::Class>

=item * L<DBIx::Class::TimeStamp>

=item * L<DateTime>

=back

=head1 AUTHORS

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

Adam Paynter E<lt>adapay@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2012 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

