package CSS::Inliner;
use strict;
use warnings;

our $VERSION = '4003';

use Carp;
use Encode;
use LWP::UserAgent;
use HTML::Query 'query';
use URI;

use CSS::Inliner::Parser;
use CSS::Inliner::TreeBuilder;

=pod

=head1 NAME

CSS::Inliner - Library for converting CSS <style> blocks to inline styles.

=head1 SYNOPSIS

use CSS::Inliner;

my $inliner = new CSS::Inliner();

$inliner->read_file({ filename => 'myfile.html' });

print $inliner->inlinify();

=head1 DESCRIPTION

Library for converting CSS style blocks into inline styles in an HTML
document.  Specifically this is intended for the ease of generating
HTML emails.  This is useful as even in 2015 Gmail and Hotmail don't
support top level <style> declarations.

=cut

BEGIN {
  my $members = ['stylesheet','css','html','html_tree','query','strip_attrs','relaxed','leave_style','warns_as_errors','content_warnings','agent','fixlatin'];

  #generate all the getter/setter we need
  foreach my $member (@{$members}) {
    no strict 'refs';

    *{'_' . $member} = sub {
      my ($self,$value) = @_;

      $self->_check_object();

      $self->{$member} = $value if defined($value);

      return $self->{$member};
    }
  }
}

=head1 METHODS

=head2 new

Instantiates the Inliner object. Sets up class variables that are used
during file parsing/processing. Possible options are:

html_tree - (optional) Pass in a fresh unparsed instance of HTML::Treebuilder

NOTE: Any passed references to HTML::TreeBuilder will be substantially altered by passing it in here...

strip_attrs - (optional) Remove all "id" and "class" attributes during inlining

leave_style - (optional) Leave style/link tags alone within <head> during inlining

relaxed - (optional) Relaxed HTML parsing which will attempt to interpret non-HTML4 documents.

NOTE: This argument is not compatible with passing an html_tree.

agent - (optional) Pass in a string containing a preferred user-agent, overrides the internal default provided by the module for handling remote documents

=cut

sub new {
  my ($proto, $params) = @_;

  my $class = ref($proto) || $proto;

  # passed in html_tree argument must be of correct type
  # TODO: make sure tree has no content already
  if (defined $$params{html_tree} && $$params{html_tree} && ref $$params{html_tree} ne 'HTML::TreeBuilder') {
    croak 'Incompatible argument passed to new: "html_tree"';
  }

  # check to make sure caller is not trying to pass both an html_tree and setting relaxed flag
  # relaxed flag requires our own internal TreeBuilder, not HTML::TreeBuilder
  if (defined $$params{html_tree} && $$params{html_tree} && defined $$params{relaxed} && $$params{relaxed}) {
    croak 'Incompatible argument passed to new: "html_tree"';
  }

  my $self = {
    stylesheet => undef,
    css => CSS::Inliner::Parser->new({ warns_as_errors => $$params{warns_as_errors} }),
    html => undef,
    html_tree => defined($$params{html_tree}) ? $$params{html_tree} : CSS::Inliner::TreeBuilder->new(),
    query => undef,
    content_warnings => {},
    strip_attrs => (defined($$params{strip_attrs}) && $$params{strip_attrs}) ? 1 : 0,
    relaxed => (defined($$params{relaxed}) && $$params{relaxed}) ? 1 : 0,
    leave_style => (defined($$params{leave_style}) && $$params{leave_style}) ? 1 : 0,
    warns_as_errors => (defined($$params{warns_as_errors}) && $$params{warns_as_errors}) ? 1 : 0,
    agent => (defined($$params{agent}) && $$params{agent}) ? $$params{agent} : 'Mozilla/4.0',
    fixlatin => eval { require Encoding::FixLatin; return 1; } ? 1 : 0
  };

  bless $self, $class;

  $self->_configure_tree({ tree => $self->_html_tree });

  return $self;
}

=head2 fetch_file

Fetches a remote HTML file that supposedly contains both HTML and a
style declaration, properly tags the data with the proper charset
as provided by the remote webserver (if any). Subsequently calls the
read method automatically.

This method expands all relative urls, as well as fully expands the
stylesheet reference within the document.

This method requires you to pass in a params hash that contains a
url argument for the requested document. For example:

$self->fetch_file({ url => 'http://www.example.com' });

Note that you can specify a user-agent to override the default user-agent
of 'Mozilla/4.0' within the constructor. Doing so may avoid certain issues
with agent filtering related to quirky webserver configs.

Input Parameters:
 url - the desired url for a remote asset presumably containing both html and css
 charset - (optional) programmer specified charset for the pass url

=cut

sub fetch_file {
  my ($self,$params) = @_;

  $self->_check_object();

  unless ($params && $$params{url}) {
    croak 'You must pass in hash params that contain a url argument';
  }

  # fetch and retrieve the remote content
  my ($content,$baseref,$ctcharset) = $self->_fetch_url({ url => $$params{url} });

  my $charset = $self->detect_charset({ content => $content, charset => $$params{charset}, ctcharset => $ctcharset });

  my $decoded_html;
  if ($charset) {
    $decoded_html = $self->decode_characters({ content => $content, charset => $charset });
  }
  else {
    # no good hints found, do the best we can

    if ($self->_fixlatin()) {
      Encoding::FixLatin->import('fix_latin');
      $decoded_html = fix_latin($content);
    }
    else {
      $decoded_html = $self->decode_characters({ content => $content, charset => 'ascii' });
    }
  }

  my $html = $self->_absolutize_references({ content => $decoded_html, baseref => $baseref });

  $self->read({ html => $html, charset => $charset });

  return();
}

=head2 read_file

Opens and reads an HTML file that supposedly contains both HTML and a
style declaration, properly tags the data with the proper charset
if specified. It subsequently calls the read() method automatically.

This method requires you to pass in a params hash that contains a
filename argument. For example:

$self->read_file({ filename => 'myfile.html' });

Additionally you can specify the character encoding within the file, for
example:

$self->read_file({ filename => 'myfile.html', charset => 'utf8' });

Input Parameters:
 filename - name of local file presumably containing both html and css
 charset - (optional) programmer specified charset of the passed file

=cut

sub read_file {
  my ($self,$params) = @_;

  $self->_check_object();

  unless ($params && $$params{filename}) {
    croak "You must pass in hash params that contain a filename argument";
  }

  open FILE, "<", $$params{filename} or die $!;
  my $content = do { local( $/ ) ; <FILE> };

  my $charset = $self->detect_charset({ content => $content, charset => $$params{charset} });

  my $decoded_html;
  if ($charset) {
    $decoded_html = $self->decode_characters({ content => $content, charset => $charset });
  }
  else {
    # no good hints found, do the best we can

    if ($self->_fixlatin()) {
      Encoding::FixLatin->import('fix_latin');
      $decoded_html = fix_latin($content);
    }
    else {
      $decoded_html = $self->decode_characters({ content => $content, charset => 'ascii' });
    }
  }

  $self->read({ html => $decoded_html, charset => $charset });

  return();
}

=head2 read

Reads passed html data and parses it.  The intermediate data is stored in
class variables.

The <style> block is ripped out of the html here, and stored
separately. Class/ID/Names used in the markup are left alone.

This method requires you to pass in a params hash that contains scalar
html data. For example:

$self->read({ html => $html });

NOTE: You are required to pass a properly encoded perl reference to the
html data. This method does *not* do the dirty work of encoding the html
as utf8 - do that before calling this method.

Input Parameters:
 html - scalar presumably containing both html and css
 charset - (optional) scalar representing the original charset of the passed html

=cut

sub read {
  my ($self,$params) = @_;

  $self->_check_object();

  unless ($params && $$params{html}) {
    croak 'You must pass in hash params that contains html data';
  }

  if ($params && $$params{charset} && !find_encoding($$params{charset})) {
    croak "Invalid charset passed to read()";
  }

  $self->_html_tree->parse_content($$params{html});

  $self->_init_query();

  #suck in the styles for later use from the head section - stylesheets anywhere else are invalid
  my $stylesheet = $self->_parse_stylesheet();

  #save the data
  $self->_html($$params{html});
  $self->_stylesheet($stylesheet);

  return();
}

=head2 detect_charset

Detect the charset of the passed content.

The algorithm present here is roughly based off of the HTML5 W3C working group document,
which lays out a recommendation for determining the character set of a received document, which
can be seen here under the "determining the character encoding" section:
http://www.w3.org/TR/html5/syntax.html

NOTE: In the event that no charset can be identified the library will handle the content as a mix of
UTF-8/CP-1252/8859-1/ASCII by attempting to use the Encoding::FixLatin module, as this combination
is relatively common in the wild. Finally, if Encoding::FixLatin is unavailable the content will be
treated as ASCII.

Input Parameters:
 content - scalar presumably containing both html and css
 charset - (optional) programmer specified charset for the passed content
 ctcharset - (optional) content-type specified charset for content retrieved via a url

=cut

sub detect_charset {
  my ($self,$params) = @_;

  $self->_check_object();

  unless ($params && $$params{content}) {
    croak "You must pass content for content character decoding";
  }

  my $charset;
  if (exists($$params{charset}) && $$params{charset} && find_encoding($$params{charset})) {
    # precedence given to programmer provided charset
    $charset = $$params{charset};
  }
  elsif (exists($$params{ctcharset}) && $$params{ctcharset} && find_encoding($$params{ctcharset})) {
    # use the Content-Type charset if available
    $charset = $$params{ctcharset};
  }
  else {
    # analyze the document to scan for any meta charset hints we can use
    my $meta_charset = $self->_extract_meta_charset({ content => $$params{content} });

    if ($meta_charset && find_encoding($meta_charset)) {
      # use the meta charset from the document if available
      $charset = $meta_charset;
    }
    else {
      # no hints found...
    }
  }

  return $charset;
}

=head2 decode_characters

Implement the character decoding algorithm for HTML as outlined by the various working groups

Basically apply best practices for determining the applied character encoding and properly decode it

It is expected that this method will be called before any calls to read()

Input Parameters:
 content - scalar presumably containing both html and css
 charset - known charset for the passed content

=cut

sub decode_characters {
  my ($self,$params) = @_;

  $self->_check_object();

  unless ($params && $$params{content}) {
    croak "You must pass content for content character decoding";
  }

  unless ($params && $$params{charset}) {
    croak "You must pass the charset type of the content to decode";
  }

  my $content = $$params{content};
  my $charset = $$params{charset};

  my $decoded_html;
  eval {
    $decoded_html = decode($charset,$content);
  };

  if (!$decoded_html) {
    croak('Error decoding content with character set "'.$$params{charset}.'"');
  }

  return $decoded_html;
}

=head2 inlinify

Processes the html data that was entered through either 'read' or
'read_file', returns a scalar that contains a composite chunk of html
that has inline styles instead of a top level <style> declaration.

=cut

sub inlinify {
  my ($self,$params) = @_;

  $self->_check_object();

  $self->_content_warnings({}); # overwrite any existing warnings

  unless ($self->_html() && $self->_html_tree()) {
    croak 'You must instantiate and read in your content before inlinifying';
  }

  # perform a check to see how bad this html is...
  $self->_validate_html({ html => $self->_html() });

  my $html;
  if (defined $self->_css()) {
    #parse and store the stylesheet as a hash object

    $self->_css->read({ css => $self->_stylesheet() });

    my @css_warnings = @{$self->_css->content_warnings()};
    foreach my $css_warning (@css_warnings) {
      $self->_report_warning({ info => $css_warning });
    }

    my %matched_elements;
    my $count = 0;

    foreach my $entry (@{$self->_css->get_rules()}) {
      next unless exists $$entry{selector} && $$entry{declarations};

      my $selector = $$entry{selector};
      my $declarations = $$entry{declarations};

      #skip over the following pseudo selectors, these particular ones are not inlineable
      if ($selector =~ /(?:^|[\w\._\*\]])::?(?:([\w\-]+))\b/io && $1 !~ /first-child|last-child/i) {
        $self->_report_warning({ info => "The pseudo-class ':$1' cannot be supported inline" });
        next;
      }

      #skip over @import or anything else that might start with @ - not inlineable
      if ($selector =~ /^\@/io) {
        $self->_report_warning({ info => "The directive '$selector' cannot be supported inline" });
        next;
      }

      my $query_result;

      #check to see if query fails, possible for jacked selectors
      eval {
        $query_result = $self->query({ selector => $selector });
      };

      if ($@) {
        $self->_report_warning({ info => $@->info() });
        next;
      }

      # CSS rules cascade based on the specificity and order
      my $specificity = $self->specificity({ selector => $selector });

      #if an element matched a style within the document store the rule, the specificity
      #and the actually CSS attributes so we can inline it later
      foreach my $element (@{$query_result->get_elements()}) {

       $matched_elements{$element->address()} ||= [];
        my %match_info = (
          rule     => $selector,
          element  => $element,
          specificity   => $specificity,
          position => $count,
          css      => $declarations
         );

        push(@{$matched_elements{$element->address()}}, \%match_info);
        $count++;
      }
    }

    #process all elements
    foreach my $matches (values %matched_elements) {
      my $element = $matches->[0]->{element};
      # rules are sorted by specificity, and if there's a tie the position is used
      # we sort with the lightest items first so that heavier items can override later
      my @sorted_matches = sort { $a->{specificity} <=> $b->{specificity} || $a->{position} <=> $b->{position} } @$matches;

      my %new_style;
      my %new_important_style;

      foreach my $match (@sorted_matches) {
        %new_style = (%new_style, %{$match->{css}});
        %new_important_style = (%new_important_style, _grep_important_declarations($match->{css}));
      }

      # styles already inlined have greater precedence
      if (defined($element->attr('style'))) {
        my $cur_style = $self->_split({ style => $element->attr('style') });
        %new_style = (%new_style, %{$cur_style});
        %new_important_style = (%new_important_style, _grep_important_declarations($cur_style));
      }

      # override styles with !important styles
      %new_style = (%new_style, %new_important_style);

      $element->attr('style', $self->_expand({ declarations => \%new_style }));
    }

    #at this point we have a document that contains the expanded inlined stylesheet
    #BUT we need to collapse the declarations to remove duplicate overridden styles
    $self->_collapse_inline_styles();

    # dump out the final processed html for returning to the caller
    $html = $self->_html_tree->as_HTML('',' ',{});
  }
  else {
    $html = $self->{html};
  }

  return $html . "\n";
}

=head2 query

Given a particular selector return back the applicable styles

=cut

sub query {
  my ($self,$params) = @_;

  $self->_check_object();

  unless ($self->_query()) {
    $self->_init_query();
  }

  return $self->_query->query($$params{selector});
}

=head2 specificity

Given a particular selector return back the associated selectivity

=cut

sub specificity {
  my ($self,$params) = @_;

  $self->_check_object();

  unless ($self->_query()) {
    $self->_init_query();
  }

  return $self->_query->get_specificity($$params{selector});
}

=head2 content_warnings

Return back any warnings thrown while inlining a given block of content.

Note: content warnings are initialized at inlining time, not at read time. In
order to receive back content feedback you must perform inlinify first

=cut

sub content_warnings {
  my ($self,$params) = @_;

  $self->_check_object();

  my @content_warnings = keys %{$self->_content_warnings()};

  return \@content_warnings;
}

####################################################################
#                                                                  #
# The following are all private methods and are not for normal use #
# I am working to finalize the get/set methods to make them public #
#                                                                  #
####################################################################


sub _check_object {
  my ($self, $params) = @_;

  unless (ref $self) {
   croak 'You must instantiate this class in order to properly use it';
  }

  return();
}

sub _report_warning {
  my ($self,$params) = @_;

  $self->_check_object();

  if ($self->_warns_as_errors()) {
    croak $$params{info};
  }
  else {
    my $warnings = $self->_content_warnings();
    $$warnings{$$params{info}} = 1;
  }

  return();
}

sub _configure_tree {
  my ($self,$params) = @_;

  $self->_check_object();

  my $tree = $$params{tree};

  # configure tree
  $tree->store_comments(1);
  $tree->attr_encoded(1);
  $tree->no_expand_entities(1);
  if ($self->_relaxed()) {
    $tree->ignore_unknown(0);
    $tree->implicit_tags(0);
  }

  return();
}

sub _fetch_url {
  my ($self,$params) = @_;

  $self->_check_object();

  # Create a user agent object
  my $ua = LWP::UserAgent->new;

  $ua->agent($self->_agent()); # masquerade as Mozilla/4.0 unless otherwise specified in the constructor
  $ua->protocols_allowed( ['http','https'] );

  # set URI internal flag such that leading dot edge-case urls work
  local $URI::ABS_REMOTE_LEADING_DOTS = 1;

  # Create a request
  my $uri = URI->new($$params{url});

  my $req = HTTP::Request->new('GET', $uri, [ 'Accept' => 'text/html, */*' ]);

  # Pass request to the user agent and get a response back
  my $res = $ua->request($req);

  # if not successful
  if (!$res->is_success()) {
    croak 'There was an error in fetching the document for ' . $uri . ' : ' . $res->message;
  }

  # Is it a HTML document
  if ($res->content_type ne 'text/html' && $res->content_type ne 'text/css') {
    croak 'The web site address you entered is not an HTML document.';
  }

  # record the content, charset and baseref of the response
  my $ctcharset = $res->content_type_charset();
  my $content = $res->content || '';
  my $baseref = $res->base;

  return ($content,$baseref,$ctcharset);
}

sub _absolutize_references {
  my ($self,$params) = @_;

  $self->_check_object();

  # parse the protected document, we need to localize it
  my $absolutize_tree = new CSS::Inliner::TreeBuilder();
  $self->_configure_tree({ tree => $absolutize_tree });

  $absolutize_tree->parse_content($$params{content});

  # Change relative links to absolute links
  $self->__changelink_relative({ content => $absolutize_tree->content(), baseref => $$params{baseref} });

  $self->__expand_stylesheet({ content => $absolutize_tree, html_baseref => $$params{baseref} });

  # dump out the final processed html for reading
  my $absolutized_content = $absolutize_tree->as_HTML('',' ',{});

  return $absolutized_content;
}

sub __changelink_relative {
  my ($self,$params) = @_;

  $self->_check_object();

  my $base = $$params{baseref};

  foreach my $i (@{$$params{content}}) {

    next unless ref $i eq 'HTML::Element';

    if ($i->tag eq 'img' or $i->tag eq 'frame' or $i->tag eq 'input' or $i->tag eq 'script') {

      if ($i->attr('src') and $base) {
        # Construct a uri object for the attribute 'src' value
        my $uri = URI->new($i->attr('src'));
        $i->attr('src',$uri->abs($base));
      }                         # end 'src' attribute
    }
    elsif ($i->tag eq 'form' and $base) {
      # Construct a new uri for the 'action' attribute value
      my $uri = URI->new($i->attr('action'));
      $i->attr('action', $uri->abs($base));
    }
    elsif (($i->tag eq 'a' or $i->tag eq 'area' or $i->tag eq 'link') and $i->attr('href') and $i->attr('href') !~ /^\#/) {
      # Construct a new uri for the 'href' attribute value
      my $uri = URI->new($i->attr('href'));

      # Expand URLs to absolute ones if base uri is defined.
      my $newuri = $base ? $uri->abs($base) : $uri;

      $i->attr('href', $newuri->as_string());
    }
    elsif ($i->tag eq 'td' and $i->attr('background') and $base) {
      # adjust 'td' background
      my $uri = URI->new($i->attr('background'));
      $i->attr('background',$uri->abs($base));
    }                           # end tag choices

    # Recurse down tree
    if (defined $i->content) {
      $self->__changelink_relative({ content => $i->content, baseref => $base });
    }
  }
}

sub __fix_relative_url {
  my ($self,$params) = @_;

  $self->_check_object();

  my $uri = URI->new($$params{url});

  return $$params{prefix} . "'" . $uri->abs($$params{base})->as_string ."'";
}

sub __expand_stylesheet {
  my ($self,$params) = @_;

  $self->_check_object();

  my $doc = $$params{content};

  my $stylesheets = ();

  my (@style,@link);
  if ($self->_relaxed()) {
    #get the <style> nodes
    @style = $doc->look_down('_tag','style');

    #get the <link> nodes
    @link = $doc->look_down('_tag','link','href',qr/./);
  }
  else {
    #get the head section of the document
    my $head = $doc->look_down('_tag', 'head'); # there should only be one

    #get the <style> nodes underneath the head section - that's the only place stylesheets are allowed to live
    @style = $head->look_down('_tag','style');

    #get the <link> nodes underneath the head section - there should be *none* at this step in the process
    @link = $head->look_down('_tag','link','href',qr/./);
  }

  foreach my $i (@link) {
    # determine attribute values for the link tag, assign some defaults to avoid comparison warnings later
    my $rel = defined($i->attr('rel')) ? $i->attr('rel') : '';
    my $type = defined($i->attr('type')) ? $i->attr('type') : '';
    my $href = defined($i->attr('href')) ? $i->attr('href') : '';

    # if we don't match the signature of an inlineable stylesheet, skip over
    next unless (($rel eq 'stylesheet') || ($type eq 'text/css') || ($href =~ m/\.css$/));

    my ($content,$baseref) = $self->_fetch_url({ url => $i->attr('href') });

    #absolutized the assetts within the stylesheet that are relative
    $content =~ s/(url\()["']?((?:(?!https?:\/\/)(?!\))[^"'])*)["']?(?=\))/$self->__fix_relative_url({ prefix => $1, url => $2, base => $baseref })/exsgi;

    my $stylesheet = HTML::Element->new('style', type => 'text/css', rel=> 'stylesheet');
    $stylesheet->push_content($content);

    $i->replace_with($stylesheet);
  }

  foreach my $i (@style) {
    #use the baseref from the original document fetch
    my $baseref = $$params{html_baseref};

    my @content = $i->content_list();
    my $content = join('',grep {! ref $_ } @content);

    # absolutize the assets within the stylesheet that are relative
    $content =~ s/(url\()["']?((?:(?!https?:\/\/)(?!\))[^"'])*)["']?(?=\))/$self->__fix_relative_url({ prefix => $1, url => $2, base => $baseref })/exsgi;

    my $stylesheet = HTML::Element->new('style', type => 'text/css', rel=> 'stylesheet');
    $stylesheet->push_content($content);

    $i->replace_with($stylesheet);
  }

  return();
}

sub _validate_html {
  my ($self,$params) = @_;

  my $validator_tree = new CSS::Inliner::TreeBuilder();

  $validator_tree->ignore_unknown(0);
  $validator_tree->implicit_tags(0);
  $validator_tree->parse_content($$params{html});

  if ($self->_relaxed()) {
    # TODO: print out any html issues that would cause the relaxed parsing to modify the document or might cause
    # a rendering problem of some type
    #
    # Currently there are no known issues, but when found they would go here
  }
  else {
    # The following are inconsistencies that can easily be found by scanning our document using the internal Treebuilder
    # The standard TreeBuilder actually alters the document in an attempt to create something "valid", but by doing so
    # all sorts of weird things can happen, so we add them to the warnings report so the caller knows what's going on.

    # count up the major structural components of the document
    my @html_nodes = $validator_tree->look_down('_tag', 'html');
    my @head_nodes = $validator_tree->look_down('_tag', 'head');
    my @body_nodes = $validator_tree->look_down('_tag', 'body');

    # we should have exactly 2 root nodes, the treebuilder inserted one and the nested one from the document...
    if (scalar @html_nodes == 0) {
      $self->_report_warning({ info => 'Unexpected absence of html root node, force inserted' });
    }
    elsif (scalar @html_nodes > 1) {
      $self->_report_warning({ info => 'Unexpected spurious html root node(s) found within referenced document, coalesced' });
    }

    if (scalar @head_nodes > 1) {
      $self->_report_warning({ info => 'Unexpected spurious head node(s) found within referenced document, coalesced' });
    }

    if (scalar @body_nodes > 1) {
      $self->_report_warning({ info => 'Unexpected spurious body node(s) found within referenced document, coalesced' });
    }

    my @link = $validator_tree->look_down('_tag','link','href',qr/./);

    foreach my $i (@link) {
      my $rel = defined($i->attr('rel')) && $i->attr('rel') ? $i->attr('rel') : '';
      my $type = defined($i->attr('type')) && $i->attr('type') ? $i->attr('type') : '';
      my $href = defined($i->attr('href')) && $i->attr('href') ? $i->attr('href') : '';

      # link references to stylesheets at this point in the workflow means the caller is doing something improper
      # currently such references are only chased down if you fetch a document, not if you feed one in
      if ($rel eq 'stylesheet' || $type eq 'text/css' || $href =~ m/.css$/) {
        $self->_report_warning({ info => 'Unexpected reference to remote stylesheet was not inlined' });
        last;
      }
    }

    my $body = $self->_html_tree->look_down('_tag', 'body');

    if ($body) {
      # located spurious <style> tags that won't be handled
      my @spurious_style = $body->look_down('_tag','style','type','text/css');

      if (scalar @spurious_style) {
        $self->_report_warning({ info => 'Unexpected reference to stylesheet within document body skipped' });
      }
    }
  }

  return();
}

sub _parse_stylesheet {
  my ($self,$params) = @_;

  $self->_check_object();

  my $stylesheet = '';

  # figure out where to look for styles
  my $stylesheet_root = $self->_relaxed() ? $self->_html_tree() : $self->_html_tree->look_down('_tag', 'head');

  # get the <style> nodes
  my @style = $stylesheet_root->look_down('_tag','style','type','text/css');

  foreach my $i (@style) {
    #process this node if the html media type is screen, all or undefined (which defaults to screen)
    if (($i->tag eq 'style') && (!$i->attr('media') || $i->attr('media') =~ m/\b(all|screen)\b/)) {

      foreach my $item ($i->content_list()) {
        # remove HTML comment markers
        $item =~ s/<!--//mg;
        $item =~ s/-->//mg;

        $stylesheet .= $item;
      }
    }

    unless ($self->_leave_style()) {
      $i->delete();
    }
  }

  return $stylesheet;
}

sub _collapse_inline_styles {
  my ($self,$params) = @_;

  $self->_check_object();

  #check if we were passed a node to recurse from, otherwise use the root of the tree
  my $content = exists($$params{content}) ? $$params{content} : [$self->_html_tree()];

  foreach my $i (@{$content}) {

    next unless (ref $i && $i->isa('HTML::Element'));

    if ($i->attr('style')) {

      #flatten out the styles currently in place on this entity
      my $existing_styles = $i->attr('style');
      $existing_styles =~ tr/\n\t/  /;

      # hold the property value pairs
      my $styles = $self->_split({ style => $existing_styles });

      my $collapsed_style = '';
      foreach my $key (sort keys %{$styles}) { #sort for predictable output
        $collapsed_style .= $key . ': ' . $$styles{$key} . '; ';
      }

      $collapsed_style =~ s/\s*$//;
      $i->attr('style', $collapsed_style);
    }

    #if we have specifically asked to remove the inlined attrs, remove them
    if ($self->_strip_attrs()) {
      $i->attr('id',undef);
      $i->attr('class',undef);
    }

    # Recurse down tree
    if (defined $i->content) {
      $self->_collapse_inline_styles({ content => $i->content() });
    }
  }
}

sub _extract_meta_charset {
  my ($self,$params) = @_;

  $self->_check_object();

  # we are going to parse an html document as ascii that is not necessarily ascii - silence the warning
  local $SIG{__WARN__} = sub { my $warning = shift; warn $warning unless $warning =~ /^Parsing of undecoded UTF-8/ };

  # parse document and pull out key header elements
  my $extract_tree = new CSS::Inliner::TreeBuilder();
  $self->_configure_tree({ tree => $extract_tree });

  $extract_tree->parse_content($$params{content});

  my $head = $extract_tree->look_down("_tag", "head"); # there should only be one

  my $meta_charset;
  if ($head) {
    # pull key header meta elements
    my $meta_charset_elem = $head->look_down('_tag','meta','charset',qr/./);
    my $meta_equiv_charset_elem = $head->look_down('_tag','meta','http-equiv',qr/content-type/i,'content',qr/./);

    # assign meta charset, we give precedence to meta http_equiv content type
    if ($meta_equiv_charset_elem) {
      my $meta_equiv_content = $meta_equiv_charset_elem->attr('content');

      # leverage charset allowable chars from https://tools.ietf.org/html/rfc2978
      if ($meta_equiv_content =~ /charset(?:\s*)=(?:\s*)([\w!#$%&'\-+^`{}~]+)/i) {
        $meta_charset = find_encoding($1);
      }
    }

    if (!defined($meta_charset) && $meta_charset_elem) {
      $meta_charset = find_encoding($meta_charset_elem->attr('charset'));
    }
  }

  return $meta_charset;
}

sub _init_query {
  my ($self,$params) = @_;

  $self->_check_object();

  $self->{query} = HTML::Query->new($self->_html_tree());

  return();
}

sub _expand {
  my ($self, $params) = @_;

  $self->_check_object();

  my $declarations = $$params{declarations};
  my $inline = '';
  foreach my $property (keys %{$declarations}) {
    $inline .= $property . ':' . $$declarations{$property} . ';';
  }

  return $inline;
}

sub _split {
  my ($self, $params) = @_;

  $self->_check_object();

  my $style = $params->{style};
  my %split;

  # Split into properties/values
  foreach ( grep { /\S/ } split /\;/, $style ) {
    unless ( /^\s*([\w._-]+)\s*:\s*(.*?)\s*$/ ) {
      $self->_report_warning({ info => "Invalid or unexpected property '$_' in style '$style'" });
    }
    $split{lc $1} = $2;
  }

  return \%split;
}

sub _grep_important_declarations {
  my ($declarations) = @_;

  my %important;

  while (my ($property, $value) = each %$declarations) {
    if ($value =~ /!\s*important\s*$/i) {
      $important{$property} = $value;
    }
  }

  return %important;
}

1;

=head1 Sponsor

This code has been developed under sponsorship of MailerMailer LLC,
http://www.mailermailer.com/

=head1 AUTHOR

 Kevin Kamel <kamelkev@mailermailer.com>

=head1 CONTRIBUTORS

 Dave Gray <cpan@doesntsuck.com>
 Vivek Khera <vivek@khera.org>
 Michael Peters <wonko@cpan.org>
 Chelsea Rio <chelseario@gmail.com>

=head1 LICENSE

This module is Copyright 2015 Khera Communications, Inc.  It is
licensed under the same terms as Perl itself.

=cut
