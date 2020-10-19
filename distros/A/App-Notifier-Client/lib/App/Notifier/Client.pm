package App::Notifier::Client;
$App::Notifier::Client::VERSION = '0.0401';
use strict;
use warnings;

use 5.012;

use LWP::UserAgent;
use URI;

use JSON::MaybeXS qw(encode_json);

sub notify
{
    my $class = shift;

    my ($args) = @_;

    my $base_url = $args->{base_url};
    my $cmd_id   = $args->{cmd_id};
    my $msg      = $args->{msg};

    my $ua = LWP::UserAgent->new;
    my $url =
        URI->new( $base_url . ( $base_url =~ m#/\z# ? '' : '/' ) . 'notify' );

    my $query = [];

    if ( defined($cmd_id) )
    {
        push @$query, ( cmd_id => $cmd_id );
    }

    if ( defined($msg) )
    {
        push @$query,
            ( text_params => scalar( encode_json( { msg => $msg, } ) ) );
    }

    $url->query_form($query);

    my $response = $ua->get($url);

    if ( !$response->is_success() )
    {
        die "Error " . $response->status_line();
    }

    return $response->content();
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::Notifier::Client - a client library for App::Notifier::Service

=head1 VERSION

version 0.0401

=head1 SYNOPSIS

    use App::Notifier::Client;

    App::Notifier::Client->notify(
        {
            base_url => 'http://localhost:6300/',
            cmd_id => 'shine',
        }
    );

    # Without cmd_id.
    App::Notifier::Client->notify(
        {
            base_url => 'http://localhost:6300/',
        }
    );

    # With a msg
    App::Notifier::Client->notify(
        {
            base_url => 'http://localhost:6300/',
            msg => "Compilation Finished",
        }
    );
    1;

=head1 DESCRIPTION

This module is used to invoke a notification at a remote
L<App::Notifier::Service> . It provides one class method - notify() .

=head1 METHODS

=head2 App::Notifier::Client->notify({ base_url => $url })

Sends a notification to the service at the base_url of $url .
If C<'cmd_id'> is specified, it is also used (see the synopsis). If
C<'msg'> is specified, it is sent as well.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2012 Shlomi Fish.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-Notifier-Client>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Notifier-Client>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-Notifier-Client>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-Notifier-Client>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-Notifier-Client>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::Notifier::Client>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-notifier-client at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-Notifier-Client>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/app-notifier>

  git clone git://github.com/shlomif/app-notifier.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Notifier-Client> or by email
to
L<bug-app-notifier-client@rt.cpan.org|mailto:bug-app-notifier-client@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
