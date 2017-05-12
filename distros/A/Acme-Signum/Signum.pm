package Acme::Signum;

use strict;
use warnings;
use vars qw/@SIG %signum @signame/;
use Config;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	@SIG
);

our $VERSION = '0.01';


sub import {
    tie @SIG => __PACKAGE__;
    my @names = split ' ', $Config{sig_name};
    @signum{@names} = split ' ', $Config{sig_num};
    foreach (@names) {
        $signame[$signum{$_}]||=$_;
    }
}

sub _signame {
    $signame[$_[0]];
}

sub TIEARRAY {
    my $cls = shift;
    my $d = undef;
    bless \$d => $cls;
}

sub FETCH {
    my $i = pop;
    my $name = _signame($i);
    unless ($name) { return }
    return $SIG{$name};
}

sub STORE {
    my ($val, $i) = (pop,pop);
    my $name = _signame($i);
    unless ($name) { return }
    $SIG{$name} = $val;
}

sub FETCHSIZE {
    scalar @signame;
}

sub STORESIZE { undef }

sub EXTEND { undef }

sub EXISTS {
    my $i = pop;
    my $name = _signame($i);
    unless ($name) { return 0 }
    return exists $SIG{$name};
}

sub PUSH { undef }

sub CLEAR { undef }

sub DELETE { undef }

1;
__END__

=head1 NAME

Acme::Signum - Address signal handlers by number

=head1 SYNOPSIS

  use Acme::Signum;
  
  $SIG[3] = sub{ print "this works\n" };
  kill(3,$$);
  print ":)\n";
  $SIG[3]='DEFAULT';
  kill(3,$$);
  print ":(\n";

=head1 DESCRIPTION

  @SIG is tied to directly modify %SIG.

=head1 EXPORT

@SIG

=head1 SEE ALSO

  kill(2)

=head1 AUTHOR

Raoul Zwart, E<lt>rlzwart@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Raoul Zwart

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
