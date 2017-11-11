package App::FTPThis;

our $DATE = '2017-11-10'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Cwd;
use Getopt::Long;
use Pod::Usage;

sub new {
    my $class = shift;
    my $self = bless {port => 8021, root => '.'}, $class;

    GetOptions($self, "help", "man", "port=i",
           ) || pod2usage(2);
    pod2usage(1) if $self->{help};
    pod2usage(-verbose => 2) if $self->{man};

    if (@ARGV > 1) {
        pod2usage("$0: Too many roots, only single root supported");
    } elsif (@ARGV) {
        $self->{root} = shift @ARGV;
    } else {
        $self->{root} = getcwd();
    }

    return $self;
}

sub run {
    require File::Slurper;
    require File::Temp;
    require Net::FTPServer::RO_FTPThis::Server;

    my ($self) = @_;

    my $dir = File::Temp::tempdir(CLEANUP => !$ENV{DEBUG});
    say "D: temporary dir = $dir" if $ENV{DEBUG};

    File::Slurper::write_text(
        "$dir/conf",
        join(
            "",
            "root directory: $self->{root}\n",
            "allow anonymous: 1\n",
            "anonymous password check: none\n",
            "anonymous password enforce: 0\n",
            "home directory: $self->{root}\n",
            "limit memory: -1\n",
            "limit nr processes: -1\n",
            "limit nr files: -1\n",
        ),
    );

    say "Starting FTP server on port $self->{port} ...";

    chdir $self->{root} or die "Can't chdir to $self->{root}: $!";
    local @ARGV = (
        "-C=$dir/conf",
        "-p", $self->{port},
        "-s", # daemon mode (not background, which is -S)
    );
    my $ftpd = Net::FTPServer::RO_FTPThis::Server->run;
}

1;
# ABSTRACT: Export the current directory over anonymous FTP

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FTPThis - Export the current directory over anonymous FTP

=head1 VERSION

This document describes version 0.003 of App::FTPThis (from Perl distribution App-FTPThis), released on 2017-11-10.

=head1 SYNOPSIS

 # Not to be used directly, see ftp_this command

=head1 DESCRIPTION

=head1 METHODS

=head2 new

=head2 run

=head1 ENVIRONMENT

=head2 DEBUG => bool

If set to true, won't cleanup temporary directory.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-FTPThis>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ftpthis>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FTPThis>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
