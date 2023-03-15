use Affix qw[malloc strdup memcpy free];
my $buffer     = malloc 14;
my $ptr_string = strdup("hello there!!\n");
memcpy $buffer, $ptr_string, 15;
print $buffer;
free $ptr_string;
free $buffer;
