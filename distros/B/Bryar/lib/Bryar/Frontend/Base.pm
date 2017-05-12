package Bryar::Frontend::Base;
use 5.006;
use strict;
use warnings;
use Carp;
our $VERSION = '1.2';
use Time::Piece;
use Time::Local;
use Digest::MD5 qw(md5_hex);
use Encode;
use HTTP::Date;

=head1 NAME

Bryar::Frontend::Base - Base class for frontend classes

=head1 SYNOPSIS

    use base 'Bryar::Frontend::Base';
    sub obtain_url {...}
    sub obtain_path_info {...}
    sub obtain_args {...}
    sub send_data {...}
    sub send_header {...}
    sub get_header {...}

=head1 DESCRIPTION

This abstracts the work of front-ending Bryar, to make real front-end
classes tidier.

=head1 METHODS

You provide these.

=head2 obtain_url

Returns the full URL for this page.

=head2 obtain_path_info

Returns the path info from the server: the part of the URL after
F<bryar.cgi> or whatever.

=head2 obtain_params

Returns a hash of CGI parameters.

=head2 send_data

Write stuff to the browser. This will only be called once.

=head2 send_header

Write stuff to the browser, first.

=head2 get_header

Read a HTTP header.

=cut

sub obtain_url { croak "Don't use Bryar::FrontEnd::Base directly"; }
sub obtain_params { croak "Abstract base class. ABSTRACT BASE CLASS."; }

sub parse_args {
    my $self = shift;
    my $config = shift;
    my %params = $self->obtain_params();
    my %args = $self->parse_path($config);
    if (my $search = $params{search}) {
        $args{content} = $search if $search =~ /\S{3,}/; # Avoid trivials.
    }
    for (qw(comments format)) {
		$args{$_} = $params{$_} if exists $params{$_};
    }
    $self->process_new_comment($config, %params) if $params{newcomment};
    return %args;
}

sub parse_path {
    my ($self, $config) = @_;
    my $pi = $self->obtain_path_info();
    my @pi = split m{/}, $pi;
    shift @pi while @pi and not$pi[0];
    #...

    my %args;
    if ($pi[-1] and $pi[-1] eq "xml") { $args{format} = "xml"; pop @pi; }
    if ($pi[-1] and $pi[-1] =~ /^id_([0-9]+)/) { $args{id} = $1; pop @pi; }
    if ($pi[0] and $pi[0] =~ /^([a-zA-Z]\w*)/
               and $pi[0] !~ /^(?:before)_[0-9]+$/) { # We have a subblog
        $args{subblog} = $1;
        shift @pi;
    }
    if (@pi == 1 and $pi[0] =~ /^before_([0-9]+)$/) {
        $args{before} = $1;
        $args{limit} = $config->{recent};
    } elsif (@pi) { # Time/date handling
        my ($from, $til) = _make_from_til(@pi);
        if ($from and $til) {
            $args{before} = $til;
            $args{since} = $from;
        }
    } else {
        $args{limit}   = $config->{recent} if $args{subblog};
    }

    return %args;
}

sub process_new_comment {
    my ($self, $config, %params) = @_;
    my ($doc) = $config->source->search($config, id => $params{id});
    $self->report_error("Couldn't find Doc $params{id}") unless $doc;
    $config->source->add_comment(
        $config,
        document => $doc,
        author => $params{author},
        url => $params{url},
        email => $params{email},
        content => $params{content},
        epoch => time
    );
}

my $mon = 0;
my %mons = map { $_ => $mon++ }
    qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

sub _make_from_til {
    my ($y, $m, $d) = @_;
    if (!$y) { return (0,0) }
    my ($fm, $tm) = (0, 11);
    if ($m and exists $mons{$m}) { $fm = $tm = $mons{$m}; }
    my ($fd, $td);
    if ($d) { $fd = $td = $d }
    else { 
        $fd = 1;
        my $when = timelocal(0,0,0,1, $tm, $y);
        $td = Time::Piece->new($when)->month_last_day;
    }
    return (timelocal(0,0,0, $fd, $fm, $y),
            timelocal(59,59,23, $td, $tm, $y));
}


=head2 output

    $self->output

Output the entire blog data to the browser

=cut

sub output {
    my ($self, $ct, $data, $last_modified, $headers) = @_;
    $headers ||= { };

    $self->send_header('Content-Type', $ct) if not $headers->{'Content-Type'};

    if (not $headers->{Status} and $self->not_modified($last_modified, $data)) {
        $self->send_header($_, $headers->{$_}) foreach keys %$headers;
        $self->send_header('Status', '304 Not Modified');
        $self->send_header('Content-Length', 0);
        $self->send_data('');
    } else {
        $self->send_header($_, $headers->{$_}) foreach keys %$headers;
        $self->send_header('Content-Length', bytes::length($data));
        $self->send_data($data);
    }
}

sub not_modified {
    my ($self, $last_modified, $data) = @_;

	# Each method outputs a header as a side effect, so they cannot be
	# combined in a single test.
	my $t1 = $self->check_last_modified($last_modified);
	my $t2 = $self->check_etag($data);
	return $t1 and $t2;
}

sub check_etag {
    my ($self, $data) = @_;
    my $req_tag = $self->get_header("If-None-Match") || '';
    my $etag = '"'.md5_hex(Encode::encode_utf8($data)).'"';
    $self->send_header('ETag', $etag);
    return $etag eq $req_tag;
}

sub check_last_modified {
	my ($self, $last_modified) = @_;
	return 0 if not $last_modified;

	my $last_modified_str = HTTP::Date::time2str($last_modified);
	$self->send_header('Last-Modified', $last_modified_str);

	my $since = $self->get_header('If-Modified-Since') || return 0;
	$since =~ s/;.+$//; # remove any parameters

	return 1 if $since eq $last_modified_str; # optimization
	my $since_epoch = HTTP::Date::str2time($since) || return 0;
	return 1 if $since_epoch >= $last_modified;

	return 0; # modified
}

=head2 report_error

    $self->report_error($title, $message)

Used when something went horribly wrong inside Bryar. Spits out the
error in as friendly a way as possible to the browser, HTML-escaped
and enclosed by a <p> tag, and to STDERR.

=cut

sub report_error_browser {
    my ($class, $title, $message) = @_;
    $class->send_header("Content-type", "text/html");
    $class->send_header('Status', '500');
    $class->send_data(
        "<!DOCTYPE HTML>\n" .
        "<html><head><title>$title</title></head>\n" .
        "<body><h1>$title</h1>$message</body></html>"
    );
}

sub report_error_html {
    my ($class, $title, $message) = @_;
    $class->report_error_browser($title, $message);
    croak "$title: $message";
}

sub report_error {
    my ($class, $title, $message) = @_;
    my ($texttitle, $textmessage) = ($title, $message);
    $title   =~ s/&/&amp;/g; $title   =~ s/</&lt;/g; $title   =~ s/>/&gt;/g;
    $message =~ s/&/&amp;/g; $message =~ s/</&lt;/g; $message =~ s/>/&gt;/g;
    $message = "<p>$message</p>";
    $class->report_error_browser($title, $message);
    croak "$texttitle: $textmessage";
}

sub init {
    my ($self, $config) = @_;
    my $url = $self->obtain_url();
    if (!$config->baseurl) {
        $config->baseurl($url) if $url =~ s/((bryar|blosxom).cgi).*/$1/;
    }
}
=head1 LICENSE

This module is free software, and may be distributed under the same
terms as Perl itself.

=head1 AUTHOR

Copyright (C) 2003, Simon Cozens C<simon@kasei.com>

some parts Copyright 2007 David Cantrell C<david@cantrell.org.uk>


=head1 SEE ALSO

=cut

1;
