package Class::XSAccessor::Compat;
use 5.008;
use strict;
use warnings;
our $VERSION = '0.01';
use Class::XSAccessor;
use Class::Accessor::Fast;
our @ISA = qw(Class::Accessor::Fast);

# The following is almost 100% the same as Ruslan Zakirov's code:
sub make_ro_accessor {
  my($class, $field) = @_;

  my $sub = $class ."::__cxs_ro_". $field;
  # Do not copy this code. It's the only place where this internal function should be used:
  Class::XSAccessor::newxs_getter($sub, $field);

  no strict 'refs';
  return \&{$sub};
}

sub make_wo_accessor {
  my($class, $field) = @_;

  my $sub = $class ."::__cxs_wo_". $field;
  # Do not copy this code. It's the only place where this internal function should be used:
  Class::XSAccessor::_newxs_compat_setter($sub, $field);

  no strict 'refs';
  return \&{$sub};
}

sub make_accessor {
  my($class, $field) = @_;

  my $sub = $class ."::__cxs_ac_". $field;
  # Do not copy this code. It's the only place where this internal function should be used:
  Class::XSAccessor::_newxs_compat_accessor($sub, $field);

  no strict 'refs';
  return \&{$sub};
}




1;

__END__

=head1 NAME

Class::XSAccessor::Compat - Class::Accessor::Fast compatible interface for Class::XSAccessor

=head1 SYNOPSIS

Use it like you would use C<Class::Accessor::Fast>. But B<MUCH> faster.

=head1 DESCRIPTION

C<Class::XSAccessor::Compat> implements a compatibility layer for
L<Class::Accessor::Fast> on top of L<Class::XSAccessor>.

It should work exactly the same way as C<Class::Accessor::Fast>.
If you find that is not the case, please report your findings as a bug.

=head1 SEE ALSO

=over

=item * L<Class::XSAccessor>

=item * L<Class::Accessor::Fast>

=item * L<Class::Accessor::Fast::XS>

... which is a fork of C<Class::XSAccessor> and provides the same interface
as this module. But it doesn't have the same maintenance and optimization
level as C<Class::XSAccessor> itself.

=item * L<Class::Accessor>

=back

=head1 ACKNOWLEDGMENT

This module was inspired by and based on Ruslan Zakirov's
C<Class::Accessor::Fast::XS> module. That, in turn was heavily based
on an old version of C<Class::XSAccessor>.

=head1 AUTHOR

Steffen Mueller E<lt>smueller@cpan.orgE<gt>

chocolateboy E<lt>chocolate@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
