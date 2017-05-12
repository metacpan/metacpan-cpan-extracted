package Catalyst::View::MobileJpFilter;
use strict;
use warnings;
our $VERSION = '0.01';

use base 'Catalyst::View';
use Class::C3;
use Data::Visitor::Callback;
use HTML::MobileJp::Filter;

__PACKAGE__->mk_accessors(qw( html_filter ));

sub new {
    my ($class, $c, $args) = @_;
     
    my $self = $class->next::method($c, $args);
    
    $self->config(
        $self->merge_config_hashes($self->config, $args)
    );
    
    my $v = Data::Visitor::Callback->new(
        plain_value => sub {
            return unless defined $_;
            s{__path_to\((.*?)\)__}{ $c->path_to( $1 ? split( /,/, $1 ) : () ) }eg;
        },
    );
    $v->visit( $self->config );
    
    $self->html_filter(do {
        HTML::MobileJp::Filter->new( filters => $self->config->{filters} )
    });
    
    $self;
}

sub render {
    my ($self, $c) = @_;
    
    $self->html_filter->filter(
        mobile_agent => $c->req->mobile_agent,
        html         => $c->res->body || "",
    );
}

sub process {
    my ($self, $c) = @_;
    
    return 1 if $c->req->method eq 'HEAD';
    return 1 if $c->res->status =~ /^(?:204|3\d\d)$/;
    return 1 unless $c->res->body;
    return 1 unless $c->res->content_type =~ /html$|xhtml\+xml$/;

    $c->res->body( $self->render($c) );

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Catalyst::View::MobileJpFilter - Filtering HTML for Japanese cellphone

=head1 DESCRIPTION

Catalyst::View::MobileJpFilter is a simple adapter to use
L<HTML::MobileJp::Filter> as Catalyst view class.

=head1 SYNOPSIS

  package MyApp::View::MobileJpFilter;
  use strict;
  use base 'Catalyst::View::MobileJpFilter';
  
  use YAML;
  
  __PACKAGE__->config(YAML::Load <<'...'
  ---
  filters:
    - module: DoCoMoCSS
      config:
        base_dir: __path_to(root)__
    - module: DoCoMoGUID
    - module: FallbackImage
      config:
        template: '<img src="%s.gif" />'
        params:
          - unicode_hex
  ...
  );
  
  1;

=head1 CONFIGURATION

Same as L<HTML::MobileJp::Filter>.

One trick: You can use L<Catalyst::Plugin::ConfigLoader>'s
C<__path_to(some/dir)__> syntax in view class. maybe you need this.

=head1 HOW TO USE

Use as follows from your controller.

  sub end :Private {
      my ($self, $c) = @_;
      $c->forward( $c->view('TT') );             # making $c->res->body
      $c->forward( $c->view('MobileJpFilter') ); # filtering $c->res->body
  }

Or with L<RenderView|Catalyst::Action::RenderView>.

  sub render :ActionClass('RenderView') { }
  
  sub end :Private {
      my ($self, $c) = @_;
      $c->forward('render');
      $c->forward( $c->view('MobileJpFilter') );
  }

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTML::MobileJp::Filter>

L<http://coderepos.org/share/browser/lang/perl/Catalyst-View-MobileJpFilter> (repository)

=cut
