use strict;

# vim: ft=perl ts=3 sts=3 sw=3 et ai :

use Test::More;
use Data::Dumper;

use Data::Tubes qw< summon >;

summon('Parser::parse_by_separators');
ok __PACKAGE__->can('parse_by_separators'), "summoned parse_by_separators";

eval {
   my @separators = qw< :: ; , >;
   my $tube       = parse_by_separators(\@separators);
   my $input      = '  what  :: ever;you  , do';
   my $orec       = $tube->({raw => $input});
   is_deeply $orec->{structured}, ['  what  ', ' ever', 'you  ', ' do'],
     'simple stringy separators';
} or diag Dumper $@;

{
   my @separators = qw< :: ; , >;
   my $tube       = parse_by_separators(\@separators, trim => 1);
   my $input      = '  what  :: ever;you  , do';
   my $orec       = $tube->({raw => $input});
   is_deeply $orec->{structured}, ['what', 'ever', 'you', 'do'],
     'simple stringy separators, with trimming';
}

{
   my @separators = (qr{\s*::\s*}, qr{\s*;\s*}, qr{\s*,\s*});
   my $tube       = parse_by_separators(\@separators);
   my $input      = '  what  :: ever;you  , do ';
   my $orec       = $tube->({raw => $input});
   is_deeply $orec->{structured}, ['  what', 'ever', 'you', 'do '],
     'regexp separators, auto-trimming inside only';
}

{
   my @separators = (qr{\s*::\s*}, qr{\s*;\s*}, qr{\s*,\s*});
   my $tube  = parse_by_separators(\@separators, trim => 1);
   my $input = '  what  :: ever;you  , do ';
   my $orec  = $tube->({raw => $input});
   is_deeply $orec->{structured}, ['what', 'ever', 'you', 'do'],
     'regexp separators, auto-trimming inside & trim';
}

{
   my @separators = (qr{\s*::\s*}, ';;', qr{\s*,\s*});
   my $tube = parse_by_separators(
      \@separators,
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
     'mixed separators, auto-trimming inside & trim, with keys';
}

done_testing();
