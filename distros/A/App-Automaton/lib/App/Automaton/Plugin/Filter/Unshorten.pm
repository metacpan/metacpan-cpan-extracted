package App::Automaton::Plugin::Filter::Unshorten;

# ABSTRACT: Expansion of shortneded URLs

use strict;
use warnings;
use Moo;
use LWP::UserAgent;

use Data::Dumper;

sub go {
    my $self = shift;
	my $in = shift;
	my $bits = shift;
	my $d = $in->{debug};
	
	my @patterns = (
		"http[s]?:\/\/t.co\/.{10}", #twitter
		"http[s]?:\/\/goo.gl\/[a-z,A-Z,0-9]*", # google
		"http[s]?:\/\/bit.ly\/[a-z,A-Z,0-9]*", #http://bit.ly/1vsPSjP
		"http[s]?:\/\/bit.do\/[a-z,A-Z,0-9]*", #http://bit.do/UVBz
		"http[s]?:\/\/ow.ly\/[a-z,A-Z,0-9]*", # http://ow.ly/FiTXV
		"http[s]?:\/\/tr.im\/[a-z,A-Z,0-9]*", # https://tr.im/23498
		"http[s]?:\/\/youtu.be\/.{11}",
		"http[s]?:\/\/t.ted.com\/.{7}",
	);
	
	my $pattern_string = join('|', @patterns);
	
	foreach my $bit (@$bits) {
		$bit =~ s/($pattern_string)/_unshorten($d, $1)/eg;
	}

	return 1;
}

sub _unshorten {
	my $d = shift;
	my $input = shift;
	my $ua = LWP::UserAgent->new;
	my $r = $ua->head($input);
	my $new_url = $r->base;
	_logger($d, "Expanding $input to $new_url");
	return $new_url;
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

App::Automaton::Plugin::Filter::Unshorten - Expansion of shortneded URLs

=head1 VERSION

version 0.150912

=head1 SYNOPSIS

This module is intended to be used from within the App::Automaton application.

It expands shortened URLs to their full size so that other modules may identify them.
It currently supports the following shortening services:
 * Twitter t.co
 * Google goo.gl
 * Bitly bit.ly
 * BitDo bit.do
 * Owly ow.ly
 * Trim tr.im
 * YouTube youtu.be
 * Ted.com t.ted.com

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
