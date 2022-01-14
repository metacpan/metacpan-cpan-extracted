use strict;

# vim: ts=3 sts=3 sw=3 et ai ft=perl :

use Test::More;
use Test::Exception;
use Data::Dumper;

use Data::Tubes qw< summon >;

summon('Plumbing::dispatch');
ok __PACKAGE__->can('dispatch'), "summoned dispatch";

{
   my @outcome;
   lives_ok {
      my $tube = dispatch(
         key => 'key',
         handlers => {
            one => sub {
               my $record = shift;
               my $data = $record->{structured};
               $record->{rendered} = "1. <$data->{msg}>";
               return $record;
            },
            two => [
               'Renderer::with_template_perlish',
               template => 'hey ho two <[% msg %]>',
            ],
         },
         factory => sub {
            my ($key, $record) = @_;
            return sub {
               my $record = shift;
               my $data = $record->{structured};
               $record->{rendered} = "$key <$data->{msg}>";
               return $record;
            };
         },
      );

      for my $k (qw< one two three four >) {
         push @outcome, $tube->({key => $k, structured => {msg => $k}});
      }
   } ## end lives_ok
   'dispatch lives';

   is_deeply \@outcome,
     [
         {
            key => 'one',
            structured => {msg => 'one'},
            rendered => '1. <one>',
         },
         {
            key => 'two',
            structured => {msg => 'two'},
            rendered => 'hey ho two <two>',
         },
         {
            key => 'three',
            structured => {msg => 'three'},
            rendered => 'three <three>',
         },
         {
            key => 'four',
            structured => {msg => 'four'},
            rendered => 'four <four>',
         },
     ],
     'outcome of dispatch'
     or diag Dumper \@outcome;
}

done_testing();
