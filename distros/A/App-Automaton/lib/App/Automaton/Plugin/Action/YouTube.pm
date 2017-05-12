package App::Automaton::Plugin::Action::YouTube;

# ABSTRACT: Download module for YouTube videos

use strict;
use warnings;
use Moo;
use File::Spec::Functions;
use WWW::YouTube::Download 0.57;

our $VERSION = '0.57';

use Data::Dumper;

sub go {
	my $self = shift;
	my $in = shift;
	my $bits = shift;
	my $d = $in->{debug};
	
	my $target = $in->{target};
	
	foreach my $bit  (@$bits) {
		my @urls = $bit =~ /http[s]?:\/\/www.youtube\.com\/watch\?v=.{11}/g;
		foreach my $url (@urls) {
			my $client = WWW::YouTube::Download->new();
			my $video_data;
			eval { $video_data = $client->prepare_download($url); }; warn "Error with $url\n".$@ if $@;
			#TODO: Report errors
			next unless $video_data;
			my $target_file = catfile($target, $video_data->{title} . '.' . $video_data->{suffix} );
			next if -e $target_file;
			_logger($d, "downloading $url to $target_file");
			eval{$client->download( $url, { filename => $target_file } );}
		}
	}
	
	return 1;
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

App::Automaton::Plugin::Action::YouTube - Download module for YouTube videos

=head1 VERSION

version 0.150912

=head1 SYNOPSIS

This module is intended to be used from within the App::Automaton application.

It identifies and downloads links from youtube.com.

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
