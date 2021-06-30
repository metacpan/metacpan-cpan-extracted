use Text::Balanced;

$QUOTED_STRING = Text::Balanced::gen_delimited_pat( q{'"} );

$PossiblyQuotedString = qr/\s*( (?:$QUOTED_STRING | [^'",;]+)+ )/x;

1;


