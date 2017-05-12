# $Id: /mirror/perl/DateTime-Format-RSS/trunk/lib/DateTime/Format/RSS.pm 63379 2008-06-17T20:51:20.618065Z daisuke  $
#
# Copyright (c) 2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package DateTime::Format::RSS;
use strict;
use warnings;
use vars qw($VERSION);
use DateTime::Format::Mail;
use DateTime::Format::ISO8601;
use DateTime::Format::DateParse;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors($_) for qw(parsers version);

BEGIN
{
    $VERSION = '0.03000';
}

sub new
{
    my $class = shift;
    my %args  = @_;
    my $self  = $class->SUPER::new({
        version => $args{version} || '1.0',
        parsers => [
            # order matters
            DateTime::Format::Mail->new,
            DateTime::Format::ISO8601->new,
            'DateTime::Format::DateParse',
        ]
    });
    return $self;
}

sub parse_datetime
{
    my $self = shift;
    my $date = shift;
    if (! ref($self)) {
        $self = $self->new();
    }

    my $dt;
    foreach my $p (@{$self->parsers}) {
        $dt = eval { $p->parse_datetime($date) };
        last if $dt;
    }
    return $dt;
}

sub format_datetime
{
    my $self = shift;
    if ($self->version eq '2.0') {
        return $self->parsers->[0]->format_datetime($_[0]);
    } else {
        return $_[0]->iso8601;
    }
}

1;

__END__

=head1 NAME

DateTime::Format::RSS - Format DateTime For RSS 

=head1 SYNOPSIS

  use DateTime::Format::RSS;
  my $fmt = DateTime::Format::RSS->new;
  my $dt  = $fmt->parse_datetime($str);
  my $str = $fmt->format_datetime($dt);

  my $fmt = DateTime::Format::RSS->new(version => 2.0);

=head1 DESCRIPTION

DateTime::Format::RSS attempts to deal with those nasty RSS date/time strings used in fields (such as E<lt>issuedE<gt>, E<lt>modifiedE<gt>, E<lt>pubDateE<gt>)
that never ever seems to be right.

=head1 METHODS

=head2 new

Creates a new DateTime::Format::RSS object

=head2 parse_datetime SCALAR

Internally, it just attempts to parse the string using DateTime::Format::Mail,
DateTime::Format::ISO8601, and then finally with DateTime::Format::DateParse.

=head2 format_datetime OBJECT

Formats the given DateTime object using DateTime::Format::ISO8601

=head1 CREDITS

This module was based on L<Plagger|Plagger>'s LiberalDateTime DateTime
parser.

=head1 SEE ALSO

L<DateTime::Format::Mail|DateTime::Format::Mail>
L<DateTime::Format::IOS8601|DateTime::Format::IOS8601>
L<DateTime::Format::DateParse|DateTime::Format::DateParse>

=head1 AUTHORS

Copyright (c) 2006 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt> All rights reserved.
Tatsuhiko Miyagawa <miyagawa@bulknews.netE<gt> All rights reserved.

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut