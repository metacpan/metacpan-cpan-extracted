package App::Oozie::Types::DateTime;
$App::Oozie::Types::DateTime::VERSION = '0.002';
use 5.010;
use strict;
use warnings;

use App::Oozie::Date;
use Date::Parse ();
use DateTime    ();

use Type::Library -base;
use Type::Tiny;
use Type::Utils -all;
use Sub::Quote qw( quote_sub );

BEGIN {
    extends 'Types::Standard';
}

declare IsHour => as Int,
    constraint => quote_sub q{
        my $val = shift;
        return if  $val !~ /^[0-9]+$/
                    || $val < 0
                    || $val > 23;
        return 1;
    },
;

declare IsMinute => as Int,
    constraint => quote_sub q{
        my $val = shift;
        return if  $val !~ /^[0-9]+$/
                    || $val < 0
                    || $val > 59;
        return 1;
    },
;

declare IsDate => as Str,
    constraint => quote_sub q{
        my $val = shift;
        # The TZ values doesn't matter in here as this is only
        # doing a syntactical check
        state $date     = App::Oozie::Date->new( timezone => 'UTC' );
        state $is_short = { map { $val => 1 } $date->SHORTCUT_METHODS };
        return if ! $val;
        return 1 if $is_short->{ $val };
        return if ! $date->is_valid( $val );
        return 1;
    },
;

declare IsDateStr => as Str,
    constraint => quote_sub q{
        my $val = shift;
        return if ! $val;
        return Date::Parse::str2time $val;
    },
;

declare IsTZ => as Str,
    constraint => quote_sub q{
        my $val = shift || return;
        eval {
            DateTime->now( time_zone => $val );
            1;
        };
    },
;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Types::DateTime

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use  App::Oozie::Types::DateTime qw( IsDate );

=head1 DESCRIPTION

Internal types.

=head1 NAME

App::Oozie::Types::DateTime - Internal types.

=head1 Types

=head2 IsDate

=head2 IsDateStr

=head2 IsHour

=head2 IsMinute

=head2 IsTZ

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
