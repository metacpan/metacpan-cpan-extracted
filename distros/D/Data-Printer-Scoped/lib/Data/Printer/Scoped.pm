package Data::Printer::Scoped;
# ABSTRACT:  silence Data::Printer except in a controlled scope
$Data::Printer::Scoped::VERSION = '0.001004';
use strict;
use warnings;

use Data::Printer ();
use Import::Into;
use Context::Preserve;
use Class::Method::Modifiers qw(:all);

use base qw(Exporter);

our @EXPORT = qw(scope);

our $enabled = 0;

install_modifier('Data::Printer', 'around', '_print_and_return', sub {
  my $orig = shift;

  # noop unless enabled.
  return $enabled ? $orig->(@_) : ();
});

sub import {
  shift->export_to_level(1);
  Data::Printer->import::into(1);
}

# we only blanket disable Data::Printer if a scope() call has been made.
sub scope(&) {
  my ($code) = @_;

  $enabled = 0;

  return preserve_context { $enabled = 1; $code->() }
             after => sub { $enabled = 0 };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Printer::Scoped - silence Data::Printer except in a controlled scope

=head1 VERSION

version 0.001004

=head1 SYNOPSIS

Sometimes you want to stick a dumper statement on a very hot codepath, but you
are interested in the output of your specific invocation. Often times this is
in the middle of a test. To narrow down when and what gets dumped, you can just
do this:

  use Data::Printer::Scoped qw/scope/;

  scope {
    do_something();
  };

  # elsewhere deep in another package
  sub some_hot_codepath {
    use Data::Printer;
    p $foo;
  }

=head1 PROVIDED FUNCTIONS

=over 4

=item B<scope(&)>

Takes a single code block, and runs it. Before running, the overridden print
method of Data::Printer will be enabled, and disabled afterward.

=back

=head1 AUTHOR

Matthew Phillips <mattp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Matthew Phillips <mattp@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
