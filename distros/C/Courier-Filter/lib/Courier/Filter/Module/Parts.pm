#
# Courier::Filter::Module::Parts class
#
# (C) 2003-2008 Julian Mehnle <julian@mehnle.net>
# $Id: Parts.pm 210 2008-03-21 19:30:31Z julian $
#
###############################################################################

=head1 NAME

Courier::Filter::Module::Parts - Message (MIME multipart and ZIP archive)
parts filter module for the Courier::Filter framework

=cut

package Courier::Filter::Module::Parts;

use warnings;
use strict;

use base 'Courier::Filter::Module';

use MIME::Parser 5.4;
use IO::InnerFile 2.110;
    # Require either MIME::Parser 5.413 or lower, or IO::InnerFile 2.110+
    # (where IO::InnerFile::seek() properly returns TRUE when appropriate).
use Digest::MD5;
use File::Spec;
    # In-memory processing doesn't work, see comments in match_mime_part().

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant default_response   => 'Prohibited message part detected.';

=head1 SYNOPSIS

    use Courier::Filter::Module::Parts;
    
    my $module = Courier::Filter::Module::Parts->new(
        max_message_size
                        => $max_message_size,
        max_part_size   => $max_part_size,
        views           => ['raw', 'zip'],
        signatures      => [
            {
                # One or more of the following options:
                mime_type       => 'text/html' || qr/html/i,
                file_name       => 'file_name.ext' || qr/\.(com|exe)$/i,
                size            => 106496,
                digest_md5      => 'b09e26c292759d654633d3c8ed00d18d',
                encrypted       => 0,
                
                # Optionally any of the following:
                views           => ['raw', 'zip'],
                response        => $response_text
            },
            ...
        ],
        
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
message if one of the message's parts (MIME parts, or files in a ZIP archive)
matches one of the configured signatures.

=cut

# Implementation:
###############################################################################

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Courier::Filter::Module::Parts>

Creates a new B<Parts> filter module.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<views>

An arrayref containing the global default set of I<views> the filter module
should apply to message parts when matching the configured signatures against
them.  A view is the way how a MIME part's (MIME-decoded) data is interpreted.
Defaults to B<['raw']>.

The following views are supported:

=over

=item B<raw>

The MIME part is MIME-decoded but not otherwise transformed.  The raw MIME part
is then matched against the configured signatures.

=item B<zip>

If the MIME part has a file name ending in C<.zip>, it is considered a ZIP
archive, and all unencrypted files in the archive are matched as individual
message parts against the configured signatures.  The zip view requires the
B<Archive::Zip> Perl module to be installed.

=back

=item B<max_message_size>

=item B<max_size> (DEPRECATED)

An integer value controlling the maximum size (in bytes) of the overall message
text for a message to be processed by this filter module.  Messages larger than
this value will never be processed, and thus will never match.  If B<undef>,
there is no size limit.  Defaults to B<1024**2> (1MB).

As MIME multipart and ZIP archive processing can be quite CPU- and
memory-intensive (although the B<Parts> filter module makes use of temporary
files since version 0.13), you should definitely restrict the message size to
some sensible value that easily fits in your server's memory.  1024**2 (1MB)
should be appropriate for most uses of this filter module.

The C<max_message_size> option was previously called C<max_size>, but the
latter is now deprecated and may not be supported in future versions of the
B<Parts> filter module.

=item B<max_part_size>

An integer value controlling the maximum size (in bytes) of any single message
part (i.e. MIME part in a message, or file in an archive) for that part to be
processed by this filter module.  Parts larger than this value will never be
processed, and thus will never match.  If B<undef>, there is no size limit.

Defaults to the value of the C<max_message_size> option, so you don't really
need to specify a part size limit if you are comfortable with using the same
value for both.  See the C<max_message_size> option for its default.

If you make use of the B<'zip'> view, be aware of the risk posed by so-called
I<decompression bombs>, which allow messages to easily fall below the overall
message size limit, while a file in a small attached ZIP archive can decompress
to a huge size.  The part size limit prevents huge files from being
decompressed.

=item B<signatures>

I<Required>.  A reference to an array containing the list of I<signatures>
against which message parts are to be matched.  A signature in turn is a
reference to a hash containing one or more so-called signature I<aspects> (as
key/value pairs) and any signature I<options> (also as key/value pairs).

I<Signature aspects>

Aspects may either be scalar values (for exact, case-sensitive matches), or
regular expression objects created with the C<qr//> operator (for inexact,
partial matches).  For a signature to match a message part, I<all> of the
signature's specified aspects must match those of the message part.  For the
filter module to match a message, I<any> of the signatures must match I<any> of
the message's parts.

A signature aspect can be any of the following:

=over

=item B<mime_type>

The MIME type of the message part ('type/sub-type').

=item B<file_name>

The file name of the message part.

=item B<size>

The exact size (in bytes) of the decoded message part.

=item B<digest_md5>

The MD5 digest of the decoded message part (32 hex digits, as printed by
`md5sum`).

=item B<encrypted>

A boolean value denoting whether the message part is encrypted and its contents
are inaccessible to the B<Parts> filter module.

=back

I<Signature options>

A signature option can be any of the following:

=over

=item B<views>

An arrayref containing the set of I<views> the filter module should apply to
message parts when matching I<this> signature against them.  For a list of
supported views, see the description of the constructor's C<views> option.
Defaults to the global set of views specified to the constructor.

=item B<response>

A string that is to be returned as the match result in case of a match.
Defaults to B<"Prohibited message part detected.">.

=back

I<Example>

So for instance, a signature list could look like this:

    signatures  => [
        {
            mime_type   => qr/html/i,
            response    => 'No HTML mail, please.'
        },
        {
            file_name   => qr/\.(com|exe|lnk|pif|scr|vbs)$/i,
            response    => 'Executable content detected'
        },
        {
            size        => 106496,
            digest_md5  => 'b09e26c292759d654633d3c8ed00d18d',
            views       => ['raw', 'zip'],  # Look into ZIP archives, too!
            response    => 'Worm detected: W32.Swen'
        },
        {
            size        => 22528,
            # Cannot set a specific digest_md5 since W32.Mydoom
            # is polymorphic.
            response    => 'Worm suspected: W32.Mydoom'
        },
        {
            encrypted   => 1,
            views       => ['zip'],
            response    => 'Worm suspected ' .
                           '(only worms and fools use ZIP encryption)'
        }
    ]

=back

All options of the B<Courier::Filter::Module> constructor are also supported
by the constructor of the B<Parts> filter module.  Please see
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
    
    my $self = $class->SUPER::new(
        %options,
        mime_parser => $mime_parser
    );
    
    # Default "max_message_size" option to the deprecated "max_size" option,
    # or to 1024**2 (1MB):
    $self->{max_message_size} = (
        exists($self->{max_size}) ? $self->{max_size} : 1024**2
    )
        if not exists($self->{max_message_size});
    
    # Default "max_part_size" option to the "max_message_size" option:
    $self->{max_part_size} = $self->{max_message_size}
        if not exists($self->{max_part_size});
    
    # Default "views" option to 'raw':
    my $views = $self->{views} || { 'raw' => TRUE };
    
    # Transform "views" option into hashref if it was given as an arrayref:
    $views = { map(($_ => TRUE), @$views) }
        if ref($views) eq 'ARRAY';
    
    my $used_views = { %$views };
    foreach my $signature ( @{$self->{signatures}} ) {
        # Default "views" option to global "views" option:
        my $signature_views = $signature->{views} || $views;
        
        # Transform "views" option into hashref if it was given as an arrayref:
        $signature_views = { map(($_ => TRUE), @$signature_views) }
            if ref($signature_views) eq 'ARRAY';
        
        # Add any signature-specific views to the global set of used views:
        %$used_views = (%$used_views, %$signature_views);

        $signature->{views} = $signature_views;
        
        $self->compile_signature($signature);
    }

    $self->{used_views} = $used_views;
    
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
    
    $result &&= 'Parts: ' . $result;
    
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
        
        #my $handle = $body->open('r');
            # In-memory processing doesn't work because MIME::Body::open()
            # doesn't provide a fully-IO::Handle-compatible I/O handle object
            # (opened() method is missing, no bug filed).  Working around that
            # by alternatively creating a Perl 5.8 style in-memory file
            # object...
            #   my $body_as_string = $body->as_string;
            #   open(my $handle, '+<', \$body_as_string);
            # ...doesn't work either because Archive::Zip::_isSeekable() is
            # broken (erroneously considers Perl 5.8 style in-memory IO::File
            # objects not to be seekable,
            # bug filed: <http://rt.cpan.org/NoAuth/Bug.html?id=7855>).
            # All of this forces us to make MIME::Parser use temporary files
            # instead of doing everything exclusively in-memory.  Aaargh!!
        
        # First, we gather signature makers for all possible (and enabled)
        # views of the MIME part, then we actually test each view in turn
        # against the configured test signatures.
        
        my @views;
        
        # Raw view (the MIME part itself) (if enabled):
        my $rawsig = $self->make_signature_from_mime_part($part);
        if ($self->{used_views}->{'raw'}) {
            push(
                @views,
                {
                    name        => 'raw',
                    sig_maker   => sub { $rawsig }
                }
            )
                if not defined($self->{max_part_size})
                or $rawsig->{size} <= $self->{max_part_size};
        }
        
        # ZIP archive members view (if enabled and MIME part is a ZIP archive):
        if (
            $self->{used_views}->{'zip'} and
            defined($rawsig->{file_name}) and
            $rawsig->{file_name} =~ /\.zip$/i
        ) {
            require Archive::Zip;
            
            my $archive = Archive::Zip->new();
            #$archive->readFromFileHandle($handle);
                # In-memory processing doesn't work, see above.
            $archive->read($body->path);
            
            # Make a view for each archive member:
            foreach my $member ($archive->members) {
                push(
                    @views,
                    {
                        name        => 'zip',
                        sig_maker   => sub {
                            $self->make_signature_from_zip_archive_member($member)
                        }
                    }
                )
                    if not defined($self->{max_part_size})
                    or $member->uncompressedSize <= $self->{max_part_size};
            }
        }
        
        # Now, for each view, try matching the configured signatures:
        foreach my $view (@views) {
            # Make signature from data view:
            my $datasig = $view->{sig_maker}->();

            # Test that signature against the configured signatures:
            foreach my $signature ( @{$self->{signatures}} ) {
                # Skip this signature if it doesn't apply to the current view:
                next if not $signature->{views}->{ $view->{name} };
                
                my ($result, @code) = $signature->{matcher}->($datasig);
                return ($result, @code) if defined($result);
            }
        }
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

sub make_signature_from_mime_part {
    my ($self, $part) = @_;
    
    my $head = $part->head;
    my $body = $part->bodyhandle;
    my $text = $body->as_string;
    
    return {
        mime_type   => $head->mime_type,
        file_name   => $head->recommended_filename,
        size        => length($text),
        digest_md5  => Digest::MD5::md5_hex($text),
        encrypted   => FALSE
    };
}

sub make_signature_from_zip_archive_member {
    my ($self, $member) = @_;
    
    return {
        mime_type   => undef,
        file_name   => $member->fileName,
        size        => $member->uncompressedSize,
        digest_md5  => $member->isEncrypted ?
                           undef
                       :   Digest::MD5::md5_hex(scalar($member->contents)),
        encrypted   => $member->isEncrypted
    };
}

sub compile_signature {
    my ($self, $signature) = @_;

    my %matchers;

    my @aspects = grep(!/^(?:response|views)$/, keys(%$signature));
    foreach my $aspect (@aspects) {
        my $pattern = $signature->{$aspect};
        
        my $matcher;
        if (ref($pattern) eq 'Regexp') {
            $matcher = sub { $_[0] =~ $pattern };
        }
        elsif (ref($pattern) eq 'CODE') {
            $matcher = $pattern;
        }
        else {
            if ($aspect =~ /^(?:encrypted)$/) {
                # Aspect is of boolean type:
                $matcher = sub { not ($_[0] xor $pattern) };
            }
            else {
                $matcher = sub { $_[0] eq $pattern };
            }
        }
        
        $matchers{$aspect} = $matcher;
    }
    
    my @response =
        ref($signature->{response}) eq 'ARRAY' ?
            @{ $signature->{response} }
        :   ($signature->{response} || $self->default_response);
    
    my $matcher = sub {
        # Closure with regard to %matchers.
        my ($signature) = @_;
        foreach my $aspect (keys(%matchers)) {
            my $value = $signature->{$aspect};
            return undef
                if not defined($value)
                or not $matchers{$aspect}->($value);
        }
        return @response;
    };
    
    $signature->{matcher} = $matcher;
    
    return;
}

=head1 SEE ALSO

L<Courier::Filter::Module>, L<Courier::Filter::Overview>.

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
