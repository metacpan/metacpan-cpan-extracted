use strict;
use warnings;

package main;

do{
  my $class   = "t::tie::$_";
  my $super   = "Tie::Std$_";
  require "Tie/$_.pm";
  {
    no strict 'refs';
    @{"${class}::ISA"} = ( $super );
  }
  my $stash   = do{ no strict 'refs'; \%{"${super}::"} };
  do{
    my $sym  = $_;
    my $glob = $stash->{$sym};
    next unless my $code = *{$glob}{CODE};
    next if $sym =~ /[^A-Z]/;
    next if $sym =~
      /\A(?:TIE(?:HASH|ARRAY|SCALAR)|AUTOLOAD|BEGIN|END|DESTROY)\Z/;
    my $myglob = do{no strict 'refs'; \*{"${class}::$sym"}};
    *{$myglob} = sub{
      $main::called = $sym;
      @main::args   = @_;
      goto $code;
    };
  } foreach keys %$stash;
} foreach  qw( Scalar Array Hash Handle );

1
__END__
