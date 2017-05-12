package App::GitGrepPerlStatement;
use 5.008001;
use strict;
use warnings;
use App::GitGrepPerlStatement::StatementFinder;
use Term::ANSIColor qw(colored);

our $VERSION = "0.05";

sub say ($) {
    my ($message) = @_;
    print $message . "\n";
}

sub run {
    my ($class, @argv) = @_;

    my $word = (@argv)[0];

    unless (defined $word) {
        say "USAGE: git grep-per-statement <pattern token> <pathspec>";
        exit 1;
    }

    my @files = split "\n", `git grep --name-only --cached --word-regexp @{[ join ' ', map { quotemeta($_) } @argv ]}`;

    my $finder = App::GitGrepPerlStatement::StatementFinder->new($word);

    for my $file (@files) {
        my @found = $finder->search($file);

        for (@found) {
            if (-t STDOUT) {
                say colored(
                    ['bold'],
                    "@{[ $file ]}:@{[ $_->line_number ]}"
                );
                say $finder->highlight($_);
            } else {
                say "@{[ $file ]}:@{[ $_->line_number ]}";
                say $_;
            }
        }
        $finder->flush;
    }

}

__END__

=encoding utf-8

=head1 NAME

App::GitGrepPerlStatement - Perl statement finder

=head1 SYNOPSIS

    use App::GitGrepPerlStatement;

=head1 DESCRIPTION

App::GitGrepPerlStatement is the frontend of L<git-grep-perl-statement>

=head1 SEE ALSO

L<git-grep-perl-statement>

=head1 LICENSE

Copyright (C) hitode909.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

hitode909 E<lt>hitode909@gmail.comE<gt>

=cut

