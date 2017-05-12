package PhonyClipboard;
our $board = '';
sub copy { my $self = shift; $board = $_[0]; }
sub paste { my $self = shift; $board }
$Clipboard::driver = 'PhonyClipboard';
1;
