
package CGI::Application::Plugin::AnyTemplate::ComponentHandler;

use CGI::Application;                  # fix for older version of CAP::Forward so
                                       # that it can install its hooks properly
use CGI::Application::Plugin::Forward;

=head1 NAME

CGI::Application::Plugin::AnyTemplate::ComponentHandler - Embed run modes within a template

=head1 DESCRIPTION

This is a little helper module used by
L<CGI::Application::Plugin::AnyTemplate> to handle finding and running
the run modes for embedded components, and returning their content.

You shouldn't need to use this module directly unless you are adding
support for a new template system.

For information on embedded components see the docs of
L<CGI::Application::Plugin::AnyTemplate>.

=cut

use strict;
use Carp;
use Scalar::Util qw(weaken);

=head1 METHODS

=over 4

=item new

Creates a new C<CGI::Application::Plugin::AnyTemplate::ComponentHandler> object.

    my $component_handler = CGI::Application::Plugin::AnyTemplate::ComponentHandler->new(
        webapp              => $webapp,
        containing_template => $template,
    );

The C<webapp> parameter should be a reference to a C<CGI::Application>
object.

The C<containing_template> parameter should be a reference to the template
object in which this component is embedded.

=cut


sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %args = @_;

    my $self = {};
    bless $self, $class;

    $self->{'webapp'}              = $args{'webapp'};
    $self->{'containing_template'} = $args{'containing_template'};

    weaken $self->{'webapp'};
    weaken $self->{'containing_template'};

    return $self;
}

=item embed

Runs the specified C<runmode> of the C<webapp> object.
Returns the results of this call.

Parameters passed to embed should be passed on to the run mode.

If the results are a scalar reference, then the return value is
dereferenced before returning.  This is the safest way of calling a run
mode since you'll get the output as a string and return it as a string,
but it involves returning potentially very large strings from
subroutines.

=cut

sub embed {
    my $self          = shift;
    my $run_mode_name = shift;

    my $webapp              = $self->{'webapp'};
    my $containing_template = $self->{'containing_template'};

    my $output;
    eval {
        $output = $webapp->CGI::Application::Plugin::Forward::forward($run_mode_name, $containing_template, @_);
    };
    if ($@) {
        confess("Error embedding run mode [$run_mode_name] in web app [$webapp]: $@\n");
    }

    if (ref $output eq 'SCALAR') {
        return $$output;
    }
    else {
        return $output;
    }
}

sub dispatch {
    goto &embed;
}


=item embed_direct

Runs the specified C<runmode> of the C<webapp> object.
Returns the results of this call.

Parameters passed to embed_direct should be passed on to the run mode.

Even if the result of this call is a scalar reference, the result
is NOT dereferenced before returning it.

If you call this method instead of embed, you should be careful to deal
with the possibility that your results are a reference to a string and
not the string itself.

=back

=cut

sub embed_direct {
    my $self          = shift;
    my $run_mode_name = shift;

    my $webapp              = $self->{'webapp'};
    my $containing_template = $self->{'containing_template'};

    # I'd like to have some error handling here, but wrapping this in
    # an eval makes return stop working :(
    return $webapp->CGI::Application::Plugin::Forward::forward($run_mode_name, $containing_template, @_);
}

sub dispatch_direct {
    goto &embed_direct;
}

=head1 AUTHOR

Michael Graham, C<< <mgraham@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Michael Graham, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;


