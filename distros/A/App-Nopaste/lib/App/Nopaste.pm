use strict;
use warnings;
package App::Nopaste; # git description: 1.012-12-g5acc073
# ABSTRACT: Easy access to any pastebin
# KEYWORDS: application executable paste output pastebin debugging

our $VERSION = '1.013';

use 5.008003;
use Module::Pluggable search_path => 'App::Nopaste::Service', sub_name => '_plugins';
use Class::Load 'load_class';
use namespace::clean 0.19;

use parent 'Exporter';
our @EXPORT_OK = 'nopaste';

sub plugins { goto \&_plugins };

sub nopaste {
    # process arguments
    # allow "nopaste($text)"
    unshift @_, 'text' if @_ == 1;

    # only look for $self if we have odd number of arguments
    my $self;
    $self = @_ % 2 ? shift : __PACKAGE__;

    # everything else
    my %args = @_;

    $args{services} = defined($ENV{NOPASTE_SERVICES})
                   && [split ' ', $ENV{NOPASTE_SERVICES}]
                        if !defined($args{services});

    $args{nick} = $ENV{NOPASTE_NICK} || $ENV{USER}
        if !defined($args{nick});


    my $using_default = 0;
    unless (ref($args{services}) eq 'ARRAY' && @{$args{services}}) {
        $using_default = 1;
        $args{services} = [ $self->plugins ];
    }

    @{ $args{services} }
        or Carp::croak "No App::Nopaste::Service module found";

    defined $args{text}
        or Carp::croak "You must specify the text to nopaste";

    $args{error_handler} ||= sub {
        my ($msg, $srv) = @_;
        $msg =~ s/\n*$/\n/;
        warn "$srv: $msg"
    };

    # try to paste to each service in order
    for my $service (@{ $args{services} }) {
        $service = "App::Nopaste::Service::$service"
            unless $service =~ /^App::Nopaste::Service/;

        no warnings 'exiting';
        my @ret = eval {

            local $SIG{__WARN__} = sub {
                $args{warn_handler}->($_[0], $service);
            } if $args{warn_handler};

            load_class($service);

            next unless $service->available(%args);
            next if $using_default && $service->forbid_in_default;
            $service->nopaste(%args);
        };

        @ret = (0, $@) if $@;

        # success!
        return $ret[1] if $ret[0];

        # failure!
        $args{error_handler}->($ret[1], $service);
    }

    Carp::croak "No available App::Nopaste::Service modules found";
}

1;

__END__

=pod

=encoding UTF-8

=for stopwords nopaste pastebin

=head1 NAME

App::Nopaste - Easy access to any pastebin

=head1 VERSION

version 1.013

=head1 SYNOPSIS

    use App::Nopaste 'nopaste';

    my $url = nopaste(q{
        perl -wle 'print "Prime" if (1 x shift) !~ /^1?$|^(11+?)\1+$/' [number]
    });

    # or on the command line:
    nopaste test.pl
    => http://pastebin.com/fcba51f

=head1 DESCRIPTION

Pastebins (also known as nopaste sites) let you post text, usually code, for
public viewing. They're used a lot in IRC channels to show code that would
normally be too long to give directly in the channel (hence the name nopaste).

Each pastebin is slightly different. When one pastebin goes down (I'm looking
at you, L<http://paste.husk.org>), then you have to find a new one. And if you
usually use a script to publish text, then it's too much hassle.

This module aims to smooth out the differences between pastebins, and provides
redundancy: if one site doesn't work, it just tries a different one.

It's also modular: you only need to put on CPAN a
L<App::Nopaste::Service::Foo> module and anyone can begin using it.

=head1 INTERFACE

=head2 CLI

See the documentation in L<App::Nopaste::Command>.

=head2 C<nopaste>

    use App::Nopaste 'nopaste';

    my $url = nopaste(
        text => "Full text to paste (the only mandatory argument)",
        desc => "A short description of the paste",
        nick => "Your nickname",
        lang => "perl",
        chan => "#moose",
        private => 1, # default: 0

        # this is the default, but maybe you want to do something different
        error_handler => sub {
            my ($error, $service) = @_;
            warn "$service: $error";
        },

        warn_handler => sub {
            my ($warning, $service) = @_;
            warn "$service: $warning";
        },

        # you may specify the services to use - but you don't have to
        services => ["Shadowcat", "Gist"],
    );

    print $url if $url;

The C<nopaste> function will return the URL of the paste on
success, or C<undef> on failure.

For each failure, the C<error_handler> argument is invoked with the error
message and the service that issued it.

For each warning, the C<warn_handler> argument is invoked with the warning
message and the service that issued it.

=head1 SEE ALSO

L<WebService::NoPaste>, L<WWW::Pastebin::PastebinCom::Create>, L<Devel::REPL::Plugin::Nopaste>

L<http://perladvent.org/2011/2011-12-14.html>

=head1 COPYRIGHT AND LICENSE

Copyright 2008- Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=App-Nopaste>
(or L<bug-App-Nopaste@rt.cpan.org|mailto:bug-App-Nopaste@rt.cpan.org>).

=head1 AUTHOR

Shawn M Moore, <sartak@gmail.com>

=head1 CONTRIBUTORS

=for stopwords Shawn M Moore Karen Etheridge Thomas Sibley Ricardo Signes François Gannaz Justin Hunter Kevin Falcone Zoffix Znet Jesse Luehrs Dean Hamstead David Golden Rafael Kitover Sergey Romanov Zakariyya Mughal gregor herrmann vti Ævar Arnfjörð Bjarmason Сергей Романов Andrew Rodland יובל קוג'מן (Yuval Kogman) Arthur Axel 'fREW' Schmidt Dan Book Darian Anthony Patrick Bremner J. Shultz Graham Knop Jason Mills John Goulah Maximilian Gass Sebastian Paaske Tørholm Shlomi Fish Tatsuhiko Miyagawa

=over 4

=item *

Shawn M Moore <code@sartak.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Thomas Sibley <tsibley@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

François Gannaz <francois.gannaz@silecs.info>

=item *

Justin Hunter <justin.d.hunter@gmail.com>

=item *

Kevin Falcone <kevin@jibsheet.com>

=item *

Zoffix Znet <cpan@zoffix.com>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Dean Hamstead <dean@fragfest.com.au>

=item *

David Golden <dagolden@cpan.org>

=item *

Rafael Kitover <rkitover@cpan.org>

=item *

Sergey Romanov <complefor@rambler.ru>

=item *

Zakariyya Mughal <zaki.mughal@gmail.com>

=item *

gregor herrmann <gregoa@debian.org>

=item *

vti <viacheslav.t@gmail.com>

=item *

Ævar Arnfjörð Bjarmason <avarab@gmail.com>

=item *

Сергей Романов <sromanov@cpan.org>

=item *

Andrew Rodland <andrew@cleverdomain.org>

=item *

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=item *

Arthur Axel 'fREW' Schmidt <frioux@gmail.com>

=item *

Dan Book <grinnz@gmail.com>

=item *

Darian Anthony Patrick <dap@darianpatrick.com>

=item *

David Bremner <bremner@unb.ca>

=item *

David J. Shultz <djshultz@gmail.com>

=item *

Graham Knop <haarg@haarg.org>

=item *

Jason Mills <jmmills@cpan.org>

=item *

John Goulah <jgoulah@gmail.com>

=item *

Maximilian Gass <mxey@ghosthacking.net>

=item *

Sebastian Paaske Tørholm <Eckankar+github@gmail.com>

=item *

Shlomi Fish <shlomif@shlomifish.org>

=item *

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
