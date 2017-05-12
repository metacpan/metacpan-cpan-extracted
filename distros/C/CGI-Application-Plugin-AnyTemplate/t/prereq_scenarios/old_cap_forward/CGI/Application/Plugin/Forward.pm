package CGI::Application::Plugin::Forward;

use warnings;
use strict;
use Carp;
use vars qw(@ISA @EXPORT);
@ISA = ('Exporter');

@EXPORT = ('forward');

=head1 NAME

CGI::Application::Plugin::Forward - Pass control from one run mode to another

=head1 VERSION

Version 1.04

=cut

our $VERSION = '1.04';

if (CGI::Application->can('new_hook')) {
    CGI::Application->new_hook('forward_prerun');
}

=head1 SYNOPSIS

    use base 'CGI::Application';
    use CGI::Application::Plugin::Forward;

    sub setup {
        my $self = shift;
        $self->run_modes([qw(
            start
            second_runmode
        )]);
    }
    sub start {
        my $self = shift;
        return $self->forward('second_runmode');
    }
    sub second_runmode {
        my $self = shift;

        my $rm = $self->get_current_runmode;  # 'second_runmode'

    }

=head1 DESCRIPTION

The forward method passes control to another run mode and returns its
output.  This is equivalent to calling C<< $self->$other_runmode >>,
except that L<CGI::Application>'s internal value of the current run mode
is updated.

This means that calling C<< $self->get_current_runmode >> after calling
C<forward> will return the name of the new run mode.  This is useful for
modules that depend on the name of the current run mode such as
L<CGI::Application::Plugin::AnyTemplate>.

For example, here's how to pass control to a run mode named C<other_action>
from C<start> while updating the value of C<current_run_mode>:

    sub setup {
        my $self = shift;
        $self->run_modes({
            start         => 'start',
            other_action  => 'other_method',
        });
    }
    sub start {
        my $self = shift;
        return $self->forward('other_action');
    }
    sub other_method {
        my $self = shift;

        my $rm = $self->get_current_runmode;  # 'other_action'
    }

Note that forward accepts the I<name> of the run mode (in this case
I<'other_action'>), which might not be the same as the name of the
method that handles the run mode (in this case I<'other_method'>)


You can still call C<< $self->other_method >> directly, but
C<current_run_mode> will not be updated:

    sub setup {
        my $self = shift;
        $self->run_modes({
            start         => 'start',
            other_action  => 'other_method',
        });
    }
    sub start {
        my $self = shift;
        return $self->other_method;
    }
    sub other_method {
        my $self = shift;

        my $rm = $self->get_current_runmode;  # 'start'
    }


Forward will work with coderef-based runmodes as well:

    sub setup {
        my $self = shift;
        $self->run_modes({
            start         => 'start',
            anon_action   => sub {
                my $self = shift;
                my $rm = $self->get_current_runmode;  # 'anon_action'
            },
        });
    }
    sub start {
        my $self = shift;
        return $self->forward('anon_action');
    }


=head1 METHODS

=head2 forward

Runs another run mode passing any parameters you supply.  Returns the
output of the new run mode.

    return $self->forward('run_mode_name', @run_mode_params);

=cut

sub forward {
    my $self     = shift;
    my $run_mode = shift;

    if ($CGI::Application::Plugin::AutoRunmode::VERSION) {
        if (CGI::Application::Plugin::AutoRunmode->can('is_auto_runmode')) {
            if (CGI::Application::Plugin::AutoRunmode::is_auto_runmode($self, $run_mode)) {
                $self->run_modes( $run_mode => $run_mode);
            }
        }
    }

    my %rm_map = $self->run_modes;
    if (not exists $rm_map{$run_mode}) {
        croak "CAP::Forward: run mode $run_mode does not exist";
    }
    my $method = $rm_map{$run_mode};

    if ($self->can($method) or ref $method eq 'CODE') {
        $self->{__CURRENT_RUNMODE} = $run_mode;
        $self->call_hook('forward_prerun');
        return $self->$method(@_);
    }
    else {
        croak "CAP::Forward: target method $method of run mode $run_mode does not exist";
    }
}


=head1 HOOKS

Before the forwarded run mode is called, the C<forward_prerun> hook is called.
You can use this hook to do any prep work that you want to do before any
new run mode gains control.

This is similar to L<CGI::Application>'s built in C<cgiapp_prerun>
method, but it is called each time you call L<forward>; not just the
when your application starts.

    sub setup {
        my $self = shift;
        $self->add_callback('forward_prerun' => \&prepare_rm_stuff);
    }

    sub prepare_rm_stuff {
        my $self = shift;
        # do any necessary prep work here....
    }

Note that your hooked method will only be called when you call
L<forward>.  If you never call C<forward>, the hook will not be called.
In particuar, the hook will not be called for your application's
C<start_mode>.  For that, you still use C<cgiapp_prerun>.

If you want to have a method run for every run mode I<including> the C<start_mode>,
then you can call the hook directly from C<cgiapp_prerun>.

    sub setup {
        my $self = shift;
        $self->add_callback('forward_prerun' => \&prepare_rm_stuff);
    }
    sub cgiapp_prerun {
        my $self = shift;
        $self->prepare_rm_stuff;
    }

    sub prepare_rm_stuff {
        my $self = shift;
        # do any necessary prep work here....
    }

Alternately, you can hook C<cgiapp_prerun> to the C<forward_prerun>
hook:

    sub setup {
        my $self = shift;
        $self->add_callback('forward_prerun' => \&cgiapp_prerun);
    }
    sub cgiapp_prerun {
        my $self = shift;
        # do any necessary prep work here....
    }

This is a less flexible solution, since certain things that can be done
in C<cgiapp_prerun> (like setting C<prerun_mode>) won't work when the
method is called from the C<forward_prerun> hook.

=head1 AUTHOR

Michael Graham, C<< <mag-perl@occamstoothbrush.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-forward@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks to Mark Stosberg for the idea and...well...the implementation as
well.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Michael Graham, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of CGI::Application::Plugin::Forward