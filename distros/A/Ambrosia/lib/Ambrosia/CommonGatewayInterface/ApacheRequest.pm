package Ambrosia::CommonGatewayInterface::ApacheRequest;
use strict;
use warnings;

use Apache ();
use Apache::Request;
use Apache::Constants qw':methods :http';

use Ambrosia::Meta;

class sealed
{
    extends => [qw/Ambrosia::CommonGatewayInterface/],
    public  => [qw/header_params/],
    private => [qw/__core/]
};

our $VERSION = 0.010;

sub open
{
    my $self = shift;
    my $params = shift;

    my $r = $self->__core = Apache->request;
    $self->_handler = new Apache::Request($r);

    if ( $params )
    {
        $self->delete_all;
        foreach ( keys %$params)
        {
            $self->_handler->param($_, $params->{$_});
        }
    }
    $self->SUPER::open();
    return $self->_handler;
}

################################################################################

sub input_data
{
    shift->_handler->param(@_);
}

sub output_data
{
    my $self = shift;
    my ($nph, $no_cache, $header) = prepare_header(@_);

    if ( $self->IS_OK )
    {
        $self->__core->status(&HTTP_OK);
    }
    elsif( $self->IS_REDIRECT )
    {
        $self->__core->status(&HTTP_MOVED_TEMPORARILY);
    }
    elsif( $self->IS_ERROR )
    {
        $self->__core->status(&HTTP_INTERNAL_SERVER_ERROR);
    }

    $self->__core->send_http_header if $nph;
    $self->__core->no_cache if $no_cache;
    $self->__core->send_cgi_header(join(crlf(), @$header, crlf()));

    return '';
}

################################################################################

sub crlf() { "\r\n"; }

sub prepare_header
{
    my %params = @_;
    my @headers = ();
    my $type = 'Content-Type: text/html';
    my $charset = '';
    my $date;
    my $nph;
    my $status;
    my $no_cache;

    foreach ( keys %params )
    {
        /-?([[:alnum:]]+)(?:[-_](\w+))?/;
        my $k = uc($1 . ($2 ? ('-' . $2) : ''));

        if ( $k eq 'TYPE' || $k eq 'CONTENT-TYPE')
        {
            $type = 'Content-Type: ' . $params{$_};
        }
        elsif( $k eq 'CHARSET' )
        {
            $charset = $params{$_};
        }
        elsif( $k eq 'PRAGMA')
        {
            $no_cache = $params{$_};
        }
        elsif( $k eq 'COOKIE' || $k eq 'COOKIES' )
        {
            my @cookies = ref $params{$_} eq 'ARRAY' ? @{$params{$_}} : $params{$_};
            foreach (@cookies)
            {
                my $cs = eval { $_->can('as_string') and $_->as_string; } || $_;
                push @headers, 'Set-Cookie: ' . $cs if $cs;
            }
            $date = 1;
        }
        elsif( $k eq 'STATUS' )
        {
            $status = $params{$_};
            push @headers, 'Status: ' . $status;
        }
        elsif( $k eq 'EXPIRES' )
        {
            push @headers, 'Expires: ' . expires($params{$_},'http');
            $date = 1;
        }
        elsif( $k eq 'P3P' )
        {
            my $p3p = $params{$_};
            push @headers, 'P3P: policyref="/w3c/p3p.xml", CP="'
                    . (ref($p3p) eq 'ARRAY' ? (join ' ', @$p3p) : $p3p) . '"';
        }
        elsif( $k eq 'NPH' )
        {
            my $protocol = $ENV{SERVER_PROTOCOL} || 'HTTP/1.0';
            $nph = $protocol . crlf();
            $date = 1;
        }
        elsif( $k eq 'TARGET' )
        {
            push @headers, 'Window-Target: ' . $params{$_};
        }
        elsif( $k eq 'ATTACHMENT' )
        {
            push @headers, 'Content-Disposition: attachment; filename="' . $params{$_} . '"';
        }
        elsif( $k eq 'URI' )
        {
            push @headers, 'Location: ' . $params{$_};
        }
        else
        {
            /-?([[:alnum:]]+)(?:[-_](\w+))?/;
            push @headers, ($1 . ($2 ? ('-' . $2) :'')) . ': ' . $params{$_};
        }
    }

    if ( defined $nph )
    {
        $nph .= ($status || '200 OK') . 'Server: ' . $ENV{SERVER_SOFTWARE};
    }

    if ($charset && $type !~ /\bcharset\b/)
    {
        $type .= '; charset=' . $charset;
    }

    push @headers, $type;

    if ( $date )
    {
        push @headers, 'Date: ' . expires(0, 'http');
    }

    return ($nph, $no_cache, \@headers);    
}


## FROM CGI::Util ##
# This internal routine creates date strings suitable for use in
# cookies and HTTP headers.  (They differ, unfortunately.)
# Thanks to Mark Fisher for this.
sub expires {
    my($time,$format) = @_;
    $format ||= 'http';

    my(@MON)=qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
    my(@WDAY) = qw/Sun Mon Tue Wed Thu Fri Sat/;

    # pass through preformatted dates for the sake of expire_calc()
    $time = expire_calc($time);
    return $time unless $time =~ /^\d+$/;

    # make HTTP/cookie date string from GMT'ed time
    # (cookies use '-' as date separator, HTTP uses ' ')
    my($sc) = ' ';
    $sc = '-' if $format eq "cookie";
    my($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime($time);
    $year += 1900;
    return sprintf("%s, %02d$sc%s$sc%04d %02d:%02d:%02d GMT",
                   $WDAY[$wday],$mday,$MON[$mon],$year,$hour,$min,$sec);
}

## FROM CGI::Util ##
# This internal routine creates an expires time exactly some number of
# hours from the current time.  It incorporates modifications from
# Mark Fisher.
sub expire_calc {
    my($time) = @_;
    my(%mult) = ('s'=>1,
                 'm'=>60,
                 'h'=>60*60,
                 'd'=>60*60*24,
                 'M'=>60*60*24*30,
                 'y'=>60*60*24*365);
    # format for time can be in any of the forms...
    # "now" -- expire immediately
    # "+180s" -- in 180 seconds
    # "+2m" -- in 2 minutes
    # "+12h" -- in 12 hours
    # "+1d"  -- in 1 day
    # "+3M"  -- in 3 months
    # "+2y"  -- in 2 years
    # "-3m"  -- 3 minutes ago(!)
    # If you don't supply one of these forms, we assume you are
    # specifying the date yourself
    my($offset);
    if (!$time || (lc($time) eq 'now')) {
      $offset = 0;
    } elsif ($time=~/^\d+/) {
      return $time;
    } elsif ($time=~/^([+-]?(?:\d+|\d*\.\d*))([smhdMy])/) {
      $offset = ($mult{$2} || 1)*$1;
    } else {
      return $time;
    }
    return (time+$offset);
}

1;

__END__

=head1 NAME

Ambrosia::CommonGatewayInterface::ApacheRequest - 

=head1 VERSION

version 0.010

=head1 DESCRIPTION

C<Ambrosia::CommonGatewayInterface::ApacheRequest> .

=head1 CONSTRUCTOR

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
