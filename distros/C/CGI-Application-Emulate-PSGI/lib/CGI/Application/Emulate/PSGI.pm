package CGI::Application::Emulate::PSGI;

use 5.008;
use strict;
use warnings;
use CGI;
use CGI::Emulate::PSGI;
use CGI::Parse::PSGI;

our $VERSION = '0.02';

sub handler {
    my ($class, $code,) = @_;
    
    return sub {
        my $env = shift;
        my $output = do {
            local %ENV = (
                %ENV,
                CGI::Emulate::PSGI->emulate_environment($env),
                CGI_APP_RETURN_ONLY => 1,
            );
            local *STDIN  = $env->{'psgi.input'};
            local *STDERR = $env->{'psgi.errors'};
            CGI::initialize_globals();
            $code->();
        };
        return CGI::Parse::PSGI::parse_cgi_output(\$output);
    };
}

1;
__END__

=head1 NAME

CGI::Application::Emulate::PSGI - a legacy-code-friendly PSGI adapter for CGI::Application

=head1 SYNOPSIS

Create a PSGI application from a L<CGI::Application> project:

    # if using CGI::Application
    my $psgi_app = CGI::Application::Emulate::PSGI->handler(sub {
        my $webapp = WebApp->new();
        $webapp->run();
    });

    # if using CGI::Application::Dispatch
    my $psgi_app = CGI::Application::Emulate::PSGI->handler(sub {
        WebApp::Dispatch->dispatch();
    });

See L<plackup> for options for running a PSGI application.

=head1 DESCRIPTION

CGI::Application::Emulate::PSGI allows a project based on L<CGI::Application> to run as a PSGI application.  Differences from L<CGI::Application::PSGI> are:

=over 4

=item uses L<CGI.pm> directly instead of L<CGI::PSGI>

L<CGI::Application::PSGI> (that uses L<CGI::PSGI>) does not support programs calling L<CGI.pm> in func-style (like CGI::virtual_host()).  CGI::Application::Emulate::PSGI sets up environment variables so that code using L<CGI.pm> will work. Both approaches explictly use CGI.pm as the query object.

=item compatible with L<CGI::Application::Dispatch>

The interface of CGI::Application::Emulate::PSGI is different from L<CGI::Application::PSGI>, and is compatible with L<CGI::Application::Dispatch>.

=item headers are parsed and re-generated.

This difference is in favor of L<CGI::Application::PSGI>, which more directly generates the HTTP headers in PSGI format. This module
requires additional processing: First CGI::Application builds the full response including the headers and body, then we parse the final result back into the header and body format called for by the PSGI spec.

=back

=head1 AUTHOR

Kazuho Oku E<lt>kazuhooku@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Application::PSGI>, L<CGI>


=cut
