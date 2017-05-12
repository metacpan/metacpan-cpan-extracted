use 5.008;
use strict;
use warnings;

package Data::Conveyor::Ticket::Provider;
BEGIN {
  $Data::Conveyor::Ticket::Provider::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use parent 'Class::Scaffold::Storable';
__PACKAGE__->mk_scalar_accessors(
    qw(
      handle prefetch supported timestamp lagmax clause
      )
)->mk_array_accessors(qw(accepted_stages stack));
use constant INFO => qw/
  ticket_no
  stage
  rc
  status
  nice
  /;
use constant PREFETCH_MAX => 12;
use constant DEFAULTS     => (
    prefetch => 5,
    lagmax   => 8
);
use constant NULLCLAUSE => '0=0';

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->storage_type('core_storage');
    $self->clause($self->delegate->ticket_provider_clause || NULLCLAUSE);
    die sprintf "prefetch value too large: %d", $self->prefetch
      if $self->prefetch > PREFETCH_MAX;
}

sub get_next_ticket {
    my $self      = shift;
    my $supported = join ",", map { "'starten_$_'" } @{ shift(@_) };
    my $succeeded = shift;
    $self->stack_clear if $succeeded;
    my $info = $self->_next_unit($supported);
    return unless $info;
    my $ticket =
      $self->delegate->make_obj('ticket', map { $_ => $info->{$_} } INFO);
    $ticket;
}

sub _next_unit {
    my ($self, $supported) = @_;
    $self->handle(
        $self->storage->prepare('
           begin
           ticket_pck.next_ticketblock_select (
                  :supported
                , :prefetch
                , :clause
                , :nextblock
           );
           end;
       ')
    ) unless $self->handle;
    if (   $self->stack_count
        && $self->fresh
        && $supported eq $self->supported) {
        return $self->stack_shift;
    } else {
        $self->supported($supported);
        my $nextblock;
        $self->handle->bind_param(':supported', $supported);
        $self->handle->bind_param(':prefetch',  $self->prefetch);
        $self->handle->bind_param(':clause',    $self->clause);
        $self->handle->bind_param_inout(':nextblock', \$nextblock, 4096);
        $self->handle->execute;
        $self->stack_clear;
        $self->timestamp(time());
        return unless $nextblock;

        for my $token (split /#/, $nextblock) {
            my (%entry, @info);
            @info = split / /, $token;
            die sprintf "severe provider error"
              unless @info == 5;
            @entry{ (INFO) } = @info;
            $self->stack_push(\%entry);
        }
        return $self->_next_unit($supported);
    }
}

sub fresh {
    my $self = shift;
    return (time() - $self->timestamp <= $self->lagmax);
}

sub DESTROY {
    my $self = shift;
    defined $self->handle
      && $self->handle->finish;
}
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Ticket::Provider - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 fresh

FIXME

=head2 get_next_ticket

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

