package Cache::Memcached::Fast::CGI;

use warnings;
use strict;

=head1 NAME

Cache::Memcached::Fast::CGI - Capture the STDOUT for Memcached in a pure cgi program!

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

use Cache::Memcached::Fast;
use IO::Capture::Stdout;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(setup get add start end auto_end);
our @EXPORT_ok = qw();

sub new {
	my $class = shift;
	$class = ref $class || $class;
	my $self ={};
	bless $self,$class;

	$self->{'cmf'}  = Cache::Memcached::Fast->new(@_);
	$self->{'ics'}  = new IO::Capture::Stdout;

	return $self;
}

sub setup {
	my $self = shift;
	my %set  = @_;
	while(my($k,$v) = each %set){
		$self -> {$k} = $v;
	}
}

sub get {
	my $self = shift;
	my $key  = shift;
	my $value = $self->{'cmf'}->get($key);
	return $value;
}

sub add {
	my $self = shift;
	$self->{'cmf'}->add(@_);
	return 1;
}

sub start {
	my $self = shift;
	$self->{'ics'} -> start();
}

sub end {
	my $self = shift;
	$self->{'ics'} -> stop();
	my $re = join '',$self->{'ics'}->read();
	return $re;
}

sub auto_end {
	my $self = shift;
	my $key  = shift;
	my $time  = shift;
	$self->{'ics'} -> stop();
	my $re = join '',$self->{'ics'}->read();
	$self->{'cmf'}->add($key,$re,$time);
	print $re;
}


=head1 SYNOPSIS

	use Cache::Memcached::Fast::CGI;

	my $cmfc = Cache::Memcached::Fast::CGI->new({
		servers         => ['localhost:11211'],
		connect_timeout => 0.3
		## ...
	});

	my $key = $ENV{'SCRIPT_FILENAME'}.'?'.$ENV{'QUERY_STRING'};

	## Retrieve values
	my $value = $cmfc->get($key);
	print $value and exit if $value;

	## Start capture
	$cmfc->start();

	print "Content-type: text/html;charset=utf-8\n\n";
	print "<html><body>";
	print "hello world -- 1<br>";
	## ...
	print "hello world -- 2<br>";
	print "</body></html>";

	## Automatic end of the capture
	$cmfc->auto_end($key);

	exit;


=head1 SUBROUTINES/METHODS

=head2 add
	
	# Add the key and valuse into memcahced
	$cmfc->add($key,$value,$time);

=head2 end

	## End capture
	my $captured = $cmfc->end();
	
=head3 auto_end

	## Automatic end of the capture
	$cmfc->auto_end($key,$time);

=head1 AUTHOR

=HITSU, C<< <hitsubunnu at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cache-memcached-fast-cgi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Cache-Memcached-Fast-CGI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Cache::Memcached::Fast::CGI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Cache-Memcached-Fast-CGI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Cache-Memcached-Fast-CGI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Cache-Memcached-Fast-CGI>

=item * Search CPAN

L<http://search.cpan.org/dist/Cache-Memcached-Fast-CGI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 =Hitsu Bunnu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
