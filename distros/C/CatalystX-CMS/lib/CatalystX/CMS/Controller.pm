package CatalystX::CMS::Controller;
use strict;
use warnings;
use base 'Catalyst::Controller';
use Carp;
use Data::Dump qw( dump );
use MRO::Compat;
use mro 'c3';
use Catalyst::Utils;

our $VERSION = '0.011';

__PACKAGE__->mk_accessors(qw( cms ));

# default config
__PACKAGE__->config(
    cms => {
        model_name             => 'CMS',
        view_name              => 'CMS',
        actionclass_per_action => 0,
        use_editor             => 1,
        use_layout             => 1,
        editor                 => {
            height => '300',
            width  => '550',
        },
        default_type    => 'html',
        default_flavour => 'default',
        lock_period     => 3600,
    }
);

=head1 NAME

CatalystX::CMS::Controller - controller base class

=head1 SYNOPSIS

 package MyApp::Controller::Foo;
 use base (
    'CatalystX::CMS::Controller',    # MUST come first
    'Other::Controller::Base::Class'
 );
 
 sub bar : Local {
     
 }
 
 1;
 
 # if /foo/bar?cxcms=edit then can edit foo/bar.tt
 
=head1 DESCRIPTION

CatalystX::CMS::Controller is a Catalyst::Controller
base class for use with CatalystX::CMS.
 
=head1 METHODS

Only new or overridden method are documented here.

=cut

=head2 new

Merges config with app config and then calls next::method().

=cut

sub new {

    my ( $class, $app ) = @_;

    my $class_conf = $class->config->{cms};
    my $app_conf   = $app->config->{cms};
    unless ( exists $class_conf->{root} ) {
        my $rroot = $app_conf->{root}->{r}
            || [
            ( $app_conf->config->{root} || $app_conf->path_to('root') ) ];
        my $rwroot = $app_conf->{root}->{rw}
            || [ $app_conf->path_to('../cms') ];

        $class_conf->{root}->{r}  ||= $rroot;
        $class_conf->{root}->{rw} ||= $rwroot;
    }

    $class->config(
        cms => $class->merge_config_hashes( $app_conf, $class_conf ) );

    return shift->next::method(@_);
}

=head2 create_action( I<args> )

Overrides base method to use set default Action
class as CatalystX::CMS::Action instead of Catalyst::Action.

=cut

sub create_action {
    my $self = shift;

    return $self->next::method(@_) if $self->cms->{actionclass_per_action};

    my %args = @_;

    my $class = (
        exists $args{attributes}{ActionClass}
        ? $args{attributes}{ActionClass}[0]
        : 'CatalystX::CMS::Action'
    );

    unless ( Class::Inspector->loaded($class) ) {
        require Class::Inspector->filename($class);
    }

    return $class->new( \%args );
}

=head2 cms_template_for( I<c>, I<args> )

Returns a CatalystX::CMS::Page object to be acted upon.
The default assumes the same logic as Catalyst::View::TT but you
may override to implement different naming scheme or logic.

I<args> is an array. I<args> is what is passed to the 
CatalystX::CMS::Action execute()
method. See Catalyst::Action execute() documentation for details.

If present, I<args> will be joined with a C</> and passed to the CMS model.

If no I<args> are present, then $c->action->reverse is used.

If the special request param C<cxcms-url> is present in $c->req->params,
then that value will override all others and will
be used as the C<file> argument to the CMS model.

=cut

sub cms_template_for {
    my ( $self, $c, @arg ) = @_;
    my $file;
    if ( exists $c->req->params->{'cxcms-url'} ) {
        $file = $c->req->params->{'cxcms-url'};
    }
    else {
        $file = @arg ? join( '/', @arg ) : $c->action->reverse;
    }
    return $c->model( $self->cms->{model_name} )->fetch( file => $file );
}

=head2 cms_may_edit( I<c> )

Default returns true. Override to implement authorization.

=cut

sub cms_may_edit {1}

=head2 cms_list

Default local URL method for browsing the pages available in the CMS.
Uses the C<cms/svn/list.tt> template by default.

Override this method in your local controller to customize
the browsing of your CMS.

=cut

sub cms_list : Local {
    my ( $self, $c ) = @_;
    my $pages = $c->model( $self->cms->{model_name} )->search();
    $c->stash( pages    => $pages );
    $c->stash( template => 'cms/svn/list.tt' );
    $c->stash( new_file => 1 );    # hide the 'Edit this page' link
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-cms@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

