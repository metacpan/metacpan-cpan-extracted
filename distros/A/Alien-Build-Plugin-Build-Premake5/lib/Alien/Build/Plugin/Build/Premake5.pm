use strict;
use warnings;

package Alien::Build::Plugin::Build::Premake5;
# ABSTRACT: Premake5 build plugin for Alien::Build

our $VERSION = '0.002';

use Alien::Build::Plugin;

has os           => sub { undef };
has cc           => sub { undef };
has dc           => sub { undef };
has dotnet       => sub { undef };
has fatal        => sub { undef };
has file         => sub { undef };
has insecure     => sub { undef };
has scripts      => sub { undef };
has systemscript => sub { undef };
has verbose      => sub { undef };

has action => 'gmake';

sub init {
  my ($self, $meta) = @_;

  $meta->add_requires( 'share', 'Alien::premake5' => '0.001' );
  $meta->add_requires( 'configure',
    'Alien::Build::Plugin::Build::Premake5' => '0.001'
  );

  $meta->apply_plugin( 'Build::Make', make_type => 'gmake' );

  $meta->interpolator->replace_helper(
    premake5 => sub {
      require Alien::premake5;
      my @cmd = Alien::premake5->exe;

      foreach my $key (qw( cc dc dotnet file os scripts systemscript )) {
        my $val = $self->$key;
        next unless defined $val;
        next if $key eq 'os' and $val eq $self->os_string;
        push @cmd, "--$key=$val" if $val;
      }

      foreach my $key (qw( fatal insecure verbose )) {
        push @cmd, "--$key" if defined $self->$key;
      }

      return join ' ', @cmd;
    },
  );

  $meta->interpolator->add_helper(
    premake => $meta->interpolator->has_helper('premake5'),
  );

  $meta->default_hook(
    build => [
      '%{premake5} ' . $self->action,
      '%{make}',
      '%{make} install',
    ]
  );

}

sub os_string {
  my ($self) = shift;

  my $os = '';
  for ($^O) {
       if (/aix/i)     { $os = 'aix' }
    elsif (/bsd/i)     { $os = 'bsd' }
    elsif (/darwin/i)  { $os = 'macosx' }
    elsif (/haiku/i)   { $os = 'haiku' }
    elsif (/hurd/i)    { $os = 'hurd' }
    elsif (/linux/i)   { $os = 'linux' }
    elsif (/mswin32/i) { $os = 'windows' }
    elsif (/solaris/i) { $os = 'solaris' }
  }

  return $os;
}

1;

__END__

=encoding utf8

=head1 NAME

Alien::Build::Plugin::Build::Premake5 - Premake5 build plugin for Alien::Build

=head1 SYNOPSIS

    use alienfile;
    plugin 'Build::Premake5';

=head1 DESCRIPTION

This plugin provides tools to build projects that use premake5. In particular,
it adds the C<%{premake5}> helper, which can be used in L<alienfile> recipes,
and adds a default build stage with the following commands:

    '%{premake} ' . $action,
    '%{make}',
    '%{make} install',

Since premake5 requires gmake, loading this plugin will also load the
L<Build::Make|https://metacpan.org/pod/Alien::Build::Plugin::Build::Make>
plugin with its C<make_type> option set to "gmake".

=head1 OPTIONS

With the exception of the B<action> property, this plugin's options follow
those of the C<premake5> client. For more information, consult the client's
documentation.

=over 4

=item B<action>

Specify the action for premake5. This defaults to "gmake", but is only really
used in the default build phase. If you are providing your own build phase,
then the value of this property will largely be ignored.

For a list of valid actions, check the premake5 client's documentation.

=back

=head2 Flags

These flags can only be set to true or false. They will be ignored if false.

=over 4

=item B<fatal>

Treat warnings from project scripts as errors.

=item B<insecure>

Forfeit SSH certification checks.

=item B<verbose>

Generate extra debug text output.

=back

=head2 Key / value pairs

=over 4

=item B<os>

Generate files for a different operating system. Valid values are
"aix", "bsd", "haiku", "hurd", "linux", "macosx", "solaris", or "windows".

=item B<cc>

Choose a C/C++ compiler set. Valid values are "clang" or "gcc".

=item B<dc>

Choose a D compiler. Valid values are "dmd", "gdc", or "ldc".

=item B<dotnet>

 Choose a .NET compiler set. Valid values are "msnet", "mono", or "pnet".

=item B<file>

Read FILE as a premake5 script. The default is C<premake5.lua>.

=item B<scripts>

Search for additional scripts on the given path.

=item B<systemscript>

Override default system script (C<premake5-system.lua>).

=back

=head1 METHODS

=over 4

=item B<os_string>

This method provides a mapping between the C<$^O> Perl variable and the
operating system labels used by premake5. The return values are the same as
those in the list of valid values for the B<os> option.

If the operating system is not supported, or is impossible to determine, the
returned value will be the empty string.

=back

=head1 HELPERS

=over 4

=item B<premake>

=item B<premake5>

The C<%{premake5}> is defined by L<Alien::premake5> to be the executable of
premake client. This plugin replaces that helper to include any options as
they were passed to the plugin. It also defines a convenience C<%{premake}>
helper, with the same content.

Buy default, all options are turned off.

=back

=head1 SEE ALSO

=over 4

=item * L<https://premake.github.io/>

=back

=head1 CONTRIBUTIONS AND BUG REPORTS

Contributions of any kind are most welcome!

The main repository for this distribution is on
L<Github|https://github.com/jjatria/Alien-Build-Plugin-Build-Premake5>, which is
where patches and bug reports are mainly tracked. Bug reports can also be sent
through the CPAN RT system, or by mail directly to the developers at the
addresses below, although these will not be as closely tracked.

=head1 AUTHOR

=over 4

=item * José Joaquín Atria <jjatria@cpan.org>

=back

=head1 ACKNOWLEDGEMENTS

Special thanks to Graham Ollis for his help in the preparation of this
distribution.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
