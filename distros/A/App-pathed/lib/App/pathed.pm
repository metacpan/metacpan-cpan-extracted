package App::pathed;
use strict;
use warnings;
use Config;
use Getopt::Long;
use Pod::Usage;
use Pod::Find qw(pod_where);
our $VERSION = '0.07';

sub usage {
    pod2usage(-input => pod_where({ -inc => 1 }, __PACKAGE__), @_);
}

sub run {
    my %opt;
    GetOptions(
        \%opt, qw(
          delete|d=s@  append|a=s@  prepend|p=s@
          unique|u split|s check|c
          var|v=s sep|e=s help|h man
          )
    ) or usage(-exitval => 2);
    usage(-exitval => 1) if $opt{help};
    usage(-exitval => 0, -verbose => 2, -output => \*STDERR) if $opt{man};
    usage(-exitval => 2, -msg => '--split and --check are mutually exclusive')
      if $opt{split} && $opt{check};
    my $path = shift @ARGV;
    usage(
        -exitval => 2,
        -msg     => 'using a path argument and --var and are mutually exclusive'
    ) if defined $path && $opt{var};
    unless (defined $path) {
        if ($opt{var}) {
            $path = $ENV{ $opt{var} };
            unless (defined $path && length $path) {
                die "The $opt{var} environment variable is empty\n";
            }
        } else {
            $path = $ENV{PATH};
        }
    }
    my @result = process($path, \%opt);
    print "$_\n" for @result;
}

# separate methods so it's easily testable
sub process {
    my ($path, $opt) = @_;
    my $separator = $opt->{sep} // $Config::Config{path_sep};
    my @parts = split $separator => $path;
    if ($opt->{append}) {
        push @parts, @{ $opt->{append} };
    }
    if ($opt->{prepend}) {
        unshift @parts, reverse @{ $opt->{prepend} };
    }
    if ($opt->{delete}) {
        for my $delete (@{ $opt->{delete} }) {
            @parts = grep { index($_, $delete) == -1 } @parts;
        }
    }
    if ($opt->{unique}) {
        my %seen;
        @parts = grep { !$seen{$_}++ } @parts;
    }
    if ($opt->{check}) {
        my (%seen, @result);
        for my $part (@parts) {
            next if $seen{$part}++;
            next if -r $part;
            push @result => "$part is not readable";
        }
        return @result;
    } elsif ($opt->{split}) {
        return @parts;
    } else {
        return (join $separator => @parts);
    }
}
1;

=pod

=head1 NAME

App::pathed - munge the Bash PATH environment variable

=head1 SYNOPSIS

    $ PATH=$(pathed --unique --delete rbenv)
    $ PATH=$(pathed --append /home/my/bin -a /some/other/bin)
    $ PATH=$(pathed --prepend /home/my/bin -p /some/other/bin)
    $ for i in $(pathed --split); do ...; done
    $ pathed --check
    $ pathed -u --var PERL5LIB
    $ pathed -u $PERL5LIB
    $ pathed -d two --sep ';' '/foo/one;foo/two'
    $ pathed --man

=head1 DESCRIPTION

The Bash C<PATH> environment variable contains a colon-separated list of paths.
Platforms other than UNIX might use a different separator; C<pathed> uses the
default separator for the current OS. C<pathed> - "path editor" - can split
the path, append, prepend or remove elements, remove duplicates and reassemble
it.

The result is then printed so you can assign it to the C<PATH> variable. If
C<--split> is used, each path element is printed on a separate line, so you can
iterate over them, for example.

The path elements can also be checked with C<--check> to make sure that the
indicated paths are readable.

But C<pathed> isn't just for the C<PATH> variable. You can specify an
environment variable to use with the C<--var> option, or just pass a value to
be used directly after the options.

The following command-line options are supported:

=over 4

=item C<--append>, C<-a> C<< <path> >>

Appends the given path to the list of path elements. This option can be
specified several times; the paths are appended in the given order.

=item C<--prepend>, C<-p> C<< <path> >>

Prepends the given path to the list of path elements. This option can be
specified several times; the paths are prepended in the given order. For
example:

    $ pathed -p first -p second -p third

will result in C<third:second:first:$PATH>.

=item C<--delete>, C<-d> C<< <substr> >>

Deletes those path elements which contain the given substring. This option can
be specified several times; the path elements are deleted in the given order.

When options are mixed, C<--append> is processed first, then C<--prepend>, then
C<--delete>.

=item C<--unique>, C<-u>

Removes duplicate path elements.

=item C<--split>, C<-s>

Prints each path element on its own line. If this option is not specified, the
path elements are printed on one line, joined by the default path separator as
reported by L<Config> - usually a colon -, like you would normally specify the
C<PATH> variable.

=item C<--check>, C<-c>

Checks whether each path element is readable and prints warnings if necessary.
Does not check whether the path element is a directory because C<pathed> can
also be used for specifying multiple files such as configuration files.
Warnings are printed only once per path element, even if that element occurs
several times in C<PATH>.

When C<--check> is used, the path is not printed. C<--check> and C<--split> are
mutually exclusive.

=item C<--var>, C<-v> C<< <variable> >>

Use the indicated environment variable.

=item C<--sep>, C<-e> C<< <separator> >>

The default path separator is what L<Config> reports - usually a colon - but
with this option you can specify a different separator. It is used to split the
input path and to join the output path.

=item C<--help>, C<-h>

Prints the synopsis.

=item C<--man>

Prints the whole documentation.

=back

=head1 WHY pathed?

The initial motivation for writing C<pathed> came when I tried to install
C<vim> with C<homebrew> while C<rbenv> was active. C<vim> wanted to be compiled
with the system ruby, so I was looking for a quick way to remove C<rbenv> from
the C<PATH>:

    $ PATH=$(pathed -d rbenv) brew install vim

=head1 AUTHORS

The following person is the author of all the files provided in this
distribution unless explicitly noted otherwise.

Marcel Gruenauer <marcel@cpan.org>, L<http://marcelgruenauer.com>

=head1 COPYRIGHT AND LICENSE

The following copyright notice applies to all the files provided in this
distribution, including binary files, unless explicitly noted otherwise.

This software is copyright (c) 2013 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.
