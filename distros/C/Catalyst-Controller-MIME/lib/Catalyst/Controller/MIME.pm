package Catalyst::Controller::MIME;
use strict;
use warnings;

our $VERSION = 0.02;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

use Catalyst::Utils;
use HTML::TokeParser::Simple;
use HTML::Entities;
use Data::Dumper::Concise 'Dumper';

# ---
# Supply code to obtain the MIME object via either coderef attr or
# extending get_mime() method
has 'get_mime_coderef', is => 'ro', isa => 'CodeRef', lazy => 1, default => sub {
  sub { (shift)->get_mime(@_) }
};
sub get_mime { ... }
# ---

has 'expose_methods', is => 'ro', isa => 'Bool', default => 0;

# Render a MIME Object
sub content :Local {
  my ($self, $c, $id, @path) = @_;
  my $MIME = $self->_resolve_path($c, $id, @path);
  return $self->_direct_render($c,$MIME);
}

# View a MIME Object
sub view :Local {
  my ($self, $c, $id, @path) = @_;
  my $MIME = $self->_resolve_path($c, $id, @path);
  return $self->_view_mime($c, $MIME, $id, @path);
}

# View a MIME Object as RAW Text
sub raw_text :Local {
  my ($self, $c, $id, @path) = @_;
  my $MIME = $self->_resolve_path($c, $id, @path);
  
  $c->response->header( 'Content-Type' => 'text/plain' );
  $c->response->body( $MIME->as_string );
  return $c->detach;
}

sub _path_to_content_url {
  my ($self, $c, @path) = @_;
  return '/' . join('/',$self->action_namespace($c),'content',@path);
}

sub _path_to_cid_path {
  my ($self, $c, @path) = @_;
  return '/' . join('/',$self->action_namespace($c),'content',@path,'cid');
}


# DEBUG action: Call a method on the Email::MIME object
sub method :Local {
  my ($self, $c, $method, $id, @path) = @_;
  
  $c->res->header( 'Content-Type' => 'text/plain' );
  
  unless( $self->expose_methods ) {
    $c->res->body('MIME Object Methods Disabled (see "expose_methods")');
    return $c->detach;
  }
  
  my $MIME = $self->_resolve_path($c, $id, @path);
  
  unless( $MIME->can($method) ) {
    $c->res->body("No such method '$method'");
    return $c->detach;
  }
  
  my @ret = $MIME->$method;
  if(scalar @ret > 1) {
     $c->res->body( Dumper(\@ret) );
  }
  else {
    if(ref $ret[0]) {
      $c->res->body( Dumper($ret[0]) );
    }
    else {
      $c->res->body( $ret[0] );
    }
  }
  
  return $c->detach;
}



sub _resolve_path {
  my ($self, $c, $MIME, $next, @path) = @_;
  
  # $MIME is either a MIME object or the key/id of a MIME object:
  unless (blessed $MIME) {
    $MIME = $self->get_mime_coderef->($self,$c,$MIME)
      # Idealy the derived class will throw its own exception
      or Catalyst::Exception->throw("Content '$MIME' not found");
    
    Catalyst::Exception->throw(
      "get_mime/get_mime_coderef did not return an Email::MIME object"
    ) unless (blessed $MIME && $MIME->isa('Email::MIME'));
  }
  
  return $MIME unless (defined $next);
  $next = lc($next);
  
  my $SubPart;
  
  # Resolve by part index tree or cid
  if($next eq 'cid' || $next eq 'content-id') {
    my $cid = shift @path;
    $SubPart = $self->_resolve_cid($MIME,$cid);
  }
  else {
    # Assume 'part'
    $next = shift @path if ($next eq 'part');

    my $idx = $next;
    Catalyst::Exception->throw("Bad MIME Part Index '$idx' - must be an integer")
      unless ($idx =~ /^\d+$/);
      
    $SubPart = ($MIME->parts)[$idx]
      or Catalyst::Exception->throw("MIME Part not found at index '$idx'");
  }
  
  # Continue recursively:
  return $self->_resolve_path($c,$SubPart,@path);
}


sub _resolve_cid {
  my ($self, $MIME, $cid) = @_;
  
  my $FoundPart;
	
	$MIME->walk_parts(sub {
		my $Part = shift;
		return if ($FoundPart);
		$FoundPart = $Part if ( $Part->header('Content-ID') and (
			$cid eq $Part->header('Content-ID') or 
			'<' . $cid . '>' eq $Part->header('Content-ID')
		));
	});
  
  Catalyst::Exception->throw('Content-ID ' . $cid . ' not found.')
    unless ($FoundPart);
    
  return $FoundPart;
}

# Renders the MIME part directly, setting its headers/body as the response
sub _direct_render {
  my ($self, $c, $MIME) = @_;
  
  $self->_set_mime_headers($c,$MIME);
  
  $c->res->body( $MIME->body );
  return $c->detach;
}


sub _render_part {
  my ($self, $c, $MIME, @path) = @_;
  
  $self->_set_mime_headers($c,$MIME);
  
  my $body = $MIME->body;
  my $cid_path = $self->_path_to_cid_path($c,@path);
  $self->_convert_cids(\$body,$cid_path) 
    if ($MIME->content_type =~ /^text/);
  
  $c->res->body( $body );
  return $c->detach;
}


sub _set_mime_headers {
  my ($self, $c, $MIME,$exclude) = @_;
  
  # TODO: find all the headers that will cause issues like the date/cookie
  my @exclude_headers = qw(Date);
  push @exclude_headers, @$exclude if (ref($exclude) eq 'ARRAY');
  my %excl = map {lc($_)=>1} @exclude_headers;
  my @header_names = grep { !$excl{lc($_)} } $MIME->header_names;
  $c->res->header( $_ => $MIME->header($_) ) for (@header_names);

}

sub _view_part {
  my ($self, $c, $MIME, @path) = @_;
  
  my $ViewPart = $self->_find_best_view_part($MIME);
  
  # Fall back to raw rendering unless the found View Part is text:
  return $self->_render_part($c, $MIME, @path) unless (
    $ViewPart->content_type =~ /^text/
  );

  #$self->_set_mime_headers($c,$ViewPart,
  #  # must exclude these headers since we're decoding the message ourselves:
  #  # TODO: we probably don't need to be setting any headers
  #  ['Content-Type','Content-Transfer-Encoding']
  #);
	
  #my $body = $ViewPart->content_type =~ /^text\/html/ ?
  #  $self->_get_rich_html_body($ViewPart,$cid_path) :
  #    $self->_render_html_with_headers($ViewPart);
      
  my $body = $self->_get_rich_html_body($c,$MIME,$ViewPart,@path);
	
	$c->res->body( $body );
  return $c->detach;
}

# recurses into a multipart message and finds the best part to
# use to display the content
sub _find_best_view_part {
  my ($self, $MIME) = @_;
  # This only applies to multipart:
  return $MIME unless ($MIME->content_type =~ /^multipart/);
  
  my $CurBest;
  my @parts = $MIME->parts;
  for my $Part (@parts) {
    # Recurse if the first part is another multipart
    return $self->_find_best_view_part($Part) if (
      ! $CurBest && $Part->content_type =~ /^multipart/
    );
    
    # Any text part:
    $CurBest = $Part if (
      ! $CurBest && 
      $Part->content_type =~ /^text/
    );
    
    # text/html takes priority over text/plain:
    $CurBest = $Part if (
      ! ($CurBest->content_type =~ /^text\/html/) &&
      $Part->content_type =~ /^text\/html/
    );
  }
  return $CurBest ? $CurBest : $MIME;
}


sub _convert_cids {
  my ($self, $htmlref, $cid_path) = @_;

	my $parser = HTML::TokeParser::Simple->new($htmlref);
	
	my $substitutions = {};
	
  # currently only doing img and a tags:
  
	while (my $tag = $parser->get_tag) {
	
		my $attr;
		if($tag->is_tag('img')) {
			$attr = 'src';
		}
		elsif($tag->is_tag('a')) {
			$attr = 'href';
		}
		else {
			next;
		}
		
		my $url = $tag->get_attr($attr) or next;
    my ($prefix,$cid) = split(/\:/,$url,2);
		next unless (lc($prefix) eq 'cid' && $cid);
		
    # Replace the CID URL with a url back to this controller:
		my $find = $tag->as_is;
		$tag->set_attr($attr,"$cid_path/$cid");
		$substitutions->{$find} = $tag->as_is;
	}
	
	foreach my $find (keys %$substitutions) {
		my $replace = $substitutions->{$find};
		$$htmlref =~ s/\Q$find\E/$replace/gm;
	}
}



###### TODO: This needs to be moved into a View ######
sub _view_mime {
  my ($self, $c, $MIME, @path) = @_;
  
  return $self->_view_image($c, $MIME, @path)
    if ( $MIME->content_type =~ /^image/ );
  
  
  # Old view:
  
  return $self->_view_part($c, $MIME, @path);
}


sub _view_image {
  my ($self, $c, $MIME, @path) = @_;
  my $src = $self->_path_to_content_url($c,@path);
  
  return $self->_render_html_with_headers($c,$MIME,
    "\n\n" . '<img src="' . $src . '">' . "\n\n"
  );
}


sub _render_html_with_headers {
  my ($self, $c, $MIME, $body) = @_;
  
  my @inc_headers = qw(From Date To Subject);
  @inc_headers = $MIME->header_names;
  
  my $p = '<p style="margin-top:3px;margin-bottom:3px;">';
	my $html = '<div style="font-size:90%;">';
  
	$html .= $p . '<b>' . $_ . ':&nbsp;</b>' . 
    encode_entities(join(',',$MIME->header($_))) . '</p>' . "\n" for (@inc_headers);
	
  $html .= '</div>';
	$html .= '<hr><div style="padding-top:15px;"></div>';
	
	$html .= $body;
	
	$c->res->body( $html );
  return $c->detach;
}


sub _get_rich_html_body {
  my ($self, $c, $MIME, $ViewPart, @path) = @_;
  
  my $body_str = $ViewPart->body_str;
  if ($ViewPart->content_type =~ /^text\/html/) {
    my $cid_path = $self->_path_to_cid_path($c,@path);
    $self->_convert_cids(\$body_str,$cid_path);
  }
  else {
    # Plain text:
    $body_str =  "\n\n" . '<pre style="white-space: pre-wrap; word-wrap: break-word;">' .
      $body_str . 
    '</pre>' . "\n\n";
  }
  
  # E-Mail headers:
  my @inc_headers = qw(From Date To Subject);
  
  my @exist_headers = $MIME->header_names;
  my %exist_hd = map {$_=>1} @exist_headers;
  @inc_headers = grep { $exist_hd{$_} } @inc_headers; 
  
  # Unless there is more than 1 existing header from our list, 
  # just use all the headers:
  @inc_headers = @exist_headers unless (scalar(@inc_headers) > 1);
  
  my $p = '<p style="margin-top:3px;margin-bottom:3px;">';
	my $html = '<div style="font-size:90%;">';
  
	$html .= $p . '<b>' . $_ . ':&nbsp;</b>' . 
    encode_entities(join(',',$MIME->header($_))) . '</p>' . "\n" for (@inc_headers);
	
  my @links = $self->_get_attachments_links($c,$MIME,@path);
  $html .= $p . 
    '<b><i><span style="color:darkgreen;">Attachments:&nbsp;</span></i></b>' . 
    join(',&nbsp',@links) . '</p>' . "\n" if (scalar(@links) > 0);
      
  $html .= '</div>' . "\n";
	$html .= '<hr><div style="padding-top:15px;"></div>' . "\n\n";
	
  return $html . $body_str;
}


# Gets a list of links (<a> tags) pointing to subparts (of multipart/mixed
# MIME objects) with a "name" or "filename" property within the content_type
# This I *think* is what E-Mail clients do when they add attachments
sub _get_attachments_links {
  my ($self, $c, $MIME, @path) = @_;
  
  # Displayed attachments in E-Mails are parts in multipart/mixed:
  return () unless ($MIME->content_type =~ /multipart\/mixed/);
  
  my @links = ();
  my $count = 0;
  foreach my $Part ($MIME->parts) {
    my $idx = $count++;
    my @sections = split(/\s*\;\s*/,$Part->content_type);
    my %prop = ();
    foreach my $sect (@sections) {
      my ($k,$v) = split(/\s*\=\s*/,$sect,2);
      next unless ($v);
      $v =~ s/^\"//;
      $v =~ s/\"$//;
      $prop{lc($k)} = $v;
    }
    
    my $filename = ($prop{name} || $prop{filename}) or next;
    push @links, '<a target="_blank" href="' . 
      $self->_path_to_content_url($c,@path,$idx) . '">' .
        encode_entities($filename) . '</a>';
  }

  return @links;
}

1;

__END__

=pod

=head1 NAME

Catalyst::Controller::MIME - Multipart MIME viewer via Catalyst

=head1 SYNOPSIS

  package MyApp::Controller::MimeView;
  use Moose;
  use namespace::autoclean;
  use Email::MIME;
  
  BEGIN {extends 'Catalyst::Controller::MIME'; }
  
  sub get_mime {
    my ($self, $c, $id) = @_;
    
    my $mime_content = $c->model('SomeModel')->get_content_by_id($id)
      or return undef;
    
    return Email::MIME->new($mime_content);
  }
  
  1;

Then, access URLs like the following to view MIME objects:

  # View MIME object with id '1234'
  http://localhost:3000/mimeview/view/1234
  
  # View part 1 of a MIME object with id '1234'
  http://localhost:3000/mimeview/view/1234/1
  
  # View part 3 of part 1 of a MIME object with id '1234'
  http://localhost:3000/mimeview/view/1234/1/3
  
  # Download MIME object with id '1234'
  http://localhost:3000/mimeview/content/1234


=head1 DESCRIPTION

Quick and dirty Catalyst Controller interface for viewing MIME objects, including multipart MIME objects with rich content and
embedded images, such as those typically generated by rich-text E-Mails and MHTML files. This module might be
used as an E-Mail viewer, but can also be used to view any MIME content, including *.mht files, image attachments,
and so on.

=head1 METHODS

=head2 get_mime

Method to be defined in consuming class used to resolve an id into an Email::MIME object. Must return an
Email::MIME object. See Synopsis above for example.

=head1 CONFIG PARAMS

=head2 get_mime_coderef

Alternative way to supply the C<get_mime()> method as a CodeRef that can be passed as a config param. If
defined, the real get_mime method will be ignored.

=head2 expose_methods

Bool option for debug purposes. Allows calling methods on the Email::MIME object directly and dumping the
output. For example:

  # Dump the output of $MIME->debug_structure() for id '1234'
  http://localhost:3000/mimeview/method/debug_structure/1234/

Defaults to false (0).

=head1 SEE ALSO

=over

=item L<Email::MIME>

=back

=head1 TODO

  * Define a View API and write proper View classes
  * Document the controller actions
  * Write tests

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


1;