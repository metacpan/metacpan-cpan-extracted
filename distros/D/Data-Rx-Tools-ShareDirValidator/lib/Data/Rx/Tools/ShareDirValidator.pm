use strict;
use warnings;

package Data::Rx::Tools::ShareDirValidator;
BEGIN {
  $Data::Rx::Tools::ShareDirValidator::AUTHORITY = 'cpan:KENTNL';
}
{
  $Data::Rx::Tools::ShareDirValidator::VERSION = '0.1.3';
}

# ABSTRACT: A Simple base class for generating simple validators based on Data::Rx



use Data::Rx;
use File::ShareDir qw();
use Path::Tiny qw();
use Scalar::Util qw( blessed );


sub filename { return 'schema' }


sub suffix { return '.json' }

my $cache;


sub check {
  my ( $self, $data ) = @_;
  if ( not exists $cache->{ _CLASS($self) } ) {
    $cache->{ _CLASS($self) } = _CLASS($self)->_make_rx;
  }
  return $cache->{ _CLASS($self) }->check($data);
}


sub decode_file {
  my ( $self, $file ) = @_;
  require JSON;
  return JSON->new()->utf8(1)->relaxed(1)->decode( scalar $file->slurp() );
}

sub _make_rx {
  my ($self) = @_;
  return Data::Rx->new()->make_schema( _CLASS($self)->decode_file( _CLASS($self)->_specfile ) );
}

sub _sharedir {
  my ($self) = @_;
  return Path::Tiny::path( File::ShareDir::module_dir( _CLASS($self) ) );
}

sub _specfile {
  my ($self) = @_;
  return _CLASS($self)->_sharedir->child( _CLASS($self)->filename . _CLASS($self)->suffix );
}

sub _CLASS {
  my ($classname) = @_;
  return blessed $classname if ( ref $classname && blessed $classname );
  return $classname if not ref $classname;
  require Carp;
  ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
  Carp::croak( q{Argument 0 was an unblessed ref instead of the expected classname,}
      . q{ ensure you are calling the method right with $classname->check( $data ) or similar} );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Data::Rx::Tools::ShareDirValidator - A Simple base class for generating simple validators based on Data::Rx

=head1 VERSION

version 0.1.3

=head1 SYNOPSIS

  package Foo;
  use Data::Rx::Tools::ShareDirValidator;
  use parent 'Data::Rx::Tools::ShareDirValidator';

  sub filename { 'schema' } # default value.
  sub suffix  {'.json'} # default value.

  1;

  ...

Later:

  use Foo;
  Foo->check({ some => [ 'data', 'structure' ] }) # true/false

  1;

=head1 DESCRIPTION

The purpose of this is to make creating a portable validator with Data::Rx as painless as possible, while still
permitting you to keep the specification itself separate from the actual implementation.

=head1 METHODS

=head2 filename

Defaults to just 'schema' and is combined with L</suffix> to form the name of the file
to load from the share directory.

=head2 suffix

Defaults to '.json' and is combined with L</filename> to form the name of the file.

=head2 check

  ClassName->check( $data )

Does all the lifting behind this module and validates the data in $data.

=head2 decode_file

Defaults to a decoder that can read JSON files.

  ->decode_file( Path::Class::File $file )

Override this method with something else if you don't want JSON files.

=head1 IMPLEMENTATION INSTRUCTIONS

=over 4

=item 1. Create package 'Foo' and fill it with the generic boilerplate to extend the base class.

=item 2. Generate your Data::Rx schema in the format you desire ( ideally JSON ) and place it in the modules "Share" directory.

( i.e.: With Dist::Zilla, you would do this:

  [ModuleSharedirs]
  Foo = sharedir/Foo

or something similar. )

=item 3. Ship your distribution and/or install it.

=item 4. Use it by simply doing:

  use Foo;
  if( Foo->check({ datastructure => [] })

passing the data structure you need validated to check().

=back

=head1 EXTENDING

By default, we assume you want JSON for everything, so by default, the suffix is ".json",
and the default deserialiser is as follows:

  sub decode_file {
    my ( $self, $file ) = @_;
    require JSON;
    return JSON->new()->utf8(1)->relaxed(1)->decode( scalar $file->slurp() );
  }

If you want to use a file format other than JSON, overriding the suffix and decode_file sub is required.

Note: C<$file> in this context is a L<< C<file> from Path::Class|Path::Class::File >>, which is why we can
just do C<slurp()> on it.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
