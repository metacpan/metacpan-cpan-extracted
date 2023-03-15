use Affix;
#
affix 'notify', 'notify_init',              [Str];
affix 'notify', 'notify_uninit',            [];
affix 'notify', 'notify_notification_new',  [ Str, Str, Str ] => Pointer [Void];
affix 'notify', 'notify_notification_show', [ Pointer [Void], Pointer [Void] ];
#
my $message = "Hello from Affix!\nWelcome to the fun\nworld of Affix";
notify_init('Affix 🏒');
my $n = notify_notification_new( 'Keep your stick on the ice!', $message, 'dialog-information' );
notify_notification_show( $n, undef );
notify_uninit();
