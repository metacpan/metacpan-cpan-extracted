package Banal::Config;

use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

our $VERSION = '0.11';

use File::Spec;

use Banal::Config::General;
use Banal::Config::General::Extended;
use Banal::Utils::Data 		qw(banal_get_data);


use Moose;

has 'verbose' 		=> (is => 'rw', lazy_build=>1); 
has 'debug' 		=> (is => 'rw', lazy_build=>1); 
has 'switches'		=> (is => 'rw', isa   => 'HashRef', default=>sub{{}});		# Typically contains command line switches as produced by Getopt::Long or Getopt::Descriptive, or something that resembles it.
has 'options'		=> (is => 'rw', isa   => 'HashRef', default=>sub{{}});		# The hash that gets passed to "new" for the actual configuration object (xcfg). The 'ConfigFile' option will default to the value of 'source' property. 
has 'source' 		=> (is => 'rw', isa   => 'Str', lazy_build=>1);				# The path to the configuration file. If it's not set, it will be guessed based on the name of the running process ($0). Note that this may be overriden by the "-ConfigFile" option.
has 'xcfg_class' 	=> (is => 'rw', isa   => 'Str', default=>'Banal::Config::General::Extended' ); 
has 'xcfg' 			=> (
     					 	is      	=> 'rw',
     					 	isa     	=> 'Banal::Config::General::Extended',
     					 	lazy_build	=>	1,
      						handles 	=> 	[qw (obj value hash array is_hash is_array is_scalar exists keys delete configfile find)],
 						);
 						
 						
has 'cfg_hash' 						=> (is => 'rw', lazy_build=>1);

has 'cfg_context' 					=> (is => 'rw', lazy_build=>1);		# If you do not set this, you can also provide it with the 'cfg_context' switch or the '-Banal_ConfigContext' option. Otherwise, it will take upon the value given by 'cfg_context_default'
has 'cfg_context_default' 			=> (is => 'rw', lazy_build=>1);		# You may wish to override this, if needed. 

has 'default_options_for_banal_get_data' 	=> (is => 'rw', default=>sub 	{
																	{
																	search_upwards_while_not_defined 	=> 1,
																	use_path_semantics					=> 1,
																	path_separator						=> '/',
																	remove_extra_separators				=> 1,
																	remove_leading_separator			=> 0,
																	remove_trailing_separator			=> 1,
																	remove_empty_segments				=> 1,
																	try_avoiding_repeated_segments		=> 1,
																	lower_case							=> 1,
																	trim								=> 1,	
																	}	
																	}
										);



#-----------------------------------------------
sub load {
	my 	$self	= shift;
	
	return $self->reload();
}

#-----------------------------------------------
sub reload {
	my 	$self	= shift;
	my  $cc		= $self->xcfg_class;
	my 	$opts	= $self->options;
	
	eval {
			require $cc;
		 };
	my  $c 		= $cc->new(-ConfigFile=>$self->source, %$opts);	# source can be overriden with the options.
	
	return $self->xcfg($c);
}
	
	
#
#-----------------------------------------------
sub get_cfg {
	my $self	= shift;
	return $self->grab_cfg(key=>[@_]);
}	


#-----------------------------------------------
sub grab_cfg {
	my $self		= shift;
	my $args		= {@_};
	
	$args->{data}		||= $self->cfg_hash();
	
	unless (defined($args->{context})) {
		$args->{context}	=  $self->cfg_context();
	}
	
	unless (defined($args->{options})) {
		# get a copy.
		my $opts			= $self->default_options_for_banal_get_data();
		$args->{options}	= {%$opts};
	}
	

	return banal_get_data(%$args);
}	


#***************************************************
# Possible Overrides
#***************************************************
#-----------------------------------------------
sub get_default_config_term {
	my 	$self	= shift;
	
	my ($prg_volume, $prg_dirs, $prg_name) = File::Spec->splitpath( $0 );
	
	return $prg_name;
}

#-----------------------------------------------
sub get_default_config_file_base_name {
	my 	$self	= shift;
	
	return $self->get_default_config_term();
}


#***************************************************
# Less likely overrides
#***************************************************
#-----------------------------------------------
sub guess_config_file_path {
	my $self	= shift;
	my $args	= $self->switches;
	   $args	= {%$args, @_};			# swicth overrides are possible by passing arguments to the function.
	
	# If we have an explicit argument for the config file path, return that. 
	foreach my $opt ($self->get_possible_option_names_for_config_file_path(@_)) {
		my $p = $args->{$opt};
		return $p if ($p);
	}
	
	# Or else, if we have a defined ENVIRONMENT variable that contains a value, return that.
	foreach my $v ($self->get_possible_environment_variable_names_for_config_file_path(@_)) {
		my $p = $ENV{$v};
		return $p if ($p);
	}
	
	# Otherwise, return the first config file that exists in a list of possible file paths (normally based on the program name).
	foreach my $p ($self->get_possible_config_file_paths(@_)) {
		return $p if ($p and (-e $p));
	}
	
	
	# Too bad. We've got nothing.
	
	warn  "No config file can be accessed. Does it exist?!\n" if $self->verbose > 7; # DEBUG
	return;
}

	
#-----------------------------------------------
sub get_possible_option_names_for_config_file_path {
	my 	$self	= shift;
	my  @possibilities;
	
	my $term = $self->get_default_config_term();
	
	@possibilities = 	(
							$term . "_cfg",
							"cfg_" . $term,
							"cfg",
						);
	return @possibilities;
}

#-----------------------------------------------
sub get_possible_environment_variable_names_for_config_file_path {
	my 	$self	= shift;
	my  @possibilities;
	
	my $term = $self->get_default_config_term();
	
	@possibilities = 	(
							uc($term . "_CFG"),
							uc("CFG_" . $term),
						);
	return @possibilities;
}

#-----------------------------------------------
sub get_possible_config_file_paths {
	my 	$self	= shift;
	my  @possibilities;

	my $base_name = $self->get_default_config_file_base_name();
	
	@possibilities = 	(
						"./test/etc/" 	. 	$base_name . ".conf",	# this one is for testing purposes during "make test"
						"~/." 			.   $base_name . ".conf",
						"/etc/" 		.   $base_name . ".conf",
						"." 			.   $base_name . ".conf",
						);
	return @possibilities;
}





#**********************************************
# BUILDERS
#**********************************************
#--------------------------------------
sub _build_verbose {
	my $self 	= shift;	
	
	return $self->switches->verbose;
}

#--------------------------------------
sub _build_debug {
	my $self 	= shift;	
	
	return ($self->verbose >= 7);
}

#--------------------------------------
sub _build_source {
	my $self 	= shift;	
	return $self->guess_config_file_path();
}

#--------------------------------------
sub _build_xcfg {
	my $self 	= shift;	
	return $self->load();
}

#--------------------------------------
sub _build_cfg_hash {
	my $self 	= shift;	
	return $self->xcfg()->config;
}


#--------------------------------------
sub _build_cfg_context {
	my $self 	= shift;
	my $ctx	= $self->switches->{cfg_context} || $self->options->{-Banal_ConfigContext} || $self->cfg_context_default;
	return $ctx;
}

#--------------------------------------
sub _build_cfg_context_default {
	my $self 	= shift;
	my $ctx		= $self->get_default_config_term();
	return $ctx;
}



no Moose;
 __PACKAGE__->meta->make_immutable;

1;





__END__

=head1 NAME

Banal::Config - A convenient wrapper around Config::General 


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Banal::Config;

    my $foo = Banal::Config->new(options=>{...}, switches=>{...});
    ...

=head1 EXPORT

None.

=head1 EXPORT_OK

None.

=head1 CLASS METHODS

=head2 get_default_config_term()  

This "term" is in several places, such as :
	- for generating the name of the default command line switch possibly holding the config file path (used when no explicit config file path is given)
	- for generating the name of the default environment variable possibly holding the config file path	(used when no explicit config file path is given)
	- for generating the default base name of the config file, which in turn is searched in several places (used when no explicit config file path is given)
	- for generating the default configuration context within the config file.
	
	
By default, returns the base name of the main program (script).

Can be overridden.


=head2 get_default_config_file_base_name()  

The default base name of the configuration file, which will be searched in several places when trying to "guess" the config file path.
This would only be needed when there is no explicit config file path given.

By default, simply calls "get_default_config_term()".


=head2 guess_config_file_path()

A call to this class method is made in order to build the default value of the "source" attribute, which will be used as the source path for the config file UNLESS one is explicetly given in the options argument to new().

The current implementation goes as follows:
	- It will first try suitable "switches". If one that designates the config fie path is defined, the that one will be return. By default, here are those switches that will be checked for definedness:
			cfg_[%TERM%]  [%TERM%]_cfg cfg
		
			where TERM is obtained by a call to get_default_config_term()
			
	- Then, we will see if there is an ENVIRONMENT variable, 
			[%TERM%]_CFG
			CFG_[%TERM%]
			
	- or else, we will use as config, the first file that exists in the following list: 

			"./test/etc/" 	. 	$base_name . ".conf",	# this one is for testing purposes during "make test"
			"~/." 			.   $base_name . ".conf",
			"/etc/" 		.   $base_name . ".conf",
			"." 			.   $base_name . ".conf",

		where $base_name is obtained by a call to get_default_config_file_base_name()
		
	
=head2 get_possible_option_names_for_config_file_path

Used by guess_config_file_path() to check for command line switches.

Currently returns the list:   cfg_[%TERM%]  [%TERM%]_cfg cfg
where TERM is obtained by a call to get_default_config_term()
	
	
=head2 get_possible_environment_variable_names_for_config_file_path

Used by guess_config_file_path() to check for ENVIRONMENT variables.

Currently returns the list:    [%TERM%]_CFG  CFG_[%TERM%] 

where TERM is obtained by a call to get_default_config_term()
	

=head2 get_possible_config_file_paths()

Used by guess_config_file_path() after trying command line swictches and ENV variables.
At this point (when everything else is exhausted), the first file that exists in the list returned by this function will be used as the config file.

Currently returns the list:   

						"./test/etc/" 	. 	$base_name . ".conf",	# this one is for testing purposes during "make test"
						"~/." 			.   $base_name . ".conf",
						"/etc/" 		.   $base_name . ".conf",
						"." 			.   $base_name . ".conf",

where $base_name is obtained by a call to get_default_config_file_base_name()
	
	
=head1 METHODS

=head2 get_cfg()

Return the configuration value given by key (which may also be an ARRAY of path segments, or one long config key in path notation, or a mix). 

If the value for the given key is not defined, it will be tried in outer contexts (in concentric circles) until it is found.
This way, it is possible to set a value in an outer configuration context, and use it within.

A simple call to:

	 $self->grab_cfg(key=>[@_]);

=head2 grab_cfg()

Return the configuration value given by key (which may also be an ARRAY of path segments, or one long config key in path notation, or a mix). 

If the value for the given key is not defined, it will be tried in outer contexts (in concentric circles) until it is found.
This way, it is possible to set a value in an outer configuration context, and use it within.

	$value = $c->grab_cfg(key => {..}, options => {..}, context=>{..})


By default:
	options : $self->default_options_for_banal_get_data()
	context	: $self->cfg_context();
	

=head2 reload()

Reload the configuratoin file from disk.


=head2 load()

Reload the configuratoin file from disk (when the first such call needs to be distinguished, as opposed to reload().)



=head1 AUTHOR

"aulusoy", C<< <"dev (at) ulusoy.name"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-banal-config at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Banal-Config>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Banal::Config


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Banal-Config>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Banal-Config>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Banal-Config>

=item * Search CPAN

L<http://search.cpan.org/dist/Banal-Config/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 "aulusoy".

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Banal::Config
