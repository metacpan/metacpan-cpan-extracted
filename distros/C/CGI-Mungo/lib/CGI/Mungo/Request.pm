#request object
package CGI::Mungo::Request;

=pod

=head1 NAME

CGI::Mungo::Request - Form request class

=head1 SYNOPSIS

	my $r = $mungo->getRequest();
	my $params = $r->getParameters();

=head1 DESCRIPTION

Class to deal with the current page request

=head1 METHODS

=cut

use strict;
use warnings;
use CGI;
use Carp;
use Data::Dumper;
#########################################################

=head2 new()

	my $r = CGI::Mungo::Request->new();

Constructor, gets all the GET/POST information from the browser request.

=cut

##########################################
sub new{
	my $class = shift;
	my $self = {
		'_parameters' => {},
		'__cgi' => undef
	};
	bless $self, $class;
	$self->_setParameters();
	return $self;
}
#########################################################

=pod

=head2 getParameters()

	my $params = $r->getParameters();

Returns a hash reference of all the GET/POST values from the current request.

=cut

##########################################
sub getParameters{	#get POST or GET data
	my $self = shift;
	return $self->{'_parameters'};
}
#########################################################

=pod

=head2 validate()

	my $rules = {
		'age' => {
			'rule' => '^\d+$',
			'friendly' => 'Your Age'
		}
	};	#the form validation rules
	my($result, $errors) = $r->validate($rules);

Validates all the current form fields against the provided hash reference.

The hash reference contains akey for every field you are concerned about,
which is a reference to another hash containing two elements. The first is the 
actaul matching rule. The second is the friendly name for the field used
in the error message, if a problem with the field is found.

The method returns two values, first being a 0 or a 1 indicating the success of the form.
The second is a reference to a list of errors if any.

=cut

##########################################
sub validate{	#checks %form againist the hash rules
	my($self, $rules) = @_;
	my %params = %{$self->getParameters()};
	my @errors;	#fields that have a problem
	my $result = 0;
	if($rules){
		foreach my $key (keys %{$rules}){	#check each field
			if(!$params{$key} || $params{$key} !~ m/$rules->{$key}->{'rule'}/){	#found an error
				push(@errors, $rules->{$key}->{'friendly'});
			}
		}
		if($#errors == -1){	#no errors
			$result = 1;
		}
	}
	else{
		confess("No rules to validate form");
	}
	return($result, \@errors);
}
#########################################

=pod

=head2 getheader($header)

	$request->getHeader($name)

Returns the value of the specified request header.

=cut

#########################################
sub getHeader{
	my($self, $name) = @_;
	my $value = undef;
	$name = uc($name);
	$name =~ s/\-/_/g;
	if(defined($ENV{"HTTP_" . $name})){
		$value = $ENV{'HTTP_' . $name};
	}
	return $value;
}
#########################################
sub _setParameters{
	my $self = shift;
	my $cgi = $self->__getCgi();   
	foreach my $param ($cgi->param()){
		my $value = $cgi->param($param);
		$self->{'_parameters'}->{$param} = $value;  #save
	}
	return 1;
}
################ss###########################################
sub __getCgi{
	my $self = shift;
	if(!$self->{'__cgi'}){
		$self->{'__cgi'} = CGI->new();	#create a new cgi object
	}
	return $self->{'__cgi'};
}
####################################################
sub __stringfy{
	my($self, $item) = @_;
	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Indent = 0;
	return Dumper($item);
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

##########################################
return 1;