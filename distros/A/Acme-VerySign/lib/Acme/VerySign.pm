package Acme::VerySign;

use overload '""' => "as_string",
    fallback => 1;

use Carp;
use Devel::Symdump;

use strict;
#use warnings;

use vars qw($AUTOLOAD $VERSION);

$VERSION = "1.00";

####################################################################
# cargo culted from Symbol::Approx::Sub
####################################################################

# List of functions that we _never_ try to match approximately.
my @_BARRED = qw(AUTOLOAD BEGIN CHECK INIT DESTROY END);
my %_BARRED = (1) x @_BARRED;

sub _pkg2file {
  $_ = shift;
  s|::|/|g;
  "$_.pm";
}

####################################################################

sub import
{
  my $class = shift;

  # work out who called us
  my $pkg =  caller(0);

  # turn off refs while we write to another package namespace
  no strict "refs";

  ####################################################################
  # cargo culted from Symbol::Approx::Sub
  ####################################################################

  my %param;
  my %CONF;
  %param = @_ if @_;

  my %defaults = (xform => 'Text::Soundex',
                  match => 'String::Equal',
                  choose => 'Random');

  # Work out which transformer(s) to use. The valid options are:
  # 1/ $param{xform} doesn't exist. Use default transformer.
  # 2/ $param{xform} is undef. Use no transformers.
  # 3/ $param{xform} is a reference to a subroutine. Use the 
  #    referenced subroutine as the transformer.
  # 4/ $param{xform} is a scalar. This is the name of a transformer
  #    module which should be loaded.
  # 5/ $param{xform} is a reference to an array. Each element of the
  #    array is one of the previous two options.

  if (exists $param{xform}) {
    if (defined $param{xform}) {
      my $type = ref $param{xform};
      if ($type eq 'CODE') {
        $CONF{xform} = [$param{xform}];
      } elsif ($type eq '') {
        my $mod = "Symbol::Approx::Sub::$param{xform}";
        require(_pkg2file($mod));
        $CONF{xform} = [\&{"${mod}::transform"}];
      } elsif ($type eq 'ARRAY') {
        foreach (@{$param{xform}}) {
          my $type = ref $_;
          if ($type eq 'CODE') {
            push @{$CONF{xform}}, $_;
          } elsif ($type eq '') {
            my $mod = "Symbol::Approx::Sub::$_";
            require(_pkg2file($mod));
            push @{$CONF{xform}}, \&{"${mod}::transform"};
          } else {
            croak 'Invalid transformer passed to Acme::VerySign';
          }
        }
      } else {
        croak 'Invalid transformer passed to Acme::VerySign';
      }
    } else {
      $CONF{xform} = [];
    }
  } else {
    my $mod = "Symbol::Approx::Sub::$defaults{xform}";
    require(_pkg2file($mod));
    $CONF{xform} = [\&{"${mod}::transform"}];
  }

  # Work out which matcher to use. The valid options are:
  # 1/ $param{match} doesn't exist. Use default matcher.
  # 2/ $param{match} is undef. Use no matcher.
  # 3/ $param{match} is a reference to a subroutine. Use the 
  #    referenced subroutine as the matcher.
  # 4/ $param{match} is a scalar. This is the name of a matcher
  #    module which should be loaded.

  if (exists $param{match}) {
    if (defined $param{match}) {
      my $type = ref $param{match};
      if ($type eq 'CODE') {
        $CONF{match} = $param{match};
      } elsif ($type eq '') {
        my $mod = "Symbol::Approx::Sub::$param{match}";
        require(_pkg2file($mod));
        $CONF{match} = \&{"${mod}::match"};
      } else {
        croak 'Invalid matcher passed to Symbol::Approx::Sub';
      }
    } else {
      $CONF{match} = undef;
    }
  } else {
    my $mod = "Symbol::Approx::Sub::$defaults{match}";
    require(_pkg2file($mod));
    $CONF{match} = \&{"${mod}::match"};
  }


  ####################################################################

  # install the AUTOLOAD method
  *{"${pkg}::AUTOLOAD"} = sub {
    Acme::VerySign->new($AUTOLOAD =~ /^(.*)::(.*)$/, %CONF);
  }
}

{
  my $pkg;
  my $subname;

sub new
{
  my $class = shift;
  $pkg      = shift;
  my $sub = $subname = shift;
  my %CONF  = @_;

  ####################################################################
  # code cargo culted from Symbol::Approx::Sub
  ####################################################################

    # Get a list of all of the subroutines in the current package
    # using the get_subs function from GlobWalker.pm
    # Note that we deliberately omit function names that exist
    # in the %_BARRED hash
    my (@subs, @orig);
    my $sym = Devel::Symdump->new($pkg);
    @orig = @subs = grep { ! $_BARRED{$_} } 
                    map { s/${pkg}:://; $_ }
                    grep { defined &{$_} } $sym->functions($pkg);

    # Transform all of the subroutine names
    foreach (@{$CONF{xform}}) {
      croak "Invalid transformer passed to Acme::VerySign\n"
        unless defined &$_;
      ($sub, @subs) = $_->($sub, @subs);
    }

    # Call the subroutine that will look for matches
    # The matcher returns a list of the _indexes_ that match
    my @match_ind;
    if ($CONF{match}) {
      croak "Invalid matcher passed to Acme::VerySign\n"
        unless defined &{$CONF{match}};
      @match_ind = $CONF{match}->($sub, @subs);
    } else {
      @match_ind = (0..$#subs);
    }

   @orig = @orig[@match_ind];


  ####################################################################

  # unique that array
  my %orig = map { $_ => 1 } @orig;
  my $this = bless [keys %orig], $class;
  return $this;
}

sub as_string { "64.94.110.11" }

sub buy
{
  my $this = shift;
  die "No matching subroutines!" unless defined $this->[0];
  no strict 'refs';
   *{"${pkg}::${subname}"} = *{"${pkg}::".$this->[0]}{CODE};
}

}

1;

__END__

=head1 NAME

Acme::VerySign - make unused subroutines useful

=head1 SYNOPSIS

  use Acme::VerySign;

  sub hello { "Hello World" }

  print helo();
  print "Did you mean: $_ ?" foreach @{ helo() }
  helo()->buy();
  print helo();

=head1 DESCRIPTION

After all is said and done, it's not actually that helpful that perl
returns an error whenever it can't find a subroutine.

This module solves this.  With new I<subfinder> technology whenever
perl can't call a subroutine it automatically returns a scalar that
stringifies to "64.94.110.11" instead!

But wait!  There's more - due to our use of B<Symbol::Approx::Sub>
technology if you treat the scalar as an arrayref you can get the
names of the subroutines we think you meant!  You can even specify
the way we do searching using B<Symbo::Approx::Sub> semantics (i.e.
we support the 'match' and 'xform' parameters.

  use Acme::VerySign xform => "Text::Metaphone";

Finally, you can use the "buy" method on the returned scalar and this
module will install the first matching subroutine for you.

=head1 AUTHOR

Written by Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

Copyright Mark Fowler 2003.  All Rights Reserved.

Most of the code in here is stolen from B<Symbol::Approx::Sub>
written by Dave Cross.  That code copyright him, though the
terrible joke was all my fault.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

The whole concept is flawed.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme::VerySign>.

=head1 SEE ALSO

L<Symbol::Approx::Sub>
L<http://towshortplanks.com/>

=cut
