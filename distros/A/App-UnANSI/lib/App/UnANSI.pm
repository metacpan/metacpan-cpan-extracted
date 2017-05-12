package App::UnANSI;
our $AUTHORITY = 'cpan:XSAWYERX';
# ABSTRACT: Remove ANSI coloring from output or files
$App::UnANSI::VERSION = '0.003';
use strict;
use warnings;
use Getopt::Long qw<:config no_ignore_case>;

# Helper function
sub _help {
    my $msg = shift;

    $msg
        and print "Error: $msg\n\n";

    print << "_HELP";
command_that_creates_colored_output | $0 [OPTIONS] FILE1 FILE2...FILEN

Options:

-h | --help     Print this help menu and exit
-v | --version  Print version number and exit
_HELP

    if ($msg) {
        exit 2;
    } else {
        exit 0;
    }
}

sub new_with_options {
    my ( $class, %opts ) = @_;

    my @files;
    GetOptions(
        'help|h'    => sub { _help(); },
        'version|v' => sub {
            my $version = $App::UnANSI::VERSION || 'DEV';
            print "$0 $version\n";
            exit 0;
        },
        '<>' => sub {
            push @files, @_;
        },
    ) or _help();

    return $class->new( 'files' => \@files );
}

sub new {
    my ( $class, %opts ) = @_;

    $opts{'files'} ||= [];

    foreach my $file ( @{ $opts{'files'} } ) {
        -e $file && -r $file
            or _help("$file is not a readable file")
    }

    return bless {%opts}, $class;
}

sub files {
    my $self = shift;
    return @{ $self->{'files'} };
}

sub run {
    my $self  = shift;
    my @files = $self->files;

    if ( !@files ) {
        # Work on STDIN
        while ( my $line = <STDIN> ) {
            $self->remove_ansi_colors($line);
            print $line;
        }
    } else {
        # Work on files
        foreach my $file (@files) {
            open my $fh, '<', $file
                or die "Cannot open $file: $!\n";

            while ( my $line = <$fh> ) {
                $self->remove_ansi_colors($line);
                print $line;
            }

            close $fh
                or die "Cannot close $file: $!\n";
        }
    }

    return 1;
}

sub remove_ansi_colors {
    $_[1] =~ s{\x1b\[[^m]*m}{}sgmx;
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::UnANSI - Remove ANSI coloring from output or files

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use App::UnANSI;
    my $unansi = App::UnANSI->new();
    my $some_line = get_line_with_coloring();
    $unansi->remove_ansi_colors($some_line);
    # $some_line is now clean

=head1 DESCRIPTION

This is the underlying implementation of
L<unansi|https://metacpan.org/pod/distribution/App-UnANSI/bin/unansi>.

This is the documentation of the command implementation. You are most likely
looking for the command documentation itself:
L<unansi|https://metacpan.org/pod/distribution/App-UnANSI/bin/unansi>.

=head1 ATTRIBUTES

=head2 files

Can be set on instantiation, returns a list of files to process.

    my @files_to_process = $unansi->files;

=head1 METHODS

=head2 new

Creates a new instance. You can provide C<files> to process.

    my $unansi = App::UnANSI->new();

    # or

    my $unansi = App::UnANSI->new(
        'files' => [ 'foo.txt', 'bar.txt' ],
    );

=head2 new_with_options

Creates a new instance using options from the command line. This
is what the CLI uses.

=head2 run

Processes either the files or the input from the command line. In both cases
it prints to the screen. This might change for files in the future.

=head2 remove_ansi_colors

The actual code that removes the ANSI coloring from a string. It alters the
string it receives, for speed purposes.

    my $line = '...';
    $unansi->remove_ansi_colors($line);

=head1 AUTHOR

Sawyer X

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Sawyer X.

This is free software, licensed under:

  The MIT (X11) License

=cut
