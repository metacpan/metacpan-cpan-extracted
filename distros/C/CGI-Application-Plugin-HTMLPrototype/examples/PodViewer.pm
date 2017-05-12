package PodViewer;

use strict;
use warnings;

use base qw(CGI::Application);
use CGI::Application::Plugin::TT 0.07;
use CGI::Application::Plugin::HTMLPrototype;
use CGI::Application::Plugin::ViewSource;
use CGI::Util ();
use LWP::UserAgent ();
use HTML::TokeParser::Simple ();
use CPAN::Config ();
use Compress::Zlib;
use File::Spec ();

my $modules_source = File::Spec->catdir($CPAN::Config->{keep_source_where}, '/modules', '02packages.details.txt.gz');

sub setup {
    my $self = shift;
    $self->run_modes([qw(
        start
        autocomplete
        loadpod
    )]);
}

sub loadpod {
    my $self = shift;
    my $q = $self->query;

    my $name = $q->param('package_name');
    my $p = HTML::TokeParser::Simple->new(url => 'http://search.cpan.org/search?module='.CGI::Util::escape($name));

    my $html;
    my $divlevel = 0;
    my $starting = 0;
    while ( my $token = $p->get_token ) {
        no warnings qw(uninitialized);
        if ( $starting && $divlevel ) {
            if ( $token->is_start_tag('div') ) {
              $divlevel++;
            } elsif ( $token->is_end_tag('div') ) {
              $divlevel--;
            } elsif ( $token->is_tag('img') && $token->get_attr('src') =~ /^\//  ) {
              next; # remove images with relative paths
            } elsif ( $token->is_tag('a') && $token->get_attr('href') =~ /^\//  ) {
              # fully qualify relative paths
              $token->set_attr('href', 'http://search.cpan.org'.$token->get_attr('href'));
            }
            $html .= $token->as_is;
        } elsif ( $token->is_start_tag('div') && $token->get_attr('class') =~ /(pod|path)/ ) {
            $divlevel++;
            $starting++;
            $html .= $token->as_is;
        }
    }
    return $html || "<i>Pod not found for module $name</i>";
}

sub autocomplete {
    my $self = shift;
    my $q = $self->query;

    my $name = $q->param('package_name');
    my @names;
    if ($name) {
        my @options = map { qr/\Q$_\E/i } split ' ', $name;

        my $gz = Compress::Zlib::gzopen( $modules_source, "rb" ) or die "Cannot open $modules_source: $gzerrno\n";

        while ($gz->gzreadline($_) > 0) {
            chomp;
            last unless $_;
        }

        # Example line:
        #  CGI::Application::Session          0.07  C/CE/CEESHEK/CGI-Application-Session-0.07.tar.gz
        my $line;
        while ( $gz->gzreadline($line) > 0 && @names <= 6 ) {
            my ($package, $version, $location) = split /\s+/, $line, 3;
            push @names, format_package($package, $version, $location) unless grep { $package !~ $_ } @options;
        }

        $gz->gzclose();

    }

    # The auto_complete_result method will properly format a response for you,
    #  but the response I am making is a bit more complex than it allows, so I
    #  am doing it the manual way
    #return $self->prototype->auto_complete_result(\@names);
    return '<ul class="modules">'.join('', @names).'</ul>';
}

sub format_package {
  my ($package, $version, $location) = @_;
  $version = '' if $version eq 'undef';
  my $cpanid = (split /\//, $location)[2];
  return qq{<li class="module"><div class="version"><span class="informal">$version</span></div><div class="name">$package</div><div class="cpanid"><span class="informal">$cpanid</span></div></li>};
}


sub start {
    my $self = shift;

    return $self->tt_process(\*DATA);
}

1;
__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <title>CGI::Application::Plugin::HTMLPrototype - PodViewer Example</title>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  [% c.prototype.define_javascript_functions %]

  <link rel="stylesheet" href="http://search.cpan.org/s/style.css" type="text/css">

  <style>
  div.auto_complete {
      width: 350px;
      background: #fff;
  }

  ul.modules  {
      list-style-type: none;
      margin:0px;
      padding:0px;
  }
  ul.modules li.selected {
       background-color: #ffb;
  }

  li.module {
      list-style-type: none;
      display:block;
      margin:0;
      padding:2px;
      height:32px;
  }
  li.module div.version {
      float:left;
      width:42px;
      height:32px;
      margin-right:8px;
  }
  li.module div.name {
      font-weight:bold;
      font-size:12px;
      line-height:1.2em;
  }
  li.module div.cpanid {
      font-size:10px;
      color:#888;
  }
  #list {
      margin:0;
      margin-top:10px;
      padding:0;
      list-style-type: none;
      width:250px;
  }
  #list li {
      margin:0;
      margin-bottom:4px;
      padding:5px;
      border:1px solid #888;
      cursor:move;
  }
</style>
</head>
<body>

<div id="content">
<h3>CGI::Application::Plugin::HTMLPrototype - PodViewer Example</h3>

<p>Code:  <a href="podviewer.cgi?rm=view_source">PodViewer source</a>

<p>Type in a part of a module name (or space separated list of search terms) and a list of CPAN modules matching your terms will be shown.  Choose one and press enter (or click on the "Load Pod" button to load the documentation for that module!</p>

[% c.prototype.form_remote_tag( { url='podviewer.cgi' update='pod' loading=c.prototype.update_element_function( 'pod' { action='update' content='Loading Pod...' } ) } ) %]

CPAN module: <input autocomplete="off" id="package_name" name="package_name" size="100" type="text" value="" />
<div class="auto_complete" id="package_name_auto_complete"></div>

[% c.prototype.auto_complete_field( 'package_name', { url='podviewer.cgi' with="value+'&rm=autocomplete'" } ) %]
<input type="hidden" name="rm" value="loadpod" />
<input type="submit" name=".submit" value="Load Pod" />
</form>

<hr />

<div class="pod" id="pod"></div>

</div>
  
</body>
</html>
