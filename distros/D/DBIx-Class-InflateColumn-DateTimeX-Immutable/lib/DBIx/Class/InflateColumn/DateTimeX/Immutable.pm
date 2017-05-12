package DBIx::Class::InflateColumn::DateTimeX::Immutable;

# ABSTRACT: Inflate/deflate DBIx::Class columns to DateTimeX::Immutable objects

use strict;
use warnings;
use base qw/DBIx::Class::InflateColumn::DateTime/;
use DBIx::Class::Carp;
use DateTimeX::Immutable;
use Try::Tiny;
use namespace::autoclean;

our $VERSION = '0.33';

sub _inflate_to_datetime {
    my $self = shift;
    my $rv   = $self->next::method(@_);

    ## warn "\$rv isa " . ref $rv . "\n";
    bless $rv, 'DateTimeX::Immutable';
    return $rv;
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::InflateColumn::DateTimeX::Immutable - Inflate/deflate DBIx::Class columns to DateTimeX::Immutable objects

=head1 VERSION

version 0.33

=head1 SYNOPSIS

Load this component and then declare one or more columns to be of the datetime,
timestamp or date datatype.

    package Event;
    use base 'DBIx::Class::Core';

    __PACKAGE__->load_components(qw/InflateColumn::DateTimeX::Immutable/);
    __PACKAGE__->add_columns(
      starts_when => { data_type => 'datetime' }
      create_date => { data_type => 'date' }
    );

Then you can treat the specified column as a L<DateTimeX::Immutable> object.

    print "This event starts the month of ".
      $event->starts_when->month_name();

=head1 DESCRIPTION

This is subclass of L<DBIx::Class::InflateColumn::DateTime> which inflates
and deflates columns to L<DateTimeX::Immutable> objects. If functions exactly
like its parent, but objects are re-blessed into L<DateTimeX::Immutable>
objections.

See L<DBIx::Class::InflateColumn::DateTime> for more documentation.

=head1 SEE ALSO

L<DateTimeX::Immutable>, L<DBIx::Class::InflateColumn::DateTime>,
L<DateTime>, L<DBIx::Class>

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
