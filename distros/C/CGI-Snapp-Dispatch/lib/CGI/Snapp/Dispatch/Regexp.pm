package CGI::Snapp::Dispatch::Regexp;

use parent 'CGI::Snapp::Dispatch';
use strict;
use warnings;

use Carp;

our $VERSION = '2.00';

# --------------------------------------------------

sub dispatch_args
{
	my($self, $args) = @_;

	return
	{
		args_to_new => {},
		default     => '',
		prefix      => '',
		table       =>
		[
			qr|/([^/]+)/?|         => {names => ['app']},
			qr|/([^/]+)/([^/]+)/?| => {names => [qw/app rm/]},
		],
	};

} # End of dispatch_args.

# --------------------------------------------------

sub _parse_path
{
	my($self, $http_method, $path_info, $table) = @_;

	$self -> log(debug => "_parse_path($path_info, ...)");

	# Compare each rule in the table with the path_info, and process the 1st match.

	my($rule);

	for (my $i = 0; $i < scalar @$table; $i += 2)
	{
		$rule = $$table[$i];

		next if (! defined $rule);

		$self -> log(debug => "Trying to match path info '$path_info' against rule '$rule'");

		# If we find a match, then run with it.

		if (my @values = ($path_info =~ m#^$rule$#) )
		{
			$self -> log(debug => 'Matched!');

			my(%named_args)      = %{$$table[++$i]};
			my($names)           = delete $named_args{names};
			@named_args{@$names} = @values if (ref $names eq 'ARRAY');

			return {%named_args};
		}
	}

	# No rule matched the given path info.

	$self -> log(debug => 'Nothing matched');

	return {};

}	# End of _parse_path.

# --------------------------------------------------

1;

=pod

=head1 NAME

CGI::Snapp::Dispatch::Regexp - Dispatch requests to CGI::Snapp-based objects

=head1 Synopsis

I<Note the call to new()!>

	use CGI::Snapp::Dispatch::Regexp;

	CGI::Snapp::Dispatch::Regexp -> new -> dispatch
	(
		prefix  => 'MyApp',
		table   =>
		[
			qr|/([^/]+)/?|                        => { names => ['app']                },
			qr|/([^/]+)/([^/]+)/?|                => { names => [qw(app rm)]           },
			qr|/([^/]+)/([^/]+)/page(\d+)\.html?| => { names => [qw(app rm page)]      },
		],
	);

This would also work in a PSGI context. I<Note the call to new()!>

	CGI::Snapp::Dispatch::Regexp -> new -> as_psgi
	(
	...
	);

See t/psgi.regexp.t and t/regexp.t.

This usage of new(), so unlike L<CGI::Application::Dispatch>, is dicussed in L<CGI::Snapp::Dispatch/PSGI Scripts>.

=head1 Description

CGI::Snapp::Dispatch::Regexp is a sub-class of L<CGI::Snapp::Dispatch> which overrides 2 methods:

=over 4

=item o dispatch_args()

=item o _parse_path()

=back

The point is to allow you to use regexps as rules to match the path info, whereas L<CGI::Snapp::Dispatch> always
assumes your rules are strings.

See L<CGI::Snapp::Dispatch/Description> for more detail.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<CGI::Snapp::Dispatch> as you would for any C<Perl> module:

Run:

	cpanm CGI::Snapp::Dispatch

or run:

	sudo cpan CGI::Snapp::Dispatch

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($app) = CGI::Snapp::Dispatch::Regexp -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<CGI::Snapp::Dispatch::Regexp>.

This module accepts exactly the same parameters as does L<CGI::Snapp::Dispatch>.

See L<CGI::Snapp::Dispatch/Constructor and Initialization> for details.

=head1 Methods

=head2 dispatch_args($args)

Returns a hashref of args to be used by L<CGI::Snapp::Dispatch/dispatch(@args)> or
L<CGI::Snapp::Dispatch/as_psgi(@args)>.

Default output:

	{
		args_to_new => {},
		default     => '',
		prefix      => '',
		table       =>
		[
			qr|/([^/]+)/?|         => {names => ['app']},
			qr|/([^/]+)/([^/]+)/?| => {names => [qw/app rm/]},
		],
	};

The differences between this structure and what's used by L<CGI::Snapp::Dispatch> are discussed in the L</FAQ>.

=head1 FAQ

=head2 Is there any sample code?

Yes. See t/psgi.regexp.t and t/regexp.t.

This module works with both L<CGI::Snapp::Dispatch/dispatch(@args)> and L<CGI::Snapp::Dispatch/as_psgi(@args)>.

=head2 What is the structure of the dispatch table?

Basically it's the same as in L<CGI::Snapp::Dispatch/What is the structure of the dispatch table?>.

The important difference is in the I<table> key, which can be seen just above, under L</dispatch_args($args)>.

The pairs of elements in the I<table>, compared to what's handled by L<CGI::Snapp::Dispatch> are:

=over 4

=item o A regexp instead of a string

=item o A hashref with a key of I<names> and an array ref of field names

=back

See the L</Synopsis> for a more complex example.

=head1 Troubleshooting

See L<CGI::Snapp::Dispatch/Troubleshooting>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Credits

See L<CGI::Application::Dispatch::Regexp/COPYRIGHT & LICENSE>. This module is a fork of that code.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=CGI::Snapp::Dispatch>.

=head1 Author

L<CGI::Snapp::Dispatch> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
