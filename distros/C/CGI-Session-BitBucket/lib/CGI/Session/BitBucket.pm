package CGI::Session::BitBucket;

use Carp;
use CGI::Session;
use CGI::Session::ID::MD5;
use base qw(
    CGI::Session
    CGI::Session::ID::MD5
    CGI::Session::Serialize::Default
);
use strict;
use warnings;
use vars qw($VERSION);
($VERSION) = '1.2';

########################
# Driver methods follow
########################


# the null session does not store data
sub store {
    my ($self, $sid, $options, $data) = @_;   

	my $args = $options->[1] || {};  # or $self->driver_options (new CGI::Session method)

	if( $args->{Log} ) {
		carp "CGI::Session::BitBucket->store($sid) ".$self->freeze($data);
	}
    
    return 1;
}



# the null session does not retrieve data
sub retrieve {
    my ($self, $sid, $options) = @_;
    
	my $args = $options->[1] || {};  # or $self->driver_options (new CGI::Session method)

	if( $args->{Log} ) {
		carp "CGI::Session::BitBucket->retrieve($sid)";
	}
    
    return $self->thaw("");
}


# removes the given data and all the disk space associated with it
sub remove {
    my ($self, $sid, $options) = @_;

	my $args = $options->[1] || {};  # or $self->driver_options (new CGI::Session method)

	if( $args->{Log} ) {
		carp "CGI::Session::BitBucket->remove($sid)";
	}
    
    
    return 1;    
}


# called right before the object is destroyed to do cleanup
sub teardown {
    my ($self, $sid, $options) = @_;

	my $args = $options->[1] || {};  # or $self->driver_options (new CGI::Session method)

	if( $args->{Log} ) {
		carp "CGI::Session::BitBucket->teardown($sid)";
	}
    

    return 1;
}




1;       
=pod

=head1 NAME

CGI::Session::BitBucket - a module that loses your session data

=head1 SYNOPSIS
    
    use CGI::Session;
    my $session = new CGI::Session("driver:BitBucket", $sid, {Log=>1});
    
For more options and examples, read the rest of this document and
consult L<CGI::Session>.

=head1 DESCRIPTION

CGI::Session::BitBucket is a CGI::Session driver to let you add session
support to your program and not have to worry about where it will be 
stored until you're ready for that part. 

You can use the Log=>1 argument to see warnings in your log when the
session would have stored, retrieved, and trashed data.

To write your own drivers for B<CGI::Session>, refer to L<CGI::Session>.

=head1 STORAGE

This driver does not store any data.  This means whenever you load a session using
BitBucket, your session will always be blank.

=head1 OPTIONS

=head2 Log => 1

Turn this on to see messages in your log about the data you would have saved
if you were using something other than the bit bucket for storage.


=head1 COPYRIGHT

CGI::Session::BitBucket is Copyright (C) 2004 Jonathan Buhacoff.  All rights reserved.

=head1 LICENSE

This library is free software and can be modified and distributed under the same
terms as Perl itself. 

=head1 AUTHOR

Jonathan Buhacoff <jonathan@buhacoff.net> wrote CGI::Session::BitBucket

=head1 SEE ALSO

=over 4

=item *

L<CGI::Session|CGI::Session> - CGI::Session manual

=item *

L<CGI::Session::Tutorial|CGI::Session::Tutorial> - extended CGI::Session manual

=item *

L<CGI::Session::CookBook|CGI::Session::CookBook> - practical solutions for real life problems

=item *

B<RFC 2965> - "HTTP State Management Mechanism" found at ftp://ftp.isi.edu/in-notes/rfc2965.txt

=item *

L<CGI|CGI> - standard CGI library

=item *

L<Apache::Session|Apache::Session> - an alternative to CGI::Session

=back

=cut
