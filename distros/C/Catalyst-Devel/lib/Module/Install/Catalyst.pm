package Module::Install::Catalyst;

use strict;

use base qw/ Module::Install::Base /;
our @ISA;
require Module::Install::Base;

use File::Find;
use FindBin;
use File::Copy::Recursive;
use File::Spec ();
use Getopt::Long ();
use Data::Dumper;

my $SAFETY = 0;

our @IGNORE =
  qw/Build Build.PL Changes MANIFEST META.yml Makefile.PL Makefile README
  _build blib lib script t inc .*\.svn \.git _darcs \.bzr \.hg
  debian build-stamp install-stamp configure-stamp/;

=head1 NAME

  Module::Install::Catalyst - Module::Install extension for Catalyst

=head1 SYNOPSIS

  use lib '.';
  use inc::Module::Install;

  name 'MyApp';
  all_from 'lib/MyApp.pm';

  requires 'Catalyst::Runtime' => '5.7014';

  catalyst_ignore('.*temp');
  catalyst_ignore('.*tmp');
  catalyst;
  WriteAll;

=head1 DESCRIPTION

L<Module::Install> extension for Catalyst.

=head1 METHODS

=head2 catalyst

Calls L<catalyst_files>. Should be the last catalyst*
command called in C<Makefile.PL>.

=cut

sub catalyst {
    my $self = shift;

    if($Module::Install::AUTHOR) {
        $self->include("File::Copy::Recursive");
    }

    print <<EOF;
*** Module::Install::Catalyst
EOF
    $self->catalyst_files;
    print <<EOF;
*** Module::Install::Catalyst finished.
EOF
}

=head2 catalyst_files

Collect a list of all files a Catalyst application consists of and copy it
inside the blib/lib/ directory. Files and directories that match the modules
ignore list are excluded (see L<catalyst_ignore> and L<catalyst_ignore_all>).

=cut

sub catalyst_files {
    my $self = shift;

    chdir $FindBin::Bin;

    my @files;
    opendir CATDIR, '.';
  CATFILES: for my $name ( readdir CATDIR ) {
        for my $ignore (@IGNORE) {
            next CATFILES if $name =~ /^$ignore$/;
            next CATFILES if $name !~ /\w/;
        }
        push @files, $name;
    }
    closedir CATDIR;
    my @path = split '-', $self->name;
    for my $orig (@files) {
        my $path = File::Spec->catdir( 'blib', 'lib', @path, $orig );
        File::Copy::Recursive::rcopy( $orig, $path );
    }
}

=head2 catalyst_ignore_all(\@ignore)

This function replaces the built-in default ignore list with the given list.

=cut

sub catalyst_ignore_all {
    my ( $self, $ignore ) = @_;
    @IGNORE = @$ignore;
}

=head2 catalyst_ignore(@ignore)

Add a regexp to the list of ignored patterns. Can be called multiple times.

=cut

sub catalyst_ignore {
    my ( $self, @ignore ) = @_;
    push @IGNORE, @ignore;
}

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
