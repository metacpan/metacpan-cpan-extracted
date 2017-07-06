use strict;
use warnings;
use 5.014;

package App::af 0.11 {

  use Moose::Role;
  use namespace::autoclean;
  use Getopt::Long qw( GetOptionsFromArray );
  use Pod::Usage   qw( pod2usage           );

  # ABSTRACT: Command line tool for alienfile


  has args => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] }
  );

  sub BUILDARGS
  {
    my($class, @args) = @_;
    
    my($subcommand) = $class =~ /App::af::(.*)/;
    my %args = ( args => \@args );
    
    my @options = (
      'help'    => sub {
        pod2usage({
          -verbose  => 99,
          -sections => $subcommand eq 'default' ? "SYNOPSIS|DESCRIPTION" : "SUBCOMMANDS/$subcommand",
          -exitval => 0,
        }) },
      'version' => sub {
        say "App::af version ", ($App::af::VERSION // 'dev');
        exit;
      },
    );
    
    foreach my $attr ($class->meta->get_all_attributes)
    {
      next unless $attr->does("App::af::opt");
      my $name = $attr->name;
      $name =~ s/_/-/g;
      $name .= '|' . $attr->short    if $attr->short;
      $name .= "=" . $attr->opt_type if $attr->opt_type;
      if($attr->is_array)
      {
        my @array;
        $args{$attr->name} = \@array;
        push @options, $name => \@array;
      }
      else
      {
        push @options, $name => \$args{$attr->name};
      }
    }
    
    GetOptionsFromArray(\@args, @options)
      || pod2usage({
           -exitval => 1, 
           -verbose => 99, 
           -sections => $subcommand eq 'default' ? 'SYNOPSIS' : "SUBCOMMANDS/$subcommand/Usage",
         });
    
    delete $args{$_} for grep { ! defined $args{$_} } keys %args;

    \%args,
  }

  sub compute_class
  {
    defined $ARGV[0] && $ARGV[0] !~ /^-/
      ? 'App::af::' . shift @ARGV
      : 'App::af::default';
  }
  
  requires 'main';  
}

package App::af::default 0.11 {

  use Moose;
  with 'App::af';

  sub main
  {
    say "App::af version @{[ $App::af::VERSION || 'dev' ]}";
    say "  af --help for usage information";
    0;
  }

  __PACKAGE__->meta->make_immutable;
}

package App::af::role::alienfile 0.11 {

  use Moose::Role;
  use namespace::autoclean;
  use MooseX::Types::Path::Tiny qw( AbsPath );
  use Path::Tiny qw( path );
  use File::Temp qw( tempdir );
  
  has file => (
    is       => 'ro',
    isa      => AbsPath,
    traits   => ['App::af::opt'],
    short    => 'f',
    opt_type => 's',
    default  => 'alienfile',
    coerce   => 1,
  );
  
  has class => (
    is       => 'ro',
    isa      => 'Str',
    traits   => ['App::af::opt'],
    short    => 'c',
    opt_type => 's',
  );
  
  sub build
  {
    my($self, %args) = @_;
    
    my $alienfile;
    
    my $prefix;
    
    $args{root} ||= tempdir( CLEANUP => 1);
    
    if($self->class)
    {
      my $class = $self->class =~ /::/ ? $self->class : "Alien::" . $self->class;
      my $pm    = $class . '.pm';
      $pm =~ s/::/\//g;
      require $pm;
      if($class->can('runtime_prop') && $class->runtime_prop)
      {
        my $dist = path($class->dist_dir);
        $alienfile = $dist->child('_alien/alienfile');
        my $patch = $dist->child('_alien/patch');
        $args{patch} = $patch->stringify if -d $patch;
        $prefix = $dist->stringify;
      }
      else
      {
        say STDERR "class @{[ $self->class ]} does not appear to have been installed using Alien::Build";
        exit 2;
      }
    }
    else
    {
      $alienfile = $self->file;
    }

    unless(-r $alienfile)
    {
      say STDERR "unable to read $alienfile";
      exit 2;
    }
    
    if(my $patch = $alienfile->parent->child('patch'))
    {
      if(-d $patch)
      {
        $args{patch} = "$patch";
      }
    }
  
    require Alien::Build;
    my $build = Alien::Build->load("$alienfile", %args);
    
    wantarray ? ($build, $prefix) : $build;

  }  
}

package App::af::role::phase 0.11 {

  use Moose::Role;
  use namespace::autoclean;
  
  has phase => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'all',
    traits   => ['App::af::opt'],
    opt_type => 's',
    short    => 'p',
  );
  
  sub check_phase
  {
    my($self) = @_;
    
    if($self->phase !~ /^(configure|any|all|share|system)$/)
    {
      say STDERR "unknown phase: @{[ $self->phase ]}";
      exit 2;
    }
  }
  
}

package App::af::role::libandblib 0.11 {

  use Moose::Role;
  use namespace::autoclean;
  use Path::Tiny qw( path );

  has I => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    traits   => ['App::af::opt'],
    opt_type => 's',
    is_array => 1,
  );
  
  has blib => (
    is       => 'ro',
    isa      => 'Int',
    traits   => ['App::af::opt'],
  );
  
  around main => sub {
    my $orig = shift;
    my $self = shift;
    my @args = @_;

    local @INC = @INC;

    foreach my $inc (reverse @{ $self->I })
    {
      require lib;
      lib->import($inc);
    }
    
    if($self->blib)
    {
      require blib;
      blib->import;
    }

    # make sure @INC entries are absolute, since $build
    # may do a lot of directory changes
    @INC = map { ref $_ ? $_ : path($_)->absolute->stringify } @INC;
    
    $orig->($self, @args);
    
  };

}

package App::af::opt 0.11 {

  use Moose::Role;
  use namespace::autoclean;
  
  has short => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
  );
  
  has opt_type => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
  );
  
  has is_array => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub {
      my($self) = @_;
      int $self->opt_type =~ /\{/;
    },
  );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::af - Command line tool for alienfile

=head1 VERSION

version 0.11

=head1 SYNOPSIS

 af --help

=head1 DESCRIPTION

This class provides the machinery for the af command.

=head1 SEE ALSO

L<af>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
