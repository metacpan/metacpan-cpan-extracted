package Catalyst::View::Embperl;

use strict;
our $VERSION = '0.02';

use base qw( Catalyst::View );
#use File::Spec;
use Embperl;
use NEXT;

__PACKAGE__->mk_accessors(qw/ rootdir dumper /);

=head1 NAME

Catalyst::View::Embperl - Embperl View Class

=head1 SYNOPSIS

    # use the helper (XXX TODO)
    create.pl view Embperl Epl

    # lib/MyApp/View/Epl.pm
    package MyApp::View::Epl;

    use base 'Catalyst::View::Embperl';

    __PACKAGE__->config(
    );

    1;

    # Meanwhile, maybe in an 'end' action
    $c->forward('MyApp::View::Epl');


=head1 DESCRIPTION

This is the C<Embperl> view class. Your subclass should inherit from this
class.

=head2 METHODS

=over 4

=item new

The constructor for the Embperl view.

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

    # use Execute
    # cf http://www3.ecos.de/embperl/pod/doc/doc13/HTML/Embperl.-page-3-.htm#sect_4 

    my $template_root = $self->rootdir;

    eval { 
        Embperl::Execute ({ 
            inputfile  => "$template_root/$template",
            mtime      => 1,
            output     => \$body 
            });
      };
    if ( my $error = $@ ) {
        chomp $error;
        $error = "Couldn't render template \"$template\". Error: \"$error\"";
        $c->log->error($error);
        $c->error($error);
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
