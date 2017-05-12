package Blikistan::MagicEngine::PerlSite;
use strict;
use warnings;
use base 'Blikistan::MagicEngine::TT2';
use base 'Blikistan::MagicEngine::YamlConfig';
use URI::Escape;
use JSON;

=head1 NAME

Blikistan::MagicEngine::PerlSite

=head1 SYNOPSIS

use Blikistan;
my $b = Blikistan->new(
              magic_engine => 'perlSite',
              rester => $rester,
              magic_opts => \%magic_opts,
           );
      
=head1 DESCRIPTION

MagicEngine for Blikistan designed for presenting Wiki content as a web 1.0 website.

=cut

sub print_blog {
    my $self = shift;
    my $r = $self->{rester};
    
    my $params = $self->load_config($r);
    $params->{rester} = $r;
    $params->{blog_tag} ||= $self->{blog_tag};

    my $page = $self->{subpage} || $params->{start_page};

    # Need to get the metadata here
    $r->accept('application/json');
    my $return = _get_page($r, $page);
    my $page_obj = jsonToObj($return);
    my $page_name = $page_obj->{name};
    my $page_uri = $page_obj->{page_uri};

    # If we're searching, do the search thing
    $r->accept('text/html');
    my $nav  = _get_page($r, 
			$params->{nav_page},
			$params->{base_uri},
			$page_uri);

    my ($page_content);
    if ( $self->{search} ) {
   	$page_content = _search($r, 
				$self->{search},
				$params->{base_uri},
				'search');
    } else {
    	$page_content = _get_page($r, 
				$page,
				$params->{base_uri},
				$page_uri);
    	$page_content = "<h1>$page_name</h1>\n$page_content";
    }

    $params->{nav} = $nav;
    $params->{page} = $page_content;	
    return $self->render_template( $params );
}

sub _fix_links {
    my $r = shift;
    my $base_uri = shift;
    my $page_uri = shift;
    my $page_content = shift;
    my $return;

    $base_uri =~ s#/hydra##g;
    # Interesting pieces of the page URI
    my ($server_uri, $workspace, $page_name) = 
	($page_uri =~ m#(https?://[^/]+)/([^/]+)/.*\?(.*)$#);

    # Now we can build the internal REST links
    my $rest_page_uri = "/data/workspaces/$workspace/pages/";
    my @links = ($page_content =~ m/href=["']([^'"]+)["']/g);

    foreach my $link (@links) {
	if ( $link =~ m#^[^/]+$# ) {
		$page_content =~ s/href=(.)$link/href=$1$base_uri$link/g;
	} elsif ( $link =~ m/^$rest_page_uri/ ) {
		$page_content =~ s/$rest_page_uri/$base_uri/g;
	} elsif ( $link =~ m/^pages/ ) {
		$page_content =~ s/href='pages\//href='$base_uri/g;
	}
    }

    my %seen;
    my @image_links = ($page_content =~ m/src=["']([^'"]+)["']/g);
    foreach my $link (@image_links) {
	next if $seen{$link}++;
	if ( $link =~ m/attachments/ ) {
		$page_content =~ s/$link/$server_uri\/$link/g;
	}
	else {
		warn "$link has no attachments\n";
	}
    }
    return $page_content;
}
   
sub _search {
    my $r = shift;
    my $query_string = shift;
    my $base_uri = shift;
    my $page_uri = shift;
    $r->accept('text/html'); 
    $r->query($query_string);
    my $return = $r->get_pages();
    $return = _fix_links ($r,
                        $base_uri,
                        $page_uri,
                        $return);
    return $return;
}
    
sub _get_page {
    my $r = shift;
    my $page_name = shift;
    my $base_uri = shift;
    my $page_uri = shift;
    my $html = $r->get_page($page_name) || '';

    $html =~ s#^<div class="wiki">(.+)</div>\s*$#$1#s;
    $html = _fix_links ($r,
			$base_uri,
			$page_uri,
			$html);

    return $html;
}

=head1 AUTHOR

Kirsten L. Jones<< <synedra at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Kirsten L. Jones, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

