package App::GitHub::Repository;

use warnings;
use strict;
use Carp;

use Git;
use File::Slurper qw(read_text);
use JSON;
use parent 'Test::Builder::Module'; # Included in Test::Simple

use version; our $VERSION = qv('0.0.5');

# Module implementation here

sub new {
  my $class = shift;
  my $repo = shift;
  my $tmp_dir = shift || "/tmp";
  croak "$repo is not a GitHub repo" if ( $repo !~ /github/);
  my ($user,$name) = ($repo=~ /github.com\/(\S+)\/([^\.]+)/);
  my $self = {_tb => __PACKAGE__->builder,
	      _repo => $repo,
	      _user => $user,
	      _name => $name };
  my $repo_dir =  "$tmp_dir/$user-$name";
  croak "$repo_dir already exists" if -d $repo_dir;
  Git::command_oneline( ['clone', $repo, $repo_dir] );
  croak "Couldn't download repo" if !(-d $repo_dir);
  my $student_repo =  Git->repository ( Directory => $repo_dir );
  my @repo_files = $student_repo->command("ls-files");
  $self->{'_repo_dir'} = $repo_dir;
  $self->{'_repo_files'} = \@repo_files;
  $self->{'_README'} =  read_text( "$repo_dir/README.md");
  bless $self, $class;
  return $self;
}

sub has_readme {
  my $self = shift;
  my $message = shift || "Has README.md";
  my $tb = $self->{'_tb'};
  $tb->ok( $self->{'_README'} ne '', $message );
}

sub has_file{
  my $self = shift;
  my $file = shift || croak "No file";
  my $message = shift || "Includes file $file";
  my $tb = $self->{'_tb'};
  $tb->ok( grep(@{$self->{'_repo_files'}}, $file) , $message );
}

sub has_milestones {
  my $self = shift;
  my $how_many = shift || 1;
  my $message = shift || "Has $how_many milestones";
  my $tb = $self->{'_tb'};
  my $user = $self->{'_user'};
  my $repo = $self->{'_name'};
  my $page = $self->get_github( "https://github.com/$user/$repo/milestones" );
  my ($milestones ) = ( $page =~ /(\d+)\s+Open/);
  $tb->cmp_ok( $milestones, ">=", $how_many, $message);
}

sub issues_well_closed {
  my $self = shift;
  my $message = shift || "Issues have been closed from commit";
  my $tb = $self->{'_tb'};
  my $user = $self->{'_user'};
  my $repo = $self->{'_name'};

  my $page = $self->get_github( "https://github.com/$user/$repo".'/issues?q=is%3Aissue+is%3Aclosed' );
  my (@closed_issues ) = ( $page =~ m{<a\s+(id=\"issue_\d+_link\")}gs );
  for my $i (@closed_issues) {
    my ($issue_id) = ($i =~ /issue_(\d+)_link/);

    $tb->ok($self->closes_from_commit($issue_id),"El issue $issue_id se ha cerrado desde commit")
  }

}

sub get_github {
  my $self = shift;
  my $url = shift;
  my $page = `curl -ss $url`;
  croak "No pude descargar la página" if !$page;
  return $page;
}

sub closes_from_commit {
  my ($self,$issue) = @_;
  my $page = $self->get_github( "https://github.com/" . $self->{'_user'} ."/" .$self->{'_repo'}."/issues/$issue" );
  return $page =~ /closed\s+this\s+in/gs ;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

App::GitHub::Repository - [One line description of module's purpose here]


=head1 VERSION

This document describes App::GitHub::Repository version 0.0.1


=head1 SYNOPSIS

    use App::GitHub::Repository;


=head1 DESCRIPTION

A series of sanity checks on GitHub repositories.


=head1 INTERFACE

=head2 new

Creates object with repo URL

=head2 issues_well_closed

Checks that issues have been closed with a commit

=head2 has_milestones

Checks that has a minimum number of milestones open

=head2 has_readme

Checks that the readme.md file is present

=head2 has_file

Checks that the repository contains a file

=head2 get_github

Auxiliary function to get a file from github

=head2 closes_from_commit

Checks if an issue has been closed from a commit.


=head1 DIAGNOSTICS


=head1 CONFIGURATION AND ENVIRONMENT


App::GitHub::Repository requires no configuration files or environment variables.


=head1 DEPENDENCIES

The system needs to have `curl` installed and available.

Use C<./Build installdeps> to install all dependencies>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-github-repository@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

JJ Merelo  C<< <jjmerelo@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2018, JJ Merelo C<< <jjmerelo@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
