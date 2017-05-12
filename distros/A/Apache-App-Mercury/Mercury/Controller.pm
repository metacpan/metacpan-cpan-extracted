package Apache::App::Mercury::Controller;

require 5.004;
use strict;

#use Apache;
use Apache::Constants qw(:response);
use CGI;

use Apache::App::Mercury::Base;
use base qw(Apache::App::Mercury::Base);
use Apache::App::Mercury;

=head1 NAME

Apache::App::Mercury::Controller - Example Controller class

=head1 DESCRIPTION

This is simply a skeleton class which illustrates how a controller
should interact with Apache::App::Mercury.  Please look at the code
to see how it should contruct and initialize an Apache::App::Mercury
object, run its main content handler, and then cleanup non-persistent
instance variables on completion.  It does not illustrate object
persistence; not for difficulty reasons, simply for lack of time.
I highly recommend Apache::Session.

The below instance variables and accessors are required in your
controller class for Apache::App::Mercury to operate properly.

=head1 INSTANCE VARIABLES

=over 4

=item * $controller->{q}

A CGI query object for the current http request.

=item * $controller->{r}

An Apache->request object for the current http request.

=back

=cut

sub initialize {
    my ($self, $r) = @_;
    $self->{r} = $r;
    $self->{q} = CGI->new;
    $self->{mercury} = Apache::App::Mercury->new;
    $self->{mercury}->initialize($self);

    $self->{time} = time;
}

sub cleanup {
    my ($self) = @_;
    foreach (qw(r q)) {
	delete $self->{$_};
    }
    $self->{mercury}->cleanup;
}

# mod_perl handler
sub handler {
    my ($self, $r) = @_;
    # if called directly from mod_perl PerlHandler, swap $self and $r
    unless (ref $self eq __PACKAGE__ and ref $r eq "Apache") {
	$r = $self;
	$self = __PACKAGE__->new;
    }
    $self->initialize($r);
    eval { $self->{mercury}->content_handler; };
    if ($@) {
	$self->log_error;
	$self->write_response();
    } else {
	$self->write_response();
    }
    $self->cleanup;
}


=head1 ACCESSORS

=over 4

=item * infomsg([$msg])

Set or get a page-specific informational message.  The controller should
display this message in some prominent location on the resulting HTML page.

=item * pagetitle([$title])

Set or get the HTML page title.

=item * pagebody([$body])

Set or get the page body content.

=item * get_time()

Return the current unixtime, as returned by the Perl time() function.
This accessor is used for time synchronization throughout the application,
so your controller can keep a single time for each http request.

=item * sitemark([$mark])

Set or get a page-specific location mark, for logging purposes.

=back

=cut
sub get_time { return $_[0]->{time}; }
sub sitemark { $_[0]->{sitemark} = $_[1] if $_[1]; $_[0]->{sitemark}; }

sub infomsg { $_[0]->{msg} = $_[1] if $_[1]; $_[0]->{msg}; }
sub pagetitle { $_[0]->{title} = $_[1] if $_[1]; $_[0]->{title}; }
sub pagebody { $_[0]->{body} = $_[1] if $_[1]; $_[0]->{body}; }


sub write_response {
    my ($self) = @_;
    my $r = $self->{r};
    my $q = $self->{q};

    $r->content_type("text/html");

    if ($r->status != REDIRECT) {
	$self->{out} = '<html><head>';
	if ($self->{error_title}) {
	    $self->{out} .= $q->title($self->{error_title});
	} elsif ($self->{error}) {
	    $self->{out} .= $q->title("Apache::App::Mercury - Error");
	} else {
	    $self->{out} .= $q->title($self->{title});
	}
	$self->{out} .= '</head><body>';

	if ($self->{error}) {
	    $self->{out} .= $self->{error};
	} else {
	    $self->{out} .= $self->process_msg if defined $self->{msg};
	    $self->{out} .= $self->{body};
	}
	$self->{out} .= '</body></html>';

	$r->header_out("Location" => $r->uri);
	$r->header_out("Content-Length" => length($self->{out}));

	$r->status(DOCUMENT_FOLLOWS);

	if ($self->{cgi_headers}) {
	    $r->send_cgi_header($self->{cgi_headers} . "\n");
	} else {
	    $r->send_http_header;
	}
	$r->print($self->{out});
    } else {
	$r->send_http_header;
    }

    $self->{out} = '';
    $self->{body} = '';
    undef $self->{msg};

    return $r->status;
}

sub process_msg {
    my ($self) = @_;
    my $q = $self->{q};

    return
      ($q->div({-align => 'center'},
	       $q->font({-color => '#ff0000'}, $q->b($self->{msg}))) .
       $q->br . $q->hr({-size => 1, -width => '80%', -align => 'center'}) .
       $q->br
      );
}


1;

__END__

=head1 AUTHOR

Adi Fairbank <adi@adiraj.org>

=head1 COPYRIGHT

Copyright (c) 2003 - Adi Fairbank

This software (Apache::App::Mercury and all related Perl modules under
the Apache::App::Mercury namespace) is copyright Adi Fairbank.

=head1 LAST MODIFIED

July 19, 2003

=cut
