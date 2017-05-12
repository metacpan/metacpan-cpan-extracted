package Clipboard::MacPasteboard;
use Mac::Pasteboard;
our $board = Mac::Pasteboard->new();
$board->set( missing_ok => 1 );
sub copy {
    my $self = shift;
    $board->clear();
    $board->copy($_[0]);
}
sub paste {
    my $self = shift;
    return scalar $board->paste();
}
