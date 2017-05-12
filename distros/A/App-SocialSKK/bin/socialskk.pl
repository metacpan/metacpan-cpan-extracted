#!/usr/bin/env perl
use strict;
use warnings;
use YAML::Syck;
use File::Spec;
use File::HomeDir;
use Getopt::Long;
use Sys::Hostname;
use Pod::Usage;
use POE qw(Component::Server::TCP Filter::Stream);

use App::SocialSKK;

my %options = (
    config   => File::Spec->catfile(File::HomeDir->my_home, '.socialskk'),
    port     => 1179,
    address  => '127.0.0.1',
    hostname => Sys::Hostname::hostname(),
    help     => undef,
);

GetOptions(
    'config=s'   => \$options{config},
    'hostname=s' => \$options{hostname},
    'address=s'  => \$options{address},
    'port=i'     => \$options{port},
    'help'       => \$options{help},
);

pod2usage(2) if $options{help};

# use Social IME as a default backend
my $config = {
    plugins => [
        { name => 'SocialIME' },
    ],
};

$config =  YAML::Syck::LoadFile($options{config}) if -e $options{config};
my $app = App::SocialSKK->new({(%options, config => $config)});

POE::Component::Server::TCP->new(
    Port         => $options{port},
    Address      => $options{address},
    Hostname     => $options{hostname},
    ClientFilter => POE::Filter::Stream->new,
    ClientInput  => sub {
        my ($kernel, $heap, $input)  = @_[KERNEL, HEAP, ARG0];
        if ($input =~ /^0/) {
            $kernel->yield('shutdown');
            return;
        }
        my $result = $app->protocol->accept($input);
        if (defined $result) {
            $heap->{client}->put($result);
        }
    },
);

POE::Kernel->run;
exit;

__END__

=head1 NAME

socialskk.pl - Yet Another skkserv Implementation

=head1 SYNOPSIS

  socialskk.pl [-c|config file] [-p|port number] [--help]

  Options:
    -c --config: configuration file
    -p --port  : port number
       --help  : show usage

=head1 DESCRIPTION

socialskk.pl works as a SKK dictionary server which performs searches
for candidates and returns results along with requests from client.

=head1 OPTIONS

=over 4

=item -c|--config

Sets a path to configuration file. If not set, socialskk.pl tries to
load $HOME/.socialskk instead.

=item -p|--port

Sets a number of port used by the server.

=item --help

Shows this help document.

=back

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE (The MIT License)

Copyright (c) Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
