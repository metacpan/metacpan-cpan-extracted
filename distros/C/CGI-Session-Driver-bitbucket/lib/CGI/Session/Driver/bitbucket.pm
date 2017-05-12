package CGI::Session::Driver::bitbucket;

use Carp;
use CGI::Session::Driver;
use strict;
use warnings;
@CGI::Session::Driver::bitbucket::ISA        = qw( CGI::Session::Driver );
$CGI::Session::Driver::bitbucket::VERSION    = "1.06";

=pod

=head1 NAME

CGI::Session::Driver::bitbucket - a module that loses your session data

=head1 SYNOPSIS
    
    use CGI::Session;
    my $session = new CGI::Session("driver:bitbucket", $sid, {Log=>1});
    
For more options and examples, read the rest of this document and
consult L<CGI::Session>.

=head1 DESCRIPTION

bitbucket is a CGI::Session driver to let you add session
support to your program and not have to worry about where it will be 
stored until you're ready for that part. 

You can use the Log=>1 argument to see warnings in your log when the
session would have stored, retrieved, and trashed data.

To write your own drivers for B<CGI::Session>, refer to L<CGI::Session>.

=head1 STORAGE

This driver does not store any data.  This means whenever you load a session using
bitbucket, your session will always be blank.

=head1 OPTIONS

=head2 Log => 1

Turn this on to see messages in your log about the data you would have saved
if you were using something other than the bit bucket for storage.

=head1 METHODS

=cut

########################
# Driver methods follow
########################

=head2 store

The null session does not store data. This method always returns 1.

=cut

sub store {
    my ($self, $sid, $data) = @_;   
    if( $self->{Log} ) {
        carp "bitbucket->store($sid,$data)";
    }
    return 1;
}

=head2 retrieve

The null session does not retrieve data. This method always returns 0.

=cut

sub retrieve {
    my ($self, $sid) = @_;
    if( $self->{Log} ) {
        carp "bitbucket->retrieve($sid)";
    }
    return 0;
}

=head2 remove

Since the null session does not store data, this method does nothing and
always returns 1.

=cut

sub remove {
    my ($self, $sid) = @_;
    if( $self->{Log} ) {
	carp "bitbucket->remove($sid)";
    }
    return 1;    
}

=head2 traverse

Does nothing and always returns 1.

=cut

sub traverse {
    my ($self, $coderef) = @_;
	if( $self->{Log} ) {
		carp "bitbucket->traverse(@_)";
	}
	return 1;
}


# called before object is terminated
sub DESTROY {
    my $self = shift;
	if( $self->{Log} ) {
		carp "bitbucket->delete()";
	}
}


1;       

=head1 COPYRIGHT

CGI::Session::Driver::bitbucket is Copyright (C) 2005-2008 Jonathan Buhacoff.  All rights reserved.

=head1 LICENSE

This library is free software and can be modified and distributed under the same
terms as Perl itself. 


=head1 AUTHOR

Jonathan Buhacoff <jonathan@pnc.net> wrote CGI::Session::Driver::bitbucket

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
