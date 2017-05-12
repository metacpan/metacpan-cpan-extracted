package AutoCode::Unimplemented;
use strict;
use AutoCode::Root;
our @ISA=qw(AutoCode::Root);

sub import {
    my ($caller, $methods, $pkg)=@_;
    my $class = ref($caller)||$caller;
    $pkg||=caller;
    no strict 'refs';
    foreach(@$methods){
        *{"$pkg\::$_"}= sub {shift->not_implemented;};
    }
}

1;
__END__

=head1 NAME

AutoCode::Unimplemented - stuff the unimplemented methods in Interface module

=head1 SYNOPSIS

  package InterfaceModule;
  use AutoCode::Root;
  our @ISA=qw(AutoCode::Root);
  use AutoCode::Unimplemented([method1 method2]);

=head1 DESCRIPTION

This module is to add unimplmented methods into an interface module, which 
inherits AutoCode::Root directly or indirectly.

=head1 HISTORY

=cut

=cut
