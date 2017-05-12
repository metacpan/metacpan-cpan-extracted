package Catalyst::Plugin::Setenv;

use warnings;
use strict;
use MRO::Compat;

=head1 NAME

Catalyst::Plugin::Setenv - Allows you to set up the environment from Catalyst's config file.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

In your application:

    use Catalyst qw/Setenv/;

In your config file:

    environment:
      FOO: bar
      BAR: baz

When your app starts, C<$ENV{FOO}> will be "bar", and C<$ENV{BAR}> will be
"baz".

You can also append and prepend to existing environment variables.
For example, if C<$PATH> is C</bin:/usr/bin>, you can append
C</myapp/bin> by writing:

   environment:
     PATH: "::/myapp/bin"

After that, C<$PATH> will be set to C</bin:/usr/bin:/myapp/bin>.  You
can prepend, too:

   environment:
     PATH: "/myapp/bin::"

which yields C</myapp/bin:/bin:/usr/bin>.

If you want a literal colon at the beginning or end of the environment
variable, escape it with a C<\>, like C<\:foo> or C<foo\:>.  Note that
slashes aren't meaningful elsewhere, they're inserted verbatim into
the relevant environment variable.

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 setup

Calls the other setup methods, and then sets the environment variables.

=cut

sub setup {
    my $c = shift;
    
    $c->next::method(@_);
    
    my $env = $c->config->{environment};
    return unless ref $env eq 'HASH';

    foreach my $key (keys %$env){
	my $value = $env->{$key};
	
	if($value =~ /^:(.+)$/){
	    $ENV{$key} .= $1;
	}
	elsif($value =~ /^(.+[^\\]):$/){
	    $ENV{$key} = $1. $ENV{$key};
	}
	else {
	    $value =~ s/(^\\:|\\:$)/:/;
	    $value =~ s/(^\\\\:|\\\\:$)/\\:/;

	    $ENV{$key} = $value;
	}
    }
    
    return;
}

=head1 AUTHOR

Jonathan Rockway, C<< <jrockway at cpan.org> >>

=head1 BUGS

=head2 Escaping

Things like "\:foo" can't be literally inserted into an environment
variable, due to my simplistic escaping scheme.  Patches to fix this
(but not interpert C<\>s anywhere else) are welcome.

=head2 REPORTING

Please report any bugs or feature requests to
C<bug-catalyst-plugin-setenv at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-Setenv>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::Setenv

You can also look for information at:

=over 4

=item * The Catalyst Website

L<http://www.catalystframework.org/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-Setenv>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-Setenv>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-Setenv>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-Setenv>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Bill Moseley's message to the mailing list that prompted me
to write this.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jonathan Rockway, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::Plugin::Setenv
