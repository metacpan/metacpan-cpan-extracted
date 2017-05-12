package AnyEvent::WebArchive;

use strict;
use AnyEvent::HTTP;
use Data::Dumper;
use base 'Exporter';
our $VERSION = '0.02';

our @EXPORT = qw(restore_url);
my $DEBUG = 0;
sub restore_url {
	my $url = shift;
	my $cb  = pop;
	
	$url =~ s/^www\.//;
	my $opt = ref $_[0] ? $_[0] : {@_};
	
	$AnyEvent::HTTP::USERAGENT      = $opt->{'user_agent'} || 'Opera/9.80 (Windows NT 5.1; U; ru) Presto/2.5.24 Version/10.52';
	$AnyEvent::HTTP::MAX_PER_HOST ||= $opt->{'max_per_host'};
	$AnyEvent::HTTP::ACTIVE       ||= $opt->{'active'      };
	
	my $count;
	my $worker = {};
	bless $worker, __PACKAGE__;
	$worker->{'domain'} = $url;
	http_get _search($url), sub {
		$url = $url;
		$DEBUG && warn "GET $url\n";
		my ($body, $headers) = @_;
		
		for my $job (grep { $_->[0] } # XXX
			map { [ /href="([^"]+)"/sg, />([^<]+)<\/a>/sg ] } map { split /(<br>){2}/ } 
			$body =~ m{<!-- SEARCH RESULTS -->(.*?)<!-- /SEARCH RESULTS -->}si
		) {
			$DEBUG && warn "GET $job->[0]\n";
			$count++;
			http_get $job->[0], sub {
				my ($body, $headers) = @_;
				if ($headers->{'Status'} == 200) {
					$worker->_save_file($job->[1], $body);
				} else {
					warn "Bad status for url $job->[0]: $_" for Dumper($headers);
				}
				
				$cb->() unless --$count;
			} 
		}
	}
}

sub _filename {
	my $str = shift;
	
	$str =~ s/[^a-z\.\,\s\;-]/_/sig;
	
	return $str;
}

sub _search {
	return "http://web.archive.org/web/*sr_1nr_10000/$_*" for shift;
}

sub _save_file {
	my ($worker, $url,$body) = @_;
	
	$url = $worker->{'domain'} . $worker->_normalize_url($url);
	
	my $path;
	for (split /\//, $url) {
		last if /^\?/ || $url =~ /$_$/;
		$path .= "$_/";
		$DEBUG && warn "mkdir $path\n"; 
		mkdir $path;
	}
	
	return warn "file $url already exists, skipping\n" if -e $url;
	$DEBUG && warn "writing $url\n";
	
	
	open my $fh, '>', $url or warn "$!: $url";
	print $fh $worker->_normalize($body);
}

sub _normalize {
	my ($worker,$body) = @_;
	
	$body =~ s/(?<=href=")([^"]+)(?=")/$worker->_normalize_url($1)/sieg;
	$body =~ s{(?<=</body>).*(?=</html>)}{}si;
	return $body;
}

sub _normalize_url {
	my ($worker,$url) = @_;
	$url =~ s/\?$//;
	
	$url  =~ s/^.*?$worker->{domain}//i unless $url =~ /^\//;
	$url .= 'index.html' if     $url =~ /\/$/;       # dirs
	$url .= '.html'      unless $url =~ /\..{1,7}$/; # w/o extension
	
	$url =~ s/[^a-z0-9_\/\.\-\+=%&]/_/ig;            # strip bad characters in filename
	
	return $url;
}

1;

=head1 NAME

AnyEvent::WebArchive - simple non-blocking WebArchive client

=head1 VERSION

0.02

=head1 SYNOPSIS

   use AnyEvent::WebArchive;
   
   my $c = AnyEvent->condvar;
   restore_url('cpan.org', sub { $c->send });
   $c->recv;

=head1 METHODS

=over 4

=item restore_url $url, option => value, ..., $callback

Restore all data from WebArchive cache for C<$url>

=back

=head1 OPTIONS

=over 4

=item user_agent - UserAgent string

=item active - number of active connections for L<AnyEvent::HTTP>

=item max_per_host - maximum connections per one host for L<AnyEvent::HTTP>

=back

=head1 SUPPORT

=over 4

=item * Repository

L<http://github.com/konstantinov/AnyEvent-WebArchive>

=back

=head1 SEE ALSO

L<AnyEvent>, L<AnyEvent::HTTP>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dmitry Konstantinov. All right reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.