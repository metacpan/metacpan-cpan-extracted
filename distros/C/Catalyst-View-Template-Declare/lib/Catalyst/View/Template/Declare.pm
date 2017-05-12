package Catalyst::View::Template::Declare;
use strict;
use warnings;
use base qw(Catalyst::View::Templated);
use Class::C3;
require Module::Pluggable::Object;

our $VERSION = '0.04';

sub COMPONENT {
    my $self  = shift;
    my $c     = shift;
    my $class = ref $self || $self;

    # find sub-templates
    my $mpo = Module::Pluggable::Object->new(require     => 0,
                                             search_path => $class,
                                            );

    # load sub-templates (and do a bit of magic niceness)
    my @extras = $mpo->plugins;
    foreach my $extra (@extras) {
        $c->log->info("Loading subtemplate $extra");

        # load module
        if (!eval "require $extra"){
            die "Couldn't include $extra: $@";
        }

        # make the templates a subclass of TD (required by TD)
        {
            no strict 'refs';
            push @{$extra. "::ISA"}, 'Template::Declare';
        }

    }

    # init Template::Declare
    Template::Declare->init(roots => [$class, @extras]);

    # init superclasses
    $self->next::method($c, @_);
}

sub _render {
    my ($self, $template) = (shift, shift);

    Template::Declare->new_buffer_frame;
    local *_ = $_[0];
    my $out = Template::Declare->show($template, $self->context, @_);
    Template::Declare->end_buffer_frame;

    $out =~ s/^\n+//g; # kill leading newlines
    return $out;
}

package c;
use PadWalker qw(peek_my);
our $AUTOLOAD;
sub AUTOLOAD {
    shift; # kill class

    # walk up the stack looking for the Catalyst context
    # in a lexical somewhere (evil, yes.)
    my $frames_up = 1;
    my $context;
    while($frames_up < 300 && !$context){
        ($context) =
          map { $$_ }
            grep {eval{$$_->isa('Catalyst')}}
              values %{peek_my($frames_up++)};
    }
    die "INTERNAL ERROR: No Catalyst context found!" if !$context;

    $AUTOLOAD =~ s/^c:://; # kill package c
    return $context->$AUTOLOAD(@_);
}

1;
__END__

=head1 NAME

Catalyst::View::Template::Declare - Use Template::Declare with Catalyst

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Create the view:

     myapp_create.pl view TD Template::Declare

Add templates in C<< MyApp::View::TD::<name> >>:

     package MyApp::View::TD::Test;
     use Template::Declare::Tags;

     template foo => sub { html {} };
     template bar => sub {   ...   };
     1;

Then use the templates from your application:

     $c->view('TD')->template('foo');
     $c->detach('View::TD');

The Catalyst context is passed as the second agument to the templates:

     template foo => sub {
         my ($self, $c) = @_;
         return 'This is the '. $c->action. ' action.';
     };

The Catalyst stash is passed as the third argument, but is also
available via the glocal C<$_> variable for the duration of the
template:

     template bar => sub {
         return "Hello, $_{world}";
     };

Have fun.  This is all somewhat experimental and subject to change.

=head1 DESCRIPTION

Make a view:

    package MyApp::View::TD;
    use base 'Catalyst::View::Template::Declare';
    1;

Make a template:

    package MyApp::View::TD::Root;
    use Template::Declare::Tags;

    template foo => sub {
        my ($self, $c) = @_;
        html {
            head { title { $c->stash->{title} } };
            body { "Hello, world" }
          }
    };

In your app:

    $c->view('TD')->template('foo');
    $c->stash(title => 'test');
    $c->detach('View::TD');

And get the output:

    <html><head><title>test</title></head><body>Hello, world</body></html>

You can spread your templates out over multiple files.  If your
view is called MyApp::View::TD, then everything in MyApp::View::TD::*
will be included and templates declared in those files will be available
as though they were declared in your main view class.

Example:

    package MyApp::View::TD::Foo;
    use Template::Declare::Tags;
    template bar => sub { ... };
    1;

Then you can set C<< $c->view('TD')->template('bar') >> and everything
will work as you expect.

The arguments passed to the templates are:

=over

=item C<$self>

The object or package name in which the template is defined.

=item C<$c>

The Catalyst context object.

=item C<$stash>

A copy of the Catalyst stash, also available via C<$_>. Modifications to this
copy of the stash will have no effect on the contents of C<< $c->stash >>.

=item C<$args>

Any arguments passed to C<render()>.

=back

For those stuck with a version of Template::Declare older then 0.26, no
arguments will be passed to the templates. But you can still use the
otherwise-deprecated C<c> package to get at the Catalyst context:

    template bar => sub { "Hello, ". c->stash->{world} };

=head1 METHODS

=head2 process

Render the template in C<< $self->template >>; see
L<Catalyst::View::Templated> for information on how to specify the
template.

=head2 render($template, @args)

Render the template named by C<$template> and return the output.

=head2 COMPONENT

Not for you.

=head1 AUTHOR

Jonathan Rockway, C<< <jrockway at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-view-template-declare at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-View-Template-Declare>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

Visit #catalyst on irc.perl.org, submit an RT ticket, or send me an e-mail.

The git repository is at L<http://git.jrock.us/>.

=head1 SEE ALSO

L<Catalyst::View::Templated>

=head1 ACKNOWLEDGEMENTS

L<Template::Declare>

L<Jifty>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jonathan Rockway, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


