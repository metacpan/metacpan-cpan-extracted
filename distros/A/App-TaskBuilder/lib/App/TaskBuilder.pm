use strict;
use warnings;

package App::TaskBuilder;
our $VERSION = '1.000';

use File::Spec;
use File::Path ();
use File::Basename ();
use File::Temp ();
use File::Copy ();
use Cwd ();

sub _accessor {
  no strict 'refs';
  my $attr = shift;
  *$attr = sub { @_ > 1 ? ($_[0]->{$attr} = $_[1]) : $_[0]->{$attr} };
}
BEGIN { _accessor($_) for qw(name require include version output) }

sub new {
  my $class = shift;
  my $self = bless {@_} => $class;
  $self->{output} ||= $self->vars->{dist_vname} . ".tar.gz";
  %{ $self->require } = (
    (map {
      my %r = %{ do($_) || die $@ };
      ( 
        %{ $r{requires} || {} },
        %{ $r{test_requires} || {} },
        %{ $r{build_requires} || {} },
      );
    } @{ $self->include }),
    %{ $self->require }
  );
  return $self;
}

sub _dist_name {
  my ($self) = @_;
  (my $name = $self->name) =~ s/::/-/g;
  $name;
}

sub _file_name {
  my ($self) = @_;
  my @parts = split /::/, ($self->name . '.pm');
  File::Spec->catfile('lib', @parts);
}

sub vars {
  my $self = shift;
  use Data::Dumper;
  local $Data::Dumper::Terse = 1;
  my %v = (
    mod_name  => $self->name,
    dist_name => $self->_dist_name,
    mod_file  => $self->_file_name,
    requires  => Dumper($self->require),
    version   => $self->version,
  );
  $v{dist_vname} = "$v{dist_name}-$v{version}";
  return wantarray ? %v : \%v;
}

sub run {
  my $self = shift;
  my $old = Cwd::cwd;
  chdir(my $tmp = File::Temp::tempdir(CLEANUP => 1));

  my %v = $self->vars; 
  mkdir $v{dist_vname}, 0755 or die "Can't mkdir $v{dist_vname}: $!";

  my $s = $self->templates(%v);

  for my $path (keys %$s) {
    my $text = $s->{$path};
    $path = "$v{dist_vname}/$path";
    File::Path::mkpath(File::Basename::dirname($path));
    open my $fh, '>', $path or die "Can't open $path: $!";
    $text =~ s/\{\{(.+?)\}\}/$v{$1}/g;
    print $fh $text;
  }

  # XXX use Archive::Tar or something instead
  system("tar zcf $v{dist_vname}.tar.gz $v{dist_vname}") && exit($? >> 8);

  chdir $old;
  File::Copy::copy "$tmp/$v{dist_vname}.tar.gz", $self->output
    or die "Can't copy to " . $self->output . ": $!";
}

sub _templates {
  my ($self, %v) = @_;
  return {
    'Makefile.PL' => <<'END',
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => '{{mod_name}}',
  VERSION_FROM => '{{mod_file}}',
  ABSTRACT => 'install dependencies for {{mod_name}}',
  PREREQ_PM => {{requires}},
  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean               => { FILES => '{{dist_name}}-*' },
);
END

    'MANIFEST' => <<'END',
Makefile.PL
README
{{mod_file}}
END

    'README' => <<'END',
This is an automatically generated README for {{mod_name}}.
END

    $v{mod_file} => <<'END',
  package
  {{mod_name}};

  ${{mod_name}}::VERSION =
      {{version}};

  1;
END

  };
}

1;
__END__

=head1 NAME

App::TaskBuilder - build empty, dependency-only distributions

=head1 VERSION

version 1.000

=head1 SYNOPSIS

  use App::TaskBuilder;
  App::TaskBuilder->new(%opt)->run;

  # or, more likely

  task-builder --name Task::Foo --version 0.123 --require Some::Module=1.01

  # writes 'Task-Foo-0.123.tar.gz'

=head1 DESCRIPTION

Naming a package C<Task::Something> is a convention for distributions that
exist only to make sure that a certain set of modules is installed.

Building these Task distributions by hand is a pain.  App::TaskBuilder
automates the process, giving you a tarball that you can then upload,
manipulate with CPAN/CPANPLUS, etc.

=head1 PARAMETERS

=head2 name

The name of the Task module to generate.  (Despite referring to C<Task>
throughout this documentation, any module name can be used; it doesn't have to
start with C<Task::>.)

=head2 version

The version (module and distribution) to generate.

=head2 output

The output file to write.  Defaults to C<$name-$version.tar.gz>.

=head2 require

A hashref of module names and their versions.

=head2 include

A list of files to include data from.  Each one is loaded with C<do>.  It
should return a hashref with any of the following keys: C<requires>,
C<build_requires>, C<test_requires>.  Any that are found will be merged
together with the hashref passed in as the C<require> parameter.

Currently, everything gets written to the Makefile.PL as a normal dependency;
TaskBuilder doesn't actually distinguish between build/test/install
dependencies.

=head1 FILES

TaskBuilder generates the following files:

=head2 Makefile.PL

=head2 README

=head2 (your task module)

This file contains a package statement for your module and a C<$VERSION>, so it
can be depended on by other distributions.

=head1 METHODS

=head2 new

  my $tb = App::TaskBuilder->new(%opt);

Create a new TaskBuilder object.  See L</PARAMETERS>.

=head2 vars

  my %vars = $tb->vars;

A hash of variables suitable for passing to a template, which is what
TaskBuilder does with this internally.

=head2 run

  $tb->run;

Run the application and write the output distribution file.

=head1 CAVEATS

TaskBuilder uses your C<tar> binary instead of Archive::Tar.  If this bothers
you, write a patch to use Archive::Tar when it's available.  I'd like to avoid
non-core dependencies, though, since I originally wrote this as part of an
automated dependency installer for a (non-CPAN, non-Makefile.PL) project.

=head1 AUTHOR

  Hans Dieter Pearcey <hdp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Hans Dieter Pearcey <hdp@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut