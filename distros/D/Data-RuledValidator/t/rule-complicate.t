use Test::Base;

use lib qw(t/lib);
use Data::RuledValidator;
use DRV_Test;
use Data::Dumper;
use strict;

my $DEFAULT =
  {
   page        => 'registration'                ,
   first_name  => 'Atsushi'                     ,
   last_name   => 'Kato'                        ,
   age         => 29                            ,
   sex         => 'male'                        ,
   mail        => 'ktat@cpan.org'               ,
   mail2       => 'ktat@cpan.org'               ,
   mail3       => 'ktat@example.com'            ,
   mail4       => 'ktat@example.com'            ,
   password    => 'pass'                        ,
   password2   => 'pass'                        ,
   hobby       => [qw/programming outdoor camp/],
   birth_year  => 1777                          ,
   birth_month => 1                             ,
   birth_day   => 1                             ,
   favorite    => [qw/books music/]             ,
   favorite_books  => ["Nodame", "Ookiku Furikabutte"],
   favorite_music  => ["Paul Simon"],
   must_select3    => [qw/1 2 3/],
   must_select1    => [qw/1/],
   same_data       => 'compare_from_data',
   must_gt_1000    => 1001,
   must_lt_1000    => 999,
   must_in_1_10    => [qw/8 9 7 4 3/],
   length_in_10    => '1234567890',
   regex           => 'abcdef',
  };

my $RESULT =
  {
   page_is              => 1,
   page_valid           => 1,
   first_name_is        => 1,
   first_name_valid     => 1,
   last_name_is         => 1,
   last_name_valid      => 1,
   age_is               => 1,
   age_valid            => 1,
   sex_in               => 1,
   sex_valid            => 1,
   mail_is              => 1,
   mail_valid           => 1,
   mail2_eq             => 1,
   mail2_valid          => 1,
   mail3_ne             => 1,
   mail3_valid          => 1,
   mail3_eq             => 1,
   password_is          => 1,
   password_valid       => 1,
   password2_eq         => 1,
   password2_valid      => 1,
   same_data_eq         => 1,
   same_data_valid      => 1,
   'require_of-valid'   => 1,
   'require_valid'      => 1,
   required_valid       => 1,
   birth_year_is        => 1,
   birth_year_valid     => 1,
   birth_month_is       => 1,
   birth_month_valid    => 1,
   birth_day_is         => 1,
   birth_day_valid      => 1,
   'birthdate_of-valid' => 1,
   'birthdate_valid'    => 1,
   hobby_in             => 1,
   hobby_valid          => 1,
   favorite_in          => 1,
   favorite_valid       => 1,
   favorite_books_is    => 1,
   favorite_books_valid => 1,
   favorite_music_is    => 1,
   favorite_music_valid => 1,
   must_select3_has     => 1,
   must_select3_valid   => 1,
   must_select1_has     => 1,
   must_select1_valid   => 1,
   'must_gt_1000_>'     => 1,
   'must_gt_1000_valid' => 1,
   'must_lt_1000_<'     => 1,
   'must_lt_1000_valid' => 1,
   must_in_1_10_between => 1,
   must_in_1_10_valid   => 1,
   'length_in_10_<='    => 1,
   length_in_10_length  => 1,
   length_in_10_valid   => 1,
   regex_match          => 1,
   regex_valid          => 1,
  };

filters({
         i => [qw/eval validator/],
         e => [qw/eval result/],
        });

run_compare i  => 'e';

sub validator{
  my $in = shift;
  my %default = %$DEFAULT;
  foreach my $k (keys %$in){
    $default{$k} = $in->{$k};
  }
  my $q = DRV_Test->new(%default);

  my $v = Data::RuledValidator->new(strict => 1, obj => $q, method => 'p', rule => "t/validator_complicate.rule");
  $v->by_rule({same_data => 'compare_from_data'});
  my %tmp;
  foreach(qw/failure result valid missing/){
    $tmp{$_} = $v->{$_};
  }
  @{$tmp{missing}} = sort {$a cmp $b} @{$tmp{missing}};
#   warn Data::Dumper::Dumper(\%tmp);
  return \%tmp;
}

sub result{
  my $in = shift;
  if(exists $in->{result}){
    foreach my $k (keys %$RESULT){
      if(not exists $in->{result}->{$k}){
        $in->{result}->{$k} = $RESULT->{$k};
      }elsif(not defined $in->{result}->{$k}){
        delete $in->{result}->{$k};
      }
    }
  }else{
    $in->{result} = $in->{result2} || {};
    delete $in->{result2};
  }
  $in->{missing} = [ sort {$a cmp $b} @{$in->{missing} || []} ];
  return $in;
}

__END__
=== all ok
--- i
  {};
--- e
  {
   result => {},
   valid   => 1,
   failure => {},
   missing => [ qw/hogehoge hogehoge2/]
}
=== mail incorrect
--- i
  {
   mail        => 'ktat@cpa'                    ,
   mail2       => 'ktat@cpan'                   ,
   mail3       => 'ktat@exampl'                 ,
   mail4       => 'ktat@example'                ,
 };
--- e
  {
   result =>
   {
    mail_is              => 0,
    mail_valid           => 0,
    mail2_eq             => 0,
    mail2_valid          => 0,
    mail3_ne             => 1,
    mail3_eq             => 0,
    mail3_valid          => 0,
    'require_of-valid'   => 0,
    'require_valid'      => 0,
   },
   valid   => 0,
   failure => {
               mail_is  => ['ktat@cpa'],
               mail2_eq => ['ktat@cpan'],
               mail3_eq => ['ktat@exampl'],
               'require_of-valid' => [undef],
              },
   missing => [sort {$a cmp $b} qw/hogehoge hogehoge2/]
}
=== mail missing
--- i
  {
   mail        => undef               ,
   mail2       => undef               ,
   mail3       => undef               ,
   mail4       => undef               ,
 };
--- e
  {
   result =>
   {
    'require_of-valid'   => 0,
    'require_valid'      => 0,
    required_valid       => 0,
    mail_is              => undef,
    mail_valid           => undef,
    mail2_eq             => undef,
    mail2_valid          => undef,
    mail3_ne             => undef,
    mail3_valid          => undef,
    mail3_eq             => undef,
   },
   valid   => 0,
   failure => {
               'require_of-valid' => [undef],
              },
   missing => [sort {$a cmp $b} qw/hogehoge hogehoge2 mail mail2 mail3/],
}
=== mail missing ok
--- i
  {
   page        => 'registrationNoRequired',
   mail        => undef               ,
   mail2       => undef               ,
   mail3       => undef               ,
   mail4       => undef               ,
 };
--- e
  {
   result =>
   {
    'require_of-valid'   => 1,
    'require_valid'      => 1,
    required_valid       => undef,
    mail_is              => undef,
    mail_valid           => undef,
    mail2_eq             => undef,
    mail2_valid          => undef,
    mail3_ne             => undef,
    mail3_valid          => undef,
    mail3_eq             => undef,
   },
   valid   => 1,
   failure => {},
   missing => [sort {$a cmp $b} qw/hogehoge hogehoge2 mail mail2 mail3/],
}
=== mail missing ok 2
--- i
  {
   page        => 'registration_no_required',
   mail        => undef               ,
   mail2       => undef               ,
   mail3       => undef               ,
   mail4       => undef               ,
 };
--- e
  {
   result =>
   {
    'require_of-valid'   => 0,
    'require_valid'      => 0,
    required_valid       => undef,
    mail_is              => undef,
    mail_valid           => undef,
    mail2_eq             => undef,
    mail2_valid          => undef,
    mail3_ne             => undef,
    mail3_valid          => undef,
    mail3_eq             => undef,
   },
   valid   => 0,
   failure => {
               'require_of-valid' => [undef],
              },
   missing => [sort {$a cmp $b} qw/hogehoge hogehoge2 mail mail2 mail3/],
}
=== mail missing not ok
--- i
  {
   page        => 'registrationNoRequired2',
   mail        => undef               ,
   mail2       => undef               ,
   mail3       => undef               ,
   mail4       => undef               ,
 };
--- e
  {
   result =>
   {
    'require_of-valid'   => 0,
    'require_valid'      => 0,
    required_valid       => undef,
    mail_is              => undef,
    mail_valid           => undef,
    mail2_eq             => undef,
    mail2_valid          => undef,
    mail3_ne             => undef,
    mail3_valid          => undef,
    mail3_eq             => undef,
   },
   valid   => 0,
   failure => {
               'require_of-valid' => [undef],
              },
   missing => [sort {$a cmp $b} qw/hogehoge hogehoge2 mail mail2 mail3/],
}
=== mail missing ok 3
--- i
  {
   page        => 'registrationNoRequired2',
   mail        => undef               ,
   mail2       => undef               ,
   mail3       => undef               ,
   mail4       => undef               ,
   hogehoge    => 'hogehoge',
 };
--- e
  {
   result =>
   {
    'require_of-valid'   => 1,
    'require_valid'      => 1,
    required_valid       => undef,
    mail_is              => undef,
    mail_valid           => undef,
    mail2_eq             => undef,
    mail2_valid          => undef,
    mail3_ne             => undef,
    mail3_valid          => undef,
    mail3_eq             => undef,
    hogehoge_valid       => 1,
    hogehoge_eq          => 1,
   },
   valid   => 1,
   failure => {},
   missing => [sort {$a cmp $b} qw/hogehoge2 mail mail2 mail3/],
}
=== GLOBAL is n/a
--- i
  {
    page => 'registration2'
  };
--- e
  {
   valid   => 1,
   failure => {},
   missing => [],
}

=== no rule
--- i
  {
    page => 'no_rule'
  };
--- e
  {
   valid   => 1,
   failure => {},
   missing => [],
}
=== id missing
--- i
  {
    page => undef
  };
--- e
  {
   valid   => 1,
   failure => {},
   missing => [],
}
=== filter
--- i
  {
    page => 'filter',
    name => '  ktat  ',
    zip  => '000-000',
  };
--- e
  {
   valid   => 1,
   result2 => {
               zip_is     => 1,
               zip_valid  => 1,
               name_is    => 1,
               name_valid => 1,
              },
   failure => {},
   missing => [],
  };
=== filter2
--- i
  {
    page => 'filter2',
    name => '  ktat  ',
    zip  => '000-000',
  };
--- e
  {
   valid   => 1,
   result2 => {
               zip_is     => 1,
               zip_valid  => 1,
               name_is    => 1,
               name_valid => 1,
              },
   failure => {},
   missing => [],
  };
=== no_filter
--- i
  {
    page => 'no_filter',
    name => '  ktat  ',
    zip  => '000-000',
  };
--- e
  {
   valid   => 0,
   result2 => {
               zip_is     => 0,
               zip_valid  => 0,
               name_is    => 0,
               name_valid => 0,
              },
   failure => {
               zip_is  => ['000-000'],
               name_is => ['  ktat  '],
              },
   missing => [],
  };
=== filter3
--- i
  {
    page => 'filter3',
    name => '  ktat  ',
    zip  => '000-000',
  };
--- e
  {
   valid   => 0,
   result2 => {
               zip_is     => 1,
               zip_valid  => 1,
               name_is    => 0,
               name_valid => 0,
              },
   failure => {
               name_is => ['  ktat  '],
              },
   missing => [],
  };
=== filter4
--- i
  {
    page => 'filter4',
    name => '  ktat  ',
    zip  => '000-000',
  };
--- e
  {
   valid   => 0,
   result2 => {
               zip_is     => 1,
               zip_valid  => 1,
               name_is    => 0,
               name_valid => 0,
              },
   failure => {
               name_is => ['  ktat  '],
              },
   missing => [],
  };
=== special filter
--- i
  {
    page => 'specialfilter',
  };
--- e
  {
   valid   => 1,
   result2 => {
               birth_year_is_1777_valid   => 1,
               birth_year_is_1777_eq      => 1,
              },
   failure => {},
   missing => [],
  };
=== filter *
--- i
  {
    page => 'filter5',
    name => '  ktat  ',
    zip  => '  000000  ',
  };
--- e
  {
   valid   => 1,
   result2 => {
               zip_is     => 1,
               zip_valid  => 1,
               name_is    => 1,
               name_valid => 1,
              },
   failure => {},
   missing => [],
  };

=== order test
--- i
  {
    page => 'order_test',
    name => '  ktat  ',
    zip  => '  000000  ',
  };
--- e
  {
   valid   => 1,
   result2 => {
               zip_is             => 1,
               zip_valid          => 1,
               name_is            => 1,
               name_valid         => 1,
               'all_v_of-valid'   => 1,
               all_v_valid        => 1,
               all_valid_of       => 1,
               all_valid_valid    => 1,
              },
   failure => {},
   missing => [],
  };

