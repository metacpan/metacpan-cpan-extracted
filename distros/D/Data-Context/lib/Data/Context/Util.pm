package Data::Context::Util;

# Created on: 2012-04-12 15:59:08
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Scalar::Util qw/blessed/;
use List::Util;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Class::Inspector;
use base qw/Exporter/;

our $VERSION   = version->new('0.3');
our @EXPORT_OK = qw/lol_path lol_iterate do_require/;

sub lol_path {
    my ($lol, $path) = @_;
    my @path = split /[.]/xms, $path;
    my $point = $lol;
    my $replacer;

    if ( ! @path ) {
        my $replacer = sub { confess "Can't replace '$path'!\n" };
        if ( ref $lol eq 'HASH' ) {
            $replacer = sub {
                %$lol = %{ $_[0] };
            };
        }
        elsif ( ref $lol eq 'ARRAY' ) {
            $replacer = sub {
                @$lol = @{ $_[0] };
            };
        }
        return wantarray ? ( $lol, $replacer ) : $lol;
    }

    POINT:
    while ( $point && @path ) {

        # ignore empty path parts
        if ( $path[0] eq '' ) {
            shift @path;
            next POINT;
        }

        my $item = shift @path;
        my $current = $point;

        # process the point
        if ( !ref $point ) {
            return;
        }
        elsif ( ref $point eq 'HASH' ) {
            $replacer = sub { $current->{$item} = shift };
            $point = $point->{$item};
        }
        elsif ( ref $point eq 'ARRAY' ) {
            $replacer = sub {  $current->[$item] = shift };
            $point = $point->[$item];
        }
        elsif ( blessed $point && $point->can( $item ) ) {
            $replacer = undef;
            $point = $point->$item();
        }
        else {
            confess "Don't know how to deal with $point";
        }

        return wantarray ? ($point, $replacer) : $point if !@path;
    }

    # nothing found
    return;
}

sub lol_iterate {
    my ($lol, $code, $path) = @_;
    my $point = $lol;

    if ( !$path && defined $point ) {
        $code->( $point, '' );
    }

    $path = $path ? "$path." : '';

    if ( $point ) {
        if ( !ref $point ) {
            $code->( $point, $path );
        }
        elsif ( ref $point eq 'HASH' ) {
            for my $key ( keys %$point ) {
                $code->( $point->{$key}, "$path$key" );
                lol_iterate( $point->{$key}, $code, "$path$key" ) if ref $point->{$key};
            }
        }
        elsif ( ref $point eq 'ARRAY' ) {
            for my $i ( 0 .. @$point - 1 ) {
                $code->( $point->[$i], "$path$i" );
                lol_iterate( $point->[$i], $code, "$path$i" ) if ref $point->[$i];
            }
        }
        elsif ( blessed $point && eval { %{$point} } ) {
            for my $key ( keys %$point ) {
                $code->( $point->{$key}, "$path$key" );
                lol_iterate( $point->{$key}, $code, "$path$key" ) if ref $point->{$key};
            }
        }
    }

    return;
}

our %required;
sub do_require {
    my ($module) = @_;

    return if $required{$module}++;

    # check if namespace appears to be loaded
    return if Class::Inspector->loaded($module);

    # Try loading namespace
    $module =~ s{::}{/}gxms;
    $module .= '.pm';
    eval {
        require $module
    };
    if (my $e = $@) {
        confess $e;
    }

    return;
}

1;

__END__

=head1 NAME

Data::Context::Util - Helper functions for Data::Context

=head1 VERSION

This documentation refers to Data::Context::Util version 0.3.

=head1 SYNOPSIS

   use Data::Context::Util qw/lol_path lol_iterate/;

   my $lol = {
        data => [
            {
                structure => 'item',
            },
        ],
   };

   my $value = lol_path($lol, 'data.0.structure');
   # value == item

   lol_iterate(
        $lol,
        sub {
            my ($value, $path) = @_;
            print "$path = $value" if !ref $value;
        }
   );
   # would print data.0.structure = item

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<lol_path ( $lol, $path )>

=over 4

=item C<$lol>

List of lists ie an arbitrary data structure

=item C<$path>

A string encoded as a dotted path through the data structure

=back

C<lol_path> tries to extract data from an arbitrary Perl data structure based
on the specified path. It will try yo do what makes sense ie if the current
context of the lol is a hash the path part will be used as a key, similarly
if the context is an array the path part will be used as an index. If the
context is a blessed reference then it try to call the path part as a method.

All errors result in returning no value.

=head2 C<lol_iterate ($lol, $code)>

=over 4

=item C<$lol>

Arbitrary perl data structure

=item C<$code>

A subroutine that is called against all values found in the data structure.
It is called as:

 $code->($value, $path);

=back

Recursively iterates through a data structure calling C<$code> for each value
encountered.

=head2 C<do_require ($module)>

Requires the specified module (if not previously required

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

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
