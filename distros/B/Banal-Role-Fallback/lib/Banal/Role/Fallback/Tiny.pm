use 5.014;
use utf8;
use strict;
use warnings;

package Banal::Role::Fallback::Tiny;
# vim: set ts=2 sts=2 sw=2 tw=115 et :
# ABSTRACT: A tiny role that provides a 'fallback' method which helps building default values for object attributes.
# KEYWORDS: author utility

our $VERSION = '0.001';
# AUTHORITY

use Banal::Util::Mini   qw(tidy_arrayify hash_lookup_staged sanitize_subroutine_name);
use Array::Utils        qw(intersect);
use Scalar::Util        qw(blessed refaddr reftype);
use List::Util 1.45     qw(any none pairs uniq);
use List::MoreUtils     qw(arrayify firstres listcmp);
use Text::ParseWords    qw(quotewords);
use Data::Printer;

use namespace::autoclean;
use Role::Tiny;
requires qw( _fallback_settings );



#######################################
sub _resolve    {  # Transitional. Helps support an older name & interface to _fallback
#######################################
  my  $o            = shift;
  my  %opt          = %{ ref $_[0] eq 'HASH' ? shift : +{} };
  _fallback($o, { args_are_keys => 1, %opt}, @_)
}

#######################################
sub _resolve_mv { # Explicitely asks for an ARRAY reference.
#######################################
  # Also handles 'implicit additions' (extras that are appended systematically)
  my  $self     = shift;
  my  $opt    = ( ref ($_[0]) =~ /HASH/ ) ? shift : {};
  $self->_resolve( {  %$opt, want_reftype => 'ARRAY', multivalue => 1 }, @_);
}

#######################################
sub _resolve_mv_list {  # Always returns a list, instead of an ARRAY reference.
#######################################
  @{ shift->_resolve_mv(@_) }
}

#######################################
sub _resolve_href { # Explicitely asks for a hash reference
#######################################
  my  $self     = shift;
  my  $opt    = ( ref ($_[0]) =~ /HASH/ ) ? shift : {};
  $self->_resolve( {  %$opt, want_reftype => 'HASH' }, @_ );
}


# Practical method-helper for determining the effective value to be used for a given attribute for a given object.
# The object would need to satisfy several conditions, though
#######################################
sub _fallback   {
#######################################
  local $_;
  my ($o, %opt)     = &_normalize_fallback_opts;
  my  @keys         = tidy_arrayify( $opt{keys} );
  my  @blankers     = tidy_arrayify( $opt{blanker_token} );
  my  @mid          = tidy_arrayify( @opt{qw( via )});
      @mid          = tidy_arrayify( @opt{qw( mid nrm normally )}, \&_smart_lookup) unless !!@mid;
  my  @attempts     = tidy_arrayify(
                          @opt{qw( apriori primo )},
                          @mid,
                          @opt{qw( def last fin final finally )}
                        );
  my  @res;
  my  $debug         = $opt{debug};

  # say STDERR "Looking up keys : " . np @keys if $debug;
ATTEMPT:
  foreach my $item (@attempts) {
    next unless defined $item;
    my $v = (reftype($item) // '') eq 'CODE'
              ? eval { $item->($o, \%opt) }
              : $item;

    # say STDERR "Attempt died on us : $@"  if $@ && $debug;

    if (defined($v) && !$@) {
      push @res, $v;
      last ATTEMPT;
    }
    eval {; 1 }; # clear the last error
  }

  @res = tidy_arrayify(@res);

  # say STDERR "  Got (raw) : " . np @res if $debug;

  {
    no warnings qw(uninitialized);
    my  @greps   = tidy_arrayify( $opt{grep}, $opt{greps});
    push @greps, sub {; my @v=($_); !intersect(@blankers, @v) } if (@blankers);

    foreach my $f ( @greps ) {
        my  $rt = reftype($f) // '';
        @res =  grep {
                  my $gr = $_;
                  $rt eq 'CODE'   and   $gr  = $f->($_);
                  $rt eq 'REGEXP' and   $gr  = m/$f/;
                  !$rt            and   $gr  = looks_like_number($f) ? ($_ == $f) : ($_ eq "$f");
                  $gr
                }@res;
    }
    @res  = uniq(@res) unless $opt{no_uniq} && !$opt{uniq};
    @res  = sort @res  if $opt{sort};
  }

  # say STDERR "  Keys : " . np @keys if grep { m/install/ } @keys;
  # say STDERR "  Got  : " . np @res  if $debug;

  return [ @res ] if $opt{want_reftype}  eq 'ARRAY' ;
  return          unless @res;   # Got no results at all. Signal that.
  return $res[0]  if @res == 1;  # If we've got only one value, then there is no ambiguity. Just return that.

  if ( $opt{want_reftype}  eq 'HASH' ) {
      my %res = map {; ref ($_) =~ /HASH/ix ? ( %{$_} ) : ()  } reverse @res;      # effectively shallow-merge the resulting hashes
      return +{ %res };
  }

  # At this stage, even if we have more than one value, we only return the first found.
  # CONSIDER: raising an error, perhaps.
  return $res[0];
}

#
# #######################################
# around _fallback =>  sub { # DEBUG wrapper.
# #######################################
#   my  $orig         = shift;
#   my ($o, %opt)     = &_normalize_fallback_opts;
#   my  @keys         = tidy_arrayify( $opt{keys} );
#   my  $debug         = $opt{debug};
#   my  %info         = (keys => [@keys] );
#
#   if (wantarray) {
#     say STDERR "\n\nFallback in ARRAY context for keys [@keys] ... " if $debug;
#     my @r = $o->$orig($o, \%opt, @_);
#     $info{result} = [@r];
#     say STDERR "Fallback in ARRAY context. info : " . np %info if $debug;
#     return @r;
#   } else {
#     say STDERR "\n\nFallback in SCALAR context for keys [@keys] ... " if $debug;
#     my $r = scalar($o->$orig($o, \%opt, @_));
#     $info{result} = $r;
#     say STDERR "   Fallback result in SCALAR context. info : " . np %info if $debug;
#     return $r;
#   }
#
# };
#

#######################################
sub _smart_lookup  {
#######################################
# Returns the first found item (corresponding to any of the given keys) in any of the hash sources.
  local $_;
  my ($o, %opt)     = &_normalize_fallback_opts;
  my  @keys         = tidy_arrayify( $opt{keys} )
                      or   die "No keys given for us to lookup during staged fallback!";
  my  @res;
  my  @sfx          = tidy_arrayify( $opt{implicit_suffix} // '_implicit' );
  my  @blankers     = tidy_arrayify( $opt{blanker_token} );
  my  @no_implicit  = tidy_arrayify( $opt{no_implicit} );
  my $debug         = $opt{debug};

  push @no_implicit, sub {; shift; shift; intersect(@blankers, @_) } if (@blankers);

  # say STDERR "    Smart-lookup keys : " . np @keys  if $debug;

SUFFIX:
  foreach my $suffix ('', @sfx) {
      if ($suffix) {
        # An non-empty suffix means we are dealing with an 'implcit' lookup.
          last if any { ( reftype($_) eq 'CODE') ? $_->($o, \%opt, @res) : $_ } @no_implicit;
      }

      my @mkeys =  map {; $_ . $suffix } @keys;
      my $found;

      # Try $o->$key_$suffix(...)
      if ( $suffix && !$opt{no_implicit_accessor_calls} ) {
        # Try to invoke a subroutine by the given name (only if we've got a suffix)
        foreach my $k (@mkeys) {
          my $method = sanitize_subroutine_name ($k);
          $found   //= eval { $o->$method(@_) } if blessed ($o) && $o->can($method);
          last if defined $found;
        }
      }
      $found = eval { hash_lookup_staged( %opt, keys=> [@mkeys] ) }  unless defined ($found);
      push @res, ($found) if defined($found) && !$@;
  }
  @res  = tidy_arrayify(@res);

  # say STDERR "    Smart-lookup got (raw)  : " . np @res  if $debug;

  # If are asked to do so, make sure we return an array-reference
  # if ($opt{want_reftype} eq 'ARRAY') {
  #   $res =  [tidy_arrayify($res)];
  #   $res =  [ Text::ParseWords::quotewords('\s+', 0,  @$res) ]  if $opt{'parsewords'};
  # }

  # Parse words and make them into array items (if asked to do so)
  #@res =  tidy_arrayify(quotewords('\s+', 0,  @res))  if $opt{'parsewords'};

  # say STDERR "    Smart-lookup got (after-parsewords)  : " . np @res  if $debug;

  die "Can't lookup any of the given keys [@keys]!" unless scalar(@res);

  wantarray ? (@res) : \@res;
  # return [ @res ] if $opt{want_reftype}  eq 'ARRAY' ;
  # return          unless @res;   # Got no results at all. Signal that.
  # return $res[0]  if @res == 1;  # If we've got only one value, then there is no ambiguity. Just return that.
  #
  # if ( $opt{want_reftype}  eq 'HASH' ) {
  #     my %res = map {; ref ($_) =~ /HASH/ix ? ( %{$_} ) : ()  } reverse @res;      # effectively shallow-merge the resulting hashes
  #     return +{ %res };
  # }
  #
  # # At this stage, even if we have more than one value, we only return the first found.
  # # CONSIDER: raising an error, perhaps.
  # return $res[0];
}


#######################################
sub _normalize_fallback_opts {
#######################################
  local $_;
  my  $o            = shift;
  my  %opt          = %{ ref $_[0] eq 'HASH' ? shift : +{} };

  unless ( exists $opt{_normalized_} && ($opt{_normalized_} // 0) )  {
    # these may be overridden by the caller.
    %opt            = ( payload=>1,  author_specific=>1, generic=>1, %opt );
    my $fbs         = eval { $o->_fallback_settings(%opt) } // eval { $o->fallback_settings(%opt) } // +{};
    %opt            = ( %$fbs, %opt );

    my  $isam       = exists $opt{isam} ? $opt{isam} : '';
        $isam       = "$isam";  # We are only able to consider plain scalars.


    #say STDERR "metam : " . np %meta;
    #say STDERR "isam : '$isam'";

    my  $rt         = $opt{want_reftype} // '';
        $rt         = 'ARRAY'        if $opt{multivalue} || any { defined && /^ARRAY/ix } ($rt, $isam);
        $rt         = 'HASH'         if any { defined && /^HASH/ix } ($rt, $isam);
    $opt{want_reftype}    = $rt;
    $opt{multivalue}    //= $rt =~ /^ARRAY/ix || 0;
    $opt{parsewords}    //= $rt =~ /^ARRAY/ix || 0;
    $opt{keys}            = [ tidy_arrayify(  # we are quite forgiving in terms of specifiying keys/aliases
                                $opt{key},  $opt{keys},
                                $opt{name}, $opt{names},
                                $opt{aka},  $opt{alias}, $opt{aliases}, )
                            ];
  }

  # This is done even if opts are already normalized.
  $opt{keys}  = [ tidy_arrayify($opt{keys}, splice @_) ] if delete($opt{args_are_keys})  // 0;
  my @keys    =  tidy_arrayify($opt{keys});
  $opt{debug} = 0;
  # $opt{debug} = grep { m/(installer|stopword)/ix } @keys;

  if ( !$opt{_normalized_} ){ # DEBUG
    my %mopt = (%opt);
    delete @mopt{qw(sources)};
    #say STDERR "mopt : " . np %mopt;
  }

  $opt{_normalized_} = 1;
  return wantarray ? ($o, %opt) : \%opt;
}



1;

=pod

=encoding UTF-8

=head1 NAME

Banal::Role::Fallback::Tiny - A tiny role that provides a 'fallback' method which helps building default values for object attributes.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    Role::Tiny::With;
    with Banal::Role::Fallback::Tiny;

    has username => (
      is => ro,
      isa => Str,
      lazy => 1,
      default => sub { fallback(keys=> [qw(username user)}
    );

=head1 DESCRIPTION

=for stopwords isa lazy ro Str

=for stopwords TABULO
=for stopwords GitHub DZIL

This is a tiny role that provides a 'fallback' method for building default values for your attributes.

=head2 WARNING

Please note that, although this module needs to be on CPAN for obvious reasons,
it is really intended to be a collection of personal preferences, which are
expected to be in great flux, at least for the time being.

Therefore, please do NOT base your own distributions on this one, since anything
can change at any moment without prior notice, while I get accustomed to dzil
myself and form those preferences in the first place...
Absolutely nothing in this distribution is guaranteed to remain constant or
be maintained at this point. Who knows, I may even give up on dzil altogether...

You have been warned.

=head1 SEE ALSO

=over 4

=item *

L<Role::Tiny>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Banal-Role-Fallback>
(or L<bug-Banal-Role-Fallback@rt.cpan.org|mailto:bug-Banal-Role-Fallback@rt.cpan.org>).

=head1 AUTHOR

Ayhan ULUSOY <dev@tabulo.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ayhan ULUSOY.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#region pod


#endregion pod
