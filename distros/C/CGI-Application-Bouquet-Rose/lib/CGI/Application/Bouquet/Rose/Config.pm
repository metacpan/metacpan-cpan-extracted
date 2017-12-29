package CGI::Application::Bouquet::Rose::Config;

use strict;
use warnings;

use Carp;

use Config::IniFiles;

use Moo;

use Types::Standard qw/Int Str/;

has config =>
(
	default		=> sub {return ''},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

has section =>
(
	default		=> sub {return ''},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

has verbose =>
(
	default		=> sub {return 0},
	is			=> 'rw',
	isa			=> Int,
	required	=> 0,
);

our $VERSION = '1.06';

# -----------------------------------------------

sub get_docroot
{
	my($self) = @_;

	return $$self{'config'} -> val($$self{'section'}, 'docroot');

} # End of get_docroot.

# -----------------------------------------------

sub get_exclude
{
	my($self) = @_;

	return $$self{'config'} -> val($$self{'section'}, 'exclude');

} # End of get_exclude.

# -----------------------------------------------

sub get_output_dir
{
	my($self) = @_;

	return $$self{'config'} -> val($$self{'section'}, 'output_dir');

} # End of get_output_dir.

# -----------------------------------------------

sub get_tmpl_path
{
	my($self) = @_;

	return $$self{'config'} -> val($$self{'section'}, 'tmpl_path');

} # End of get_tmpl_path.

# -----------------------------------------------

sub get_verbose
{
	my($self) = @_;

	return $$self{'config'} -> val($$self{'section'}, 'verbose');

} # End of get_verbose.

# -----------------------------------------------

sub BUILD
{
	my($self)	= @_;
	my($name)	= '.htcgi.bouquet.conf';

	my($path);

	for (keys %INC)
	{
		next if ($_ !~ m|CGI/Application/Bouquet/Rose/Config.pm|);

		($path = $INC{$_}) =~ s/Config.pm/$name/;
	}

	$self -> config(Config::IniFiles -> new(-file => $path) );
	$self -> section('CGI::Application::Bouquet::Rose');

	if (! $self -> config -> SectionExists($self -> section) )
	{
		Carp::croak "Config file '$path' does not contain the section [" . $self -> section . ']';
	}

}	# End of BUILD.

# --------------------------------------------------

1;

=head1 NAME

C<CGI::Application::Bouquet::Rose::Config> - A helper for CGI::Application::Bouquet::Rose

=head1 Synopsis

	See docs for CGI::Application::Bouquet::Rose.

=head1 Description

C<CGI::Application::Bouquet::Rose::Config> is a pure Perl module.

See docs for C<CGI::Application::Bouquet::Rose>.

=head1 Constructor and initialization

Auto-generated code will create objects of type C<CGI::Application::Bouquet::Rose::Config>. You don't need to.

=head1 Method: get_doc_root()

Return the value of 'doc_root' from the config file lib/CGI/Application/Bouquet/Rose/.htcgi.bouquet.conf.

=head1 Method: get_exclude()

Return the value of 'exclude' from the config file lib/CGI/Application/Bouquet/Rose/.htcgi.bouquet.conf.

=head1 Method: get_output_dir()

Return the value of 'output_dir' from the config file lib/CGI/Application/Bouquet/Rose/.htcgi.bouquet.conf.

=head1 Method: get_tmpl_path()

Return the value of 'tmpl_path' from the config file lib/CGI/Application/Bouquet/Rose/.htcgi.bouquet.conf.

=head1 Method: get_verbose()

Return the value of 'verbose' from the config file lib/CGI/Application/Bouquet/Rose/.htcgi.bouquet.conf.

=head1 Author

C<CGI::Application::Bouquet::Rose::Config> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2008.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2008, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
