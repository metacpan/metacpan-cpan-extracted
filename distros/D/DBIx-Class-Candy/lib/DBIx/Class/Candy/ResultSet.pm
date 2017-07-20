package DBIx::Class::Candy::ResultSet;
$DBIx::Class::Candy::ResultSet::VERSION = '0.005003';
use strict;
use warnings;

use MRO::Compat;
use Sub::Exporter 'build_exporter';
use Carp 'croak';

# ABSTRACT: Sugar for your resultsets

sub base { return $_[1] || 'DBIx::Class::ResultSet' }

sub perl_version { return $_[1] }

sub experimental { $_[1] }

sub import {
   my $self = shift;

   my $inheritor = caller(0);
   my $args         = $self->parse_arguments(\@_);
   my $perl_version = $self->perl_version($args->{perl_version});
   my $experimental = $self->experimental($args->{experimental});
   my @rest         = @{$args->{rest}};

   $self->set_base($inheritor, $args->{base});
   $inheritor->load_components(@{$args->{components}});

   @_ = ($self, @rest);
   my $import = build_exporter({
      installer  => $self->installer,
      collectors => [ INIT => $self->gen_INIT($perl_version, $inheritor, $experimental) ],
   });

   goto $import
}

sub parse_arguments {
  my $self = shift;
  my @args = @{shift @_};

  my $skipnext;
  my $base;
  my @rest;
  my $perl_version = undef;
  my $components   = [];
  my $experimental;

  for my $idx ( 0 .. $#args ) {
    my $val = $args[$idx];

    next unless defined $val;
    if ($skipnext) {
      $skipnext--;
      next;
    }

    if ( $val eq '-base' ) {
      $base = $args[$idx + 1];
      $skipnext = 1;
    } elsif ( $val eq '-perl5' ) {
      $perl_version = ord $args[$idx + 1];
      $skipnext = 1;
    } elsif ( $val eq '-experimental' ) {
      $experimental = $args[$idx + 1];
      $skipnext = 1;
    } elsif ( $val eq '-components' ) {
      $components = $args[$idx + 1];
      $skipnext = 1;
    } else {
      push @rest, $val;
    }
  }

  return {
    base         => $base,
    perl_version => $perl_version,
    components   => $components,
    rest         => \@rest,
    experimental => $experimental,
  };
}

sub installer {
  my ($self) = @_;
  sub {
    Sub::Exporter::default_installer @_;
  }
}

sub set_base {
   my ($self, $inheritor, $base) = @_;

   # inlined from parent.pm
   for ( my @useless = $self->base($base) ) {
      s{::|'}{/}g;
      require "$_.pm"; # dies if the file is not found
   }

   {
      no strict 'refs';
      # This is more efficient than push for the new MRO
      # at least until the new MRO is fixed
      @{"$inheritor\::ISA"} = (@{"$inheritor\::ISA"} , $self->base($base));
   }
}

sub gen_INIT {
  my ($self, $perl_version, $inheritor, $experimental) = @_;
  sub {
    my $orig = $_[1]->{import_args};
    $_[1]->{import_args} = [];

    strict->import;
    warnings->import;

    if ($perl_version) {
       require feature;
       feature->import(":5.$perl_version")
    }

    if ($experimental) {
       require experimental;
       die 'experimental arg must be an arrayref!'
          unless ref $experimental && ref $experimental eq 'ARRAY';
       # to avoid experimental referring to the method
       experimental::->import(@$experimental)
    }

    mro::set_mro($inheritor, 'c3');

    1;
  }
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::Candy::ResultSet - Sugar for your resultsets

=head1 SYNOPSIS

 package MyApp::Schema::ResultSet::Artist;

 use DBIx::Class::Candy::ResultSet
   -components => ['Helper::ResultSet::Me'];

 use experimental 'signatures';

 sub by_name ($self, $name) { $self->search({ $self->me . 'name' => $name }) }

 1;

=head1 DESCRIPTION

C<DBIx::Class::Candy::ResultSet> is an initial sugar layer in the spirit of
L<DBIx::Class::Candy>.  Unlike the original it does not define a DSL, though I
do have plans for that in the future.  For now all it does is set some imports:

=over

=item *

turns on strict and warnings

=item *

sets your parent class

=item *

sets your mro to C<c3>

=back

=head1 IMPORT OPTIONS

See L</SETTING DEFAULT IMPORT OPTIONS> for information on setting these schema wide.

=head2 -base

 use DBIx::Class::Candy::ResultSet -base => 'MyApp::Schema::ResultSet';

The first thing you can do to customize your usage of C<DBIx::Class::Candy::ResultSet>
is change the parent class.  Do that by using the C<-base> import option.

=head2 -components

 use DBIx::Class::Candy::ResultSet -components => ['Helper::ResultSet::Me'];

C<DBIx::Class::Candy::ResultSet> allows you to set which components you are using at
import time.

=head2 -perl5

 use DBIx::Class::Candy::ResultSet -perl5 => v20;

I love the new features in Perl 5.20, so I felt that it would be
nice to remove the boiler plate of doing C<< use feature ':5.20' >> and
add it to my sugar importer.  Feel free not to use this.

=head1 SETTING DEFAULT IMPORT OPTIONS

Eventually you will get tired of writing the following in every single one of
your resultsets:

 use DBIx::Class::Candy::ResultSet
   -base      => 'MyApp::Schema::ResultSet',
   -perl5     => v20,
   -experimental => ['signatures'];

You can set all of these for your whole schema if you define your own C<Candy::ResultSet>
subclass as follows:

 package MyApp::Schema::Candy::ResultSet;

 use base 'DBIx::Class::Candy::ResultSet';

 sub base { $_[1] || 'MyApp::Schema::ResultSEt' }
 sub perl_version { 20 }
 sub experimental { ['signatures'] }

Note the C<< $_[1] || >> in C<base>.  All of these methods are passed the
values passed in from the arguments to the subclass, so you can either throw
them away, honor them, die on usage, or whatever.  To be clear, if you define
your subclass, and someone uses it as follows:

 use MyApp::Schema::Candy::ResultSet
    -base => 'MyApp::Schema::ResultSet',
    -perl5 => v18,
   -experimental => ['postderef'];

Your C<base> method will get C<MyApp::Schema::ResultSet>, your C<experimental>
will get C<['postderef']>, and your C<perl_version> will get C<18>.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
