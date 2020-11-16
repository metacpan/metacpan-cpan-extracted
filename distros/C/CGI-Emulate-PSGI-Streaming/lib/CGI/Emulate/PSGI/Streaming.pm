package CGI::Emulate::PSGI::Streaming;
use strict;
use warnings;
our $VERSION = '1.0.1'; # VERSION
use parent 'CGI::Emulate::PSGI';
use CGI::Parse::PSGI::Streaming;
use SelectSaver;
use Carp qw(croak);
use 5.008001;

# ABSTRACT: streaming PSGI adapter for CGI


sub handler {
    my ($class, $code) = @_;

    # this closure is the PSGI application
    return sub {
        my $env = shift;

        # this is the PSGI response, as a coderef because we want to
        # have it streaming; as the PSGI spec says, it will be invoked
        # by the backend, once per request, with a responder callback
        return sub {
            my ($responder) = @_;

            # we have the responder (i.e. the thing we will send the
            # response to), so we can now build the output filehandle
            my $stdout = CGI::Parse::PSGI::Streaming::parse_cgi_output_streaming_fh($responder);

            my $saver = SelectSaver->new("::STDOUT");
            # emulate_environment comes from CGI::Emulate::PSGI
            local %ENV = (%ENV, $class->emulate_environment($env));

            local *STDIN  = $env->{'psgi.input'};
            local *STDOUT = $stdout;
            local *STDERR = $env->{'psgi.errors'};

            # call the CGI code, and let it print to its heart's content
            $code->();
            # explicit close, to make sure the response is finalised
            close $stdout;
        };
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CGI::Emulate::PSGI::Streaming - streaming PSGI adapter for CGI

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

  my $app = CGI::Emulate::PSGI::Streaming->handler(sub {
    # Existing CGI code
  });

=head1 DESCRIPTION

This module allows an application designed for the CGI environment to
run in a PSGI environment, and thus on any of the backends that PSGI
supports.

It is a subclass of L<< C<CGI::Emulate::PSGI> >>. The parsing logic is
implemented in L<< C<CGI::Parse::PSGI::Streaming> >>, which is heavily
based on L<< C<CGI::Parse::PSGI> >>.

Please note that using the PSGI application produced by this module
under a non-streaming backend will probably not work.

=head1 METHODS

=head2 C<handler>

  my $app = CGI::Emulate::PSGI::Streaming->handler($code);

Creates a streaming PSGI application code reference out of CGI code
reference.

=head1 CGI.pm

(This section is copied from L<<
C<CGI::Emulate::PSGI>|CGI::Emulate::PSGI/CGI.pm >>)

If your application uses L<CGI>, be sure to cleanup the global
variables in the handler loop yourself, so:

    my $app = CGI::Emulate::PSGI::Streaming->handler(sub {
        use CGI;
        CGI::initialize_globals();
        my $q = CGI->new;
        # ...
    });

Otherwise previous request variables will be reused in the new
requests.

=head1 SEE ALSO

L<< C<CGI::Emulate::PSGI> >>  L<< C<CGI::Parse::PSGI::Streaming> >>
L<< C<PSGI> >> L<< C<Plack> >>

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Broadbean.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
