package CGI::Lazy::Widget::DomLoader;

use strict;

use base qw(CGI::Lazy::Widget);
use JSON;

#----------------------------------------------------------------------------------------
sub new {
	my $class = shift;
	my $q = shift;
	my $inputvars = shift;

	my $vars = {};

	foreach (keys %{$inputvars->{lookups}}) {
		$vars->{lookups}->{$_} = $_;
		$vars->{lookups}->{$_}->{preload} = 1;
	}

	$vars->{raw} = $inputvars->{raw};

        my $widgetID = $vars->{id};
	return bless {_q => $q, _vars => $vars, _widgetID => $widgetID}, $class;
}

#----------------------------------------------------------------------------------------
sub output {
	my $self = shift;

	my $rawObjectJs;

        foreach my $rawvar (keys %{$self->vars->{raw};}) {
		$rawObjectJs .= "var $rawvar = JSON.parse('".to_json($self->vars->{raw}->{$rawvar})."');\n";
        }

        $rawObjectJs = $self->q->jswrap($rawObjectJs) if $rawObjectJs;

	my $output = $self->preloadLookup;
	$output .= $rawObjectJs if $rawObjectJs;

	return $output;
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

CGI::Lazy::Widget::DomLoader

=head1 SYNOPSIS

	use CGI::Lazy;

	my $q = CGI::Lazy->new('frobnitz.conf');

	my $domloader = $q->widget->domloader({

			raw => {
				jsobjectname 	=> $perlvariable,
				someotherobj	=> $someOtherVariable,

			},

			lookups {

				countryLookup => {  #name of resultant DOM object

					sql 		=> 'select ID, country from countryCodeLookup ', 

					orderby		=> ['ID'],

					output		=> 'hash',

					primarykey	=> 'ID',

				},

			},

			});

	print $domloader->output;

=head1 DESCRIPTION

CGI::Lazy::Widget::DomLoader is an object for preloading useful stuff into a page's DOM, such as lookup queries, or any javascript object that might be desired.  This is functionality that is duplicated from the internals of CGI::Lazy::Widget::Dataset, but it's included as a separate object for preloading arbitrary values for other purposes.

It's created by calling the domloader method on the widget object, and passing in its configuration hashref.

=head2 lookups

Queries to be run and loaded into the DOM as simple lists.

=head2 raw

Raw perl variables to be parsed and converted to javascript objects.  This is intended to facilitate loading complex data structures, arrays of arrays, hashes of hashes, etc into the DOM.  Basically you create it in perl, and it gets parsed into JS and loaded into the DOM for the page.

=head1 METHODS

=head2 output ()

Returns output of object for printing to the web page

=cut

