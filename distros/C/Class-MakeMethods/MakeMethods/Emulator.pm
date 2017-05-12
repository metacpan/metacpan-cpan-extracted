package Class::MakeMethods::Emulator;

$VERSION = 1.009;

########################################################################
### IMPORT BEHAVIOR: import(), _handle_namespace()
########################################################################

@EXPORT_OK = qw( namespace_capture namespace_release );
sub import { 
  
  if ( scalar @_ == 2 and $_[1] eq '-isasubclass' ) {
    splice @_, 1, 1;
    my $target_class = ( caller )[0];
    no strict;
    push @{"$target_class\::ISA"}, $_[0];
  }
  
  if ( $_[0] eq __PACKAGE__ ) {
    require Exporter and goto &Exporter::import  # lazy Exporter
  }
}

sub _handle_namespace {
  my $class = shift;
  my $emulation_target = shift;
  my $firstarg = shift or return;
  my $take = shift || '-take_namespace';
  my $release = shift || '-release_namespace';
  
  if ( $firstarg eq $take) {
    Class::MakeMethods::Emulator::namespace_capture($class, $emulation_target);
    return 1;
  } elsif ( $firstarg eq $release) {
    Class::MakeMethods::Emulator::namespace_release($class, $emulation_target);
    return 1;
  }
}

########################################################################
### NAMESPACE MUNGING: _namespace_capture(), _namespace_release()
########################################################################

sub namespace_capture {
  my $source_package = shift;
  my $target_package = shift;

  # warn "Mapping $source_package over $target_package \n";

  my $source_file = "$source_package.pm";
  $source_file =~ s{::}{/}g;
  
  my $target_file = "$target_package.pm";
  $target_file =~ s{::}{/}g;
  
  my $temp_package = $source_package . '::Target::' . $target_package;
  my $temp_file = "$temp_package.pm";
  $temp_file =~ s{::}{/}g;
  
  no strict;
  unless ( ${$temp_package . "::TargetCaptured"} ++ ) {
    *{$temp_package . "::"} = *{$target_package . "::"};
    $::INC{$temp_file} = $::INC{$target_file};
  }
  *{$target_package . "::"} = *{$source_package . "::"};
  $::INC{$target_file} = $::INC{$source_file}
}

sub namespace_release {
  my $source_package = shift;
  my $target_package = shift;
  
  my $target_file = "$target_package.pm";
  $target_file =~ s{::}{/}g;
  
  my $temp_package = $source_package . '::Target::' . $target_package;
  my $temp_file = "$temp_package.pm";
  $temp_file =~ s{::}{/}g;
  
  no strict;
  unless ( ${"${temp_package}::TargetCaptured"} ) {
    Carp::croak("Can't _namespace_release: -take_namespace not called yet.");
  }
  *{$target_package . "::"} = *{$temp_package. "::"};
  $::INC{$target_file} = $::INC{$temp_file};
}

########################################################################

1;

__END__


=head1 NAME

Class::MakeMethods::Emulator - Demonstrate class-generator equivalency


=head1 SYNOPSIS

  # Equivalent to use Class::Singleton;
  use Class::MakeMethods::Emulator::Singleton; 
  
  # Equivalent to use Class::Struct;
  use Class::MakeMethods::Emulator::Struct; 
  struct ( ... );
  
  # Equivalent to use Class::MethodMaker( ... );
  use Class::MakeMethods::Emulator::MethodMaker( ... );
  
  # Equivalent to use base 'Class::Inheritable';
  use base 'Class::MakeMethods::Emulator::Inheritable';
  MyClass->mk_classdata( ... );
  
  # Equivalent to use base 'Class::AccessorFast';
  use base 'Class::MakeMethods::Emulator::AccessorFast';
  MyClass->mk_accessors(qw(this that whatever));
  
  # Equivalent to use accessors( ... );
  use Class::MakeMethods::Emulator::accessors( ... );
  
  # Equivalent to use mcoder( ... );
  use Class::MakeMethods::Emulator::mcoder( ... );


=head1 DESCRIPTION

In several cases, Class::MakeMethods provides functionality closely
equivalent to that of an existing module, and it is simple to map
the existing module's interface to that of Class::MakeMethods.

Class::MakeMethods::Emulator provides emulators for Class::MethodMaker,
Class::Accessor::Fast, Class::Data::Inheritable, Class::Singleton,
Class::Struct, accessors, and mcoder, each of which passes the
original module's test suite, usually requiring only the addition
of a a single line to each test, activating the emulation module.

Beyond demonstrating compatibility, these emulators also generally
indicate the changes needed to switch to direct use of Class::MakeMethods
functionality, illustrate commonalities between the various modules,
and serve as a source for new ideas that can be integrated into
Class::MakeMethods.


=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

See L<Class::MakeMethods::Emulator::accessors>, and L<accessors> from CPAN.

See L<Class::MakeMethods::Emulator::Struct>, and L<Class::Struct> from CPAN.

See L<Class::MakeMethods::Emulator::AccessorFast>, and L<Class::Accessor::Fast> from CPAN.

See L<Class::MakeMethods::Emulator::Inheritable>, and L<Class::Data::Inheritable> from CPAN.

See L<Class::MakeMethods::Emulator::MethodMaker>, and L<Class::MethodMaker> from CPAN.

See L<Class::MakeMethods::Emulator::Singleton>, and L<Class::Singleton> from CPAN.

See L<Class::MakeMethods::Emulator::mcoder>, and L<mcoder> from CPAN.

=cut

