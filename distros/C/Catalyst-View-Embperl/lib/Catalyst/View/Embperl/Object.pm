package Catalyst::View::Embperl::Object;

use strict;

use base qw( Catalyst::View );

use NEXT;

__PACKAGE__->mk_accessors(qw/ rootdir dumper /);

=head1 NAME

Catalyst::View::Embperl::Object - Embperl::Object View Class

=head1 SYNOPSIS

    # use the helper XXX TODO
    create.pl view Embperl::Object Epo

    # lib/MyApp/View/Epo.pm
    package MyApp::View::Epo;

    use base 'Catalyst::View::Embperl::Object';

    __PACKAGE__->config(
    

    );

    1;

    # Meanwhile, maybe in an 'end' action
    $c->forward('MyApp::View::Epo');


=head1 DESCRIPTION

This is the C<Embperl::Object> view class. Your subclass should inherit from this
class.

=head2 METHODS

=over 4

=item new

The constructor for the Embperl::Object view.

=cut

sub new {
    my($class, $c, $arguments) = @_;

    my $self = $class->NEXT::new($c);

    for my $field (keys %$arguments) {
        if ($self->can($field)) {
            $self->$field($arguments->{$field});
        } else {
            $c->log->debug("Unkown config parameter '$field'");
        }
    }

     BEGIN {
         %Embperl::initparam = (use_env => 1) ;

         # XXX TODO goes in config...
         
         $ENV{EMBPERL_SESSION_CLASSES} = "File" ;
         $ENV{EMBPERL_SESSION_ARGS} = "Directory=/tmp";

         #$ENV{EMBPERL_OBJECT_APP} = "_app.pl" ;

     };

#    Embperl::Req::SetupSession ($req_rec, $uid, $sid, $app_param);

	use Embperl::Object;

    return $self;
}

=item process

Renders the template specified in C<< $c->stash->{template} >>
Template arguments are C<$c>. Output is stored in C<<
$c->response->body >>.

=cut

sub process {
    my ( $self, $c ) = @_;

    my $template = $c->stash->{template};

    unless ($template) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    $c->log->debug(qq/Rendering template "$template"/) if $c->debug;

    my $body;
    my $errors;
    my $err;

    my $rootdir = $self->rootdir;

    unless ($rootdir) {
        $c->log->debug('No rootdir specified for rendering') if $c->debug;
        return 0;
    }

    $c->log->debug("Loading '$rootdir/$template'");

    eval { 

        $err = Embperl::Object::Execute ({
            
            # Name of the base page to search for
            #object_app => '_app.pl',
            
            # Name of the base page to search for
            #object_base => '_base.epl',
            
            # Additional directories where to search for pages. Directories are separated by ; (on Unix : works also). This path is always appended to the searchpath.
            #object_addpath => $rootdir,
            
            #Directory where to stop searching for the base page
            object_stopdir => $rootdir,
            
            #If the requested file is not found the file given by EMBPERL_OBJECT_FALLBACK is displayed instead. If EMBPERL_OBJECT_FALLBACK isn't set a staus 404, NOT_FOUND is returned as usual. If the fileame given in EMBPERL_OBJECT_FALLBACK doesn't contain a path, it is searched thru the same directories as EMBPERL_OBJECT_BASE.
            
            # object_fallback
            
            # If you specify this call the template base and the requested page inherit all methods from this class. This class must contain Embperl::Req in his @ISA array.
            #    object_handler_class
            
            inputfile  => "$rootdir/$template",
            mtime      => 1,
            output     => \$body,

            param      => [ $c ],

            # Segmentation fault !!
            # errors     => \@body_errors,

            #options    => 268432,
            #escmode    => 7,
            
            #cookie_name => 'sessionid',
            #cookie_path => '/',
            #cookie_domain => 1,
            #cookie_expires => 1,
            
        }) ;
    };
    if ( my $error = $@ ) {
        chomp $error;
        $error = "Couldn't render template \"$template\". Error: \"$error\"";
        $c->log->error($error);
        $c->error($error);

        $c->log->error("EPO err $err");

        return 0;
    }

    unless ( $c->response->headers->content_type ) {
        $c->res->headers->content_type('text/html; charset=utf-8');
    }

    $c->response->body( $body  );

    return 1;
}

=item config

This allows your view subclass to pass additional settings to the
Embperl config hash.

=back

=head1 SEE ALSO

L<Embperl>, L<Catalyst>, L<Catalyst::Base>.

=head1 AUTHOR

Christophe Le Bars, C<clb@2fp.net>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
