use 5.008;
use strict;
use warnings;

package Data::Conveyor::Storage::DBI;
BEGIN {
  $Data::Conveyor::Storage::DBI::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use Error::Hierarchy::Internal::DBI::STH;
use Error ':try';
use parent 'Data::Conveyor::Storage';
__PACKAGE__->mk_scalar_accessors(qw(idcache));
use constant DEFAULTS => (idcache => {},);

# Subclasses could override this to rethrow certain ::DBI::STH exceptions as
# something more specific to the workflow system at hand.
sub ticket_handle_exception {
    my ($self, $E) = @_;
    throw $E;
}

sub ticket_update {
    my ($self, $ticket) = @_;
    try {
        $self->_ticket_update($ticket);
    }
    catch Error::Hierarchy::Internal::DBI::STH with {
        $self->ticket_handle_exception($_[0], $ticket);
    };
    $ticket;
}

sub ticket_insert {
    my ($self, $ticket) = @_;
    try {
        $self->_ticket_insert($ticket);
    }
    catch Error::Hierarchy::Internal::DBI::STH with {
        $self->ticket_handle_exception($_[0], $ticket);
    };
    $ticket;
}

sub cached_statement {
    my ($self, $args) = @_;

    # The result will be an aarray of hashrefs; one element per returned row;
    # each row has a column hash.
    # To compute $argstr, dereference as an array, not a hash, because hash
    # sort order is not defined.
    my $argstr = join $;, %{ $args->{args} };
    return $self->cache->{ $args->{name} }{$argstr} ||= do {
        my (@result, %row);
        my $sth = $self->prepare_named($args->{name} => $args->{SQL});
        while (my ($key, $type) = each %{ $args->{param} || {} }) {
            $sth->bind_param(":$key", $args->{args}{$key}, $type);
        }
        $sth->execute;
        $sth->bind_columns(map { \$row{$_} } @{ $args->{fields} });
        while ($sth->fetch) {
            push @result => \%row;
        }
        $sth->finish;
        \@result;
      }
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Storage::DBI - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 cached_statement

FIXME

=head2 ticket_handle_exception

FIXME

=head2 ticket_insert

FIXME

=head2 ticket_update

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

