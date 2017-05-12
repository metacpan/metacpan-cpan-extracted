package DBIx::Class::TimeStamp::HiRes;

use warnings;
use strict;

use DateTime::HiRes;
use base 'DBIx::Class::TimeStamp';

use version 0.77; our $VERSION = qv('v1.0.1');

sub get_timestamp {
    return DateTime::HiRes->now();
}

1;
__END__

=head1 NAME

DBIx::Class::TimeStamp::HiRes - Like DBIC TimeStamp but in HiRes


=head1 VERSION

This document describes DBIx::Class::TimeStamp::HiRes version 1.0.0


=head1 SYNOPSIS

__PACKAGE__->load_components( qw/ TimeStamp::HiRes /);


=head1 DESCRIPTION

Extends DBIx::Class::TimeStamp and overrides its get_timestamp method with
DateTime::HiRes


=head1 SUBROUTINES/METHODS

=head2 get_timestamp

Returns a DataTime::HiRes->now() timestamp


=head1 DIAGNOSTICS

None


=head1 CONFIGURATION AND ENVIRONMENT

DBIx::Class::TimeStamp::HiRes requires no configuration files or environment variables.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.


=head1 AUTHOR

John Judd C<< <funkyshu@dark-linux.com> >>
