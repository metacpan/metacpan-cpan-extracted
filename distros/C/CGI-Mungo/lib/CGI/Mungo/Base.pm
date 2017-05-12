package CGI::Mungo::Base;

=pod

=head1 NAME

CGI::Mungo::Base - Base Mungo class

=head1 SYNOPSIS

	my $r = $mungo->getRequest();
	my $params = $r->getParameters();

=head1 DESCRIPTION

Abstract class used in all other CGI::Mungo classes.

=head1 METHODS

=cut

use strict;
use warnings;
###########################################################
sub new{
	my $class = shift;
	my $self = {
		'_error' => undef
	};
	bless $self, $class;
	return $self;
}
#########################################################

=head2 setError($mesage)

	$obj->setError($message);

Sets an error on the object, the message can be retrieved later.

=cut

#########################################################
sub setError{
	my($self, $error) = @_;
	$self->{'_error'} = $error;
	return 1;
}
#########################################################

=pod

=head2 getError()

	$error = $obj->getError();

Retrieve a previously set error message. This method is used to 
determine the object's error state.

=cut

#########################################################
sub getError{
	my $self = shift;
	return $self->{'_error'};
}
###########################################################

=pod

=head1 Notes

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address

=head1 Copyright

Copyright (c) 2011 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

##########################################################
return 1;
