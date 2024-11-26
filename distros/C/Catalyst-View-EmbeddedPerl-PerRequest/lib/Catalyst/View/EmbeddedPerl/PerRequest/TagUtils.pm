package Catalyst::View::EmbeddedPerl::PerRequest::TagUtils;

use warnings;
use strict;
use JSON::MaybeXS ('encode_json');

sub new {
  my $class = shift;
  my $view = shift;
  return bless {view=>$view}, $class;
} 

our $ATTRIBUTE_SEPARATOR = ' ';
our %SUBHASH_ATTRIBUTES = map { $_ => 1} qw(data aria);
our %ARRAY_ATTRIBUTES = map { $_ => 1 } qw(class);
our %HTML_VOID_ELEMENTS = map { $_ => 1 } qw(area base br col circle embed hr img input keygen link meta param source track wbr);
our %BOOLEAN_ATTRIBUTES = map { $_ => 1 } qw(
  allowfullscreen allowpaymentrequest async autofocus autoplay checked compact controls declare default
  defaultchecked defaultmuted defaultselected defer disabled enabled formnovalidate hidden indeterminate
  inert ismap itemscope loop multiple muted nohref nomodule noresize noshade novalidate nowrap open
  pauseonexit playsinline readonly required reversed scoped seamless selected sortable truespeed
  typemustmatch visible);

our %HTML_CONTENT_ELEMENTS = map { $_ => 1 } qw(
  a abbr acronym address apple article aside audio
  b basefont bdi bdo big blockquote body button
  canvas caption center cite code colgroup
  data datalist dd del details dfn dialog dir div dl dt
  em
  fieldset figcaption figure font footer form frame frameset
  head header hgroup h1 h2 h3 h4 h5 h6 html
  i iframe ins
  kbd label legend li
  main map mark menu menuitem meter
  nav noframes noscript
  object ol optgroup option output
  p picture pre progress
  q
  rp rt ruby
  s samp script section select small span strike strong style sub summary sup svg
  table tbody td template textarea tfoot th thead time title  tt tr
  u ul
  var video);
our @ALL_TAGS = (keys(%HTML_VOID_ELEMENTS), keys(%HTML_CONTENT_ELEMENTS));

sub is_content_tag {
  my ($self, $name) = @_;
  return $HTML_CONTENT_ELEMENTS{$name} ? 1 : 0;
}
sub is_void_tag {
  my ($self, $name) = @_;
  return $HTML_VOID_ELEMENTS{$name} ? 1 : 0;
}

sub _tag_options {
  my $self = shift;
  my (%attrs) = @_;
  return '' unless %attrs;
  my @attrs = ();
  foreach my $attr (sort keys %attrs) {
    if($BOOLEAN_ATTRIBUTES{$attr}) {
      push @attrs, $attr if $attrs{$attr};
    } elsif($SUBHASH_ATTRIBUTES{$attr}) {
      foreach my $subkey (sort keys %{$attrs{$attr}}) {
        push @attrs, $self->_tag_option("${attr}-@{[ _dasherize($subkey) ]}", $attrs{$attr}{$subkey});
      }
    } elsif($ARRAY_ATTRIBUTES{$attr}) {
      my $class = ((ref($attrs{$attr})||'') eq 'ARRAY') ? join(' ', @{$attrs{$attr}}) : $attrs{$attr};
      push @attrs, $self->_tag_option($attr, $class);
    } else {
      push @attrs, $self->_tag_option($attr, $attrs{$attr});
    }
  }
  return '' unless @attrs;
  return join $ATTRIBUTE_SEPARATOR, @attrs;
}
sub _tag_option {
  my $self = shift;
  my $attr = shift;
  my $value = defined($_[0]) ? shift() : '';
  if(ref($value) eq 'HASH') {
    $value = encode_json($value);
    $value = $self->{view}->safe($value);
  } else {
    $value = $self->{view}->safe($value);
  }
  return qq[${attr}="@{[ $value ]}"];
}

sub _dasherize {
  my $value = shift;
  my $copy = $value;
  $copy =~s/_/-/g;
  return $copy;
}