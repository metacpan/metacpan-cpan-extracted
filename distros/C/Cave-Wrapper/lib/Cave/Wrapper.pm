use 5.006;    # our
use strict;
use warnings;

package Cave::Wrapper;

# ABSTRACT: A Wrapper to the Paludis 'cave' Client.

our $VERSION = '1.000001';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY
























































































use Moo;
use Sub::Install;
use namespace::autoclean;
use Carp qw();

no Moo;

sub _cave_exec_to_list {
  my @args = @_;
  my (@output);
  {
    ## no critic ( ProhibitPunctuationVars )
    open my $fh, q{-|}, 'cave', @args or Carp::croak("Error executing 'cave': $@ $? $!");
    @output = <$fh>;
    close $fh or Carp::carp("Closing 'cave' returned an error: $@ $? $!");
  }
  chomp for @output;
  return @output;
}

my %collisions = map { $_ => 1 } qw( import );

our $_COMMANDS_INITIALIZED;

sub _ensure_initialized {
  return if $_COMMANDS_INITIALIZED;
  for my $command ( _cave_exec_to_list( 'print-commands', '--all' ) ) {
    my $method = $command;
    ## no critic ( RegularExpressions )
    $method =~ s{-}{_}g;
    if ( exists $collisions{$command} ) {
      $method = 'cave_' . $method;
    }
    ## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
    Sub::Install::install_sub(
      {
        code => sub {
          shift;
          return _cave_exec_to_list( $command, @_ );
        },
        as   => $method,
        into => __PACKAGE__,
      },
    );
  }
  $_COMMANDS_INITIALIZED = 1;
  return;
}





sub BUILD { return _ensure_initialized }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cave::Wrapper - A Wrapper to the Paludis 'cave' Client.

=head1 VERSION

version 1.000001

=head1 DESCRIPTION

C<cave> is a package management client for the L<Paludis|http://paludis.pioto.org/> package manager available for use with both
the L<Exherbo Linux|http://exherbo.org/> and L<Gentoo Linux|http://gentoo.org/> Distributions.

This module is designed as a syntactic sugar wrapper for that client to minimize development time and clarify code.

    my $cave = Cave::Wrapper->new();
    my @ids = $cave->print_ids(qw( --matches  dev-lang/perl ));

=head1 METHODS

Methods are generated entirely at run-time by introspecting the output from C<cave print-commands --all> and then
generating the appropriate methods. This is mostly because we don't want to have to cut a new release every time
paludis produce a new release I<just> to avoid breaking code.

=head1 CAVEATS

=head2 Naming Collisions

There exists 1 command we cannot perform a native mapping for, and its due to a perlism, and that is C<import>.

For now, this is named C<cave_import> instead.

=head2 Hyphenated Commands

Hyphenated commands can't be used as method names in Perl, so we've translated the hyphens to underscores
in the method names.

i.e.: if you wanted C<print-ids> you now want C<print_ids>

=head2 Slightly Under-powered

This is a first-pass "Just get it working" implementation at this time, and is reasonably useful for the print_ family of commands
the cave client provides. However, you probably do not wish to use it for more complex things like calling C<cave resolve> as it
might cause you untold sorrows while it silently buffers into a growing array and then spews its contents when its finished.

=head1 TODO

One day we'd like to have a sweeter syntax, like

    $cave->print_ids({ matches => 'dev-lang/perl' })

or

    $cave->print_ids({ matches => [ 'dev-lang/perl' , 'dev-lang/python' ]});

However, there are a few problems and questions to be answered, which are not a problem with the existing
syntax but would be a problem with a possible alternative syntax.

=over 4

=item * Toggle Switches

There are a lot of toggle switches that don't take a parameter, and while we could just do

    $cave->print_commands({ all => 1 });

That means we have to get rid of the '1' before we pass the command to C<cave>, and that is going to be difficult to
do without needing tight coupling. Not to mention how to handle C<< all => 2 >> and C<< all => 1 >>.

=item * Fixed Order operations.

Some C<cave> functions require operators to be ordered, so if you needed to do this

    cave foobar --matching foo --not --matching bar

having a structure

    $cave->foobar({ matching => [ 'foo', 'bar' ]} , '--not' )

would obviously not work.

    $cave->foobar([ matching => 'foo', not => matching => 'bar' ])

or anything not using a hash is going to be equally confusing, especially as we can now no longer tell what
is a key and what is a value, so adding '--' to the front of them becomes impossible.

=back

=for Pod::Coverage BUILD

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
