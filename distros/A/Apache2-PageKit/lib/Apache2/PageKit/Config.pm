package Apache2::PageKit::Config;

# $Id: Config.pm,v 1.37 2002/12/12 12:05:33 borisz Exp $

use integer;
use strict;
use Apache2::PageKit;
use XML::LibXML;

use vars qw($page_id $ATTR_NAME $cur_config
	$global_attr $user_attr $server_attr $view_attr $section_attr $page_attr $uri_match $mtime_hashref);

sub new {
  my $class = shift;
  my $self = { @_ };
  unless (-d "$self->{'config_dir'}"){
    die "Config directory $self->{'config_dir'} doesn't exist";
  }
  if($self->{'config_dir'} =~ m!/$!){
    warn "Config directory $self->{'config_dir'} has trailing slash";
  }
  $self->{'server'} ||= 'Default';
  bless $self, $class;
  my $reload = $self->get_server_attr('reload') || 'no';
  $self->reload if $reload eq 'yes';
  return $self;
}

sub get_config_dir {
  my $config = shift;
  return $config->{'config_dir'};
}

# checks to see if we have config data and is up to date, otherwise, load/reload
sub reload {
  my ($config) = @_;
  my $config_dir = $config->{config_dir};
  my $mtime = (stat "$config_dir/Config.xml")[9];
  unless(exists $mtime_hashref->{$config_dir} &&
	$mtime < $mtime_hashref->{$config_dir}){
    $config->parse_xml;
    $mtime_hashref->{$config_dir} = $mtime;
  }
}

sub parse_xml {
  my ($config) = @_;

  # set global variable so that XML::Parser's handlers can see it
  $cur_config = $config;

  # delete current init
  my $config_dir  = $config->{config_dir};
  $section_attr->{$config_dir} = {};
  $server_attr->{$config_dir}  = {};
  $global_attr->{$config_dir}  = {};
  $page_attr->{$config_dir}    = {};
  $user_attr->{$config_dir}    = {};
  $view_attr->{$config_dir}    = {};
  $uri_match->{$config_dir}    = {};

  my $parser = XML::LibXML->new;

  # this open close hack is needed. oherwise XML::LibXML sometimes likes to open with the
  # handlers we set in Content.pm! So we use parse_fh instead of parse_file.
  open CFH, "<$config_dir/Config.xml" or die $!;
  binmode CFH;
  my $dom  = $parser->parse_fh(\*CFH);
  close CFH;

  my $root = $dom->getDocumentElement;

  #search for the following nodes ...
  my %subs = (
    GLOBAL             => \&GLOBAL,
    USER               => \&USER,
    'SERVERS/SERVER'   => \&SERVER,
    'VIEWS/VIEW'       => \&VIEW,
    'PAGES/PAGE'       => \&PAGE,
    'SECTIONS/SECTION' => \&SECTION
  );

  for my $tag ( keys %subs ) {
    for my $node ( $root->findnodes("/CONFIG/$tag") ) {
      $subs{$tag}($node);
    }
  }

  # allow login at least on these pages
  for my $page_id ( grep { $_ } ( $config->get_global_attr('default_page') || 'index',
                                  $config->get_global_attr('login_page'),
                                  $config->get_global_attr('verify_page'))) {
    $page_attr->{$config_dir}->{$page_id}->{require_login} = 'no';
  }

  # remove leading or trailing /'s (if any)
  for ( $global_attr->{$config_dir}->{'uri_prefix'} ) {
    next unless $_;
    s!/+$!!;
    s!^/+!!;
  }
}

sub get_global_attr {
  my ($config, $key) = @_;
  return $global_attr->{$config->{config_dir}}->{$key};
}

sub get_user_attr {
  my ($config, $key) = @_;
  return $user_attr->{$config->{config_dir}}->{$key};
}

sub get_server_attr {
  my ($config, $key) = @_;
  return $server_attr->{$config->{config_dir}}->{$config->{server}}->{$key};
}

sub get_view_attr {
  my ($config, $view_id, $key) = @_;
  return $view_attr->{$config->{config_dir}}->{$view_id}->{$key};
}

# required page_id paramater
sub get_page_attr {
  my ($config, $page_id, $key) = @_;
  my $config_dir = $config->{config_dir};

  if ( exists $page_attr->{$config_dir}->{$page_id} 
        && $page_attr->{$config_dir}->{$page_id}->{$key} ) {
    return $page_attr->{$config_dir}->{$page_id}->{$key};
  }

  # here page_id IS the section_id
  while ( $page_id =~ s!^(.*)/+[^/]*$!$1! ) {
    if ( exists $section_attr->{$config_dir}->{$page_id} ) {
      return $section_attr->{$config_dir}->{$page_id}->{$key};
    }
  }

  # test for a global default in the section '/' or ''
  return $section_attr->{$config_dir}->{''}->{$key};
}


# required section_id paramater
sub get_section_attr {
  my ($config, $section_id, $key) = @_;

  return unless exists $section_attr->{$config->{config_dir}}->{$section_id};
  return $section_attr->{$config->{config_dir}}->{$section_id}->{$key};
}

# used to match pages to regular expressions in the uri_match setting
sub uri_match {
  my ($config, $page_id_in) = @_;
  my $page_id_out;
  while(my ($page_id, $reg_exp) = each %{$uri_match->{$config->{config_dir}}}){
    my $match = '$page_id_in =~ /' . $reg_exp . '/';
    if(eval $match){
      $page_id_out = $page_id;
      last;
    }
  }
  return $page_id_out;
}

##################################
# methods for parsing XML file

# called at <GLOBAL> tag in XML file
sub GLOBAL {
  my ($node) = @_;

  for my $attr ( $node->getAttributes ) {
    $global_attr->{$cur_config->{config_dir}}->{$attr->getName} = $attr->getValue;
  }
}

# called at <USER> tag in XML file
sub USER {
  my ($node) = @_;
  for my $attr ( $node->getAttributes ) {
    $user_attr->{$cur_config->{config_dir}}->{$attr->getName} = $attr->getValue;
  }
}

# called at <SERVER> tag in XML file
sub SERVER {
  my ($node) = @_;
  my %attrs = map { ( $_->getName, $_->getValue ) } $node->getAttributes;

  my $config = $cur_config;
  my $server_id = $attrs{id} || 'Default';
  while (my ($key, $value) = each %attrs){
    $server_attr->{$config->{config_dir}}->{$server_id}->{$key} = $value;
  }
}

# called at <VIEW> tag in XML file
sub VIEW {
  my ($node) = @_;
  my %attrs = map { ( $_->getName, $_->getValue ) } $node->getAttributes;

  my $config = $cur_config;
  my $view_id = $attrs{id} || 'Default';
  while (my ($key, $value) = each %attrs){
    $view_attr->{$config->{config_dir}}->{$view_id}->{$key} = $value;
  }
}

# called at beginning <PAGE> tag in XML file
sub PAGE {
  my ($node) = @_;
  my %attrs = map { ( $_->getName, $_->getValue ) } $node->getAttributes;

  my $config = $cur_config;
  my $page_id = $attrs{id} || die "The attribute id is prescribed for the tag PAGE";

  # warn if use_sessions eq 'no' and page_session eq 'yes' thats illegal.
  # we ignore use_sessions.
  if ( $attrs{page_session} && $attrs{page_session} eq 'yes' &&
       $attrs{use_sessions} && $attrs{use_sessions} eq 'no' ) {
       delete $attrs{use_session};
       warn "Page attribute use_sessions ignored";
  }

  # remove leading /
  $page_id =~ s!^/+!!;

  while (my ($key, $value) = each %attrs){
    next if $key eq 'id';
    if($key eq 'uri_match'){
      $uri_match->{$config->{config_dir}}->{$page_id} = $value;
    } else {
      $page_attr->{$config->{config_dir}}->{$page_id}->{$key} = $value;
    }
  }
}

# called at beginning <SECTION> tag in XML file
sub SECTION {
  my ($node) = @_;
  my %attrs = map { ( $_->getName, $_->getValue ) } $node->getAttributes;

  my $config = $cur_config;
  my $section_id = $attrs{id} || die "The attribute id is prescribed for the tag SECTION";

  # remove leading /
  $section_id =~ s!^/+!!;
  # remove trailing /
  $section_id =~ s!/+$!!;

  while (my ($key, $value) = each %attrs){
    next if $key eq 'id';
    $section_attr->{$config->{config_dir}}->{$section_id}->{$key} = $value;
  }
}

1;
