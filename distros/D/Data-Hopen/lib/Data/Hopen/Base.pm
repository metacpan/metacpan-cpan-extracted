# Data::Hopen::Base: common definitions for hopen.
# Thanks to David Farrell,
# https://www.perl.com/article/how-to-build-a-base-module/
# Copyright (c) 2018 Christopher White.  All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

package Data::Hopen::Base;
use parent 'Exporter';
use Import::Into;

our $VERSION = '0.000021';

# Pragmas
use 5.014;
use feature ":5.14";
use strict;
use warnings;
require experimental;

# Packages
use Data::Dumper;
use Carp;

# Definitions from this file
use constant {
    true => !!1,
    false => !!0,
};

our @EXPORT = qw(true false);
#our @EXPORT_OK = qw();
#our %EXPORT_TAGS = (
#    default => [@EXPORT],
#    all => [@EXPORT, @EXPORT_OK]
#);

#DEBUG
BEGIN {
    unless($SIG{'__DIE__'}) {
        $SIG{'__DIE__'} = sub { Carp::confess(@_) };
    }
    #$Exporter::Verbose=1;
}

sub import {
    my $target = caller;

    # Copy symbols listed in @EXPORT first, in case @_ gets trashed later.
    Data::Hopen::Base->export_to_level(1, @_);

    # Re-export pragmas
    feature->import::into($target, qw(:5.14));
    "$_"->import::into($target) foreach qw(strict warnings);

    # Re-export packages
    Data::Dumper->import::into($target);
    Carp->import::into($target, qw(carp croak confess));
} #import()

1;
__END__

=head1 NAME

Data::Hopen::Base - basic definitions for hopen

=head1 SYNOPSIS

C<use Data::Hopen::Base;> to pull in C<5.014>, L<strict>, L<warnings>,
L<Carp>, L<Data::Dumper>, C<true>, and C<false>.

NOTE: Modules also C<use strict> manually for the sake of Kwalitee.

=cut
