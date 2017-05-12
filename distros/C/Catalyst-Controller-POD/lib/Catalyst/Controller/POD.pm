#
# This file is part of Catalyst-Controller-POD
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package Catalyst::Controller::POD;
BEGIN {
  $Catalyst::Controller::POD::VERSION = '1.0.0';
}
# ABSTRACT: Serves PODs right from your Catalyst application
use warnings;
use strict;
use File::Find qw( find );
use File::ShareDir qw( dist_file );
use File::Spec;
use File::Slurp;
use Pod::Simple::Search;
use JSON::XS;
use Path::Class::File;
use Pod::POM;
use XML::Simple;
use LWP::Simple;
use List::MoreUtils qw(uniq);
use Catalyst::Controller::POD::Template;

use base "Catalyst::Controller";

__PACKAGE__->mk_accessors(qw(_dist_dir inc namespaces self dir show_home_tab initial_module home_tab_content expanded_module_tree));

__PACKAGE__->config(
 self                 => 1,
 namespaces           => ["*"],
 initial_module       => "",
 show_home_tab        => 1,
 expanded_module_tree => 0,
 home_tab_content     => <<HTML,
<div style="width:500px; margin:50px" class='x-box-blue' id='move-me'>
<div class="x-box-tl"><div class="x-box-tr"><div class="x-box-tc"></div></div></div>
<div class="x-box-ml"><div class="x-box-mr"><div class="x-box-mc">
<h3 style="margin-bottom:5px;">Search the CPAN</h3>
<input type="text" name="search" id="search" class="x-form-text" style='font-size: 20px; height: 31px'/>
<div style="padding-top:4px;">Type at least three characters</div>
</div></div></div>
<div class="x-box-bl"><div class="x-box-br"><div class="x-box-bc"></div></div></div>
</div>
HTML
);

sub search : Local {
	my ( $self, $c ) = @_;
	my $k = $c->req->param("value");
	my $s = $c->req->param("start");
	my $url = new URI("http://search.cpan.org/search");
	$url->query_form_hash(
		query  => $k,
		mode   => "module",
		n      => 50,
		format => "xml",
		s      => $s
	);
	my $ua = new LWP::UserAgent;
	$ua->timeout(15);
	$c->log->debug("get url ".$url->canonical) if($c->debug);
	my $response = $ua->get($url);
	my $xml = $response->content;
	my $data;
	eval{ $data = XMLin($xml, keyattr => [] )};
	if(@$) {
		$c->res->body("[]");
		return;
	}
	my $output = {count => $data->{matches}};
	while(my($k,$v) = each %{$output->{module}}) {
		
	}
	$c->res->body(encode_json($data));
}


sub module : Local {
	my ( $self, $c, $module ) = @_;
	my $search = Pod::Simple::Search->new->inc( $self->inc || 0 );
	push( @{ $self->{dirs} }, $c->path_to('lib')->stringify )
	  if ( $self->{self} );
	my $name2path =
	  $search->limit_glob($module)->survey( @{ $self->{dirs} } );
	my $view = "Catalyst::Controller::POD::POM::View";
	Pod::POM->default_view($view);
	my $parser = Pod::POM->new( warn => 0 );
	$view->_root( $self->_root($c) );
	$view->_module($module);
	my $pom;

	if ( $name2path->{$module} ) {
		$c->log->debug("Getting POD from local store") if($c->debug);
		$view->_toc( _get_toc( $name2path->{$module} ) );
		$pom = $parser->parse_file( $name2path->{$module} )
		  || die $parser->error(), "\n";
	} else {
		$c->log->debug("Getting POD from CPAN") if($c->debug);
		my $html = get( "http://search.cpan.org/perldoc?" . $module );
	    my $source;
		if($html && $html =~ /.*<a href="(.*?)">Source<\/a>.*/) {
		    $html =~ s/.*<a href="(.*?)">Source<\/a>.*/$1/s;
    		$c->log->debug("Get source from http://search.cpan.org" . $html) if($c->debug);
    		$source = get( "http://search.cpan.org" . $html );
        } else {
            $source = "=head1 ERROR\n\nThis module could not be found.";
        }
		$view->_toc( _get_toc( $source ) );
		$pom = $parser->parse_text($source)
		  || die $parser->error(), "\n";
	}
	Pod::POM->default_view("Catalyst::Controller::POD::POM::View");
	$c->res->body( "$pom" );
}

sub _get_toc {
	my $source = shift;
	my $toc;
	my $parser = Pod::POM->new( warn => 0 );
	my $view = "Pod::POM::View::TOC";
	Pod::POM->default_view($view);
	my $pom = $parser->parse($source);
	$toc = $view->print($pom);
	return encode_json( _toc_to_json( [], split( /\n/, $toc ) ) );
}

sub _toc_to_json {
	my $tree     = shift;
	my @sections = @_;
	my @uniq     = uniq( map { ( split(/\t/) )[0] } @sections );
	foreach my $root (@uniq) {
		next unless ($root);
		push( @{$tree}, { text => $root } );
		my ( @children, $start );
		for (@sections) {
			if ( $_ =~ /^\Q$root\E$/ ) {
				$start = 1;
			} elsif ( $start && $_ =~ /^\t(.*)$/ ) {
				push( @children, $1 );
			} elsif ( $start && $_ =~ /^[^\t]+/ ) {
				last;
			}
		}
		unless (@children) {
			$tree->[-1]->{leaf} = \1;
			next;
		}
		$tree->[-1]->{children} = [];
		$tree->[-1]->{children} =
		  _toc_to_json( $tree->[-1]->{children}, @children );
	}
	return $tree;
}

sub modules : Local {
	my ( $self, $c, $find ) = @_;
	my $search = Pod::Simple::Search->new->inc( $self->{inc} || 0 );
	push( @{ $self->{dirs} }, $c->path_to('lib')->stringify )
	  if ( $self->{self} );
	my $name2path = {};

		for ( @{ $self->{namespaces} } ) {
			my $found =
			  Pod::Simple::Search->new->inc( $self->{inc} || 0 )
				  ->limit_glob($_)->survey( @{ $self->{dirs} } );
			%{$name2path} = (
				%{$name2path}, %{$found}
			);
		}
	
	my @modules;
	while ( my ( $k, $v ) = each %$name2path ) {
		next if($find && $k !~ /\Q$find\E/ig);
		push( @modules, $k );
	}
	@modules = sort @modules;
	my $json = _build_module_tree( [], "", @modules );
	$c->res->body( encode_json($json) );
}

sub _build_module_tree : Private {
	my $tree    = shift;
	my $stack   = shift;
	my @modules = @_;
	my @uniq    = uniq( map { ( split(/::/) )[0] } @modules );
	foreach my $root (@uniq) {
		my $name = $stack ? $stack . "::" . $root : $root;
		push( @{$tree}, { text => $root, name => $name } );
		my @children;
		for (@modules) {
			if ( $_ =~ /^$root\:\:(.*)$/ ) {
				push( @children, $1 );
			}
		}
		unless (@children) {
			$tree->[-1]->{leaf} = \1;
			next;
		}
		$tree->[-1]->{children} = [];
		$tree->[-1]->{children} =
		  _build_module_tree( $tree->[-1]->{children}, $name, @children );
	}
	return $tree;
}

sub _root {
	my ( $self, $c ) = @_;
	my $index = $c->uri_for( __PACKAGE__->config->{path} );

	#$index  =~ s/\/index//g;
	return $index;
}

sub new {
    my $class = shift;
    my $self  = $class->next::method(@_);
    my $file  = Path::Class::File->new( 'share', 'docs.js' );
    eval {
        $file = Path::Class::File->new(
            dist_file( 'Catalyst-Controller-POD', 'docs.js' ) );
    } unless(-e $file);
    $self->_dist_dir( $file->dir );
    return $self;
}


sub index : Path : Args(0) {
	my ( $self, $c ) = @_;
	$c->res->content_type('text/html; charset=utf-8');
	$c->response->body(
		Catalyst::Controller::POD::Template->get(
			$self->_root($c) . "/static"
		)
	);
}

sub get_home_tab_content : Path("home_tab_content") {
	my ( $self, $c ) = @_;
	$c->response->body($self->home_tab_content);
}

sub static : Path("static") {
	my ( $self, $c, @file ) = @_;
	my $file = File::Spec->catfile($self->_dist_dir, @file);
	if ( $file[-1] eq "docs.js" ) {
	    my $data;
        eval { $data = read_file( $file ) };
		_replace_template_vars(\$data, "root",                       $self->_root($c));
		_replace_template_vars(\$data, "initial_module",             $self->initial_module);
		_replace_template_vars(\$data, "show_home_tab",              $self->show_home_tab ? "true" : "false");
		_replace_template_vars(\$data, "expand_module_tree_on_load", $self->expanded_module_tree ? "true" : "false");
		$c->res->content_type('application/json');
		$c->response->body($data);
	} else {
	    $c->serve_static_file($file);
	}
}

# A poor man's template module. 
sub _replace_template_vars {
	my ($data_ref, $var_name, $var_val) = @_;
	$$data_ref =~ s/\[% $var_name %\]/$var_val/g;
}

1;



=pod

=head1 NAME

Catalyst::Controller::POD - Serves PODs right from your Catalyst application

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

Create a new controller and paste this code:

  package MyApp::Controller::YourNewController;  # <-- Change this to your controller
  
  use strict;
  use warnings;
  use base 'Catalyst::Controller::POD';
  __PACKAGE__->config(
    inc        => 1,
    namespaces => [qw(Catalyst::Manual*)],
    self       => 1,
    dirs       => [qw()]
  );
  1;

=head1 DESCRIPTION

This is a catalyst controller which serves PODs. It allows you to browse through your local
repository of modules. On the front page of this controller is a search box
which uses CPAN's xml interface to retrieve the results. If you click on one of them
the POD is displayed in this application.

Cross links in PODs are resolved and pop up as a new tab. If the module you clicked on is
not installed this controller fetches the source code from CPAN and creates the pod locally.
There is also a TOC which is always visible and scrolls the current POD to the selected section.

It is written using a JavaScript framework called ExtJS (L<http://www.extjs.com>) which
generate beautiful and intuitive interfaces.

Have a look at L<http://cpan.org/authors/id/P/PE/PERLER/pod-images/pod-encyclopedia-01.png>.

B<< L<Catalyst::Plugin::Static::Simple> is required and has to be loaded. >>

=head1 CONFIGURATION

=over

=item dirs (Arrayref)

Search for modules in these directories.

Defaults to C<[]>.

=item expanded_module_tree (Boolean)

Expand the module browser tree on initial page load.

Defaults to C<1>

=item home_tab_content (String)

HTML to be displayed in the Home tab.

Defaults to the existing CPAN search box.

=item inc (Boolean)

Search for modules in @INC. Set it to 1 or 0.

Defaults to C<0>.

=item initial_module (String)

If this option is specified, a tab displaying the perldoc for the given module
will be opened on load.  Handy if you wish to disable the home tab and specify
a specific module's perldoc as the initial page a user sees.

Defaults to C<"">

=item namespaces (Arrayref)

Filter by namespaces. See L<Pod::Simple::Search> C<limit_glob> for syntax.

Defaults to C<["*"]>

=item self (Boolean)

Search for modules in C<< $c->path_to( 'lib' ) >>.

Defaults to C<1>.

=item show_home_tab (Boolean)

Show or hide the home tab.

Defaults to C<1>

=head1 NOTICE

This module works fine for most PODs but there are a few which do not get rendered properly. 
Please report any bug you find. See L</BUGS>.

Have a look at L<Pod::Browser> which is a catalyst application running this controller. You
can use it as a stand-alone POD server.

=head1 TODO

Write more tests!

=head1 CONTRIBUTORS

Tristan Pratt

=cut

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

