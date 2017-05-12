package Attribute::Method;

use warnings;
use strict;
use Attribute::Handlers;
use B::Deparse;

our $VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /(\d+)/g;

my $dp        = Attribute::Method::_Deparse->new('-l');
my $dppack;
my %sigil2ref = (
    '$' => \undef,
    '@' => [],
    '%' => {},
);

sub import {
    my ( $class, @vars ) = @_;
    my $pkg = caller();
    push @vars, '$self';
    for my $var (@vars) {
        my $sigil = substr( $var, 0, 1, '' );
        no strict 'refs';
        *{ $pkg . '::' . $var } = $sigil2ref{$sigil};
    }
}

sub UNIVERSAL::Method : ATTR(RAWDATA) {
    my ( $pkg, $sym, $ref, undef, $args ) = @_;
    $dppack = $pkg;
    my $src = $dp->coderef2text($ref);
    if ($args) {
        $src =~ s/\{/{\nmy \$self = shift; my ($args) = \@_;\n/;
    }
    else {
        $src =~ s/\{/{\nmy \$self = shift;\n/;
    }
    no warnings 'redefine';
    my $sub_name = *{$sym}{NAME};
    eval qq{ package $pkg; sub $sub_name $src };
}

package
 Attribute::Method::_Deparse;

BEGIN { our @ISA = 'B::Deparse' }

sub maybe_qualify {
    my $ret = SUPER::maybe_qualify{@_};
    my ($pack,$name) = $ret =~ /(.*)::(.+)/;
    length $pack && $pack eq $dppack and return $name;
    $ret;
}

"Rosebud"; # for MARCEL's sake, not 1 -- dankogai

__END__

=head1 NAME

Attribute::Method - No more 'my $self = shift;'

=head1 SYNOPSIS

  package Lazy;
  use strict;
  use warnings;
  use Attribute::Method qw( $val );
	                # pass all parameter names here
                        # to make strict.pm happy
  sub new : Method { 
      bless { @_ }, $self 
  }
  sub set_foo : Method( $val ){
      $self->{foo} = $val;
  }
  sub get_foo : Method {
      $self->{foo};
  }
  #....

=head1 DESCRIPTION

This Attribute makes your subroutine a method -- $self is
automagically set and the parameter list is supported.

This trick is actually introduced in "Perl Hacks", hack #47.
But the code sample therein is a little  buggy so have a look at this
module instead.

=head1 BUGS

None known so far. If you find any bugs or oddities, please do inform the
author.

=head1 CAVEAT

The following does not work.

=over 2

=item foo.pl

  use Attribute::Memoize;
  use strict;
  use warnings;
  use lib '.';
  print "loading bar ...\n";
  require bar; # should have been 'use bar;'
  print "bar is loaded\n";
  print bar::func(),"\n";
  print bar::func(),"\n";
  exit 0;

=item bar.pm

  package bar;
  use strict;
  use warnings;
  use Attribute::Memoize;

  sub func : Memoize {
    print "func runs\n";
    return 123;
  }
  1;

=back

To use modules that use L<Attribute::Memoize>, don't C<require>;
C<use> it.  That holds true for most Attribute::* modules.

=head1 AUTHOR

Dan Kogai, C<< <dankogai+cpan at gmail.com> >>

=head1 COPYRIGHT

Copyright 2008 Dan Kogai.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), L<Attribute::Handlers>

Perl Hacks, isbn:0596526741

=cut
