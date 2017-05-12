package Acme::Innuendo;

use 5.006001;
use strict;
use warnings;

require Exporter::Lite;

our @ISA = qw(Exporter::Lite);

our @EXPORT_OK = ( );

our @EXPORT = qw(
  special_place nudge_nudge wink_wink walk_the_dog
);

our $VERSION = '0.03';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

sub special_place {
  my $namespace = shift || 'main';
  if (defined $namespace) {
    $namespace .= '::';
  }
  no strict 'refs';
  return *$namespace;
}

sub nudge_nudge {
  my ($root, $sym, $value) = @_;
  $root->{$sym} = $value;
}

sub wink_wink {
  my ($root, $sym) = @_;
  return $root->{$sym};
}


sub walk_the_dog {
  my $root     = shift;
  my $callback = shift || sub { };

  return unless ($root);

  foreach my $sym (keys %$root) {
    my $ref = $root->{$sym};
    if ($sym =~ m/::$/)  {
      walk_the_dog($ref, $callback), if ($sym ne 'main::');
    }
    else {
      &$callback($root,$sym,$ref);
    }
  }
}


1;
__END__


=head1 NAME

Acme::Innuendo - polite access to Perl's private parts

=head1 SYNOPSIS

  use Acme::Innuendo;

  # Create an alias

  nudge_nudge( special_place(), "alias_sub",
    wink_wink( special_place(), "some_sub" )
  );

  # Walk the symbol table

  walk_the_dog( special_place(), sub {
    my ($namespace, $symbol, $ref) = @_;
    print $namespace, $symbol, "\n";
  } );


=head1 DESCRIPTION

This module provides an alternative method of addressing the symbol
table for those who condider it akin to "touching Perl's genitals."

=over

=item special_place

  $root_namespace = special_place();

  $module_namespace = special_place( $module_name );

Returns the name space of the specified module, or the root namespace
if no module is specified.

=item wink_wink

  $ref = wink_wink( $namespace, $symbol );

Returns the glob for the symbol in the given namespace, if it exists.

=item nudge_nudge

  nudge_nudge( $namespace, $symbol, $ref );

Changes or adds the symbol in the namespace.

=item walk_the_dog

  walk_the_dog( $namespace, sub { ... } );

Walks a namespace and sends symbol information to the callback routine.

=back

=head1 SEE ALSO

This module is a bit of humor.  For more serious applications, see the
following modules on CPAN:

  Alias
  Devel::LexAlias
  Lexical::Alias
  Package::Alias
  Tie::Alias
  Tie::Alias::Array
  Tie::Alias::Handle
  Tie::Alias::Hash
  Variable::Alias

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

current Maintainer: Rene Schickbauer <rene.schickbauer at gmail.com>


=head1 REPORTING BUGS

We don't know of any bugs, but that doesn't mean there aren't any.
Please the CPAN bugtracker or mail Rene Schickbauer directly.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Robert Rothenberg.  All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

Now maintained by Rene Schickbauer, so i guess everything after version 0.02
is (C) 2010 Rene Schickbauer

=cut
