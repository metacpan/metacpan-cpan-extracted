package Apache::Wyrd::Interfaces::IndexUser;
use strict;
use warnings;
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Interfaces::IndexUser - Convenience Class for Index-driven Wyrds

=head1 SYNOPSIS

	use base qw(Apache::Wyrd::Intefaces::IndexUser Apache::Wyrd);

	sub _startup {
		my ($self) = @_;
		$self->_init_index;
	}

	sub _format_output {
		my ($self) = @_;
		$self->index->update_entry($self);

		...

	}

	sub _shutdown {
		my ($self) = @_;
		$self->_dispose_index;
	}

=head1 DESCRIPTION

A very simple and lazy inteface for invoking a BASECLASS::Index object
as an index and storing it as $self->{index};

=head1 METHODS

=item _init_index

Invoke a handle to a new default index (assuming the class
BASECLASS::Index holds a default definition and put it in the index data
key of the Wyrd.  It can then be used at any point in the body of the
Wyrd's perl code.

=item _dispose_index

Shutdown the index and dispose of the handle.  Must be called to avoid
database/dbfile handle "leaks" (open but dead database connections).

=cut

sub _init_index {
	my ($self) = @_;
	return $self->{'index'} if (UNIVERSAL::isa($self->{'index'}, $self->_base_class . '::Index'));
	my $formula = $self->_base_class . '::Index';
	eval("use $formula") unless ($INC{$formula});
	$self->{'index'} = eval($formula . '->new');
	$self->_raise_exception("Failed to open the index: $formula; reason: $@") if ($@);
	return $self->{'index'};
}

sub _dispose_index {
	my ($self) = @_;
	if (UNIVERSAL::isa($self->{'index'}, $self->_base_class . '::Index')) {
		$self->{'index'}->close_db;
	}
	$self->{'index'} = undef;
	return;
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;