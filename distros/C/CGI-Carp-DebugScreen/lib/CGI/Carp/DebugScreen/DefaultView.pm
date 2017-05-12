package CGI::Carp::DebugScreen::DefaultView;

use strict;
use warnings;

our $VERSION = '0.15';

sub as_html {
  my ($pkg, %options) = @_;

  delete $options{debug_template};
  delete $options{error_template};

  $options{debug} ? $pkg->_debug(%options) : $pkg->_error(%options);
}

sub _escape {
  my $str = shift;

  $str =~ s/&/&amp;/g;
  $str =~ s/>/&gt;/g;
  $str =~ s/</&lt;/g;
  $str =~ s/"/&quot;/g;

  $str;
}

sub _navi {
  my %options = @_;

  my $html =<<"EOT";
<div class="navi">
[<a href="#top">top</a>]
[<a href="#stacktraces">stacktraces</a>]
EOT
  if (@{ $options{watchlist} }) {
    $html .=<<"EOT";
[<a href="#watch">watchlist</a>]
EOT
  }
  if (@{ $options{modules} }) {
    $html .=<<"EOT";
[<a href="#modules">modules</a>]
EOT
  }
  if (@{ $options{environment} }) {
    $html .=<<"EOT";
[<a href="#environment">environment</a>]
EOT
  }
  $html .=<<"EOT";
</div>
EOT

  return $html;
}

sub _debug {
  my ($pkg, %options) = @_;

  my $error_at = _escape($options{error_at});

  my $html =<<"EOT";
<html>
<head>
<title>Debug Screen</title>
$options{style}
</head>
<body>
<div id="page">
<a name="top"></a>
<h1>$error_at</h1>
EOT

  if ($options{show_raw_error}) {
    $html .=<<"EOT";
<pre class="raw_error">$options{raw_error}</pre>
EOT
  }
  else {
    $html .=<<"EOT";
<div class="box">
$options{error_message}
</div>
EOT
  }

  $html .= _navi(%options);

  $html .=<<"EOT";
<div class="box">
<h2><a name="stacktraces">Stacktraces</a></h2>
<ul id="stacktraces">
EOT

  foreach my $stacktrace (@{ $options{stacktraces} }) {
    my $caller = _escape($stacktrace->{caller});
    my $line   = $stacktrace->{line};
    $html .=<<"EOT";
<li>$caller LINE : $line</li>
<table class="code">
EOT

    foreach my $line (@{ $stacktrace->{context} }) {
      if ($line->{hit}) {
        $html .=<<"EOT";
<tr class="hit">
EOT
      }
      else {
        $html .=<<"EOT";
<tr>
EOT
      }
      my $line_no   = _escape($line->{no});
      my $line_body = _escape($line->{line});
      $html .=<<"EOT";
<td class="num">$line_no:</td><td>$line_body</td>
</tr>
EOT
    }
    $html .=<<"EOT";
</table>
EOT
  }

  $html .=<<"EOT";
</ul>
</div>
EOT

  if (@{ $options{watchlist} }) {
    $html .= _navi(%options);

    $html .=<<"EOT";
<div class="box">
<h2><a name="watch">Watch List</a></h2>
<ul id="watch">
EOT

    foreach my $watch (@{ $options{watchlist} }) {
      my $key   = _escape($watch->{key});
      my $table = $watch->{value};
      $html .=<<"EOT";
<li>
<b>$key</b><br>
<div class="scrollable">
$table
</div>
</li>
EOT
    }
    $html .=<<"EOT";
</ul>
</div>
EOT
  }

  if (@{ $options{modules} }) {
    $html .= _navi(%options);

    $html .=<<"EOT";
<div class="box">
<h2><a name="modules">Included Modules</a></h2>
<ul id="modules">
EOT

    foreach my $module (@{ $options{modules} }) {
      my $package = _escape($module->{package});
      my $file    = _escape($module->{file});

      $html .=<<"EOT";
<li>$package ($file)</li>
EOT
    }
    $html .=<<"EOT";
</ul>
</div>
EOT
  }

  if (@{ $options{environment} }) {
    $html .= _navi(%options);

    $html .=<<"EOT";
<div class="box">
<h2><a name="environment">Environmental Variables</a></h2>
<table id="environment">
EOT

    foreach my $env (@{ $options{environment} }) {
      my $key   = _escape($env->{key});
      my $value = _escape($env->{value});
      $html .=<<"EOT";
<tr>
<td>$key</td><td><div class="scrollable">$value</div><//td>
</tr>
EOT
    }
    $html .=<<"EOT";
</table>
</div>
EOT
  }

  my $version = _escape($options{version});
  my $view    = _escape($options{view});

  $html .=<<"EOT";
<p class="footer">CGI::Carp::DebugScreen $version. Output via $view</p>
</div>
</body>
</html>
EOT

  return $html;
}

sub _error {
  my ($pkg, %options) = @_;

  my %escaped = map {
    ( $_, _escape($options{$_}) )
  } keys %options;

  my $html =<<"EOT";
<html>
<head>
<title>An unexpected error has been detected</title>
$options{style}
</head>
<body>
<div id="page">
<h1>An unexpected error has been detected</h1>
<p>Sorry for inconvenience.</p>
</div>
</body>
</html>
EOT

  return $html;
}

1;

__END__

=head1 NAME

CGI::Carp::DebugScreen::DefaultView - CGI::Carp::DebugScreen Renderer without template engines

=head1 SYNOPSIS

  use CGI::Carp::DebugScreen (
    engine => 'DefaultView',  # CGI::Carp::DebugScreen::DefaultView
                              # will be called internally; you can
                              # omit this.
  );

=head1 DESCRIPTION

One of the ready-made view (renderer) classes for L<CGI::Carp::DebugScreen>.

Note that this doesn't support template overriding.

=head1 METHOD

=head2 as_html

will be called internally from L<CGI::Carp::DebugScreen>.

=head1 SEE ALSO

L<CGI::Carp::DebugScreen>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
