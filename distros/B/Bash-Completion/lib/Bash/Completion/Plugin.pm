package Bash::Completion::Plugin;
{
  $Bash::Completion::Plugin::VERSION = '0.008';
}

# ABSTRACT: base class for Bash::Completion plugins

use strict;
use warnings;


sub new {
  my $class = shift;
  my %args = (args => [], @_);

  return bless \%args, $class;
}



sub args {
  my ($self) = @_;

  return @{$self->{args}};
}



sub should_activate { return [] }



sub generate_bash_setup { return [] }



1;



=pod

=head1 NAME

Bash::Completion::Plugin - base class for Bash::Completion plugins

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    ## Example plugin for xpto command
    package Bash::Completion::Plugin::XPTO;
    
    use strict;
    use warnings;
    use parent 'Bash::Completion::Plugin';
    use Bash::Completion::Utils qw( command_in_path );
    
    sub should_activate {
      return [grep { command_in_path(_) } ('xpto')];
    }
    
    
    ## Optionally, for full control of the generated bash code
    sub generate_bash_setup {
      return q{complete -C 'bash-complete complete XPTO' xpto};
    }
    
    ## Use plugin arguments
    sub generate_bash_setup {
      return q{complete -C 'bash-complete complete XPTO arg1 arg2 arg3' xpto};
    }
    ## $plugin->args will have ['arg1', 'arg2', 'arg3']
    
    
    sub complete {
      my ($self, $r) = @_;
    
      my @options = ('-h', '--help');
      $r->candidates(prefix_match($r->word, @options));
    }
    1;

=head1 DESCRIPTION

    WARNING: the most important class for Plugin writers is the Request
    class. Please note that the Request class interface is Alpha-quality
    software, and I will update it before 1.0.

A base class for L<Bash::Completion> plugins that provides the default
implementations for the required plugin methods.

See the L</SYNOPSIS> for an example of a plugin.

=head1 ATTRIBUTES

=head2 args

An list reference with plugin arguments.

=head1 METHODS

=head2 new

A basic plugin constructor. Accepts a list of key/values. Accepted keys:

=over 4

=item args

A list reference with parameters to this plugin.

=back

=head2 should_activate

The method C<should_activate()> is used by the automatic setup of
completion rules in the .bashrc. It should return a reference to a list
of commands that the plugin is can complete.

If this method returns a reference to an empty list (the default), the
plugin will not be used.

A common implementation of this method is to check the PATH for the
command we want to provide completion, and return the com only if that
command is found.

The L<Bash::Completion::Utils> library has a C<command_in_path()> that
can be pretty useful here.

For example:

    sub should_activate {
      return [grep { command_in_path($_) } qw( perldoc pod )];
    }

=head2 generate_bash_setup

This method receives the list of commands that where found by
L</should_activate> and must return a list of options to use when
creating the bash C<complete> command.

For example, if a plugin returns C<[qw( nospace default )]>, the
following bash code is generated:

    complete -C 'bash-complete complete PluginName' -o nospace -o default command

By default this method returns a reference to an empty list.

Alternatively, and for complete control, you can return a string with
the entire bash code to activate the plugin.

=head2 complete

The plugin completion logic. The class L<Bash::Completion> will call
this method with a L<Bash::Completion::Request> object, and your code
should use the Request C<candidates()> method to set the possible
completions.

The L<Bash::Completion::Utils> library has two functions,
C<match_perl_module()> and C<prefix_math()> that can be pretty
useful here.

=head1 AUTHOR

Pedro Melo <melo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

