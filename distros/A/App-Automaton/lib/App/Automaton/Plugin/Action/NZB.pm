package App::Automaton::Plugin::Action::NZB;

# ABSTRACT: Download module for nzb files

use strict;
use warnings;
use Moo;
use LWP::UserAgent;
use File::Spec::Functions;

use Data::Dumper;

sub go {
    my $self = shift;
	my $in = shift;
	my $bits = shift;
	my $target = $in->{target} || '.';
	my $d = $in->{debug};
	
	my @patterns = (
		'http:\/\/www.nzbsearch.net\/nzb_get.aspx\?mid=[a-z,A-Z,0-9]*',
		'https:\/\/www.nzb-rss.com\/nzb\/.*nzb'
	);
	my $pattern_string = join('|', @patterns);
	
	foreach my $bit (@$bits) {
		my @urls = $bit =~ /$pattern_string/g;
		foreach my $url (@urls) {
			my $name = _get_name($url);
			my $target_file = catfile($target, $name);
			next if -e $target_file;
			my $ua = LWP::UserAgent->new();
			_logger($d, "downloading $url to $target_file");
			$ua->mirror($url, $target_file);
		}
	}
		
    return(1);
}

sub _get_name {
	my $uri = shift;

	my $name = (split(/\//, $uri))[-1];
	
	# swap out characters that we don't want in the file name
	$name =~ s/[^a-zA-Z0-9\\-]/_/g;
	
	# ensure file name ends in .nzb for ease
	if ( lc(substr($name, -4)) ne '.nzb' ) {
		$name .= '.nzb';
	}
	
	return $name;
}

sub _logger {
	my $level = shift;
	my $message = shift;
	print "$message\n" if $level;
	return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Automaton::Plugin::Action::NZB - Download module for nzb files

=head1 VERSION

version 0.150912

=head1 SYNOPSIS

This module is intended to be used from within the App::Automaton application.

It identifies and downloads links from the following newsgroup search services:
 * www.nzb-rss.com
 * www.nzbsearch.net

=head1 METHODS

=over 4

=item go

Executes the plugin. Expects input: conf as hashref, queue as arrayref

=back

=head1 SEE ALSO

L<App::Automaton>

=head1 AUTHOR

Michael LaGrasta <michael@lagrasta.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Michael LaGrasta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
