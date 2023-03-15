use Affix;
affix( './string_reverse.so', 'string_reverse' => [Str] => Str );
print string_reverse("\nHello world");
string_reverse(undef);
