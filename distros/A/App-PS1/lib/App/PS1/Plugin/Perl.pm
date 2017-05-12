package App::PS1::Plugin::Perl;

# Created on: 2011-06-21 09:48:47
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use Carp;
use English qw/ -no_match_vars /;

our $VERSION     = 0.04;
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();
#our @EXPORT      = qw//;

sub perl {
    my ($self, $options) = @_;
    my $path = $ENV{PERLBREW_PERL};
    return if !$path;

    my ($version) = $path =~ /perl-(.*)$/;

    return $self->surround(
        5 + length $version,
        $self->colour('branch_label') . 'perl ' . $self->colour('branch') . $version
    );
}

1;

__END__

=head1 NAME

App::PS1::Plugin::Perl - Shows current version of Perl if using perlbrew

=head1 VERSION

This documentation refers to App::PS1::Plugin::Perl version 0.04.

=head1 SYNOPSIS

   use App::PS1::Plugin::Perl;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<perl ()>

Determines the current version of Perl if using L<perlbrew>

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
