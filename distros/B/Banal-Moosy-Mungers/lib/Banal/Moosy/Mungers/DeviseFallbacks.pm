use 5.014;  # because we use the 'non-destructive substitution' feature (s///r)
use strict;
use warnings;

package Banal::Moosy::Mungers::DeviseFallbacks;
# vim: set ts=2 sts=2 sw=2 tw=115 et :
# ABSTRACT: Provide several MUNGER functions that may be use in conjunction with C<MooseX::MungeHas>.
# KEYWORDS: Munge Has has MungeHas MooseX::MungeHas Moose MooseX Moo MooX

our $VERSION = '0.002';
# AUTHORITY

use Data::Printer;    # DEBUG purposes.
use Scalar::Util      qw(reftype);
use List::Util 1.45   qw(pairs);

use Banal::Util::Mini qw(peek tidy_arrayify);

use namespace::autoclean;
use Exporter::Shiny qw( mhs_fallbacks );


#######################################
sub mhs_fallbacks { # Munge attr specs so that the attribute may use a 'fallback' routine for its 'default' sub.
#######################################
  # ATTENTION : Special calling convention and interface defined by MooseX::MungeHas.
  my $name    = $_;         # $_ contains the attribute NAME
  %_          = (@_, %_);   # %_ contains the attribute SPECS, whereas @_ contains defaults (prefs) for those specs.

  # say STDERR 'Fallback munger : about to start munging : ...';

  # Initial determination of some key properties involving fallback setup.
  my  $fbo_detected       = exists  $_{fallback};
  my  %fbo                = %{ delete( $_{fallback}    ) // +{} };
  my  $disabled           =    delete( $_{no_fallback} ) // peek(\%fbo, [qw(disable disabled)], 0) // 0;

  # Grok some properties (either directly from the 'has' parameters (%_), or from the 'fallback' hash (%fbo)
  my %mappings = (
    # Aliases
    alias   => [qw(aka alias aliases) ],

    #Actual fallback routines or values
    apriori => [qw(apriori primo)     ],
    mid     => [qw(mid nrm normally)  ],
    final   => [qw(def last fin final finally)  ],
    via     => [qw(via)               ],


    # Fallback source specifiers
    author_specific   => [ map {; ($_, 'lookup_' . $_ ) } qw(author author_specific author_prefs author_specific_prefs author_defaults author_settings)  ],

    # Special handling
    no_implicit         => [qw(no_implicit)           ],
    blanker_token       => [qw(blanker blankers blanker_token blanker_tokens ) ],
    implicit_suffix     => [qw(implicit_suffix implicit_suffixes  implicit_suffices implicit_sfx ) ],

    # wants
    multivalue          => [qw(multivalue)           ],

    # Processing to be done on the result
    grep                => [qw(grep greps filter filters)  ],
    sort                => [qw(sort)  ],
    uniq                => [qw(uniq unique)  ],
    no_uniq             => [qw(no_uniq no_unique)  ],
  );

  #say STDERR 'Fallback munger : about to start groking SETTINGS : ...';

SETTING:
  while ( my ($k, $v) = (each %mappings) ) {
    my @eqv = tidy_arrayify($v);
    next SETTING if !@eqv;

    my @array = ();
HASH:
    foreach my $h (\%fbo, \%_) {
      foreach my $e (@eqv) {   #(grep {; $_ ne $k }(@eqv)) {
        push @array, tidy_arrayify( delete($h->{$e}) ) if exists $h->{$e};
      }
    }

    @array    =  tidy_arrayify(@array);
SWITCH:
  for (scalar(@array)) {
      $_ == 0     and do { delete $fbo{$k};         last SWITCH };  # no need to keep it around if it is empty.
      $_ == 1     and do { $fbo{$k}  = pop @array;  last SWITCH };  # It's prettier
      $_ >  1     and do { $fbo{$k}  = [ @array ];  last SWITCH };  # multiple items.
    }
  }

  # Process aka/alias properties that are HASH references, which implies them being added to the 'handles' hash parameter.
  # This helps with the DRY principle, and is done regardless of fallback being enabled or not.

  my @handles;
  # 'delete' is used because we may end up with an empty list in the end.
  my @aliases = tidy_arrayify( (delete $fbo{alias}) // [] );
  @aliases =  map {
                        my $alias = $_;
                        if ( (reftype ($alias) // '') eq 'HASH') {
                          push @handles, ( map {; $_->value ? (@$_) : () } pairs %$alias); # push only those kv entries with a true value.
                          ( sort keys %$alias );
                        } else {
                          $_
                        }
                      } @aliases;

  @aliases = tidy_arrayify( @aliases );

  $fbo{alias}   = [@aliases] if scalar(@aliases);
  $_{handles}   = +{ @handles, %{ $_{handles} // +{} } }   if scalar(@handles);


  # Final determination of fallback setup status (enabled or disabled)
  my  $enabled           =  ($fbo_detected || !!%fbo) &&  !exists($_{default});  # && !$disabled;
      $enabled          //= 0;

  # say STDERR "Fallback setup for attribute '$name' status : { enabled => $enabled } : "   . np %fbo;

  # Do the actual fallback setup.
  if (  $enabled ) {
        # say STDERR " ==> Setting up a 'default' subroutine for '$name' since { enabled => $enabled }";
#        $fbo{metam}   //= +{%_};
        $fbo{isam}    //= "$_{isa}";  # We need the stringification! Somehow, at this point MungeHas manages to make this into an oject.
        $fbo{name}    //= "$name";
    my  $m              = $fbo{method} // '_fallback';
    $_{lazy}          //= 1,
    $_{default}         = sub { $_[0]->$m( \%fbo )  }
  }

   #'.. cannot have a lazy attribute without specifying a default'
  delete($_{lazy}) unless exists $_{default};

  wantarray ? (%_) : +{%_}
}

1;

=pod

=encoding UTF-8

=head1 NAME

Banal::Moosy::Mungers::DeviseFallbacks - Provide several MUNGER functions that may be use in conjunction with C<MooseX::MungeHas>.

=head1 VERSION

version 0.002

=head1 SYNOPSIS

=head1 DESCRIPTION

=for stopwords haz ro

use Moose;
use MooseX::MungeHas {
    haz => [  sub {; mhs_specs( is => 'ro', init_arg => undef, lazy => 1 ) },
              sub {; mhs_fallbacks() },
            ]
  };

=for stopwords TABULO

This module provides several mungers that may be use in conjunction with C<MooseX::MungeHas>.

=head2 EXPORT_OK

=over 4

=item *

mhs_fallbacks

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Banal-Moosy-Mungers>
(or L<bug-Banal-Moosy-Mungers@rt.cpan.org|mailto:bug-Banal-Moosy-Mungers@rt.cpan.org>).

=head1 AUTHOR

Tabulo <tabulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tabulo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#region pod

