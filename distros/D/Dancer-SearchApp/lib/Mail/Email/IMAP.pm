package Mail::Email::IMAP;
use strict;
use MIME::WordDecoder;
use MIME::Base64;
use MIME::QuotedPrint;
use Scalar::Util qw(weaken);
use Encode qw(decode);
use Text::Markdown ();
use HTTP::Date qw( time2isoz );
use Time::Piece;
#use 5.016; # for fc

use Mail::Clean 'clean_subject';
use vars qw($VERSION);
$VERSION = '0.06';

sub new {
    my $class = shift;
    bless { 
        text_formatter => Text::Markdown->new(),
        @_,
    } => $class;
};

sub from_imap_client {
    my ($package, $conn, $uid, %info) = @_;
    #weaken $conn;
    
    my $dt = $conn->date( $uid );
    
    my $timestamp;
    if( $dt ) {
        $dt =~ s!\s*\(([A-Z]+.*?)\)\s*$!!; # strip clear name of timezone at end
        $dt =~ s!\s*$!!; # Strip whitespace at end
        $dt =~ s!\bUTC$!GMT!; # "UTC" -> "GMT", ah, well...
        
        # Let's be lenient about the time format:
        my $format = '%d %b %Y %H:%M:%S';
        
        if( $dt =~ /,/ ) {
            # As good citizens, they added the weekday name:
            $format = "%a, $format";

        };
        if( $dt =~ /[A-Z]+$/ ) {
            # Instead of an offset, we have the name :-/
            $format = $format . " %Z";

        } else {
            # The default, for well-formed servers, an TZ offset
            $format .= " %z";
        };
        
        if( ! eval { $timestamp = Time::Piece->strptime( $dt, $format ); 1 }) {
            die "$@:\n$format - [$dt]\n";
        };
    } else {
        $dt ||= '';
        warn "No timestamp for $uid?! [$dt]";
    };
    
    my $self = $package->new(
        %info,
        uid      => $uid,
        date     => $timestamp,
        imap     => $conn,
        body     => $conn->get_bodystructure($uid),
        envelope => $conn->get_envelope($uid),
        categories => [],
    );
    
    $self
};

sub imap() {
    $_[0]->{imap}
};

# Install our reflectors for the envelope
BEGIN {
    no strict 'refs';
    for my $acc (qw< inreplyto >) {
        *{"$acc"} = sub {
            $_[0]->{envelope}->$acc
        };
    };
    
};

sub subject {
    if( ! $_[0]->{envelope} ) {
        warn Dumper $_[0];
    };
    my $str = clean_subject( mime_to_perl_string( $_[0]->{ envelope }->subject ) );
};

sub from {
    mime_to_perl_string( $_[0]->{ envelope }->from );
};

sub recipients {
    map { mime_to_perl_string( $_ ) } 
    grep { defined $_ } 
    ( $_[0]->{ envelope }->from,
      $_[0]->{ envelope }->cc,
      $_[0]->{ envelope }->bcc,
    )
};

sub uid { $_[0]->{uid} };
sub messageid { my $id = $_[0]->{envelope}->{messageid}; $id =~ s!^<(.*)>$!$1!; $id };

sub date { $_[0]->{date} };
sub year { $_[0]->date->year };
sub month { $_[0]->date->strftime('%m') };

=head2 C<< ->body( $pref ) >>

Finds the preferred body type or one of HTML, PLAIN
(in that order)

=cut

# Check for inline images
# Check for other linked media and inline it

sub best_alternative {
    my( $self, $body ) = @_;
    my $part;
    ($part)=     grep { #warn $_ . " (". $_->bodysubtype . ")";
                        'HTML' eq uc $_->bodysubtype
                      }
                 grep { 'HEAD' ne $_->bodytype }
                 $body->bodystructure;
    if(! $part) {
      ($part) = grep { #warn $_ . " (". $_->bodysubtype . ")";
                        'PLAIN' eq $_->bodysubtype
                      }
                 grep { 'HEAD' ne $_->bodytype }
                 $body->bodystructure;
    };
    return $part
}

sub body {
    my $self = shift;
    
    # We should query:
    # If multipart/alternative:
    #     Choose text/html
    #     Choose text/plain
    # else
    #     use whatever we got
    # And then look for attached images
    #warn Dumper [ $self->{body}->parts ];
    #warn Dumper $self->{body}->bodystructure;
    
    #warn $self->{body}->bodytype . "/" . $self->{body}->bodysubtype;
    #for ($self->{body}->parts) {
    #    warn "Part: $_";
    #    warn Dumper $self->{imap}->bodypart_string( $self->{uid}, $_ );
    #};
    
    # Recursively enumerate the body parts
    my %elements= (
        text => [],
        images => [],
    );
    
    my $body = $self->{body};
    my @toplevel = grep { $_->id =~ /^\d+$/ } $body->bodystructure;
    
    if( ! @toplevel ) {
        @toplevel = $body;
    };
    
    for my $part (@toplevel) {
        # This walks the whole mail structure
        #warn sprintf "Part %s", $part->id;
        my $mime= sprintf "%s/%s", lc $part->bodytype, lc $part->bodysubtype;
        #warn $mime;
    
        if( 'multipart/alternative' eq $mime ) {
            # -> subroutine: get_best_alternative()
            #warn "Have multipart bodytype, finding best alternative";
            # find suitable part
            # Assume it's about text anyway
            # Cascade from HTML -> plaintext
            $part = $self->best_alternative( $part );
            push @{ $elements{ text } }, {
                    content => $self->imap()->bodypart_string( $self->{uid}, $part->id ),
                    mime => $mime,
                    part => $part
            };
            #warn Dumper $elements{ text }->[-1];
        } elsif( 'multipart/mixed' eq $mime ) {
            # Find the different types (image, text, sound?) and use
            # one from each, resp concatenate
            # -> subroutine: get_parts()
            
        } else {
            #warn sprintf "Have only one body type (%s)", $part->bodytype;
            # take what we got
            
            if( 'image' eq $part->bodytype ) {
                my $ref = $part->bodyparms;
                next if( ! ref $part->bodyparms );
                my $name = $part->bodyparms->{name};
                # Download the image so we can later serve it up again under its name
                #push @{ $elements{ images } }, $part->textlines;
                #$body = sprintf '<img src="/%s/%s">',
                #    $self->permabase,
                #    $name;
                #warn "Image detected, serving up as '$body'";
                @{ $elements{ text } } = { content => $body, mime => "text/html", part => undef };
                
            } elsif( 'text/plain' eq $mime ) {
                push @{ $elements{ text } }, {
                    content => $self->imap()->bodypart_string( $self->{uid}, $part->id ),
                    mime => $mime,
                    part => $part
                };

            # we should handle text/html more gracefully!
            } else {
                #my $body= $part->textlines;
                #warn "Unknown / unhandled part $mime, hope it's text.";
                
                #warn Dumper $part;
                push @{ $elements{ text } }, {
                    content => $self->imap()->bodypart_string( $self->{uid}, $part->id ),
                    mime => $mime,
                    part => $part
                };
            };
        };
    };
    
    if( ! @{$elements{ text }}) {
        return 'No mail body';
    };

       $body= $elements{ text }->[0]->{content};
    my $type= $elements{ text }->[0]->{mime};
    my $part= $elements{ text }->[0]->{part};
    
    # Decode the transport encoding
    if( $part and 'base64' eq $part->bodyenc ) {
        $body = decode_base64( $body );
    } elsif( $part and 'quoted-printable' eq $part->bodyenc ) {
        $body = decode_qp( $body );
    };
    
    # Decode to appropriate charset
    if( $part and ref $part and my $enc = $part->bodyparms->{charset}) {
        $body = decode( $enc, $body );
    };
    
    # Find out whether we have HTML or plaintext
    if( 'text/plain' eq $type ) {
        $part= $body;

        # Maybe this should go into a separate sub/module
        # Strip mail footer
        $body=~ s!\n--\s*\n.*!!sm;
    
        # Strip obvious reply:
        $body=~ s!----- Reply message -----.*!!sm;
    
        # Strip quoted part in case we have a reply
        # A reply counts as
        # a line ending with ":" as the "$foo wrote on $date:"
        # followed by more than three (consecutive!) quoted lines
        $body=~ s!^[A-Z].*:(?:\s*^>.*$){3,}!!mg;
            #or warn "No quoted part found";

        # Fix the hardcoded ->markdown method
        # Maybe this should go into a separate sub/module
        $body= $self->{text_formatter}->markdown( $body );
    } elsif( 'text/html' eq $type ) {

        # Strip JS and other stuff, resp. only allow good stuff
        #     Most likely Clinton's HTML::StripScripts is the module to use
        # Maybe this should go into a separate sub/module
        # Also, we should use an HTML parser
        
        $body=~ s!<br>\s*--\s*<br>.*!!ms; # Strip mail footer
    };
    
    $body
};

1;