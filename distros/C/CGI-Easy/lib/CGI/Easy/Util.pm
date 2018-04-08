package CGI::Easy::Util;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.1';

use Export::Attrs;
use URI::Escape qw( uri_unescape uri_escape_utf8 );


sub date_http :Export {
    my ($tick) = @_;
    return _date($tick, 'http');
}

sub date_cookie :Export {
    my ($tick) = @_;
    return _date($tick, 'cookie');
}

sub _date {
	my ($tick, $format) = @_;
    my $sp = $format eq 'cookie' ? q{-} : q{ };
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime $tick;
	my $wkday = qw(Sun Mon Tue Wed Thu Fri Sat)[$wday];
	my $month = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)[$mon];
	return sprintf "%s, %02d$sp%s$sp%s %02d:%02d:%02d GMT",
        $wkday, $mday, $month, $year+1900, $hour, $min, $sec;   ## no critic(ProhibitMagicNumbers)
}

sub make_cookie :Export {
    my ($opt) = @_;
    return q{} if !defined $opt->{name};

    my $name    = $opt->{name};
    my $value   = defined $opt->{value} ? $opt->{value} : q{};
    my $domain  = $opt->{domain};
    my $path    = defined $opt->{path}  ? $opt->{path}  : q{/}; # IE require it
    my $expires = defined $opt->{expires} && $opt->{expires} =~ /\A\d+\z/xms ?
        date_cookie($opt->{expires}) : $opt->{expires};
    my $set_cookie = 'Set-Cookie: ';
    $set_cookie .= uri_escape_utf8($name) . q{=} . uri_escape_utf8($value);
    $set_cookie .= "; domain=$domain"   if defined $domain; ## no critic(ProhibitPostfixControls)
    $set_cookie .= "; path=$path";
    $set_cookie .= "; expires=$expires" if defined $expires;## no critic(ProhibitPostfixControls)
    $set_cookie .= '; secure'           if $opt->{secure};  ## no critic(ProhibitPostfixControls)
    $set_cookie .= "\r\n";
    return $set_cookie;
}

sub uri_unescape_plus :Export {
    my ($s) = @_;
    $s =~ s/[+]/ /xmsg;
    return uri_unescape($s);
}

sub burst_urlencoded :Export {
	my ($buffer) = @_;
    my %param;
    if (defined $buffer) {
        foreach my $pair (split /[&;]/xms, $buffer) {
            my ($name, $data) = split /=/xms, $pair, 2;
            $name = !defined $name ? q{} : uri_unescape_plus($name);
            $data = !defined $data ? q{} : uri_unescape_plus($data);
            push @{ $param{$name} }, $data;
        }
    }
    return \%param;
}

# This function derived from CGI::Minimal (1.29) by
#     Benjamin Franz <snowhare@nihongo.org>
#     Copyright (c) Benjamin Franz. All rights reserved.
sub burst_multipart :Export {
	my ($buffer, $bdry) = @_;

	# Special case boundaries causing problems with 'split'
	if ($bdry =~ m{[^A-Za-z0-9',-./:=]}ms) {                ## no critic (ProhibitEnumeratedClasses)
		my $nbdry = $bdry;
		$nbdry =~ s/([^A-Za-z0-9',-.\/:=])/ord($1)/msge;## no critic (ProhibitEnumeratedClasses)
		my $quoted_boundary = quotemeta $nbdry;
		while ($buffer =~ m/$quoted_boundary/ms) {
			$nbdry .= chr(65 + int rand 25);        ## no critic (ProhibitParensWithBuiltins, ProhibitMagicNumbers)
			$quoted_boundary = quotemeta $nbdry;
		}
		my $old_boundary = quotemeta $bdry;
		$buffer =~ s/$old_boundary/$nbdry/msg;
		$bdry   = $nbdry;
	}

	$bdry = "--$bdry(--)?\r\n";
	my @pairs = split /$bdry/ms, $buffer;

        my (%param, %filename, %mimetype);
	foreach my $pair (@pairs) {
		next if !defined $pair;
		chop $pair; # Trailing \015 
		chop $pair; # Trailing \012
		last if $pair eq q{--};
		next if !$pair;

		my ($header, $data) = split /\r\n\r\n/ms, $pair, 2;

		# parse the header
		$header =~ s/\r\n/\n/msg;
		my @headerlines = split /\n/ms, $header;
		my ($name, $filename, $mimetype);

		foreach my $headfield (@headerlines) {
			my ($fname, $fdata) = split /: /ms, $headfield, 2;
			if (lc $fname eq 'content-type') {
				$mimetype = $fdata;
			}
			if (lc $fname eq 'content-disposition') {
				my @dispositionlist = split /; /ms, $fdata;
				foreach my $dispitem (@dispositionlist) {
					next if $dispitem eq 'form-data';
					my ($dispfield,$dispdata) = split /=/ms, $dispitem, 2;
					$dispdata =~ s/\A\"//ms;
					$dispdata =~ s/\"\z//ms;
					if ($dispfield eq 'name') {
					        $name = $dispdata;
					}
					if ($dispfield eq 'filename') {
        					$filename = $dispdata;
        				}
				}
			}
		}
                next if !defined $name;
                next if !defined $data;

                push @{ $param{$name}    }, $data;
                push @{ $filename{$name} }, $filename;
                push @{ $mimetype{$name} }, $mimetype;
	}
        return (\%param, \%filename, \%mimetype);
}


### Unrelated to CGI, and thus internal/undocumented

sub _quote {
    my ($s) = @_;
    croak 'can\'t quote undefined value' if !defined $s;
    if ($s =~ / \s | ' | \A\z /xms) {
        $s =~ s/'/''/xmsg;
        $s = "'$s'";
    }
    return $s;
}

sub _unquote {
    my ($s) = @_;
    if ($s =~ s/\A'(.*)'\z/$1/xms) {
        $s =~ s/''/'/xmsg;
    }
    return $s;
}

sub quote_list :Export {
    return join q{ }, map {_quote($_)} @_;
}

sub unquote_list :Export {
    my ($s) = @_;
    return if !defined $s;
    my @w;
    while ($s =~ /\G ( [^'\s]+ | '[^']*(?:''[^']*)*' ) (?:\s+|\z)/xmsgc) {
        my $w = $1;
        push @w, _unquote($w);
    }
    return if $s !~ /\G\z/xmsg;
    return \@w;
}

sub unquote_hash :Export {
    my $w = unquote_list(@_);
    return $w && $#{$w} % 2 ? { @{$w} } : undef;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

CGI::Easy::Util - low-level helpers for HTTP/CGI


=head1 VERSION

This document describes CGI::Easy::Util version v2.0.1


=head1 SYNOPSIS

    use CGI::Easy::Util qw( date_http date_cookie make_cookie );

    my $mtime = (stat '/some/file')[9];
    printf "Last-Modified: %s\r\n", date_http($mtime);

    printf "Set-Cookie: a=5; expires=%s\r\n", date_cookie(time+86400);

    printf make_cookie({ name=>'a', value=>5, expires=>time+86400 });


    use CGI::Easy::Util qw( uri_unescape_plus
                            burst_urlencoded burst_multipart );

    my $s = uri_unescape_plus('a+b%20c');   # $s is 'a b c'

    my %param = %{ burst_urlencoded($ENV{QUERY_STRING}) };
    my $a = $param{a}[0];

    ($params, $filenames, $mimetypes) = burst_multipart($STDIN_data, $1)
        if $ENV{CONTENT_TYPE} =~ m/;\s+boundary=(.*)/xms;
    my $avatar_image    = $params->{avatar}[0];
    my $avatar_filename = $filenames->{avatar}[0];
    my $avatar_mimetype = $mimetypes->{avatar}[0];


=head1 DESCRIPTION

This module contain low-level function which you usually doesn't need -
use L<CGI::Easy::Request> and L<CGI::Easy::Headers> instead.


=head1 EXPORTS

Nothing by default, but all documented functions can be explicitly imported.


=head1 INTERFACE 

=head2 date_http

    $date = date_http( $seconds );

Convert given time into text format suitable for sending in HTTP headers.

Return date string.

=head2 date_cookie

    $date = date_cookie( $seconds );

Convert given time into text format suitable for sending in HTTP header
Set-Cookie's "expires" option.

Return date string.

=head2 make_cookie

    $header = make_cookie( \%cookie );

Convert HASHREF with cookie properties to "Set-Cookie: ..." HTTP header.

Possible keys in %cookie:

    name        REQUIRED STRING
    value       OPTIONAL STRING (default "")
    domain      OPTIONAL STRING (default "")
    path        OPTIONAL STRING (default "/")
    expires     OPTIONAL STRING or SECONDS
    secure      OPTIONAL BOOL

Format for "expires" should be either correct date 
'Thu, 01-Jan-1970 00:00:00 GMT' or time in seconds.

Return HTTP header string.

=head2 uri_unescape_plus

    $unescaped = uri_unescape_plus( $uri_escaped_value );

Same as uri_unescape from L<URI::Escape> but additionally replace '+' with space.

Return unescaped string.

=head2 burst_urlencoded

    my %param = %{ burst_urlencoded( $url_encoded_name_value_pairs ) };

Unpack name/value pairs from url-encoded string (like $ENV{QUERY_STRING}
or STDIN content for non-multipart forms sent using POST method).

Return HASHREF with params, each param's value will be ARRAYREF
(because there can be more than one value for any parameter in source string).

=head2 burst_multipart

    ($params, $filenames, $mimetypes) = burst_multipart( $buffer, $boundary );

Unpack buffer with name/value pairs in multipart/form-data format.
This format usually used to upload files from forms, and each name/value
pair may additionally contain 'file name' and 'mime type' properties.

Return three HASHREF (with param's values, with param's file names, and
with param's mime types), all values in all three HASHREF are ARRAYREF
(because there can be more than one value for any parameter in source string).
For non-file-upload parameters corresponding values in last two hashes
(with file names and mime types) will be undef().


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

This module also include some code derived from

=over

=item CGI::Minimal (1.29)

by Benjamin Franz <snowhare@nihongo.org>.
Copyright (c) Benjamin Franz. All rights reserved.

=back

This is free software, licensed under:

  The MIT (X11) License


=cut
