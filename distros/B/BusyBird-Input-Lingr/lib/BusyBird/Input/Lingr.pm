package BusyBird::Input::Lingr;
use 5.010;
use strict;
use warnings;
use Carp;
use DateTime::Format::ISO8601;
use BusyBird::DateTime::Format;

our $VERSION = "0.02";

my $PARSER = DateTime::Format::ISO8601->new;

sub new {
    my ($class, %args) = @_;
    my $api_base = $args{api_base} // "http://lingr.com/api";
    $api_base =~ qr{^(https?://[^/]+)};
    my $url_base = $1;
    my $self = bless {
        url_base => $url_base
    }, $class;
    return $self;
}

sub convert {
    my ($self, @messages) = @_;
    my @statuses = map { $self->_convert_one($_) } @messages;
    return wantarray ? @statuses : $statuses[0];
}

sub _convert_one {
    my ($self, $message) = @_;
    croak "message must be a HASH-ref" if !defined($message) || ref($message) ne "HASH";
    croak "timestamp field was empty" if !defined($message->{timestamp});
    croak "id field was empty" if !defined($message->{id});
    my $time = $PARSER->parse_datetime($message->{timestamp});
    croak "Invalid timestamp format" if !defined($time);
    my $permalink = sprintf('%s/room/%s/archives/%04d/%02d/%02d#message-%s',
                            $self->{url_base}, $message->{room},
                            $time->year, $time->month, $time->day, $message->{id});
    return {
        id => $permalink,
        created_at => BusyBird::DateTime::Format->format_datetime($time),
        user => {
            profile_image_url => $message->{icon_url},
            screen_name => $message->{speaker_id},
            name => $message->{nickname},
        },
        text => $message->{text},
        busybird => {
            status_permalink => $permalink
        }
    };
}

1;
__END__

=pod

=head1 NAME

BusyBird::Input::Lingr - import Lingr chat texts into BusyBird

=head1 SYNOPSIS

    use BusyBird;
    use WebService::Lingr::Archives;
    use BusyBird::Input::Lingr;
    
    my $downloader = WebService::Lingr::Archives->new(
        user => 'your lingr username',
        passworkd => 'your lingr password',
    );
    my $input = BusyBird::Input::Lingr->new;
    
    my @raw_messages = $downloader->get_archives("perl_jp");
    my @busybird_statuses = $input->convert(@raw_messages);
    
    timeline("perl_jp_chat")->add(\@busybird_statuses);

=head1 DESCRIPTION

L<BusyBird::Input::Lingr> converts text message objects obtained from Lingr (L<http://lingr.com/>) API into L<BusyBird> status objects.

Note that this module does not download messages from Lingr.
For that purpose, use L<WebService::Lingr::Archives> or L<AnyEvent::Lingr>.

=head1 CLASS METHODS

=head2 $input = BusyBird::Input::Lingr->new(%args)

The constructor.

Fields in C<%args> are:

=over

=item C<api_base> => STR (optional, default: "http://lingr.com/api")

Lingr API base URL. This field is used to create permalinks.

=back

=head1 OBJECT METHODS

=head2 @busybird_statuses = $input->convert(@lingr_messages)

Convert Lingr message objects into L<BusyBird> status objects.

If called in scalar context, it returns the first status object.

If there is an invalid message in C<@lingr_messages>, this method croaks.

=head1 SEE ALSO

=over

=item *

L<BusyBird>

=item *

L<WebService::Lingr::Archives>

=item *

L<AnyEvent::Lingr>

=back

=head1 REPOSITORY

L<https://github.com/debug-ito/BusyBird-Input-Lingr>

=head1 BUGS AND FEATURE REQUESTS

Please report bugs and feature requests to my Github issues
L<https://github.com/debug-ito/BusyBird-Input-Lingr/issues>.

Although I prefer Github, non-Github users can use CPAN RT
L<https://rt.cpan.org/Public/Dist/Display.html?Name=BusyBird-Input-Lingr>.
Please send email to C<bug-BusyBird-Input-Lingr at rt.cpan.org> to report bugs
if you do not have CPAN RT account.


=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

