use strict;

# vim: ft=perl ts=3 sts=3 sw=3 et ai :

use Test::More;
use Data::Dumper;

use Data::Tubes qw< summon >;

summon('Parser::parse_by_value_separator');
ok __PACKAGE__->can('parse_by_value_separator'),
  "summoned parse_by_value_separator";

eval {
   my $tube  = parse_by_value_separator('::');
   my $input = '  what  :: ever::you  :: do';
   my $orec  = $tube->({raw => $input});
   is_deeply $orec->{structured}, ['  what  ', ' ever', 'you  ', ' do'],
     'simple stringy separator, using default "whatever"';
} or diag Dumper $@;

{
   my $tube  = parse_by_value_separator(qr/[:;]{2}/, trim => 1);
   my $input = '  what  :: ever::you  :: do';
   my $orec  = $tube->({raw => $input});
   is_deeply $orec->{structured}, ['what', 'ever', 'you', 'do'],
     'simple separator, with trimming'
     or diag Dumper $orec;
}

{
   my $tube  = parse_by_value_separator(qr{\s*[:;,]+\s*});
   my $input = '  what  :: ever;you  , do ';
   my $orec  = $tube->({raw => $input});
   is_deeply $orec->{structured}, ['  what', 'ever', 'you', 'do '],
     'regexp separators, auto-trimming inside only';
}

{
   my $tube  = parse_by_value_separator(qr{\s*[:;,]+\s*}, trim => 1);
   my $input = '  what  :: ever;you  , do ';
   my $orec  = $tube->({raw => $input});
   is_deeply $orec->{structured}, ['what', 'ever', 'you', 'do'],
     'regexp separators, auto-trimming inside & trim';
}

{
   my $tube = parse_by_value_separator(
      qr{[:;,]+},
      trim => 1,
      keys => [qw< WHAT EVER YOU DO >]
   );
   my $input = '  what  :: ever     ;; you  , do ';
   my $orec = $tube->({raw => $input});
   is_deeply $orec->{structured},
     {
      WHAT => 'what',
      EVER => 'ever',
      YOU  => 'you',
      DO   => 'do'
     },
     'mixed seps, trim, with keys';
}

{
   my $tube = parse_by_value_separator(
      qr{[:;,]+},
      value => 'escaped',
      trim  => 1,
      keys  => [qw< WHAT EVER YOU DO >]
   );
   my $input = '  wh\\:at  :: ever     ;; you  , do ';
   my $orec = $tube->({raw => $input});
   is_deeply $orec->{structured},
     {
      WHAT => 'wh:at',
      EVER => 'ever',
      YOU  => 'you',
      DO   => 'do'
     },
     'mixed seps, trim, with keys, escaped';
}

{
   my $tube = parse_by_value_separator(
      qr{[:;,]+},
      value => ['single-quoted', 'whatever'],
      trim  => 1,
      keys  => [qw< WHAT EVER YOU DO >]
   );
   my $input = "'wh:at':: ever     ;; you  , do ";
   my $orec = $tube->({raw => $input});
   is_deeply $orec->{structured},
     {
      WHAT => 'wh:at',
      EVER => 'ever',
      YOU  => 'you',
      DO   => 'do'
     },
     'mixed seps, trim, with keys, single-quoted & whatever';
}

{
   my $tube = parse_by_value_separator(
      qr{[:;,]+},
      value => ['single-quoted', 'escaped'],
      trim  => 1,
      keys  => [qw< WHAT EVER YOU DO >]
   );
   my $input = "'wh:at':: ever     ;; yo\\;u  , do ";
   my $orec = $tube->({raw => $input});
   is_deeply $orec->{structured},
     {
      WHAT => 'wh:at',
      EVER => 'ever',
      YOU  => 'yo;u',
      DO   => 'do'
     },
     'mixed seps, trim, with keys, single-quoted & escaped';
}

{
   my $tube = parse_by_value_separator(
      qr{[:;,]+},
      value => ['single-quoted', 'escaped'],
      trim  => 1,
      keys  => [qw< WHAT EVER YOU DO >]
   );
   {
      my $input = "'wh:at':: ever     ;; yo\\;u  , do ";
      my $orec = $tube->({raw => $input});
      is_deeply $orec->{structured},
        {
         WHAT => 'wh:at',
         EVER => 'ever',
         YOU  => 'yo;u',
         DO   => 'do'
        },
        'mixed seps, trim, with keys, single-quoted & escaped, first';
   }
   {
      my $input = "'WH:AT':: EVER     ;; YO\\;U  , DO ";
      my $orec = $tube->({raw => $input});
      is_deeply $orec->{structured},
        {
         WHAT => 'WH:AT',
         EVER => 'EVER',
         YOU  => 'YO;U',
         DO   => 'DO'
        },
        'mixed seps, trim, with keys, single-quoted & escaped, second';
   }
}

done_testing();
