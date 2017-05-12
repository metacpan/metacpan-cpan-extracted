package App::merge_cpanfile;
use 5.008001;
use strict;
use warnings;

use Module::CPANfile;
use CPAN::Meta::Prereqs;

our $VERSION = "0.01";

sub run {
  my ($self, @argv) = @_;
  my ($dest, $src) = @argv;

  my $dest_cpanfile = Module::CPANfile->load($dest);
  my $src_cpanfile = Module::CPANfile->load($src);

  my $merged_cpanfile = $self->merge_cpanfiles(
    $src_cpanfile,
    $dest_cpanfile,
    'runtime',
    'requires',
  );

  print $merged_cpanfile->to_string;
}

sub merge_cpanfiles {
  my ($self, $src, $dest, $phase, $type) = @_;

  my $merged_prereqs = $dest->prereqs->with_merged_prereqs(
      $self->extract_prereqs_for($src->prereqs, $phase, $type)
  );

  return Module::CPANfile->from_prereqs($merged_prereqs->as_string_hash);
}

sub extract_prereqs_for {
    my ($self, $prereqs, $phase, $type) = @_;
    my $reqs = $prereqs->requirements_for($phase, $type);
    my $new_prereqs = CPAN::Meta::Prereqs->new({
        $phase => { $type => $reqs->as_string_hash }
    });
    return $new_prereqs;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::merge_cpanfile - Merge multiple cpanfile into one

=head1 SYNOPSIS

    cat core.cpanfile
    # requires 'Carp';
    cat sub.cpanfile
    # requires 'LWP::UserAgent';
    merge-cpanfile core.cpanfile sub.cpanfile
    # requires 'Carp';
    # requires 'LWP::UserAgent';

=head1 DESCRIPTION

App::merge_cpanfile merges multiple cpanfile into one cpanfile.

It's handy way to manage dependencies of private modules same as published CPAN modules'.

=head1 LICENSE

Copyright (C) aereal.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

=cut

