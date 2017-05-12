
package Class::Prevayler::FileCounter;
use strict;
use warnings;
use Carp;

BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = 0.02;
    @ISA     = qw (Exporter);

    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw ();
    @EXPORT_OK   = qw ();
    %EXPORT_TAGS = ();
    use Class::MethodMaker
      new_with_init => 'new',
      new_hash_init => 'hash_init',
      get_set       => [ 'next_logfile_number', ];
}

########################################### main pod documentation begin ##
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Class::Prevayler::FileCounter - Prevayler implementation - www.prevayler.org


=head1 DESCRIPTION

this class is an internal part of the Class::Prevayler module.

=head1 AUTHOR

	Nathanael Obermayer
	CPAN ID: nathanael
	natom-pause@smi2le.net
	http://a.galaxy.far.far.away/modules

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Class::Prevayler

=cut

sub init {
    my $self   = shift;
    my %values = (@_);
    $self->hash_init(%values);
    ( $self->next_logfile_number )
      or croak "need the next number!";
    return;
}

sub reserve_number_for_command {
    my ($self) = @_;

    return $self->next_logfile_number();
}

sub reserve_number_for_snapshot {
    my ($self) = @_;

    $self->next_logfile_number( $self->next_logfile_number + 2 );
    return $self->next_logfile_number - 1;
}

1;    #this line is important and will help the module return a true value
__END__

