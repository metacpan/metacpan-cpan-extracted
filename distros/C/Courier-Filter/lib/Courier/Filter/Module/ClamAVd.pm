#
# Courier::Filter::Module::ClamAVd class
#
# (C) 2004-2008 Julian Mehnle <julian@mehnle.net>
# $Id: ClamAVd.pm 210 2008-03-21 19:30:31Z julian $
#
###############################################################################

=head1 NAME

Courier::Filter::Module::ClamAVd - ClamAV clamd filter module for the
Courier::Filter framework

=cut

package Courier::Filter::Module::ClamAVd;

use warnings;
use strict;

use base 'Courier::Filter::Module';

use MIME::Parser 5.4;
use ClamAV::Client;
use File::Spec;
    # In-memory processing doesn't work, see comments in match_mime_part().

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant default_response   => 'Malware detected:';

=head1 SYNOPSIS

    use Courier::Filter::Module::ClamAVd;
    
    my $module = Courier::Filter::Module::ClamAVd->new(
        # See the socket options description for details.
        socket_name     => '/var/run/clamav/clamd.ctl',
        socket_host     => 'clamav.example.com',
        socket_port     => '3310',
        
        max_message_size
                        => $max_message_size,
        max_part_size   => $max_part_size,
        response        => $response_text,
        
        logger          => $logger,
        inverse         => 0,
        trusting        => 0,
        testing         => 0,
        debugging       => 0
    );
    
    my $filter = Courier::Filter->new(
        ...
        modules         => [ $module ],
        ...
    );

=head1 DESCRIPTION

This class is a filter module class for use with Courier::Filter.  It matches a
message if the configured ClamAV C<clamd> daemon detects malware in it.

=cut

# Implementation:
###############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Courier::Filter::Module::ClamAVd>

Creates a new B<ClamAVd> filter module.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<socket_name>

=item B<socket_host>

=item B<socket_port>

These options describe the Unix domain or TCP/IP socket that should be used to
connect to the ClamAV daemon.  If I<no> socket options are specified, first the
socket options from the local C<clamd.conf> configuration file are tried, then
the Unix domain socket B</var/run/clamav/clamd.ctl> is tried, then finally the
TCP/IP socket at B<127.0.0.1> on port B<3310> is tried.  If either Unix domain
or TCP/IP socket options are explicitly specified, only these are used.

=item B<max_message_size>

An integer value controlling the maximum size (in bytes) of the overall message
text for a message to be processed by this filter module.  Messages larger than
this value will never be processed, and thus will never match.  If B<undef>,
there is no size limit.  Defaults to B<1024**2> (1MB).

As MIME multipart processing can be quite CPU- and memory-intensive, you should
definitely restrict the message size to some sensible value that easily fits in
your server's memory.  1024**2 (1MB) should be appropriate for most uses of
this filter module.

=item B<max_part_size>

An integer value controlling the maximum size (in bytes) of any single MIME
part for that part to be processed by this filter module.  Parts larger than
this value will never be processed, and thus will never match.  If B<undef>,
there is no size limit.

Defaults to the value of the C<max_message_size> option, so you don't really
need to specify a part size limit if you are comfortable with using the same
value for both.  See the C<max_message_size> option for its default.

=item B<response>

A string that is to be returned as the match result in case of a match.  The
name of the detected malware is appended to the response text.  Defaults to
B<"Malware detected:">.

=back

All options of the B<Courier::Filter::Module> constructor are also supported
by the constructor of the B<ClamAVd> filter module.  Please see
L<Courier::Filter::Module/"new"> for their descriptions.

=cut

sub new {
    my ($class, %options) = @_;
    
    my $mime_parser = MIME::Parser->new();
    #$mime_parser->output_to_core(TRUE);
        # In-memory processing doesn't work, see comments in match_mime_part().
    $mime_parser->output_under(File::Spec->tmpdir);
    #$mime_parser->tmp_to_core(TRUE);
        # In-memory processing doesn't work, see comments in match_mime_part().
    $mime_parser->use_inner_files(TRUE);
    
    my $clamav_client = ClamAV::Client->new(
        socket_name     => $options{socket_name},
        socket_host     => $options{socket_host},
        socket_port     => $options{socket_port}
    );
    
    my $self = $class->SUPER::new(
        %options,
        mime_parser     => $mime_parser,
        clamav_client   => $clamav_client
    );
    
    # Default "max_message_size" option to 1024**2 (1MB):
    $self->{max_message_size} = 1024**2
        if not exists($self->{max_message_size});
    
    # Default "max_part_size" option to the "max_message_size" option:
    $self->{max_part_size} = $self->{max_message_size}
        if not exists($self->{max_part_size});
    
    return $self;
}

=back

=head2 Instance methods

See L<Courier::Filter::Module/"Instance methods"> for a description of the
provided instance methods.

=cut

sub match {
    my ($self, $message) = @_;
    
    return undef
        if  defined($self->{max_message_size})
        and -s $message->file_name > $self->{max_message_size};
    
    #my $text = $message->text;
    #my $part = $self->{mime_parser}->parse_data($text);
        # In-memory processing doesn't work, see comments in match_mime_part().
    my $part = $self->{mime_parser}->parse_open($message->file_name);
    my ($result, @code) = $self->match_mime_part($part);
    
    $result &&= 'ClamAVd: ' . $result;
    
    $self->{mime_parser}->filer->purge();
        # In-memory processing doesn't work, see comments in match_mime_part().
    rmdir($self->{mime_parser}->filer->output_dir);
        #if MIME::Tools->VERSION < 6.0;
        # Purging also doesn't work properly
        # (bug filed: <http://rt.cpan.org/NoAuth/Bug.html?id=7858>).
    
    return ($result, @code);
}

sub match_mime_part {
    my ($self, $part) = @_;
    
    if (my $body = $part->bodyhandle) {
        # No sub-parts, match this part.
        my $handle = $body->open('r');
        my $malware_name = $self->{clamav_client}->scan_stream($handle);
        return ($self->{response} || $self->default_response) . ' ' . $malware_name
            if defined($malware_name);
    }
    else {
        # Match all sub-parts:
        foreach my $subpart ($part->parts) {
            my ($result, @code) = $self->match_mime_part($subpart);
            return ($result, @code) if defined($result);
        }
    }
    
    return undef;
}

=head1 SEE ALSO

L<Courier::Filter::Module>, L<Courier::Filter::Overview>.

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
