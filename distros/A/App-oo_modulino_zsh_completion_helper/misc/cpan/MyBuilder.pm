package
  MyBuilder;
use strict;
use warnings;
use utf8;

use parent qw(Module::Build);

use Module::CPANfile;

use File::Basename;
use File::Spec;

sub new {
  _add_zsh_fpath(
    shift->SUPER::new(@_)
  );
}

sub _add_zsh_fpath {
  my ($self) = @_;
  my $elem = 'zsh_fpath';
  $self->add_build_element($elem);

  # XXX: Is this portable? only tested in Fedora...
  my $zsh_site_fpath = "share/zsh/site-functions";
  my $zsh_vendor_completion = do {
    my $rel = "share/zsh/vendor-completions";
    if (-d "/usr/$rel") {
      $rel
    } else {
      $zsh_site_fpath;
    }
  };

  $self->install_base_relpaths($elem => $zsh_site_fpath);
  $self->prefix_relpaths($_ => $elem => $zsh_site_fpath) for qw(site);
  $self->prefix_relpaths($_ => $elem => $zsh_vendor_completion)
    for qw(core vendor);

  my $installdirs = $self->installdirs;
  if ($self->install_path($elem)) {
    # Use specified value in Build.PL invocation.
  }
  elsif ($installdirs eq 'core' or $installdirs eq 'vendor') {
    $self->install_path($elem => "/usr/$zsh_vendor_completion");
  }
  elsif ($installdirs eq 'site') {
    $self->install_path($elem => "/usr/local/$zsh_site_fpath");
  }
  else {
    die "Unknown installdirs to derive zsh_fpath: $installdirs";
  }

  $self;
}

# sub _default_zsh_fpath {
#   local $ENV{FPATH};
#   chomp(my $fpath = qx(zsh -f -c 'print -l \$fpath'));
#   grep {
#     m{/site-functions\z}
#   } split "\n", $fpath;
# }

# Copied from my YATT::Lite distribution
sub my_cpanfile_specs {
  my ($pack) = @_;
  my $file = Module::CPANfile->load("cpanfile");
  my $prereq = $file->prereq_specs;
  my %args;
  %{$args{requires}} = lexpand($prereq->{runtime}{requires});
  foreach my $phase (qw/configure runtime build test/) {
    %{$args{$phase . "_requires"}} = lexpand($prereq->{$phase}{requires});
  }
  %{$args{recommends}} = (map {lexpand($prereq->{$_}{recommends})}
			  keys %$prereq);
  %args
}

sub lexpand {
  return unless defined $_[0];
  %{$_[0]};
}

1;
