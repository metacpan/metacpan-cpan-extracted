package CatalystX::REPL;
our $VERSION = '0.04';

# ABSTRACT: read-eval-print-loop for debugging your Catalyst application

use Moose::Role;
use Carp::REPL ();
use Catalyst::Utils;

use namespace::autoclean;


# Normally we'd hook into setup_finalize, but unfortunately for us Class::MOP
# localizes $SIG{__DIE__}, which Carp::REPL relies on, during load_class. That
# way the die handler will only be set up between between finishing setup and
# until after the run time of MyApp.pm ends, when MyApp is loaded with
# load_class, which it often is, for example in Catalyst::Test. Because of that
# we hook in at the start of each request and install our handler. This isn't
# too bad. After all, we're a debugging only tool. We could play some tricks to
# do this only once, before the first request and avoid reinstalling the
# handler on every subsequent request, but given we're a role, and we don't
# have a MyApp instance to store attributes in, we don't even try.

before prepare => sub {
    my ($self) = @_;
    if (my $repl_options = Catalyst::Utils::env_value($self, 'repl')) {
        Carp::REPL->import(split q{,}, $repl_options);
    }
};

1;

__END__

=pod

=head1 NAME

CatalystX::REPL - read-eval-print-loop for debugging your Catalyst application

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    package MyApp;

    use Moose;

    # Requires Catalyst 5.8 series
    extends 'Catalyst';
    with 'CatalystX::REPL';

    __PACKAGE__->setup(qw/-Debug/);

    1;

=head1 DESCRIPTION

Using L<Carp::REPL|Carp::REPL> with a Catalyst application is hard. That's
because of all the internal exceptions that are being thrown and caught by
Catalyst during application startup. You'd have to manually skip over all of
those.

This role works around that by automatically setting up Carp::REPL after
starting your application, if the C<CATALYST_REPL> or C<MYAPP_REPL> environment
variables are set:

 MYAPP_REPL=1 ./script/myapp_server.pl
 # Hit an action
 ...

 42 at lib/MyApp/Controller/Foo.pm line 8.

 # instead of exiting, you get a REPL!
 Trace begun at lib/MyApp/Controller/Foo.pm line 8
 MyApp::Controller::Foo::bar('MyApp::Controller::Foo=HASH(0xc9fe20)', 'MyApp=HASH(0xcea6a4)') called at ...
 ... # Many more lines of stack trace

 $ $c
 MyApp=HASH(0xcea6ec)
 $ $c->req->uri
 http://localhost/foo/bar
 $

Options like C<warn> or C<nodie> can be passed to Carp::REPL by putting them,
seperated by commas, into the environment variable:

 MYAPP_REPL=warn,nodie ./script/myapp_server.pl

Carp::REPL uses L<Devel::REPL> for the shell, so direct any questions how how
to use or customize the repl at that module.

=head1 SEE ALSO

L<Carp::REPL>

L<Devel::REPL>



=head1 AUTHORS

  Tomas Doran <bobtfish@bobtfish.net>
  Florian Ragwitz <rafl@debian.org>
  Ash Berlin <ash@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 


