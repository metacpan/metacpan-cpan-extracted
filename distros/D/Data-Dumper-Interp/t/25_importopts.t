#!/usr/bin/env perl
use Data::Dumper::Interp;

our (@VARNAMES, %defaults);
BEGIN{ # before t_* libraries mess with settings
  @VARNAMES = qw/Debug MaxStringwidth Truncsuffix Trunctailwidth Objects Refaddr Foldwidth Foldwidth1 Useqq Quotekeys Sortkeys Maxdepth Maxrecurse Deparse Deepcopy/;
  () = vis(""); # set Foldwidth
  %defaults = (
    map{ do{ no strict 'refs'; ($_ => ${"Data::Dumper::Interp::$_"}) } } @VARNAMES
  );
  #warn dvis '##INIT %defaults\n';
}

use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp
###use t_TestCommon ':silent', qw/bug/; # Test2::V0 etc.
use t_TestCommon qw/bug/; # Test2::V0 etc.

use Data::Dumper::Interp;

diag "AT TOP";

sub check_vars(@) {
  my %changed = @_;
  my $lno = (caller)[2];
diag "check_vars lno=$lno\n";
diag dvis '%changed\n';
  no strict 'refs';
  foreach my $name (@VARNAMES) {
    my $exp = exists($changed{$name}) ? vis($changed{$name}) : vis($defaults{$name});
    my $got = vis( ${"Data::Dumper::Interp::${name}"} );
#warn dvis '## $lno $name $exp $got %changed\n';
    is($got, $exp, "Line $lno: Global $name = $exp");
  }
}

main::check_vars();

sub change_one($$) {
  my ($name, $setting) = @_;
diag "change_one name=$name setting=$setting\n";
  state %changed;
  #oops if exists $changed{$name};
  $changed{$name} = eval $setting; confess "<$setting> $@" if $@;
  my $code = "use Data::Dumper::Interp q{:${name}=$setting};";
  eval $code; die dvis 'eval error, $name $setting $@' if $@;
  @_ = %changed;
  goto &check_vars;
}

change_one(Debug => 'undef');
change_one(Debug => 0);
change_one(MaxStringwidth => 1234);
change_one(Truncsuffix => '"zzz"');
change_one(Trunctailwidth => 42);
change_one(Objects => 0);
change_one(Objects => 1);
change_one(Objects => '{overloads => "transparent"}');
change_one(Refaddr => 'undef');
change_one(Refaddr => 0);
change_one(Foldwidth => 55);
change_one(Foldwidth1 => 56);
change_one(Foldwidth => $defaults{Foldwidth});
change_one(Useqq => 1);
change_one(Useqq => "'unicode:condense'");
change_one(Useqq => '"unicode"');
change_one(Quotekeys => 0);
change_one(Quotekeys => 1);
change_one(Sortkeys => 1);
change_one(Sortkeys => 0);
change_one(Maxdepth => 18);
change_one(Maxdepth => 0);
change_one(Maxrecurse => 19);
change_one(Maxrecurse => 0);
change_one(Deparse => 1);
change_one(Deparse => 0);
change_one(Deepcopy => 'undef');
change_one(Deepcopy => 0);

done_testing();
exit 0;
