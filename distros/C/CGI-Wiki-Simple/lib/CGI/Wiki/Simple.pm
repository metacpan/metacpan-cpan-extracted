package CGI::Wiki::Simple;

use strict;

use URI::Escape;
use CGI::Wiki;
use CGI::Wiki::Simple::NoTemplates;

use base qw[ CGI::Application ];
use Class::Delegation
    send => ['retrieve_node', 'retrieve_node_and_checksum', 'verify_checksum',
             'list_all_nodes', 'list_recent_changes', 'node_exists', 'write_node', 'delete_node',
             'search_nodes', 'supports_phrase_searches',
             'format' ],
    to   => sub { $_[0]->wiki },
    ;

use vars qw( $VERSION %magic_node );

$VERSION = '0.12';

=head1 NAME

CGI::Wiki::Simple - A simple wiki application using CGI::Application.

=head1 DESCRIPTION

This is an instant wiki.

=head1 SYNOPSIS

=for example begin

  use strict;
  use CGI::Wiki::Simple;
  use CGI::Wiki::Simple::Setup; # currently only for SQLite

  # Change this to match your setup
  use CGI::Wiki::Store::SQLite;
  CGI::Wiki::Simple::Setup::setup_if_needed( dbname => "mywiki.db",
                                             dbtype => 'sqlite' );
  my $store = CGI::Wiki::Store::SQLite->new( dbname => "mywiki.db" );

  my $search = undef;
  my $wiki = CGI::Wiki::Simple->new( TMPL_PATH => "templates",
                                     PARAMS => {
                                        store => $store,
                                     })->run;

=for example end

=head1 EXAMPLE WITHOUT HTML::Template

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

=head1 METHODS

=over 4

=item B<new>

C<new> passes most of the parameters on to the constructor of L<CGI::Wiki>.
If HTML::Template is not available, you'll automagically get a non-templated
wiki in the subclass CGI::Wiki::Simple::NoTemplates. Note that CGI::Application
lists HTML::Template as one of its prerequisites but also works without it.

=cut

{
  my $have_html_template;
  BEGIN { eval { require HTML::Template }; $have_html_template = ($@ eq '') };

  sub new {
    my ($class) = shift;
    my $self = $class->SUPER::new(@_);

    bless $self, 'CGI::Wiki::Simple::NoTemplates'
      unless ($have_html_template);

    $self;
  };
};

=item B<setup>

The C<setup> method is called by the CGI::Application framework
when the application should initialize itself and load all necessary
parameters. The wiki decides here what to do and loads all needed values
from the configuration or database respectively. These parameters are
passed to the wiki via the C<PARAMS> parameter of CGI::Application, as
C<setup> is not called directly. So the general use is like this :

=for example begin

  my $wiki = CGI::Wiki::Simple
             ->new( PARAMS => {
                                header => "<hr /> My custom header <hr />",
                                store => $store,
                              })->run;

=for example end

C<setup> takes a list of pairs as parameters, one mandatory and some optional :

  store => $store

The store entry must be the CGI::Wiki::Store that this wiki resides in.

  header => "<hr />My own wiki<hr />"

This is the header that gets printed before every node. The default is
some simplicistic table to contain the wiki content. This is only used
if you don't use templates, that is, if the wiki C<isa> CGI::Wiki::NoTemplates.

  footer => "<hr />This node was presented by me<hr />"

This is the footer that gets printed after every node. Also only used
when no (other) templates are in use.

  style => "http://www.example.com/style.css",

This is the stylesheet to use with your page. Also, this is only used
if you don't use templates. The default is no style sheet.

Most of the parameters to the constructor of CGI::Wiki can also be passed
here and will be passed on to the CGI::Wiki object.

=cut

sub setup {
  my ($self) = @_;
  $self->run_modes(
    preview  => 'render_editform',
    display  => 'render_display',
    commit   => 'render_commit',
  );
  $self->mode_param( \&decode_runmode );
  $self->start_mode("display");

  my $q = $self->query;
  #open OUT, ">>", "query.log"
  #  or die "Couldn't create query save file : $!";
  #$q->save(*OUT);
  #close OUT;

  my %default_config = (
                 store           => $self->param("store"),
  							 script_name     => $q->script_name,
                 extended_links  => 1,
                 implicit_links  => 1,
                 node_prefix     => $q->script_name . '/display/',
                 style           => "",
                 header          => "<table width='100%'><tr><td align='left'><a href='".$q->script_name."/display/AllNodes'>AllNodes</a></td><td align='center'>CGI::Wiki::Simple Wiki</td>" .
                                      "<td align='right'><form method=post action='".$q->script_name."'><input type='text' name='node' /><input type='hidden' name='action' value='display' /><input type='submit' value='go' /></form></td></tr></table>",
                 footer          => "<center>
                                       <form method=post action='".$q->script_name."'>
                                       <a href='".$q->script_name."/display/index'>home</a>
                                       | Powered by <a href='http://search.cpan.org/search?mode=module&query=CGI::Wiki'>CGI::Wiki</a>::Simple
                                       | <input type='text' name='node' /><input type='hidden' name='action' value='display' /><input type='submit' value='go' /></form>
                                       </center>",
  );

  my %args;
  $args{$_} = defined $self->param($_) ? $self->param($_) : $default_config{$_}
    for (keys %default_config);

  $self->param( $_ => $args{$_})
    for qw( script_name );

  for (qw( header footer style )) {
    $self->param("cgi_wiki_simple_$_", $self->param($_) || $args{$_});
  };

  $self->param(wiki => CGI::Wiki->new(%args));

  # Maybe later add the connection to the database here...
};

=item B<teardown>

The C<teardown> sub is called by CGI::Application when the
program ends. Currently, it does nothing in CGI::Wiki::Simple.

=cut

sub teardown {
  my ($self) = @_;
  # Maybe later add the database disconnect here ...
};

=item B<node_link %ARGS>

C<node_link> creates a link to a node suitable to use as the C<href> attribute.
The arguments are :

  node => 'Node title'
  mode => 'display' # or 'edit' or 'commit'

The default mode is C<display>.

=cut

sub node_url {
  my ($self,%args) = @_;
  $args{mode} = 'display'
    unless exists $args{mode};
  return $self->param('script_name') . "/$args{mode}/" . uri_escape($args{node});
};

=item B<inside_link %ARGS>

C<inside_link> is a convenience function to create a link within the Wiki.
The parameters are :

  title  => 'Link title'
  target => 'Node name'
  node   => 'Node name' # synonymous to target
  mode   => 'display' # or 'edit' or 'commit'

If C<title> is missing, C<target> is used as a default, if C<mode> is missing,
C<display> is assumed. Everything is escaped in the right way. This method
is mostly intended for plugins. A possible API change might be a move of
this function into L<CGI::Wiki::Simple::Plugin>.

=cut

sub inside_link {
  my ($self,%args) = @_;
  $args{node} ||= $args{target};
  $args{title} ||= $args{node};

  "<a href='" . $self->node_url(%args) . "'>" . HTML::Entities::encode_entities($args{title}) . "</a>";
};

=item B<wiki>

This is the accessor method to the contained CGI::Wiki class.

=cut

sub wiki { $_[0]->param("wiki") };

sub load_tmpl {
  my ($self,$name) = @_;
  my $template = $self->SUPER::load_tmpl( $name, die_on_bad_params => 0 );
  $template->param($_,$self->param($_)) for qw(node_title cgi_wiki_simple_style script_name node_prefix version content checksum);
  $self->header_props( -title => $self->param("node_title"));
  $template;
};

sub load_actions {
  my ($self,$template,%actions) = @_;
  for (keys %actions) {
    $template->param($_, $actions{$_});
  };
};

sub render {
  my ($self,$templatename,$actions,@params) = @_;
  my $template = $self->load_tmpl($templatename);
  #warn join "+",@$actions;
  $self->load_actions($template, map { $_ => 1 } @$actions );
  $template->param( $_ => $self->param( $_ )) for @params;
  $template->output;
};

sub render_display {
  my ($self) = @_;
  $self->render( "page_display.templ", [ 'preview' ] );
};

sub render_editform {
  my ($self) = @_;
  $self->render( "page_edit.templ", [ 'display','commit' ], qw( content raw ) );
};

sub render_conflict {
  my ($self) = @_;
  $self->render( "page_conflict.templ", [ 'display','commit' ], qw( content raw submitted_content ));
};

=item render_commit

Renders either the display page or a page indicating that
there was a version conflict.

=cut

sub render_commit {
  my ($self) = @_;
  my $q = $self->query;
  my $node = $self->param("node_title");
  my $submitted_content = $q->param("content");

  $submitted_content =~ s/\r\n/\n/g;
  my $cksum = $q->param("checksum");
  my $written;
  $written = $self->write_node($node, $submitted_content, $cksum)
    if $cksum;

  if ($written || not defined $cksum) {
    $self->header_type("redirect");
    $self->header_props( -url => $self->node_url( node => $node, mode => 'display' ));
  } else {
    $self->param( submitted_content => $submitted_content );
    return $self->render_conflict();
  }
};

=item B<decode_runmode>

C<decode_runmode> decides upon the url what to do. It also
initializes the following CGI::Application params :

  html_node_title
  url_node_title
  node_title

  version
  checksum
  content
  raw

=cut

sub decode_runmode {
  my ($self) = @_;
  my $q = $self->query;
  my $node_title = $q->param("node");
  my $action = $q->param("action");

  # Magic runmode decoding :
  my $runmodes = join "|", map { quotemeta } $self->run_modes;
  if ($q->path_info =~ m!^/($runmodes)/(.*)!) {
    $action = $1;
    $node_title ||= $2;
    $q->param("action","");
  };
  $action ||= 'display';
  $node_title ||= "index";
  $node_title = uri_unescape($node_title);

  $self->param(html_node_title => HTML::Entities::encode_entities($node_title));
  $self->param(url_node_title  => uri_escape($node_title));
  $self->param(node_title      => $node_title);

  my (%node,$raw);
  if (exists $CGI::Wiki::Simple::magic_node{$node_title}) {
    eval { %node = $CGI::Wiki::Simple::magic_node{$node_title}->($self,$node_title); };
    die $@ if $@;
    $self->param(version  => $node{version});
    $self->param(checksum => $node{checksum});
    $self->param(content  => $node{content});
  } else {
    %node = $self->retrieve_node($node_title);
    $raw = $node{content};
    $self->param(raw => $raw);
    $self->param(content => $self->format($raw));
    $self->param(checksum => $node{checksum});
  };

  $action = "display"
    unless defined $raw;

  $action;
};

=back

=cut

1;

=head1 ACKNOWLEDGEMENTS

Many thanks must go to Kate Pugh, for writing L<CGI::Wiki> and for testing and proofreading this module.

=head1 AUTHOR

Max Maischein (corion@cpan.org)

=head1 COPYRIGHT

     Copyright (C) 2003 Max Maischein.  All Rights Reserved.

This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Wiki>,L<CGI::Application>
