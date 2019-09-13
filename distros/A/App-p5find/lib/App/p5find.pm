package App::p5find;
use v5.18;
our $VERSION = "0.03";

use File::Next;
use PPI::Document::File;
use PPIx::QuoteLike;

use Exporter 'import';
our @EXPORT_OK = qw( p5_doc_iterator
                     p5_source_file_iterator
                     print_file_linenum_line );

my %EXCLUDED = (
    '.git' => 1,
    '.svn' => 1,
    'CVS'  => 1,
    'node_modules' => 1, # You won't hide your Perl5 code there, right ?
);

sub p5_doc_iterator {
    my (@paths) = @_;
    my $files = p5_source_file_iterator(@paths);
    return sub {
        my $f = $files->();
        return undef unless defined($f);
        my $dom = PPI::Document::File->new( $f, readonly => 1 );
        $dom->index_locations;
        return $dom;
    };
}

sub p5_source_file_iterator {
    my (@paths) = @_;
    my $files = File::Next::files(
        +{ descend_filter => sub { ! $EXCLUDED{$_} } },
        @paths
    );
    return sub {
        my $f;
        do { $f = $files->() } while defined($f) && ! is_perl5_source_file($f);
        return $f;
    }
}

sub is_perl5_source_file {
    my ($file) = @_;
    return 1 if $file =~ / \.(?: t|p[ml]|pod|comp ) $/xi;
    return 0 if $file =~ / \. /xi;
    if (open my $fh, '<', $file) {
        my $line = <$fh>;
        return 1 if $line =~ m{^#!.*perl};
    }
    return 0;
}

sub print_file_linenum_line {
    my ($file, $to_print) = @_;

    my $line_number = 0;
    open my $fh, "<", $file;
    while (my $line = <$fh>) {
        $line_number++;
        if ( $to_print->{$line_number} ) {
            print "${file}:${line_number}:${line}";
        }
    }
    close($fh);
}

1;

__END__

=head1 NAME

App::p5find - A collection of programs for locating certain constructs in Perl5 code.

=head1 DESCRIPTION

This distribution provides a collection of programs that search through Perl5
code structure for certain patterns. Such as: string literals with
interpolations, bareword tokens, vairable in method names.

While those code patterns may be discoverable with sufficient amount of
ack/grep-fu, this projects aims to reduce the amount of false recalls to the
point that it becomes usefull for tasks such as hunting for anti-patterns.

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 LICENSE

MIT

=cut
