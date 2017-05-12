use lib '../lib';
use Backup::Omni::Session::Messages;

my $messages = Backup::Omni::Session::Messages->new(
    -session => '2013/01/28-1'
);

while (my $message = $messages->next) {
    
    printf("next message = %s\n", $message);
    
}

while (my $message = $messages->prev) {
    
    printf("prev message = %s\n", $message);
    
}

