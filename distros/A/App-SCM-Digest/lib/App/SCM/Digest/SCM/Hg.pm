package App::SCM::Digest::SCM::Hg;

use strict;
use warnings;

use App::SCM::Digest::Utils qw(system_ad);

use autodie;

sub new
{
    my ($class) = @_;

    my $res = system("hg --version >/dev/null");
    if ($res != 0) {
        die "Unable to find hg executable.";
    }

    my $self = {};
    bless $self, $class;
    return $self;
}

sub clone
{
    my ($self, $url, $name) = @_;

    my $res = system_ad("hg clone $url $name");

    return 1;
}

sub open_repository
{
    my ($self, $path) = @_;

    chdir $path;

    return 1;
}

sub is_usable
{
    return 1;
}

sub pull
{
    my ($self) = @_;

    my $res = system_ad("hg pull");

    return 1;
}

sub branches
{
    my ($self) = @_;

    my $current = $self->branch_name();
    my @branch_infos = `hg branches`;
    my @results;
    for my $branch_info (@branch_infos) {
        chomp $branch_info;
        my ($entry, $commit) = ($branch_info =~ /^(\S+?)\s+(\S+)/);
        $self->checkout($entry);
        $commit = `hg log --limit 1 --template '{node}'`;
        chomp $commit;
        push @results, [ $entry => $commit ];
    }
    if ($current ne 'default') {
        $self->checkout($current);
    }

    return \@results;
}

sub branch_name
{
    my ($self) = @_;

    my $branch = `hg branch`;
    chomp $branch;

    return $branch;
}

sub checkout
{
    my ($self, $branch) = @_;

    system_ad("hg checkout $branch");

    return 1;
}

sub commits_from
{
    my ($self, $branch, $from) = @_;

    my @new_commits =
        map { chomp; $_ }
            `hg log -b $branch --template "{node}\n" -r $from:tip`;

    if (@new_commits and ($new_commits[0] eq $from)) {
        shift @new_commits;
    }

    return \@new_commits;
}

sub has
{
    my ($self, $id) = @_;

    my $res = system("hg log --rev $id >/dev/null 2>&1");

    return ($res == 0);
}

sub show
{
    my ($self, $id) = @_;

    my @data = `hg log --rev $id`;

    return \@data;
}

sub show_all
{
    my ($self, $id) = @_;

    my @data = `hg log --patch --rev $id`;

    return \@data;
}

1;

__END__

=head1 NAME

App::SCM::Digest::SCM::Git

=head1 DESCRIPTION

Git L<App::SCM::Digest::SCM> implementation.

=cut
