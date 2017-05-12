use 5.008001;
use strict;
use warnings;

package App::mymeta_requires;
# ABSTRACT: Extract module requirements from MYMETA files

our $VERSION = '0.006';

# Dependencies
use Class::Load qw/try_load_class/;
use CPAN::Meta;
use List::Util qw/max/;
use Getopt::Lucid ':all';
use CPAN::Meta::Requirements;

use Class::Tiny qw/opt/;

my $opt_spec = [
  Param("file|f"),
  Switch("verbose|v"),
  Switch("report"),
  Switch("help|h"),
  Switch("runtime|r")->default(1),
  Switch("configure|c")->default(1),
  Switch("build|b")->default(1),
  Switch("test|t")->default(1),
  Switch("develop|d")->default(0),
  Switch("recommends")->default(1),
  Switch("suggests")->default(1),
];

sub BUILD {
  my $self = shift;
  $self->{opt} = Getopt::Lucid->getopt($opt_spec);
}

sub run {
  my $self = shift;
  $self = $self->new unless ref $self;

  if ( $self->opt->get_help ) {
    require File::Basename;
    require Pod::Usage;
    my $file = File::Basename::basename($0);
    Pod::Usage::pod2usage();
  }

  my $mymeta = $self->load_mymeta
    or die "Could not load a MYMETA file\n";
  my $prereqs = $self->merge_prereqs( $mymeta->effective_prereqs );
  if ( $self->opt->get_report ) {
    print for $self->prereq_report( $prereqs );
  }
  else {
    my @missing = $self->find_missing( $prereqs );
    print for sort @missing;
  }
  return 0;
}

sub load_mymeta {
  my $self = shift;
  my @candidates = $self->opt->get_file
    ? ($self->opt->get_file)
    : qw/MYMETA.json MYMETA.yml META.json META.yml/;
  for my $f ( @candidates ) {
    next unless -r $f;
    my $mymeta = eval { CPAN::Meta->load_file($f) }
      or $self->_log("Error loading '$f': $@\n");
    if ( $mymeta ) {
      $self->_log("Got MYMETA from '$f'\n");
      return $mymeta;
    }
  }
  return;
}

sub merge_prereqs {
  my ($self, $prereqs) = @_;
  my $merged = CPAN::Meta::Requirements->new;
  for my $phase (qw(configure runtime build test develop)) {
    my $get_p = "get_$phase";
    next unless $self->opt->$get_p;
    # Always get 'requires'
    $merged->add_requirements( $prereqs->requirements_for( $phase, 'requires' ) );
    # Maybe get other types
    for my $extra( qw/recommends suggests/ ) {
      my $get_x = "get_$extra";
      next unless $self->opt->$get_x;
      $merged->add_requirements( $prereqs->requirements_for( $phase, $extra ) );
    }
  }
  return $merged;
}

sub find_missing {
  my ($self, $prereqs) = @_;
  my @missing;
  for my $mod ( $prereqs->required_modules ) {
    next if $mod eq 'perl';
    if ( try_load_class($mod) ) {
      push @missing, "$mod\n" unless $prereqs->accepts_module($mod, $mod->VERSION);
    }
    else {
      push @missing, "$mod\n";
    }
  }
  return @missing;
}

sub prereq_report {
    my ( $self, $prereqs ) = @_;
    my @report;
    for my $mod ( sort $prereqs->required_modules ) {
        next if $mod eq 'perl';
        my $req = $prereqs->requirements_for_module($mod);
        if ( try_load_class($mod) ) {
            my $version = $mod->VERSION || "<no version>";
            push @report, [ $mod, $version, $req ];
        }
        else {
            push @report, [ $mod, "<missing>", $req ];
        }
    }
    my $max_mod_len = max( map { length $_->[0] } @report );
    my $max_ver_len = max( map { length $_->[1] } @report );
    my $max_req_len = max( map { length $_->[2] } @report );

    unshift @report, [ "Module", "Have", "Want" ],
      [ "-" x $max_mod_len, "-" x $max_ver_len, "-" x $max_req_len ];

    return map {
        sprintf( "%-*s %-*s %-*s\n",
            $max_mod_len, $_->[0], $max_ver_len, $_->[1], $max_req_len, $_->[2] )
    } @report;
}

sub _log {
  my $self = shift;
  warn "$_[0]\n" if $self->opt->get_verbose;
}

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

App::mymeta_requires - Extract module requirements from MYMETA files

=head1 VERSION

version 0.006

=head1 SYNOPSIS

   use App::mymeta_requires;
   exit App::mymeta_requires->run;

=head1 DESCRIPTION

This module contains the guts of the LE<lt>mymeta_requiresE<gt> program.  See
that program for command line usage information.

=for Pod::Coverage BUILD
find_missing
load_mymeta
merge_prereqs
opt
prereq_report
run

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/app-mymeta_requires/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/app-mymeta_requires>

  git clone https://github.com/dagolden/app-mymeta_requires.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
