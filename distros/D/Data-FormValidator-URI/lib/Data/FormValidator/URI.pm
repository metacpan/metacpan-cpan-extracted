package Data::FormValidator::URI;

###############################################################################
# Required inclusions.
use strict;
use warnings;
use URI;

###############################################################################
# Export our methods.
use base qw( Exporter );
our @EXPORT = qw(
    FV_uri_filter
    FV_uri
);

###############################################################################
# Version number.
our $VERSION = '0.03';

###############################################################################
# Subroutine:   FV_uri_filter(%opts)
###############################################################################
# Filter method which cleans up the given value as best it can and returns
# something that looks like a URI.
#
# The filtered URI will be canonicalized, and common typos will be corrected.
#
# Supported options:
#   default_scheme - Default URI scheme to use, if none was provided in the URI
sub FV_uri_filter {
    my %opts = @_;

    return sub {
        my $val = shift;

        # Add default scheme if one was not provided in the URI.
        if ($opts{default_scheme}) {
            unless ($val =~ m{^\s*\w+://}) {
                $val = $opts{default_scheme} . "://" . $val;
            }
        }

        # Correct typos in "://"
        if ($val =~ m{^\s*(\w+):/(\w.*)$}) {
            $val = join '://', $1, $2;
        }

        # Canonicalize the URI
        {
            my $uri = URI->new($val);
            $val = $uri->canonical if ($uri);
        }

        return $val;
    };
}

###############################################################################
# Subroutine:   FV_uri(%opts)
###############################################################################
# Constraint method, which ensures that we have a valid URI.
#
# Supported options:
#   schemes   - list-ref of valid schemes
#   hostcheck - host exists in URI and resolves as a valid host? (default off)
#   allow_userinfo  - allow user info in URI (default off)
sub FV_uri {
    my %opts = @_;

    return sub {
        my $dfv = shift;
        my $val = shift;

        $dfv->name_this($dfv->get_current_constraint_field);

        my $uri = URI->new($val);

        # Fail if its not a valid URI at all
        return 0 unless ($uri);

        # URI must have a scheme
        my $scheme = $uri->scheme;
        return 0 unless $scheme;

        # Check list of supported schemes
        if ($opts{schemes}) {
            return 0 unless (grep { $_ eq $scheme } @{$opts{schemes}});
        }

        # Check for embedeed user info
        unless ($opts{allow_userinfo}) {
            return 0 if ($uri->userinfo);
        }

        # Check for valid hostname
        if ($opts{hostcheck}) {
            return 0 unless ($uri->can('host'));

            my $host = $uri->host;
            return 0 unless ($host);

            my @bits = gethostbyname($host);
            return 0 unless (@bits);
        }

        # Looks good!
        return 1;
    };
}

1;

=for stopwords hostcheck canonicalized

=head1 NAME

Data::FormValidator::URI - URI constraint/filter for Data::FormValidator

=head1 SYNOPSIS

  use Data::FormValidator;
  use Data::FormValidator::URI;

  my $res = Data::FormValidator->check(
    {
      website => 'http://www.example.com/path/to/some/resource.html',
    },
    {
      required      => [qw( website )],
      field_filters => {
        website => FV_uri_filter(default => 'http'),
      },
      constraint_methods => {
        website => FV_uri(
          schemes        => [qw( http https )],
          hostcheck      => 1,
          allow_userinfo => 0,
        ),
      },
    },
  );

=head1 DESCRIPTION

This module provides a filter and a constraint method for use with
C<Data::FormValidator>, to help make it easier to valid URIs.

=head1 METHODS

=over

=item FV_uri_filter(%opts)

Filter method which cleans up the given value as best it can and returns
something that looks like a URI.

The filtered URI will be canonicalized, and common typos will be corrected.

Supported options:

=over

=item default_scheme

Default URI scheme to use, if none was provided in the URI

=back

=item FV_uri(%opts)

Constraint method, which ensures that we have a valid URI.

Supported options:

=over

=item schemes

list-ref of valid schemes

=item hostcheck

host exists in URI and resolves as a valid host? (default off)

=item allow_userinfo

allow user info in URI (default off)

=back

=back

=head1 AUTHOR

Graham TerMarsch <cpan@howlingfrog.com>

=head1 COPYRIGHT

Copyright (C) 2013, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the terms
of the Artistic 2.0 license.

=head1 SEE ALSO

=over

=item L<Data::FormValidator>

=item L<URI>

=back

=cut
