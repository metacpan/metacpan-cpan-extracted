package App::PodPreview;
BEGIN {
  $App::PodPreview::VERSION = '0.002';
}

# ABSTRACT: Preview POD files in a browser

use strict;
use warnings;	
use autodie;

use Perl6::Export::Attrs;
use Pod::Simple::HTML;
use Config::Tiny;
use Browser::Open qw(open_browser_cmd);
use File::HomeDir;
use File::Temp;
use File::Spec;
use Carp qw(carp);

sub podpreview :Export
{
	my $input_pod = shift;

	my $parser = Pod::Simple::HTML->new;
	my $config_path = File::Spec->catfile(File::HomeDir->my_home, '.podpreview');

	if ( -e $config_path and -f $config_path )
	{
		my $config = Config::Tiny->read($config_path) 
			or carp "Error loading config: " . Config::Tiny::errstr;

		my @options = qw(
			perldoc_url_prefix
			perldoc_url_postfix
			man_url_prefix
			man_url_postfix
			title_prefix
			title_postfix
			html_h_level
			html_header_before_title
			html_header_after_title
			html_footer
			index
			html_css
			html_javascript
			force_title 
			default_title
		);

		foreach my $option (@options)
		{
			if ( exists $config->{_}->{$option} )
			{
				$parser->$option( $config->{_}->{$option} );
			}
		}
	}

	my $fh = File::Temp->new( SUFFIX => '.html');
	$parser->output_fh($fh);
	$parser->parse_file($input_pod);
	close $fh;

	if ( $^O eq "MSWin32" )
	{
		# Browser::Open currently has issues on Win32
		exec ( "start " . $fh->filename );
	}
	else
	{
		exec ( open_browser_cmd . " " . $fh->filename );
	}
}

1;

=head1 NAME

App::PodPreview - Preview POD files in a browser

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use App::PodPreview qw(podpreview);
  podpreview('/path/to/file.pod');

=head1 DESCRIPTION

This module is used internally by the C<podpreview> utility.

=head1 AUTHOR

Peter Shangov <pshangov at yahoo dot com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.