package CGI::Lazy::Plugin;

use strict;

use CGI::Lazy::Globals;

#-------------------------------------------------------------------------------
sub AUTOLOAD {
	my $self = shift;

	my $name = our $AUTOLOAD;
	return if $name =~ /::DESTROY$/;
	my @list = split "::", $name;
	my $value = pop @list;

	if (@_) {
		return $self->{_plugins}->{$value} = shift; 
	} else {
		return $self->{_plugins}->{$value}; 
	}
}
#------------------------------------------------------------
sub config {
	my $self = shift;

	return $self->q->config;
}

#------------------------------------------------------------
sub q {
	my $self = shift;

	return $self->{_q};
}

#------------------------------------------------------------
sub new {
	my $class = shift;
	my $q = shift;

	my $self = bless {_q => $q}, $class;

	$self->{_plugins} = $self->config->plugins;

	return $self; 
}

1

__END__

=head1 LEGAL

#===========================================================================

Copyright (C) 2008 by Nik Ogura. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Bug reports and comments to nik.ogura@gmail.com. 

#===========================================================================

=head1 NAME

CGI::Lazy::Plugin

=head1 SYNOPSIS

	use CGI::Lazy;

	my $q = CGI::Lazy->new('/path/to/config/file');

=head1 DESCRIPTION

Internal module used for tracking which pieces of CGI::Lazy are being used.  Plugins are enabled or excluded in the config file.

=head1 METHODS

=head2 config ( ) 

Returns CGI::Lazy::Config object.

=head2 q ()

Returns CGI::Lazy object

=head2 new ( q )

Constructor

=head3 q

CGI::Lazy Object

=cut

