package Class::Usul::Programs;

use namespace::autoclean;

use Class::Usul::Constants qw( TRUE );
use Class::Usul::Functions qw( find_apphome get_cfgfiles );
use File::DataClass::Types qw( Directory );
use Scalar::Util           qw( blessed );
use Moo;
use Class::Usul::Options;

extends q(Class::Usul);
with    q(Class::Usul::TraitFor::OutputLogging);
with    q(Class::Usul::TraitFor::Prompting);
with    q(Class::Usul::TraitFor::DebugFlag);
with    q(Class::Usul::TraitFor::Usage);
with    q(Class::Usul::TraitFor::RunningMethods);

# Override attribute default in base class
has '+config_class' => default => 'Class::Usul::Config::Programs';

# Public attributes
option 'home'    => is => 'lazy', isa => Directory, format => 's',
   documentation => 'Directory containing the configuration file',
   builder       => sub { $_[ 0 ]->config->home }, coerce => TRUE;

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_;

   my $attr = $orig->( $self, @args ); my $conf = $attr->{config} //= {};

   my $appclass = delete $attr->{appclass}; my $home = delete $attr->{home};

   $conf->{appclass} //= $appclass || blessed $self || $self;
   $conf->{home    } //= find_apphome $conf->{appclass}, $home;
   $conf->{cfgfiles} //= get_cfgfiles $conf->{appclass}, $conf->{home};

   return $attr;
};

sub BUILD {} # Modified by applied roles

1;

__END__

=pod

=encoding utf8

=head1 Name

Class::Usul::Programs - Re-composable support for command line programs

=head1 Synopsis

   # In YourClass.pm
   use Moo;

   extends q(Class::Usul::Programs);

   # In yourProg.pl
   use YourClass;

   exit YourClass->new_with_options( appclass => 'YourApplicationClass' )->run;

=head1 Description

This base class provides methods common to command line programs. The
constructor can initialise a multi-lingual message catalogue if required

=head1 Configuration and Environment

Supports this list of command line options:

=over 3

=item C<home>

Directory containing the configuration file

=back

Defines these attributes;

=over 3

=item C<config_class>

Overrides the default in the base class, setting it to
C<Class::Usul::Config::Programs>

=back

=head1 Subroutines/Methods

=head2 BUILDARGS

Called just before the object is constructed this method modifier determines
the location of the configuration file

=head2 BUILD

This empty subroutine exists to allow for modification by the applied roles

=head1 Diagnostics

Turning debug on produces log output at the debug level

=head1 Dependencies

=over 3

=item L<Class::Usul::Options>

=item L<Class::Usul::TraitFor::DebugFlag>

=item L<Class::Usul::TraitFor::OutputLogging>

=item L<Class::Usul::TraitFor::Prompting>

=item L<Class::Usul::TraitFor::RunningMethods>

=item L<Class::Usul::TraitFor::Usage>

=item L<Moo>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Usul.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2018 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
