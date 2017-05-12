package Dancer2::Plugin::Growler;

use strict;
use warnings;

use Dancer2::Plugin;

$Dancer2::Plugin::Growler::VERSION = '0.03';

sub _growl {
    my ( $dsl, $msg, $args ) = @_;
    $dsl->app->session->write( 'growls', [] ) if !$dsl->app->session->read('growls');
    if ( exists $args->{delay} ) {
        if ( !defined $args->{delay} || $args->{delay} < 1 ) {
            $args->{allow_dismiss} = 1;
        }

        # else {
        #     # ?TODO/YAGNI?: enforce a sane default if too low?
        # }
    }
    push @{ $dsl->app->session->read('growls') }, { message => $msg, options => $args };
    $dsl->app->session->write( 'growls', $dsl->app->session->read('growls') );
}

register growl => \&_growl;

register growl_info => sub {
    $_[2]->{type} = 'info';
    goto &_growl;
};

register growl_success => sub {
    $_[2]->{type} = 'success';
    goto &_growl;
};

register growl_warning => sub {
    $_[2]->{type} = 'warning';
    goto &_growl;
};

register growl_error => sub {
    $_[2]->{type} = 'danger';
    goto &_growl;
};

register growls => sub {
    my $dsl = shift;
    return if !$dsl->app->session->read('growls');
    my @growls = @{ $dsl->app->session->read('growls') };
    $dsl->app->session->write( 'growls', [] );
    return \@growls;
};

on_plugin_import {
    my $dsl = shift;

    # TODO 2: Is there a better way to add template keyword?
    $dsl->app->add_hook(

        # ?TODO/YAGNI? do growl() and growl_*() in TT also?
        Dancer2::Core::Hook->new(
            name => 'before_template_render',
            code => sub {
                $_[0]->{growls} = sub { $dsl->growls(@_) }
            },
        )
    );
};

register_plugin;

1;

__END__

=encoding utf-8

=head1 NAME

Dancer2::Plugin::Growler - Growl multiple messages of varying types to the user on their next hit.

=head1 VERSION

This document describes Dancer2::Plugin::Growler version 0.03

=head1 SYNOPSIS

    use Dancer2::Plugin::Growler;

    …

    my $error = locale->maketext('Invalid login credentials.'); # locale() is from L<Dancer2::Plugin::Locale>
    growl_error($error); 
    redirect '/login';

    …

    my $msg = locale->maketext('Successfully created post the post “[_1]”.', $html_safe_title); # locale() is from L<Dancer2::Plugin::Locale>
    growl_success($msg); 
    redirect "/post/$new_id";

Then in the view’s layout (this example implies a bootstrap3/jquery environment w/ the bootstrapGrowl jquery plugin):

    [% SET growl_list = growls() %]
    [%- IF growl_list.size %]
    [% USE JSON.Escape %]
    <script type="text/javascript">
        $( document ).ready(function() {
            [% FOREACH growl in growl_list -%]
                $.bootstrapGrowl("[% growl.message.dquote %]", [% growl.options.json %]);
            [% END %]
        });
    </script>
    [%- END %]

=head1 DESCRIPTION

This allows you to specify one or more one-time messages (of varying types) to growl on the user’s next hit (or this hit if you render a view that implements it) with out needing to pass around parameters.

It is also a nice approach because it is refresh safe. For example, in the SYNOPSIS example with the blog post, say we rendered the message at the end of the request instead: refreshing the page could cause us to post the blog article again.

It is similar to the “flash” example in the Dancer2 documentation but without the multi-user race condition and limitation of one message.

It is also AJAX-safe (don’t call growls() in your AJAX templates and you won’t miss any message) yet still AJAX-able (call growls() in your AJAX templates in order to include them in your response).

Also, with this approach your perl can growl exactly like you do in JavaScript with zero effort. Ease of Consistency FTW!

=head1 INTERFACE 

=over 4

=item growl()

The first argument is the message to growl. The second, optional argument is hashref of arguments.

The keys it can specify are:

=over 4

=item 'type'

The type of message. The values, if given, can be: 'info', 'success', 'warning', or 'danger' (That last one is from bootstrap convention).

If your javascript implementation uses a different key (or different values) for this then your system will need to factor that in.

=item 'delay'

The number of milliseconds you intend the growl to display before fading out.

Zero should cause your JavaScript implementation to not fade, effectively making it permanent.

If your JavaScript implementation uses a different key for this then your system will need to factor that in.

=item 'allow_dismiss'

Boolean of if the growl should be dismissible via a close icon.

If the delay is turned off this is forced to true so that we don’t end up with a permanent growl on the screen. 

If your JavaScript implementation uses a different key for this then your system will need to factor that in.

=item (anything else your underlying javascript library can use)

I recommend leaving this to the templates and JavaScript to make maintenance easier and keep things consistent.

=back

=item growl_info()

Same as growl() but forces a type of 'info'.

=item growl_success()

Same as growl() but forces a type of 'success'.

=item growl_warning()

Same as growl() but forces a type of 'warning'.

=item growl_error()

Same as growl() but forces a type of 'danger' (That is from bootstrap convention).

=item growls()

For the consumer to use in its templates (though it is availaable in perl also).

It returns the list of growls (if any) and clears the list.

Each growl consists of two keys:

=over 4

=item 'message'

The message to display.

=item 'options'

The hashref of options for the view that can include 'delay' and 'allow_dismiss' noted above.

=back

See the SYNOPSIS for an example.

=back

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

=head1 CONFIGURATION AND ENVIRONMENT

Dancer2::Plugin::Growler requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Dancer2::Plugin>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-dancer2-plugin-growler@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<Dancer2::Plugin::Deferred> does a similar thing but, for my growling needs, it turned out to be overly complex and not flexible enough.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
