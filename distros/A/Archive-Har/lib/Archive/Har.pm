package Archive::Har;

use warnings;
use strict;
use English qw(-no_match_vars);
use Archive::Har::Creator();
use Archive::Har::Browser();
use Archive::Har::Page();
use Archive::Har::Entry();
use XML::LibXML();
use IO::Compress::Gzip();
use IO::Uncompress::Gunzip();
use JSON();
use overload '""' => 'string';

our $VERSION = '0.21';

sub new {
    my ( $class, $params ) = @_;
    my $self = {};
    bless $self, $class;
    $self->_init();
    return $self;
}

sub _init {
    my ($self) = @_;
    foreach my $key ( keys %{$self} ) {
        delete $self->{$key};
    }
    $self->{log} = {};
    return;
}

sub gzip {
    my ( $self, $gzipped ) = @_;
    my $uncompressed = $self->string();
    my $old;
    IO::Compress::Gzip::gzip( \$uncompressed, \$old,
        -Level => IO::Compress::Gzip::Z_BEST_COMPRESSION() )
      or
      Carp::croak("Failed to gzip HAR archive:$IO::Compress::Gzip::GzipError");
    if ( defined $gzipped ) {
        my $string;
        IO::Uncompress::Gunzip::gunzip( \$gzipped, \$string )
          or Carp::croak('Failed to gunzip HAR archive');
        $self->string($string);
    }
    return $old;
}

sub hashref {
    my ( $self, $ref ) = @_;
    my $old = JSON->new()->utf8()->decode( $self->string() );
    if ( ( @_ > 1 ) && ( defined $ref ) ) {
        $self->_init();
        $self->version( $ref->{log}->{version} );
        $self->creator( Archive::Har::Creator->new( $ref->{log}->{creator} ) );
        if ( defined $ref->{log}->{browser} ) {
            $self->browser(
                Archive::Har::Browser->new( $ref->{log}->{browser} ) );
        }
        if ( defined $ref->{log}->{pages} ) {
            $self->pages( $ref->{log}->{pages} );
        }
        $self->entries( $ref->{log}->{entries} );
        $self->comment( $ref->{log}->{comment} );
    }
    return $old;
}

sub string {
    my ( $self, $string ) = @_;
    if ( defined $string ) {
        my $utf8_regex  = qr/\xef\xbb\xbf/smx;
        my $utf16_regex = qr/(?:\xfe\xff|\xff\xfe)/smx;
        my $utf32_regex = qr/(?:\x00\x00\xfe\xff|\xff\xfe\x00\x00)/smx;
        $string =~ s/^(?:$utf8_regex|$utf16_regex|$utf32_regex)//smxg;
    }
    my $json = JSON->new();
    $json = $json->utf8();
    $json = $json->allow_blessed(1);
    $json = $json->convert_blessed(1);
    $json = $json->pretty();
    $json = $json->canonical(1);
    my $old = $json->encode($self);

    if ( ( @_ > 1 ) && ( defined $string ) ) {
        my $ref = JSON->new()->utf8()->decode($string);
        $self->hashref($ref);
    }
    return $old;
}

sub _xml_creator {
    my ( $self, $ie_log ) = @_;
    foreach my $ie_creator ( $ie_log->getChildrenByTagName('creator') ) {
        $self->creator( Archive::Har::Creator->new() );
        foreach my $ie_name ( $ie_creator->getChildrenByTagName('name') ) {
            $self->creator()->name( $ie_name->findvalue('text()') );
        }
        foreach my $ie_value ( $ie_creator->getChildrenByTagName('version') ) {
            $self->creator()->version( $ie_value->findvalue('text()') );
        }
    }
    return;
}

sub _xml_browser {
    my ( $self, $ie_log ) = @_;
    foreach my $ie_browser ( $ie_log->getChildrenByTagName('browser') ) {
        $self->browser( Archive::Har::Creator->new() );
        foreach my $ie_name ( $ie_browser->getChildrenByTagName('name') ) {
            $self->browser()->name( $ie_name->findvalue('text()') );
        }
        foreach my $ie_value ( $ie_browser->getChildrenByTagName('version') ) {
            $self->browser()->version( $ie_value->findvalue('text()') );
        }
    }
    return;
}

sub _xml_pages {
    my ( $self, $ie_log ) = @_;
    foreach my $ie_pages ( $ie_log->getChildrenByTagName('pages') ) {
        my @pages;
        foreach my $ie_page ( $ie_pages->getChildrenByTagName('page') ) {
            my $page = Archive::Har::Page->new();
            foreach my $ie_id ( $ie_page->getChildrenByTagName('id') ) {
                $page->id( $ie_id->findvalue('text()') );
            }
            foreach my $ie_title ( $ie_page->getChildrenByTagName('title') ) {
                $page->title( $ie_title->findvalue('text()') );
            }
            foreach my $ie_started (
                $ie_page->getChildrenByTagName('startedDateTime') )
            {
                $page->started_date_time( $ie_started->findvalue('text()') );
            }
            my $page_timings = Archive::Har::Page::PageTimings->new();
            foreach
              my $ie_timings ( $ie_page->getChildrenByTagName('pageTimings') )
            {
                foreach my $ie_content (
                    $ie_timings->getChildrenByTagName('onContentLoad') )
                {
                    $page_timings->on_content_load(
                        $ie_content->findvalue('text()') );
                }
                foreach
                  my $ie_load ( $ie_timings->getChildrenByTagName('onLoad') )
                {
                    $page_timings->on_load( $ie_load->findvalue('text()') );
                }
                $page->page_timings($page_timings);
            }
            push @pages, $page;
        }
        $self->pages( \@pages );
    }
    return;
}

sub _xml_cookies {
    my ( $self, $ie_object, $object ) = @_;
    foreach my $ie_cookies ( $ie_object->getChildrenByTagName('cookies') ) {
        my @cookies;
        foreach my $ie_cookie ( $ie_cookies->getChildrenByTagName('cookie') ) {
            my $cookie = Archive::Har::Entry::Cookie->new();
            foreach my $ie_name ( $ie_cookie->getChildrenByTagName('name') ) {
                $cookie->name( $ie_name->findvalue('text()') );
            }
            foreach my $ie_value ( $ie_cookie->getChildrenByTagName('value') ) {
                $cookie->value( $ie_value->findvalue('text()') );
            }
            push @cookies, $cookie;
        }
        $object->cookies( \@cookies );
    }
    return;
}

sub _xml_headers {
    my ( $self, $ie_object, $object ) = @_;
    foreach my $ie_headers ( $ie_object->getChildrenByTagName('headers') ) {
        my @headers;
        foreach my $ie_header ( $ie_headers->getChildrenByTagName('header') ) {
            my $header = Archive::Har::Entry::Header->new();
            foreach my $ie_name ( $ie_header->getChildrenByTagName('name') ) {
                $header->name( $ie_name->findvalue('text()') );
            }
            foreach my $ie_value ( $ie_header->getChildrenByTagName('value') ) {
                $header->value( $ie_value->findvalue('text()') );
            }
            push @headers, $header;
        }
        $object->headers( \@headers );
    }
    return;
}

sub _xml_request {
    my ( $self, $ie_entry, $entry ) = @_;
    foreach my $ie_request ( $ie_entry->getChildrenByTagName('request') ) {
        my $request = $entry->request();
        foreach my $ie_method ( $ie_request->getChildrenByTagName('method') ) {
            $request->method( $ie_method->findvalue('text()') );
        }
        foreach my $ie_url ( $ie_request->getChildrenByTagName('url') ) {
            $request->url( $ie_url->findvalue('text()') );
        }
        foreach
          my $ie_version ( $ie_request->getChildrenByTagName('httpVersion') )
        {
            $request->http_version( $ie_version->findvalue('text()') );
        }
        $self->_xml_cookies( $ie_request, $request );
        $self->_xml_headers( $ie_request, $request );
        foreach my $ie_query_string (
            $ie_request->getChildrenByTagName('queryString') )
        {
            my @query_strings;
            foreach
              my $ie_param ( $ie_query_string->getChildrenByTagName('param') )
            {
                my $query_string =
                  Archive::Har::Entry::Request::QueryString->new();
                foreach my $ie_name ( $ie_param->getChildrenByTagName('name') )
                {
                    $query_string->name( $ie_name->findvalue('text()') );
                }
                foreach
                  my $ie_value ( $ie_param->getChildrenByTagName('value') )
                {
                    $query_string->value( $ie_value->findvalue('text()') );
                }
                push @query_strings, $query_string;
            }
            $request->query_string( \@query_strings );
        }
        foreach
          my $ie_post_data ( $ie_request->getChildrenByTagName('postData') )
        {
            my $post_data = Archive::Har::Entry::Request::PostData->new();
            foreach my $ie_mime_type (
                $ie_post_data->getChildrenByTagName('mimeType') )
            {
                $post_data->mime_type( $ie_mime_type->findvalue('text()') );
            }
            foreach my $ie_text ( $ie_post_data->getChildrenByTagName('text') )
            {
                $post_data->text( $ie_text->findvalue('text()') );
            }
            $request->post_data($post_data);
        }
        foreach my $ie_headers_size (
            $ie_request->getChildrenByTagName('headersSize') )
        {
            $request->headers_size( $ie_headers_size->findvalue('text()') );
        }
        foreach
          my $ie_body_size ( $ie_request->getChildrenByTagName('bodySize') )
        {
            $request->body_size( $ie_body_size->findvalue('text()') );
        }
        $entry->request($request);
    }
    return;
}

sub _xml_response {
    my ( $self, $ie_entry, $entry ) = @_;
    foreach my $ie_response ( $ie_entry->getChildrenByTagName('response') ) {
        my $response = $entry->response();
        foreach my $ie_status ( $ie_response->getChildrenByTagName('status') ) {
            $response->status( $ie_status->findvalue('text()') );
        }
        foreach my $ie_status_text (
            $ie_response->getChildrenByTagName('statusText') )
        {
            $response->status_text( $ie_status_text->findvalue('text()') );
        }
        foreach
          my $ie_version ( $ie_response->getChildrenByTagName('httpVersion') )
        {
            $response->http_version( $ie_version->findvalue('text()') );
        }
        $self->_xml_cookies( $ie_response, $response );
        $self->_xml_headers( $ie_response, $response );
        foreach my $ie_content ( $ie_response->getChildrenByTagName('content') )
        {
            my $content = Archive::Har::Entry::Response::Content->new();
            foreach
              my $ie_mime_type ( $ie_content->getChildrenByTagName('mimeType') )
            {
                $content->mime_type( $ie_mime_type->findvalue('text()') );
            }
            foreach my $ie_text ( $ie_content->getChildrenByTagName('text') ) {
                $content->text( $ie_text->findvalue('text()') );
            }
            foreach my $ie_size ( $ie_content->getChildrenByTagName('size') ) {
                $content->size( $ie_size->findvalue('text()') );
            }
            $response->content($content);
        }
        foreach my $ie_redirect_url (
            $ie_response->getChildrenByTagName('redirectionURL') )
        {
            $response->redirect_url( $ie_redirect_url->findvalue('text()') );
        }
        foreach my $ie_headers_size (
            $ie_response->getChildrenByTagName('headersSize') )
        {
            $response->headers_size( $ie_headers_size->findvalue('text()') );
        }
        foreach
          my $ie_body_size ( $ie_response->getChildrenByTagName('bodySize') )
        {
            $response->body_size( $ie_body_size->findvalue('text()') );
        }
        $entry->response($response);
    }
    return;
}

sub _xml_entries {
    my ( $self, $ie_log ) = @_;
    foreach my $ie_entries ( $ie_log->getChildrenByTagName('entries') ) {
        my @entries;
        foreach my $ie_entry ( $ie_entries->getChildrenByTagName('entry') ) {
            my $entry = Archive::Har::Entry->new();
            foreach
              my $ie_pageref ( $ie_entry->getChildrenByTagName('pageref') )
            {
                $entry->pageref( $ie_pageref->findvalue('text()') );
            }
            foreach my $ie_started (
                $ie_entry->getChildrenByTagName('startedDateTime') )
            {
                $entry->started_date_time( $ie_started->findvalue('text()') );
            }
            foreach
              my $ie_timings ( $ie_entry->getChildrenByTagName('timings') )
            {
                my $timings = Archive::Har::Entry::Timings->new();
                foreach
                  my $ie_send ( $ie_timings->getChildrenByTagName('send') )
                {
                    $timings->send( $ie_send->findvalue('text()') );
                }
                foreach
                  my $ie_wait ( $ie_timings->getChildrenByTagName('wait') )
                {
                    $timings->wait( $ie_wait->findvalue('text()') );
                }
                foreach my $ie_receive (
                    $ie_timings->getChildrenByTagName('receive') )
                {
                    $timings->receive( $ie_receive->findvalue('text()') );
                }
                $entry->timings($timings);
            }
            $self->_xml_request( $ie_entry, $entry );
            $self->_xml_response( $ie_entry, $entry );
            push @entries, $entry;
        }
        $self->entries( \@entries );
    }
    return;
}

sub xml {
    my ( $self, $xml ) = @_;
    my $parser = XML::LibXML->new();
    my $ie_dom = $parser->parse_string($xml);
    my $ie_log = $ie_dom->documentElement();
    $self->_init();
    foreach my $ie_version ( $ie_log->getChildrenByTagName('version') ) {
        $self->version( $ie_version->findvalue('text()') );
    }
    $self->_xml_creator($ie_log);
    $self->_xml_browser($ie_log);
    $self->_xml_pages($ie_log);
    $self->_xml_entries($ie_log);
    return;
}

sub version {
    my ( $self, $new ) = @_;
    my $old = $self->{log}->{version};
    if ( @_ > 1 ) {
        $self->{log}->{version} = $new;
    }
    if ( defined $old ) {
        return $old;
    }
    else {
        return '1.1';
    }
}

sub creator {
    my ( $self, $new ) = @_;
    my $old = $self->{log}->{creator};
    if ( @_ > 1 ) {
        $self->{log}->{creator} = $new;
    }
    return $old;
}

sub browser {
    my ( $self, $new ) = @_;
    my $old = $self->{log}->{browser};
    if ( @_ > 1 ) {
        $self->{log}->{browser} = $new;
    }
    return $old;
}

sub pages {
    my ( $self, $new ) = @_;
    my $old = $self->{log}->{pages};
    if ( @_ > 1 ) {
        if ( defined $new ) {
            $self->{log}->{pages} = [];
            my $page_count = 0;
            foreach my $page ( @{$new} ) {
                if ( !defined $page->{id} ) {
                    $page->{id} = 'page_' . $page_count;
                }
                push @{ $self->{log}->{pages} }, Archive::Har::Page->new($page);
                $page_count += 1;
            }
        }
    }
    if ( defined $old ) {
        return @{$old};
    }
    else {
        return ();
    }
}

sub entries {
    my ( $self, $entries ) = @_;
    my $old = $self->{log}->{entries} || [];
    if ( @_ > 1 ) {
        $self->{log}->{entries} = [];
        foreach my $entry ( @{$entries} ) {
            push @{ $self->{log}->{entries} }, Archive::Har::Entry->new($entry);
        }
    }
    return @{$old};
}

sub comment {
    my ( $self, $comment ) = @_;
    my $old = $self->{log}->{comment};
    if ( @_ > 1 ) {
        $self->{log}->{comment} = $comment;
    }
    return $old;
}

sub TO_JSON {
    my ($self) = @_;
    my $json = {};
    $json->{version} = $self->version();
    $json->{creator} = $self->creator();
    if ( defined $self->browser() ) {
        $json->{browser} = $self->browser();
    }
    if ( defined $self->pages() ) {
        $json->{pages} = [ $self->pages() ];
    }
    $json->{entries} = [ $self->entries() ];
    if ( defined $self->comment() ) {
        $json->{comment} = $self->comment();
    }
    return { log => $json };
}

1;    # End of Archive::Har
__END__

=head1 NAME

Archive::Har - Provides an interface to HTTP Archive (HAR) files

=head1 VERSION

Version '0.21'

=for stopwords xml gzip stringified HAR gzipped gzipping JSON hashref gunzipping

=head1 SYNOPSIS

    use Archive::Har();

    my $http_archive_string = '"log": { "version": "1.1", .... ';
    my $har = Archive::Har->new();
    $har->string($http_archive_string);
    print $har->creator()->name() . ' version ' . $har->creator()->version();
    $har->creator()->name("new name"); # update har
    print $har->browser()->name() . ' version ' . $har->browser()->version();
    foreach my $page = $har->pages()) {
        $page->comment("Something interesting here");
        print "Page Title: " . $page->title() . "\n";

    }
    print $har; # print har in stringified pretty form
    ...

=head1 DESCRIPTION
 
This Module is intended to provide an interface to create/read/update
entire HTTP Archive (HAR) files.

=head1 SUBROUTINES/METHODS

=head2 new

Archive::Har->new() will return a new HAR object, ready to process HTTP archives

=head2 string

$har->string() accepts a stringified version of an L<HTTP archive|http://www.softwareishard.com/blog/har-12-spec/> and parses it.  It returns the previous state of the archive in stringified form

=head2 hashref

$har->hashref() accepts a hashref of the L<HTTP archive|http://www.softwareishard.com/blog/har-12-spec/> and parses it.  It returns a hashref of the previous state of the archive

=head2 gzip

$har->gzip() accepts a gzipped version of an L<HTTP archive|http://www.softwareishard.com/blog/har-12-spec/> and parses it. It returns a gzipped version of the previous state of the archive

=head2 xml

$har->xml() accepts a stringified version of Internet Explorer's Network Inspector XML export and parses it.  There is no return value

=head2 version

$har->version() will return the version of the HTTP Archive ('1.1' by default)

=head2 creator

$har->creator() will return the L<creator|Archive::Har::Creator> object for the HTTP Archive

=head2 browser

$har->browser() will return the L<browser|Archive::Har::Browser> object for the HTTP Archive

=head2 pages

$har->pages() will return the list of L<page|Archive::Har::Page> objects for the HTTP Archive

=head2 entries

$har->entries() will return the list of L<entry|Archive::Har::Entry> objects for the HTTP Archive

=head2 comment

$har->comment() will return the comment for the HTTP Archive

=head1 DIAGNOSTICS

=over

=item C<< Failed to gzip HAR archive >>

An error occurred while gzipping.

=item C<< Failed to gunzip HAR archive >>

An error occurred while gunzipping.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Archive::Har requires no configuration files or environment variables.  

=head1 DEPENDENCIES

Archive::Har requires the following non-core Perl modules

=over

=item *
L<JSON|JSON>

=item *
L<IO::Compress::Gzip|IO::Compress:Gzip>

=item *
L<IO::Uncompress::Gunzip|IO::Uncompress:Gunzip>

=item *
L<XML::LibXML|XML::LibXML>

=back

=head1 INCOMPATIBILITIES

None reported

=head1 SEE ALSO

L<HTTP Archive 1.2 Specification|http://www.softwareishard.com/blog/har-12-spec/>

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-archive-har at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Archive-Har>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
