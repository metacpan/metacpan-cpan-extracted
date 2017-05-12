package Catalyst::Plugin::ConfigurablePathTo;

use warnings;
use strict;

use Path::Class;

=head1 NAME

Catalyst::Plugin::ConfigurablePathTo - Provides a configurable C<path_to()>

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This plugin provides a way to have generic configurable paths in L<Catalyst>.

  # in myapp.yml
  
  path_to:
  
    profiles: /usr/local/profiles
  
    tempfiles: /tmp/myapp_tempfiles
  
    ...

  # in some Catalyst controller
  
    # 'profiles' is defined in the config file, so you'll
    # get '/usr/local/profiles' back
    my $profiles_path = $c->path_to('profiles');

    # it also correctly creates the paths, using Path::Class
    # you'll get '/tmp/myapp_tempfiles/file.tmp' back
    my $temp_path = $c->path_to('tempfiles', 'file.tmp');

    # performs as the original path_to() would if it's not defined
    # in the config file
    my #other_path = $c->path_to('other');

=head1 METHODS

=cut


=head2 $c->path_to( @path )

If C<$path[0]> represents an already configured path in the application
config file, C<$path[0]> is replaced with the configured path and C<@path>
is merged into a L<Path::Class> object.

Otherwise, C<@path> is merged with C<$c-E<gt>config-E<gt>{home}> into a
L<Path::Class> object.

=cut
sub path_to {
	my ($c, @path) = @_;
	
	if (exists $c->config->{path_to}->{$path[0]}) {
		$path[0] = $c->config->{path_to}->{$path[0]};
	}
	else {
		unshift(@path, $c->config->{home});
	}

	# code adapted (i.e. almost shamelessly ripped) from Catalyst.pm v5.65
	my $path = dir(@path);
	if (-d $path) {return $path}
	else {return file(@path)}
}

=head1 AUTHOR

Nilson Santos Figueiredo Júnior, C<< <nilsonsfj at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests directly to the author.
If you ask nicely it will probably get fixed or implemented.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::ConfigurablePathTo

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-ConfigurablePathTo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-ConfigurablePathTo>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-ConfigurablePathTo>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-ConfigurablePathTo>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nilson Santos Figueiredo Junior, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::Plugin::ConfigurablePathTo
