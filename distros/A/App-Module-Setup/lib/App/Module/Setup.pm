#! perl

package App::Module::Setup;

### Please use this module via the command line module-setup tool.

our $VERSION = '0.06';

use warnings;
use strict;
use File::Find;
use File::Basename qw( dirname );
use File::Path qw( mkpath );

sub main {
    my $options = shift;
    # Just in case we're called as a method.
    eval { $options->{module} || 1 } or $options = shift;

    my $tpldir = "templates/". $options->{template};
    my $mod = $options->{module};

    # Replacement variables
    my $vars =
      { "module.name"    => $mod,	# Foo::Bar
	"module.version" => "0.01",
	"current.year"   => 1900 + (localtime)[5],
	"author.name"    => $options->{author} || (getpwuid($<))[6],
	"author.email"   => $options->{email},
	"author.cpanid"  => $options->{"cpanid"},
      };

    my $dir;
    if ( $options->{'install-templates'} ) {
	$dir = $tpldir;
    }
    else {
	( $dir = $mod ) =~ s/::/-/g;
	$vars->{"module.distname"} = $dir;	# Foo-Bar
	$vars->{"module.distnamelc"} = lc($dir);
	( my $t = $mod ) =~ s/::/\//g;
	$vars->{"module.filename"} = $t . ".pm";	# Foo/Bar.pm
	$vars->{"author.cpanid"} ||= $1
	  if $options->{email}
	     && $options->{email} =~ /^(.*)\@cpan.org$/i;
	$vars->{"author.cpanid"} = uc( $vars->{"author.cpanid"} )
	  if $vars->{"author.cpanid"};
    }

    if ( -d $dir ) {
	die( "Directory $dir exists. Aborted!\n" );
    }

    # Get template names and data.
    my ( $files, $dirs, $data );
    for my $cfg ( "./", @{ $options->{_configs} } ) {
	if ( -d "$cfg$tpldir" ) {
	    ( $files, $dirs, $data ) =
	      load_templates_from_directory( "$cfg$tpldir" );
	    last if $files;
	}
    }

    # Nope. Use built-in defaults.
    unless ( $files ) {
	unless ( $options->{template} eq "default" ) {
	    warn( "No templates found for ", $options->{template},
		  ", using default templates\n" );
	}
	require App::Module::Setup::Templates::Default;
	( $files, $dirs, $data ) =
	  App::Module::Setup::Templates::Default->load;
    }

    if ( $options->{'install-templates'} ) {
	warn( "Writing built-in templates to $dir\n" );
    }
    else {
	# Change the magic _Module.pm name to
	# the module file name.
	for my $file ( @$files ) {
	    if ( $file =~ /^(.*)_Module.pm$/ ) {
		my $t = $1 . $vars->{"module.filename"};
		push( @$dirs, dirname($t) );
		$data->{$t} = delete $data->{$file};
		$file = $t;
	    }
	}
    }

    my $massage;
    if ( $options->{'install-templates'} ) {
	$massage = sub { $_[0] };
    }
    else {
	require App::Module::Setup::Templates;
	$massage = App::Module::Setup::Templates->can("templater");
    }

    # Create the neccessary directories.
    mkpath($dir, $options->{trace}, 0777 );
    chdir($dir) or die( "Error creating directory $dir\n" );
    mkpath( $dirs, $options->{trace}, 0777 );

    for my $target ( @$files ) {
	$vars->{" file"} = $target;
	open( my $fd, '>', $target )
	  or die( "Error opening ", "$dir/$target: $!\n" );
	print { $fd } $massage->( $data->{$target}, $vars );
	close($fd)
	  or die( "Error writing $target: $!\n" );
	warn( "Wrote: $dir/$target\n" )
	  if $options->{verbose};
    }

    # Postprocessing, e.g., set up git repo.
    foreach my $cmd ( @{ $options->{postcmd} } ) {
	system( $cmd );
    }

    # If we have a git repo, add all boilerplate files.
    if ( -d ".git" ) {
	system( "git", "add", @$files );
    }

    chdir("..");		# see t/90-ivp.t

    return 1;			# assume everything went ok
}

sub load_templates_from_directory {
    my ( $dir ) = shift;
    my $dl = length($dir);
    $dl++ unless $dir =~ m;/$;;
    my ( $files, $dirs, $data );

    find( { wanted => sub {
		return if length($_) < $dl; # skip top
		my $f = substr( $_, $dl );  # file relative to top
		if ( -d $_ ) {
		    push( @$dirs, $f );
		    return;
		}
		return unless -f $_;
		return if /~$/;

		push( @$files, $f );
		open( my $fd, '<', $_ )
		  or die( "Error reading template $_: $!\n" );
		local $/;
		$data->{$f} = <$fd>;
		close($fd);
	    },
	    no_chdir => 1,
	  }, $dir );

    return ( $files, $dirs, $data );
}


=head1 NAME

App::Module::Setup - a simple setup for a new module


=head1 SYNOPSIS

Nothing in here is meant for public consumption. Use F<module-setup>
from the command line.

    module-setup --author="A.U. Thor" --email=a.u.thor@example.com Foo::Bar


=head1 DESCRIPTION

This is the core module for App::Module::Setup. If you're not looking
to extend or alter the behavior of this module, you probably want to
look at L<module-setup> instead.

App::Module::Setup is used to create a skeletal CPAN distribution,
including basic builder scripts, tests, documentation, and module
code. This is done through just one method, C<main>.


=head1 METHODS

=head2 App::Module::Setup->main( $options )

C<main> is the only method you should need to use from outside this
module; all the other methods are called internally by this one.

This method creates the distribution and populates it with the all the
requires files.

It takes a reference to a hash of params, as follows:

    module       # module to create in distro
    version      # initial version
    author       # author's full name (taken from C<getpwuid> if not provided)
    email        # author's email address
    verbose      # bool: print progress messages; defaults to 0
    template     # template set to use
    postcmd	 # array ref of commands to execute after creating
    install-templates # bool: just install the selected templates

=cut


=head1 AUTHOR

Johan Vromans, C<< <jv at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-app-module-setup at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Module-Setup>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Module::Setup

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Module-Setup>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Module-Setup>

=back


=head1 ACKNOWLEDGEMENTS

David Golden, for giving me the final incentive to write this module.

Sawyer X, for writing Module::Starter where I borrowed many ideas from.


=head1 COPYRIGHT & LICENSE

Copyright 2013 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of App::Module::Setup
