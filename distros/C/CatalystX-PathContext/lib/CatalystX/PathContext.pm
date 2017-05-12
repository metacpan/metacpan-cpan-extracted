package CatalystX::PathContext;

use Moose::Role;

our $VERSION = 'v0.0.1';

use Catalyst::Exception;

after 'prepare_path' => sub {
    my $c = shift;

    my @removed;

    # we have to concatenate __PACKAGE__ with an empty string
    # otherwise it's interpreted as hash key
    my $config_ref   = $c->config()->{ q{} . __PACKAGE__ };
    my $request_path = $c->request()->path();
    if ( $config_ref ) {
        for my $context_ref ( @{$config_ref} ) {
            if ( ref $context_ref->{match} eq 'CODE' ) {
                for my $item ( $context_ref->{match}->($c, $request_path) ) {
                    $request_path =~ s{\A $item (?: / | \z ) }{}xms;
                    push @removed, $item;
                }
            }
            else {
                if ( 'Regexp' ne ref $context_ref->{match} ) {
                    # upgrade string based regex in config ref for performance++
                    $context_ref->{match}
                        = qr{\A $context_ref->{match} (?: / | \z )}xms;
                }

                # find if we should handle this url part
                if ( $request_path =~ m{$context_ref->{match}}xms ) {
                    # write a copy of named captures into path_context stash key
                    $c->stash()->{path_context}->{$context_ref->{name}} = { %+ };

                    # push each path part into removed array for
                    # rewrite of path_segments
                    push @removed,
                        split m{/}xms, $&;  ## no critic (ProhibitMatchVars)

                    # remove from request path
                    $request_path =~ s{$context_ref->{match}}{}xms;
                }
            }
        }
    }

    # Stuff modified request path back into request:
    $c->request()->path($request_path);

    # Modify the path part of the request base to include the path prefix:
    my $base = $c->request()->base();
    $base->path_segments(
        $base->path_segments() ? $base->path_segments()
                               : (),
        @removed,
    );

    return;
};

1;
__END__

=head1 NAME

CatalystX::PathContext - use different context based on the request path


=head1 VERSION

This document describes CatalystX::PathContext version 0.0.1


=head1 SYNOPSIS

    package MyApp;
    use Moose;
    use namespace::autoclean;

    use Catalyst::Runtime;
    use Catalyst;
    extends 'Catalyst';

    # our Catalyst uses the CatalystX::PathContext Role
    with 'CatalystX::PathContext';

    our $VERSION = '0.01';
    $VERSION = eval $VERSION;

    __PACKAGE__->config(
        name => 'MyApp',

        # we configure our CatalystX::PathContext object
        # to convert uri's like
        #    http://localhost:3000/eng/hello
        # to a controller which would be normally accessed via
        #    http://localhost:3000/hello
        # if we found 3 lower case chars (eg. eng) as first part of our url
        #    $c->stash()->{path_context}->{language}->{'code'} eq 'eng'
        'CatalystX::PathContext' => [
            { name  => 'language',
              match => '(?<code>[a-z]{3})',
            },
        ],
    );

    __PACKAGE__->setup;


=head1 DESCRIPTION

This Role allows your Catalyst app to provide multiple path prefixes aka
a context with none or multiple url path based arguments.

You can specify as much path prefixes as you like and give them a name
and use a matchp for matching them. If the module finds a configured
path prefix you could find all info in the catalyst stash and it could be
used for whatever you like (eg. use a different view for different
languages).

If you use this module your Catalyst controllers would be reachable via
the default urls but also over urls which are prefixed with anything you
would use as prefix.

=head1 INTERFACE

please see L</CONFIGURATION AND ENVIRONMENT>


=head1 DIAGNOSTICS

None.


=head1 CONFIGURATION AND ENVIRONMENT

CatalystX::PathContext must be configured via the Catalyst configuration.

  $c->config(
      'CatalystX::PathContext' => [
          { name  => 'language',
            match => '(?<code>[a-z]{3})',
          },
      ],
  );

All configuration items will be stored in the your Catalyst App config.
We use the Class Name of this Module CatalystX::PathContext as base
config key.

This config Item is a array reference of Path Prefixes. Each item in this
reference is an hash reference with the keys name and match.

The key name defines the name which identifies your context / prefix. If you
set the name to "language" and our regex in "match" matched the request path
you can find the following keys in your stash:

  $c->stash()->{path_context}->{langague};

You can use the named capture feature which is available since perl 5.10 to
to fetch some url based param values from your request path into your stash
without passing them directly to the catalyst dispatch engine / controllers.

=head3 You can use precompiled regexes like

  match => qr{\A $context_ref->{match} (?: / | \z )}xmso

=head3 or strings which would be upgraded (directly in the catalyst config) to
matches like

  match => '(?<code>[a-z]{3})'

The string based match is always prefixed with an \A and suffixed with
(?: / | \z )

If your request path matches this match your stash would contain for example
for the Request URL look like http://localhost:3000/eng/hello the following:

  $c->stash()->{path_context}->{language}->{code} eq 'eng'

You can add multiple item like { name => ..., match => ... } to your
config - but be warned that the position of this items matters.

=head3 Last but not least you could use a subroutine reference for matching path
prefixes.

  match => sub {
      my ( $c, $request_path ) = @_;

      my ( $code )   = $request_path =~ m{\A (..) (?: / | \z ) }xms;
      my %country_of = qw(en Englang de Germany);

      if ( defined $code && exists $country_of{$code} ) {
          $c->stash()->{whateveryouwant}->{country} = $country_of{$code};
          return $code;
      }

      return;
  }

You have to take care about 2 things, which differs from the regex based
matching.

=over 1

=item 1. return a list of removed path parts or an empty list

You have to return a list of all removed prefixes or a empty list and
not undef eg. to dispatch http://localhost:3000/en/ to http://localhost:3000/
you have to return a list with the item "en". You can return more than one
item of course.

=item 2. store your context info manually

If you use subroutine references to match a path prefix the stash is
not updated for this context/prefix. -> $c->stash()->{path_context}->{country}
is not filled automatically.

=back

=head1 DEPENDENCIES

This module only works under Perl 5.10 or later.
It requires a L<Catalyst/"Catalyst"> and isa L<Moose::Role/"Moose::Role">.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-catalystx-pathcontext@rt.cpan.org>, or through the web interface at
L<"http://rt.cpan.org"/"http://rt.cpan.org/">.


=head1 AUTHOR

Andreas 'ac0v' Specht  C<< <ac0v@sys-network.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Andreas 'ac0v' Specht C<< <ac0v@sys-network.de> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic/"perlartistic">.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
