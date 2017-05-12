
package Config::Constants::Perl;

use strict;
use warnings;

our $VERSION = '0.02';

sub new {
    my ($class, $file) = @_;
    (defined $file)
        || die "No config file supplied";
    my $self = bless({}, ref($class) || $class);
    $self->_init($file);
    return $self;
}

sub _init {
    my ($self, $file) = @_;
    (-e $file && -f $file)
        || die "Bad config file '$file' either it doesn't exist or it's not a file";    
    my $config = eval { do $file };
    (ref($config) eq 'HASH')
        || die "Config file must return a hash";
    $self->{_config} = $config;
}

sub modules { keys %{(shift)->{_config}} }

sub constants {
    my ($self, $module) = @_;  
    (defined $module)
        || die "You must supply a module name";
    (exists $self->{_config}->{$module})
        || die "The module ($module) is not found in this config";  
    return map {{ $_ => $self->{_config}->{$module}->{$_} }} keys %{$self->{_config}->{$module}};
}

1;

__END__

=head1 NAME

Config::Constants::Perl - Configuration loader for Config::Constants

=head1 SYNOPSIS
  
  use Config::Constants::Perl;

=head1 DESCRIPTION

This module reads and evaluates perl files as configuration files. This is a highly unsafe option unless your configuration files are secure since we use the C<do> function to read the file. You should take great caution in using this module/feature. For a safer option, consider L<Config::Constants::XML>.

That said, your perl data structures should look like this:

  {
      'Foo::Bar' => {
          'BAZ' => 'the coolest module ever',
      }
  }  
  
The main structure is a hash, each key being your module name, their values being an Array of Hashes. Those hashes each having exactly one key-value pair. The key is the name of the constant (which should be a valid perl identifier), and the value should be the constant value you want.

=head1 METHODS

=over 4

=item B<new ($file)>

This takes the file, loads it and stores the resulting hash.

=item B<modules>

This will return an array of modules in this configuration.

=item B<constants ($module_name)>

Given a C<$module_name>, this will return an array of hash references for each constant specified.

=back

=head1 TO DO

=over 4

=item Consider making this safer using Safe.pm?

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, see the L<Config::Constants> module for more information.

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

