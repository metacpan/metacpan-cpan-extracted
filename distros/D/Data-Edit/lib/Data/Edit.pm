package Data::Edit;

use 5.010001;
use strict;
use warnings;

require Exporter;
use File::Spec;
use YAML::Any;
use File::Temp qw/ tempfile /;
use Data::Edit::vimdiff;
use Data::Edit::editor;
use Cwd;
use Try::Tiny;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Data::Edit ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    edit_structure
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.02';

sub edit_structure {
    my ($structure, $name) = @_;

    my $last_error;
    my $out;

    my $header_lines=5;

    my @offer_to_edit = map { "$_\n" } split(/\n/, Dump($structure));

    do {
        my @header_block = map { "## $_\n" } split(/\n/, $name || "");
        if ($last_error) {
            push @header_block, "## The previous error was:\n";
            push @header_block, map { "## $_\n" } split(/\n/, $last_error);
        }

        push @header_block, "##\n" while scalar(@header_block)<$header_lines;

        if (scalar(@header_block)>$header_lines) {
            # Which cunningly extends the next header block by one line.
            push @header_block, "## Error too long, line numbers will be wrong.\n";
        }

        my ($orig_fh, $orig_fn) = tempfile( SUFFIX => ".yml" );
        print $orig_fh map { "##\n" } @header_block;
        print $orig_fh Dump($structure);
        close $orig_fh;

        chmod 0400, $orig_fn;

        my ($edit_fh, $edit_fn) = tempfile( SUFFIX => ".yml" );
        print $edit_fh @header_block;

        # XXX assumes only header lines at start
        print $edit_fh grep { $_!~ /^##/ } @offer_to_edit;
        close $edit_fh;

        my $ed = find_editor();
        $ed->edit($edit_fn, $orig_fn);

        open(my $fh, "<", $edit_fn) or die $!;
        @offer_to_edit = <$fh>;

        # XXX assumes only header lines at start
        $header_lines = scalar(grep { /^##/ } @offer_to_edit);

        $last_error = undef;
        try {
            $out = Load(join("", @offer_to_edit));
        }
        catch {
            $last_error = $_;
        };

        close $fh;
        unlink($orig_fn) or warn "Could not delete '$orig_fn': $!";
        unlink($edit_fn) or warn "Could not delete '$edit_fn': $!";


    } while ($last_error);

    return $out;
}

sub find_editor {
    my $ed = $ENV{VISUAL} || $ENV{EDITOR};

    # Debian / Ubuntu magic
    unless ($ed) {
        $ed = "/usr/bin/editor";
        if (-l $ed) {
            $ed = Cwd::realpath($ed);
        }
    }

    my ($vol, $dir, $file) = File::Spec->splitpath($ed);

    if ($file eq 'vim') {
        if (-x (my $vimdiff = File::Spec->catpath($vol, $dir, 'vimdiff'))) {
            return Data::Edit::vimdiff->new( path => $vimdiff );
        }
    }
    return Data::Edit::editor->new( path => $ed );
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Data::Edit - Perl wrapper around your text editor

=head1 SYNOPSIS

  use Data::Edit;
  my $structure = { ... };
  Data::Edit::edit_structure($structure, "my structure");

=head1 DESCRIPTION

The module is a wrapper around a YAML parser and your text editor, for the
purpose of editing a data structure in memory.  Special magic is added for vim
users to allow them to see the changes they are making in C<vimdiff>.

=head2 EXPORT

=over

=item edit_structure

May be exported

=back

=head1 ENVIRONMENT

C<VISUAL> and C<EDITOR> are looked at to determine the text editor to use.  If
these aren't defined, it checks for a symlink at /usr/bin/editor.

=head1 SEE ALSO

=over

=item *

L<YAML>

=item *

L<vimdiff>

=back

=head1 AUTHOR

Dave Lambley, E<lt>davel@state51.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Dave Lambley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
