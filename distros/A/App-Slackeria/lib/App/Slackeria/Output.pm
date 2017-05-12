package App::Slackeria::Output;
use strict;
use warnings;
use autodie;
use 5.010;

use File::ShareDir qw(dist_file);
use HTML::Template;

our $VERSION = '0.12';

sub format_check {
	my ( $self, $res ) = @_;
	my ( $class, $href, $data );

	if ( not $res->{skip} and $res->{ok} and $res->{data} eq q{} ) {
		$data = 'ok';
	}

	if ( $res->{ok} and $res->{href} ) {
		$href = $res->{href};
	}

	if ( not $res->{skip} ) {
		$data //= $res->{data};
		if ( $res->{ok} ) {
			$class = 'ok';
		}
		else {
			$class = 'fail';
		}
	}

	return {
		class => $class // q{},
		data  => $data,
		href  => $href,
	};
}

sub write_out {
	my ( $self, %opt ) = @_;
	my @project_lines;
	my @headers;

	my $filename = $opt{filename};
	my $project  = $opt{data};
	my $template = $opt{template}
	  // dist_file( 'App-Slackeria', 'template.xhtml' );

	my $tmpl = HTML::Template->new( filename => $template );

	$tmpl->param(
		title   => 'Software version matrix',
		version => $VERSION,
	);

	for my $p ( sort keys %{$project} ) {

		my @plugins = sort keys %{ $project->{$p} };

		my @project_plugins
		  = map { $self->format_check( $project->{$p}->{$_} ) } @plugins;

		if ( @headers == 0 ) {
			push( @headers, map { { plugin => $_ } } @plugins );
		}

		push(
			@project_lines,
			{
				project => $p,
				plugins => [@project_plugins]
			}
		);

	}

	$tmpl->param(
		headers  => [@headers],
		projects => [@project_lines],
	);

	open( my $fh, '>', $filename );
	print $fh $tmpl->output();
	close($fh);

	return;
}

1;

__END__

=head1 NAME

App::Slackeria::Output - XHTML output for App::Slackeria

=head1 SYNOPSIS

    # $project looks like this:
    # {
    #     perl => {
    #         Debian    => { ok => 1, data => '5.12.3-7' },
    #         Freshmeat => { ok => 1, data => '5.14.0' },
    #     },
    #     irssi => {
    #         Debian    => { ok => 1, data => '0.8.15-3+b1' },
    #         Freshmeat => { ok => 1, data => '0.8.12' },
    #     },
    # }
    App::Slackeria::Output->write_out(
        filename => '/tmp/out.html',
        data => $project
    );

=head1 VERSION

version 0.12

=head1 DESCRIPTION

App::Slackeria::Out::XHTML takes a hashref of projects, which themselves are
hashrefs of plugin name => plugin output pairs, and stuffs it into a nicely
formatted (X)HTML table.

=head1 FUNCTIONS

=over

=item App::Slackeria::Output->write_out(B<filename> => I<filename>, B<data> =>
I<data>, [B<template> => I<template file>])

Creates HTML in I<filename> based on I<data>.

=back

=head1 TEMPLATE VARIABLES

In the outer layer, there are just two loop variables available, B<headers> and
B<projects>. Use C<< <TMPL_LOOP headers> ... stuff ... </TMPL_LOOP> >> to access
their content.

=head2 HEADERS

The B<headers> loop contains the table fields, i.e. the names of the
executed plugins in the correct order, in the variable B<plugin>. It can be
used like C<< <TMPL_VAR plugin> >>.

=head2 PROJECTS

B<projects> loops over each project, which in turn loops over each plugin
result. It provides the variable B<project> with the current project's name
and the loop variable B<plugins>.

B<plugins> provides the following variables:

=over

=item * B<class>

CSS class for plugin result. Either "ok" or "fail".

=item * B<href>

URL to project page for this plugin, if available.

=item * B<data>

plugin's text output

=back

=head1 DEPENDENCIES

HTML::Template(3pm)

=head1 SEE ALSO

slackeria(1)

=head1 AUTHOR

Copyright (C) 2011 by Daniel Friesel <derf@finalrewind.org>

=head1 LICENSE

  0. You just DO WHAT THE FUCK YOU WANT TO.
