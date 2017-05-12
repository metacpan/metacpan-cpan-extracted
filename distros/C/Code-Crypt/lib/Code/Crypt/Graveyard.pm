package Code::Crypt::Graveyard;
{
  $Code::Crypt::Graveyard::VERSION = '0.001000';
}

# ABSTRACT: Encrypt you code with multiple nested keys

use Moo;

has code => (
   is => 'ro',
   required => 1,
);

has builders => (
   is => 'ro',
   required => 1,
);

sub _builder_at { $_[0]->builders->[$_[1]] }
sub _innermost_builder { $_[0]->_builder_at(0) }
sub _outermost_builder { $_[0]->_builder_at($_[0]->_final_builder_index) }
sub _final_builder_index { scalar @{$_[0]->builders} - 1 }

sub final_code {
   my $self = shift;

   $self->_innermost_builder->code($self->code);

   for my $builder_id (1 .. $self->_final_builder_index) {
      my $builder = $self->_builder_at($builder_id);
      my $wrapped_builder = $self->_builder_at($builder_id - 1);
      $builder->code($wrapped_builder->final_code);
   }
   $self->_outermost_builder->final_code
}

1;

__END__

=pod

=head1 NAME

Code::Crypt::Graveyard - Encrypt you code with multiple nested keys

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

 use Code::Crypt;
 use Code::Crypt::Graveyard;

 print "#!/usr/bin/env perl\n\n" . Code::Crypt::Graveyard->new(
    code => 'print "hello world!\n";',
    builders => [
       Code::Crypt->new(
          get_key => q{ $] },
          key => $],
          cipher => 'Crypt::Rijndael',
       ),
       Code::Crypt->new(
          get_key => q{ $^O },
          key => $^O,
          cipher => 'Crypt::Rijndael',
       ),
       Code::Crypt->new(
          get_key => q{
             require Sys::Hostname;
             Sys::Hostname::hostname();
          },
          key => 'wanderlust',
          cipher => 'Crypt::Rijndael',
       ),
    ],
 )->final_code

=head1 DESCRIPTION

C<Code::Crypt::Graveyard> leverages L<Code::Crypt> to encrypt code in a nested
fashion.  This can help to keep what inner keys are a secret.  In the example
given in the L</SYNOPSIS> the outermost key is the hostname.  The inner keys are
the operating system and the perl version.  Of course, as with L<Code::Crypt>, a
technically proficient user that the code is targetted towards can likely remove
all encryption entirely.

=head1 METHODS

=head2 C<final_code>

 my $code = $cc->final_code;

This method takes no arguments.  It returns the compiled code based on the
L</ATTRIBUTES>.

=head1 ATTRIBUTES

=head2 C<code>

B<required>. The code that will be encrypted.

=head2 C<builders>

B<required>.  An arrayref of L<Code::Crypt> objects that will encrypt the
L</code> recursively.  Innermost is first.

=head1 SEE ALSO

L<Code::Crypt>

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
