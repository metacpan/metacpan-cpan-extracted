package CGI::Easy::Headers;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.1';

use CGI::Easy::Util qw( date_http make_cookie );


sub new {
    my ($class, $opt) = @_;
    my $self = {
        'Status'        => '200 OK',
        'Content-Type'  => 'text/html; charset=utf-8',
        'Date'          => q{},
        'Set-Cookie'    => [],
        $opt ? %{$opt} : (),
    };
    return bless $self, $class;
}

sub add_cookie {
    my ($self, @cookies) = @_;
    push @{ $self->{'Set-Cookie'} }, @cookies;
    return;
}

sub redirect {
    my ($self, $url, $status) = @_;
    $self->{'Location'} = $url;
    if (!defined $status) {
        $status = '302 Found';
    }
    $self->{'Status'} = $status;
    return;
}

sub require_basic_auth {
    my ($self, $realm) = @_;
    if (!defined $realm) {
        $realm = q{};
    }
    $self->{'WWW-Authenticate'} = "Basic realm=\"$realm\"";
    $self->{'Status'} = '401 Authorization Required';
    return;
}

sub compose {
    my ($self) = @_;
    my %h = %{$self};
    for my $header (keys %h) {
        my $expect = join q{-}, map {ucfirst lc} split /-/xms, $header;
        $expect =~ s/\bEtag\b/ETag/xms;
        $expect =~ s/\bWww\b/WWW/xms;
        $expect =~ s/\bMd5\b/MD5/xms;
        if ($header ne $expect) {
            croak "Bad header name '$header' (should be '$expect')";
        }
    }

    my $s =     sprintf "Status: %s\r\n",       delete $h{'Status'};
    $s .=       sprintf "Content-Type: %s\r\n", delete $h{'Content-Type'};
    my $date = delete $h{'Date'};
    if (defined $date) {
        $s .=   sprintf "Date: %s\r\n",         $date || date_http(time);
    }
    for my $cookie (@{ delete $h{'Set-Cookie'} }) {
        $s .=   make_cookie($cookie);
    }
    for my $header (keys %h) {
        if (!ref $h{$header}) {
            $h{$header} = [ $h{$header} ];
        }
        for my $value (@{ $h{$header} }) {
            $s .= sprintf "%s: %s\r\n",         $header, $value;
        }
    }

    return $s . "\r\n";
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

CGI::Easy::Headers - Manage HTTP headers


=head1 VERSION

This document describes CGI::Easy::Headers version v2.0.1


=head1 SYNOPSIS

    use CGI::Easy::Headers;

    my $h = CGI::Easy::Headers->new();

    $h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT';
    $h->add_cookie({
        name    => 'somevar',
        value   => 'someval',
        expires => time + 86400,
        domain  => '.example.com',
        path    => '/admin/',
        secure  => 1,
    });
    print $h->compose(), '<html>...</html>';

    $h->redirect('http://google.com/');
    print $h->compose();

    $h->require_basic_auth('Secret Area');
    print $h->compose();


=head1 DESCRIPTION

Provides user with simple hash where user can easy add/modify/delete HTTP
headers while preparing them for sending in CGI reply. 


=head1 INTERFACE 

=head2 new

    $h = CGI::Easy::Headers->new();
    $h = CGI::Easy::Headers->new( \%headers );

Create new CGI::Easy::Headers object/hash with these fields:

    'Status'        => '200 OK',
    'Content-Type'  => 'text/html; charset=utf-8',
    'Date'          => q{},
    'Set-Cookie'    => [],

If %headers given, it will be appended to default keys and so may
overwrite default values.

See compose() below about special values in 'Date' and 'Set-Cookie' fields.

While you're free to add/modify/delete any fields in this object/hash,
HTTP headers is case-insensitive, and thus it's possible to accidentally
create different keys in this hash for same HTTP header:

    $h->{'Content-Type'} = 'text/plain';
    $h->{'content-type'} = 'image/png';

To protect against this, compose() allow only keys named in 'Content-Type'
way and will throw exception if it found keys named in other way. There
few exceptions from this rule: 'ETag', 'WWW-Authenticate' and 'Digest-MD5'.

Return created CGI::Easy::Headers object.

=head2 add_cookie

    $h->add_cookie( \%cookie );
    $h->add_cookie( \%cookie1, \%cookie2, ... );

Add new cookies to current HTTP headers. Actually it's just do this:

    push @{ $h->{'Set-Cookie'} }, \%cookie, ...;

Possible keys in %cookie:

    name        REQUIRED STRING
    value       OPTIONAL STRING (default "")
    domain      OPTIONAL STRING (default "")
    path        OPTIONAL STRING (default "/")
    expires     OPTIONAL STRING or SECONDS
    secure      OPTIONAL BOOL

Format for "expires" should be either correct date 
'Thu, 01-Jan-1970 00:00:00 GMT' or time in seconds.

Return nothing.

=head2 redirect

    $h->redirect( $url );
    $h->redirect( $url, $status );

Set HTTP headers 'Location' and 'Status'.

If $status not provided, use '302 Found'.

Return nothing.

=head2 require_basic_auth

    $h->require_basic_auth();
    $h->require_basic_auth( $realm );

Set HTTP headers 'WWW-Authenticate' and 'Status'.

Return nothing.

=head2 compose

    $headers = $h->compose();

Render all object's fields into single string with all HTTP headers suitable
for sending to user's browser.

Most object's field values expected to be simple strings (or ARRAYREF with
strings for headers with more than one values) which should be copied to
HTTP headers as is:

    $h->{ETag} = '123';
    $h->{'X-My-Header'} = 'my value';
    $h->{'X-Powered-By'} = ['Perl', 'CGI::Easy'];
    $headers = $h->compose();
    # $headers will be:
    #   "ETag: 123\r\n" . 
    #   "X-My-Header: my value\r\n" .
    #   "X-Powered-By: Perl\r\n" .
    #   "X-Powered-By: CGI::Easy\r\n" .
    #   "\r\n"

But there few fields with special handling:

=over

=item Date

You can set it to usual string (like 'Sat, 01 Jan 2000 00:00:00 GMT')
or to unixtime in seconds (as returned by time()) - in later case time
in seconds will be automatically converted to string with date/time.

If it set to empty string (new() will initially set it this way),
then current date/time will be automatically used.

=item Set-Cookie

This field must be ARRAYREF (new() will initially set it to []), and
instead of strings must contain HASHREF with cookie properties (see
add_cookie() above).

=back

Return string with HTTP headers ending with empty line.
Throw exception on keys named with wrong case (see new() about details).


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-CGI-Easy/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-CGI-Easy>

    git clone https://github.com/powerman/perl-CGI-Easy.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=CGI-Easy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/CGI-Easy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Easy>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=CGI-Easy>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/CGI-Easy>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
