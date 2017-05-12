package Class::MakeMethods::Emulator::mcoder;

$VERSION = '0.05';

use Class::MakeMethods::Emulator '-isasubclass';
use Class::MakeMethods::Template '-isasubclass';

########################################################################

sub import {
  my $class = shift;
  ( my $target = $class ) =~ s/^Class::MakeMethods::Emulator:://;
  $class->_handle_namespace( $target, $_[0] ) and shift;
  $class->make( @_ ) if ( scalar @_ );
}


sub new        { 'Template::Hash::new --with_values' }
sub proxy      { 'Template::Universal:forward_methods -target' }
sub generic    { { '-import' => { 'Template::Hash:scalar' => '*' } } }
sub get        { { interface => { default => { '*'       =>'get' } } } }
sub set        { { interface => { default => { 'set_*'   =>'set' } } } }
sub undef      { { interface => { default => { 'undef_*' =>'clear' } } } }
sub delete     { { interface => { default => { 'delete_*'=>'hash_delete' } } } }
sub bool_set   { { interface => { default => { 'set_*'   =>'set_value' } },
		   '-import' => { 'Template::Hash:boolean' => '*' } } }
sub bool_unset { { interface => { default => { 'unset_*' =>'clear' } } } }
sub calculated { { interface => { default => { '*'       =>'get_init' } },
		   params    => { init_method=>'_calculate_*' } } }

########################################################################

foreach my $type ( qw( new get set proxy calculated ) ) {
  $INC{"Class/MakeMethods/Emulator/mcoder/$type.pm"} = 
			     $INC{"mcoder/$type.pm"} = __FILE__;
  *{__PACKAGE__ . "::${type}::import"} = sub {
    (shift) and (__PACKAGE__)->make( $type => [ @_ ] )
  };
}

########################################################################

1;

__END__

package Class::MakeMethods::Emulator::mcoder::get;
@ISA = 'Class::MakeMethods::Emulator::mcoder';
$INC{"Class/MakeMethods/Emulator/mcoder/get.pm"} = __FILE__;
sub import { goto &Class::MakeMethods::Emulator::mcoder::sub_import }

package Class::MakeMethods::Emulator::mcoder::set;
@ISA = 'Class::MakeMethods::Emulator::mcoder';
$INC{"Class/MakeMethods/Emulator/mcoder/set.pm"} = __FILE__;
sub import { goto &Class::MakeMethods::Emulator::mcoder::sub_import }

package Class::MakeMethods::Emulator::mcoder::proxy;
@ISA = 'Class::MakeMethods::Emulator::mcoder';
$INC{"Class/MakeMethods/Emulator/mcoder/proxy.pm"} = __FILE__;
sub import { goto &Class::MakeMethods::Emulator::mcoder::sub_import }


1;

__END__

=head1 NAME

Class::MakeMethods::Emulator::mcoder - Emulate the mcoder module


=head1 SYNOPSIS

  package MyClass;

  use Class::MakeMethods::Emulator::mcoder 
           [qw(get set)] => [qw(color sound height)], 
           proxy => [qw(runner run walk stop)], 
           calculated => weight;

  sub _calculate_weight { shift->ask_weight }


=head1 DESCRIPTION

This module emulates the functionality of the mcoder module, using
Class::MakeMethods to generate similar methods. 

For example, the following lines are equivalent:

  use mcoder 'get' => 'foo';
  use mcoder::get 'foo';
  use Class::MakeMethods::Template::Hash 'scalar --get' => 'foo';

You may use this module directly, as shown in the SYNOPSIS above,
or you may call C<use Class::MakeMethods::Emulator::mcoder
'-take_namespace';> to alias the mcoder namespace to this package,
and subsequent calls to the original package will be transparently
handled by this emulator. To remove the emulation aliasing, call
C<use Class::MakeMethods::Emulator::mcoder '-release_namespace'>.
The same mechanism is also available for the "sugar" subclasses.

B<Caution:> This affects B<all> subsequent uses of the mcoder module in
your program, including those in other modules, and might cause
unexpected effects.


=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Emulator> for more about this family of subclasses.

See L< mcoder> for documentation of the original module.

=cut
