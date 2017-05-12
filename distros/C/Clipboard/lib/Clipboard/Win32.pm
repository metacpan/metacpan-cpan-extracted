package Clipboard::Win32;
use Win32::Clipboard;
our $board = Win32::Clipboard();
sub copy {
    my $self = shift;
    $board->Set($_[0]);
}
sub paste {
    my $self = shift;
    $board->Get();
}
