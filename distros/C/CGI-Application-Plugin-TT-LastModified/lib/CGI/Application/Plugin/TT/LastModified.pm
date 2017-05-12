package CGI::Application::Plugin::TT::LastModified;

###############################################################################
# Required inclusions.
###############################################################################
use strict;
use warnings;
use CGI::Util qw(expires);
use List::Util qw(max);

###############################################################################
# Version numbering.
###############################################################################
our $VERSION = '1.02';

###############################################################################
# Export our methods.
###############################################################################
our @EXPORT = qw(
    tt_last_modified
    tt_set_last_modified_header
    );

###############################################################################
# Subroutine:   import()
###############################################################################
# Custom import routine, which allows for 'tt_set_last_modified_header()' to be
# auto-added in as a TT post process hook.
###############################################################################
sub import {
    my $pkg = shift;
    my $auto = shift;
    my $caller = scalar caller;

    # manually export our symbols
    foreach my $sym (@EXPORT) {
        no strict 'refs';
        *{"${caller}::$sym"} = \&{$sym};
    }

    # sanity check caller package, and set up auto-header functionality
    if (not UNIVERSAL::isa($caller, 'CGI::Application')) {
        warn "Calling package is not a CGI::Application module.\n";
    }
    elsif (not UNIVERSAL::can($caller, 'tt_obj')) {
        warn "Calling package hasn't imported CGI::Application::Plugin::TT.\n";
    }
    elsif ($auto and ($auto eq ':auto')) {
        $caller->add_callback( tt_post_process => \&tt_set_last_modified_header );
    }
}

###############################################################################
# Subroutine:   tt_last_modified()
###############################################################################
# Returns the most recent modification time for any component of the most
# recently processed template (via 'tt_process()').  Time is returned back to
# the caller as "the number of seconds since the epoch".
###############################################################################
sub tt_last_modified {
    my $self = shift;
    my $ctx   = $self->tt_obj->context();
    my $mtime = 0;
    foreach my $provider (@{$ctx->{'LOAD_TEMPLATES'}}) {
        foreach my $file (keys %{$provider->{'LOOKUP'}}) {
            my $c_mtime = $provider->{'LOOKUP'}{$file}[3];
            $mtime = max( $mtime, $c_mtime );
        }
    }
    return $mtime;
}

###############################################################################
# Subroutine:   tt_set_last_modified_header()
###############################################################################
# Sets a "Last-Modified" header in the HTTP response, equivalent to the last
# modification time of the template components as returned by
# 'tt_last_modified()'.
###############################################################################
sub tt_set_last_modified_header {
    my $self = shift;
    my $mtime = $self->tt_last_modified();
    if ($mtime) {
        my $lastmod = expires( $mtime, 'http' );
        $self->header_add( '-last-modified' => $lastmod );
    }
}

1;

=head1 NAME

CGI::Application::Plugin::TT::LastModified - Set "Last-Modified" header based on TT template

=head1 SYNOPSIS

  # when you want to set the "Last-Modified" header manually
    use base qw(CGI::Application);
    use CGI::Application::Plugin::TT;
    use CGI::Application::Plugin::TT::LastModified;

    sub my_runmode {
        my $self = shift;
        my %params = (
            ...
            );
        my $html = $self->tt_process( 'template.html', \%params );
        $self->tt_set_last_modified_header();
        return $html;
    }

  # when you want the "Last-Modified" header set automatically
    use base qw(CGI::Application);
    use CGI::Application::Plugin::TT;
    use CGI::Application::Plugin::TT::LastModified qw(:auto);

    sub my_runmode {
        my $self = shift;
        my %params = (
            ...
            );
        return $self->tt_process( 'template.html', \%params );
    }

=head1 DESCRIPTION

C<CGI::Application::Plugin::TT::LastModified> adds support to
C<CGI::Application> for setting a "Last-Modified" header based on the most
recent modification time of I<any> of the components of a template that was
processed with TT.

Normally you'll want to call it manually, on as "as needed" basis; if you're
processing templates with TT you're most likely dealing with dynamic content
(in which case you probably don't even want a "Last-Modified" header).  The odd
time you'll want to set a "Last-Modified" header, though, this plugin helps
make that easier.

B<If> you have a desire to have the "Last-Modified" header set automatically
for you, though, C<CGI::Application::Plugin::TT::LastModified> does have an
C<:auto> import tag which auto-registers L</tt_set_last_modified_header()> as a
"tt_post_process" hook for you.  If you've got an app that just processes
static TT pages and generates output, this'll be useful for you.

=head1 METHODS

=over

=item import()

Custom import routine, which allows for C<tt_set_last_modified_header()> to
be auto-added in as a TT post process hook. 

=item tt_last_modified()

Returns the most recent modification time for any component of the most
recently processed template (via C<tt_process()>). Time is returned back to
the caller as "the number of seconds since the epoch". 

=item tt_set_last_modified_header()

Sets a "Last-Modified" header in the HTTP response, equivalent to the last
modification time of the template components as returned by
C<tt_last_modified()>. 

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2007, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<CGI::Application::Plugin::TT>,
L<CGI::Application>,
L<Template>.

=cut
