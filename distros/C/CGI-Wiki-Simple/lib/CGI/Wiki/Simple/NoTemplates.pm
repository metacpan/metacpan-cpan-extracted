package CGI::Wiki::Simple::NoTemplates;
use strict;
use base 'CGI::Wiki::Simple';

use vars qw($VERSION);
$VERSION = 0.09;

=head1 NAME

CGI::Wiki::Simple::NoTemplates - A simple wiki without templates

=head1 DESCRIPTION

This is an instant wiki.

=head1 SYNOPSIS

It might be the case that you don't want to use HTML::Template,
and in fact, no templates at all. Then you can simple use the
following example as your wiki, which does not rely on
HTML::Template to prepare the content :

=for example begin

  use strict;
  use CGI::Wiki::Simple::NoTemplates;
  use CGI::Wiki::Store::MySQL; # Change this to match your setup

  my $store = CGI::Wiki::Store::MySQL->new( dbname => "test",
                                            dbuser => "master",
                                            dbpass => "master" );


  my $search = undef;
  my $wiki = CGI::Wiki::Simple::NoTemplates
             ->new( PARAMS => {
                                store => $store,
                              })->run;

=for example end

=cut

sub make_edit_form {
  my ($self,$raw_content,%actions) = @_;

  my ($url_title) = $self->param("url_node_title");
  #my $prefix = $self->query->script_name;

  return "<form method='post' enctype='multipart/form-data' action='".
            $self->node_url(node => $self->param("node_title"), mode => 'commit')."'>"
       . "<textarea name='content' cols='60' rows='20'>"
       . HTML::Entities::encode_entities($raw_content)
       . "</textarea><br />"
       . $self->actions(node=>$url_title,%actions)
       . "</form>";
};

sub make_header {
  my ($self,$version) = @_;
  $self->header_props( -title => $self->param("node_title"), -content_type => "text/html" );

  if ($version) {
    $version = " (v $version)"
  } else {
    $version = "";
  };

  return
    "<html><head><title>" . $self->param("node_title") . "</title>".$self->param("cgi_wiki_simple_style")."</head><body>"
  . "<table width='100%'><tr><td>" . $self->param("cgi_wiki_simple_header") . $self->param("html_node_title")
  . "$version</td></tr></table><hr />";
};

sub make_footer {
  my ($self) = @_;

  my $template = $self->load_tmpl("footer.templ", die_on_bad_params => 0 );
  return $self->param("cgi_wiki_simple_footer"),
};

sub make_checksum {
  my ($self) = @_;
  return "<input type='hidden' name='checksum' value='" . $self->param('checksum') . "' />";
};

sub actions {
  my ($self,%args) = @_;
  #my $node = $self->param("url_node_title");
  my $node = $self->param("node_title");
  my $checksum = $self->make_checksum();

  my $prefix = $self->query->script_name;

  my @result;

  # First, make the "display" link
  if (delete $args{display}) {
    push @result, $self->inside_link( node => $node, mode => 'display', title => 'display' );
    #push @result, "<a href='$prefix/display/$node'>display</a>";
  };

  # and then the "preview" link
  if (delete $args{preview}) {
    push @result, $self->inside_link( node => $node, mode => 'preview', title => 'preview' );
    #push @result, "<a href='$prefix/preview/$node'>edit</a>";
  };

  # and then the "save" link
  if (delete $args{commit}) {
    push @result, "<input type='submit' name='save' value='commit'>$checksum";
  };

  # Further actions will have to go here

  join " | ", @result;
};

sub render_display {
  my ($self) = @_;
  my $node = $self->param("node_title");
  my $html_node_title = $self->param("html_node_title");
  return $self->make_header()
       . $self->param('content')
       . "<hr />"
       . $self->actions( preview => 1, node => $html_node_title )
       . $self->param("cgi_wiki_simple_footer"),
       . "</body></html>";
};

sub render_editform {
  my ($self) = @_;
  return $self->make_header()
       .        $self->param("content")
       .        "<hr />"
       .        $self->make_edit_form($self->param("raw"),commit=>1,display=>1 )
       .        $self->param("cgi_wiki_simple_footer")
       .        "</body></html>"
};

sub render_conflict {
  my ($self) = @_;
  return $self->make_header()
       . $self->param("content")
       . "<hr />"
       . "<p class='errorMessage'>While you were editing this node, somebody else changed it already. Please integrate your changes into the changed node text to resolve the conflict.</p>"
       . "<hr />"
       . "<p>Your content:</p>"
       . "<pre>"
       . HTML::Entities::encode_entities($self->param("submitted_content"))
       . "</pre>"
       . "<p>Current node content:</p>"
       . $self->make_edit_form($self->param("raw"),commit=>1,display=>1,preview=>1 )
       . $self->{cgi_wiki_simple_footer}
       . "</body></html>";
};

1;