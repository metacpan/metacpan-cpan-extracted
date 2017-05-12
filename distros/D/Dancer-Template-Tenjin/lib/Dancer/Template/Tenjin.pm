package Dancer::Template::Tenjin;

# ABSTRACT: Tenjin wrapper for Dancer

use strict;
use warnings;

our $VERSION = "0.5";
$VERSION = eval $VERSION;

use Tenjin 0.070001;
use Dancer::Config 'setting';
use File::Basename;
use Try::Tiny;
use Carp;

use base 'Dancer::Template::Abstract';

=head1 NAME

Dancer::Template::Tenjin - Tenjin wrapper for Dancer

=head1 VERSION

version 0.5

=head1 SYNOPSIS

	# in your config.yml
	template: "tenjin"

	# note: templates must use the '.tt' extension

	# you might also want to add (if your templates are UTF-8, which is the
	# default encoding used by Tenjin):
	charset: "UTF-8"

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<Tenjin> module.

Tenjin is a fast and feature-full templating engine that can be used by
Dancer for production purposes. In comparison to L<Template::Toolkit|Template>,
it is much more lightweight, has almost no dependencies, and supports
embedded Perl code instead of defining its own language.

In order to use this engine, you need to set your webapp's template engine
in your app's configuration file (config.yml) like so:

	template: "tenjin"

You can also directly set it in your app code with the B<set> keyword.

Now you can create Tenjin templates normally, but note that due to a
Dancer restriction your template files must end in the '.tt' extension as
Dancer automatically adds this extension to the template names you declare
in your apps.

=head1 METHODS

=head2 init()

Initializes a template engine by generating a new instance of L<Tenjin>.

=cut

sub init {
	$_[0]->{engine} = Tenjin->new({ postfix => '.tt', path => [setting('views')] });
}

=head2 render( $template, $tokens )

Receives a template name and a hash-ref of key-value pairs to pass to
the template, and returns the template rendered by Tenjin.

=cut

sub render($$$) {
	my ($self, $template, $tokens) = @_;

	croak "'$template' is not a regular file"
		if !ref $template && !-f $template;

	$tokens ||= {};

	# Dancer seems to be sending the full filename (i.e. including full path)
	# of the template, while we only need the relative path, so let's
	# strip the base path from the template filename
	foreach (@{$self->{engine}->{path}}) {
		my $basepath = $_;
		$basepath .= '/' unless $basepath =~ m!/^!;

		next unless $template =~ m/^$basepath/;

		$template =~ s/^$basepath//;
	}

	# ignore 'bad' tokens - this is here because for some reason
	# Dancer is passing the entire user agent as a token, and I can't
	# find the cause of that yet.
	foreach (keys %$tokens) {
		delete $tokens->{$_} if m/[ ()]/;
	}

	my $output = try { $self->{engine}->render($template, $tokens) } catch { croak $_ };
	return $output;
}

=head1 SEE ALSO

L<Dancer>, L<Tenjin>

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50 dot net> >>

=head1 ACKNOWLEDGEMENTS

=over

=item * Alexis Sukrieh, C<< <sukria@cpan.org> >>

Author of L<Dancer>, who wrote L<Dancer::Template::Toolkit>,
on which this module is based.

=item * Sawyer X, C<< <xsawyerx at cpan.org> >>

Submitted helpful changes for version 0.3.

=item * Franck Cuny C<< <franck at lumberjaph dot net> >>

Submitted a simple test for version 0.4.

=back

=head1 TODO

=over 2

=item * Non-file sources

Find a way to allow using templates from other source, such as
a database, just like in L<Catalyst::View::Tenjin>.

=item * Fine-tune Tenjin

Allow passing arguments to Tenjin, such as USE_STRICT.

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-template-tenjin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Template-Tenjin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Template::Tenjin

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Template-Tenjin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Template-Tenjin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Template-Tenjin>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Template-Tenjin/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;