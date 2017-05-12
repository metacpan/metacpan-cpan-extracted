package AnyEvent::Net::Curl::Queued::Stats;
# ABSTRACT: Connection statistics for AnyEvent::Net::Curl::Queued::Easy


use strict;
use utf8;
use warnings qw(all);

use AnyEvent;
use Carp qw(confess);
use Moo;
use MooX::Types::MooseLike::Base qw(HashRef Num);

use AnyEvent::Net::Curl::Const;

our $VERSION = '0.047'; # VERSION


has stamp       => (is => 'ro', isa => Num, default => sub { AE::time }, writer => 'set_stamp');


has stats       => (
    is          => 'ro',
    isa         => HashRef[Num],
    default     => sub { {
        appconnect_time     => 0,
        connect_time        => 0,
        header_size         => 0,
        namelookup_time     => 0,
        num_connects        => 0,
        pretransfer_time    => 0,
        redirect_count      => 0,
        redirect_time       => 0,
        request_size        => 0,
        size_download       => 0,
        size_upload         => 0,
        starttransfer_time  => 0,
        total_time          => 0,
    } },
);


sub sum {
    my ($self, $from) = @_;

    my $is_stats = (__PACKAGE__ eq ref $from) ? 1 : 0;
    for my $type (keys %{$self->stats}) {
        $self->stats->{$type} +=
            $is_stats
                ? $from->stats->{$type}
                : $from->getinfo(AnyEvent::Net::Curl::Const::info($type));
    }

    $self->set_stamp(AE::time);

    return 1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Net::Curl::Queued::Stats - Connection statistics for AnyEvent::Net::Curl::Queued::Easy

=head1 VERSION

version 0.047

=head1 SYNOPSIS

    use AnyEvent::Net::Curl::Queued;
    use Data::Printer;

    my $q = AnyEvent::Net::Curl::Queued->new;
    #...
    $q->wait;

    p $q->stats;

    $q->stats->sum(AnyEvent::Net::Curl::Queued::Stats->new);

=head1 WARNING: GONE MOO!

This module isn't using L<Any::Moose> anymore due to the announced deprecation status of that module.
The switch to the L<Moo> is known to break modules that do C<extend 'AnyEvent::Net::Curl::Queued::Easy'> / C<extend 'YADA::Worker'>!
To keep the compatibility, make sure that you are using L<MooseX::NonMoose>:

    package YourSubclassingModule;
    use Moose;
    use MooseX::NonMoose;
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

Or L<MouseX::NonMoose>:

    package YourSubclassingModule;
    use Mouse;
    use MouseX::NonMoose;
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

Or the L<Any::Moose> equivalent:

    package YourSubclassingModule;
    use Any::Moose;
    use Any::Moose qw(X::NonMoose);
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

However, the recommended approach is to switch your subclassing module to L<Moo> altogether (you can use L<MooX::late> to smoothen the transition):

    package YourSubclassingModule;
    use Moo;
    use MooX::late;
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

=head1 DESCRIPTION

Tracks statistics for L<AnyEvent::Net::Curl::Queued> and L<AnyEvent::Net::Curl::Queued::Easy>.

=head1 ATTRIBUTES

=head2 stamp

Unix timestamp for statistics update.

=head2 stats

C<HashRef[Num]> with statistics:

    appconnect_time
    connect_time
    header_size
    namelookup_time
    num_connects
    pretransfer_time
    redirect_count
    redirect_time
    request_size
    size_download
    size_upload
    starttransfer_time
    total_time

Variable names are from respective L<curl_easy_getinfo()|http://curl.haxx.se/libcurl/c/curl_easy_getinfo.html> accessors.

=head1 METHODS

=head2 sum($from)

Aggregate attributes from the C<$from> object.
It is supposed to be an instance of L<AnyEvent::Net::Curl::Queued::Easy> or L<AnyEvent::Net::Curl::Queued::Stats>.

=head1 SEE ALSO

=over 4

=item *

L<AnyEvent::Net::Curl::Queued::Easy>

=item *

L<AnyEvent::Net::Curl::Queued>

=back

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stanislaw Pusep.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
