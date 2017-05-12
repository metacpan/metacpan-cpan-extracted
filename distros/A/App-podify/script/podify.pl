#!/usr/bin/env perl
use Applify;

use File::Find;
use File::Spec;

use if -e '.ship.conf', lib => 'lib';

option bool => i => 'Replace source', 0;
option bool => recursive => 'Recurse into directories in source list',
  0, (alias => 'r');
option str => eopm => 'End of perl module marker', '^1;';

documentation 'App::podify';

sub check_pod {
  my $self = shift;

  for my $section (qw(attrs subs)) {
    for my $name (keys %{$self->{$section} || {}}) {
      warn "Missing $section in pod: $name\n";
    }
  }

  return $self;
}

sub find_files {
  my ($self, $path) = @_;
  my @files;

  File::Find::find(
    {
      no_chdir => 1,
      wanted   => sub {
        $File::Find::prune = 1 if -d $File::Find::name and !$self->recursive;
        $File::Find::prune = 0 if $File::Find::name eq $path;
        return if $File::Find::prune;
        push @files, $File::Find::name if $File::Find::name =~ m/[.] pm \z/msx;
      }
    },
    $path
  );

  return sort { length $a <=> length $b } @files;
}

sub generate {
  my ($self, $OUT) = @_;

  $self->{pod} = $self->pod_template unless @{$self->{pod}};

  if ($self->i) {
    open $OUT, '>', $self->{perl_module} or die "Write $self->{perl_module}: $!\n";
  }
  elsif (!$OUT) {
    $OUT = \*STDOUT;
  }

  my $code = join '', @{$self->{code}};
  $code =~ s!\n\n\n!\n\n!g;
  $code =~ s!\n+use!\nuse!s;
  $code =~ s!\n+$!\n\n!;

  print $OUT "${code}1;\n\n";
  print $OUT "=encoding utf8\n\n" unless $self->{pod_has_encoding};
  print $OUT $_ for grep { !/^=cut/ } @{$self->{pod}};
  print $OUT "=cut\n";
  print $OUT "\n" . join '', @{$self->{data}} if @{$self->{data}};
}

sub init {
  my $self = shift;
  $self->{$_} = [] for qw(code data pod);
  $self->{$_} = {} for qw(attrs subs);
  $self;
}

sub parse {
  my $self = shift;
  my $eopm = $self->eopm;
  my %has;

  open my $IN, '<', $self->{perl_module} or die "Read $self->{perl_module}: $!\n";
  $eopm = qr{$eopm};

  while (<$IN>) {
    my $pod;
    next if /^=encoding\s/;
    $self->{attrs}{$1}      = $1 if /^has\s+([a-z]\w*)/;
    $self->{subs}{$1}       = $1 if /^sub\s+([a-z]\w*)/;
    $self->{documented}{$1} = $1 if /^=head2\s([a-z]\w*)/;
    $self->{module_name}    ||= $1 if /^package\s+([^\s;]+)/;
    $self->{module_version} ||= $1 if /^VERSION.*([\d\.]+)/;
    $pod = push @{$self->{pod}}, $_ if /^=head/ .. /=cut/;
    push @{$self->{data}}, $_ if @{$self->{data}} or /^__DATA__$/;
    push @{$self->{code}}, $_ unless @{$self->{data}} or $pod or $_ =~ $eopm;
  }

  return $self;
}

sub pod_template {
  my $self = shift;

  return [
    sprintf("=head1 NAME\n\n%s - TODO\n\n", $self->{module_name} || 'Unknown'),
    $self->{module_version} ? printf("=head1 VERSION\n\n$%s\n\n", $self->{module_version}) : (),
    sprintf("=head1 SYNOPSIS\n\nTODO\n\n"),
    sprintf("=head1 DESCRIPTION\n\nTODO\n\n"),
    sprintf("=head1 ATTRIBUTES\n\n"),
    map({ sprintf "=head2 %s\n\n", delete $self->{attrs}{$_} } sort keys %{$self->{attrs} || {}}),
    sprintf("=head1 METHODS\n\n"),
    map({ sprintf "=head2 %s\n\n", delete $self->{subs}{$_} } sort keys %{$self->{subs} || {}}),
    sprintf("=head1 AUTHOR\n\n%s\n\n", $ENV{PODIFY_AUTHOR} || (getpwuid $<)[6] || (getpwuid $<)[0]),
    sprintf("=head1 COPYRIGHT AND LICENSE\n\nTODO\n\n"),
    sprintf("=head1 SEE ALSO\n\nTODO\n\n"),
  ];
}

sub post_process {
  my $self = shift;
  delete $self->{attrs}{$_} or delete $self->{subs}{$_} for keys %{$self->{documented}};
}

app {
  my ($self, @paths) = @_;

  unless (@paths) {
    die $self->_script->print_help, "No input files specified.\n";
  }

  while (my $path = File::Spec->canonpath(shift @paths)) {
    if (-d $path) {
      push @paths, $self->find_files($path);
    }
    else {
      $self->init;
      $self->{perl_module} = $path;
      $self->parse;
      $self->post_process;
      $self->generate;
      $self->check_pod;
    }
  }

  return 0;
};
