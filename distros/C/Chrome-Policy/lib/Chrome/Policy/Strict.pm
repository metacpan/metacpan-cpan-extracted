# ABSTRACT: Chrome strict policy role

use v5.37;
use Object::Pad;

package Chrome::Policy::Strict;
role Chrome::Policy::Strict;
use experimental qw( builtin );
use builtin qw( true false );
use JSON::PP qw();
use Data::Printer;
use Path::Tiny;

# @formatter:off
field %policy = (
# @formatter:on
  ForceGoogleSafeSearch   => true ,
  ForceYouTubeRestrict    => 1 ,
  SafeSitesFilterBehavior => 1 ,
);


method set_strict_policy ( $name = 'strict.json' , $type = 'managed' ) {
  my $json = JSON::PP -> new -> pretty( true );
  my $policy = $json -> encode( \%policy );
  # p $policy;
  my $file;
  if ( $type eq 'managed' ) {
    $file = path( $self -> managed_policy_path , $name ) -> touchpath -> openw;
  }
  $file -> print( $policy );
  $file -> close;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Chrome::Policy::Strict - Chrome strict policy role

=head1 VERSION

version 0.230410

=head1 METHODS

=head2 set_strict_policy([$name, $type])

Apply strict policy set using Chrome policies below:

  ForceGoogleSafeSearch: true
  ForceYouTubeRestrict: 1
  SafeSitesFilterBehavior: 1

C<$name> is policy file name (F<strict.json> by default)

C<$type> is "managed" by default, but may also be "recommended" as per the policy specification

=head1 AUTHOR

Elvin Aslanov <rwp.primary@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Elvin Aslanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
