package CGI::Carp::DebugScreen;

use strict;
use warnings;
use Exporter;
use CGI::Carp qw/fatalsToBrowser/;

our $VERSION = '0.16';

BEGIN {
  my $MyDebug = 0;
  CGI::Carp::set_message(
    sub { __PACKAGE__->_output(@_) }
  ) unless $MyDebug;
}

$Carp::Verbose = 1;   # for stacktraces

sub _default_stylesheet {
  return <<'EOS';
<style type="text/css">
<!--
  body {
    font-family: "Bitstream Vera Sans", "Trebuchet MS", Verdana,
    Tahoma, Arial, helvetica, sans-serif;
    color: #000;
    background-color: #f60;
    margin: 0px;
    padding: 0px;
  }
  :link, :link:hover, :visited, :visited:hover {
    color: #333;
  }
  div#page {
    position: relative;
    background-color: #fff;
    border: 1px solid #600;
    padding: 10px;
    margin: 10px;
    -moz-border-radius: 10px;
  }
  div.navi {
    color: #333;
    padding: 0 4px;
  }
  div.box {
    background-color: #fff;
    border: 3px solid #fc9;
    padding: 8px;
    margin: 4px;
    margin-bottom: 10px;
    -moz-border-radius: 10px;
  }
  h1 {
    margin: 0;
    color: #666;
  }
  h2 {
    margin-top: 0;
    margin-bottom: 10px;
    font-size: medium;
    font-weight: bold;
    text-decoration: underline;
  }
  table.code {
    font-size: .8em;
    line-height: 120%;
    font-family: 'Courier New', Courier, monospace;
    background-color: #fc9;
    color: #333;
    border: 1px dotted #600;
    margin: 8px;
    width: 90%;
    border-collapse: collapse;
  }
  table.code tr.hit {
    font-weight: bold;
    color: #000;
    background-color: #f90;
  }
  table.code td {
    padding-left: 1em;
    line-height: 130%;
  }
  table.code td.num {
    width: 4em;
    text-align:right
  }
  table.watch {
    line-height: 120%;
  }
  table.watch th {
    font-weight: normal;
    color: #000;
    background-color: #fc9;
    padding: 0 1em;
  }
  table.watch td {
    line-height: 130%;
    padding: 2px;
  }
  div.scrollable {
    font-size: .8em;
    overflow: auto;
    margin-left: 1em;
  }
  pre.raw_error {
    background-color: #fff;
    border: 3px solid #fc9;
    padding: 8px;
    margin: 4px;
    margin-bottom: 10px;
    -moz-border-radius: 10px;
    font-size: .8em;
    line-height: 120%;
    font-family: 'Courier New', Courier, monospace;
    overflow: auto;
  }
  ul#stacktraces, ul#traces, ul#modules ul#watch {
    margin: 1em 1em;
    padding: 0 1em;
  }
  table#environment {
    margin: 0 1em;
  }
  p.footer {
    margin: 0 1em;
    font-size: .8em;
    text-align:right;
  }
-->
</style>
EOS
}

my %Options;
my %Mapping = (
  debug           => qr/^d(?:ebug)?$/,
  engine          => qr/^e(?:ngine)?$/,
  show_lines      => qr/^l(?:ines)?$/,
  show_mod        => qr/^m(?:od(?:ules)?)?$/,
  show_env        => qr/^env(?:ironment)?$/,
  show_raw_error  => qr/^raw(?:_error)?$/,
  ignore_overload => qr/^(?:ignore_)?overload$/,
  debug_template  => qr/^d(?:ebug_)?t(?:emplate)?$/,
  error_template  => qr/^e(?:rror_)?t(?:emplate)?$/,
  style           => qr/^s(?:tyle)?$/,
);

sub import {
  my ($class, %options) = @_;

  %Options = (
    debug           => 1,
    engine          => 'DefaultView',
    show_lines      => 3,
    show_mod        => 0,
    show_env        => 0,
    show_raw_error  => 0,
    ignore_overload => 0,
    debug_template  => '',
    error_template  => '',
    style           => _default_stylesheet(),
    watchlist       => {},
  );

  while(my ($key, $value) = each %options) {
    next unless defined $value;
    foreach my $canonkey ( keys %Mapping ) {
      if ( $key =~ $Mapping{$canonkey} ) {
        $Options{$canonkey} = $value;
        last;
      }
    }
  }
}

sub debug              { shift; $Options{debug}           = shift; }
sub set_debug_template { shift; $Options{debug_template}  = shift; }
sub set_error_template { shift; $Options{error_template}  = shift; }
sub set_style          { shift; $Options{style}           = shift; }
sub show_modules       { shift; $Options{show_mod}        = shift; }
sub show_environment   { shift; $Options{show_env}        = shift; }
sub show_raw_error     { shift; $Options{show_raw_error}  = shift; }
sub ignore_overload    { shift; $Options{ignore_overload} = shift; }

sub add_watchlist      {
  my ($class, %hash) = @_;
  foreach my $key (keys %hash) {
    $Options{watchlist}->{$key} = $hash{$key};
  }
}

sub _get_stacktraces {
  my ($class, $raw_error) = @_;

  my $first_message = '';
  my $no_more_first;

  my @stacktraces = grep {
    my $caller = $_->{caller} || '';
    (
      $caller eq '' or                  # ignore undefined caller;
      $caller eq $INC{'Carp.pm'} or     # ignore Carp;
      $caller eq $INC{'CGI/Carp.pm'}    # ignore CGI::Carp;
    ) ? 0 : 1;
  }
  map {
    my $line = $_;
    my ($message, $caller, $line_no) = $line =~ /^(?:\s*)(.*?)(?: called)? at (\S+) line (.+)$/;
    $first_message .= "$line<br>" if !defined $message && !$no_more_first;
    $no_more_first = 1 if defined $message;
    $first_message = $message unless $first_message;
    $caller  ||= '';
    $line_no ||= 0;
    my $context = $class->_get_context($caller, $line_no);
    +{
       message  => $message,
       caller   => $caller,
       line     => $line_no,
       context  => $context,

       # XXX: will be deprecated next time
       contents => $context,
    };
  } split(/\n/, $raw_error);

  my $error_at      = $stacktraces[$#stacktraces]->{caller};
  my $error_message = $first_message.' at '.$stacktraces[0]->{caller}.' line '.$stacktraces[0]->{line};

  return ( $error_at, $error_message, @stacktraces );
}

sub _get_context {
  my ($class, $file, $line_no) = @_;

  return unless $file && -f $file;

  my @context;
  if (open my $fh, '<', $file) {
    my $ct = 0;
    while(my $line = <$fh>) {
      $ct++;
      next if $ct < $line_no - $Options{show_lines};
      last if $ct > $line_no + $Options{show_lines};
      push @context, {
        no   => $ct,
        line => $line,
        hit  => ($ct == $line_no),
      };
    }
  }
  \@context;
}

sub _get_modules {
  my ($class, $flag) = @_;

  return unless $flag;

  return map {
    my $key = $_;
    (my $package = $key) =~ s|/|::|g;
    +{
      package => $package,
      file    => $INC{$key},
    }
  } sort {$a cmp $b} keys %INC;
}

sub _get_env {
  my ($class, $flag) = @_;

  return unless $flag;

  return map {
    +{
      key   => $_,
      value => $ENV{$_},
    }
  } sort {$a cmp $b} keys %ENV;
}

sub _get_watchlist {
  my ($class, $href, $overload) = @_;

  my @list;
  if (%{ $href }) {
    require CGI::Carp::DebugScreen::Dumper;
    CGI::Carp::DebugScreen::Dumper->ignore_overload($overload);
    foreach my $key (sort {$a cmp $b} keys %{ $href }) {
      my $dump = CGI::Carp::DebugScreen::Dumper->dump($href->{$key});
      push @list, {
        key   => $key,
        value => $dump,

        # XXX: will be deprecated next time
        table => $dump,
      };
    }
  }
  return @list;
}

sub _load_view {
  my ($class, $engine) = @_;

  my ($view_class, $view);
  if ( ref $engine && $engine->can('as_html') ) {
    $view_class = ref $engine;
    $view       = $engine;
  }
  else {
    # engine alias
    $engine = 'TT' if lc $engine eq 'template';

    $view_class = ( $engine =~ s/^\+// ) ? $engine : __PACKAGE__.'::'.$engine;

    eval "require $view_class";
    if ($@) {
      require CGI::Carp::DebugScreen::DefaultView;
      $view_class = 'CGI::Carp::DebugScreen::DefaultView';
    }
    $view = $view_class;
  }
  return ( $view_class, $view );
}

sub _render {
  my ($class, $raw_error) = @_;

  my ($error_at, $error_message, @stacktraces) = $class->_get_stacktraces($raw_error);

  my @modules     = $class->_get_modules($Options{show_mod});
  my @environment = $class->_get_env($Options{show_env});
  my @watchlist   = $class->_get_watchlist(
    $Options{watchlist},
    $Options{ignore_overload},
  );

  my ($view_class, $view) = $class->_load_view($Options{engine});

  return $view->as_html(
    version        => $VERSION,
    debug          => $Options{debug},
    debug_template => $Options{debug_template},
    error_template => $Options{error_template},
    view           => $view_class,
    style          => $Options{style},
    error_at       => $error_at,
    error_message  => $error_message,
    raw_error      => $raw_error,
    show_raw_error => $Options{show_raw_error},
    stacktraces    => \@stacktraces,
    modules        => \@modules,
    environment    => \@environment,
    watchlist      => \@watchlist,

    # XXX: will be deprecated next time
    debug_tmpl     => $Options{debug_template},
    error_tmpl     => $Options{error_template},
    traces         => \@stacktraces,
  );
}

sub _output {
  my ($class, $raw_error) = @_;

  my $html = $class->_render($raw_error);

  # shamelessly stolen from CGI::Carp

  if (exists $ENV{MOD_PERL}) {
    my $r;
    my $mod_perl;
    if ($ENV{MOD_PERL_API_VERSION}) {
      $mod_perl = 2;
      require Apache2::RequestRec;
      require Apache2::RequestIO;
      require Apache2::RequestUtil;
      require APR::Pool;
      require ModPerl::Util;
      require Apache2::Response;
      $r = Apache2::RequestUtil->request;
    }
    else {
      $r = Apache->request;
    }
    if ($r->bytes_sent) {
      $r->print($html);
      $mod_perl == 2 ? ModPerl::Util::exit(0) : $r->exit;
    }
    else {
      if ($ENV{HTTP_USER_AGENT} =~ /MSIE/) {
        $html = "<!-- " . (' ' x 513) . " -->\n$html";
      }
      $r->custom_response(500, $html);
    }
  }
  else {
    print $html;
  }
}

1;

__END__

=head1 NAME

CGI::Carp::DebugScreen - provides a decent debug screen for Web applications

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Carp;
  use CGI::Carp::DebugScreen ( debug => $ENV{Debug} );
  use CGI;

  my $query = CGI->new;

  croak "let's see";

=head1 DESCRIPTION

C<CGI::Carp qw/fatalsToBrowser/> is very useful for debugging. But the error screen it provides is a bit too plain; something you don't want to see, and you don't want your boss and colleagues and users to see. You might know CGI::Carp has a wonderful C<set_message()> function but, you don't want to repeat yourself, right?

Hence this module.

This module calls C<CGI::Carp qw/fatalsToBrowser/> and C<set_message()> function internally. If something dies or croaks, this confesses stack traces, included modules (optional), environmental variables (optional, too) in a more decent way.

When you finish debugging, set debug option to false (via some environmental variable, for example). Then, more limited, less informative error screen appears with dies or croaks. If something goes wrong and your users might see the screen, they only know something has happened. They'll never know where your modules are and they'll never see the awkward 500 Internal Server Error -- hopefully.

You can, and are suggested to, customize both debug and error screens, and some style settings, in harmony with your application.

Enjoy.

=head1 OPTIONS

Your code will look like this when you want to configure everything:

  use CGI::Carp::DebugScreen (
    debug          => 1,
    engine         => '+MyEngine',
    lines          => 5,
    modules        => 1,
    environment    => 1,
    raw_error      => 0,
    overload       => 1,
    debug_template => $DebugTemplate,
    error_template => $ErrorTemplate,
    style          => $Style,
  );

=head2 debug (or d)

If set to true, debug screen appears; if false, error screen does. The default value is 1. Setting some environmental variable here is a good idea.

=head2 engine (or e)

Sets the base name of a view class. Default value is C<DefaultView>, which uses no template engines. C<HTML::Template> and C<TT> are also available. As of 0.15, you can pass any class with a prepending C<+> or any object with C<as_html> method, which should take a hash of options and returns an HTML string. Your rendering class/object doesn't need to use all of the options naturally.

The options are:

=over 4

=item version

version of this module.

=item debug

if true, debug_template should be used, otherwise, error_template.

=item debug_template, error_template, style

the ones you specified while loading (or via methods).

=item view_class

the actual class name of the view (i.e. renderer).

=item error_at, error_message

where and why your application died.

=item raw_error, show_raw_error

an unprocessed error message (from L<CGI::Carp>), and a flag to use this.

=item stacktraces

array reference of hash references whose keys are C<message>, C<caller>, C<line>, C<context> (information on the lines around the traced line; array reference of hash references whose keys are C<no>, C<line>, C<hit>).

=item modules

array reference of hash references whose keys are C<package> and C<file>.

=item environment

array reference of hash references whose keys are C<key> and C<value>.

=item watchlist

array reference of hash references whose keys are C<key> and C<value> (which may be an escaped scalar or an HTML table).

=back

=head2 lines (or l)

Sets the number of lines shown before and after the traced line. The default value is 3.

=head2 modules (or m / mod)

If set to true, debug screen shows a list of included modules. The default value is undef.

=head2 environment (or env)

If set to true, debug screen shows a table of environmental variables. The default value is undef.

=head2 raw_error (or raw)

If set to true, debug screen shows a raw error message from C<CGI::Carp::confess>. The default value is undef.

=head2 ignore_overload (or overload)

If set to true, watchlist dumper (L<CGI::Carp::DebugScreen::Dumper>) ignores overloading of the objects and pokes into further. The default value is undef.

=head2 debug_template (or dt)

=head2 error_template (or et)

=head2 style (or s)

Override the default templates/style if defined. You may want to set these templates through correspondent methods.

=head1 PACKAGE METHODS

=head2 debug

=head2 show_modules

=head2 show_environment

=head2 show_raw_error

=head2 ignore_overload

=head2 set_debug_template

=head2 set_error_template

=head2 set_style

Do the same as the correspondent options. e.g.

  CGI::Carp::DebugScreen->debug(1); # debug screen appears

=head2 add_watchlist

  CGI::Carp::DebugScreen->add_watchlist( name => $ref );

If set, the module dumps the contents of the references while outputting the debug screen.

=head1 TODO

Encoding support (though CGI::Carp qw/fatalsToBrowser/ sends no charset header). And some more tests. Any ideas?

=head1 SEE ALSO

L<CGI::Carp>, L<CGI::Application::Plugin::DebugScreen>, L<Sledge::Plugin::DebugScreen>

=head1 ACKNOWLEDGMENT

The concept, debug screen template and style are based on several Japanese hackers' blog articles. You might not be able to read Japanese pages but I thank:

=over 4

=item tokuhirom (Tokuhiro Matsuno)

for original Sledge::Plugin::DebugScreen (L<http://tokuhirom.dnsalias.org/~tokuhirom/tokulog/2181.html>, this site is gone now)

=item nipotan (Koichi Taniguchi)

for patches for Sledge::Plugin::DebugScreen (L<http://blog.livedoor.jp/nipotan/archives/50342811.html> and L<http://blog.livedoor.jp/nipotan/archives/50342898.html>)

=item nekokak (Atsushi Kobayashi)

for L<CGI::Application::Plugin::DebugScreen> articles (L<http://www.border.jp/nekokak/blog/archives/2005/12/cgiappdebugscre.html>, L<http://www.border.jp/nekokak/blog/archives/2005/12/cgiappdebugscre_1.html>, L<http://www.border.jp/nekokak/blog/archives/2005/12/cgiappdebugscre_2.html>, L<http://www.border.jp/nekokak/blog/archives/2005/12/cgiappdebugscre_3.html>, all gone now)

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut
