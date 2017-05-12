package CGI::Lazy::Config;

use strict;

use JSON;
use Carp;
use CGI::Lazy::Globals;

#-------------------------------------------------------------------------------
sub AUTOLOAD {
	my $self = shift;

	my $name = our $AUTOLOAD;
	return if $name =~ /::DESTROY$/;
	my @list = split "::", $name;
	my $value = pop @list;

	if (@_) {
		return $self->{_config}->{$value} = shift; 
	} else {
		return $self->{_config}->{$value}; 
	}
}

#-------------------------------------------------------------------------------
sub configfile {
	my $self = shift;
	
	return $self->{_configfile};
}

#-------------------------------------------------------------------------------
sub get {
	my $self = shift;
	my $prop = shift;
	
	return $self->{_config}{$prop};
}

#-------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my $q = shift;
	my $filename = shift;

	my $json;
	my $conf;

	if (ref $filename) {
		$conf = $filename;
	} else {	
		eval {
			open IF, "< $CONFIGROOT/$filename" or croak $!; 

			while (<IF>) {
				$json .= $_ unless ($_ =~ /^\s*#/);
			}
			close IF;
		};

		if ($@) {
			$q->errorHandler->noConfig($filename);
		}
		
		eval {
			$conf = from_json($json);
		};

		if ($@) {
			$q->errorHandler->badConfig($filename);
		}
	}

	my $self = {_q => $q, _config =>$conf, _configfile => $filename};

	bless $self, $class;

	return $self;
}

#-------------------------------------------------------------------------------
sub set {
	my $self = shift;
	my $name = shift;
	my $value = shift;

	$self->{_config}{$name} = $value;
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

CGI::Lazy::Config

=head1 SYNOPSIS

	use CGI::Lazy;

	my $q = CGI::Lazy->new('/path/to/config/file');

	my $c = $q->config;

	my $prop = $c->property1; #getter

	$c->property1('foo'); #setter

=head1 DESCRIPTION

Internal module used for parsing config file and getting/ setting values from same.

Configuration values are accessed by calling the property name on the config object without arguments.

The same method doubles as a setter if called with arguments.

=head1 METHODS

=head2 configfile ()

Returns the name of the config file the object is based on


=head2 get ( property )

Static accessor method.  Use in places where autoloading isn't appropriate.  e.g $q->widget->"somestring".$variable  or some such nonsense.

=head3 property

name of the property to retrieve


=head2 new ( q vars )

Constructor.  Creates and returns the config object.

=head3 q

CGI::Lazy object.

=head3 vars

Hashref containing initialization variables, or absolute path to config file.


CGI::Lazy::Config uses an autoloader to get and set its properties.  You can access any property by calling $q->config->var  where var is the name of the property.

=head3 set ( prop, value )

Static property setter.  For use when autoloading isn't possible.

=head3 prop

Name of property

=head3 value

Value of property

=cut


