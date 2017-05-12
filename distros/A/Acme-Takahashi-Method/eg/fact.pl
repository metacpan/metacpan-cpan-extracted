use Acme::Takahashi::Method;
our $n = shift || 1;
our $result = 1;
loop: 
$result *= $n--;
goto loop unless $n <= 1;
print $result, "\n";
