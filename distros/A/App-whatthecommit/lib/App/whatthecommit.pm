package App::whatthecommit;

use strict;
use 5.008_005;
use base 'Exporter';
our @EXPORT_OK = qw(goodie);
our $VERSION   = '0.02';
our $HOOK
    = 'echo $(curl -L http://whatthecommit.com/ 2>/dev/null | grep -Po \'(?<=\<p\>).*$\') > "$1"';

sub goodie($) {
    my $git                = shift;
    my $prepare_commit_msg = $git . "/.git/hooks/prepare-commit-msg";
    open my $REPO, ">$prepare_commit_msg"
        or die( print "Cannot open $prepare_commit_msg\n" );
    print $REPO $HOOK;
    close $REPO;
    chmod 0755, $prepare_commit_msg;
    print "[$git] You are good to go, try to commit in your repo now\n";
}

__END__
=encoding utf-8

=head1 NAME

App::whatthecommit - Add a prepare-commit-msg to your git repository that uses whatthecommit.com to generate random commit messages

=head1 SYNOPSIS

  $ whatthecommit [git-repository] [another-git-repository]
  $ whatthecommit --help

=head1 DESCRIPTION

App::whatthecommit is just another lazy-to-lazy line command utility.
whatthecommit.com generates commit messages for the lazy, this tool will increment your lazyness to another level, just give your git repo(s) as args and he will create prepare-commit-msg hook to fetch a random commit.
After running it on your repo, just try C<git commit>.

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 COPYRIGHT

Copyright 2014- mudler

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut


1;

