use 5.008;
use strict;
use warnings;

package Data::Conveyor::Storage::DBI::Core::Setup;
BEGIN {
  $Data::Conveyor::Storage::DBI::Core::Setup::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

# Utility storage methods encapsulating statements that all or most
# applications based on Data-Conveyor are going to need. They presume a
# certain database layout, so if you use these conventions, these methods will
# work for you. If not, they won't.
use DBI ':sql_types';

sub add_lookup_items {
    my ($self, $table_name, $table_prefix, @items) = @_;
    $self->log->info('add_lookup_items [%s]', $table_name);

    # normalize the table name
    $table_name = '<P>_' . $table_name unless $table_name =~ /^<P>_/;

    # find the new items by removing the existing ones from the list given to
    # us.
    my %insert = map { $_ => 1 } @items;
    my $item;
    my $sth = $self->prepare("
        SELECT ${table_prefix}_code FROM $table_name
    ");
    $sth->execute;
    $sth->bind_columns(\$item);
    while ($sth->fetch) {
        $self->log->debug('existing [%s] lookup item [%s]', $table_name, $item);
        delete $insert{$item};
    }
    $sth->finish;
    $sth = $self->prepare("
        INSERT INTO $table_name (
            ${table_prefix}_id,
            ${table_prefix}_code,
            ${table_prefix}_create_user,
            ${table_prefix}_create_date
        ) VALUES (
            <NEXTVAL>(<P>_id_seq),
            :item,
            <USER>,
            <NOW>
        )
    ");
    for my $new_item (sort keys %insert) {
        $self->log->info('inserting [%s] lookup item [%s]',
            $table_name, $new_item);
        $sth->bind_param(':item', $new_item, SQL_VARCHAR);
        $sth->execute;
    }
    $sth->finish;
}

sub add_ticket_types {
    my ($self, @ticket_types) = @_;
    $self->add_lookup_items('request_types', 'ret', @ticket_types);
}

sub add_origins {
    my ($self, @origins) = @_;
    $self->add_lookup_items('origins', 'ori', @origins);
}

sub prime {
    my $self = shift;
    $self->add_ticket_types($self->delegate->TT);
    $self->add_origins($self->delegate->OR);
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Storage::DBI::Core::Setup - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 add_lookup_items

FIXME

=head2 add_origins

FIXME

=head2 add_ticket_types

FIXME

=head2 prime

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Conveyor>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Conveyor/>.

The development version lives at L<http://github.com/hanekomu/Data-Conveyor>
and may be cloned from L<git://github.com/hanekomu/Data-Conveyor>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

