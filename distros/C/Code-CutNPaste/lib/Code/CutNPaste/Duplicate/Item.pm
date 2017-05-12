package Code::CutNPaste::Duplicate::Item;

use Moo;
has 'file' => ( is => 'ro' );
has 'line' => ( is => 'ro' );
has 'code' => ( is => 'ro' );

our $VERSION = 0.31;

1;

__END__

=head1 NAME

Code::CutNPaste::Duplicate::Item - Individual code snippet

=head1 SYNOPSIS

    my $item = Code::CutNPaste::Duplicate::Item->new(
        file => $filename,
        line => $line_number,
        code => $text_of_code,
    );

=head1 DESCRIPTION

This is merely a simple object to report on a chunk of code. For internal use
only.

=head1 VERSION

0.31

=head1 METHODS

=head2 C<file>

Returns the name of the file the code is contained in.

=head2 C<line>

Returns the (approximate) line number the code starts at.

=head2 C<code>

Returns the (approximate) code which is duplicated.
